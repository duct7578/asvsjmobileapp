import 'package:myasvsj/com.myasvsj.model/app_notification.dart';

/// Một trang của danh sách "Thông báo": `{items, hasMore, unread}` (NotificationPage của web, 20 thông báo một trang,
/// mới nhất trước).
class NotificationPage {
  const NotificationPage({this.items = const [], this.hasMore = false, this.unread = 0});

  final List<AppNotification> items;

  /// Còn trang sau để tải thêm.
  final bool hasMore;

  /// Số thông báo chưa đọc của người dùng (tất cả các trang).
  final int unread;

  factory NotificationPage.fromJson(Map<String, dynamic> json) => NotificationPage(
    items: AppNotification.listFrom(json['items']),
    hasMore: (json['hasMore'] ?? false) as bool,
    unread: (json['unread'] ?? 0) as int,
  );
}
