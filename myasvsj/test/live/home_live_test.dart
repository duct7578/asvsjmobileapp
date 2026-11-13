// HomeDao với server thật: mọi hàm đọc, khách và thành viên (user@gmail.com, chỉ đọc).
// Agent khác có thể đang ghi dữ liệu: chỉ kiểm tra cấu trúc và parse, không khẳng định số lượng cố định.
//   flutter test test/live/home_live_test.dart --dart-define=LIVE_API=http://localhost:8080
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/home_dao.dart';

import 'live_api.dart';

void main() {
  group('khách', () {
    test('GET /api/home: số liệu, review "Hữu ích", câu tiếng Nhật hôm nay', () async {
      final home = await HomeDao(liveGuest()).findGuest();
      expect(home.placesWithReviews, greaterThan(0));
      expect(home.reviewCount, greaterThanOrEqualTo(home.placesWithReviews));
      expect(home.phraseCount, greaterThan(0));
      for (final quote in home.quotes) {
        expect(quote.text, isNotEmpty);
        expect(quote.authorName, isNotEmpty);
        expect(quote.placeName, isNotEmpty);
      }
      expect(home.phrase?.japanese, isNotEmpty);
      expect(home.phrase?.meaningVi, isNotEmpty);
    }, skip: liveSkip);

    test('GET /api/home/reviews: chỉ phạm vi Tất cả, trang 0 và trang 1', () async {
      final dao = HomeDao(liveGuest());
      final feed = await dao.findRecentReviews();
      expect(feed.scope, 'ALL');
      expect(feed.areaName, isNull);
      expect(feed.scopes.map((s) => s.code), ['ALL']);
      expect(feed.page, 0);
      expect(feed.items, isNotEmpty);
      expect(feed.items.length, lessThanOrEqualTo(HomeDao.pageSize));
      for (final r in feed.items) {
        expect(r.placeName, isNotEmpty);
        expect(r.rating, inInclusiveRange(1, 5));
        expect(r.createdAt, isNotNull);
        expect(r.near, isNull);
      }
      // Hỏi phạm vi của thành viên khi là khách: server trả về Tất cả
      final area = await dao.findRecentReviews(scope: 'AREA', page: 1);
      expect(area.scope, 'ALL');
      expect(area.page, 1);
    }, skip: liveSkip);

    test('API của thành viên trả 401 cho khách', () async {
      final dao = HomeDao(liveGuest());
      await expectLater(
        dao.findMember(),
        throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
      );
      await expectLater(
        dao.findForYou(),
        throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
      );
    }, skip: liveSkip);
  });

  group('thành viên user@gmail.com', () {
    late HomeDao dao;

    setUpAll(() async {
      if (liveSkip == null) {
        dao = HomeDao(await liveSignedIn('user@gmail.com'));
      }
    });

    test('GET /api/me/home: đủ các phần của trang chủ thành viên', () async {
      final home = await dao.findMember();
      expect(home.displayName, isNotEmpty);
      expect(home.areaId, isNotNull);
      expect(home.areaName, contains('Arakawa'));
      expect(home.stage, isNotNull);
      expect(home.hasAreaAndStage, isTrue);
      expect(home.rankName, isNotEmpty);
      expect(home.points, greaterThanOrEqualTo(0));
      expect(home.phrase?.japanese, isNotEmpty);

      final guide = home.guide!;
      expect(guide.stageCode, isNotEmpty);
      expect(guide.stageTitle, isNotEmpty);
      expect(guide.done, lessThanOrEqualTo(guide.total));
      if (guide.next != null) {
        expect(guide.next!.guideId, greaterThan(0));
        expect(guide.next!.title, isNotEmpty);
      }
      for (final e in home.events) {
        expect(e.title, isNotEmpty);
        expect(e.endDate.isBefore(e.startDate), isFalse);
      }
      expect(home.reviews.length, lessThanOrEqualTo(3));
      for (final r in home.reviews) {
        expect(r.placeId, greaterThan(0));
        expect(r.authorName, isNotEmpty);
      }
      expect(home.forYou.length, lessThanOrEqualTo(5));
      for (final p in home.forYou) {
        expect(p.title, isNotEmpty);
        for (final reason in p.reasons) {
          expect(['AREA', 'PREFECTURE', 'STAGE', 'INTEREST'], contains(reason.code));
          expect(reason.label, isNotEmpty);
        }
      }
      expect(home.stageGuides.length, lessThanOrEqualTo(3));
      for (final g in home.stageGuides) {
        expect(g.title, isNotEmpty);
        expect(g.percent, inInclusiveRange(0, 100));
      }
      for (final chosen in home.chosenInterests) {
        expect(home.interests, contains(chosen));
      }
    }, skip: liveSkip);

    test('GET /api/me/for-you: mọi phạm vi, tìm, trang sau', () async {
      final first = await dao.findForYou();
      expect(first.scope, 'ALL');
      expect(first.page, 0);
      expect(first.scopes.first.code, 'ALL');
      expect(first.countOf('ALL'), greaterThanOrEqualTo(first.items.length));
      expect(first.items.length, lessThanOrEqualTo(HomeDao.pageSize));
      expect(first.areaName, isNotNull);

      for (final scope in first.scopes) {
        final feed = await dao.findForYou(scope: scope.code);
        expect(feed.scope, scope.code);
        expect(feed.items.length, lessThanOrEqualTo(HomeDao.pageSize));
      }

      final found = await dao.findForYou(q: 'Nippori');
      expect(found.q, 'Nippori');
      expect(found.countOf('ALL'), lessThanOrEqualTo(first.countOf('ALL')));

      final next = await dao.findForYou(page: 1);
      expect(next.page, 1);

      await expectLater(
        dao.findForYou(q: 'x' * 101),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    }, skip: liveSkip);

    test('GET /api/home/reviews: ba phạm vi quanh khu vực của thành viên', () async {
      final first = await dao.findRecentReviews();
      expect(first.areaName, isNotNull);
      expect(first.prefectureName, isNotEmpty);
      expect(first.scopes.map((s) => s.code), ['AREA', 'PREFECTURE', 'ALL']);
      for (final scope in first.scopes) {
        final feed = await dao.findRecentReviews(scope: scope.code);
        expect(feed.scope, scope.code);
        expect(feed.items.length, lessThanOrEqualTo(HomeDao.pageSize));
        if (scope.code == 'AREA') {
          expect(feed.items.every((r) => r.near == 'AREA'), isTrue);
        }
      }
    }, skip: liveSkip);
  });
}
