// Widget test của "Lịch sử điểm" (PointHistoryScreen) với DAO giả.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/place_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/point_history_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_sign_in_prompt.dart';

import 'profile_fakes.dart';
import 'profile_test_app.dart';

void main() {
  testWidgets('hiện điểm, các dòng cộng / trừ, nội dung không còn', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(profileTestApp(const PointHistoryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Bạn có 130 điểm'), findsOneWidget);
    expect(find.text('25 lần cộng / trừ'), findsOneWidget);
    expect(find.text('THÁNG 11/2026'), findsOneWidget, reason: 'các dòng nhóm theo tháng');
    expect(find.text('−20'), findsWidgets);
    expect(find.text('+10'), findsWidgets);
    expect(find.text('Ga Nippori'), findsOneWidget);
    expect(find.text('Nội dung không còn'), findsOneWidget);
    expect(find.text('Nội dung bị Moderator gỡ'), findsWidgets);
  });

  testWidgets('cuộn tới cuối thì tải trang sau, hết thì không còn nút Tải thêm', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(profileTestApp(const PointHistoryScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Bài số 1'), findsNothing);

    await tester.scrollUntilVisible(find.text('Bài số 1'), 400, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('Bài số 1'), findsOneWidget);
    expect(find.text('Tải thêm'), findsNothing);
  });

  testWidgets('trang đầu vừa màn hình (không cuộn được) thì bấm Tải thêm', (tester) async {
    // Màn hình rất cao: 20 dòng nằm gọn, không có cú cuộn nào để tự tải trang sau
    tester.view.physicalSize = const Size(1080, 7800);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final dao = FakeProfileDao();
    await tester.pumpWidget(profileTestApp(const PointHistoryScreen(), profileDao: dao));
    await tester.pumpAndSettle();
    expect(find.text('Bài số 1'), findsNothing);

    await tester.tap(find.text('Tải thêm'));
    await tester.pumpAndSettle();
    expect(dao.calls.where((c) => c == 'findPointHistory'), hasLength(2));
    expect(find.text('Bài số 1'), findsOneWidget);
    expect(find.text('Tải thêm'), findsNothing);
  });

  testWidgets('chưa có dòng nào: câu tùy theo đã có điểm hay chưa', (tester) async {
    final dao = FakeProfileDao()..pointLines = [];
    await tester.pumpWidget(profileTestApp(const PointHistoryScreen(), profileDao: dao));
    await tester.pumpAndSettle();
    expect(find.text('Bạn có 130 điểm. Chưa có lần cộng hoặc trừ điểm nào được ghi lại.'), findsOneWidget);

    final none = FakeProfileDao()
      ..pointLines = []
      ..points = 0;
    await tester.pumpWidget(profileTestApp(const PointHistoryScreen(), profileDao: none));
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa có điểm nào. Viết review đầu tiên để nhận 10 điểm.'), findsOneWidget);
  });

  testWidgets('lỗi server hiện câu thông báo và Thử lại', (tester) async {
    final dao = FakeProfileDao()..failWith = const ApiException('Không kết nối được tới server.');
    await tester.pumpWidget(profileTestApp(const PointHistoryScreen(), profileDao: dao));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);

    dao.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Ga Nippori'), findsOneWidget);
  });

  testWidgets('bấm dòng có nội dung còn xem được thì mở nội dung đó', (tester) async {
    final recorder = PushRecorder();
    await tester.pumpWidget(profileTestApp(const PointHistoryScreen(), observer: recorder));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ga Nippori'));
    expect(recorder.takeScreen(), isA<PlaceDetailScreen>().having((s) => s.placeId, 'placeId', 1));
    await tester.pumpAndSettle();

    // Dòng không có link thì bấm không mở gì
    await tester.tap(find.text('Nội dung không còn'));
    await tester.pumpAndSettle();
    expect(recorder.pushed, isEmpty);
  });

  testWidgets('khách thấy lời mời đăng nhập', (tester) async {
    await tester.pumpWidget(profileTestApp(const PointHistoryScreen(), signedIn: false));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileSignInPrompt), findsOneWidget);
  });
}
