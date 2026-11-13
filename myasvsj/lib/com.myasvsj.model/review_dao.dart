import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/api_response.dart';
import 'package:myasvsj/com.myasvsj.model/review.dart';
import 'package:myasvsj/com.myasvsj.model/review_compose.dart';

/// Kết quả lưu review (Saved của web): [changed] false khi bản sửa không đổi gì; [status] PROCESSING khi ảnh
/// đang được quét (chỉ tác giả thấy review); [message] là câu thông báo của server.
typedef ReviewSaved = ({int id, int placeId, String status, bool changed, String message});

/// Truy cập dữ liệu review địa điểm (CRUD) qua REST API của web (ReviewController.java), ghi vào bảng `reviews`.
/// Chỉ User đã đăng nhập gọi được.
///
/// | Hàm          | API                                         |
/// |--------------|---------------------------------------------|
/// | findCompose  | GET /api/reviews/compose?placeId=           |
/// | findForEdit  | GET /api/reviews/{id}/edit                  |
/// | create       | POST /api/reviews (multipart "review" + "images") |
/// | update       | PUT /api/reviews/{id} (multipart)           |
/// | delete       | DELETE /api/reviews/{id}                    |
class ReviewDao {
  ReviewDao(this._api);

  final ApiClient _api;

  /// Giới hạn nhập, lượt đăng hôm nay, và `myReviewId` khi mình đã review [placeId]. Không có [placeId] (địa điểm
  /// OpenStreetMap chưa có trên Senpai ơi) thì chỉ có giới hạn và lượt đăng. Khách nhận 401.
  Future<ReviewCompose> findCompose({int? placeId}) async => ReviewCompose.fromJson(
    await _api.get('/api/reviews/compose', query: {'placeId': ?placeId}) as Map<String, dynamic>,
  );

  /// Review như đang lưu, kèm giới hạn nhập. Chỉ tác giả gọi được; người khác nhận 403.
  Future<({Review review, ReviewCompose compose})> findForEdit(int id) async {
    final data = await _api.get('/api/reviews/$id/edit') as Map<String, dynamic>;
    return (review: Review.fromEditJson(data), compose: ReviewCompose.fromJson(data));
  }

  /// Đăng review mới, kèm ảnh mới [imagePaths] (≤ 5, đường dẫn trên máy). Không có ảnh: đăng ngay, +10 điểm
  /// ("Đã đăng review. +10 điểm."); có ảnh: PROCESSING tới khi quét xong.
  Future<ReviewSaved> create(Review review, {List<String> imagePaths = const []}) async => _saved(
    await _api.sendMultipart(
      'POST',
      '/api/reviews',
      jsonPart: 'review',
      json: review.toJson(),
      files: {if (imagePaths.isNotEmpty) 'images': imagePaths},
    ),
  );

  /// Lưu review đã sửa: giữ ảnh trong `review.media` (`keepMediaIds`), thêm ảnh mới [imagePaths].
  /// Trả về "Đã lưu thay đổi." hoặc "Không có thay đổi nào." ([ReviewSaved.changed] false).
  Future<ReviewSaved> update(Review review, {List<String> imagePaths = const []}) async => _saved(
    await _api.sendMultipart(
      'PUT',
      '/api/reviews/${review.id}',
      jsonPart: 'review',
      json: review.toJson(),
      files: {if (imagePaths.isNotEmpty) 'images': imagePaths},
    ),
  );

  /// Xóa review của mình; trả về "Đã xóa review. Điểm của review này được thu lại.".
  Future<String> delete(int id) async => (await _api.delete('/api/reviews/$id')).message;

  static ReviewSaved _saved(ApiResponse response) {
    final data = response.data as Map<String, dynamic>;
    return (
      id: data['id'] as int,
      placeId: data['placeId'] as int,
      status: (data['status'] ?? 'PUBLISHED') as String,
      changed: (data['changed'] ?? true) as bool,
      message: response.message,
    );
  }
}
