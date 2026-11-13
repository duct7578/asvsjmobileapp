// Test HomeDao với server giả: đúng phương thức, đường dẫn, tham số; đọc đúng mọi trường JSON thật của web.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/home_dao.dart';

import 'fake_api.dart';
import 'home_samples.dart';

void main() {
  group('findGuest – GET /api/home', () {
    test('đọc số liệu, review "Hữu ích" và câu tiếng Nhật hôm nay', () async {
      final server = FakeServer({'GET /api/home': (_) => jsonDecode(guestHomeJson)});
      final home = await HomeDao(server.api).findGuest();

      expect(server.requests.single.method, 'GET');
      expect(home.placesWithReviews, 7);
      expect(home.reviewCount, 9);
      expect(home.phraseCount, 48);
      expect(home.quotes, hasLength(2));
      final quote = home.quotes.first;
      expect(quote.text, startsWith('Đăng ký cư trú ở tầng 1'));
      expect(quote.authorName, 'Lan Anh');
      expect(quote.authorTags.single.name, 'Mentor');
      expect(quote.authorTags.single.color, '#C2456E');
      expect(quote.placeName, 'Văn phòng quận Arakawa');
      final phrase = home.phrase!;
      expect(phrase.japanese, '温めてください。');
      expect(phrase.romaji, 'Atatamete kudasai.');
      expect(phrase.meaningVi, 'Làm ơn hâm nóng giúp tôi.');
      expect(phrase.categoryId, 'konbini');
      expect(phrase.categoryName, 'Cửa hàng tiện lợi');
      expect(phrase.categoryIcon, 'local_convenience_store');
      expect(phrase.topicId, isNull);
    });

    test('server lỗi thì ném ApiException mang câu của server', () async {
      final server = FakeServer({'GET /api/home': (_) => apiError(500, 'Đã có lỗi xảy ra. Vui lòng thử lại sau.')});
      await expectLater(
        HomeDao(server.api).findGuest(),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Đã có lỗi xảy ra. Vui lòng thử lại sau.')),
      );
    });
  });

  group('findMember – GET /api/me/home', () {
    test('đọc lời chào, điểm, Việc tiếp theo, sự kiện, review, bài nổi bật, Dành cho bạn, cẩm nang', () async {
      final server = FakeServer({'GET /api/me/home': (_) => jsonDecode(memberHomeJson)});
      final home = await HomeDao(server.api).findMember();

      expect(server.last('GET', '/api/me/home').uri.query, isEmpty);
      expect(home.displayName, 'Trần Minh');
      expect(home.stage, 'ARR');
      expect(home.areaId, 679);
      expect(home.areaName, 'Arakawa-ku, Tokyo · 東京都荒川区');
      expect(home.hasAreaAndStage, isTrue);
      expect(home.points, 45);
      expect(home.rankName, 'Người mới');
      expect(home.phrase?.japanese, '温めてください。');

      final guide = home.guide!;
      expect(guide.stageCode, 'ARR');
      expect(guide.stageTitle, 'Khi mới đến (tuần đầu đến 3 tháng)');
      expect(guide.done, 0);
      expect(guide.total, 10);
      expect(guide.progress, 0);
      final next = guide.next!;
      expect(next.guideId, 21);
      expect(next.title, startsWith('Thẻ cư trú'));
      expect(next.dueNote, isNull);
      expect(next.placeId, isNull);
      expect(next.checklist, isTrue);
      expect(next.tasksDone, 0);
      expect(next.tasksTotal, 6);
      expect(next.nextTask, 'Hộ chiếu còn hiệu lực');

      expect(home.events, hasLength(3));
      final event = home.events.first;
      expect(event.id, 2);
      expect(event.title, 'Chợ phiên cuối tuần phố Yanaka Ginza');
      expect(event.startDate, DateTime(2026, 11, 6));
      expect(event.endDate, DateTime(2026, 11, 8));
      expect(event.locationName, 'Phố Yanaka Ginza');
      expect(event.daysUntil, 0);
      expect(event.isHappening, isTrue);
      expect(home.events[1].daysUntil, 2);

      expect(home.reviews, hasLength(3));
      final review = home.reviews.first;
      expect(review.id, 4);
      expect(review.placeId, 2);
      expect(review.placeName, 'Trường Nhật ngữ FPT');
      expect(review.categoryIcon, 'school');
      expect(review.placeArea, 'Arakawa-ku, Tokyo · 東京都荒川区');
      expect(review.near, 'AREA');
      expect(review.rating, 4);
      expect(review.authorName, 'Hoàng');
      expect(review.excerpt, startsWith('Mình mới nhập học'));
      expect(review.createdAt?.toUtc(), DateTime.utc(2026, 11, 1, 18, 36, 45));

      final featured = home.featured!;
      expect(featured.id, 3);
      expect(featured.title, 'Hai quán ăn dưới 1.000 yên quanh Nippori');
      expect(featured.authorName, 'Hoàng');
      expect(featured.authorTags.single.name, 'Kouhai');
      expect(featured.readMinutes, 1);
      expect(featured.isThisWeek, isTrue);

      expect(home.forYou, hasLength(5));
      final post = home.forYou.first;
      expect(post.id, 2);
      expect(post.title, 'Tin nhắn tuyển việc làm thêm lương cao quanh ga');
      expect(post.excerpt, startsWith('Gần đây có tài khoản'));
      expect(post.authorName, 'Lan Anh');
      expect(post.topicName, 'Cảnh báo lừa đảo');
      expect(post.likeCount, 31);
      expect(post.commentCount, 0);
      expect(post.createdAt?.toUtc(), DateTime.utc(2026, 10, 29, 18, 36, 45));
      expect(post.reason, 'Gần khu vực của bạn');
      expect(post.reasons.map((r) => r.code), ['AREA', 'STAGE']);
      expect(post.reasons.first.label, 'Gần khu vực của bạn');
      expect(post.reasons.first.detail, 'Ga Nippori');
      expect(post.engaged, isFalse);

      expect(home.interests, ['Mua sắm', 'Ngân hàng và tiền']);
      expect(home.chosenInterests, isEmpty);

      expect(home.stageGuides.map((g) => g.id), [22, 23, 24]);
      final plain = home.stageGuides.first;
      expect(plain.topicName, 'Nhà ở');
      expect(plain.excerpt, isNull);
      expect(plain.checklist, isFalse);
      final checklist = home.stageGuides[1];
      expect(checklist.checklist, isTrue);
      expect(checklist.tasksDone, 0);
      expect(checklist.tasksTotal, 3);
      expect(checklist.percent, 0);
      expect(checklist.nextTask, 'Cài đặt ứng dụng tìm đường');
      expect(checklist.inProgress, isFalse);
      expect(home.stageGuides[2].excerpt, startsWith('Phân loại và bỏ rác'));
    });

    test('khách nhận 401 thành ApiException isUnauthorized', () async {
      final server = FakeServer({'GET /api/me/home': (_) => const FakeReply(401, null)});
      await expectLater(
        HomeDao(server.api).findMember(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)
              .having((e) => e.message, 'message', 'Bạn cần đăng nhập để làm việc này.'),
        ),
      );
    });
  });

  group('findForYou – GET /api/me/for-you', () {
    test('trang đầu không gửi scope và q rỗng, đọc phạm vi và bài', () async {
      final server = FakeServer({'GET /api/me/for-you': (_) => jsonDecode(forYouJson)});
      final feed = await HomeDao(server.api).findForYou(q: '   ');

      expect(server.last('GET', '/api/me/for-you').uri.queryParameters, {'page': '0'});
      expect(feed.scope, 'ALL');
      expect(feed.q, isNull);
      expect(feed.areaName, 'Arakawa-ku, Tokyo · 東京都荒川区');
      expect(feed.stage, 'ARR');
      expect(feed.interests, ['Mua sắm', 'Ngân hàng và tiền']);
      expect(feed.chosenInterests, isEmpty);
      expect(feed.scopes.map((s) => s.code), ['ALL', 'NEAR', 'STAGE', 'INTEREST']);
      expect(feed.countOf('ALL'), 5);
      expect(feed.countOf('NEAR'), 4);
      expect(feed.countOf('INTEREST'), 0);
      expect(feed.countOf('KHAC'), 0);
      expect(feed.page, 0);
      expect(feed.hasMore, isFalse);
      expect(feed.items, hasLength(5));
      expect(feed.items.first.reasons.first.detail, 'Ga Nippori');
    });

    test('gửi phạm vi, trang và từ khóa đã bỏ khoảng trắng', () async {
      final server = FakeServer({'GET /api/me/for-you': (_) => jsonDecode(forYouJson)});
      await HomeDao(server.api).findForYou(scope: 'NEAR', page: 2, q: '  Nippori ');

      expect(server.last('GET', '/api/me/for-you').uri.queryParameters, {'scope': 'NEAR', 'page': '2', 'q': 'Nippori'});
    });

    test('từ khóa quá dài: server trả 400 thành ApiException', () async {
      final server = FakeServer({'GET /api/me/for-you': (_) => apiError(400, 'Từ khóa tìm kiếm tối đa 100 ký tự.')});
      await expectLater(
        HomeDao(server.api).findForYou(q: 'x' * 101),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', 'Từ khóa tìm kiếm tối đa 100 ký tự.'),
        ),
      );
    });
  });

  group('findRecentReviews – GET /api/home/reviews', () {
    test('khách: chỉ phạm vi Tất cả, đọc đủ trường của review', () async {
      final server = FakeServer({'GET /api/home/reviews': (_) => jsonDecode(guestReviewsJson)});
      final feed = await HomeDao(server.api).findRecentReviews();

      expect(server.last('GET', '/api/home/reviews').uri.queryParameters, {'page': '0'});
      expect(feed.scope, 'ALL');
      expect(feed.areaName, isNull);
      expect(feed.prefectureName, isNull);
      expect(feed.scopes.single.code, 'ALL');
      expect(feed.countOf('ALL'), 9);
      expect(feed.page, 0);
      expect(feed.hasMore, isFalse);
      expect(feed.items, hasLength(9));
      final review = feed.items.first;
      expect(review.id, 4);
      expect(review.placeId, 2);
      expect(review.placeName, 'Trường Nhật ngữ FPT');
      expect(review.categoryName, 'Trường học');
      expect(review.categoryIcon, 'school');
      expect(review.placeArea, 'Arakawa-ku, Tokyo · 東京都荒川区');
      expect(review.placeClosed, isFalse);
      expect(review.near, isNull);
      expect(review.rating, 4);
      expect(review.authorName, 'Hoàng');
      expect(review.authorTags.single.name, 'Kouhai');
      expect(review.authorTags.single.color, '#2E7D5B');
      expect(review.excerpt, startsWith('Mình mới nhập học'));
      expect(review.likeCount, 3);
      expect(review.isHelpful, isFalse);
      expect(review.createdAt?.toUtc(), DateTime.utc(2026, 11, 1, 18, 36, 45));
      expect(review.photoUrl, isNull);
      expect(review.mediaCount, 0);
      // Ramen Aoba có 12 lượt thích: "Hữu ích"
      expect(feed.items[1].isHelpful, isTrue);
    });

    test('thành viên có khu vực: ba phạm vi, gửi đúng phạm vi và trang', () async {
      final server = FakeServer({'GET /api/home/reviews': (_) => jsonDecode(memberReviewsJson)});
      final feed = await HomeDao(server.api).findRecentReviews(scope: 'AREA', page: 1);

      expect(server.last('GET', '/api/home/reviews').uri.queryParameters, {'scope': 'AREA', 'page': '1'});
      expect(feed.scope, 'AREA');
      expect(feed.areaName, 'Arakawa-ku, Tokyo · 東京都荒川区');
      expect(feed.prefectureName, 'Tokyo');
      expect(feed.scopes.map((s) => s.code), ['AREA', 'PREFECTURE', 'ALL']);
      expect(feed.items.first.near, 'AREA');
    });
  });
}
