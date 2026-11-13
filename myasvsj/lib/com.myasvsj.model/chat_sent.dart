import 'package:myasvsj/com.myasvsj.model/chat_message.dart';
import 'package:myasvsj/com.myasvsj.model/chat_status.dart';

/// Kết quả gửi một tin (Sent của web): cuộc trò chuyện (tạo mới khi là tin đầu tiên), tin đã lưu, trạng thái mới.
///
/// JSON: `{conversationId, message, status}`.
class ChatSent {
  const ChatSent({required this.conversationId, required this.message, required this.status});

  final int conversationId;
  final ChatMessage message;
  final ChatStatus status;

  factory ChatSent.fromJson(Map<String, dynamic> json) => ChatSent(
    conversationId: json['conversationId'] as int,
    message: ChatMessage.fromJson(json['message'] as Map<String, dynamic>),
    status: ChatStatus.fromJson(json['status'] as Map<String, dynamic>),
  );
}
