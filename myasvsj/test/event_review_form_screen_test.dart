// Widget test của EventReviewFormScreen: kiểm tra nhập, đăng mới, sửa (giữ / bỏ ảnh cũ), lỗi mở form.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/event_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/event_review_form.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/event_review_form_screen.dart';

import 'auth_fakes.dart';
import 'event_fakes.dart';

/// Trang thử: nút "Mở" đẩy form lên, rồi ghi lại kết quả form trả về.
Widget app(FakeEventDao dao) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthController(FakeAuthDao(current: testUser))..currentUser = testUser),
    ChangeNotifierProvider(create: (_) => EventController(dao)),
  ],
  child: const MaterialApp(home: Scaffold(body: _Host())),
);

class _Host extends StatefulWidget {
  const _Host();

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String result = 'chưa';

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('kết quả: $result'),
      ElevatedButton(
        onPressed: () async {
          final saved = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const EventReviewFormScreen(eventId: 1)),
          );
          setState(() => result = '$saved');
        },
        child: const Text('Mở'),
      ),
    ],
  );
}

Future<void> open(WidgetTester tester, FakeEventDao dao) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(app(dao));
  await tester.tap(find.text('Mở'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('form mới: hiện sự kiện, bấm Đăng review khi chưa nhập thì báo lỗi, không gửi', (tester) async {
    final dao = FakeEventDao();
    await open(tester, dao);

    expect(find.text('Viết review'), findsOneWidget);
    expect(find.text('Lễ hội Obon'), findsOneWidget);
    expect(find.text('Review cho lần tổ chức năm 2026 · 8/9/2026 – 10/9/2026'), findsOneWidget);

    await tester.tap(find.text('Đăng review'));
    await tester.pumpAndSettle();
    expect(find.text('Hãy chọn số sao (1 đến 5).'), findsOneWidget);
    expect(find.text('Hãy viết vài dòng về sự kiện.'), findsOneWidget);
    expect(dao.created, isEmpty);
  });

  testWidgets('chọn sao, viết nội dung, đăng: form đóng và trả về true', (tester) async {
    final dao = FakeEventDao();
    await open(tester, dao);

    await tester.tap(find.byTooltip('4 sao'));
    await tester.enterText(find.byType(TextField), 'Đông vui, nên đi buổi tối.');
    await tester.tap(find.text('Đăng review'));
    await tester.pumpAndSettle();

    expect(dao.created.single.rating, 4);
    expect(dao.created.single.content, 'Đông vui, nên đi buổi tối.');
    expect(find.byType(EventReviewFormScreen), findsNothing);
    expect(find.text('kết quả: true'), findsOneWidget);
  });

  testWidgets('form sửa: điền sẵn review cũ, bỏ ảnh đã đăng rồi lưu', (tester) async {
    final dao = FakeEventDao();
    dao.form = EventReviewForm(event: dao.events.first, review: ownReview());
    await open(tester, dao);

    expect(find.text('Sửa review'), findsOneWidget);
    expect(find.text('Vui, đông người.'), findsOneWidget);
    expect(find.text('Ảnh đã đăng'), findsOneWidget);
    expect(find.text('Ảnh mới (0/4)'), findsOneWidget);

    await tester.tap(find.byTooltip('Bỏ ảnh'));
    await tester.pumpAndSettle();
    expect(find.text('Ảnh đã đăng'), findsNothing);

    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(dao.updated.single.reviewId, 13);
    expect(dao.updated.single.rating, 4);
    expect(dao.updated.single.keep, isEmpty);
    expect(find.text('kết quả: true'), findsOneWidget);
  });

  testWidgets('tài khoản mới thấy hạn mức hôm nay', (tester) async {
    final dao = FakeEventDao();
    dao.form = EventReviewForm(
      event: dao.events.first,
      newAccount: true,
      postsUsed: 3,
      postsLimit: 3,
      pinsLimit: 2,
      videosLimit: 1,
    );
    await open(tester, dao);
    expect(find.textContaining('Tài khoản mới, hôm nay: 3/3 bài viết và review'), findsOneWidget);
    expect(find.textContaining('Bạn đã dùng hết lượt đăng hôm nay'), findsOneWidget);
  });

  testWidgets('server từ chối mở form: hiện câu của server', (tester) async {
    final dao = FakeEventDao()..failWith = const ApiException('Viết review được khi sự kiện bắt đầu.', statusCode: 400);
    await open(tester, dao);
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Viết review được khi sự kiện bắt đầu.'), findsOneWidget);
  });

  testWidgets('server từ chối khi đăng: hiện câu của server dưới ô, form không đóng', (tester) async {
    final dao = FakeEventDao()
      ..writeFailWith = const ApiException(
        'Nội dung chứa từ ngữ không phù hợp.',
        statusCode: 400,
        fields: {'content': 'Nội dung chứa từ ngữ không phù hợp.'},
      );
    await open(tester, dao);

    await tester.tap(find.byTooltip('5 sao'));
    await tester.enterText(find.byType(TextField), 'abc');
    await tester.tap(find.text('Đăng review'));
    await tester.pumpAndSettle();
    expect(find.text('Nội dung chứa từ ngữ không phù hợp.'), findsNWidgets(2));
    expect(find.byType(EventReviewFormScreen), findsOneWidget);
  });

  testWidgets('màn hẹp 360 dp không tràn chữ (form sửa, tài khoản mới)', (tester) async {
    final dao = FakeEventDao();
    dao.form = EventReviewForm(event: dao.events.first, newAccount: true, postsLimit: 3, review: ownReview());
    await tester.pumpWidget(app(dao));
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Lưu thay đổi'), findsOneWidget);
  });
}
