import 'package:flutter/foundation.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/profile_dao.dart';
import 'package:myasvsj/com.myasvsj.model/tag_compose.dart';
import 'package:myasvsj/com.myasvsj.model/tag_option.dart';
import 'package:myasvsj/com.myasvsj.model/tag_pending_request.dart';
import 'package:myasvsj/com.myasvsj.model/tag_request.dart';

/// Controller của màn "Xin tag định danh" (TagRequestScreen): chọn tag, loại minh chứng, một ảnh, đồng ý cho
/// Kiểm duyệt viên xem ảnh, rồi gửi `POST /api/me/tag-requests`. Đang có yêu cầu chờ duyệt thì không gửi được.
class TagRequestController extends ChangeNotifier {
  TagRequestController(this._dao);

  final ProfileDao _dao;

  TagCompose? compose;
  bool isLoading = false;
  String? error;

  // ----- Form
  int? tagId;
  int? proofTypeId;

  /// Ảnh minh chứng (tối đa 1), đường dẫn trên máy do PhotoPicker trả về.
  List<String> photoPaths = [];
  bool consent = false;

  bool isSubmitting = false;

  /// Lỗi chung của form (câu đầu tiên, hoặc lỗi server như "Bạn đang có một yêu cầu tag chờ duyệt.").
  String? formError;

  /// Lỗi theo ô: `tagId`, `proofTypeId`, `photo`, `consent` (cùng tên với lỗi server trả về).
  Map<String, String> fieldErrors = {};

  /// Câu của server sau khi gửi; màn hình lấy một lần bằng [takeMessage].
  String? message;

  TagPendingRequest? get pending => compose?.pending;

  TagOption? get selectedTag {
    for (final tag in compose?.tags ?? const <TagOption>[]) {
      if (tag.id == tagId) {
        return tag;
      }
    }
    return null;
  }

  /// Mở form: lấy danh sách tag và yêu cầu đang chờ (nếu có), xóa lựa chọn cũ.
  Future<void> open() async {
    compose = null;
    _resetForm();
    error = null;
    isLoading = true;
    notifyListeners();
    try {
      compose = await _dao.findTagCompose();
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _resetForm() {
    tagId = null;
    proofTypeId = null;
    photoPaths = [];
    consent = false;
    formError = null;
    fieldErrors = {};
  }

  /// Chọn tag; tag đã có thì không chọn được. Đổi tag thì chọn lại loại minh chứng.
  void selectTag(int? id) {
    TagOption? tag;
    for (final t in compose?.tags ?? const <TagOption>[]) {
      if (t.id == id) {
        tag = t;
      }
    }
    if (tag == null || tag.owned || tag.id == tagId) {
      return;
    }
    tagId = tag.id;
    proofTypeId = null;
    fieldErrors = {...fieldErrors}
      ..remove('tagId')
      ..remove('proofTypeId');
    notifyListeners();
  }

  void selectProofType(int? id) {
    proofTypeId = id;
    fieldErrors = {...fieldErrors}..remove('proofTypeId');
    notifyListeners();
  }

  void setPhotos(List<String> paths) {
    photoPaths = paths.take(1).toList();
    fieldErrors = {...fieldErrors}..remove('photo');
    notifyListeners();
  }

  void setConsent(bool value) {
    consent = value;
    fieldErrors = {...fieldErrors}..remove('consent');
    notifyListeners();
  }

  /// Kiểm tra trước khi gửi, cùng câu chữ với TagService của server (server kiểm tra lại).
  static Map<String, String> validate({
    required TagOption? tag,
    required int? proofTypeId,
    required String? photoPath,
    required bool consent,
  }) {
    final errors = <String, String>{};
    if (tag == null) {
      errors['tagId'] = 'Hãy chọn một tag.';
    } else if (!tag.selfieOnly && !tag.proofTypes.any((p) => p.id == proofTypeId)) {
      errors['proofTypeId'] = 'Hãy chọn loại minh chứng.';
    }
    if (photoPath == null) {
      errors['photo'] = tag != null && tag.selfieOnly ? 'Hãy chọn ảnh chân dung.' : 'Hãy chọn ảnh minh chứng.';
    }
    if (!consent) {
      errors['consent'] = 'Bạn cần đồng ý cho Kiểm duyệt viên xem ảnh.';
    }
    return errors;
  }

  /// Gửi yêu cầu. Trả về true khi server đã nhận; lúc đó [pending] là yêu cầu vừa gửi.
  Future<bool> submit() async {
    final tag = selectedTag;
    final photo = photoPaths.isEmpty ? null : photoPaths.first;
    fieldErrors = validate(tag: tag, proofTypeId: proofTypeId, photoPath: photo, consent: consent);
    formError = fieldErrors.isEmpty ? null : fieldErrors.values.first;
    if (fieldErrors.isNotEmpty || compose == null) {
      notifyListeners();
      return false;
    }
    isSubmitting = true;
    notifyListeners();
    try {
      final result = await _dao.submitTagRequest(
        TagRequest(
          tagId: tag!.id,
          // Tag chỉ cần ảnh chân dung: server tự dùng loại minh chứng duy nhất của nó
          proofTypeId: tag.selfieOnly ? null : proofTypeId,
          consent: consent,
          photoPath: photo,
        ),
      );
      message = result.message;
      compose = compose!.withPending(result.pending ?? TagPendingRequest(tagName: tag.name));
      _resetForm();
      return true;
    } on ApiException catch (e) {
      formError = e.message;
      fieldErrors = e.fields;
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  /// Lấy câu thông báo để hiện SnackBar, rồi xóa để không hiện lại.
  String? takeMessage() {
    final text = message;
    message = null;
    return text;
  }
}
