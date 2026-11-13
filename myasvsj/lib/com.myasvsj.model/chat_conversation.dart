import 'package:myasvsj/com.myasvsj.model/chat_message.dart';
import 'package:myasvsj/com.myasvsj.model/chat_peer.dart';
import 'package:myasvsj/com.myasvsj.model/chat_status.dart';
import 'package:myasvsj/com.myasvsj.model/report_reason.dart';

/// Một cuộc trò chuyện đang mở: người kia, các tin mới nhất (cũ trước), điều người xem làm được (Conversation của web).
///
/// JSON: `{id, peer, status, messages, hasOlder, reportReasons, limits: {messageMax, pendingMax, editMinutes, …},
/// serverTime}`.
class ChatConversation {
  const ChatConversation({
    this.id,
    required this.peer,
    required this.status,
    this.messages = const [],
    this.hasOlder = false,
    this.reportReasons = const [],
    this.messageMax = 2000,
    this.editMinutes = 15,
    this.serverTime,
  });

  /// null khi mở với một thành viên chưa từng nhắn: cuộc trò chuyện được tạo bởi tin đầu tiên.
  final int? id;
  final ChatPeer peer;
  final ChatStatus status;

  /// Tin nhắn, cũ trước.
  final List<ChatMessage> messages;

  /// Còn tin cũ hơn ("Xem tin cũ hơn").
  final bool hasOlder;

  /// Lý do báo cáo tin nhắn.
  final List<ReportReason> reportReasons;

  /// Số ký tự tối đa của một tin (2.000).
  final int messageMax;

  /// Sửa được tin trong bao nhiêu phút sau khi gửi (15).
  final int editMinutes;

  /// Giờ của server lúc trả lời, gửi lại làm `changedSince` khi hỏi cập nhật (đồng hồ máy có thể sai).
  final String? serverTime;

  ChatConversation copyWith({
    int? id,
    ChatStatus? status,
    List<ChatMessage>? messages,
    bool? hasOlder,
    String? serverTime,
  }) => ChatConversation(
    id: id ?? this.id,
    peer: peer,
    status: status ?? this.status,
    messages: messages ?? this.messages,
    hasOlder: hasOlder ?? this.hasOlder,
    reportReasons: reportReasons,
    messageMax: messageMax,
    editMinutes: editMinutes,
    serverTime: serverTime ?? this.serverTime,
  );

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    final limits = json['limits'] as Map<String, dynamic>? ?? const {};
    return ChatConversation(
      id: json['id'] as int?,
      peer: ChatPeer.fromJson(json['peer'] as Map<String, dynamic>),
      status: ChatStatus.fromJson(json['status'] as Map<String, dynamic>),
      messages: ChatMessage.listFrom(json['messages']),
      hasOlder: (json['hasOlder'] ?? false) as bool,
      reportReasons: ReportReason.listFrom(json['reportReasons']),
      messageMax: (limits['messageMax'] ?? 2000) as int,
      editMinutes: (limits['editMinutes'] ?? 15) as int,
      serverTime: json['serverTime'] as String?,
    );
  }
}
