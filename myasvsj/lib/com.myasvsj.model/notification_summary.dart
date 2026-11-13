import 'package:myasvsj/com.myasvsj.model/app_notification.dart';

/// Điều cái chuông cần biết, đọc trong một lần: `{unread, latestId, processing, fresh}` (NotificationSummary của web).
class NotificationSummary {
  const NotificationSummary({this.unread = 0, this.latestId = 0, this.processing = 0, this.fresh = const []});

  /// Số thông báo chưa đọc.
  final int unread;

  /// id của thông báo mới nhất (0 khi chưa có).
  final int latestId;

  /// Số bài, câu hỏi, review của chính người dùng còn đang quét ảnh / video.
  final int processing;

  /// Tối đa 5 thông báo mới hơn id `after` đã hỏi, mới nhất trước (rỗng khi không hỏi `after`).
  final List<AppNotification> fresh;

  factory NotificationSummary.fromJson(Map<String, dynamic> json) => NotificationSummary(
    unread: (json['unread'] ?? 0) as int,
    latestId: (json['latestId'] ?? 0) as int,
    processing: (json['processing'] ?? 0) as int,
    fresh: AppNotification.listFrom(json['fresh']),
  );
}
