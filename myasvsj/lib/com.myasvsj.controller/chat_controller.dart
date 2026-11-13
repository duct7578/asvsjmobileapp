import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/chat_blocked_member.dart';
import 'package:myasvsj/com.myasvsj.model/chat_conversation.dart';
import 'package:myasvsj/com.myasvsj.model/chat_counts.dart';
import 'package:myasvsj/com.myasvsj.model/chat_crypto.dart';
import 'package:myasvsj/com.myasvsj.model/chat_dao.dart';
import 'package:myasvsj/com.myasvsj.model/chat_device_key_dao.dart';
import 'package:myasvsj/com.myasvsj.model/chat_envelope.dart';
import 'package:myasvsj/com.myasvsj.model/chat_key_dao.dart';
import 'package:myasvsj/com.myasvsj.model/chat_keyring.dart';
import 'package:myasvsj/com.myasvsj.model/chat_message.dart';
import 'package:myasvsj/com.myasvsj.model/chat_status.dart';
import 'package:myasvsj/com.myasvsj.model/conversation_item.dart';
import 'package:myasvsj/com.myasvsj.model/live_event.dart';
import 'package:myasvsj/com.myasvsj.model/notification_device.dart';
import 'package:myasvsj/com.myasvsj.model/user.dart';

/// Controller của "Tin nhắn": danh sách cuộc trò chuyện (hộp "Tin nhắn" và "Lời mời"), người đã chặn, và cuộc trò
/// chuyện đang mở (ChatScreen).
///
/// Mã hóa đầu cuối như web ([ChatKeyring]): người dùng nhập "mật khẩu khôi phục" để mở khóa ([unlockKey]) hoặc bật mã
/// hóa ([createKey]); sau đó tin mã hóa được giải mã để hiện ([display], [previewOf]), tin gửi / sửa trong hội thoại
/// mã hóa được mã hóa trước khi gửi, báo cáo tin mã hóa gửi kèm nội dung đã giải mã. Khóa đã mở được lưu an toàn
/// trên máy ([deviceKeys]) nên chỉ hỏi mật khẩu một lần mỗi máy. App chưa hiện / gửi ảnh, video, ghi âm.
///
/// Nghe sự kiện `chat` của luồng tức thì ([attachLive], lấy từ NotificationController.liveEvents): hỏi cập nhật cho
/// cuộc trò chuyện đang mở, làm mới danh sách, hiện "đang soạn tin", và hiện "Tin nhắn mới từ …" trên máy
/// ([NotificationDevice]) khi tin đến cuộc trò chuyện không mở.
///
/// Hàm tạo chỉ cần DAO, không gọi mạng hay plugin.
class ChatController extends ChangeNotifier {
  ChatController(
    this._dao, {
    NotificationDevice? device,
    this.typingShow = const Duration(seconds: 6),
    this.typingSendEvery = const Duration(seconds: 3),
    this.pollEvery = const Duration(seconds: 15),
    ChatKeyDao? keyDao,
    ChatDeviceKeyDao? deviceKeys,
    ChatCrypto? crypto,
  }) : _device = device,
       _keys = ChatKeyring(keyDao, crypto ?? ChatCrypto(), device: deviceKeys) {
    _keys.onChanged = _notify;
  }

  final ChatDao _dao;
  final NotificationDevice? _device;
  final ChatKeyring _keys;

  /// "đang soạn tin" của người kia hiện trong bao lâu sau một sự kiện typing (server giữ 6 giây).
  final Duration typingShow;

  /// Báo "đang soạn tin" cho server nhiều nhất mỗi khoảng này.
  final Duration typingSendEvery;

  /// Lưới an toàn như trang web: cuộc trò chuyện đang mở tự hỏi cập nhật mỗi khoảng này, phòng khi luồng tức thì
  /// rớt hoặc chưa nối.
  final Duration pollEvery;

  static const String inbox = ChatDao.inbox;
  static const String requests = ChatDao.requests;

  /// Lỗi gửi trong hội thoại mã hóa khi app chưa mở khóa.
  static const String lockedNotice = 'Nhập mật khẩu khôi phục để gửi tin nhắn mã hóa.';

  /// id thông báo trên máy của tin nhắn: một thông báo cho mỗi cuộc trò chuyện, không trùng id thông báo thường.
  static const int deviceIdBase = 1 << 30;

  // ----- Danh sách (ConversationListScreen)
  final Map<String, _Box> _boxes = {inbox: _Box(), requests: _Box()};

  /// Số cuộc trò chuyện có tin chưa đọc, số lời mời, tin chưa đọc mới nhất.
  ChatCounts counts = const ChatCounts();

  List<ConversationItem> conversationsOf(String box) => _box(box).items;
  bool isLoadingOf(String box) => _box(box).isLoading;
  bool isLoadingMoreOf(String box) => _box(box).isLoadingMore;
  bool hasMoreOf(String box) => _box(box).hasMore;
  String? errorOf(String box) => _box(box).error;

  // ----- Người đã chặn
  List<ChatBlockedMember> blocked = [];
  bool isLoadingBlocks = false;
  String? blocksError;

  // ----- Cuộc trò chuyện đang mở (ChatScreen)
  ChatConversation? room;
  bool isLoadingRoom = false;
  String? roomError;
  bool isLoadingOlder = false;
  bool isSending = false;

  /// Lỗi khi gửi / sửa, hiện dưới ô soạn tin (chữ vẫn giữ trong ô).
  String? sendError;

  /// Tin đang sửa (ô soạn tin chứa chữ của nó); null khi soạn tin mới.
  ChatMessage? editing;

  /// Người kia đang soạn tin.
  bool peerTyping = false;

  /// Câu thông báo của server sau một thao tác; màn hình hiện một lần bằng [takeMessage].
  String? message;

  String? _roomKey;
  Object? _roomOwner;
  int _afterId = 0;
  int _readUpTo = 0;
  bool _refreshing = false;
  bool _refreshAgain = false;
  DateTime? _typingSentAt;
  Timer? _typingTimer;
  Timer? _pollTimer;

  /// Đang mở khóa / tạo khóa (hộp thoại mật khẩu khôi phục hiện "Đang mở khóa…").
  bool keyBusy = false;
  bool _keyPrompted = false;

  User? _user;
  Stream<LiveEvent>? _liveStream;
  StreamSubscription<LiveEvent>? _liveSub;
  int _lastNotifiedId = 0;
  bool _disposed = false;

  _Box _box(String box) => _boxes[box] ?? _boxes[inbox]!;

  // ---------------------------------------------------------------- Đăng nhập, luồng tức thì

  /// Nghe luồng tức thì (NotificationController.liveEvents). Gọi lại với cùng luồng thì không làm gì.
  void attachLive(Stream<LiveEvent> events) {
    if (identical(events, _liveStream)) {
      return;
    }
    final old = _liveSub;
    if (old != null) {
      unawaited(old.cancel());
    }
    _liveStream = events;
    _liveSub = events.listen(_onLive);
  }

  /// Người đăng nhập đổi: xóa dữ liệu của người cũ; đăng nhập thì lấy mốc tin chưa đọc (không báo lại tin cũ).
  void onSignedInChanged(User? user) {
    if (user?.id == _user?.id) {
      return;
    }
    _user = user;
    for (final box in _boxes.values) {
      box.clear();
    }
    counts = const ChatCounts();
    blocked = [];
    blocksError = null;
    _lastNotifiedId = 0;
    _keyPrompted = false;
    _keys.reset(user?.id);
    _notify();
    if (user != null) {
      unawaited(_loadBaseline(user));
      unawaited(_keys.load());
    }
  }

  /// App vừa mở lại từ nền: hỏi bù cuộc trò chuyện đang mở và danh sách.
  void onAppResumed() {
    unawaited(refreshRoom());
    unawaited(_reloadLoadedLists());
  }

  Future<void> _loadBaseline(User user) async {
    try {
      final c = await _dao.findCounts();
      if (_user?.id != user.id) {
        return;
      }
      counts = c;
      _lastNotifiedId = math.max(_lastNotifiedId, c.latest?.messageId ?? 0);
      _notify();
    } on ApiException {
      // Không có mốc: tin chưa đọc mới nhất có thể được báo một lần
    }
  }

  void _onLive(LiveEvent event) {
    if (event.isReady) {
      // Luồng vừa mở lại: hỏi bù những gì có thể đã lỡ
      unawaited(refreshRoom());
      unawaited(_reloadLoadedLists());
      return;
    }
    if (!event.isChat) {
      return;
    }
    final r = room;
    final inRoom = r != null && r.id != null && r.id == event.conversationId;
    if (inRoom) {
      if (event.kind == 'typing') {
        _showPeerTyping();
      } else {
        unawaited(refreshRoom());
      }
    } else if (r != null && r.id == null && event.kind == 'message') {
      // Người kia vừa nhắn trước trong lúc mình đang mở màn hình nhắn cho họ
      unawaited(_reloadRoom());
    }
    if (event.kind != 'typing') {
      unawaited(_reloadLoadedLists());
    }
    if (event.kind == 'message' && !inRoom) {
      unawaited(_notifyNewMessage());
    }
  }

  /// Tin mới ở cuộc trò chuyện không mở: hỏi các con số, hiện "Tin nhắn mới từ …" trên máy một lần cho mỗi tin.
  Future<void> _notifyNewMessage() async {
    try {
      final c = await _dao.findCounts();
      counts = c;
      _notify();
      final latest = c.latest;
      final device = _device;
      if (device == null || latest == null || latest.messageId <= _lastNotifiedId) {
        return;
      }
      _lastNotifiedId = latest.messageId;
      if (room?.id == latest.conversationId) {
        return;
      }
      await device.show(
        id: deviceIdBase + latest.conversationId,
        title: latest.request ? '${latest.peerName} muốn nhắn tin với bạn' : 'Tin nhắn mới từ ${latest.peerName}',
        body: 'Bấm để xem tin nhắn.',
        link: '/messages/${latest.conversationId}',
      );
    } on ApiException {
      // Bỏ qua: lần sau hỏi lại
    }
  }

  // ---------------------------------------------------------------- Danh sách cuộc trò chuyện

  /// Trang đầu của hộp [box] ([inbox] hoặc [requests]); kéo xuống làm mới cũng gọi hàm này.
  Future<void> loadConversations(String box) async {
    final b = _box(box);
    b.isLoading = true;
    b.error = null;
    _notify();
    try {
      final page = await _dao.findAll(box: box);
      b.items = page.items;
      b.hasMore = page.hasMore;
      b.page = 0;
      b.loaded = true;
      counts = page.counts;
    } on ApiException catch (e) {
      b.error = e.message;
    } finally {
      b.isLoading = false;
      _notify();
    }
  }

  /// Trang sau của hộp [box] ("Xem thêm").
  Future<void> loadMoreConversations(String box) async {
    final b = _box(box);
    if (b.isLoadingMore || !b.hasMore) {
      return;
    }
    b.isLoadingMore = true;
    _notify();
    try {
      final page = await _dao.findAll(box: box, page: b.page + 1);
      final known = {for (final c in b.items) c.id};
      b.items = [...b.items, ...page.items.where((c) => !known.contains(c.id))];
      b.hasMore = page.hasMore;
      b.page++;
      counts = page.counts;
    } on ApiException catch (e) {
      message = e.message;
    } finally {
      b.isLoadingMore = false;
      _notify();
    }
  }

  /// Làm mới lặng lẽ (không vòng quay) các hộp đã tải, khi có sự kiện chat hoặc sau một thao tác.
  Future<void> _reloadLoadedLists() async {
    for (final entry in _boxes.entries) {
      final b = entry.value;
      if (!b.loaded || b.isLoading || b.reloading) {
        continue;
      }
      b.reloading = true;
      try {
        final page = await _dao.findAll(box: entry.key);
        b.items = page.items;
        b.hasMore = page.hasMore;
        b.page = 0;
        b.error = null;
        counts = page.counts;
        _notify();
      } on ApiException {
        // Giữ danh sách cũ
      } finally {
        b.reloading = false;
      }
    }
  }

  // ---------------------------------------------------------------- Người đã chặn

  Future<void> loadBlocks() async {
    isLoadingBlocks = true;
    blocksError = null;
    _notify();
    try {
      blocked = await _dao.findBlocks();
    } on ApiException catch (e) {
      blocksError = e.message;
    } finally {
      isLoadingBlocks = false;
      _notify();
    }
  }

  /// "Bỏ chặn" trong danh sách người đã chặn.
  Future<bool> unblock(ChatBlockedMember member) async {
    try {
      message = await _dao.unblock(member.peer.id);
      blocked = blocked.where((b) => b.peer.id != member.peer.id).toList();
      if (room?.peer.id == member.peer.id) {
        await _reloadRoom();
      }
      unawaited(_reloadLoadedLists());
      return true;
    } on ApiException catch (e) {
      message = e.message;
      return false;
    } finally {
      _notify();
    }
  }

  // ---------------------------------------------------------------- Cuộc trò chuyện đang mở

  static String? _keyOf(int? conversationId, int? withUserId) =>
      conversationId != null ? 'c$conversationId' : (withUserId != null ? 'u$withUserId' : null);

  /// Mở cuộc trò chuyện [conversationId], hoặc với thành viên [withUserId] (từ bài viết, bình luận).
  /// [owner] là màn hình đang hiện nó (chỉ màn hình đó đóng được, xem [closeRoom]). Mở lại cùng cuộc trò chuyện
  /// (quay về màn hình) thì tải lại mà không xóa tin đang hiện.
  Future<void> openRoom({int? conversationId, int? withUserId, Object? owner}) async {
    _roomOwner = owner;
    final key = _keyOf(conversationId, withUserId);
    if (key == null) {
      roomError = 'Không tìm thấy cuộc trò chuyện này.';
      _notify();
      return;
    }
    if (_roomKey != key) {
      _roomKey = key;
      room = null;
      editing = null;
      sendError = null;
      peerTyping = false;
      _typingTimer?.cancel();
      _afterId = 0;
      _readUpTo = 0;
    }
    isLoadingRoom = room == null;
    roomError = null;
    _pollTimer ??= Timer.periodic(pollEvery, (_) => unawaited(refreshRoom()));
    _notify();
    try {
      final loaded = conversationId != null ? await _dao.findById(conversationId) : await _dao.findWith(withUserId!);
      if (_roomKey != key) {
        return;
      }
      _setRoom(loaded);
      unawaited(_markRead());
    } on ApiException catch (e) {
      if (_roomKey == key) {
        roomError = e.message;
      }
    } finally {
      if (_roomKey == key) {
        isLoadingRoom = false;
      }
      _notify();
    }
  }

  /// Cuộc trò chuyện đang giữ ([room], [roomError]) là của màn hình [owner] (màn hình bên dưới, bị che, thì không).
  bool ownsRoom(Object owner) => identical(_roomOwner, owner);

  /// ChatScreen [owner] đóng. Màn hình khác đã mở cuộc trò chuyện sau nó (chồng lên, hoặc màn hình bên dưới vừa mở
  /// lại) thì giữ nguyên. Không gọi notifyListeners vì cây widget đang tháo.
  void closeRoom(Object owner) {
    if (!identical(_roomOwner, owner)) {
      return;
    }
    _roomOwner = null;
    _roomKey = null;
    room = null;
    roomError = null;
    editing = null;
    sendError = null;
    isLoadingRoom = false;
    peerTyping = false;
    _typingTimer?.cancel();
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _setRoom(ChatConversation loaded) {
    room = loaded;
    _keys.checkStatus(loaded.status);
    peerTyping = loaded.status.peerTyping;
    for (final m in loaded.messages) {
      _afterId = math.max(_afterId, m.id);
    }
  }

  /// Tải lại cuộc trò chuyện đang mở (sau chấp nhận, chặn, bỏ chặn).
  Future<void> _reloadRoom() async {
    final r = room;
    final key = _roomKey;
    if (r == null || key == null) {
      return;
    }
    try {
      final loaded = r.id != null ? await _dao.findById(r.id!) : await _dao.findWith(r.peer.id);
      if (_roomKey == key) {
        _setRoom(loaded);
        _notify();
      }
    } on ApiException catch (e) {
      message = e.message;
    }
  }

  /// Hỏi những gì mới trong cuộc trò chuyện đang mở (`/updates`): tin mới, tin đã sửa / thu hồi, trạng thái. Mỗi lúc
  /// chỉ một lần hỏi; có sự kiện trong lúc hỏi thì hỏi thêm một lần ngay sau.
  Future<void> refreshRoom() async {
    final id = room?.id;
    if (id == null) {
      return;
    }
    if (_refreshing) {
      _refreshAgain = true;
      return;
    }
    _refreshing = true;
    try {
      do {
        _refreshAgain = false;
        final r = room;
        if (r == null || r.id != id) {
          return;
        }
        final updates = await _dao.findUpdates(id, after: _afterId, changedSince: r.serverTime);
        final now = room;
        if (now == null || now.id != id) {
          return;
        }
        for (final m in updates.messages) {
          _afterId = math.max(_afterId, m.id);
        }
        final theirsArrived = updates.messages.any((m) => !m.mine);
        room = now.copyWith(
          messages: _merge(now.messages, [...updates.messages, ...updates.changed]),
          status: updates.status,
          serverTime: updates.serverTime,
        );
        _keys.checkStatus(updates.status);
        if (updates.status.peerTyping) {
          _showPeerTyping(notify: false);
        } else if (theirsArrived) {
          peerTyping = false;
        }
        _notify();
        unawaited(_markRead());
      } while (_refreshAgain);
    } on ApiException {
      // Thử lại ở sự kiện sau
    } finally {
      _refreshing = false;
    }
  }

  /// "Xem tin cũ hơn".
  Future<void> loadOlder() async {
    final r = room;
    final id = r?.id;
    if (r == null || id == null || !r.hasOlder || isLoadingOlder || r.messages.isEmpty) {
      return;
    }
    isLoadingOlder = true;
    _notify();
    try {
      final older = await _dao.findOlder(id, before: r.messages.first.id);
      final now = room;
      if (now != null && now.id == id) {
        room = now.copyWith(messages: _merge(now.messages, older.messages), hasOlder: older.hasOlder);
      }
    } on ApiException catch (e) {
      message = e.message;
    } finally {
      isLoadingOlder = false;
      _notify();
    }
  }

  /// Gộp [incoming] vào [current] theo id (tin cùng id được thay), sắp cũ trước.
  static List<ChatMessage> _merge(List<ChatMessage> current, List<ChatMessage> incoming) {
    final byId = {for (final m in current) m.id: m};
    for (final m in incoming) {
      byId[m.id] = m;
    }
    return byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  }

  void _replace(ChatMessage message) {
    final r = room;
    if (r != null) {
      room = r.copyWith(messages: _merge(r.messages, [message]));
    }
  }

  Future<void> _markRead() async {
    final r = room;
    final id = r?.id;
    if (r == null || id == null) {
      return;
    }
    final newest = r.messages.where((m) => !m.mine).fold<int>(0, (top, m) => math.max(top, m.id));
    if (newest <= _readUpTo) {
      return;
    }
    _readUpTo = newest;
    try {
      counts = await _dao.markRead(id, upToId: newest);
      _notify();
    } on ApiException {
      // Lần mở sau sẽ đánh dấu lại
    }
  }

  void _showPeerTyping({bool notify = true}) {
    peerTyping = true;
    _typingTimer?.cancel();
    _typingTimer = Timer(typingShow, () {
      peerTyping = false;
      _notify();
    });
    if (notify) {
      _notify();
    }
  }

  // ---------------------------------------------------------------- Gửi, sửa, thu hồi

  /// Kiểm tra trước khi gửi; null khi hợp lệ.
  static String? validate(String content, {int max = 2000}) {
    if (content.trim().isEmpty) {
      return 'Hãy nhập tin nhắn.';
    }
    if (content.trim().length > max) {
      return 'Tin nhắn tối đa $max ký tự.';
    }
    return null;
  }

  /// Gửi [text] (hoặc lưu tin đang sửa khi [editing] khác null). Trả về true khi server đã nhận; lỗi ở [sendError].
  Future<bool> sendMessage(String text) async {
    final r = room;
    if (r == null || isSending) {
      return false;
    }
    final content = text.trim();
    sendError = validate(content, max: r.messageMax);
    final edited = editing;
    final encrypted = edited != null ? edited.isEncrypted : r.status.isEncrypted;
    if (sendError == null && encrypted && keyState != ChatKeyState.ready) {
      sendError = lockedNotice;
    }
    if (sendError != null) {
      _notify();
      return false;
    }
    if (edited != null) {
      return _saveEdit(edited, content);
    }
    if (encrypted) {
      return _sendEncrypted(r, content);
    }
    isSending = true;
    _notify();
    try {
      final sent = r.id != null ? await _dao.send(r.id!, content) : await _dao.sendTo(r.peer.id, content);
      final now = room;
      if (now != null && (now.id == sent.conversationId || (now.id == null && now.peer.id == r.peer.id))) {
        room = now.copyWith(
          id: sent.conversationId,
          status: sent.status,
          messages: _merge(now.messages, [sent.message]),
        );
      }
      unawaited(_reloadLoadedLists());
      return true;
    } on ApiException catch (e) {
      sendError = e.message;
      return false;
    } finally {
      isSending = false;
      _notify();
    }
  }

  /// Gửi tin mã hóa: mã hóa bằng hai khóa hiện tại của cuộc trò chuyện. Server trả 409 (một khóa vừa đổi) thì đọc lại
  /// trạng thái, mã hóa và gửi lại một lần, như web.
  Future<bool> _sendEncrypted(ChatConversation r, String content) async {
    final id = r.id;
    if (id == null) {
      sendError = 'Cuộc trò chuyện này chưa sẵn sàng để gửi tin nhắn mã hóa.';
      _notify();
      return false;
    }
    isSending = true;
    _notify();
    try {
      final sent = await _sealed(id, r.status, ChatBody(text: content), (envelope) => _dao.sendEncrypted(id, envelope));
      final now = room;
      if (now != null && now.id == id) {
        room = now.copyWith(status: sent.result.status, messages: _merge(now.messages, [sent.result.message]));
      }
      _keys.remember(sent.result.message, sent.sealed);
      _keys.checkStatus(sent.result.status);
      unawaited(_reloadLoadedLists());
      return true;
    } on ApiException catch (e) {
      sendError = e.message;
      return false;
    } on ChatCryptoException catch (e) {
      sendError = e.message;
      return false;
    } finally {
      isSending = false;
      _notify();
    }
  }

  /// Mã hóa [body] cho [status] rồi gọi [call] với phong bì; 409 thì đọc lại trạng thái và thử thêm một lần.
  Future<({T result, ChatSealed sealed})> _sealed<T>(
    int id,
    ChatStatus status,
    ChatBody body,
    Future<T> Function(ChatEnvelope envelope) call,
  ) async {
    var current = status;
    for (var attempt = 0; ; attempt++) {
      final sealed = await _keys.seal(conversationId: id, status: current, body: body);
      try {
        return (result: await call(sealed.envelope), sealed: sealed);
      } on ApiException catch (e) {
        if (e.statusCode != 409 || attempt > 0) {
          rethrow;
        }
        final fresh = await _dao.findById(id);
        final now = room;
        if (now != null && now.id == id) {
          room = now.copyWith(status: fresh.status);
        }
        _keys.checkStatus(fresh.status);
        current = fresh.status;
        if (!current.isEncrypted) {
          rethrow;
        }
      }
    }
  }

  Future<bool> _saveEdit(ChatMessage edited, String content) async {
    final r = room;
    final id = r?.id;
    if (r == null || id == null) {
      return false;
    }
    if (content == edited.content) {
      editing = null;
      _notify();
      return true;
    }
    isSending = true;
    _notify();
    try {
      if (edited.isEncrypted) {
        // Giữ các tệp của tin, chỉ thay chữ
        final files = _keys.openedOf(edited)?.body.files ?? const <Map<String, Object?>>[];
        final saved = await _sealed(
          id,
          r.status,
          ChatBody(text: content, files: files),
          (envelope) => _dao.updateEncrypted(id, edited.id, envelope),
        );
        _keys.remember(saved.result.chatMessage, saved.sealed);
        _replace(saved.result.chatMessage);
      } else {
        final result = await _dao.update(id, edited.id, content);
        _replace(result.chatMessage);
      }
      editing = null;
      return true;
    } on ApiException catch (e) {
      sendError = e.message;
      return false;
    } on ChatCryptoException catch (e) {
      sendError = e.message;
      return false;
    } finally {
      isSending = false;
      _notify();
    }
  }

  /// Sửa được tin này: tin của mình, đã đọc được chữ (tin mã hóa: đã giải mã và app đang giữ khóa), chưa thu hồi,
  /// trong [ChatConversation.editMinutes] phút, cuộc trò chuyện chưa bị cắt (server còn giới hạn 5 lần sửa).
  bool canEdit(ChatMessage m, {DateTime? now}) {
    final r = room;
    if (r == null || r.id == null || !m.mine || m.recalled || m.content == null) {
      return false;
    }
    if (m.isEncrypted && (!m.decrypted || keyState != ChatKeyState.ready || !r.status.isEncrypted)) {
      return false;
    }
    final age = (now ?? DateTime.now()).difference(m.createdAt);
    return !r.status.isCutOff && age < Duration(minutes: r.editMinutes);
  }

  /// Thu hồi được tin này: tin của mình, chưa thu hồi (lúc nào cũng được).
  bool canRecall(ChatMessage m) => room?.id != null && m.mine && !m.recalled;

  /// Báo cáo được tin này: tin nhận được, chưa thu hồi; tin mã hóa phải đã giải mã (báo cáo gửi kèm nội dung).
  bool canReport(ChatMessage m) =>
      room?.id != null && !m.mine && !m.recalled && (!m.isEncrypted || _keys.openedOf(m) != null);

  /// "Sửa": đưa tin vào ô soạn tin.
  void startEdit(ChatMessage m) {
    if (!canEdit(m)) {
      return;
    }
    editing = m;
    sendError = null;
    _notify();
  }

  void cancelEdit() {
    editing = null;
    sendError = null;
    _notify();
  }

  /// "Thu hồi" tin của mình; cả hai người thấy "Tin nhắn đã được thu hồi".
  Future<bool> recallMessage(ChatMessage m) async {
    final id = room?.id;
    if (id == null) {
      return false;
    }
    try {
      final result = await _dao.recall(id, m.id);
      _replace(result.chatMessage);
      if (editing?.id == m.id) {
        editing = null;
      }
      message = result.message;
      unawaited(_reloadLoadedLists());
      return true;
    } on ApiException catch (e) {
      message = e.message;
      return false;
    } finally {
      _notify();
    }
  }

  /// Ô soạn tin vừa đổi: báo "đang soạn tin" cho người kia, nhiều nhất mỗi [typingSendEvery], chỉ khi hai người đã
  /// nhận lời nhắn tin với nhau.
  void onComposing({DateTime? now}) {
    final r = room;
    final id = r?.id;
    if (r == null || id == null || !r.status.canReact || editing != null) {
      return;
    }
    final at = now ?? DateTime.now();
    final last = _typingSentAt;
    if (last != null && at.difference(last) < typingSendEvery) {
      return;
    }
    _typingSentAt = at;
    unawaited(_sendTyping(id));
  }

  Future<void> _sendTyping(int id) async {
    try {
      await _dao.typing(id);
    } on ApiException {
      // Không quan trọng
    }
  }

  /// Dưới tin mới nhất của mình (khi chưa có tin trả lời sau nó): "Đã xem" hoặc "Đã gửi"; null với các tin khác.
  String? deliveryOf(ChatMessage m) {
    final r = room;
    if (r == null || r.id == null || !m.mine || m.recalled) {
      return null;
    }
    ChatMessage? lastMine;
    ChatMessage? lastTheirs;
    for (final x in r.messages) {
      if (x.mine) {
        lastMine = x;
      } else {
        lastTheirs = x;
      }
    }
    if (lastMine?.id != m.id || (lastTheirs != null && lastTheirs.id > m.id)) {
      return null;
    }
    return m.id <= r.status.peerReadUpTo ? 'Đã xem' : 'Đã gửi';
  }

  // ---------------------------------------------------------------- Lời mời, chặn, xóa, báo cáo

  /// "Chấp nhận" lời mời đang mở.
  Future<bool> acceptRequest() => _roomAction((id) => _dao.accept(id), reload: true);

  /// "Từ chối" lời mời đang mở (người gửi không được báo). Màn hình quay về danh sách khi thành công.
  Future<bool> declineRequest() => _roomAction((id) => _dao.decline(id));

  /// "Xóa cuộc trò chuyện" ở phía mình. Màn hình quay về danh sách khi thành công.
  Future<bool> deleteConversation() => _roomAction((id) => _dao.delete(id));

  /// "Chặn" người kia của cuộc trò chuyện đang mở.
  Future<bool> blockPeer() => _peerAction((peerId) => _dao.block(peerId));

  /// "Bỏ chặn" người kia của cuộc trò chuyện đang mở.
  Future<bool> unblockPeer() => _peerAction((peerId) => _dao.unblock(peerId));

  Future<bool> _roomAction(Future<String> Function(int id) action, {bool reload = false}) async {
    final id = room?.id;
    if (id == null) {
      return false;
    }
    try {
      message = await action(id);
      if (reload) {
        await _reloadRoom();
      }
      unawaited(_reloadLoadedLists());
      return true;
    } on ApiException catch (e) {
      message = e.message;
      return false;
    } finally {
      _notify();
    }
  }

  Future<bool> _peerAction(Future<String> Function(int peerId) action) async {
    final r = room;
    if (r == null) {
      return false;
    }
    try {
      message = await action(r.peer.id);
      await _reloadRoom();
      unawaited(_reloadLoadedLists());
      return true;
    } on ApiException catch (e) {
      message = e.message;
      return false;
    } finally {
      _notify();
    }
  }

  /// Báo cáo một tin nhận được với lý do [reasonId] và ghi chú [note].
  Future<bool> reportMessage(ChatMessage m, {required int reasonId, String note = ''}) async {
    final opened = m.isEncrypted ? _keys.openedOf(m) : null;
    if (m.isEncrypted && opened == null) {
      message = 'Chưa đọc được tin nhắn này nên chưa báo cáo được.';
      _notify();
      return false;
    }
    try {
      message = await _dao.report(
        m.id,
        reasonId: reasonId,
        note: note,
        plaintext: opened?.plaintext,
        frankingKey: opened?.frankingKey,
      );
      return true;
    } on ApiException catch (e) {
      message = e.message;
      return false;
    } finally {
      _notify();
    }
  }

  // ---------------------------------------------------------------- Mã hóa đầu cuối

  /// App làm được gì với tin mã hóa lúc này (chưa bật, chưa mở khóa, đã mở…).
  ChatKeyState get keyState => _keys.state;

  /// Lỗi khi tải khóa ([ChatKeyState.error]).
  String? get keyError => _keys.error;

  /// Tin [m] của cuộc trò chuyện đang mở để hiện: tin mã hóa thành bản đã giải mã hoặc câu "Đang giải mã…".
  ChatMessage display(ChatMessage m) {
    final r = room;
    final id = r?.id;
    if (!m.isEncrypted || r == null || id == null) {
      return m;
    }
    return _keys.view(m, conversationId: id, peerId: r.peer.id);
  }

  /// Tin cuối của một dòng trong danh sách, đã giải mã khi đọc được.
  ChatMessage? previewOf(ConversationItem item) {
    final last = item.lastMessage;
    if (last == null || !last.isEncrypted) {
      return last;
    }
    return _keys.view(last, conversationId: item.id, peerId: item.peer.id, short: true);
  }

  /// Hiện hộp thoại mật khẩu khôi phục một lần mỗi lần đăng nhập, khi mở một cuộc trò chuyện mã hóa mà app chưa mở
  /// khóa (sau đó người dùng bấm nút trên ô soạn tin).
  bool takeKeyPrompt() {
    if (_keyPrompted || keyState != ChatKeyState.locked || room?.status.isEncrypted != true) {
      return false;
    }
    _keyPrompted = true;
    return true;
  }

  /// Kiểm tra mật khẩu khôi phục mới và ô nhập lại; null khi hợp lệ.
  static String? validateNewPassphrase(String passphrase, String again) {
    final error = ChatCrypto.checkNewPassphrase(passphrase);
    if (error != null) {
      return error;
    }
    return passphrase == again ? null : 'Hai lần nhập mật khẩu khôi phục chưa giống nhau.';
  }

  /// "Mở khóa" bằng mật khẩu khôi phục; null khi xong (câu báo ở [message]), ngược lại câu lỗi để hiện trong hộp thoại.
  Future<String?> unlockKey(String passphrase) {
    if (passphrase.isEmpty) {
      return Future.value('Hãy nhập mật khẩu khôi phục.');
    }
    return _keyAction(() => _keys.unlock(passphrase), 'Đã mở khóa. Bạn đọc và gửi được tin nhắn mã hóa trên app này.');
  }

  /// "Bật mã hóa" (lần đầu) hoặc "Tạo khóa mới" ([replace], khi quên mật khẩu: tin mã hóa cũ không đọc được nữa).
  /// Lần đầu mà tài khoản đã có khóa ở máy khác thì trả lỗi và [keyState] thành [ChatKeyState.locked].
  Future<String?> createKey(String passphrase, String again, {bool replace = false}) {
    final invalid = validateNewPassphrase(passphrase, again);
    if (invalid != null) {
      return Future.value(invalid);
    }
    return _keyAction(
      () => _keys.create(passphrase, replace: replace),
      replace ? 'Đã tạo khóa mã hóa mới.' : 'Đã bật mã hóa đầu cuối.',
    );
  }

  /// Tải lại khóa sau khi lỗi ("Thử lại").
  Future<void> retryKey() async {
    await _keys.load();
    _notify();
  }

  Future<String?> _keyAction(Future<void> Function() action, String done) async {
    if (keyBusy) {
      return null;
    }
    keyBusy = true;
    _notify();
    try {
      await action();
      message = done;
      // Trạng thái cuộc trò chuyện (đã thành E2EE chưa) và các dòng xem trước đổi theo khóa
      await _reloadRoom();
      unawaited(_reloadLoadedLists());
      return null;
    } on ChatCryptoException catch (e) {
      return e.message;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      keyBusy = false;
      _notify();
    }
  }

  /// Lấy câu thông báo để hiện SnackBar, rồi xóa để không hiện lại lần nữa.
  String? takeMessage() {
    final text = message;
    message = null;
    return text;
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _typingTimer?.cancel();
    _pollTimer?.cancel();
    final sub = _liveSub;
    if (sub != null) {
      unawaited(sub.cancel());
    }
    super.dispose();
  }
}

/// Trạng thái một hộp thư ("Tin nhắn" hoặc "Lời mời").
class _Box {
  List<ConversationItem> items = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool reloading = false;
  bool hasMore = false;
  bool loaded = false;
  String? error;
  int page = 0;

  void clear() {
    items = [];
    isLoading = false;
    isLoadingMore = false;
    hasMore = false;
    loaded = false;
    error = null;
    page = 0;
  }
}
