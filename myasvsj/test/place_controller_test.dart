// Unit test của PlaceController: chạy với DAO giả và plugin giả, không cần server.
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/place_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/map_overview.dart';
import 'package:myasvsj/com.myasvsj.model/map_search_result.dart';
import 'package:myasvsj/com.myasvsj.model/place_detail.dart';

import 'place_fakes.dart';
import 'place_samples.dart';

void main() {
  late FakePlaceDao dao;
  late FakePlaceSpeaker speaker;
  late FakePlaceLocator locator;
  late PlaceController controller;

  setUp(() {
    dao = FakePlaceDao();
    speaker = FakePlaceSpeaker();
    locator = FakePlaceLocator((lat: 35.7289, lng: 139.7713));
    controller = PlaceController(dao, speaker: speaker, locator: locator);
  });

  group('bản đồ', () {
    test('loadMap lấy ghim, danh mục, sự kiện 30 ngày và tắt trạng thái chờ', () async {
      final future = controller.loadMap();
      expect(controller.isLoadingMap, isTrue);
      await future;
      expect(controller.isLoadingMap, isFalse);
      expect(controller.mapError, isNull);
      expect(controller.places.map((p) => p.id), [1, 3, 4, 10]);
      expect(controller.activeCategories.map((c) => c.id), ['konbini', 'food', 'station']);
      expect(controller.totalCount, 4);
      expect(controller.center.label, 'Arakawa-ku, Tokyo · 東京都荒川区');
      expect(controller.events, hasLength(2));
      expect(dao.calls, ['findMap', 'findEvents 30']);
    });

    test('loadMap giữ câu báo lỗi của server, không tải sự kiện', () async {
      dao.failWith = offline;
      await controller.loadMap();
      expect(controller.mapError, offline.message);
      expect(controller.overview, isNull);
      expect(controller.places, isEmpty);
      expect(dao.calls, ['findMap']);
    });

    test('lỗi tải sự kiện không làm hỏng bản đồ', () async {
      dao.failOn['findEvents'] = offline;
      await controller.loadMap();
      expect(controller.mapError, isNull);
      expect(controller.places, hasLength(4));
      expect(controller.events, isEmpty);
    });

    test('setEventDays: Tắt bỏ ghim sự kiện, 15 ngày tải lại', () async {
      await controller.loadMap();
      await controller.setEventDays(0);
      expect(controller.eventDays, 0);
      expect(controller.events, isEmpty);
      await controller.setEventDays(15);
      expect(controller.events.single.id, 2);
      expect(dao.calls.last, 'findEvents 15');
    });

    test('setCategory lọc ghim và mở bảng địa điểm của danh mục, nhiều review trước', () async {
      await controller.loadMap();
      controller.setCategory('food');
      expect(controller.places.map((p) => p.id), [4, 10]);
      expect(controller.panelTitle, 'Quán ăn');
      expect(controller.panelItems.map((o) => o.id), [4, 10]);
      expect(controller.panelItems.first.category, 'Quán ăn');
      controller.setCategory(null);
      expect(controller.isPanelOpen, isFalse);
      expect(controller.places, hasLength(4));
    });

    test('danh sách danh mục xếp gần tôi nhất trước khi đã biết vị trí', () async {
      await controller.loadMap();
      locator.position = (lat: 35.7262, lng: 139.767);
      await controller.locateMe();
      controller.setCategory('food');
      expect(controller.panelItems.map((o) => o.id), [10, 4]);
    });

    test('search mở bảng kết quả, có địa điểm OpenStreetMap và danh mục khớp', () async {
      await controller.loadMap();
      controller.setCategory('food');
      final future = controller.search('  ga ');
      expect(controller.isPanelLoading, isTrue);
      expect(controller.categoryId, isNull);
      await future;
      expect(dao.calls.last, 'search ga');
      expect(controller.panelTitle, 'Kết quả cho “ga”');
      expect(controller.panelItems.map((o) => o.name), ['Ga Nippori', 'Ueno Station']);
      expect(controller.panelCategories.single.id, 'station');
      expect(controller.panelNote, '');
      expect(controller.isPanelLoading, isFalse);
    });

    test('search của khách ghi chú đăng nhập; từ khóa trống không gọi server', () async {
      dao.searchResult = MapSearchResult.fromJson(sampleGuestSearch);
      await controller.search('   ');
      expect(dao.calls, isEmpty);
      await controller.search('ga');
      expect(controller.panelNote, 'Đăng nhập để tìm thêm trên OpenStreetMap.');
    });

    test('suggest gợi ý danh mục và địa điểm khi đang gõ, không mở bảng kết quả', () async {
      await controller.loadMap();
      final future = controller.suggest(' nippori ');
      expect(controller.isSuggestOpen, isTrue);
      expect(controller.isSuggesting, isTrue);
      await future;
      expect(dao.calls.last, 'search nippori');
      expect(controller.suggestQuery, 'nippori');
      expect(controller.suggestions!.places.map((o) => o.name), ['Ga Nippori', 'Ueno Station']);
      expect(controller.suggestions!.categories.single.id, 'station');
      expect(controller.isSuggesting, isFalse);
      expect(controller.isPanelOpen, isFalse);
    });

    test('suggest từ khóa trống đóng gợi ý; kết quả về sau khi đã đóng bị bỏ; search đóng gợi ý', () async {
      await controller.suggest('ga');
      await controller.suggest('   ');
      expect(controller.isSuggestOpen, isFalse);
      expect(dao.calls.where((c) => c.startsWith('search')), ['search ga']);

      final late = controller.suggest('ueno');
      controller.hideSuggestions();
      await late;
      expect(controller.isSuggestOpen, isFalse);
      expect(controller.suggestions, isNull);

      await controller.suggest('ga');
      await controller.search('ga');
      expect(controller.isSuggestOpen, isFalse);
      expect(controller.isPanelOpen, isTrue);
    });

    test('suggest lỗi giữ câu của server trong khung gợi ý', () async {
      dao.failOn['search'] = const ApiException('Bạn tìm hơi nhanh.', statusCode: 429);
      await controller.suggest('ramen');
      expect(controller.suggestError, 'Bạn tìm hơi nhanh.');
      expect(controller.isSuggesting, isFalse);
      expect(controller.isSuggestOpen, isTrue);
    });

    test('search lỗi giữ câu của server trong bảng', () async {
      dao.failOn['search'] = const ApiException('Bạn tìm hơi nhanh.', statusCode: 429);
      await controller.search('ramen');
      expect(controller.panelError, 'Bạn tìm hơi nhanh.');
      expect(controller.isPanelLoading, isFalse);
    });

    test('loadNearby khi đã đăng nhập hỏi server', () async {
      await controller.loadMap();
      await controller.loadNearby(35.7289, 139.7713, signedIn: true);
      expect(dao.calls.last, 'findNearby 35.7289,139.7713');
      expect(controller.panelTitle, PlaceController.nearbyTitle);
      expect(controller.panelItems, hasLength(2));
    });

    test('loadNearby không có gì quanh đây thì ghi chú', () async {
      dao.nearbyResult = const MapSearchResult(external: 'ON');
      await controller.loadNearby(35.7, 139.7, signedIn: true);
      expect(controller.panelItems, isEmpty);
      expect(controller.panelNote, contains('Không có địa điểm có tên nào trong khoảng 150 m.'));
    });

    test('loadNearby của khách tính trên máy: địa điểm Senpai ơi trong 150 m, không gọi server', () async {
      await controller.loadMap();
      dao.calls.clear();
      // Cạnh Ga Nippori (id 1); Konbini Midori (id 3) cách khoảng 160 m
      await controller.loadNearby(35.72892, 139.771364, signedIn: false);
      expect(dao.calls, isEmpty);
      expect(controller.panelItems.map((o) => o.id), [1]);
      expect(controller.panelNote, 'Đăng nhập để xem thêm địa điểm từ OpenStreetMap.');
      await controller.loadNearby(35.0, 139.0, signedIn: false);
      expect(controller.panelItems, isEmpty);
      expect(controller.panelNote, startsWith('Không có địa điểm Senpai ơi nào trong khoảng 150 m.'));
    });

    test('closePanel đóng bảng và bỏ lọc danh mục', () async {
      await controller.loadMap();
      controller.setCategory('food');
      controller.closePanel();
      expect(controller.isPanelOpen, isFalse);
      expect(controller.categoryId, isNull);
    });

    test('locateMe lấy vị trí từ máy và tính khoảng cách', () async {
      await controller.loadMap();
      final note = await controller.locateMe();
      expect(note, isNull);
      expect(locator.asked, 1);
      expect(controller.myLocation, (lat: 35.7289, lng: 139.7713));
      expect(controller.distanceTo(35.7289, 139.7713), 0);
      expect(controller.isLocating, isFalse);
    });

    test('locateMe khi người dùng từ chối quyền báo nhẹ, không có vị trí', () async {
      locator.position = null;
      final note = await controller.locateMe();
      expect(note, 'Không lấy được vị trí. Hãy bật định vị và cho phép ứng dụng dùng vị trí.');
      expect(controller.myLocation, isNull);
    });

    test('locateMe dùng vị trí giả lập của server, không hỏi máy', () async {
      dao.overview = MapOverview.fromJson({
        ...sampleOverview,
        'devLocation': {'lat': 35.7281, 'lng': 139.7707, 'label': 'Ga Nippori'},
      });
      await controller.loadMap();
      final note = await controller.locateMe();
      expect(note, 'Vị trí giả lập cho môi trường thử nghiệm: Ga Nippori');
      expect(controller.myLocation, (lat: 35.7281, lng: 139.7707));
      expect(locator.asked, 0);
    });
  });

  group('chi tiết địa điểm', () {
    test('loadPlace lấy chi tiết và trang review đầu', () async {
      final future = controller.loadPlace(1);
      expect(controller.isLoadingDetail(1), isTrue);
      await future;
      expect(controller.isLoadingDetail(1), isFalse);
      expect(controller.detailOf(1)?.name, 'Ga Nippori');
      expect(controller.reviewsOf(1).map((r) => r.id), [1, 12]);
      expect(controller.hasMoreReviews(1), isFalse);
      expect(dao.calls, ['findById 1', 'findReviews 1 p0']);
    });

    test('loadPlace lỗi 404 giữ câu của server theo id, không tải review', () async {
      await controller.loadPlace(9999);
      expect(controller.detailOf(9999), isNull);
      expect(controller.detailErrorOf(9999), 'Địa điểm này không còn trên Senpai ơi.');
      expect(dao.calls, ['findById 9999']);
    });

    test('hai địa điểm mở chồng nhau không lẫn dữ liệu', () async {
      dao.details[2] = PlaceDetail.fromJson({...sampleDetail, 'id': 2, 'name': 'Trường Nhật ngữ FPT'});
      await controller.loadPlace(1);
      await controller.loadPlace(2);
      expect(controller.detailOf(1)?.name, 'Ga Nippori');
      expect(controller.detailOf(2)?.name, 'Trường Nhật ngữ FPT');
      expect(controller.reviewsOf(2), isEmpty);
    });

    test('loadReviews more tải trang sau và nối vào danh sách', () async {
      dao.reviews[1] = manyReviews();
      await controller.loadPlace(1);
      expect(controller.reviewsOf(1), hasLength(10));
      expect(controller.hasMoreReviews(1), isTrue);
      await controller.loadReviews(1, more: true);
      expect(controller.reviewsOf(1), hasLength(12));
      expect(controller.hasMoreReviews(1), isFalse);
      expect(dao.calls.last, 'findReviews 1 p1');
    });

    test('lỗi tải review giữ câu của server', () async {
      dao.failOn['findReviews'] = offline;
      await controller.loadPlace(1);
      expect(controller.detailOf(1), isNotNull);
      expect(controller.reviewErrorOf(1), offline.message);
    });

    test('loadPhrases tải từ vựng; lỗi thì danh sách rỗng và có câu báo', () async {
      await controller.loadPhrases(1);
      expect(controller.phrasesOf(1)?.map((p) => p.id), [13, 16]);
      dao.failOn['findPhrases'] = offline;
      await controller.loadPhrases(1);
      expect(controller.phrasesOf(1), isEmpty);
      expect(controller.takeMessage(), offline.message);
    });

    test('toggleSave đổi ngay rồi giữ câu của server', () async {
      await controller.loadPlace(1);
      final future = controller.toggleSave(1);
      expect(controller.detailOf(1)?.saved, isTrue);
      expect(await future, isTrue);
      expect(dao.calls.last, 'save 1');
      expect(controller.takeMessage(), 'Đã lưu địa điểm.');
      await controller.toggleSave(1);
      expect(controller.detailOf(1)?.saved, isFalse);
      expect(dao.calls.last, 'unsave 1');
    });

    test('toggleSave lỗi thì trả lại như cũ', () async {
      await controller.loadPlace(1);
      dao.failOn['save'] = const ApiException('Bạn cần đăng nhập để thực hiện thao tác này.', statusCode: 401);
      expect(await controller.toggleSave(1), isFalse);
      expect(controller.detailOf(1)?.saved, isFalse);
      expect(controller.takeMessage(), 'Bạn cần đăng nhập để thực hiện thao tác này.');
    });

    test('reportClosed cập nhật số báo và đánh dấu đã báo', () async {
      await controller.loadPlace(1);
      expect(await controller.reportClosed(1), isTrue);
      expect(controller.detailOf(1)?.closedReports, 1);
      expect(controller.detailOf(1)?.reportedClosed, isTrue);
      expect(controller.detailOf(1)?.closedProgress, '1/5');
      expect(controller.takeMessage(), 'Đã ghi nhận báo cáo.');
    });

    test('reportClosed lần hai (409) giữ câu của server và đánh dấu đã báo', () async {
      await controller.loadPlace(1);
      dao.failOn['reportClosed'] = const ApiException('Bạn đã báo địa điểm này rồi.', statusCode: 409);
      expect(await controller.reportClosed(1), isFalse);
      expect(controller.detailOf(1)?.reportedClosed, isTrue);
      expect(controller.takeMessage(), 'Bạn đã báo địa điểm này rồi.');
    });

    test('toggleLike đổi ngay, rồi lấy số lượt thích server đếm lại', () async {
      await controller.loadPlace(1);
      dao.likeCountFromServer = 3;
      final future = controller.toggleLike(1, 1);
      final optimistic = controller.reviewsOf(1).first;
      expect(optimistic.liked, isTrue);
      expect(optimistic.likeCount, 15);
      await future;
      final review = controller.reviewsOf(1).first;
      expect(review.liked, isTrue);
      expect(review.likeCount, 3);
      expect(review.helpful, isFalse);
      expect(dao.calls.last, 'likeReview 1');
    });

    test('toggleLike lỗi thì trả lại như cũ và giữ câu báo', () async {
      await controller.loadPlace(1);
      dao.failOn['likeReview'] = const ApiException('Review này không còn hiển thị.', statusCode: 404);
      await controller.toggleLike(1, 1);
      final review = controller.reviewsOf(1).first;
      expect(review.liked, isFalse);
      expect(review.likeCount, 14);
      expect(review.helpful, isTrue);
      expect(controller.takeMessage(), 'Review này không còn hiển thị.');
    });

    test('reportReview gửi lý do rồi tải lại review', () async {
      await controller.loadPlace(1);
      expect(await controller.reportReview(1, 1, 4, 'Quảng cáo'), isTrue);
      expect(dao.calls, containsAllInOrder(['reportReview 1 r4 Quảng cáo', 'findReviews 1 p0']));
      expect(controller.takeMessage(), 'Đã gửi báo cáo cho Moderator.');
    });

    test('reportReview lỗi giữ câu của server', () async {
      dao.failOn['reportReview'] = const ApiException('Bạn đã báo cáo nội dung này rồi.', statusCode: 409);
      expect(await controller.reportReview(1, 1, 4, ''), isFalse);
      expect(controller.takeMessage(), 'Bạn đã báo cáo nội dung này rồi.');
    });

    test('speak đọc câu tiếng Nhật; máy không đọc được thì báo', () async {
      await controller.speak('乗り換え');
      expect(speaker.spoken, ['乗り換え']);
      expect(controller.takeMessage(), isNull);
      speaker.works = false;
      await controller.speak('終電');
      expect(controller.takeMessage(), 'Thiết bị này không hỗ trợ đọc tiếng Nhật.');
    });
  });
}
