import 'package:flutter/widgets.dart';

/// Cho State của các màn hình cá nhân (Tôi, Đã lưu, Lịch sử điểm…): báo [onUserChanged] sau khung hình khi
/// người đăng nhập đổi – lúc mở màn hình, khi khách vừa đăng nhập, hoặc khi đăng xuất – để tải lại dữ liệu
/// của đúng người đó.
///
/// Gọi [watchUser] trong `build` với `context.watch<AuthController>().currentUser?.id`.
mixin ProfileUserWatcher<T extends StatefulWidget> on State<T> {
  bool _started = false;
  int? _userId;

  void watchUser(int? userId) {
    if (_started && userId == _userId) {
      return;
    }
    _started = true;
    _userId = userId;
    // notifyListeners() của Controller không được chạy giữa lúc đang dựng giao diện
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        onUserChanged(userId);
      }
    });
  }

  /// [userId] null là khách.
  void onUserChanged(int? userId);
}
