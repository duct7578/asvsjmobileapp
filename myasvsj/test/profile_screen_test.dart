// Widget test của trang "Tôi" (ProfileScreen) với DAO giả.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/user_profile.dart';
import 'package:myasvsj/com.myasvsj.screen/area_stage_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/change_password_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/delete_account_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/interest_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/my_guides_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/point_history_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/saved_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/tag_request_screen.dart';

import 'profile_fakes.dart';
import 'profile_test_app.dart';

final _list = find.byType(Scrollable).first;

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: _list);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('hiện tên, tag, điểm, cấp bậc, hạn mức tài khoản mới và các mục', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(profileTestApp(const ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text('An'), findsOneWidget);
    expect(find.text('Kouhai'), findsOneWidget);
    expect(find.text('an@example.com · Đăng nhập bằng: Email và mật khẩu'), findsOneWidget);
    expect(find.text('130 điểm'), findsOneWidget);
    expect(find.text('Còn 170 điểm nữa lên Senpai tin cậy'), findsOneWidget);
    expect(find.text('Đã đạt'), findsNWidgets(2));
    expect(find.text('• Huy hiệu trên hồ sơ'), findsOneWidget);

    await _scrollTo(tester, find.text('Tài khoản mới'));
    expect(find.text('Hôm nay: 1/3 bài viết và review · 0/2 ghim · 0/1 video'), findsOneWidget);

    await _scrollTo(tester, find.text('Đã lưu (4)'));
    expect(find.text('Mới đến · Arakawa-ku, Tokyo · 東京都荒川区'), findsOneWidget);
    expect(find.text('Kinh nghiệm'), findsOneWidget, reason: 'chủ đề quan tâm đã chọn');
    expect(find.text('Xin tag định danh'), findsOneWidget);
  });

  testWidgets('đang tải hiện vòng quay, lỗi hiện câu của server và Thử lại', (tester) async {
    final dao = FakeProfileDao()..hold = Completer<void>();
    await tester.pumpWidget(profileTestApp(const ProfileScreen(), profileDao: dao));
    await tester.pump();
    expect(find.byType(LoadingView), findsOneWidget);

    dao.failWith = const ApiException('Không kết nối được tới server.');
    dao.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Không kết nối được tới server.'), findsOneWidget);

    dao.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('130 điểm'), findsOneWidget);
  });

  testWidgets('khách thấy lời mời đăng nhập; bấm Đăng nhập thì sang LoginScreen', (tester) async {
    await tester.pumpWidget(profileTestApp(const ProfileScreen(), signedIn: false));
    await tester.pumpAndSettle();
    expect(find.text('130 điểm'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('yêu cầu tag đang chờ thay cho nút Xin tag định danh', (tester) async {
    final dao = FakeProfileDao()
      ..profile = const UserProfile(
        id: 1,
        email: 'an@example.com',
        displayName: 'An',
        ranks: ranks,
        pendingTag: 'Mentor',
      );
    await tester.pumpWidget(profileTestApp(const ProfileScreen(), profileDao: dao));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Yêu cầu tag Mentor đang chờ duyệt'));
    expect(find.text('Xin tag định danh'), findsNothing);
  });

  testWidgets('Lịch sử điểm mở màn hình lịch sử của mình', (tester) async {
    await tester.pumpWidget(profileTestApp(const ProfileScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lịch sử điểm'));
    await tester.pumpAndSettle();
    expect(find.byType(PointHistoryScreen), findsOneWidget);
    expect(find.text('Ga Nippori'), findsOneWidget);
  });

  testWidgets('đổi giai đoạn ở Khu vực và giai đoạn, quay về thì trang Tôi tải lại', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(profileTestApp(const ProfileScreen()));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Khu vực và giai đoạn'));
    await tester.tap(find.text('Khu vực và giai đoạn'));
    await tester.pumpAndSettle();
    expect(find.byType(AreaStageScreen), findsOneWidget);

    await tester.tap(find.text('Sắp sang Nhật'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Lưu'),
      200,
      scrollable: find.descendant(of: find.byType(AreaStageScreen), matching: find.byType(Scrollable)).first,
    );
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.byType(AreaStageScreen), findsNothing);
    expect(find.text('Đã lưu khu vực và giai đoạn.'), findsOneWidget);
    expect(find.textContaining('Sắp sang Nhật ·'), findsOneWidget);
  });

  testWidgets('các mục mở đúng màn hình', (tester) async {
    usePhoneScreen(tester);
    final recorder = PushRecorder();
    await tester.pumpWidget(profileTestApp(const ProfileScreen(), observer: recorder));
    await tester.pumpAndSettle();

    Future<Widget> open(String title) async {
      await _scrollTo(tester, find.text(title));
      await tester.tap(find.text(title));
      final screen = recorder.takeScreen();
      await tester.pumpAndSettle();
      return screen;
    }

    expect(await open('Xin tag định danh'), isA<TagRequestScreen>());
    expect(await open('Chủ đề quan tâm'), isA<InterestScreen>());
    expect(await open('Cẩm nang của tôi'), isA<MyGuidesScreen>());
    expect(await open('Đã lưu (4)'), isA<SavedScreen>());
    expect(await open('Đổi mật khẩu'), isA<ChangePasswordScreen>());
    expect(await open('Xóa tài khoản'), isA<DeleteAccountScreen>());
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('Đăng xuất: đăng xuất rồi về màn hình đầu', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(
      profileTestApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ProfileScreen())),
              child: const Text('Mở Tôi'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mở Tôi'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Đăng xuất'));
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileScreen), findsNothing);
    expect(find.text('Mở Tôi'), findsOneWidget);
    expect(tester.element(find.text('Mở Tôi')).read<AuthController>().isSignedIn, isFalse);
  });
}
