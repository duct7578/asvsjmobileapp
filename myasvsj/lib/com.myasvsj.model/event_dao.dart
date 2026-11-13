import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/event.dart';
import 'package:myasvsj/com.myasvsj.model/event_detail.dart';
import 'package:myasvsj/com.myasvsj.model/event_review_form.dart';

/// Truy cập dữ liệu "Lễ hội và sự kiện" và review sự kiện qua REST API của web
/// (bảng `events`, và bảng `reviews` có `event_id`).
///
/// | Hàm             | API                                         |
/// |-----------------|---------------------------------------------|
/// | findAll         | GET /api/events?q=                          |
/// | findById        | GET /api/events/{id}                        |
/// | findReviewForm  | GET /api/events/{id}/review-form            |
/// | createReview    | POST /api/events/{id}/reviews (multipart)   |
/// | updateReview    | PUT /api/event-reviews/{id} (multipart)     |
/// | deleteReview    | DELETE /api/event-reviews/{id}              |
/// | likeReview      | POST /api/event-reviews/{id}/like           |
/// | unlikeReview    | DELETE /api/event-reviews/{id}/like         |
/// | reportReview    | POST /api/event-reviews/{id}/report         |
class EventDao {
  EventDao(this._api);

  final ApiClient _api;

  /// Mọi sự kiện, sớm nhất trước; [q] lọc theo tên, nơi tổ chức hoặc chi phí (không phân biệt dấu).
  /// Server trả cả danh sách, không phân trang. Ai cũng xem được.
  Future<List<Event>> findAll({String? q}) async {
    final data = await _api.get('/api/events', query: {if (q != null && q.trim().isNotEmpty) 'q': q.trim()}) as List;
    return [for (final item in data) Event.fromJson(item as Map<String, dynamic>)];
  }

  /// Chi tiết một sự kiện: album ảnh, mẹo, review, quyền của người xem. Sự kiện đã xóa → 404.
  Future<EventDetail> findById(int id) async =>
      EventDetail.fromJson(await _api.get('/api/events/$id') as Map<String, dynamic>);

  /// Form "Viết review": giới hạn, hạn mức hôm nay và review năm nay của người xem (để sửa).
  /// Chỉ User; sự kiện chưa bắt đầu → 400 "Viết review được khi sự kiện bắt đầu.".
  Future<EventReviewForm> findReviewForm(int eventId) async =>
      EventReviewForm.fromJson(await _api.get('/api/events/$eventId/review-form') as Map<String, dynamic>);

  /// Đăng review năm nay: phần JSON "review" `{rating, content}` và các ảnh ở phần "images".
  /// Trả về câu của server: "Đã đăng review. +10 điểm." hoặc "Đã gửi. Ảnh và video đang được quét…".
  /// Đã có review năm nay → 409 "Bạn đã viết review cho lần tổ chức năm …".
  Future<String> createReview(
    int eventId, {
    required int rating,
    required String content,
    List<String> imagePaths = const [],
  }) async {
    final response = await _api.sendMultipart(
      'POST',
      '/api/events/$eventId/reviews',
      jsonPart: 'review',
      json: {'rating': rating, 'content': content},
      files: {if (imagePaths.isNotEmpty) 'images': imagePaths},
    );
    return response.message;
  }

  /// Lưu review đã sửa: [keepMediaIds] là ảnh / video cũ giữ lại (theo thứ tự), [imagePaths] là ảnh mới.
  /// Trả về "Đã lưu thay đổi." (hoặc kèm câu đang quét ảnh).
  Future<String> updateReview(
    int reviewId, {
    required int rating,
    required String content,
    List<int> keepMediaIds = const [],
    List<String> imagePaths = const [],
  }) async {
    final response = await _api.sendMultipart(
      'PUT',
      '/api/event-reviews/$reviewId',
      jsonPart: 'review',
      json: {'rating': rating, 'content': content, 'keepMediaIds': keepMediaIds},
      files: {if (imagePaths.isNotEmpty) 'images': imagePaths},
    );
    return response.message;
  }

  /// Xóa review của chính mình; trả về "Đã xóa review. Điểm của review này được thu lại.".
  Future<String> deleteReview(int reviewId) async => (await _api.delete('/api/event-reviews/$reviewId')).message;

  /// Thích review của người khác; trả về trạng thái mới và số lượt thích.
  Future<({bool liked, int likeCount})> likeReview(int reviewId) async =>
      _likeState((await _api.post('/api/event-reviews/$reviewId/like')).data);

  /// Bỏ thích.
  Future<({bool liked, int likeCount})> unlikeReview(int reviewId) async =>
      _likeState((await _api.delete('/api/event-reviews/$reviewId/like')).data);

  /// Báo cáo review với một lý do và ghi chú (không bắt buộc); trả về "Cảm ơn bạn. Báo cáo đã được gửi.".
  Future<String> reportReview(int reviewId, {required int reasonId, String note = ''}) async => (await _api.post(
    '/api/event-reviews/$reviewId/report',
    {'reasonId': reasonId, 'note': note.trim().isEmpty ? null : note.trim()},
  )).message;

  static ({bool liked, int likeCount}) _likeState(Object? data) {
    final json = data as Map<String, dynamic>;
    return (liked: (json['liked'] ?? false) as bool, likeCount: (json['likeCount'] ?? 0) as int);
  }
}
