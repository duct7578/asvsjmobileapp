// Thông báo với server thật: đọc danh sách / summary, mở luồng SSE thật, tạo một thông báo (user@gmail.com bình luận
// bài của mentor@gmail.com) rồi thấy sự kiện tới, số chưa đọc tăng, thông báo hiện trên máy (giả); dọn bình luận thử.
//
//   flutter test test/live/notification_live_test.dart --dart-define=LIVE_API=http://localhost:8080
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/auth_dao.dart';
import 'package:myasvsj/com.myasvsj.model/live_dao.dart';
import 'package:myasvsj/com.myasvsj.model/live_event.dart';
import 'package:myasvsj/com.myasvsj.model/notification_dao.dart';
import 'package:myasvsj/com.myasvsj.model/user.dart';

import '../notification_fakes.dart';
import 'live_api.dart';

/// Chờ tới khi [condition] đúng (hỏi lại mỗi 100 ms), tối đa [seconds] giây.
Future<void> _until(bool Function() condition, {int seconds = 10, String reason = ''}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      fail('Hết giờ chờ: $reason');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

/// user@gmail.com bình luận một bài của [author]; server cho mỗi người một bình luận mỗi 15 giây, nên gặp giới hạn thì
/// chờ rồi thử lại một lần. Trả về (id bài, id bình luận).
Future<({int blogId, int commentId})> _commentOnBlogOf(ApiClient userApi, User author) async {
  final blogs = await userApi.get('/api/blogs', query: {'size': 30}) as Map<String, dynamic>;
  final blog = (blogs['items'] as List).cast<Map<String, dynamic>>().firstWhere(
    (b) => (b['author'] as Map<String, dynamic>?)?['id'] == author.id,
    orElse: () => throw StateError('${author.email} chưa có bài viết nào để bình luận'),
  );
  final blogId = blog['id'] as int;
  final at = DateTime.now().toIso8601String().substring(11, 19);
  final text = '[Thử app] Bình luận thử của agent thông báo lúc $at, sẽ xóa ngay.';
  Map<String, dynamic> detail;
  try {
    detail = (await userApi.post('/api/blogs/$blogId/comments', {'content': text})).data as Map<String, dynamic>;
  } on ApiException {
    await Future<void>.delayed(const Duration(seconds: 16));
    detail = (await userApi.post('/api/blogs/$blogId/comments', {'content': text})).data as Map<String, dynamic>;
  }
  final comment = (detail['comments'] as List).cast<Map<String, dynamic>>().firstWhere(
    (c) => c['mine'] == true && c['content'] == text,
  );
  return (blogId: blogId, commentId: comment['id'] as int);
}

void main() {
  test('đọc danh sách và summary của mentor@gmail.com, parse đủ trường', () async {
    final dao = NotificationDao(await liveSignedIn('mentor@gmail.com'));
    final page = await dao.findAll();
    expect(page.items, isNotEmpty);
    expect(page.items.length, lessThanOrEqualTo(NotificationDao.pageSize));
    for (final n in page.items) {
      expect(n.id, greaterThan(0));
      expect(n.type, isNotEmpty);
      expect(n.content, isNotEmpty);
      expect(n.createdAt, isNotNull);
    }
    // Mới nhất trước
    expect(page.items.first.id, greaterThanOrEqualTo(page.items.last.id));

    final summary = await dao.findSummary();
    expect(summary.latestId, page.items.first.id);
    expect(summary.unread, page.unread);
    expect(summary.fresh, isEmpty);

    final fresh = await dao.findSummary(after: 0);
    expect(fresh.fresh.length, inInclusiveRange(1, 5));

    if (page.hasMore) {
      final next = await dao.findAll(page: 1);
      expect(next.items, isNotEmpty);
    }
  }, skip: liveSkip);

  test('khách mở luồng tức thì: 401', () async {
    await expectLater(
      LiveDao(liveGuest()).open().first,
      throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
    );
  }, skip: liveSkip);

  test(
    'SSE thật: có bình luận mới → sự kiện notification → summary, chuông, thông báo trên máy, đã đọc',
    () async {
      final mentorApi = ApiClient.inMemory(liveBaseUrl);
      final mentor = await AuthDao(mentorApi).login('mentor@gmail.com', '123456');
      final userApi = await liveSignedIn('user@gmail.com');
      final dao = NotificationDao(mentorApi);

      // Luồng SSE thô
      final events = <LiveEvent>[];
      final sub = LiveDao(mentorApi).open().listen(events.add);
      // Controller dùng luồng thứ hai của cùng phiên, như app thật
      final device = FakeNotificationDevice();
      final controller = NotificationController(dao, live: LiveDao(mentorApi), device: device);
      controller.onSignedInChanged(mentor);
      ({int blogId, int commentId})? comment;
      try {
        await _until(() => events.any((e) => e.isReady), reason: 'sự kiện ready của luồng thô');
        await _until(() => controller.isLiveConnected, reason: 'Controller mở luồng');
        final before = await dao.findSummary();
        expect(controller.unreadCount, before.unread);

        comment = await _commentOnBlogOf(userApi, mentor);

        await _until(() => events.any((e) => e.isNotification), reason: 'sự kiện notification');
        await _until(() => device.shown.isNotEmpty, reason: 'thông báo trên máy');
        final shown = device.shown.last;
        expect(shown.title, 'Bình luận mới');
        expect(shown.body, contains('Trần Minh'));
        expect(shown.link, '/blog/${comment.blogId}');
        expect(controller.unreadCount, before.unread + 1);

        final summary = await dao.findSummary(after: before.latestId);
        final fresh = summary.fresh.firstWhere((n) => n.type == 'NEW_COMMENT' && n.link == '/blog/${comment!.blogId}');
        expect(fresh.read, isFalse);

        final left = await dao.markRead(upToId: fresh.id);
        expect(left, lessThan(summary.unread));
      } finally {
        // Không chờ: kết nối SSE chỉ thật sự đóng khi server gửi dòng tiếp theo (ping 25 giây)
        unawaited(sub.cancel());
        controller.dispose();
        if (comment != null) {
          await userApi.delete('/api/comments/${comment.commentId}');
        }
      }
    },
    skip: liveSkip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
