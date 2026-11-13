// Widget test của GuideDetailScreen: nội dung, hàng nút người xem, checklist (thành viên lưu, khách chỉ tick trên máy).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/guide_controller.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';

import 'auth_fakes.dart';
import 'guide_fakes.dart';

Widget app(FakeGuideDao dao, int guideId, {bool openChecklist = false}) => MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) =>
          AuthController(FakeAuthDao(current: dao.signedIn ? testUser : null))
            ..currentUser = dao.signedIn ? testUser : null,
    ),
    ChangeNotifierProvider(create: (_) => GuideController(dao)),
  ],
  child: MaterialApp(
    home: GuideDetailScreen(guideId: guideId, openChecklist: openChecklist),
  ),
);

void tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('hiện chủ đề, tiêu đề, các mục có định dạng và tài liệu tham khảo', (tester) async {
    tallView(tester);
    await tester.pumpWidget(app(FakeGuideDao(), 24));
    await tester.pumpAndSettle();

    expect(find.text('SINH HOẠT'), findsOneWidget); // chủ đề viết HOA kiểu Overline như thiết kế
    expect(find.text('Cách phân loại và bỏ rác tại Nhật Bản'), findsOneWidget);
    expect(find.text('Ngày tạo: 8/11/2026 · Dữ liệu mẫu'), findsOneWidget);
    expect(find.text('Giai đoạn: Khi mới đến (tuần đầu đến 3 tháng)'), findsOneWidget);
    expect(find.text('1. Rác cháy được'), findsOneWidget);
    expect(find.text('Bỏ vào túi chỉ định.'), findsOneWidget); // ** được bỏ, chữ in đậm
    expect(find.text('Thứ hai'), findsOneWidget);
    expect(find.text('•'), findsNWidgets(2));
    expect(find.text('Tài liệu tham khảo'), findsOneWidget);
    // Cẩm nang không có checklist: không có tab
    expect(find.byType(TabBar), findsNothing);
  });

  testWidgets('thành viên: Lưu và Đánh dấu đã xong đổi nút, hiện câu của server', (tester) async {
    tallView(tester);
    final dao = FakeGuideDao();
    await tester.pumpWidget(app(dao, 24));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(dao.actions, ['save 24']);
    expect(find.text('Đã lưu'), findsOneWidget);
    expect(find.text('Đã lưu cẩm nang.'), findsOneWidget);

    await tester.tap(find.text('Đánh dấu đã xong'));
    await tester.pumpAndSettle();
    expect(dao.actions.last, 'done 24');
    expect(find.text('Đã xong'), findsOneWidget);
  });

  testWidgets('khách bấm Lưu thì được đưa sang màn Đăng nhập', (tester) async {
    tallView(tester);
    final dao = FakeGuideDao(signedIn: false);
    await tester.pumpWidget(app(dao, 24));
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập để lưu cẩm nang và theo dõi tiến độ.'), findsOneWidget);
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(dao.actions, isEmpty);
  });

  testWidgets('khách bấm Đánh dấu đã xong thì được đưa sang màn Đăng nhập', (tester) async {
    tallView(tester);
    final dao = FakeGuideDao(signedIn: false);
    await tester.pumpWidget(app(dao, 24));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Đánh dấu đã xong'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('cẩm nang có checklist: hai tab, nút Tiến độ mở tab checklist', (tester) async {
    tallView(tester);
    await tester.pumpWidget(app(FakeGuideDao(), 23));
    await tester.pumpAndSettle();

    expect(find.text('Xem chi tiết'), findsOneWidget);
    expect(find.text('Tiến độ: 0/3 việc'), findsOneWidget);
    expect(find.text('Việc tiếp theo: Cài đặt ứng dụng tìm đường'), findsOneWidget);
    expect(find.text('Đánh dấu đã xong'), findsNothing);
    expect(find.text('1. Giới thiệu'), findsOneWidget); // tiêu đề đã có số thì không thêm số

    await tester.tap(find.text('Tiến độ: 0/3 việc'));
    await tester.pumpAndSettle();
    expect(find.text('0/3 công việc đã hoàn thành'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNWidgets(3));
  });

  testWidgets('thành viên tick một việc: lưu lên server, tiến độ trên nút đổi theo', (tester) async {
    tallView(tester);
    final dao = FakeGuideDao();
    await tester.pumpWidget(app(dao, 23, openChecklist: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cài đặt ứng dụng tìm đường'));
    await tester.pumpAndSettle();
    expect(dao.checks.single, (guideId: 23, taskId: 10, completed: true));
    expect(find.text('1/3 công việc đã hoàn thành'), findsOneWidget);
    expect(find.text('33%'), findsOneWidget);
    expect(find.text('Tiến độ: 1/3 việc'), findsOneWidget);
    expect(find.textContaining('dấu tick chỉ để tự theo dõi'), findsNothing);
  });

  testWidgets('khách tick được nhưng không lưu, màn hình nói rõ', (tester) async {
    tallView(tester);
    final dao = FakeGuideDao(signedIn: false);
    await tester.pumpWidget(app(dao, 23, openChecklist: true));
    await tester.pumpAndSettle();

    expect(find.textContaining('dấu tick chỉ để tự theo dõi'), findsOneWidget);
    await tester.tap(find.text('Nạp đủ tiền đi lại'));
    await tester.pumpAndSettle();
    expect(find.text('1/3 công việc đã hoàn thành'), findsOneWidget);
    expect(find.text('33%'), findsOneWidget);
    expect(dao.checks, isEmpty);

    await tester.tap(find.widgetWithText(TextButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('cẩm nang không còn: hiện câu của server', (tester) async {
    await tester.pumpWidget(app(FakeGuideDao(), 999));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Không tìm thấy cẩm nang.'), findsOneWidget);
  });

  testWidgets('màn hẹp 360 dp không tràn chữ (hai tab, thành viên và khách)', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final signedIn in [true, false]) {
      await tester.pumpWidget(const SizedBox()); // dựng lại từ đầu: Provider và State mới
      await tester.pumpWidget(app(FakeGuideDao(signedIn: signedIn), 23, openChecklist: true));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Xem chi tiết'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
