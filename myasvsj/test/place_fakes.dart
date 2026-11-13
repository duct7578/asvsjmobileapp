// DAO giả và lớp giả của Bản đồ / review: giữ dữ liệu trong bộ nhớ thay vì gọi server hay plugin, để test
// Controller và màn hình không cần mạng. Dữ liệu dựng từ JSON thật trong place_samples.dart.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/place_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/review_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/map_center.dart';
import 'package:myasvsj/com.myasvsj.model/map_festival.dart';
import 'package:myasvsj/com.myasvsj.model/map_overview.dart';
import 'package:myasvsj/com.myasvsj.model/map_search_result.dart';
import 'package:myasvsj/com.myasvsj.model/notification_dao.dart';
import 'package:myasvsj/com.myasvsj.model/page_result.dart';
import 'package:myasvsj/com.myasvsj.model/place_dao.dart';
import 'package:myasvsj/com.myasvsj.model/place_detail.dart';
import 'package:myasvsj/com.myasvsj.model/place_locator.dart';
import 'package:myasvsj/com.myasvsj.model/place_phrase.dart';
import 'package:myasvsj/com.myasvsj.model/place_review.dart';
import 'package:myasvsj/com.myasvsj.model/place_speaker.dart';
import 'package:myasvsj/com.myasvsj.model/review.dart';
import 'package:myasvsj/com.myasvsj.model/review_compose.dart';
import 'package:myasvsj/com.myasvsj.model/review_dao.dart';
import 'package:myasvsj/com.myasvsj.model/user.dart';

import 'auth_fakes.dart';
import 'place_samples.dart';

/// Lỗi server dùng chung trong test.
const offline = ApiException('Không kết nối được tới server.');

/// 12 review của người khác (đủ 2 trang) cho test "Xem thêm review".
List<PlaceReview> manyReviews() => [
  for (var i = 0; i < 12; i++)
    PlaceReview.fromJson({...sampleReview, 'id': 100 + i, 'content': 'Review số $i của địa điểm này.'}),
];

/// DAO bản đồ giả. [failWith] làm mọi lần gọi lỗi; [failOn] làm một hàm (theo tên) lỗi.
class FakePlaceDao implements PlaceDao {
  MapOverview overview = MapOverview.fromJson(sampleOverview);
  List<MapFestival> events = [for (final e in sampleEvents) MapFestival.fromJson(e)];
  MapSearchResult searchResult = MapSearchResult.fromJson(sampleSearch);
  MapSearchResult nearbyResult = MapSearchResult.fromJson(sampleSearch);
  final Map<int, PlaceDetail> details = {1: PlaceDetail.fromJson(sampleDetail)};
  final Map<int, List<PlaceReview>> reviews = {
    1: [PlaceReview.fromJson(sampleReview), PlaceReview.fromJson(sampleMyReview)],
  };
  List<PlacePhrase> phrases = [for (final p in samplePhrases) PlacePhrase.fromJson(p)];

  /// Tên hàm đã gọi, kèm tham số, theo thứ tự (ví dụ "save 1", "findEvents 15").
  final List<String> calls = [];

  ApiException? failWith;
  final Map<String, ApiException> failOn = {};

  /// Số lượt thích server "đếm lại" trả về; null = cộng / trừ 1.
  int? likeCountFromServer;

  void _call(String name, [Object? arg]) {
    calls.add(arg == null ? name : '$name $arg');
    final error = failOn[name] ?? failWith;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<MapOverview> findMap() async {
    _call('findMap');
    return overview;
  }

  @override
  Future<List<MapFestival>> findEvents(int days) async {
    _call('findEvents', days);
    return days == 15 ? [events.first] : events;
  }

  @override
  Future<MapSearchResult> search(String q) async {
    _call('search', q);
    return searchResult;
  }

  @override
  Future<MapSearchResult> findNearby(double lat, double lng) async {
    _call('findNearby', '$lat,$lng');
    return nearbyResult;
  }

  @override
  Future<PlaceDetail> findById(int id) async {
    _call('findById', id);
    final detail = details[id];
    if (detail == null) {
      throw const ApiException('Địa điểm này không còn trên Senpai ơi.', statusCode: 404);
    }
    return detail;
  }

  @override
  Future<PageResult<PlaceReview>> findReviews(int placeId, {int page = 0}) async {
    _call('findReviews', '$placeId p$page');
    final all = reviews[placeId] ?? const [];
    const size = PlaceDao.reviewPageSize;
    return PageResult(
      items: all.skip(page * size).take(size).toList(),
      page: page,
      size: size,
      totalItems: all.length,
      totalPages: (all.length + size - 1) ~/ size,
    );
  }

  @override
  Future<List<PlacePhrase>> findPhrases(int placeId) async {
    _call('findPhrases', placeId);
    return phrases;
  }

  @override
  Future<String> save(int placeId) async {
    _call('save', placeId);
    return 'Đã lưu địa điểm.';
  }

  @override
  Future<String> unsave(int placeId) async {
    _call('unsave', placeId);
    return 'Đã bỏ lưu địa điểm.';
  }

  @override
  Future<({int count, int threshold, bool queued, String message})> reportClosed(int placeId) async {
    _call('reportClosed', placeId);
    return (count: 1, threshold: 5, queued: false, message: 'Đã ghi nhận báo cáo.');
  }

  @override
  Future<({bool active, int count})> likeReview(int reviewId) async {
    _call('likeReview', reviewId);
    final old = _review(reviewId);
    return (active: true, count: likeCountFromServer ?? old.likeCount + 1);
  }

  @override
  Future<({bool active, int count})> unlikeReview(int reviewId) async {
    _call('unlikeReview', reviewId);
    final old = _review(reviewId);
    return (active: false, count: likeCountFromServer ?? old.likeCount - 1);
  }

  @override
  Future<String> reportReview(int reviewId, int reasonId, String note) async {
    _call('reportReview', '$reviewId r$reasonId $note'.trim());
    return 'Đã gửi báo cáo cho Moderator.';
  }

  PlaceReview _review(int id) => reviews.values.expand((list) => list).firstWhere((r) => r.id == id);
}

/// DAO review giả: giữ review đã gửi để test kiểm tra Controller gửi gì.
class FakeReviewDao implements ReviewDao {
  ReviewCompose compose = ReviewCompose.fromJson(sampleCompose);
  final Map<int, ({Review review, ReviewCompose compose})> edits = {
    12: (review: Review.fromEditJson(sampleEdit), compose: ReviewCompose.fromJson(sampleEdit)),
  };

  final List<({Review review, List<String> images})> created = [];
  final List<({Review review, List<String> images})> updated = [];
  final List<int> deleted = [];
  final List<int?> composeAsked = [];

  ApiException? failWith;
  final Map<String, ApiException> failOn = {};

  void _maybeFail(String name) {
    final error = failOn[name] ?? failWith;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<ReviewCompose> findCompose({int? placeId}) async {
    composeAsked.add(placeId);
    _maybeFail('findCompose');
    return compose;
  }

  @override
  Future<({Review review, ReviewCompose compose})> findForEdit(int id) async {
    _maybeFail('findForEdit');
    final data = edits[id];
    if (data == null) {
      throw const ApiException('Review này không còn tồn tại.', statusCode: 404);
    }
    return data;
  }

  @override
  Future<ReviewSaved> create(Review review, {List<String> imagePaths = const []}) async {
    _maybeFail('create');
    created.add((review: review, images: imagePaths));
    return (
      id: 50,
      placeId: review.placeId ?? 77,
      status: imagePaths.isEmpty ? 'PUBLISHED' : 'PROCESSING',
      changed: true,
      message: imagePaths.isEmpty
          ? 'Đã đăng review. +10 điểm.'
          : 'Đã gửi. Ảnh/video đang được quét, review hiện cho mọi người sau khi đạt.',
    );
  }

  @override
  Future<ReviewSaved> update(Review review, {List<String> imagePaths = const []}) async {
    _maybeFail('update');
    updated.add((review: review, images: imagePaths));
    return (id: review.id!, placeId: 11, status: 'PUBLISHED', changed: true, message: 'Đã lưu thay đổi.');
  }

  @override
  Future<String> delete(int id) async {
    _maybeFail('delete');
    deleted.add(id);
    return 'Đã xóa review. Điểm của review này được thu lại.';
  }
}

/// Bộ đọc tiếng Nhật giả: nhớ câu đã đọc; [works] false như máy không có giọng ja-JP.
class FakePlaceSpeaker implements PlaceSpeaker {
  final List<String> spoken = [];
  bool works = true;

  @override
  Future<bool> speak(String text) async {
    spoken.add(text);
    return works;
  }

  @override
  Future<void> stop() async {}
}

/// Định vị giả: trả về [position]; null như người dùng từ chối quyền.
class FakePlaceLocator implements PlaceLocator {
  FakePlaceLocator([this.position]);

  ({double lat, double lng})? position;
  int asked = 0;

  @override
  Future<({double lat, double lng})?> current() async {
    asked++;
    return position;
  }
}

class _FakeNotificationDao implements NotificationDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mọi thứ một widget test của Bản đồ cần: DAO giả, plugin giả, và app có đủ Controller.
///
/// Bản đồ mở giữa các ghim mẫu ở mức phóng to 16, để mọi ghim nằm trong khung (ghim ngoài khung không được dựng).
class MapTestKit {
  MapTestKit({User? user}) : auth = FakeAuthDao(current: user) {
    final sample = places.overview;
    places.overview = MapOverview(
      categories: sample.categories,
      places: sample.places,
      center: const MapCenter(lat: 35.7276, lng: 139.7700, zoom: 16, label: 'Arakawa-ku, Tokyo'),
      signedIn: user != null,
    );
  }

  final FakeAuthDao auth;
  final places = FakePlaceDao();
  final reviews = FakeReviewDao();
  final speaker = FakePlaceSpeaker();
  final locator = FakePlaceLocator((lat: 35.7289, lng: 139.7713));

  /// App với [home] và các Controller dùng DAO giả. Đã đăng nhập thì khôi phục phiên ngay khi tạo.
  /// [theme]: theme của app (ảnh chụp so thiết kế truyền SenpaiTheme.light(), để cả màn mở sau cũng đúng theme).
  Widget app(Widget home, {ThemeData? theme}) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthController(auth)..restoreSession()),
      ChangeNotifierProvider(create: (_) => NotificationController(_FakeNotificationDao())),
      ChangeNotifierProvider(
        create: (_) => PlaceController(places, speaker: speaker, locator: locator),
      ),
      ChangeNotifierProvider(create: (_) => ReviewController(reviews)),
    ],
    child: MaterialApp(debugShowCheckedModeBanner: false, theme: theme, home: home),
  );
}

/// Người dùng đã đăng nhập dùng trong widget test.
const signedInUser = testUser;
