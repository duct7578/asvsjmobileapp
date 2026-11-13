// Widget test của GuideListScreen: bộ lọc từ server, danh sách, tải thêm, lỗi, rỗng, mở chi tiết.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/guide_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_card.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_list_screen.dart';

import 'auth_fakes.dart';
import 'guide_fakes.dart';

Widget app(FakeGuideDao dao, {String? stage}) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthController(FakeAuthDao())),
    ChangeNotifierProvider(create: (_) => GuideController(dao)),
  ],
  child: MaterialApp(home: GuideListScreen(stage: stage)),
);

void tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('hiện giai đoạn, chủ đề lấy từ server và trang đầu', (tester) async {
    tallView(tester);
    await tester.pumpWidget(app(FakeGuideDao()));
    await tester.pumpAndSettle();

    // Mỗi hàng (GIAI ĐOẠN, CHỦ ĐỀ) có chip "Tất cả" như thiết kế
    expect(find.text('GIAI ĐOẠN'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Tất cả'), findsNWidgets(2));
    expect(find.text('Trước khi đi'), findsOneWidget);
    expect(find.text('Sau khi về nước'), findsOneWidget);
    expect(find.text('Sinh hoạt'), findsWidgets);
    expect(find.text('3 cẩm nang phù hợp'), findsOneWidget);
    expect(find.byType(GuideCard), findsNWidgets(2));
    expect(find.text('Cách phân loại và bỏ rác tại Nhật Bản'), findsOneWidget);
    expect(find.text('Tải thêm'), findsOneWidget);
  });

  testWidgets('Tải thêm nối trang sau', (tester) async {
    tallView(tester);
    await tester.pumpWidget(app(FakeGuideDao()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tải thêm'));
    await tester.pumpAndSettle();
    expect(find.byType(GuideCard), findsNWidgets(3));
    expect(find.text('Chuẩn bị hành lý'), findsOneWidget);
    expect(find.text('Tải thêm'), findsNothing);
  });

  testWidgets('mở với stage thì lọc sẵn giai đoạn đó', (tester) async {
    tallView(tester);
    final dao = FakeGuideDao();
    await tester.pumpWidget(app(dao, stage: 'PRE'));
    await tester.pumpAndSettle();

    expect(dao.listCalls.first.stage, 'PRE');
    expect(find.byType(GuideCard), findsOneWidget);
    final chip = tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Trước khi đi'));
    expect(chip.selected, isTrue);
  });

  testWidgets('bấm chip giai đoạn / chủ đề, tìm và sắp xếp gọi lại server', (tester) async {
    tallView(tester);
    final dao = FakeGuideDao();
    await tester.pumpWidget(app(dao));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Khi mới đến (tuần đầu đến 3 tháng)'));
    await tester.pumpAndSettle();
    expect(dao.listCalls.last.stage, 'ARR');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Đi lại'));
    await tester.pumpAndSettle();
    expect(dao.listCalls.last.topic, 'TRANSPORT');
    expect(find.byType(GuideCard), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'tàu');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(dao.listCalls.last.q, 'tàu');

    await tester.tap(find.text('Mới nhất'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiêu đề A–Z').last);
    await tester.pumpAndSettle();
    expect(dao.listCalls.last.sort, 'TITLE');
  });

  testWidgets('không có kết quả thì hiện câu rỗng của web', (tester) async {
    tallView(tester);
    final dao = FakeGuideDao()..guides = [];
    await tester.pumpWidget(app(dao));
    await tester.pumpAndSettle();
    expect(find.text('Không có cẩm nang phù hợp. Hãy thử từ khóa hoặc chủ đề khác.'), findsOneWidget);
  });

  testWidgets('lỗi server hiện câu thông báo và nút Thử lại', (tester) async {
    tallView(tester);
    final dao = FakeGuideDao()..failWith = const ApiException('Không kết nối được tới server.');
    await tester.pumpWidget(app(dao));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);

    dao.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byType(GuideCard), findsNWidgets(2));
    expect(find.text('Trước khi đi'), findsOneWidget);
  });

  testWidgets('bấm thẻ mở chi tiết cẩm nang', (tester) async {
    tallView(tester);
    await tester.pumpWidget(app(FakeGuideDao()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cách phân loại và bỏ rác tại Nhật Bản'));
    await tester.pumpAndSettle();
    expect(find.byType(GuideDetailScreen), findsOneWidget);
  });

  testWidgets('màn hẹp 360 dp không tràn chữ', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(FakeGuideDao()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(GuideCard), findsWidgets);
  });
}
