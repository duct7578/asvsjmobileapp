import 'dart:convert';

/// Một sự kiện của luồng tức thì `GET /api/me/live` (Server-Sent Events, LiveEvents.java của web).
///
/// Sự kiện chỉ mang id và loại, không bao giờ mang nội dung: app nghe xong thì gọi API thường để lấy dữ liệu.
///
/// | [type]         | [data]                                                                      |
/// |----------------|-----------------------------------------------------------------------------|
/// | `ready`        | `{}`: luồng vừa mở (mở lại), nên hỏi lại những gì có thể đã lỡ               |
/// | `notification` | `{}`: có thông báo mới                                                      |
/// | `chat`         | `{conversationId, kind, messageId?}`, kind: message, changed, read, typing, status |
/// | `ping`         | dòng chú thích `:ping` server gửi mỗi 25 giây để giữ kết nối (app tự đặt tên) |
class LiveEvent {
  const LiveEvent(this.type, [this.data = const {}]);

  static const String ready = 'ready';
  static const String notification = 'notification';
  static const String chat = 'chat';
  static const String ping = 'ping';

  final String type;
  final Map<String, dynamic> data;

  /// Sự kiện tên [type] với phần `data:` là chữ JSON; chữ hỏng thì coi như `{}` (vẫn đáng hỏi lại server).
  factory LiveEvent.parse(String type, String data) {
    Object? json;
    try {
      json = jsonDecode(data);
    } on FormatException {
      json = null;
    }
    return LiveEvent(type, json is Map<String, dynamic> ? json : const {});
  }

  bool get isChat => type == chat;
  bool get isNotification => type == notification;
  bool get isReady => type == ready;

  /// Sự kiện `chat`: message, changed, read, typing hoặc status.
  String? get kind => data['kind'] is String ? data['kind'] as String : null;

  int? get conversationId => data['conversationId'] is int ? data['conversationId'] as int : null;

  int? get messageId => data['messageId'] is int ? data['messageId'] as int : null;

  @override
  String toString() => 'LiveEvent($type, $data)';
}
