// Widget test của MyGuidesScreen: khách thấy lời mời đăng nhập; thành viên thấy 4 giai đoạn, đang làm, đã xong.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/guide_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/guide_my_progress.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/my_guides_screen.dart';

import 'auth_fakes.dart';
import 'guide_fakes.dart';

Widget app(FakeGuideDao dao, {bool signedIn = true}) => MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) =>
          AuthController(FakeAuthDao(current: signedIn ? testUser : null))..currentUser = signedIn ? testUser : null,
    ),
    ChangeNotifierProvider(create: (_) => GuideController(dao)),
  ],
  child: const MaterialApp(home: MyGuidesScreen()),
);

void tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('khách thấy lời mời đăng nhập, bấm thì sang màn Đăng nhập', (tester) async {
    final dao = FakeGuideDao(signedIn: false);
    await tester.pumpWidget(app(dao, signedIn: false));
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập để theo dõi tiến độ cẩm nang của bạn qua từng giai đoạn.'), findsOneWidget);
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('thành viên thấy 4 giai đoạn, giai đoạn của mình, đang làm dở và đã xong', (tester) async {
    tallView(tester);
    await tester.pumpWidget(app(FakeGuideDao()));
    await tester.pumpAndSettle();

    expect(find.text('Trước khi đi'), findsOneWidget);
    expect(find.text('Giai đoạn của bạn'), findsOneWidget);
    expect(find.text('1/10'), findsOneWidget);
    expect(find.text('0/5'), findsNWidgets(2));
    expect(find.text('Chưa có'), findsOneWidget);
    expect(find.text('Đang làm dở'), findsOneWidget);
    expect(find.text('1/3 việc · Tiếp theo: Tìm tuyến tàu đến trường'), findsOneWidget);
    expect(find.text('Đã xong gần đây'), findsOneWidget);
    expect(find.text('Xong ngày 8/11/2026'), findsOneWidget);
  });

  testWidgets('chưa bắt đầu cẩm nang nào thì có lời nhắc', (tester) async {
    tallView(tester);
    final dao = FakeGuideDao()..myProgress = const GuideMyProgress(stage: null);
    await tester.pumpWidget(app(dao));
    await tester.pumpAndSettle();
    expect(
      find.text('Bạn chưa bắt đầu cẩm nang nào. Mở Cẩm nang để xem việc cần làm ở từng giai đoạn.'),
      findsOneWidget,
    );
  });

  testWidgets('bấm checklist đang làm mở chi tiết ở tab checklist', (tester) async {
    tallView(tester);
    await tester.pumpWidget(app(FakeGuideDao()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hướng dẫn sử dụng tàu điện Nhật Bản'));
    await tester.pumpAndSettle();
    expect(find.byType(GuideDetailScreen), findsOneWidget);
    expect(tester.widget<GuideDetailScreen>(find.byType(GuideDetailScreen)).openChecklist, isTrue);
    expect(find.text('0/3 công việc đã hoàn thành'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('bấm một giai đoạn mở danh sách lọc theo giai đoạn đó', (tester) async {
    tallView(tester);
    final dao = FakeGuideDao();
    await tester.pumpWidget(app(dao));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Trước khi đi'));
    await tester.pumpAndSettle();
    expect(find.byType(GuideListScreen), findsOneWidget);
    expect(dao.listCalls.last.stage, 'PRE');
  });

  testWidgets('lỗi server hiện câu thông báo và Thử lại', (tester) async {
    final dao = FakeGuideDao()..failWith = const ApiException('Bạn không có quyền thực hiện thao tác này.');
    await tester.pumpWidget(app(dao));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);

    dao.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Đang làm dở'), findsOneWidget);
  });

  testWidgets('màn hẹp 360 dp không tràn chữ', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(FakeGuideDao()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Giai đoạn của bạn'), findsOneWidget);
  });
}
