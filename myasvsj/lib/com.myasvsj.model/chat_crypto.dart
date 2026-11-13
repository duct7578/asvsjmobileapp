import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

import 'package:myasvsj/com.myasvsj.model/chat_envelope.dart';
import 'package:myasvsj/com.myasvsj.model/chat_identity.dart';
import 'package:myasvsj/com.myasvsj.model/chat_key_backup.dart';

/// Chạy một việc nặng (PBKDF2, ECDH) ở đâu đó rồi trả kết quả: mặc định một Isolate riêng để giao diện không đứng.
/// Hàm [work] chỉ được giữ dữ liệu gửi được qua Isolate (chuỗi, số, byte).
typedef ChatCryptoRunner = Future<R> Function<R>(R Function() work);

/// Lỗi mã hóa có câu tiếng Việt để hiện thẳng cho người dùng.
class ChatCryptoException implements Exception {
  const ChatCryptoException(this.message);

  final String message;

  @override
  String toString() => 'ChatCryptoException: $message';
}

/// Mật khẩu khôi phục không mở được bản sao lưu khóa.
class WrongPassphraseException extends ChatCryptoException {
  const WrongPassphraseException() : super('Mật khẩu khôi phục không đúng. Hãy thử lại.');
}

/// Tin không giải mã được: sai khóa, bị sửa, franking tag không khớp hoặc nội dung không đúng dạng v1.
class UnreadableMessageException extends ChatCryptoException {
  const UnreadableMessageException() : super('Không đọc được tin nhắn đã mã hóa này.');
}

/// Nội dung P của một tin: chữ và / hoặc danh sách tệp (ảnh, video, ghi âm) như hợp đồng của web.
class ChatBody {
  const ChatBody({this.text, this.files = const []});

  final String? text;

  /// Mỗi tệp `{id, kind, mime, size, key, iv, w?, h?, dur?}`; app chỉ giữ lại để sửa chữ mà không mất tệp.
  final List<Map<String, Object?>> files;
}

/// Kết quả mã hóa một tin: phong bì gửi lên server, và fk + P (base64) để báo cáo / sửa về sau.
class ChatSealed {
  const ChatSealed({required this.envelope, required this.frankingKey, required this.plaintext, required this.body});

  final ChatEnvelope envelope;
  final String frankingKey;
  final String plaintext;
  final ChatBody body;
}

/// Kết quả giải mã một tin: nội dung, và fk + P (base64) mà báo cáo gửi kèm (server kiểm franking tag).
class ChatOpened {
  const ChatOpened({required this.body, required this.frankingKey, required this.plaintext});

  final ChatBody body;
  final String frankingKey;
  final String plaintext;
}

/// Một khóa định danh mới: khóa công khai và bản sao lưu gửi lên server, khóa bí mật giữ trong app.
class ChatNewKey {
  const ChatNewKey({
    required this.publicKey,
    required this.wrappedPrivateKey,
    required this.wrapSalt,
    required this.wrapIv,
    required this.wrapIterations,
    required this.privateKey,
  });

  final String publicKey;
  final String wrappedPrivateKey;
  final String wrapSalt;
  final String wrapIv;
  final int wrapIterations;
  final Uint8List privateKey;

  /// Thân của POST /api/me/chats/keys.
  Map<String, dynamic> toRequestJson() => {
    'publicKey': publicKey,
    'wrappedPrivateKey': wrappedPrivateKey,
    'wrapSalt': wrapSalt,
    'wrapIv': wrapIv,
    'wrapIterations': wrapIterations,
  };
}

/// Mã hóa đầu cuối "Tin nhắn", làm lại đúng từng byte của `assets/js/lib/chat-crypto.js` trên web (hợp đồng giai
/// đoạn 2, mục 4) để app và trình duyệt đọc được tin của nhau. Thuần Dart (pointycastle), không cần plugin.
///
/// - Khóa định danh: ECDH P-256. Khóa bí mật (PKCS8) được sao lưu lên server, khóa bằng AES-GCM-256 với khóa
///   PBKDF2-SHA256 (600.000 vòng) của mật khẩu khôi phục đã chuẩn hóa NFC.
/// - Khóa của một cặp khóa trong một cuộc trò chuyện: ECDH → HKDF-SHA256 (salt `asvsj-chat-v1`, info
///   `conv:<id>:<keyId nhỏ>:<keyId lớn>`).
/// - Tin: AES-GCM của `fk ‖ P`, AAD `<conversationId>|<senderId>|<senderKeyId>|<recipientKeyId>`, P là UTF-8 của
///   `{"v":1,"text"?,"files"?}`; franking tag = hex HMAC-SHA256(fk, `asvsj-frank-v1|<conv>|<sender>|` ‖ P).
///
/// Giới hạn đã biết (giống web): một khóa tĩnh cho mỗi người, không có ratchet nên không có forward secrecy.
class ChatCrypto {
  ChatCrypto({ChatCryptoRunner? runner}) : _run = runner ?? _inIsolate;

  /// Chạy mọi thứ ngay trên isolate đang gọi (test, hoặc nơi không tạo được Isolate).
  factory ChatCrypto.inline() => ChatCrypto(runner: _inline);

  final ChatCryptoRunner _run;

  static Future<R> _inIsolate<R>(R Function() work) => Isolate.run(work);

  static Future<R> _inline<R>(R Function() work) async => work();

  /// Số vòng PBKDF2 khi tạo khóa mới (như web).
  static const int wrapIterations = 600000;

  /// Mật khẩu khôi phục ngắn nhất (số ký tự sau NFC).
  static const int passphraseMinLength = 8;

  /// Bản mã lớn nhất server nhận cho một tin.
  static const int maxCiphertextBytes = 32768;

  static const int _minIterations = 100000;
  static const int _maxIterations = 5000000;
  static const int _fkBytes = 32;
  static const int _ivBytes = 12;
  static const int _filesMax = 5;
  static const String _hkdfSalt = 'asvsj-chat-v1';
  static const String _frankPrefix = 'asvsj-frank-v1';

  // ---------------------------------------------------------------- Mật khẩu khôi phục, khóa định danh

  /// Chuẩn hóa NFC: "ở" gõ dựng sẵn hay tổ hợp đều là cùng một mật khẩu.
  static String normalise(String passphrase) => unorm.nfc(passphrase);

  /// Kiểm tra mật khẩu khôi phục mới; null khi hợp lệ.
  static String? checkNewPassphrase(String passphrase) => normalise(passphrase).runes.length < passphraseMinLength
      ? 'Mật khẩu khôi phục cần ít nhất $passphraseMinLength ký tự.'
      : null;

  /// Mở bản sao lưu [backup] bằng [passphrase]. Sai mật khẩu: [WrongPassphraseException]; bản sao lưu hỏng hoặc
  /// không khớp khóa công khai: [ChatCryptoException].
  Future<ChatIdentity> unlock(ChatKeyBackup backup, String passphrase) async {
    final phrase = normalise(passphrase);
    if (phrase.isEmpty) {
      throw const WrongPassphraseException();
    }
    final Uint8List wrapped;
    final Uint8List salt;
    final Uint8List iv;
    try {
      wrapped = fromBase64(backup.wrappedPrivateKey);
      salt = fromBase64(backup.wrapSalt);
      iv = fromBase64(backup.wrapIv);
    } on FormatException {
      throw const ChatCryptoException(_badBackup);
    }
    final iterations = backup.wrapIterations;
    if (wrapped.length < 16 ||
        wrapped.length > 600 ||
        salt.length < 16 ||
        salt.length > 64 ||
        iv.length != _ivBytes ||
        iterations < _minIterations ||
        iterations > _maxIterations) {
      throw const ChatCryptoException(_badBackup);
    }
    final privateKey = await _unwrapIn(_run, phrase, wrapped, salt, iv, iterations, backup.publicKey);
    return ChatIdentity(keyId: backup.id, publicKey: backup.publicKey, privateKey: privateKey);
  }

  /// Một khóa định danh mới cho [passphrase] (ít nhất [passphraseMinLength] ký tự).
  Future<ChatNewKey> createKey(String passphrase, {int iterations = wrapIterations}) {
    final error = checkNewPassphrase(passphrase);
    if (error != null) {
      throw ChatCryptoException(error);
    }
    return _createIn(_run, normalise(passphrase), iterations);
  }

  // Hai hàm tĩnh này tạo closure gửi sang Isolate: không có `this`, chỉ giữ chuỗi, số và byte.
  static Future<Uint8List> _unwrapIn(
    ChatCryptoRunner run,
    String phrase,
    Uint8List wrapped,
    Uint8List salt,
    Uint8List iv,
    int iterations,
    String publicKey,
  ) => run(() => _unwrap(phrase, wrapped, salt, iv, iterations, publicKey));

  static Future<ChatNewKey> _createIn(ChatCryptoRunner run, String phrase, int iterations) =>
      run(() => _create(phrase, iterations));

  static const String _badBackup = 'Bản sao lưu khóa mã hóa không hợp lệ.';

  static Uint8List _unwrap(
    String phrase,
    Uint8List wrapped,
    Uint8List salt,
    Uint8List iv,
    int iterations,
    String publicKey,
  ) {
    final wrapKey = pbkdf2Sha256(Uint8List.fromList(utf8.encode(phrase)), salt, iterations);
    final Uint8List pkcs8;
    try {
      pkcs8 = _aesGcm(false, wrapKey, iv, wrapped, null);
    } catch (_) {
      throw const WrongPassphraseException();
    } finally {
      wrapKey.fillRange(0, wrapKey.length, 0);
    }
    try {
      final d = _privateKeyOf(pkcs8);
      final expected = _publicKeyBytes(publicKey);
      if (!_sameBytes(_publicPointOf(d), expected)) {
        throw const ChatCryptoException('Bản sao lưu khóa mã hóa không khớp với khóa công khai.');
      }
      return d;
    } finally {
      pkcs8.fillRange(0, pkcs8.length, 0);
    }
  }

  static ChatNewKey _create(String phrase, int iterations) {
    final d = _randomScalar();
    final point = _publicPointOf(d);
    final pkcs8 = _pkcs8Of(d, point);
    try {
      final salt = randomBytes(16);
      final iv = randomBytes(_ivBytes);
      final wrapKey = pbkdf2Sha256(Uint8List.fromList(utf8.encode(phrase)), salt, iterations);
      final wrapped = _aesGcm(true, wrapKey, iv, pkcs8, null);
      wrapKey.fillRange(0, wrapKey.length, 0);
      return ChatNewKey(
        publicKey: base64Encode(point),
        wrappedPrivateKey: base64Encode(wrapped),
        wrapSalt: base64Encode(salt),
        wrapIv: base64Encode(iv),
        wrapIterations: iterations,
        privateKey: d,
      );
    } finally {
      pkcs8.fillRange(0, pkcs8.length, 0);
    }
  }

  // ---------------------------------------------------------------- Khóa của cuộc trò chuyện

  /// Khóa AES-256 của các tin giữa hai khóa [keyIdA], [keyIdB] trong cuộc trò chuyện [conversationId] (thứ tự không
  /// quan trọng): ECDH(khóa bí mật của mình, khóa công khai của người kia) → HKDF-SHA256. Hai bên ra cùng một khóa.
  Future<Uint8List> conversationKey(
    Uint8List privateKey,
    String peerPublicKey,
    int conversationId,
    int keyIdA,
    int keyIdB,
  ) => _conversationIn(_run, privateKey, peerPublicKey, conversationId, keyIdA, keyIdB);

  static Future<Uint8List> _conversationIn(
    ChatCryptoRunner run,
    Uint8List privateKey,
    String peerPublicKey,
    int conversationId,
    int keyIdA,
    int keyIdB,
  ) => run(() => _conversationKey(privateKey, peerPublicKey, conversationId, keyIdA, keyIdB));

  static Uint8List _conversationKey(
    Uint8List privateKey,
    String peerPublicKey,
    int conversationId,
    int keyIdA,
    int keyIdB,
  ) {
    final shared = _ecdh(privateKey, _publicKeyBytes(peerPublicKey));
    try {
      final info = 'conv:$conversationId:${min(keyIdA, keyIdB)}:${max(keyIdA, keyIdB)}';
      return _hkdf(shared, _utf8(_hkdfSalt), _utf8(info));
    } finally {
      shared.fillRange(0, shared.length, 0);
    }
  }

  // ---------------------------------------------------------------- Tin nhắn

  /// Mã hóa một tin. Nội dung rỗng hoặc tệp sai dạng: [ChatCryptoException].
  ChatSealed encrypt({
    required Uint8List key,
    required int conversationId,
    required int senderId,
    required int senderKeyId,
    required int recipientKeyId,
    required ChatBody body,
  }) {
    final plaintext = _encodeBody(body);
    if (_fkBytes + plaintext.length + 16 > maxCiphertextBytes) {
      throw const ChatCryptoException('Tin nhắn quá dài.');
    }
    final fk = randomBytes(_fkBytes);
    final iv = randomBytes(_ivBytes);
    final aad = _aad(conversationId, senderId, senderKeyId, recipientKeyId);
    final ciphertext = _aesGcm(true, key, iv, _concat([fk, plaintext]), aad);
    return ChatSealed(
      envelope: ChatEnvelope(
        ciphertext: base64Encode(ciphertext),
        iv: base64Encode(iv),
        senderKeyId: senderKeyId,
        recipientKeyId: recipientKeyId,
        frankingTag: frankingTag(fk, conversationId, senderId, plaintext),
      ),
      frankingKey: base64Encode(fk),
      plaintext: base64Encode(plaintext),
      body: _decodeBody(plaintext),
    );
  }

  /// Giải mã phong bì [envelope] do [senderId] viết (id của mình khi là tin của mình). Không đọc được:
  /// [UnreadableMessageException].
  ChatOpened decrypt({
    required Uint8List key,
    required int conversationId,
    required int senderId,
    required ChatEnvelope envelope,
  }) {
    final Uint8List sealed;
    try {
      final iv = fromBase64(envelope.iv);
      if (iv.length != _ivBytes) {
        throw const UnreadableMessageException();
      }
      final aad = _aad(conversationId, senderId, envelope.senderKeyId, envelope.recipientKeyId);
      sealed = _aesGcm(false, key, iv, fromBase64(envelope.ciphertext), aad);
    } catch (_) {
      throw const UnreadableMessageException();
    }
    if (sealed.length <= _fkBytes) {
      throw const UnreadableMessageException();
    }
    final fk = Uint8List.sublistView(sealed, 0, _fkBytes);
    final plaintext = Uint8List.sublistView(sealed, _fkBytes);
    // Người gửi đặt chữ này bên trong mà tag của chữ khác thì báo cáo tin này sẽ hỏng: coi như không đọc được
    if (!_sameText(frankingTag(fk, conversationId, senderId, plaintext), envelope.frankingTag)) {
      throw const UnreadableMessageException();
    }
    return ChatOpened(body: _decodeBody(plaintext), frankingKey: base64Encode(fk), plaintext: base64Encode(plaintext));
  }

  /// Hex thường của HMAC-SHA256(fk, `asvsj-frank-v1|<conversationId>|<senderId>|` ‖ P).
  static String frankingTag(Uint8List fk, int conversationId, int senderId, Uint8List plaintext) {
    final prefix = _utf8('$_frankPrefix|$conversationId|$senderId|');
    final mac = _hmac(fk, _concat([prefix, plaintext]));
    final out = StringBuffer();
    for (final b in mac) {
      out.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return out.toString();
  }

  static Uint8List _aad(int conversationId, int senderId, int senderKeyId, int recipientKeyId) =>
      _utf8('$conversationId|$senderId|$senderKeyId|$recipientKeyId');

  /// P = UTF-8 của {"v":1,"text"?,"files"?}; chữ rỗng bị bỏ, cần chữ hoặc ít nhất một tệp.
  static Uint8List _encodeBody(ChatBody body) {
    final out = <String, Object?>{'v': 1};
    final text = body.text;
    if (text != null && text.isNotEmpty) {
      out['text'] = text;
    }
    if (body.files.isNotEmpty) {
      final files = _checkFiles(body.files);
      if (files == null) {
        throw const ChatCryptoException('Tệp đính kèm của tin nhắn không hợp lệ.');
      }
      out['files'] = files;
    }
    if (!out.containsKey('text') && !out.containsKey('files')) {
      throw const ChatCryptoException('Hãy nhập tin nhắn.');
    }
    return _utf8(jsonEncode(out));
  }

  /// Nội dung trong P, kiểm chặt như lúc viết (chỉ người kia viết ra nó).
  static ChatBody _decodeBody(Uint8List plaintext) {
    final Object? parsed;
    try {
      parsed = jsonDecode(const Utf8Decoder(allowMalformed: false).convert(plaintext));
    } on FormatException {
      throw const UnreadableMessageException();
    }
    if (parsed is! Map || parsed['v'] != 1) {
      throw const UnreadableMessageException();
    }
    final text = parsed['text'];
    if (text != null && text is! String) {
      throw const UnreadableMessageException();
    }
    final files = parsed['files'] == null ? const <Map<String, Object?>>[] : _checkFiles(parsed['files']);
    if (files == null) {
      throw const UnreadableMessageException();
    }
    return ChatBody(text: text as String?, files: files);
  }

  static const Map<String, List<String>> _fileTypes = {
    'IMAGE': ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
    'VIDEO': ['video/mp4', 'video/quicktime', 'video/webm'],
    'AUDIO': ['audio/webm', 'audio/ogg', 'audio/mp4', 'audio/mpeg', 'audio/aac', 'audio/wav'],
  };
  static final RegExp _mimeParams = RegExp(r'^[a-z0-9=.,+" -]*$', caseSensitive: false);

  /// Các tệp chỉ với trường đã biết, hoặc null khi một tệp sai dạng hay cách trộn không được phép (1–5 ảnh, hoặc một
  /// video, hoặc một ghi âm).
  static List<Map<String, Object?>>? _checkFiles(Object? list) {
    if (list is! List || list.length > _filesMax) {
      return null;
    }
    final files = <Map<String, Object?>>[];
    for (final f in list) {
      final entry = _checkFile(f);
      if (entry == null) {
        return null;
      }
      files.add(entry);
    }
    final kinds = {for (final f in files) f['kind']};
    if (kinds.length > 1 || (files.length > 1 && !kinds.contains('IMAGE'))) {
      return null;
    }
    return files;
  }

  static Map<String, Object?>? _checkFile(Object? f) {
    if (f is! Map) {
      return null;
    }
    final kind = f['kind'];
    final mime = f['mime'];
    final id = f['id'];
    final size = f['size'];
    final key = f['key'];
    final iv = f['iv'];
    if (kind is! String ||
        !_fileTypes.containsKey(kind) ||
        mime is! String ||
        !_allowedMime(kind, mime) ||
        id is! int ||
        id < 0 ||
        size is! int ||
        size < 0 ||
        key is! String ||
        iv is! String) {
      return null;
    }
    try {
      if (fromBase64(key).length != 32 || fromBase64(iv).length != _ivBytes) {
        return null;
      }
    } on FormatException {
      return null;
    }
    final entry = <String, Object?>{'id': id, 'kind': kind, 'mime': mime, 'size': size, 'key': key, 'iv': iv};
    for (final name in ['w', 'h']) {
      final v = f[name];
      if (v != null) {
        if (v is! int || v <= 0 || v > 100000) {
          return null;
        }
        entry[name] = v;
      }
    }
    final dur = f['dur'];
    if (dur != null) {
      if (dur is! num || !dur.isFinite || dur < 0 || dur > 3600) {
        return null;
      }
      entry['dur'] = dur;
    }
    return entry;
  }

  static bool _allowedMime(String kind, String mime) {
    if (mime.length > 120) {
      return false;
    }
    final cut = mime.indexOf(';');
    final type = (cut < 0 ? mime : mime.substring(0, cut)).trim().toLowerCase();
    return _fileTypes[kind]!.contains(type) && (cut < 0 || _mimeParams.hasMatch(mime.substring(cut + 1)));
  }

  // ---------------------------------------------------------------- base64

  static final RegExp _base64 = RegExp(r'^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$');

  /// Base64 chuẩn có dấu `=`, giải mã chặt như web (không nhận khoảng trắng, thiếu dấu `=`).
  static Uint8List fromBase64(String text) {
    if (!_base64.hasMatch(text)) {
      throw const FormatException('Not standard base64');
    }
    return base64Decode(text);
  }

  // ---------------------------------------------------------------- P-256

  static final ECDomainParameters _p256 = ECDomainParameters('secp256r1');
  static final BigInt _p = BigInt.parse('ffffffff00000001000000000000000000000000ffffffffffffffffffffffff', radix: 16);
  static final BigInt _b = BigInt.parse('5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b', radix: 16);
  static final BigInt _n = BigInt.parse('ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551', radix: 16);

  /// 65 byte của điểm P-256 không nén (0x04 ‖ x ‖ y) nằm trên đường cong, hoặc [ChatCryptoException].
  static Uint8List _publicKeyBytes(String value) {
    Uint8List point;
    try {
      point = fromBase64(value);
    } on FormatException {
      throw const ChatCryptoException('Khóa công khai không hợp lệ.');
    }
    if (point.length != 65 || point[0] != 4) {
      throw const ChatCryptoException('Khóa công khai không hợp lệ.');
    }
    final x = _toBig(Uint8List.sublistView(point, 1, 33));
    final y = _toBig(Uint8List.sublistView(point, 33, 65));
    // y² = x³ − 3x + b (mod p): không nhận điểm ngoài đường cong (tấn công đường cong giả)
    final onCurve = x < _p && y < _p && (y * y - (x * x * x - BigInt.from(3) * x + _b)) % _p == BigInt.zero;
    if (!onCurve) {
      throw const ChatCryptoException('Khóa công khai không hợp lệ.');
    }
    return point;
  }

  static Uint8List _publicPointOf(Uint8List d) {
    final q = _p256.G * _toBig(d);
    if (q == null || q.isInfinity) {
      throw const ChatCryptoException('Khóa bí mật không hợp lệ.');
    }
    return q.getEncoded(false);
  }

  /// Hoành độ x (32 byte) của d · Q, đúng như WebCrypto deriveBits(ECDH, 256).
  static Uint8List _ecdh(Uint8List d, Uint8List point) {
    final x = _toBig(Uint8List.sublistView(point, 1, 33));
    final y = _toBig(Uint8List.sublistView(point, 33, 65));
    final shared = _p256.curve.createPoint(x, y) * _toBig(d);
    if (shared == null || shared.isInfinity || shared.x == null) {
      throw const UnreadableMessageException();
    }
    return _fromBig(shared.x!.toBigInteger()!, 32);
  }

  static Uint8List _randomScalar() {
    while (true) {
      final d = randomBytes(32);
      final value = _toBig(d);
      if (value > BigInt.zero && value < _n) {
        return d;
      }
    }
  }

  // PKCS8 của khóa EC P-256 đúng như Chrome xuất (WebCrypto exportKey "pkcs8"), có kèm khóa công khai.
  static final Uint8List _pkcs8Head = Uint8List.fromList([
    0x30, 0x81, 0x87, 0x02, 0x01, 0x00, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01, //
    0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x04, 0x6d, 0x30, 0x6b, 0x02, 0x01, 0x01, //
    0x04, 0x20,
  ]);
  static final Uint8List _pkcs8Mid = Uint8List.fromList([0xa1, 0x44, 0x03, 0x42, 0x00]);
  static final Uint8List _oidEcPublicKey = Uint8List.fromList([0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02, 0x01]);
  static final Uint8List _oidP256 = Uint8List.fromList([0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07]);

  static Uint8List _pkcs8Of(Uint8List d, Uint8List point) => _concat([_pkcs8Head, d, _pkcs8Mid, point]);

  /// Số d trong PKCS8 (PrivateKeyInfo → ECPrivateKey) của một khóa P-256.
  static Uint8List _privateKeyOf(Uint8List pkcs8) {
    try {
      final top = _der(pkcs8, 0, pkcs8.length);
      if (top.length != 1 || top[0].tag != 0x30) {
        throw const FormatException();
      }
      final info = _der(pkcs8, top[0].start, top[0].end);
      if (info.length < 3 || info[0].tag != 0x02 || info[1].tag != 0x30 || info[2].tag != 0x04) {
        throw const FormatException();
      }
      final algorithm = _der(pkcs8, info[1].start, info[1].end);
      if (algorithm.length != 2 ||
          !_sameBytes(Uint8List.sublistView(pkcs8, algorithm[0].start, algorithm[0].end), _oidEcPublicKey) ||
          !_sameBytes(Uint8List.sublistView(pkcs8, algorithm[1].start, algorithm[1].end), _oidP256)) {
        throw const FormatException();
      }
      final inner = _der(pkcs8, info[2].start, info[2].end);
      if (inner.length != 1 || inner[0].tag != 0x30) {
        throw const FormatException();
      }
      final ec = _der(pkcs8, inner[0].start, inner[0].end);
      if (ec.length < 2 || ec[0].tag != 0x02 || ec[1].tag != 0x04 || ec[1].end - ec[1].start > 32) {
        throw const FormatException();
      }
      final d = Uint8List(32)..setRange(32 - (ec[1].end - ec[1].start), 32, pkcs8, ec[1].start);
      final value = _toBig(d);
      if (value <= BigInt.zero || value >= _n) {
        throw const FormatException();
      }
      return d;
    } on FormatException {
      throw const ChatCryptoException(_badBackup);
    } on RangeError {
      throw const ChatCryptoException(_badBackup);
    }
  }

  /// Các phần tử DER (tag, vị trí nội dung) nằm liền nhau trong bytes[start, end).
  static List<({int tag, int start, int end})> _der(Uint8List bytes, int start, int end) {
    final out = <({int tag, int start, int end})>[];
    var i = start;
    while (i < end) {
      final tag = bytes[i++];
      var length = bytes[i++];
      if (length & 0x80 != 0) {
        final count = length & 0x7f;
        if (count == 0 || count > 2) {
          throw const FormatException();
        }
        length = 0;
        for (var k = 0; k < count; k++) {
          length = (length << 8) | bytes[i++];
        }
      }
      if (i + length > end) {
        throw const FormatException();
      }
      out.add((tag: tag, start: i, end: i + length));
      i += length;
    }
    return out;
  }

  // ---------------------------------------------------------------- AES-GCM, HMAC, HKDF, PBKDF2

  static Uint8List _aesGcm(bool encrypt, Uint8List key, Uint8List iv, Uint8List data, Uint8List? aad) {
    final cipher = GCMBlockCipher(AESEngine())
      ..init(encrypt, AEADParameters(KeyParameter(key), 128, iv, aad ?? Uint8List(0)));
    return cipher.process(data);
  }

  static Uint8List _hmac(Uint8List key, Uint8List data) =>
      (HMac(SHA256Digest(), 64)..init(KeyParameter(key))).process(data);

  /// HKDF-SHA256 lấy 32 byte (một khối T(1)).
  static Uint8List _hkdf(Uint8List ikm, Uint8List salt, Uint8List info) {
    final prk = _hmac(salt, ikm);
    return _hmac(
      prk,
      _concat([
        info,
        Uint8List.fromList([1]),
      ]),
    );
  }

  static const List<int> _sha256Init = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19, //
  ];
  static final Uint32List _k = Uint32List.fromList(const [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, //
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, //
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, //
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, //
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, //
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, //
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, //
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2, //
  ]);
  static const int _mask = 0xffffffff;

  /// PBKDF2-HMAC-SHA256 lấy 32 byte. Tự viết thay cho thư viện vì 600.000 vòng phải xong trong vài giây trên điện
  /// thoại: trạng thái SHA-256 sau khối ipad / opad được tính một lần, mỗi vòng chỉ còn hai lần nén.
  static Uint8List pbkdf2Sha256(Uint8List password, Uint8List salt, int iterations) {
    final key = password.length > 64 ? SHA256Digest().process(password) : password;
    final ipad = Uint8List(64);
    final opad = Uint8List(64);
    for (var i = 0; i < 64; i++) {
      final k = i < key.length ? key[i] : 0;
      ipad[i] = k ^ 0x36;
      opad[i] = k ^ 0x5c;
    }
    final w = Uint32List(64);
    final innerStart = Uint32List.fromList(_sha256Init);
    _loadBlock(w, ipad);
    _compress(innerStart, w);
    final outerStart = Uint32List.fromList(_sha256Init);
    _loadBlock(w, opad);
    _compress(outerStart, w);

    // U1 = HMAC(P, salt ‖ INT(1))
    final first = _hmac(
      password,
      _concat([
        salt,
        Uint8List.fromList([0, 0, 0, 1]),
      ]),
    );
    final u = Uint32List(8);
    for (var j = 0; j < 8; j++) {
      u[j] = (first[j * 4] << 24) | (first[j * 4 + 1] << 16) | (first[j * 4 + 2] << 8) | first[j * 4 + 3];
    }
    final t = Uint32List.fromList(u);
    final h = Uint32List(8);
    // Khối của một thông điệp 32 byte sau 64 byte pad: dữ liệu ‖ 0x80 ‖ 0… ‖ độ dài 768 bit
    for (var j = 9; j < 15; j++) {
      w[j] = 0;
    }
    for (var i = 1; i < iterations; i++) {
      h.setAll(0, innerStart);
      for (var j = 0; j < 8; j++) {
        w[j] = u[j];
      }
      w[8] = 0x80000000;
      w[15] = 768;
      _compress(h, w);
      for (var j = 0; j < 8; j++) {
        w[j] = h[j];
      }
      w[8] = 0x80000000;
      w[15] = 768;
      h.setAll(0, outerStart);
      _compress(h, w);
      for (var j = 0; j < 8; j++) {
        u[j] = h[j];
        t[j] ^= h[j];
      }
    }
    final out = Uint8List(32);
    for (var j = 0; j < 8; j++) {
      out[j * 4] = t[j] >> 24;
      out[j * 4 + 1] = (t[j] >> 16) & 0xff;
      out[j * 4 + 2] = (t[j] >> 8) & 0xff;
      out[j * 4 + 3] = t[j] & 0xff;
    }
    return out;
  }

  static void _loadBlock(Uint32List w, Uint8List block) {
    for (var j = 0; j < 16; j++) {
      w[j] = (block[j * 4] << 24) | (block[j * 4 + 1] << 16) | (block[j * 4 + 2] << 8) | block[j * 4 + 3];
    }
  }

  /// Một lần nén SHA-256: h ← nén(h, w[0..15]); w[16..63] dùng làm chỗ nháp.
  static void _compress(Uint32List h, Uint32List w) {
    for (var t = 16; t < 64; t++) {
      final x = w[t - 15];
      final y = w[t - 2];
      final s0 = ((x >> 7) | (x << 25)) ^ ((x >> 18) | (x << 14)) ^ (x >> 3);
      final s1 = ((y >> 17) | (y << 15)) ^ ((y >> 19) | (y << 13)) ^ (y >> 10);
      w[t] = (w[t - 16] + s0 + w[t - 7] + s1) & _mask;
    }
    var a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7];
    for (var t = 0; t < 64; t++) {
      final s1 = (((e >> 6) | (e << 26)) ^ ((e >> 11) | (e << 21)) ^ ((e >> 25) | (e << 7))) & _mask;
      final ch = (e & f) ^ (~e & g & _mask);
      final t1 = (hh + s1 + ch + _k[t] + w[t]) & _mask;
      final s0 = (((a >> 2) | (a << 30)) ^ ((a >> 13) | (a << 19)) ^ ((a >> 22) | (a << 10))) & _mask;
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final t2 = (s0 + maj) & _mask;
      hh = g;
      g = f;
      f = e;
      e = (d + t1) & _mask;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & _mask;
    }
    h[0] = (h[0] + a) & _mask;
    h[1] = (h[1] + b) & _mask;
    h[2] = (h[2] + c) & _mask;
    h[3] = (h[3] + d) & _mask;
    h[4] = (h[4] + e) & _mask;
    h[5] = (h[5] + f) & _mask;
    h[6] = (h[6] + g) & _mask;
    h[7] = (h[7] + hh) & _mask;
  }

  // ---------------------------------------------------------------- Tiện ích

  static final Random _random = Random.secure();

  static Uint8List randomBytes(int n) {
    final out = Uint8List(n);
    for (var i = 0; i < n; i++) {
      out[i] = _random.nextInt(256);
    }
    return out;
  }

  static Uint8List _utf8(String text) => Uint8List.fromList(utf8.encode(text));

  static Uint8List _concat(List<Uint8List> parts) {
    final out = Uint8List(parts.fold(0, (sum, p) => sum + p.length));
    var at = 0;
    for (final p in parts) {
      out.setAll(at, p);
      at += p.length;
    }
    return out;
  }

  static BigInt _toBig(Uint8List bytes) {
    var value = BigInt.zero;
    for (final b in bytes) {
      value = (value << 8) | BigInt.from(b);
    }
    return value;
  }

  static Uint8List _fromBig(BigInt value, int length) {
    final out = Uint8List(length);
    var v = value;
    for (var i = length - 1; i >= 0; i--) {
      out[i] = (v & BigInt.from(0xff)).toInt();
      v = v >> 8;
    }
    return out;
  }

  static bool _sameBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  /// So hai chuỗi trong thời gian không phụ thuộc chỗ khác nhau.
  static bool _sameText(String a, String b) {
    if (a.length != b.length) {
      return false;
    }
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
