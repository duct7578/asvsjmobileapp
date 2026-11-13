import 'package:flutter/foundation.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/search_dao.dart';
import 'package:myasvsj/com.myasvsj.model/search_result.dart';

/// Controller của màn "Tìm kiếm" chung: tìm một từ khóa trong mọi phần của Senpai ơi bằng [SearchDao].
class GlobalSearchController extends ChangeNotifier {
  GlobalSearchController(this._dao);

  final SearchDao _dao;

  /// Từ khóa tối đa 100 ký tự (giống server).
  static const int queryMax = 100;
  static const String queryTooLong = 'Từ khóa tìm kiếm tối đa $queryMax ký tự.';

  /// Gợi ý dưới ô tìm kiếm còn trống: những thứ du học sinh mới đến hay tìm (như web).
  static const List<String> ideas = ['Thẻ cư trú', 'Ngân hàng', 'Nhà ở', 'Làm thêm', 'Bệnh viện', 'Ga tàu'];

  /// Từ khóa của kết quả đang hiện (đã bỏ khoảng trắng hai đầu); rỗng khi ô trống, null trước lần tìm đầu.
  String? asked;

  /// Kết quả của [asked]; null khi ô trống.
  SearchResult? result;
  bool isLoading = false;
  String? error;
  int _ticket = 0;

  /// Xóa kết quả cũ khi mở màn hình mới.
  void reset() {
    _ticket++;
    asked = null;
    result = null;
    isLoading = false;
    error = null;
    notifyListeners();
  }

  /// Tìm [text]. Bỏ qua khi trùng từ khóa đang hiện, trừ khi [always] (Enter, bấm gợi ý, thử lại).
  /// Ô trống: không gọi server, chỉ hiện gợi ý. Quá 100 ký tự: báo lỗi, không gọi server.
  Future<void> search(String text, {bool always = false}) async {
    final q = text.trim();
    if (q == asked && !always) {
      return;
    }
    if (q.length > queryMax) {
      error = queryTooLong;
      notifyListeners();
      return;
    }
    final ticket = ++_ticket;
    error = null;
    if (q.isEmpty) {
      asked = '';
      result = null;
      isLoading = false;
      notifyListeners();
      return;
    }
    isLoading = true;
    notifyListeners();
    try {
      final found = await _dao.search(q);
      if (ticket == _ticket) {
        asked = q;
        result = found;
      }
    } on ApiException catch (e) {
      if (ticket == _ticket) {
        error = e.message;
      }
    } finally {
      if (ticket == _ticket) {
        isLoading = false;
        notifyListeners();
      }
    }
  }
}
