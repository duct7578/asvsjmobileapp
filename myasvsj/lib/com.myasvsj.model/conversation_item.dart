import 'package:myasvsj/com.myasvsj.model/chat_message.dart';
import 'package:myasvsj/com.myasvsj.model/chat_peer.dart';

/// Một dòng của danh sách "Tin nhắn" / "Lời mời" (ConversationItem của web).
///
/// JSON: `{id, peer, state, lastMessage, unread, blockedByMe}`.
class ConversationItem {
  const ConversationItem({
    required this.id,
    required this.peer,
    this.state = 'ACCEPTED',
    this.lastMessage,
    this.unread = 0,
    this.blockedByMe = false,
  });

  final int id;
  final ChatPeer peer;

  /// ACCEPTED (hộp "Tin nhắn") hoặc REQUEST (hộp "Lời mời").
  final String state;

  /// Tin cuối cùng (chữ đã rút gọn một dòng); null khi chưa có tin nào hiện được.
  final ChatMessage? lastMessage;

  /// Số tin của người kia mà người xem chưa đọc.
  final int unread;

  final bool blockedByMe;

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    final last = json['lastMessage'];
    return ConversationItem(
      id: json['id'] as int,
      peer: ChatPeer.fromJson(json['peer'] as Map<String, dynamic>),
      state: (json['state'] ?? 'ACCEPTED') as String,
      lastMessage: last is Map<String, dynamic> ? ChatMessage.fromJson(last) : null,
      unread: (json['unread'] ?? 0) as int,
      blockedByMe: (json['blockedByMe'] ?? false) as bool,
    );
  }
}
