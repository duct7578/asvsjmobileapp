import 'package:myasvsj/com.myasvsj.model/chat_message.dart';
import 'package:myasvsj/com.myasvsj.model/chat_status.dart';

/// Những gì mới trong cuộc trò chuyện đang mở (Updates của web): tin sau id đã có, tin vừa được sửa / thu hồi /
/// thả cảm xúc, trạng thái mới và giờ server để hỏi lần sau.
///
/// JSON: `{messages, changed, status, serverTime}`.
class ChatUpdates {
  const ChatUpdates({this.messages = const [], this.changed = const [], required this.status, this.serverTime});

  final List<ChatMessage> messages;
  final List<ChatMessage> changed;
  final ChatStatus status;
  final String? serverTime;

  factory ChatUpdates.fromJson(Map<String, dynamic> json) => ChatUpdates(
    messages: ChatMessage.listFrom(json['messages']),
    changed: ChatMessage.listFrom(json['changed']),
    status: ChatStatus.fromJson(json['status'] as Map<String, dynamic>),
    serverTime: json['serverTime'] as String?,
  );
}
