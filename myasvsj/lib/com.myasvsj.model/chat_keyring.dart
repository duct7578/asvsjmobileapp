import 'dart:async';
import 'dart:typed_data';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/chat_crypto.dart';
import 'package:myasvsj/com.myasvsj.model/chat_device_key_dao.dart';
import 'package:myasvsj/com.myasvsj.model/chat_envelope.dart';
import 'package:myasvsj/com.myasvsj.model/chat_identity.dart';
import 'package:myasvsj/com.myasvsj.model/chat_key_backup.dart';
import 'package:myasvsj/com.myasvsj.model/chat_key_dao.dart';
import 'package:myasvsj/com.myasvsj.model/chat_message.dart';
import 'package:myasvsj/com.myasvsj.model/chat_status.dart';

/// App làm được gì với tin mã hóa lúc này.
enum ChatKeyState {
  /// Không dùng mã hóa (chưa đăng nhập, hoặc không có ChatKeyDao).
  off,

  /// Đang hỏi server khóa hiện tại.
  loading,

  /// Tài khoản chưa bật mã hóa đầu cuối.
  none,

  /// Tài khoản có khóa nhưng app chưa mở (cần mật khẩu khôi phục).
  locked,

  /// Đã mở khóa: đọc và gửi được tin mã hóa.
  ready,

  /// Không tải được khóa (mất mạng…).
  error,
}

/// Khóa trên server đã đổi (mở / tạo ở máy khác) so với khóa app đang giữ.
class ChatKeyChangedException extends ChatCryptoException {
  const ChatKeyChangedException()
    : super('Khóa mã hóa của bạn vừa được đổi trên một máy khác. Hãy nhập mật khẩu khôi phục rồi gửi lại.');
}

/// Tài khoản đã có khóa (bật ở máy khác) trong lúc người dùng định bật mã hóa lần đầu: phải mở khóa đó, không tạo đè.
class ChatKeyExistsException extends ChatCryptoException {
  const ChatKeyExistsException()
    : super('Bạn đã bật mã hóa trên một thiết bị khác. Hãy nhập mật khẩu khôi phục đã đặt khi đó.');
}

/// Chùm khóa mã hóa đầu cuối của người đăng nhập trong app, như phần "encryption key" và "decrypting" của
/// `pages/messages.js` trên web:
///
/// - khóa định danh đã mở bằng mật khẩu khôi phục, lưu an toàn trên máy ([ChatDeviceKeyDao]) để lần sau mở app
///   không phải nhập lại; và
///   một khóa cũ hơn ([ChatIdentity]) khi vừa tạo khóa mới, để vẫn đọc tin viết cho khóa cũ trong lần mở app này;
/// - khóa công khai của người khác theo id, khóa AES của từng cặp khóa trong từng cuộc trò chuyện (tính một lần);
/// - kết quả giải mã của từng tin (`id:iv`, tin sửa có iv mới thì giải mã lại).
///
/// Giải mã chạy nền; xong thì gọi [onChanged] để màn hình vẽ lại.
class ChatKeyring {
  ChatKeyring(this._dao, this._crypto, {ChatDeviceKeyDao? device, this.onChanged}) : _device = device;

  final ChatKeyDao? _dao;
  final ChatCrypto _crypto;

  /// Nơi lưu khóa đã mở trên máy; null thì khóa chỉ nằm trong bộ nhớ (mở lại app phải nhập lại mật khẩu).
  final ChatDeviceKeyDao? _device;

  /// Lần mở / tạo khóa gần nhất đã được lưu trên máy (false khi không có nơi lưu hoặc máy từ chối).
  bool savedOnDevice = false;

  /// Gọi khi trạng thái khóa đổi hoặc một tin vừa giải mã xong.
  void Function()? onChanged;

  ChatKeyState state = ChatKeyState.off;

  /// Lỗi khi tải khóa ([ChatKeyState.error]).
  String? error;

  /// Khóa hiện tại của tài khoản trên server; null khi chưa bật mã hóa.
  ChatKeyBackup? serverKey;

  ChatIdentity? _identity;
  ChatIdentity? _legacy;
  int? _userId;
  Future<void>? _loading;
  int _generation = 0;

  final Map<int, Future<String>> _publicKeys = {};
  final Map<String, Future<Uint8List>> _conversationKeys = {};
  final Map<String, _Decryption> _decrypted = {};

  static const String lockedLabel = 'Tin nhắn đã mã hóa. Nhập mật khẩu khôi phục để đọc.';
  static const String shortLabel = 'Tin nhắn đã mã hóa';
  static const String loadingLabel = 'Đang tải khóa mã hóa…';
  static const String decryptingLabel = 'Đang giải mã…';
  static const String retryingLabel = 'Chưa giải mã được, đang thử lại…';
  static const String unreadableLabel = 'Không đọc được tin nhắn này';

  /// Một tin giải mã lỗi vì mạng thì thử lại sau khoảng này (khi màn hình vẽ lại).
  static const Duration retryAfter = Duration(seconds: 15);

  bool get enabled => _dao != null;

  /// Khóa đang mở; null khi chưa mở khóa.
  ChatIdentity? get identity => _identity;

  /// Người đăng nhập đổi: quên mọi khóa và tin đã giải mã của người cũ.
  void reset(int? userId) {
    _generation++;
    _userId = userId;
    _identity = null;
    _legacy = null;
    serverKey = null;
    error = null;
    savedOnDevice = false;
    _loading = null;
    _publicKeys.clear();
    _conversationKeys.clear();
    _decrypted.clear();
    state = enabled && userId != null ? ChatKeyState.loading : ChatKeyState.off;
  }

  /// Hỏi server khóa hiện tại, đọc khóa đã lưu trên máy, rồi quyết định [state]: khóa trên máy đúng là khóa hiện tại
  /// thì dùng luôn (không hỏi mật khẩu). Khóa app đang giữ mà server đã thay bằng khóa khác (máy khác tạo) thì thành
  /// khóa cũ (vẫn đọc tin viết cho nó), và phải mở khóa mới.
  Future<void> load() {
    if (_dao == null || _userId == null) {
      return Future.value();
    }
    return _loading ??= _load().whenComplete(() => _loading = null);
  }

  Future<void> _load() async {
    final generation = _generation;
    final userId = _userId!;
    try {
      final (mine, local) = await (
        _dao!.findMine(),
        _readDevice(userId),
      ).wait.onError<ParallelWaitError>((e, _) => throw (e.errors.$1 ?? e.errors.$2)!);
      if (generation != _generation) {
        return;
      }
      serverKey = mine;
      error = null;
      final current = _identity;
      if (current != null && mine != null && current.keyId == mine.id) {
        state = ChatKeyState.ready;
      } else if (local != null && mine != null && local.keyId == mine.id && local.publicKey == mine.publicKey) {
        savedOnDevice = true;
        _setIdentity(local, notify: false);
      } else {
        final old = current ?? local;
        if (old != null && old.keyId != mine?.id) {
          _legacy = old;
        }
        _identity = null;
        state = mine == null ? ChatKeyState.none : ChatKeyState.locked;
      }
    } on ApiException catch (e) {
      if (generation != _generation) {
        return;
      }
      if (state != ChatKeyState.ready) {
        state = ChatKeyState.error;
        error = e.message;
      }
    }
    onChanged?.call();
  }

  /// Mở khóa hiện tại trên server (lấy bản mới nhất) bằng [passphrase]. Sai mật khẩu: [WrongPassphraseException];
  /// tài khoản chưa có khóa: [ChatCryptoException] và [state] thành [ChatKeyState.none].
  Future<void> unlock(String passphrase) async {
    final generation = _generation;
    final backup = await _dao!.findMine();
    if (generation != _generation) {
      return;
    }
    serverKey = backup;
    if (backup == null) {
      state = ChatKeyState.none;
      onChanged?.call();
      throw const ChatCryptoException('Bạn chưa bật mã hóa đầu cuối. Hãy bật mã hóa trước.');
    }
    final unlocked = await _crypto.unlock(backup, passphrase);
    if (generation != _generation) {
      return;
    }
    _setIdentity(unlocked);
    await _keepOnDevice(unlocked);
  }

  /// Tạo khóa mới với [passphrase] và gửi bản sao lưu lên server. Lần đầu ([replace] false) mà server đã có khóa
  /// (bật ở máy khác): [ChatKeyExistsException], [state] thành [ChatKeyState.locked]. [replace] true ("Quên mật
  /// khẩu") thay khóa cũ: tin mã hóa cũ không đọc được nữa.
  Future<void> create(String passphrase, {bool replace = false}) async {
    final generation = _generation;
    if (!replace) {
      final current = await _dao!.findMine();
      if (generation != _generation) {
        return;
      }
      if (current != null) {
        serverKey = current;
        state = ChatKeyState.locked;
        onChanged?.call();
        throw const ChatKeyExistsException();
      }
    }
    final made = await _crypto.createKey(passphrase);
    final saved = await _dao!.create(made);
    if (generation != _generation) {
      return;
    }
    final old = _identity;
    if (old != null && old.keyId != saved.id) {
      _legacy = old;
    }
    serverKey = saved;
    final next = ChatIdentity(keyId: saved.id, publicKey: saved.publicKey, privateKey: made.privateKey);
    _setIdentity(next);
    await _keepOnDevice(next);
  }

  void _setIdentity(ChatIdentity next, {bool notify = true}) {
    _identity = next;
    state = ChatKeyState.ready;
    error = null;
    // Tin chưa mở được trước đây có thể mở được bây giờ
    _decrypted.removeWhere((_, d) => d.state != _DecryptState.ok && d.state != _DecryptState.pending);
    if (notify) {
      onChanged?.call();
    }
  }

  /// Khóa đã lưu trên máy; máy không đọc được (hỏng, bị xóa khóa Keystore…) thì coi như chưa lưu.
  Future<ChatIdentity?> _readDevice(int userId) async {
    final device = _device;
    if (device == null) {
      return null;
    }
    try {
      return await device.find(userId);
    } catch (_) {
      return null;
    }
  }

  /// Lưu khóa vừa mở / tạo trên máy; máy từ chối thì khóa chỉ nằm trong bộ nhớ lần mở app này.
  Future<void> _keepOnDevice(ChatIdentity identity) async {
    final device = _device;
    final userId = _userId;
    savedOnDevice = false;
    if (device == null || userId == null) {
      return;
    }
    try {
      await device.save(userId, identity);
      savedOnDevice = true;
    } catch (_) {
      // Giữ trong bộ nhớ
    }
  }

  /// Ghi nhớ khóa công khai của người kia mà trạng thái cuộc trò chuyện đã cho, đỡ một lần hỏi server.
  void rememberPublicKey(int? keyId, String? publicKey) {
    if (keyId != null && publicKey != null) {
      _publicKeys.putIfAbsent(keyId, () => Future.value(publicKey));
    }
  }

  /// Trạng thái [status] của một cuộc trò chuyện mã hóa ghi khóa của mình khác khóa app đang giữ: tải lại khóa.
  void checkStatus(ChatStatus status) {
    rememberPublicKey(status.peerKeyId, status.peerPublicKey);
    final mine = _identity;
    if (status.isEncrypted && mine != null && status.myKeyId != null && status.myKeyId != mine.keyId) {
      unawaited(load());
    }
  }

  // ---------------------------------------------------------------- Giải mã

  /// Tin [m] để hiện: tin thường giữ nguyên; tin mã hóa thành bản sao có chữ đã giải mã, hoặc câu "Đang giải mã…",
  /// "Nhập mật khẩu khôi phục để đọc."… ([short]: câu ngắn cho dòng xem trước của danh sách). Lần đầu gặp một tin thì
  /// bắt đầu giải mã nó ở nền.
  ChatMessage view(ChatMessage m, {required int conversationId, required int peerId, bool short = false}) {
    if (!m.isEncrypted || m.recalled) {
      return m;
    }
    final env = m.envelope;
    final me = _userId;
    final ready = state == ChatKeyState.ready;
    String lockedText() => short ? shortLabel : (state == ChatKeyState.loading ? loadingLabel : lockedLabel);
    if (env == null || me == null) {
      return m.withLocked(ready ? unreadableLabel : lockedText());
    }
    final cacheKey = '${m.id}:${env.iv}';
    var entry = _decrypted[cacheKey];
    final retry =
        entry != null &&
        entry.state == _DecryptState.failed &&
        DateTime.now().difference(entry.failedAt ?? DateTime.now()) >= retryAfter;
    if (entry == null || retry) {
      final myKeyId = m.mine ? env.senderKeyId : env.recipientKeyId;
      final peerKeyId = m.mine ? env.recipientKeyId : env.senderKeyId;
      if (_privateKeyFor(myKeyId) == null) {
        // Viết cho một khóa app không có (tạo trước khi đổi khóa ở máy khác): không đọc được
        return m.withLocked(ready ? unreadableLabel : lockedText());
      }
      final started = _Decryption();
      entry = started;
      _decrypted[cacheKey] = started;
      unawaited(_decrypt(started, conversationId, m.mine ? me : peerId, myKeyId, peerKeyId, env));
    }
    return switch (entry.state) {
      _DecryptState.ok => m.withDecrypted(entry.opened?.body.text ?? ''),
      _DecryptState.pending => m.withLocked(decryptingLabel),
      _DecryptState.failed => m.withLocked(short ? decryptingLabel : retryingLabel),
      _DecryptState.unreadable => m.withLocked(unreadableLabel),
    };
  }

  /// Nội dung đã giải mã của tin [m] (kèm fk và P để báo cáo, tệp để sửa chữ không mất tệp); null khi chưa đọc được.
  ChatOpened? openedOf(ChatMessage m) {
    final env = m.envelope;
    if (env == null) {
      return null;
    }
    final entry = _decrypted['${m.id}:${env.iv}'];
    return entry?.state == _DecryptState.ok ? entry?.opened : null;
  }

  Future<void> _decrypt(
    _Decryption entry,
    int conversationId,
    int senderId,
    int myKeyId,
    int peerKeyId,
    ChatEnvelope env,
  ) async {
    final generation = _generation;
    try {
      final key = await _conversationKey(conversationId, myKeyId, peerKeyId);
      entry.opened = _crypto.decrypt(key: key, conversationId: conversationId, senderId: senderId, envelope: env);
      entry.state = _DecryptState.ok;
    } on ApiException catch (e) {
      // 404: khóa công khai không còn thấy được (không cùng cuộc trò chuyện nữa); lỗi mạng thì thử lại sau
      if (e.statusCode == 404) {
        entry.state = _DecryptState.unreadable;
      } else {
        entry.state = _DecryptState.failed;
        entry.failedAt = DateTime.now();
      }
    } catch (_) {
      entry.state = _DecryptState.unreadable;
    }
    if (generation == _generation) {
      onChanged?.call();
    }
  }

  // ---------------------------------------------------------------- Mã hóa

  /// Mã hóa [body] để gửi (hoặc sửa) trong cuộc trò chuyện [conversationId] với hai khóa hiện tại của [status].
  /// Chưa mở khóa: [ChatCryptoException]; khóa trên server đã đổi: [ChatKeyChangedException] (và tải lại khóa).
  Future<ChatSealed> seal({required int conversationId, required ChatStatus status, required ChatBody body}) async {
    final mine = _identity;
    final me = _userId;
    final myKeyId = status.myKeyId;
    final peerKeyId = status.peerKeyId;
    if (!status.isEncrypted || mine == null || me == null || myKeyId == null || peerKeyId == null) {
      throw const ChatCryptoException('Nhập mật khẩu khôi phục để gửi tin nhắn mã hóa.');
    }
    if (myKeyId != mine.keyId) {
      unawaited(load());
      throw const ChatKeyChangedException();
    }
    rememberPublicKey(peerKeyId, status.peerPublicKey);
    final key = await _conversationKey(conversationId, myKeyId, peerKeyId);
    return _crypto.encrypt(
      key: key,
      conversationId: conversationId,
      senderId: me,
      senderKeyId: myKeyId,
      recipientKeyId: peerKeyId,
      body: body,
    );
  }

  /// Tin của mình vừa gửi / sửa: đã biết nội dung, không cần giải mã lại.
  void remember(ChatMessage message, ChatSealed sealed) {
    final env = message.envelope;
    if (env == null) {
      return;
    }
    _decrypted['${message.id}:${env.iv}'] = _Decryption()
      ..state = _DecryptState.ok
      ..opened = ChatOpened(body: sealed.body, frankingKey: sealed.frankingKey, plaintext: sealed.plaintext);
  }

  // ---------------------------------------------------------------- Khóa

  Uint8List? _privateKeyFor(int keyId) {
    if (_identity?.keyId == keyId) {
      return _identity!.privateKey;
    }
    if (_legacy?.keyId == keyId) {
      return _legacy!.privateKey;
    }
    return null;
  }

  /// Khóa công khai theo id: của mình lấy trong bộ nhớ, của người khác hỏi server một lần.
  Future<String> _publicKeyOf(int keyId) {
    if (_identity?.keyId == keyId) {
      return Future.value(_identity!.publicKey);
    }
    if (serverKey?.id == keyId) {
      return Future.value(serverKey!.publicKey);
    }
    return _publicKeys.putIfAbsent(keyId, () {
      final asked = _dao!.findPublicKey(keyId);
      asked.ignore();
      return asked.catchError((Object e) {
        _publicKeys.remove(keyId);
        throw e;
      });
    });
  }

  /// Khóa AES của một cặp khóa trong một cuộc trò chuyện (ECDH + HKDF), tính một lần.
  Future<Uint8List> _conversationKey(int conversationId, int myKeyId, int peerKeyId) {
    final id = '$conversationId:$myKeyId:$peerKeyId';
    final known = _conversationKeys[id];
    if (known != null) {
      return known;
    }
    final privateKey = _privateKeyFor(myKeyId);
    if (privateKey == null) {
      return Future.error(const UnreadableMessageException());
    }
    final derived = () async {
      final peerPublicKey = await _publicKeyOf(peerKeyId);
      return _crypto.conversationKey(privateKey, peerPublicKey, conversationId, myKeyId, peerKeyId);
    }();
    _conversationKeys[id] = derived;
    derived.ignore();
    return derived.catchError((Object e) {
      _conversationKeys.remove(id);
      throw e;
    });
  }
}

enum _DecryptState { pending, ok, unreadable, failed }

class _Decryption {
  _DecryptState state = _DecryptState.pending;
  ChatOpened? opened;
  DateTime? failedAt;
}
