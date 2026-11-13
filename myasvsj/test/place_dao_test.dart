// Test PlaceDao với server giả: gọi đúng phương thức, đường dẫn, tham số, body; đọc đúng JSON thật của web;
// ném ApiException khi server từ chối.
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/place_dao.dart';

import 'fake_api.dart';
import 'place_samples.dart';

void main() {
  late FakeServer server;
  late PlaceDao dao;

  setUp(() {
    server = FakeServer({
      'GET /api/map': (_) => apiOk(sampleOverview),
      'GET /api/map/events': (_) => apiOk(sampleEvents),
      'GET /api/map/search': (_) => apiOk(sampleSearch),
      'GET /api/map/nearby': (_) => apiOk(sampleSearch),
      'GET /api/map/places/1': (_) => apiOk(sampleDetail),
      'GET /api/map/places/9999': (_) => apiError(404, 'Địa điểm này không còn trên Senpai ơi.'),
      'GET /api/map/places/1/reviews': (_) => apiOk({
        'items': [sampleReview, sampleMyReview],
        'page': 0,
        'size': 10,
        'total': 12,
      }),
      'GET /api/map/places/1/phrases': (_) => apiOk(samplePhrases),
      'POST /api/map/places/1/save': (_) => apiOk({'saved': true}, message: 'Đã lưu địa điểm.'),
      'DELETE /api/map/places/1/save': (_) => apiOk({'saved': false}, message: 'Đã bỏ lưu địa điểm.'),
      'POST /api/map/places/11/closed-report': (_) =>
          apiOk({'count': 1, 'threshold': 5, 'queued': false}, message: 'Đã ghi nhận báo cáo.'),
      'POST /api/map/places/1/closed-report': (_) => apiError(409, 'Bạn đã báo địa điểm này rồi.'),
      'POST /api/reviews/1/like': (_) => apiOk({'active': true, 'count': 1}),
      'DELETE /api/reviews/1/like': (_) => apiOk({'active': false, 'count': 0}),
      'POST /api/reviews/12/like': (_) => apiError(400, 'Bạn không thể thích review của chính mình.'),
      'POST /api/reviews/1/report': (_) => apiOk(null, message: 'Đã gửi báo cáo cho Moderator.'),
    });
    dao = PlaceDao(server.api);
  });

  test('findMap đọc danh mục, ghim, khu vực của tôi', () async {
    final overview = await dao.findMap();
    expect(server.last('GET', '/api/map').method, 'GET');
    expect(overview.categories.map((c) => c.id), ['konbini', 'food', 'station', 'park']);
    expect(overview.categories[1].name, 'Quán ăn');
    expect(overview.categories[1].icon, 'restaurant');
    expect(overview.categories[1].count, 2);
    final nippori = overview.places.first;
    expect(nippori.id, 1);
    expect(nippori.name, 'Ga Nippori');
    expect(nippori.nameJa, '日暮里駅');
    expect(nippori.nameEn, 'Nippori Station');
    expect(nippori.categoryId, 'station');
    expect(nippori.lat, 35.72892);
    expect(nippori.lng, 139.771364);
    expect(nippori.source, 'OSM');
    expect(nippori.reviewCount, 2);
    expect(nippori.rating, 4.5);
    expect(nippori.scam, isTrue);
    expect(nippori.osmId, 'N772389775');
    expect(nippori.isLit, isTrue);
    final hana = overview.places[2];
    expect(hana.isCommunity, isTrue);
    final ramen = overview.places[3];
    expect(ramen.rating, isNull);
    expect(ramen.isLit, isFalse);
    expect(overview.center.lat, 35.736083);
    expect(overview.center.zoom, 15);
    expect(overview.center.label, 'Arakawa-ku, Tokyo · 東京都荒川区');
    expect(overview.signedIn, isTrue);
    expect(overview.devLocation, isNull);
  });

  test('findMap đọc vị trí giả lập của môi trường thử nghiệm', () async {
    server.routes['GET /api/map'] = (_) => apiOk({
      ...sampleOverview,
      'devLocation': {'lat': 35.7281, 'lng': 139.7707, 'label': 'Ga Nippori'},
    });
    final overview = await dao.findMap();
    expect(overview.devLocation?.lat, 35.7281);
    expect(overview.devLocation?.label, 'Ga Nippori');
  });

  test('findEvents gửi days và đọc ngày, nhãn "Còn N ngày"', () async {
    final events = await dao.findEvents(15);
    expect(server.last('GET', '/api/map/events').uri.queryParameters['days'], '15');
    expect(events, hasLength(2));
    expect(events.first.title, 'Chợ phiên cuối tuần phố Yanaka Ginza');
    expect(events.first.startDate, DateTime(2026, 11, 6));
    expect(events.first.endDate, DateTime(2026, 11, 8));
    expect(events.first.locationName, 'Phố Yanaka Ginza');
    expect(events.first.whenLabel, 'Đang diễn ra');
    expect(events[1].daysUntil, 2);
    expect(events[1].whenLabel, 'Còn 2 ngày');
  });

  test('search gửi q, đọc danh mục và địa điểm Senpai ơi / OpenStreetMap', () async {
    final found = await dao.search('ga');
    expect(server.last('GET', '/api/map/search').uri.queryParameters['q'], 'ga');
    expect(found.categories.single.name, 'Ga tàu');
    expect(found.places, hasLength(2));
    final senpai = found.places.first;
    expect(senpai.id, 1);
    expect(senpai.isOnSenpai, isTrue);
    expect(senpai.externalId, 'N772389775');
    expect(senpai.address, 'Higashi-Nippori 6, Arakawa, Tokyo');
    final osm = found.places[1];
    expect(osm.id, isNull);
    expect(osm.isOnSenpai, isFalse);
    expect(osm.externalId, 'DEV-ueno-station');
    expect(osm.nameJa, '');
    expect(osm.lat, 35.711708);
    expect(found.external, 'ON');
    expect(found.externalNote, '');
  });

  test('search của khách có ghi chú "Đăng nhập để tìm thêm"', () async {
    server.routes['GET /api/map/search'] = (_) => apiOk(sampleGuestSearch);
    final found = await dao.search('ga');
    expect(found.external, 'LOGIN');
    expect(found.externalNote, 'Đăng nhập để tìm thêm trên OpenStreetMap.');
    expect(found.places.single.name, 'Bưu điện Nippori');
  });

  test('findNearby gửi lat, lng; khách nhận lỗi 401 của server', () async {
    final found = await dao.findNearby(35.7289, 139.7713);
    final query = server.last('GET', '/api/map/nearby').uri.queryParameters;
    expect(query['lat'], '35.7289');
    expect(query['lng'], '139.7713');
    expect(found.places, hasLength(2));

    server.routes['GET /api/map/nearby'] = (_) => apiError(401, 'Hãy đăng nhập để chọn địa điểm trên bản đồ.');
    await expectLater(
      dao.findNearby(35.7, 139.7),
      throwsA(
        isA<ApiException>()
            .having((e) => e.isUnauthorized, '401', isTrue)
            .having((e) => e.message, 'message', 'Hãy đăng nhập để chọn địa điểm trên bản đồ.'),
      ),
    );
  });

  test('findById đọc mọi trường của chi tiết địa điểm', () async {
    final d = await dao.findById(1);
    expect(d.id, 1);
    expect(d.name, 'Ga Nippori');
    expect(d.address, 'Higashi-Nippori 6, Arakawa, Tokyo');
    expect(d.osmId, 'N772389775');
    expect(d.lat, 35.72892);
    expect(d.categoryName, 'Ga tàu');
    expect(d.categoryIcon, 'train');
    expect(d.sourceLabel, 'OpenStreetMap');
    expect(d.isActive, isTrue);
    expect(d.closed, isFalse);
    expect(d.closedReports, 0);
    expect(d.closedThreshold, 5);
    expect(d.closedProgress, '0/5');
    expect(d.reportedClosed, isFalse);
    expect(d.reviewCount, 2);
    expect(d.rating, 4.5);
    expect(d.scamWarnings.single.blogId, 2);
    expect(d.scamWarnings.single.title, 'Tin nhắn tuyển việc làm thêm lương cao quanh ga');
    expect(d.saved, isFalse);
    expect(d.canAct, isTrue);
    expect(d.myReviewId, isNull);
    expect(d.mergedFrom, isNull);
    expect(d.reportReasons.map((r) => r.label), ['Lừa đảo', 'Sai sự thật', 'Xúc phạm', 'Spam']);
    expect(d.directionsUrl, 'https://www.google.com/maps/dir/?api=1&destination=35.72892%2C139.771364');
  });

  test('findById ném ApiException 404 với câu của server', () async {
    await expectLater(
      dao.findById(9999),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'status', 404)
            .having((e) => e.message, 'message', 'Địa điểm này không còn trên Senpai ơi.'),
      ),
    );
  });

  test('findReviews gửi page, đổi {items, page, size, total} thành PageResult', () async {
    final page = await dao.findReviews(1, page: 0);
    expect(server.last('GET', '/api/map/places/1/reviews').uri.queryParameters['page'], '0');
    expect(page.items, hasLength(2));
    expect(page.totalItems, 12);
    expect(page.totalPages, 2);
    expect(page.hasMore, isTrue);
    final other = page.items.first;
    expect(other.author.id, 6);
    expect(other.author.displayName, 'Lan Anh');
    expect(other.author.tagNames, ['Mentor']);
    expect(other.author.rankName, 'Senpai tin cậy');
    expect(other.authorRoleLabel, '');
    expect(other.rating, 5);
    expect(other.content, startsWith('Cổng Bắc'));
    expect(other.createdAt, DateTime.utc(2026, 10, 18, 18, 36, 45).toLocal());
    expect(other.likeCount, 14);
    expect(other.helpful, isTrue);
    expect(other.mine, isFalse);
    expect(other.isPublished, isTrue);
    final mine = page.items[1];
    expect(mine.mine, isTrue);
    expect(mine.images.single.id, 20);
    expect(mine.images.single.url, startsWith('/media/review/'));
    expect(mine.images.single.width, 772);
  });

  test('findPhrases đọc từ vựng và mẫu câu', () async {
    final phrases = await dao.findPhrases(1);
    expect(phrases.first.japanese, 'この電車は上野に止まりますか。');
    expect(phrases.first.romaji, 'Kono densha wa Ueno ni tomarimasu ka.');
    expect(phrases.first.meaningVi, 'Tàu này có dừng ở Ueno không?');
    expect(phrases.first.kindLabel, 'Mẫu câu');
    expect(phrases[1].kindLabel, 'Từ vựng');
  });

  test('save và unsave gọi POST / DELETE, trả về câu của server', () async {
    expect(await dao.save(1), 'Đã lưu địa điểm.');
    expect(server.last('POST', '/api/map/places/1/save').headers['X-XSRF-TOKEN'], 'csrf-test');
    expect(await dao.unsave(1), 'Đã bỏ lưu địa điểm.');
    expect(server.last('DELETE', '/api/map/places/1/save').method, 'DELETE');
  });

  test('reportClosed đọc số báo và câu thông báo; lần hai ném 409', () async {
    final state = await dao.reportClosed(11);
    expect(state.count, 1);
    expect(state.threshold, 5);
    expect(state.queued, isFalse);
    expect(state.message, 'Đã ghi nhận báo cáo.');
    await expectLater(dao.reportClosed(1), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)));
  });

  test('likeReview / unlikeReview đọc trạng thái và số lượt thích server đếm lại', () async {
    final liked = await dao.likeReview(1);
    expect(liked.active, isTrue);
    expect(liked.count, 1);
    final unliked = await dao.unlikeReview(1);
    expect(unliked.active, isFalse);
    expect(unliked.count, 0);
    await expectLater(
      dao.likeReview(12),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Bạn không thể thích review của chính mình.')),
    );
  });

  test('reportReview gửi {reasonId, note}; ghi chú trống gửi null', () async {
    expect(await dao.reportReview(1, 4, '  Quảng cáo  '), 'Đã gửi báo cáo cho Moderator.');
    expect(server.last('POST', '/api/reviews/1/report').data, {'reasonId': 4, 'note': 'Quảng cáo'});
    await dao.reportReview(1, 2, '');
    expect(server.last('POST', '/api/reviews/1/report').data, {'reasonId': 2, 'note': null});
  });

  test('lỗi theo ô của server (400) nằm trong ApiException.fields', () async {
    server.routes['POST /api/reviews/1/report'] = (_) =>
        apiError(400, 'Hãy chọn lý do báo cáo.', fields: {'reasonId': 'Hãy chọn lý do báo cáo.'});
    await expectLater(
      dao.reportReview(1, 0, ''),
      throwsA(isA<ApiException>().having((e) => e.fields['reasonId'], 'fields', 'Hãy chọn lý do báo cáo.')),
    );
  });
}
