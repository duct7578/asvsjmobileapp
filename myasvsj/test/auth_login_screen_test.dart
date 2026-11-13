// Widget test của LoginScreen: đăng nhập, lỗi của server, từ chối staff, chuyển sang Quên mật khẩu / Đăng ký.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/forgot_password_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/register_screen.dart';

import 'auth_fakes.dart';
import 'auth_widget_helpers.dart';

/// Màn hình gốc có nút mở LoginScreen và ghi lại kết quả trả về.
class _Host extends StatelessWidget {
  const _Host(this.results);

  final List<bool?> results;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ElevatedButton(
        onPressed: () async =>
            results.add(await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const LoginScreen()))),
        child: const Text('Mở đăng nhập'),
      ),
    ),
  );
}

void main() {
  late FakeAuthDao dao;
  late List<bool?> results;

  setUp(() {
    dao = FakeAuthDao();
    results = [];
  });

  Future<void> openLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthController(dao),
        child: MaterialApp(home: _Host(results)),
      ),
    );
    await tester.tap(find.text('Mở đăng nhập'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);
  final loginButton = find.widgetWithText(FilledButton, 'Đăng nhập');

  testWidgets('vẽ đủ ô nhập và các đường sang Quên mật khẩu, Đăng ký', (tester) async {
    await openLogin(tester);
    expect(find.text('Chào mừng bạn quay lại Senpai ơi.'), findsOneWidget);
    expect(field('Email'), findsOneWidget);
    expect(field('Mật khẩu'), findsOneWidget);
    expect(loginButton, findsOneWidget);
    expect(find.text('Quên mật khẩu?'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Đăng ký'), findsOneWidget);
  });

  testWidgets('bấm Đăng nhập khi để trống: lỗi dưới ô, không gọi server', (tester) async {
    await openLogin(tester);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    expect(dao.calls, isEmpty);
  });

  testWidgets('sai mật khẩu: hiện đúng câu của server và xóa ô mật khẩu', (tester) async {
    dao.failures['login'] = const ApiException(
      'Email hoặc mật khẩu không đúng. Còn 2 lần thử trước khi tài khoản bị tạm khóa.',
      statusCode: 401,
    );
    await openLogin(tester);
    await tester.enterText(field('Email'), 'an@example.com');
    await tester.enterText(field('Mật khẩu'), 'sai-mat-khau');
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text('Email hoặc mật khẩu không đúng. Còn 2 lần thử trước khi tài khoản bị tạm khóa.'), findsOneWidget);
    expect(tester.widget<TextField>(field('Mật khẩu')).controller!.text, isEmpty);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('đăng nhập đúng: màn hình đóng và trả về true', (tester) async {
    await openLogin(tester);
    await tester.enterText(field('Email'), 'an@example.com');
    await tester.enterText(field('Mật khẩu'), 'abc12345');
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsNothing);
    expect(results, [true]);
    final auth = Provider.of<AuthController>(tester.element(find.byType(_Host)), listen: false);
    expect(auth.currentUser?.email, 'an@example.com');
  });

  testWidgets('tài khoản staff bị từ chối: báo dùng trang web, vẫn là khách', (tester) async {
    dao.loginRole = 'MODERATOR';
    await openLogin(tester);
    await tester.enterText(field('Email'), 'moderator@gmail.com');
    await tester.enterText(field('Mật khẩu'), '123456');
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text(AuthController.staffMessage), findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(dao.calls, ['login', 'logout']);
    expect(results, isEmpty);
  });

  testWidgets('màn hẹp 360 dp: không tràn chữ khi có lỗi dài', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    dao.loginRole = 'MODERATOR';
    await openLogin(tester);
    await tester.enterText(field('Email'), 'moderator@gmail.com');
    await tester.enterText(field('Mật khẩu'), '123456');
    await tester.tap(loginButton);
    await tester.pumpAndSettle();
    expect(find.text(AuthController.staffMessage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nút Hiện / Ẩn mật khẩu', (tester) async {
    await openLogin(tester);
    expect(tester.widget<TextField>(field('Mật khẩu')).obscureText, isTrue);
    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await tester.pump();
    expect(tester.widget<TextField>(field('Mật khẩu')).obscureText, isFalse);
    expect(find.byTooltip('Ẩn mật khẩu'), findsOneWidget);
  });

  testWidgets('Quên mật khẩu? mở màn Quên mật khẩu với email đã gõ', (tester) async {
    await openLogin(tester);
    await tester.enterText(field('Email'), 'an@example.com');
    await tester.tap(find.text('Quên mật khẩu?'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsOneWidget);
    expect(tester.widget<TextField>(field('Email')).controller!.text, 'an@example.com');

    await tester.tap(find.text('Quay lại Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Đăng ký xong (app tự đăng nhập) thì màn Đăng nhập cũng đóng với true', (tester) async {
    dao.resendAfterSeconds = 1;
    await openLogin(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Đăng ký'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsOneWidget);

    await tester.enterText(field('Email'), 'moi@example.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Gửi mã xác thực'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Mã xác thực'), '123456'); // đủ 6 số thì tự gửi
    await tester.pumpAndSettle();

    await tester.enterText(field('Tên hiển thị'), 'Bạn Mới');
    await tester.enterText(field('Mật khẩu'), 'abc12345');
    await tester.enterText(field('Nhập lại mật khẩu'), 'abc12345');
    await tapVisible(tester, find.text('Tôi xác nhận mình đã đủ 18 tuổi.'));
    await tapVisible(tester, find.textContaining('Tôi đồng ý với'));
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Tạo tài khoản'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsNothing);
    expect(find.byType(LoginScreen), findsNothing);
    expect(results, [true]);
    expect(dao.calls, containsAllInOrder(['sendRegisterCode', 'verifyRegisterCode', 'completeRegistration', 'login']));
  });

  testWidgets('từ màn Đăng ký bấm "Đăng nhập" thì quay lại màn Đăng nhập', (tester) async {
    await openLogin(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Đăng ký'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
