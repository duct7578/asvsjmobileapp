import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/map_festival.dart';
import 'package:myasvsj/com.myasvsj.model/map_overview.dart';
import 'package:myasvsj/com.myasvsj.model/map_search_result.dart';
import 'package:myasvsj/com.myasvsj.model/page_result.dart';
import 'package:myasvsj/com.myasvsj.model/place_detail.dart';
import 'package:myasvsj/com.myasvsj.model/place_phrase.dart';
import 'package:myasvsj/com.myasvsj.model/place_review.dart';

/// Truy cập dữ liệu Bản đồ và địa điểm qua REST API của web (MapController.java), đọc các bảng `places`,
/// `categories`, `reviews`, `review_likes`, `saved_places`, `place_closed_reports`.
///
/// | Hàm           | API                                          |
/// |---------------|----------------------------------------------|
/// | findMap       | GET /api/map                                 |
/// | findEvents    | GET /api/map/events?days=                    |
/// | search        | GET /api/map/search?q=                       |
/// | findNearby    | GET /api/map/nearby?lat=&lng=                |
/// | findById      | GET /api/map/places/{id}                     |
/// | findReviews   | GET /api/map/places/{id}/reviews?page=       |
/// | findPhrases   | GET /api/map/places/{id}/phrases             |
/// | save          | POST /api/map/places/{id}/save               |
/// | unsave        | DELETE /api/map/places/{id}/save             |
/// | reportClosed  | POST /api/map/places/{id}/closed-report      |
/// | likeReview    | POST /api/reviews/{id}/like                  |
/// | unlikeReview  | DELETE /api/reviews/{id}/like                |
/// | reportReview  | POST /api/reviews/{id}/report                |
class PlaceDao {
  PlaceDao(this._api);

  final ApiClient _api;

  /// Số review mỗi trang (server cố định 10).
  static const int reviewPageSize = 10;

  /// Danh mục kèm số lượng, mọi ghim (cộng ghim chờ duyệt của mình), nơi bản đồ mở ra. Ai cũng xem được.
  Future<MapOverview> findMap() async => MapOverview.fromJson(await _api.get('/api/map') as Map<String, dynamic>);

  /// Sự kiện đang diễn ra hoặc bắt đầu trong [days] ngày tới (15 hoặc 30).
  Future<List<MapFestival>> findEvents(int days) async {
    final data = await _api.get('/api/map/events', query: {'days': days}) as List;
    return [for (final e in data) MapFestival.fromJson(e as Map<String, dynamic>)];
  }

  /// Tìm danh mục và địa điểm. Khách chỉ được địa điểm Senpai ơi (`external` = LOGIN); người đã đăng nhập
  /// được thêm địa điểm OpenStreetMap.
  Future<MapSearchResult> search(String q) async =>
      MapSearchResult.fromJson(await _api.get('/api/map/search', query: {'q': q}) as Map<String, dynamic>);

  /// "Địa điểm quanh đây": địa điểm Senpai ơi trong 150 m và địa điểm OpenStreetMap quanh điểm vừa chạm.
  /// Chỉ người đã đăng nhập; khách nhận 401 "Hãy đăng nhập để chọn địa điểm trên bản đồ.".
  Future<MapSearchResult> findNearby(double lat, double lng) async => MapSearchResult.fromJson(
    await _api.get('/api/map/nearby', query: {'lat': lat, 'lng': lng}) as Map<String, dynamic>,
  );

  /// Chi tiết địa điểm. Địa điểm đã gộp trả về địa điểm đích (có `mergedFrom`); địa điểm đã gỡ hoặc ghim chờ duyệt
  /// của người khác: 404 "Địa điểm này không còn trên Senpai ơi.".
  Future<PlaceDetail> findById(int id) async =>
      PlaceDetail.fromJson(await _api.get('/api/map/places/$id') as Map<String, dynamic>);

  /// Một trang review (mới nhất trước, 10 review), cộng review của mình đang quét ảnh. Server trả
  /// `{items, page, size, total}`, đổi thành [PageResult].
  Future<PageResult<PlaceReview>> findReviews(int placeId, {int page = 0}) async {
    final data = await _api.get('/api/map/places/$placeId/reviews', query: {'page': page}) as Map<String, dynamic>;
    final size = (data['size'] ?? reviewPageSize) as int;
    final total = (data['total'] ?? 0) as int;
    return PageResult(
      items: [for (final r in (data['items'] as List?) ?? const []) PlaceReview.fromJson(r as Map<String, dynamic>)],
      page: (data['page'] ?? page) as int,
      size: size,
      totalItems: total,
      totalPages: size <= 0 ? 0 : (total + size - 1) ~/ size,
    );
  }

  /// Từ vựng và mẫu câu tiếng Nhật theo danh mục của địa điểm.
  Future<List<PlacePhrase>> findPhrases(int placeId) async {
    final data = await _api.get('/api/map/places/$placeId/phrases') as List;
    return [for (final p in data) PlacePhrase.fromJson(p as Map<String, dynamic>)];
  }

  /// Lưu địa điểm; trả về "Đã lưu địa điểm.".
  Future<String> save(int placeId) async => (await _api.post('/api/map/places/$placeId/save')).message;

  /// Bỏ lưu; trả về "Đã bỏ lưu địa điểm.".
  Future<String> unsave(int placeId) async => (await _api.delete('/api/map/places/$placeId/save')).message;

  /// "Báo đã đóng cửa" (mỗi người một lần, lần hai 409 "Bạn đã báo địa điểm này rồi."). Trả về số báo hiện có,
  /// ngưỡng (5), đã vào hàng chờ Moderator chưa, và câu thông báo của server.
  Future<({int count, int threshold, bool queued, String message})> reportClosed(int placeId) async {
    final response = await _api.post('/api/map/places/$placeId/closed-report');
    final data = response.data as Map<String, dynamic>;
    return (
      count: (data['count'] ?? 0) as int,
      threshold: (data['threshold'] ?? 5) as int,
      queued: (data['queued'] ?? false) as bool,
      message: response.message,
    );
  }

  /// Thích review của người khác; trả về trạng thái và số lượt thích mới (server đếm lại).
  Future<({bool active, int count})> likeReview(int reviewId) async =>
      _likeState((await _api.post('/api/reviews/$reviewId/like')).data);

  /// Bỏ thích review.
  Future<({bool active, int count})> unlikeReview(int reviewId) async =>
      _likeState((await _api.delete('/api/reviews/$reviewId/like')).data);

  /// Báo cáo review với lý do [reasonId]; trả về "Đã gửi báo cáo cho Moderator.".
  Future<String> reportReview(int reviewId, int reasonId, String note) async => (await _api.post(
    '/api/reviews/$reviewId/report',
    {'reasonId': reasonId, 'note': note.trim().isEmpty ? null : note.trim()},
  )).message;

  static ({bool active, int count}) _likeState(Object? data) {
    final json = data as Map<String, dynamic>;
    return (active: (json['active'] ?? false) as bool, count: (json['count'] ?? 0) as int);
  }
}
