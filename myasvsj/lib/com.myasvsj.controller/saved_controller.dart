import 'package:flutter/foundation.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/saved_dao.dart';
import 'package:myasvsj/com.myasvsj.model/saved_item.dart';
import 'package:myasvsj/com.myasvsj.model/saved_list.dart';

/// Controller của màn "Đã lưu" (SavedScreen): danh sách địa điểm, bài viết, câu hỏi, cẩm nang đã lưu và "Bỏ lưu".
///
/// Bỏ lưu là cập nhật lạc quan: mục biến mất ngay, server từ chối thì mục quay lại đúng chỗ cũ.
class SavedController extends ChangeNotifier {
  SavedController(this._dao);

  final SavedDao _dao;

  SavedList saved = const SavedList();
  bool isLoading = false;

  /// Đã tải xong ít nhất một lần (phân biệt "chưa tải" với "chưa lưu gì").
  bool isLoaded = false;
  String? error;

  /// Câu của server sau khi bỏ lưu / hoàn tác (hoặc câu lỗi); màn hình lấy một lần bằng [takeMessage].
  String? message;

  /// Mục vừa bỏ lưu thành công và vị trí cũ của nó, để "Hoàn tác".
  ({SavedItem item, int index})? _lastRemoved;

  bool get canUndo => _lastRemoved != null;

  /// Tải danh sách. Đang có danh sách thì vẫn giữ để hiện trong lúc tải lại (kéo xuống làm mới, quay về từ
  /// màn chi tiết).
  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      saved = await _dao.findAll();
      isLoaded = true;
      _lastRemoved = null;
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Bỏ lưu [item]. Trả về true khi server đã bỏ; lỗi thì mục được trả lại chỗ cũ.
  Future<bool> unsave(SavedItem item) async {
    final index = saved.indexOf(item);
    if (index < 0) {
      return false;
    }
    saved = saved.without(item);
    _lastRemoved = null;
    notifyListeners();
    try {
      message = await _dao.unsave(item.kind, item.id);
      _lastRemoved = (item: item, index: index);
      return true;
    } on ApiException catch (e) {
      saved = saved.withItemAt(item, index);
      message = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Lưu lại mục vừa bỏ lưu, đúng chỗ cũ. Trả về true khi server đã lưu lại.
  Future<bool> undoUnsave() async {
    final last = _lastRemoved;
    if (last == null) {
      return false;
    }
    _lastRemoved = null;
    saved = saved.withItemAt(last.item, last.index);
    notifyListeners();
    try {
      message = await _dao.save(last.item.kind, last.item.id);
      return true;
    } on ApiException catch (e) {
      saved = saved.without(last.item);
      message = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Xóa dữ liệu của người vừa đăng xuất.
  void clear() {
    saved = const SavedList();
    isLoaded = false;
    error = null;
    _lastRemoved = null;
    notifyListeners();
  }

  /// Lấy câu thông báo để hiện SnackBar, rồi xóa để không hiện lại.
  String? takeMessage() {
    final text = message;
    message = null;
    return text;
  }
}
