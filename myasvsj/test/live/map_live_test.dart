// Bản đồ với server thật: gọi MỌI hàm đọc của PlaceDao (khách và user@gmail.com) để bắt lệch tên trường JSON, và các
// thao tác ghi trả lại được như cũ (lưu rồi bỏ lưu, thích rồi bỏ thích).
//
// Chạy: flutter test test/live/map_live_test.dart --dart-define=LIVE_API=http://localhost:8080
//
// Không chạy thật ở đây: báo cáo review (tạo hồ sơ cho Moderator, có thể ẩn review mẫu). "Báo đã đóng cửa" chỉ được
// gửi một lần cho mỗi người: địa điểm 11 (Tiệm giặt Coin Laundry Sora) đã được user@gmail.com báo khi thử bằng curl,
// nên test chấp nhận cả lần đầu thành công lẫn 409 "Bạn đã báo địa điểm này rồi.".
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/place_dao.dart';

import 'live_api.dart';

void main() {
  group('khách', () {
    late PlaceDao dao;
    setUp(() => dao = PlaceDao(liveGuest()));

    test('findMap: danh mục, ghim có tọa độ, Tokyo là tâm', () async {
      final overview = await dao.findMap();
      expect(overview.signedIn, isFalse);
      expect(overview.categories, isNotEmpty);
      expect(overview.categories.every((c) => c.id.isNotEmpty && c.name.isNotEmpty && c.icon.isNotEmpty), isTrue);
      expect(overview.places, isNotEmpty);
      expect(overview.places.every((p) => p.status == 'ACTIVE'), isTrue);
      final nippori = overview.places.firstWhere((p) => p.id == 1);
      expect(nippori.name, 'Ga Nippori');
      expect(nippori.osmId, 'N772389775');
      expect(nippori.lat, closeTo(35.7289, 0.01));
      expect(overview.center.lat, closeTo(35.68, 0.01));
    }, skip: liveSkip);

    test('findEvents 15 và 30 ngày', () async {
      final thirty = await dao.findEvents(30);
      final fifteen = await dao.findEvents(15);
      expect(thirty.length, greaterThanOrEqualTo(fifteen.length));
      for (final e in thirty) {
        expect(e.title, isNotEmpty);
        expect(e.startDate, isNotNull);
        expect(e.daysUntil, greaterThanOrEqualTo(0));
      }
    }, skip: liveSkip);

    test('search chỉ địa điểm Senpai ơi, external LOGIN', () async {
      final found = await dao.search('ga');
      expect(found.external, 'LOGIN');
      expect(found.externalNote, isNotEmpty);
      expect(found.places, isNotEmpty);
      expect(found.places.every((p) => p.isOnSenpai && p.lat != null), isTrue);
      expect(found.categories.map((c) => c.id), contains('station'));
    }, skip: liveSkip);

    test('findNearby của khách bị từ chối 401', () async {
      await expectLater(
        dao.findNearby(35.7289, 139.7713),
        throwsA(isA<ApiException>().having((e) => e.isUnauthorized, '401', isTrue)),
      );
    }, skip: liveSkip);

    test('findById, findReviews, findPhrases của Ga Nippori', () async {
      final d = await dao.findById(1);
      expect(d.name, 'Ga Nippori');
      expect(d.categoryName, isNotEmpty);
      expect(d.categoryIcon, isNotEmpty);
      expect(d.canAct, isFalse);
      expect(d.saved, isFalse);
      expect(d.closedThreshold, greaterThan(0));
      expect(d.reportReasons, isNotEmpty);
      expect(d.scamWarnings.first.blogId, greaterThan(0));

      final page = await dao.findReviews(1);
      expect(page.items, isNotEmpty);
      expect(page.totalItems, greaterThanOrEqualTo(page.items.length));
      final review = page.items.first;
      expect(review.author.displayName, isNotEmpty);
      expect(review.rating, inInclusiveRange(1, 5));
      expect(review.createdAt, isNotNull);
      expect(review.mine, isFalse);

      final phrases = await dao.findPhrases(1);
      expect(phrases, isNotEmpty);
      expect(phrases.first.japanese, isNotEmpty);
      expect(phrases.map((p) => p.kind).toSet(), containsAll(['PHRASE', 'VOCAB']));
    }, skip: liveSkip);

    test('địa điểm không có: 404 với câu của server', () async {
      await expectLater(
        dao.findById(999999),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 404)
              .having((e) => e.message, 'message', 'Địa điểm này không còn trên Senpai ơi.'),
        ),
      );
    }, skip: liveSkip);

    test('khách lưu địa điểm bị từ chối', () async {
      await expectLater(dao.save(1), throwsA(isA<ApiException>()));
    }, skip: liveSkip);
  });

  group('user@gmail.com', () {
    late PlaceDao dao;
    // Không có server (chạy test thường) thì bỏ qua đăng nhập; các test trong nhóm đều skip
    setUpAll(() async {
      if (liveSkip == null) dao = PlaceDao(await liveSignedIn('user@gmail.com'));
    });

    test('findMap: khu vực của tôi là tâm', () async {
      final overview = await dao.findMap();
      expect(overview.signedIn, isTrue);
      expect(overview.center.label, isNotEmpty);
      expect(overview.center.zoom, 15);
    }, skip: liveSkip);

    test('search có thêm địa điểm OpenStreetMap; findNearby trả về địa điểm quanh Ga Nippori', () async {
      final found = await dao.search('ga');
      expect(found.external, isNot('LOGIN'));
      expect(found.places, isNotEmpty);
      final near = await dao.findNearby(35.72892, 139.771364);
      expect(near.places.map((p) => p.id), contains(1));
    }, skip: liveSkip);

    test('chi tiết của người đã đăng nhập: canAct', () async {
      final d = await dao.findById(1);
      expect(d.canAct, isTrue);
    }, skip: liveSkip);

    test('lưu rồi bỏ lưu (trả lại như cũ)', () async {
      final before = (await dao.findById(3)).saved;
      expect(await dao.save(3), 'Đã lưu địa điểm.');
      expect((await dao.findById(3)).saved, isTrue);
      expect(await dao.unsave(3), 'Đã bỏ lưu địa điểm.');
      expect((await dao.findById(3)).saved, isFalse);
      if (before) {
        await dao.save(3);
      }
    }, skip: liveSkip);

    test('thích rồi bỏ thích review 1 (trả lại như cũ)', () async {
      final before = (await dao.findReviews(1)).items.firstWhere((r) => r.id == 1);
      final liked = await dao.likeReview(1);
      expect(liked.active, isTrue);
      final unliked = await dao.unlikeReview(1);
      expect(unliked.active, isFalse);
      expect(unliked.count, liked.count - 1);
      if (before.liked) {
        await dao.likeReview(1);
      }
    }, skip: liveSkip);

    test('báo đã đóng cửa địa điểm 11: lần đầu ghi nhận, lần sau 409', () async {
      try {
        final state = await dao.reportClosed(11);
        expect(state.count, greaterThan(0));
        expect(state.message, isNotEmpty);
      } on ApiException catch (e) {
        expect(e.statusCode, 409);
        expect(e.message, 'Bạn đã báo địa điểm này rồi.');
      }
      final d = await dao.findById(11);
      expect(d.reportedClosed, isTrue);
    }, skip: liveSkip);

    // Lý do không có trong danh sách: server từ chối trước khi ghi gì (không tạo hồ sơ báo cáo)
    test('báo cáo review với lý do không hợp lệ bị từ chối', () async {
      await expectLater(
        dao.reportReview(1, -1, ''),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 400)
              .having((e) => e.message, 'message', 'Hãy chọn lý do báo cáo.'),
        ),
      );
    }, skip: liveSkip);
  });
}
