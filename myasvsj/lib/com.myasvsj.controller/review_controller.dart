import 'package:flutter/foundation.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.model/review.dart';
import 'package:myasvsj/com.myasvsj.model/review_compose.dart';
import 'package:myasvsj/com.myasvsj.model/review_dao.dart';

/// Controller của form review địa điểm (ReviewFormScreen): viết, sửa, xóa review.
///
/// Mỗi người một review cho một địa điểm: mở form "Viết review" cho nơi đã review thì form chuyển sang sửa
/// review đó (giống web). Màn chi tiết địa điểm tải lại địa điểm sau khi form lưu xong ([savedPlaceId]).
class ReviewController extends ChangeNotifier {
  ReviewController(this._dao);

  final ReviewDao _dao;

  /// Số sao tối đa. Các giới hạn khác (độ dài nội dung, số ảnh) lấy từ `limits` của server ([compose]).
  static const int ratingMax = 5;

  /// Giới hạn nhập và lượt đăng hôm nay; null khi chưa mở form hoặc không mở được.
  ReviewCompose? compose;

  /// Review đang sửa; null khi form viết review mới.
  Review? editing;
  bool isLoadingForm = false;
  bool isSaving = false;
  String? formError;
  Map<String, String> fieldErrors = {};

  /// Địa điểm của review vừa lưu (địa điểm OpenStreetMap được thêm khi lưu review đầu tiên).
  int? savedPlaceId;

  /// Câu thông báo của server sau khi lưu, xóa; màn hình hiện một lần bằng [takeMessage].
  String? message;

  // ---------------------------------------------------------------- Mở form

  /// Mở form. Sửa khi có [reviewId]; viết mới cho [placeId] hoặc [externalPlaceId] (địa điểm OpenStreetMap), và
  /// chuyển sang sửa khi server báo mình đã review nơi này (`myReviewId`).
  Future<void> openForm({int? placeId, String? externalPlaceId, int? reviewId}) async {
    compose = null;
    editing = null;
    formError = null;
    fieldErrors = {};
    isLoadingForm = true;
    notifyListeners();
    try {
      var editId = reviewId;
      if (editId == null) {
        compose = await _dao.findCompose(placeId: placeId);
        editId = compose!.myReviewId;
      }
      if (editId != null) {
        final data = await _dao.findForEdit(editId);
        editing = data.review;
        compose = data.compose;
      }
    } on ApiException catch (e) {
      compose = null;
      formError = e.message;
    } finally {
      isLoadingForm = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- Create, Update

  /// Lưu form: viết review mới khi [editing] là null, ngược lại lưu review đang sửa với ảnh cũ giữ lại [keep].
  /// [imagePaths] là ảnh mới trên máy. Trả về true khi server đã lưu.
  Future<bool> saveReview({
    int? placeId,
    String? externalPlaceId,
    required int rating,
    required String content,
    List<MediaItem> keep = const [],
    List<String> imagePaths = const [],
  }) async {
    final limits = compose ?? const ReviewCompose();
    final old = editing;
    formError = null;
    fieldErrors = validate(
      rating: rating,
      content: content,
      imageCount: imagePaths.length + (old == null ? 0 : keep.where((m) => m.isImage).length),
      compose: limits,
    );
    if (old == null && placeId == null && (externalPlaceId == null || externalPlaceId.isEmpty)) {
      fieldErrors['place'] = 'Hãy chọn địa điểm.';
    }
    if (fieldErrors.isNotEmpty) {
      notifyListeners();
      return false;
    }
    final review = Review(
      id: old?.id,
      placeId: old?.placeId ?? placeId,
      externalPlaceId: externalPlaceId,
      rating: rating,
      content: content.trim(),
      // App chỉ sửa ảnh: video đã gắn (đăng từ web) được giữ nguyên, vì server bỏ file không có trong keepMediaIds
      media: old == null
          ? const []
          : [
              ...keep,
              for (final m in old.media)
                if (!m.isImage && !keep.any((k) => k.id == m.id)) m,
            ],
    );
    isSaving = true;
    notifyListeners();
    try {
      final saved = old == null
          ? await _dao.create(review, imagePaths: imagePaths)
          : await _dao.update(review, imagePaths: imagePaths);
      message = saved.message;
      savedPlaceId = saved.placeId;
      return true;
    } on ApiException catch (e) {
      formError = e.message;
      fieldErrors = e.fields;
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Kiểm tra trước khi gửi (giống `checkWrite` của web); trả về lỗi theo từng ô, rỗng khi hợp lệ.
  static Map<String, String> validate({
    required int rating,
    required String content,
    int imageCount = 0,
    ReviewCompose compose = const ReviewCompose(),
  }) {
    final errors = <String, String>{};
    if (rating < 1 || rating > ratingMax) {
      errors['rating'] = 'Hãy chọn số sao.';
    }
    final length = content.trim().length;
    if (length < compose.contentMin) {
      errors['content'] = 'Nội dung cần ít nhất ${compose.contentMin} ký tự.';
    } else if (length > compose.contentMax) {
      errors['content'] = 'Nội dung tối đa 2.000 ký tự.';
    }
    if (imageCount > compose.imagesMax) {
      errors['images'] = 'Tối đa ${compose.imagesMax} ảnh.';
    }
    return errors;
  }

  // ---------------------------------------------------------------- Delete

  /// Xóa review; trả về true khi server đã xóa. Câu thông báo (thành công hay lỗi) nằm ở [message].
  Future<bool> deleteReview(int id) async {
    try {
      message = await _dao.delete(id);
      if (editing?.id == id) {
        editing = null;
      }
      return true;
    } on ApiException catch (e) {
      message = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Lấy câu thông báo để hiện SnackBar, rồi xóa để không hiện lại lần nữa.
  String? takeMessage() {
    final text = message;
    message = null;
    return text;
  }
}
