// Widget test của EventListScreen: cấp Controller dùng DAO giả bằng Provider, rồi kiểm tra màn hình vẽ đúng.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/event_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/event_card.dart';
import 'package:myasvsj/com.myasvsj.screen/event_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/event_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/event_review_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';

import 'auth_fakes.dart';
import 'event_fakes.dart';

Widget app(FakeEventDao dao, {bool signedIn = false}) => MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) =>
          AuthController(FakeAuthDao(current: signedIn ? testUser : null))..currentUser = signedIn ? testUser : null,
    ),
    ChangeNotifierProvider(create: (_) => EventController(dao)),
  ],
  child: const MaterialApp(home: EventListScreen()),
);

/// Màn hình cao để mọi thẻ đều được dựng (ListView chỉ dựng phần đang thấy).
void tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('hiện vòng chờ khi đang tải lần đầu', (tester) async {
    final dao = FakeEventDao()..listGate = Completer<void>();
    await tester.pumpWidget(app(dao));
    await tester.pump();
    expect(find.byType(LoadingView), findsOneWidget);

    dao.listGate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LoadingView), findsNothing);
    expect(find.byType(EventCard), findsWidgets);
  });

  testWidgets('chia nhóm Đang diễn ra / 30 ngày tới / Sau này / Đã diễn ra như web', (tester) async {
    tallView(tester);
    await tester.pumpWidget(app(FakeEventDao()));
    await tester.pumpAndSettle();

    // Tiêu đề nhóm: tên + số đếm trong badge, trình đọc màn hình đọc "Tên (n)"
    expect(find.bySemanticsLabel('Đang diễn ra (1)'), findsOneWidget);
    expect(find.bySemanticsLabel('Trong 30 ngày tới (1)'), findsOneWidget);
    expect(find.bySemanticsLabel('Sau này (1)'), findsOneWidget);
    expect(find.bySemanticsLabel('Đã diễn ra (vẫn viết review được) (1)'), findsOneWidget);
    expect(find.text('Trong 30 ngày tới'), findsOneWidget);
    expect(find.text('Đã diễn ra (vẫn viết review được)'), findsOneWidget);
    expect(find.byType(EventCard), findsNWidgets(4));
    expect(find.text('Chợ phiên Yanaka Ginza'), findsOneWidget);
    expect(find.text('Còn 2 ngày'), findsOneWidget);
    expect(find.text('5.0 · 1 review'), findsOneWidget);
    expect(find.text('Chưa có review'), findsNWidgets(2));
    // Chỉ sự kiện đã bắt đầu mới có nút "Viết review"
    expect(find.text('Viết review'), findsNWidgets(2));
  });

  testWidgets('lỗi server hiện câu thông báo và nút Thử lại', (tester) async {
    final dao = FakeEventDao()..failWith = const ApiException('Không kết nối được tới server.');
    await tester.pumpWidget(app(dao));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Không kết nối được tới server.'), findsOneWidget);

    dao.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byType(EventCard), findsWidgets);
  });

  testWidgets('gõ từ khóa thì tìm sau một nhịp, không khớp thì báo rỗng', (tester) async {
    final dao = FakeEventDao();
    await tester.pumpWidget(app(dao));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'obon');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(dao.queries.last, 'obon');
    expect(find.byType(EventCard), findsOneWidget);
    expect(find.text('Lễ hội Obon'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'không có');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Không có sự kiện nào khớp.'), findsOneWidget);

    await tester.tap(find.byTooltip('Xóa từ khóa'));
    await tester.pumpAndSettle();
    expect(dao.queries.last, '');
    expect(find.byType(EventCard), findsWidgets);
  });

  testWidgets('chưa có sự kiện nào thì hiện câu rỗng', (tester) async {
    final dao = FakeEventDao()..events = [];
    await tester.pumpWidget(app(dao));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có sự kiện nào.'), findsOneWidget);
  });

  testWidgets('khách bấm Viết review thì được đưa sang màn Đăng nhập', (tester) async {
    await tester.pumpWidget(app(FakeEventDao()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Viết review').first);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('người đã đăng nhập bấm Viết review thì mở form', (tester) async {
    await tester.pumpWidget(app(FakeEventDao(), signedIn: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Viết review').first);
    await tester.pumpAndSettle();
    expect(find.byType(EventReviewFormScreen), findsOneWidget);
  });

  testWidgets('bấm thẻ mở chi tiết sự kiện', (tester) async {
    await tester.pumpWidget(app(FakeEventDao()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chợ phiên Yanaka Ginza'));
    await tester.pumpAndSettle();
    expect(find.byType(EventDetailScreen), findsOneWidget);
    expect(find.text('Croquette 100 yên ở đầu phố rất ngon.'), findsOneWidget);
  });

  testWidgets('màn hẹp 360 dp không tràn chữ', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(FakeEventDao(), signedIn: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(EventCard), findsWidgets);
  });
}
