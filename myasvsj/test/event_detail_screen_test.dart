// Widget test của EventDetailScreen: dữ liệu, trạng thái lỗi, khách → Đăng nhập, Thích / Báo cáo / Xóa review.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/event_controller.dart';
import 'package:myasvsj/com.myasvsj.model/event_detail.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/event_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/event_review_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';

import 'auth_fakes.dart';
import 'event_fakes.dart';

Widget app(FakeEventDao dao, int eventId, {bool signedIn = false}) => MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) =>
          AuthController(FakeAuthDao(current: signedIn ? testUser : null))..currentUser = signedIn ? testUser : null,
    ),
    ChangeNotifierProvider(create: (_) => EventController(dao)),
  ],
  child: MaterialApp(home: EventDetailScreen(eventId: eventId)),
);

void tallView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('hiện thông tin, mẹo, album, nút Chỉ đường và review', (tester) async {
    tallView(tester);
    await tester.pumpWidget(app(FakeEventDao(member: false), 1));
    await tester.pumpAndSettle();

    expect(find.text('Lễ hội Obon'), findsWidgets);
    expect(find.text('Đã qua'), findsOneWidget);
    expect(find.text('8/9/2026 – 10/9/2026'), findsOneWidget);
    expect(find.text('Công viên Yanaka'), findsOneWidget);
    expect(find.text('Miễn phí'), findsOneWidget);
    expect(find.textContaining('Buổi tối có múa Bon Odori'), findsOneWidget);
    expect(find.text('Album từ review (1 ảnh)'), findsOneWidget);
    expect(find.text('Chỉ đường'), findsOneWidget);
    expect(find.text('1 review, gồm cả các năm trước'), findsOneWidget);
    expect(find.text('Viết review năm 2026'), findsOneWidget);
    expect(find.text('Review (1)'), findsOneWidget);
    expect(find.text('Lan Anh'), findsOneWidget);
    expect(find.text('Mentor'), findsOneWidget);
    expect(find.text('Senpai tin cậy'), findsOneWidget);
    expect(find.text('Năm 2026'), findsOneWidget);
    // Khách thấy Thích / Báo cáo (bấm thì đăng nhập)
    expect(find.text('Thích · 7'), findsOneWidget);
    expect(find.text('Báo cáo'), findsOneWidget);
  });

  testWidgets('sự kiện chưa bắt đầu và chưa gắn vị trí', (tester) async {
    final dao = FakeEventDao();
    dao.details[3] = EventDetail(event: sampleEvent(3, daysUntil: 2, lat: null, lng: null));
    await tester.pumpWidget(app(dao, 3));
    await tester.pumpAndSettle();

    expect(find.text('Viết review được khi sự kiện bắt đầu.'), findsOneWidget);
    expect(find.text('Sự kiện chưa gắn vị trí trên bản đồ.'), findsOneWidget);
    expect(find.text('Chỉ đường'), findsNothing);
    expect(find.text('Chưa ai viết review về sự kiện này.'), findsOneWidget);
  });

  testWidgets('sự kiện đã xóa: hiện câu của server và Thử lại', (tester) async {
    await tester.pumpWidget(app(FakeEventDao(), 99));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Không tìm thấy sự kiện. Sự kiện có thể đã bị xóa.'), findsOneWidget);
  });

  testWidgets('khách bấm Thích thì được đưa sang màn Đăng nhập', (tester) async {
    tallView(tester);
    final dao = FakeEventDao(member: false);
    await tester.pumpWidget(app(dao, 1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thích · 7'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(dao.likes, isEmpty);
  });

  testWidgets('khách bấm Viết review thì được đưa sang màn Đăng nhập', (tester) async {
    tallView(tester);
    await tester.pumpWidget(app(FakeEventDao(member: false), 1));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Viết review năm 2026'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('thành viên bấm Thích: số lượt thích lấy từ server', (tester) async {
    tallView(tester);
    final dao = FakeEventDao();
    await tester.pumpWidget(app(dao, 1, signedIn: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thích · 7'));
    await tester.pumpAndSettle();
    expect(dao.likes.single, (reviewId: 11, on: true));
    expect(find.text('Thích · 9'), findsOneWidget);
  });

  testWidgets('thành viên báo cáo review: chọn lý do, gửi, thấy câu cảm ơn', (tester) async {
    tallView(tester);
    final dao = FakeEventDao();
    await tester.pumpWidget(app(dao, 1, signedIn: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Báo cáo'));
    await tester.pumpAndSettle();
    expect(find.text('Báo cáo review'), findsOneWidget);
    await tester.tap(find.text('Spam'));
    await tester.pump();
    await tester.tap(find.text('Gửi báo cáo'));
    await tester.pumpAndSettle();

    expect(dao.reports.single.reasonId, 4);
    expect(find.text('Cảm ơn bạn. Báo cáo đã được gửi.'), findsOneWidget);
  });

  testWidgets('review của mình: có Sửa / Xóa, không có Báo cáo; Xóa hỏi xác nhận', (tester) async {
    tallView(tester);
    final dao = FakeEventDao();
    await tester.pumpWidget(app(dao, 2, signedIn: true));
    await tester.pumpAndSettle();

    expect(find.text('Sửa review năm 2026'), findsOneWidget);
    expect(find.text('Sửa'), findsOneWidget);
    expect(find.text('Báo cáo'), findsNothing);

    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    expect(find.text('Xóa review?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();

    expect(dao.deleted, [10]);
    expect(find.text('Đã xóa review. Điểm của review này được thu lại.'), findsOneWidget);
    expect(find.text('Chưa ai viết review về sự kiện này.'), findsOneWidget);
  });

  testWidgets('hủy xác nhận thì không xóa', (tester) async {
    tallView(tester);
    final dao = FakeEventDao();
    await tester.pumpWidget(app(dao, 2, signedIn: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(dao.deleted, isEmpty);
  });

  testWidgets('thành viên bấm Sửa review mở form', (tester) async {
    tallView(tester);
    await tester.pumpWidget(app(FakeEventDao(), 2, signedIn: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sửa review năm 2026'));
    await tester.pumpAndSettle();
    expect(find.byType(EventReviewFormScreen), findsOneWidget);
  });

  testWidgets('màn hẹp 360 dp không tràn chữ (review của mình và của người khác)', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final id in [1, 2]) {
      await tester.pumpWidget(const SizedBox()); // dựng lại từ đầu: Provider và State mới
      await tester.pumpWidget(app(FakeEventDao(), id, signedIn: true));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -1500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
