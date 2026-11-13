import 'dart:async';
import 'dart:math' as math;

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/app_notification.dart';
import 'package:myasvsj/com.myasvsj.model/notification_dao.dart';
import 'package:myasvsj/com.myasvsj.model/notification_device.dart';
import 'package:myasvsj/com.myasvsj.model/notification_page.dart';
import 'package:myasvsj/com.myasvsj.model/notification_summary.dart';

/// Thông báo mẫu (mới nhất trước), theo đúng loại và câu chữ server gửi.
List<AppNotification> sampleNotifications() => [
  AppNotification(
    id: 5,
    type: 'NEW_COMMENT',
    content: 'Trần Minh đã bình luận bài “Năm điều mình ước biết trước tuần đầu ở Tokyo” của bạn.',
    link: '/blog/1',
    createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
  ),
  AppNotification(
    id: 4,
    type: 'TAG_GRANTED',
    content: 'Bạn đã được cấp tag Mentor.',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  AppNotification(
    id: 3,
    type: 'PIN_APPROVED',
    content: 'Ghim “Tiệm giặt Sora” đã được duyệt. +15 điểm.',
    read: true,
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

/// DAO thông báo giả: giữ thông báo trong bộ nhớ, ghi lại mọi lần gọi để test kiểm tra Controller gửi gì.
class FakeNotificationDao implements NotificationDao {
  FakeNotificationDao({List<AppNotification>? stored, this.olderPage = const []})
    : stored = stored ?? sampleNotifications();

  /// Thông báo của trang đầu, mới nhất trước.
  List<AppNotification> stored;

  /// Trang thứ hai ("Xem thêm"); rỗng khi chỉ có một trang.
  List<AppNotification> olderPage;

  /// Đặt khác null để mọi lần gọi đều lỗi như server từ chối.
  ApiException? failWith;

  /// Lỗi riêng của "đánh dấu đã đọc".
  ApiException? failMarkWith;

  final List<int> pagesAsked = [];
  final List<int?> summaryAfter = [];
  final List<int?> markedUpTo = [];

  /// Lần findAll / findSummary / markRead tiếp theo chờ tới khi test hoàn tất completer này.
  Completer<void>? hold;

  int get unread => [...stored, ...olderPage].where((n) => !n.read).length;

  Future<void> _wait() async {
    final h = hold;
    if (h != null) {
      await h.future;
    }
    if (failWith != null) {
      throw failWith!;
    }
  }

  @override
  Future<NotificationPage> findAll({int page = 0}) async {
    pagesAsked.add(page);
    await _wait();
    return page == 0
        ? NotificationPage(items: List.of(stored), hasMore: olderPage.isNotEmpty, unread: unread)
        : NotificationPage(items: List.of(olderPage), unread: unread);
  }

  @override
  Future<NotificationSummary> findSummary({int? after}) async {
    summaryAfter.add(after);
    await _wait();
    final all = [...stored, ...olderPage];
    final latest = all.fold<int>(0, (top, n) => math.max(top, n.id));
    final fresh = after == null
        ? <AppNotification>[]
        : (all.where((n) => n.id > after).toList()..sort((a, b) => b.id.compareTo(a.id)));
    return NotificationSummary(unread: unread, latestId: latest, fresh: fresh.take(5).toList());
  }

  @override
  Future<int> markRead({int? upToId}) async {
    markedUpTo.add(upToId);
    await _wait();
    if (failMarkWith != null) {
      throw failMarkWith!;
    }
    stored = [for (final n in stored) upToId == null || n.id <= upToId ? n.copyWith(read: true) : n];
    olderPage = [for (final n in olderPage) upToId == null || n.id <= upToId ? n.copyWith(read: true) : n];
    return unread;
  }

  /// Server có thêm một thông báo mới (như khi ai đó bình luận bài của mình).
  void arrive(AppNotification n) => stored = [n, ...stored];
}

/// Thông báo trên máy giả: ghi lại các thông báo đã hiện, cho test bấm thử ([tap]).
class FakeNotificationDevice implements NotificationDevice {
  final List<({int id, String title, String body, String? link})> shown = [];
  final StreamController<String> _taps = StreamController<String>.broadcast();
  int permissionRequests = 0;

  /// Đường dẫn của thông báo đã mở app (một lần).
  String? launchLink;

  @override
  Stream<String> get taps => _taps.stream;

  /// Người dùng bấm một thông báo trên máy.
  void tap(String link) => _taps.add(link);

  @override
  Future<String?> takeLaunchLink() async {
    final link = launchLink;
    launchLink = null;
    return link;
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return true;
  }

  @override
  Future<void> show({required int id, required String title, required String body, String? link}) async =>
      shown.add((id: id, title: title, body: body, link: link));
}
