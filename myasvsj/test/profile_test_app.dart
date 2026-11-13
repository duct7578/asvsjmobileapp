// Dùng chung cho widget test của trang Tôi, Đã lưu, Lịch sử điểm, Khu vực, Chủ đề quan tâm, Xin tag.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/area_stage_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/interest_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/profile_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/saved_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/tag_request_controller.dart';

import 'auth_fakes.dart';
import 'profile_fakes.dart';
import 'saved_fakes.dart';

/// App thử: cấp AuthController và mọi Controller của phần Tôi, tất cả dùng DAO giả.
/// [signedIn] false là khách. [observer] ghi lại các màn hình được mở.
Widget profileTestApp(
  Widget home, {
  bool signedIn = true,
  FakeProfileDao? profileDao,
  FakeSavedDao? savedDao,
  PushRecorder? observer,
}) {
  final profiles = profileDao ?? FakeProfileDao();
  final saved = savedDao ?? FakeSavedDao();
  return MultiProvider(
    // Mỗi lần gọi là một app mới: pumpWidget lần hai trong cùng test không dùng lại Controller cũ
    key: UniqueKey(),
    providers: [
      // restoreSession lấy người đang đăng nhập từ DAO giả, như lúc mở app
      ChangeNotifierProvider(
        create: (_) => AuthController(FakeAuthDao(current: signedIn ? testUser : null))..restoreSession(),
      ),
      ChangeNotifierProvider(create: (_) => ProfileController(profiles)),
      ChangeNotifierProvider(create: (_) => AreaStageController(profiles)),
      ChangeNotifierProvider(create: (_) => InterestController(profiles)),
      ChangeNotifierProvider(create: (_) => TagRequestController(profiles)),
      ChangeNotifierProvider(create: (_) => SavedController(saved)),
    ],
    child: MaterialApp(home: home, navigatorObservers: [?observer]),
  );
}

/// Màn hình hẹp 360 dp (điện thoại nhỏ) để bắt chữ tràn.
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Ghi lại màn hình được mở bằng Navigator.push.
///
/// Màn hình của agent khác (PlaceDetailScreen, ChangePasswordScreen…) cần Controller riêng của họ, nên test chỉ
/// kiểm tra màn hình nào được mở với tham số nào, rồi gỡ route trước khi nó kịp dựng ([takeScreen]).
class PushRecorder extends NavigatorObserver {
  /// Các route đã mở, không tính màn hình đầu của app.
  final List<Route<dynamic>> pushed = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      pushed.add(route);
    }
  }

  /// Widget màn hình của route mở sau cùng (không dựng nó); gỡ route đó khỏi Navigator.
  Widget takeScreen() {
    final route = pushed.removeLast() as MaterialPageRoute<dynamic>;
    final screen = route.builder(navigator!.context);
    navigator!.removeRoute(route);
    return screen;
  }
}
