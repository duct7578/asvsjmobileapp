// Kiểm tra BlogDao với server web thật: gọi mọi hàm đọc, rồi chạy thật các hàm ghi an toàn
// (đăng bài thử có ảnh → sửa → thích / lưu rồi bỏ → bình luận, trả lời, sửa, xóa → xóa bài thử).
//
//   flutter test test/live/blog_live_test.dart --dart-define=LIVE_API=http://localhost:8080
//
// Báo cáo bài / bình luận KHÔNG chạy thật vì tạo hồ sơ báo cáo không xóa được (đã có test với server giả).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/blog.dart';
import 'package:myasvsj/com.myasvsj.model/blog_dao.dart';

import 'live_api.dart';

/// Ảnh PNG 120×80 nhỏ để đăng thử.
const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAHgAAABQCAYAAADSm7GJAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdv'
    'qGQAAAG+SURBVHhe7ZPBbQNBEMNSWApLie7KwT4M2AB/yWk0OhHg93Zkwl/fP49nzbWBw23gcBs43AYOt4HDbeBwGzjcBg63gcNt4HAbONwG'
    'DreBw23gcBs43MjAf4G+t9mIwFdC721ydWAl9P4G1wV2gO5ydVVgJ+g+R1cEdobuddI+8AbobhetA2+C7nfQNvBGaMe0loE3Q3smtQucAO2a'
    '0ipwErRvQpvAidBOtQ18IbRTrUXgZGiv0ga+GNqrdDzwHaDdKhtYAO1WORr4TtB+hQ0sgvYrbGARtF9hA4ug/QobWATtV9jAImi/wrHAd4N+'
    'A4X9B4ug/QobWATtV9jAImi/wgYWQfsVNrAI2q+wgUXQfoWjgY93gHarbGABtFvleOBjMrRXaQNfDO1VahH4mAjtVNvAF0I71doEPiZB+ya0'
    'CnxMgHZNaRf4uBnaM6ll4ONGaMe0toGPm6D7HbQOfNwA3e2ifeCjM3SvkysCv3SC7nN0VeCjA3SXq+sCv5yA7nB3beB3r4Te22RE4Hf/A/ru'
    'VuMC108bONwGDreBw23gcBs43AYOt4HDbeBwGzjcBg63gcNt4HAbONwGjvbx/AVfsLfPb7dwuwAAAABJRU5ErkJggg==';

void main() {
  group('khách', () {
    test('findAll (có và không có bộ lọc), findOverview, findById đọc được JSON thật', () async {
      final dao = BlogDao(liveGuest());

      final page = await dao.findAll();
      expect(page.items, isNotEmpty);
      expect(page.totalItems, greaterThanOrEqualTo(page.items.length));
      final first = page.items.first;
      expect(first.id, isNotNull);
      expect(first.title, isNotEmpty);
      expect(first.author?.displayName, isNotEmpty);
      expect(first.topics, isNotEmpty);
      expect(first.createdAt, isNotNull);

      final topicId = first.topicIds.first;
      final filtered = await dao.findAll(q: first.title.split(' ').first, topicIds: [topicId], sort: 'LIKES');
      expect(filtered.items.every((b) => b.topicIds.contains(topicId)), isTrue);

      final overview = await dao.findOverview();
      expect(overview.topics, isNotEmpty);
      expect(overview.topWritersDays, greaterThan(0));
      if (overview.featured.isNotEmpty) {
        expect(overview.featuredPeriod, anyOf('WEEK', 'MONTH'));
      }

      final blog = await dao.findById(first.id!);
      expect(blog.title, first.title);
      expect(blog.content.length, greaterThanOrEqualTo(first.content.replaceAll('…', '').length ~/ 2));
      expect(blog.isSignedIn, isFalse);
      expect(blog.canInteract, isFalse);
      expect(blog.reportReasons, isNotEmpty);
      expect(blog.author?.rankName, isNotEmpty);
    }, skip: liveSkip);

    test('bài không có: 404 với câu của server', () async {
      await expectLater(
        BlogDao(liveGuest()).findById(999999),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', startsWith('Không tìm thấy nội dung')),
        ),
      );
    }, skip: liveSkip);

    test('form viết bài và tìm địa điểm cần đăng nhập', () async {
      final dao = BlogDao(liveGuest());
      await expectLater(
        dao.findComposeOptions(),
        throwsA(isA<ApiException>().having((e) => e.isUnauthorized, '401', isTrue)),
      );
      await expectLater(dao.searchPlaces('nippori'), throwsA(isA<ApiException>()));
      await expectLater(dao.like(1), throwsA(isA<ApiException>()));
    }, skip: liveSkip);
  });

  test(
    'kouhai đăng bài có ảnh; user thích, lưu, bình luận; kouhai trả lời; sửa, xóa; xóa bài thử',
    () async {
      final kouhai = BlogDao(await liveSignedIn('kouhai@gmail.com'));
      final user = BlogDao(await liveSignedIn('user@gmail.com'));

      final options = await kouhai.findComposeOptions();
      expect(options.topics, isNotEmpty);
      expect(options.imagesMax, 5);
      final places = await kouhai.searchPlaces('nippori');
      expect(places, isNotEmpty);
      expect(places.first.name, isNotEmpty);

      final dir = Directory.systemTemp.createTempSync('blog_live');
      addTearDown(() => dir.deleteSync(recursive: true));
      final photo = File('${dir.path}${Platform.pathSeparator}anh-thu.png')..writeAsBytesSync(base64Decode(_png));
      final title = '[Thử app] Bài live ${DateTime.now().millisecondsSinceEpoch}';
      final other = options.topics.firstWhere((t) => t.name == 'Khác', orElse: () => options.topics.last);

      final created = await kouhai.create(
        Blog(title: title, content: 'Bài thử của test live, sẽ xóa ngay.', topics: [other], places: [places.first]),
        imagePaths: [photo.path],
      );
      final id = created.id;
      try {
        expect(created.status, anyOf('PUBLISHED', 'PROCESSING'));
        expect(created.message, isNotEmpty);

        // Ảnh được quét sau khi lưu (máy dev luôn PASS): chờ bài được đăng
        var mine = await kouhai.findById(id);
        for (var i = 0; i < 30 && mine.isProcessing; i++) {
          await Future<void>.delayed(const Duration(seconds: 1));
          mine = await kouhai.findById(id);
        }
        expect(mine.status, 'PUBLISHED');
        expect(mine.isMine, isTrue);
        expect(mine.images, hasLength(1));
        expect(mine.images.single.url, startsWith('/media/'));
        expect(mine.places.single.id, places.first.id);

        // Sửa: giữ ảnh cũ, đổi tiêu đề
        final edit = await kouhai.findForEdit(id);
        expect(edit.media, hasLength(1));
        expect(edit.topicNames, [other.name]);
        final saved = await kouhai.update(
          Blog(
            id: id,
            title: '$title (sửa)',
            content: edit.content,
            topics: edit.topics,
            places: edit.places,
            media: edit.media,
          ),
        );
        expect(saved.message, startsWith('Đã lưu thay đổi'));
        final edited = await user.findById(id);
        expect(edited.title, '$title (sửa)');
        expect(edited.edited, isTrue);
        expect(edited.images, hasLength(1));
        expect(edited.canInteract, isTrue);

        // Thích rồi bỏ thích, lưu rồi bỏ lưu
        expect(await user.like(id), (active: true, count: 1));
        expect(await user.unlike(id), (active: false, count: 0));
        expect(await user.save(id), 'Đã lưu bài viết.');
        expect(await user.unsave(id), 'Đã bỏ lưu bài viết.');
        await expectLater(
          kouhai.like(id),
          throwsA(
            isA<ApiException>().having((e) => e.message, 'message', 'Bạn không thể thích bài viết của chính mình.'),
          ),
        );

        // Bình luận, trả lời (người khác nên không phải chờ 15 giây), thích bình luận
        final commented = await user.addComment(id, 'Bình luận thử của test live');
        expect(commented.message, 'Đã đăng bình luận.');
        final comment = commented.blog!.comments.last;
        expect(comment.mine, isTrue);
        expect(comment.author?.displayName, isNotEmpty);

        final replied = await kouhai.addComment(id, 'Trả lời thử của test live', parentId: comment.id);
        final reply = replied.blog!.comments.firstWhere((c) => c.id == comment.id).replies.single;
        expect(reply.parentId, comment.id);
        expect(reply.mine, isTrue);

        expect(await kouhai.likeComment(comment.id), (active: true, count: 1));
        expect(await kouhai.unlikeComment(comment.id), (active: false, count: 0));

        // Sửa rồi xóa bình luận của mình: còn câu trả lời nên thành dòng "đã bị xóa"
        final updated = await user.updateComment(comment.id, 'Bình luận đã sửa');
        expect(updated.message, 'Đã lưu bình luận.');
        expect(updated.blog!.comments.firstWhere((c) => c.id == comment.id).edited, isTrue);

        final deleted = await user.deleteComment(comment.id);
        expect(deleted.message, 'Đã xóa bình luận.');
        final placeholder = deleted.blog!.comments.firstWhere((c) => c.id == comment.id);
        expect(placeholder.removed, isTrue);
        expect(placeholder.author, isNull);
        expect(placeholder.replies.single.id, reply.id);
      } finally {
        expect(await kouhai.delete(id), 'Đã xóa bài viết.');
      }
      await expectLater(user.findById(id), throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)));
    },
    timeout: const Timeout(Duration(minutes: 2)),
    skip: liveSkip,
  );
}
