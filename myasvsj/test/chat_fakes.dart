import 'dart:async';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/chat_blocked_member.dart';
import 'package:myasvsj/com.myasvsj.model/chat_conversation.dart';
import 'package:myasvsj/com.myasvsj.model/chat_counts.dart';
import 'package:myasvsj/com.myasvsj.model/chat_dao.dart';
import 'package:myasvsj/com.myasvsj.model/chat_device_key_dao.dart';
import 'package:myasvsj/com.myasvsj.model/chat_identity.dart';
import 'package:myasvsj/com.myasvsj.model/chat_envelope.dart';
import 'package:myasvsj/com.myasvsj.model/chat_key_backup.dart';
import 'package:myasvsj/com.myasvsj.model/chat_key_dao.dart';
import 'package:myasvsj/com.myasvsj.model/chat_crypto.dart';
import 'package:myasvsj/com.myasvsj.model/chat_message.dart';
import 'package:myasvsj/com.myasvsj.model/chat_peer.dart';
import 'package:myasvsj/com.myasvsj.model/chat_sent.dart';
import 'package:myasvsj/com.myasvsj.model/chat_status.dart';
import 'package:myasvsj/com.myasvsj.model/chat_updates.dart';
import 'package:myasvsj/com.myasvsj.model/conversation_item.dart';
import 'package:myasvsj/com.myasvsj.model/conversation_page.dart';
import 'package:myasvsj/com.myasvsj.model/report_reason.dart';

const lanAnh = ChatPeer(id: 6, displayName: 'Lan Anh', tags: [(name: 'Mentor', color: '#C2456E')]);
const stranger = ChatPeer(id: 9, displayName: 'Chat Stranger');

/// Một tin nhắn mẫu; [minutesAgo] tính từ bây giờ.
ChatMessage chatMessage(int id, String text, {bool mine = false, int minutesAgo = 1, bool edited = false}) =>
    ChatMessage(
      id: id,
      mine: mine,
      content: text,
      edited: edited,
      createdAt: DateTime.now().subtract(Duration(minutes: minutesAgo)),
    );

const acceptedStatus = ChatStatus(state: 'ACCEPTED', canSend: true, canReact: true, peerReadUpTo: 1);

const requestStatus = ChatStatus(
  state: 'REQUEST',
  canSend: true,
  noticeCode: 'REQUEST',
  noticeText:
      'Chat Stranger muốn nhắn tin với bạn. Bạn có thể chấp nhận, trả lời hoặc từ chối; Chat Stranger chưa '
      'biết bạn đã đọc tin cho đến khi bạn chấp nhận.',
);

const reasons = [
  ReportReason(id: 1, label: 'Lừa đảo'),
  ReportReason(id: 2, label: 'Sai sự thật'),
  ReportReason(id: 3, label: 'Xúc phạm'),
  ReportReason(id: 4, label: 'Spam'),
];

/// Cuộc trò chuyện 1 với Lan Anh (đã nhận lời): tin 1 của mình, tin 5 của Lan Anh.
ChatConversation acceptedRoom() => ChatConversation(
  id: 1,
  peer: lanAnh,
  status: acceptedStatus,
  messages: [
    chatMessage(1, 'Chào chị, em là Minh. Em muốn hỏi về thuê nhà ở Tokyo ạ.', mine: true, minutesAgo: 5),
    chatMessage(5, 'Chào em, chị đây. Em hỏi đi.', minutesAgo: 4),
  ],
  reportReasons: reasons,
  serverTime: '2026-11-07T18:54:00Z',
);

/// Cuộc trò chuyện 2: lời mời của người lạ (3 tin).
ChatConversation requestRoom() => ChatConversation(
  id: 2,
  peer: stranger,
  status: requestStatus,
  messages: [
    chatMessage(2, 'Xin chao, tin nhan thu 1 cua nguoi la.', minutesAgo: 3),
    chatMessage(3, 'Xin chao, tin nhan thu 2 cua nguoi la.', minutesAgo: 3),
    chatMessage(4, 'Xin chao, tin nhan thu 3 cua nguoi la.', minutesAgo: 3),
  ],
  reportReasons: reasons,
  serverTime: '2026-11-07T18:54:00Z',
);

/// DAO tin nhắn giả: giữ cuộc trò chuyện trong bộ nhớ, ghi lại mọi lần gọi.
class FakeChatDao implements ChatDao {
  List<ConversationItem> inbox = [
    ConversationItem(id: 1, peer: lanAnh, lastMessage: chatMessage(5, 'Chào em, chị đây. Em hỏi đi.'), unread: 1),
  ];
  List<ConversationItem> requests = [
    ConversationItem(
      id: 2,
      peer: stranger,
      state: 'REQUEST',
      lastMessage: chatMessage(4, 'Xin chao, tin nhan thu 3 cua nguoi la.'),
      unread: 3,
    ),
  ];
  ChatCounts counts = const ChatCounts(
    unread: 2,
    requests: 1,
    latest: (conversationId: 2, messageId: 4, peerName: 'Chat Stranger', request: true),
  );
  Map<int, ChatConversation> rooms = {1: acceptedRoom(), 2: requestRoom()};
  List<ChatBlockedMember> blocks = [];

  /// Trả lời lần hỏi `/updates` tiếp theo; null: không có gì mới.
  ChatUpdates? nextUpdates;

  /// Đặt khác null để mọi lần gọi đều lỗi như server từ chối.
  ApiException? failWith;

  /// Lỗi riêng khi gửi / sửa tin.
  ApiException? failSendWith;

  /// Lần gọi tiếp theo chờ tới khi test hoàn tất completer này.
  Completer<void>? hold;

  /// Mọi lần gọi theo thứ tự, ví dụ "findById 1", "send 1 Chào".
  final List<String> calls = [];
  final List<({int conversationId, int? upToId})> reads = [];
  final List<({int messageId, int reasonId, String note, bool block})> reports = [];

  /// Nội dung đã giải mã gửi kèm mỗi báo cáo (null với tin thường).
  final List<({String? plaintext, String? frankingKey})> evidence = [];
  int nextId = 100;

  Future<void> _call(String call) async {
    calls.add(call);
    final h = hold;
    if (h != null) {
      await h.future;
    }
    if (failWith != null) {
      throw failWith!;
    }
  }

  ChatConversation _room(int id) =>
      rooms[id] ?? (throw const ApiException('Không tìm thấy cuộc trò chuyện này.', statusCode: 404));

  @override
  Future<ConversationPage> findAll({String box = ChatDao.inbox, int page = 0}) async {
    await _call('findAll $box $page');
    return ConversationPage(items: List.of(box == ChatDao.inbox ? inbox : requests), counts: counts);
  }

  @override
  Future<ChatCounts> findCounts() async {
    await _call('findCounts');
    return counts;
  }

  @override
  Future<ChatConversation> findById(int id) async {
    await _call('findById $id');
    return _room(id);
  }

  @override
  Future<ChatConversation> findWith(int userId) async {
    await _call('findWith $userId');
    for (final room in rooms.values) {
      if (room.peer.id == userId) {
        return room;
      }
    }
    return ChatConversation(
      peer: ChatPeer(id: userId, displayName: 'Hoàng'),
      status: const ChatStatus(
        canSend: true,
        noticeCode: 'NEW',
        noticeText:
            'Tin nhắn đầu tiên sẽ đến Hoàng dưới dạng lời mời. Trước khi Hoàng trả lời, bạn gửi được tối '
            'đa 3 tin nhắn.',
      ),
      reportReasons: reasons,
    );
  }

  /// Tin cũ hơn trả về cho "Xem tin cũ hơn".
  List<ChatMessage> older = [];

  @override
  Future<({List<ChatMessage> messages, bool hasOlder})> findOlder(int id, {int? before, int? limit}) async {
    await _call('findOlder $id $before');
    return (messages: older, hasOlder: false);
  }

  @override
  Future<ChatUpdates> findUpdates(int id, {int after = 0, String? changedSince}) async {
    await _call('findUpdates $id $after $changedSince');
    final next = nextUpdates;
    nextUpdates = null;
    return next ?? ChatUpdates(status: _room(id).status, serverTime: '2026-11-07T18:55:00Z');
  }

  @override
  Future<ChatSent> send(int conversationId, String content) async {
    await _call('send $conversationId $content');
    if (failSendWith != null) {
      throw failSendWith!;
    }
    return ChatSent(
      conversationId: conversationId,
      message: chatMessage(nextId++, content, mine: true, minutesAgo: 0),
      status: _room(conversationId).status,
    );
  }

  @override
  Future<ChatSent> sendTo(int userId, String content) async {
    await _call('sendTo $userId $content');
    if (failSendWith != null) {
      throw failSendWith!;
    }
    return ChatSent(
      conversationId: 50,
      message: chatMessage(nextId++, content, mine: true, minutesAgo: 0),
      status: const ChatStatus(
        state: 'ACCEPTED',
        canSend: true,
        noticeCode: 'WAITING',
        noticeText: 'Hoàng chưa nhận lời mời nhắn tin của bạn. Bạn còn gửi được 2 tin nhắn trước khi Hoàng trả lời.',
      ),
    );
  }

  @override
  Future<({String message, ChatMessage chatMessage})> update(int conversationId, int messageId, String content) async {
    await _call('update $conversationId $messageId $content');
    if (failSendWith != null) {
      throw failSendWith!;
    }
    return (message: 'Đã sửa tin nhắn.', chatMessage: chatMessage(messageId, content, mine: true, edited: true));
  }

  /// Phong bì của các tin mã hóa đã gửi / sửa, theo thứ tự.
  final List<ChatEnvelope> envelopes = [];

  /// Lần gửi / sửa tin mã hóa tiếp theo bị lỗi này (ví dụ 409 khi khóa vừa đổi), rồi trở lại bình thường.
  ApiException? failEncryptedOnceWith;

  ChatMessage _encryptedMessage(int id, ChatEnvelope envelope, {bool edited = false}) =>
      ChatMessage(id: id, mine: true, isEncrypted: true, envelope: envelope, edited: edited, createdAt: DateTime.now());

  @override
  Future<ChatSent> sendEncrypted(int conversationId, ChatEnvelope encrypted) async {
    await _call('sendEncrypted $conversationId');
    final fail = failEncryptedOnceWith;
    if (fail != null) {
      failEncryptedOnceWith = null;
      throw fail;
    }
    envelopes.add(encrypted);
    return ChatSent(
      conversationId: conversationId,
      message: _encryptedMessage(nextId++, encrypted),
      status: _room(conversationId).status,
    );
  }

  @override
  Future<({String message, ChatMessage chatMessage})> updateEncrypted(
    int conversationId,
    int messageId,
    ChatEnvelope encrypted,
  ) async {
    await _call('updateEncrypted $conversationId $messageId');
    final fail = failEncryptedOnceWith;
    if (fail != null) {
      failEncryptedOnceWith = null;
      throw fail;
    }
    envelopes.add(encrypted);
    return (message: 'Đã sửa tin nhắn.', chatMessage: _encryptedMessage(messageId, encrypted, edited: true));
  }

  @override
  Future<({String message, ChatMessage chatMessage})> recall(int conversationId, int messageId) async {
    await _call('recall $conversationId $messageId');
    return (
      message: 'Đã thu hồi tin nhắn.',
      chatMessage: ChatMessage(id: messageId, mine: true, recalled: true, createdAt: DateTime.now()),
    );
  }

  @override
  Future<ChatCounts> markRead(int conversationId, {int? upToId}) async {
    await _call('markRead $conversationId $upToId');
    reads.add((conversationId: conversationId, upToId: upToId));
    return const ChatCounts(requests: 1);
  }

  @override
  Future<void> typing(int conversationId) => _call('typing $conversationId');

  @override
  Future<String> accept(int conversationId) async {
    await _call('accept $conversationId');
    final room = _room(conversationId);
    rooms[conversationId] = room.copyWith(status: acceptedStatus);
    return 'Đã chấp nhận lời mời nhắn tin.';
  }

  @override
  Future<String> decline(int conversationId) async {
    await _call('decline $conversationId');
    return 'Đã từ chối lời mời nhắn tin.';
  }

  @override
  Future<String> delete(int conversationId) async {
    await _call('delete $conversationId');
    return 'Đã xóa cuộc trò chuyện.';
  }

  @override
  Future<String> report(
    int messageId, {
    required int reasonId,
    String note = '',
    bool block = false,
    String? plaintext,
    String? frankingKey,
  }) async {
    evidence.add((plaintext: plaintext, frankingKey: frankingKey));
    await _call('report $messageId');
    reports.add((messageId: messageId, reasonId: reasonId, note: note, block: block));
    return 'Cảm ơn bạn. Báo cáo đã được gửi.';
  }

  @override
  Future<List<ChatBlockedMember>> findBlocks() async {
    await _call('findBlocks');
    return List.of(blocks);
  }

  @override
  Future<String> block(int userId) async {
    await _call('block $userId');
    for (final entry in rooms.entries.toList()) {
      if (entry.value.peer.id == userId) {
        rooms[entry.key] = entry.value.copyWith(
          status: ChatStatus(
            state: entry.value.status.state,
            blockedByMe: true,
            noticeCode: 'BLOCKED_BY_ME',
            noticeText: 'Bạn đã chặn ${entry.value.peer.displayName}. Bỏ chặn để nhắn tin tiếp.',
          ),
        );
      }
    }
    return 'Đã chặn. Hai bạn không nhắn tin được cho nhau nữa.';
  }

  @override
  Future<String> unblock(int userId) async {
    await _call('unblock $userId');
    blocks = blocks.where((b) => b.peer.id != userId).toList();
    for (final entry in rooms.entries.toList()) {
      if (entry.value.peer.id == userId) {
        rooms[entry.key] = entry.value.copyWith(status: acceptedStatus);
      }
    }
    return 'Đã bỏ chặn.';
  }
}

/// DAO khóa mã hóa giả: giữ khóa hiện tại của tài khoản và khóa công khai của người khác trong bộ nhớ.
class FakeChatKeyDao implements ChatKeyDao {
  FakeChatKeyDao({this.mine, Map<int, String>? publicKeys}) : publicKeys = publicKeys ?? {};

  /// Khóa hiện tại của tài khoản (null: chưa bật mã hóa).
  ChatKeyBackup? mine;
  final Map<int, String> publicKeys;
  final List<String> calls = [];
  int nextKeyId = 40;

  /// Đặt khác null để mọi lần gọi đều lỗi.
  ApiException? failWith;

  void _call(String call) {
    calls.add(call);
    if (failWith != null) {
      throw failWith!;
    }
  }

  @override
  Future<ChatKeyBackup?> findMine() async {
    _call('findMine');
    return mine;
  }

  @override
  Future<ChatKeyBackup> create(ChatNewKey key) async {
    _call('create');
    final saved = ChatKeyBackup(
      id: nextKeyId++,
      publicKey: key.publicKey,
      wrappedPrivateKey: key.wrappedPrivateKey,
      wrapSalt: key.wrapSalt,
      wrapIv: key.wrapIv,
      wrapIterations: key.wrapIterations,
    );
    mine = saved;
    return saved;
  }

  @override
  Future<String> findPublicKey(int keyId) async {
    _call('findPublicKey $keyId');
    return publicKeys[keyId] ?? (throw const ApiException('Không tìm thấy khóa mã hóa này.', statusCode: 404));
  }
}

/// Nơi lưu khóa trên máy giả: giữ trong bộ nhớ, dùng chung giữa các ChatController để giả lập mở lại app.
class FakeChatDeviceKeyDao implements ChatDeviceKeyDao {
  final Map<int, ChatIdentity> saved = {};

  /// true: máy từ chối lưu (ví dụ Keystore lỗi).
  bool failSave = false;

  @override
  Future<ChatIdentity?> find(int userId) async => saved[userId];

  @override
  Future<void> save(int userId, ChatIdentity identity) async {
    if (failSave) {
      throw Exception('Keystore lỗi');
    }
    saved[userId] = identity;
  }

  @override
  Future<void> delete(int userId) async => saved.remove(userId);
}
