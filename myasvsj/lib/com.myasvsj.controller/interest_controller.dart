import 'package:flutter/foundation.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/interest_settings.dart';
import 'package:myasvsj/com.myasvsj.model/interest_topic.dart';
import 'package:myasvsj/com.myasvsj.model/profile_dao.dart';

/// Controller của màn "Chủ đề quan tâm" (InterestScreen): chọn tối đa [max] chủ đề blog cho "Dành cho bạn",
/// rồi lưu cả lựa chọn bằng `PUT /api/me/interests`.
class InterestController extends ChangeNotifier {
  InterestController(this._dao);

  final ProfileDao _dao;

  List<InterestTopic> topics = [];

  /// Số chủ đề chọn tối đa (server gửi, hiện là 5).
  int max = 5;

  /// Chủ đề đang chọn trên màn hình (có thể chưa lưu).
  List<int> selectedIds = [];
  List<int> _savedIds = [];

  bool isLoading = false;
  String? error;
  bool isSaving = false;
  String? saveError;

  /// Câu của server sau khi lưu; màn hình lấy một lần bằng [takeMessage].
  String? message;

  bool get isFull => selectedIds.length >= max;

  bool isSelected(int topicId) => selectedIds.contains(topicId);

  /// Lựa chọn khác với lần lưu gần nhất.
  bool get hasChanges => selectedIds.length != _savedIds.length || selectedIds.any((id) => !_savedIds.contains(id));

  /// Có chủ đề gợi ý chưa chọn (hiện dòng giải thích dấu gợi ý).
  bool get hasSuggestions => topics.any((t) => t.learnt && !isSelected(t.id));

  Future<void> load() async {
    isLoading = true;
    error = null;
    saveError = null;
    notifyListeners();
    try {
      _apply(await _dao.findInterests());
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _apply(InterestSettings settings) {
    max = settings.max;
    topics = settings.topics;
    _savedIds = [for (final t in settings.chosen) t.id];
    selectedIds = List.of(_savedIds);
  }

  /// Bấm một chủ đề: chọn hoặc bỏ chọn. Đã đủ [max] thì không chọn thêm được, trả về false.
  bool toggle(int topicId) {
    if (isSaving) {
      return false;
    }
    if (isSelected(topicId)) {
      selectedIds = [
        for (final id in selectedIds)
          if (id != topicId) id,
      ];
    } else if (isFull) {
      return false;
    } else {
      selectedIds = [...selectedIds, topicId];
    }
    saveError = null;
    notifyListeners();
    return true;
  }

  /// Kiểm tra trước khi gửi, giống InterestService (server kiểm tra lại).
  static String? validate(List<int> topicIds, int max) =>
      topicIds.toSet().length > max ? 'Bạn chọn được tối đa $max chủ đề.' : null;

  /// Lưu cả lựa chọn (rỗng là bỏ hết). Trả về true khi server đã lưu.
  Future<bool> save() async {
    saveError = validate(selectedIds, max);
    if (saveError != null) {
      notifyListeners();
      return false;
    }
    isSaving = true;
    notifyListeners();
    try {
      final result = await _dao.updateInterests(selectedIds);
      _apply(result.settings);
      message = result.message;
      return true;
    } on ApiException catch (e) {
      saveError = e.message;
      return false;
    } finally {
      isSaving = false;
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
