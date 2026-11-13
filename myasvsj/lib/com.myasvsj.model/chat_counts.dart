/// Các con số của tin nhắn (Counts của web): cuộc trò chuyện có tin chưa đọc, lời mời đang chờ, tin chưa đọc mới nhất.
///
/// JSON: `{unread, requests, latest: {conversationId, messageId, peerName, request, createdAt} | null}`.
class ChatCounts {
  const ChatCounts({this.unread = 0, this.requests = 0, this.latest});

  /// Số cuộc trò chuyện (cả hộp thư và lời mời) có tin chưa đọc.
  final int unread;

  /// Số lời mời nhắn tin đang chờ người xem trả lời ("Lời mời").
  final int requests;

  /// Tin chưa đọc mới nhất, để báo "Tin nhắn mới từ …" / "… muốn nhắn tin với bạn"; null khi đã đọc hết.
  final ({int conversationId, int messageId, String peerName, bool request})? latest;

  factory ChatCounts.fromJson(Map<String, dynamic> json) {
    final latest = json['latest'];
    return ChatCounts(
      unread: (json['unread'] ?? 0) as int,
      requests: (json['requests'] ?? 0) as int,
      latest: latest is Map<String, dynamic>
          ? (
              conversationId: latest['conversationId'] as int,
              messageId: latest['messageId'] as int,
              peerName: (latest['peerName'] ?? '') as String,
              request: (latest['request'] ?? false) as bool,
            )
          : null,
    );
  }
}
