// Test NotificationDao với server giả: JSON chép từ server thật (curl http://localhost:8080/api/me/notifications…).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/notification_dao.dart';

import 'fake_api.dart';

/// GET /api/me/notifications?page=0 của mentor@gmail.com.
const _pageJson = r'''
{"success":true,"message":"OK","data":{"items":[{"id":5,"type":"NEW_COMMENT","content":"Trần Minh đã bình luận bài “Năm điều mình ước biết trước tuần đầu ở Tokyo” của bạn.","link":"/blog/1","read":false,"createdAt":"2026-11-07T18:52:45Z"},{"id":4,"type":"CONTENT_PUBLISHED","content":"Review về “Tiệm giặt Coin Laundry Sora” đã qua kiểm duyệt ảnh/video và đã được đăng. +10 điểm.","link":"/map?place=11","read":false,"createdAt":"2026-11-07T18:52:39Z"},{"id":3,"type":"CONTENT_PUBLISHED","content":"Câu hỏi “[TEST QA agent] Hỏi thử về gia hạn visa du học cần giấy tờ gì” đã qua kiểm duyệt ảnh/video và đã được đăng. +10 điểm.","link":"/qa/8","read":true,"createdAt":"2026-11-07T18:52:32Z"},{"id":2,"type":"TAG_GRANTED","content":"Bạn đã được cấp tag Mentor.","link":null,"read":true,"createdAt":"2026-11-06T10:00:00Z"}],"hasMore":true,"unread":2},"timestamp":"2026-11-07T18:52:39.022755700Z"}
''';

/// GET /api/me/notifications/summary?after=4.
const _summaryJson = r'''
{"success":true,"message":"OK","data":{"unread":3,"latestId":5,"processing":0,"fresh":[{"id":5,"type":"NEW_COMMENT","content":"Trần Minh đã bình luận bài “Năm điều mình ước biết trước tuần đầu ở Tokyo” của bạn.","link":"/blog/1","read":false,"createdAt":"2026-11-07T18:52:45Z"}]},"timestamp":"2026-11-07T18:52:51.409862Z"}
''';

/// GET /api/me/notifications/summary (không có after) của tài khoản chưa có thông báo.
const _emptySummaryJson = r'''
{"success":true,"message":"OK","data":{"unread":0,"latestId":0,"processing":0,"fresh":[]},"timestamp":"2026-11-07T18:52:09.146679400Z"}
''';

Map<String, dynamic> _json(String raw) => jsonDecode(raw) as Map<String, dynamic>;

void main() {
  test('findAll gọi GET /api/me/notifications?page= và đọc đủ các trường', () async {
    final server = FakeServer({'GET /api/me/notifications': (_) => _json(_pageJson)});
    final page = await NotificationDao(server.api).findAll(page: 1);

    final request = server.last('GET', '/api/me/notifications');
    expect(request.uri.queryParameters, {'page': '1'});
    expect(page.hasMore, isTrue);
    expect(page.unread, 2);
    expect(page.items.map((n) => n.id), [5, 4, 3, 2]);

    final comment = page.items.first;
    expect(comment.type, 'NEW_COMMENT');
    expect(comment.content, startsWith('Trần Minh đã bình luận bài'));
    expect(comment.link, '/blog/1');
    expect(comment.read, isFalse);
    expect(comment.createdAt, DateTime.utc(2026, 11, 7, 18, 52, 45).toLocal());
    expect(comment.target, '/blog/1');
    expect(comment.title, 'Bình luận mới');

    expect(page.items[1].link, '/map?place=11');
    expect(page.items[2].read, isTrue);

    final tag = page.items.last;
    expect(tag.link, isNull);
    expect(tag.isTag, isTrue);
    expect(tag.target, '/profile');
  });

  test('findSummary gửi after và đọc fresh; không có after thì không gửi tham số', () async {
    final server = FakeServer({
      'GET /api/me/notifications/summary': (req) =>
          _json(req.uri.queryParameters.containsKey('after') ? _summaryJson : _emptySummaryJson),
    });
    final dao = NotificationDao(server.api);

    final summary = await dao.findSummary(after: 4);
    expect(server.requests.last.uri.queryParameters, {'after': '4'});
    expect(summary.unread, 3);
    expect(summary.latestId, 5);
    expect(summary.processing, 0);
    expect(summary.fresh.single.id, 5);
    expect(summary.fresh.single.link, '/blog/1');

    final first = await dao.findSummary();
    expect(server.requests.last.uri.queryParameters, isEmpty);
    expect(first.latestId, 0);
    expect(first.fresh, isEmpty);
  });

  test('markRead gửi POST /api/me/notifications/read {upToId} và trả về số chưa đọc còn lại', () async {
    final server = FakeServer({
      'POST /api/me/notifications/read': (_) => apiOk({'unread': 1}),
    });
    final dao = NotificationDao(server.api);

    expect(await dao.markRead(upToId: 5), 1);
    final request = server.last('POST', '/api/me/notifications/read');
    expect(request.data, {'upToId': 5});
    expect(request.headers['X-XSRF-TOKEN'], 'csrf-test');

    await dao.markRead();
    expect(server.requests.last.data, {'upToId': null});
  });

  test('chưa đăng nhập: ném ApiException 401', () async {
    final server = FakeServer({'GET /api/me/notifications': (_) => const FakeReply(401, null)});
    await expectLater(
      NotificationDao(server.api).findAll(),
      throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
    );
  });

  test('server lỗi: ném ApiException mang câu của server', () async {
    final server = FakeServer({
      'POST /api/me/notifications/read': (_) => apiError(500, 'Server gặp lỗi. Hãy thử lại sau.'),
    });
    await expectLater(
      NotificationDao(server.api).markRead(upToId: 1),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Server gặp lỗi. Hãy thử lại sau.')),
    );
  });
}
