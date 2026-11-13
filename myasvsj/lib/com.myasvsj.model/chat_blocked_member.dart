import 'package:myasvsj/com.myasvsj.model/chat_peer.dart';

/// Một người trong danh sách "Người đã chặn" (BlockedMember của web, bảng `chat_blocks`).
///
/// JSON: `{peer, blockedAt}`.
class ChatBlockedMember {
  const ChatBlockedMember({required this.peer, this.blockedAt});

  final ChatPeer peer;
  final DateTime? blockedAt;

  factory ChatBlockedMember.fromJson(Map<String, dynamic> json) {
    final at = json['blockedAt'];
    return ChatBlockedMember(
      peer: ChatPeer.fromJson(json['peer'] as Map<String, dynamic>),
      blockedAt: at is String ? DateTime.tryParse(at)?.toLocal() : null,
    );
  }
}
