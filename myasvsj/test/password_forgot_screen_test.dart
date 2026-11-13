// Widget test của ForgotPasswordScreen: gửi liên kết → dán đường link → đặt mật khẩu mới.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/forgot_password_screen.dart';

import 'auth_fakes.dart';
import 'auth_widget_helpers.dart';

const _link = 'http://localhost:8080/reset-password?token=Rgw3YMVgp66LygwJKdvg30LAOm1P1FXKu8dqiRWs5TU';

class _Host extends StatelessWidget {
  const _Host(this.results);

  final List<bool?> results;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ElevatedButton(
        onPressed: () async => results.add(
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const ForgotPasswordScreen(initialEmail: 'an@example.com')),
          ),
        ),
        child: const Text('Mở quên mật khẩu'),
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

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthController(dao),
        child: MaterialApp(home: _Host(results)),
      ),
    );
    await tester.tap(find.text('Mở quên mật khẩu'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);
  Finder button(String label) => find.widgetWithText(FilledButton, label);
  // Ô dán link: nhãn "Đường link trong email" nằm phía trên ô (thiết kế màn 34), trong ô là gợi ý dạng đường link
  final linkField = find.widgetWithText(TextField, 'http://…/reset-password?token=…');

  Future<void> toPasswordStep(WidgetTester tester) async {
    await tester.tap(find.text('Tôi đã có đường link trong email'));
    await tester.pumpAndSettle();
    await tester.enterText(linkField, _link);
    await tester.tap(button('Tiếp tục'));
    await tester.pumpAndSettle();
  }

  testWidgets('bước 1: email điền sẵn từ màn Đăng nhập; gửi xong hiện câu chung của server', (tester) async {
    await open(tester);
    expect(find.text('Nhập email bạn dùng để đăng ký. Chúng tôi sẽ gửi liên kết đặt lại mật khẩu.'), findsOneWidget);
    expect(tester.widget<TextField>(field('Email')).controller!.text, 'an@example.com');

    await tester.tap(button('Gửi liên kết'));
    await tester.pumpAndSettle();
    expect(dao.calls, ['forgotPassword']);
    expect(find.textContaining('Nếu email này có tài khoản'), findsOneWidget);
    expect(linkField, findsOneWidget);
  });

  testWidgets('bước 1: email trống thì báo lỗi dưới ô, không gọi server', (tester) async {
    await open(tester);
    await tester.enterText(field('Email'), '');
    await tester.tap(button('Gửi liên kết'));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập email'), findsOneWidget);
    expect(dao.calls, isEmpty);
  });

  testWidgets('bước 2: dán chữ không phải đường link thì báo lỗi', (tester) async {
    await open(tester);
    await tester.tap(find.text('Tôi đã có đường link trong email'));
    await tester.pumpAndSettle();
    await tester.enterText(linkField, 'xin chào');
    await tester.tap(button('Tiếp tục'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hãy dán đường link trong email'), findsOneWidget);
    expect(dao.calls, isEmpty);
  });

  testWidgets('bước 2: link hết hạn → câu của server dưới ô dán link', (tester) async {
    dao.failures['checkResetToken'] = const ApiException(
      'Liên kết đã hết hạn hoặc đã được sử dụng. Hãy yêu cầu liên kết mới.',
      statusCode: 400,
    );
    await open(tester);
    await toPasswordStep(tester);
    expect(find.text('Liên kết đã hết hạn hoặc đã được sử dụng. Hãy yêu cầu liên kết mới.'), findsOneWidget);
    expect(find.text('Gửi lại liên kết'), findsOneWidget);
  });

  testWidgets('bước 3: hiện email đã che, kiểm tra luật mật khẩu trước khi gửi', (tester) async {
    await open(tester);
    await toPasswordStep(tester);
    expect(dao.resetToken, 'Rgw3YMVgp66LygwJKdvg30LAOm1P1FXKu8dqiRWs5TU');
    expect(find.text('Đặt mật khẩu mới cho tài khoản a***@example.com.'), findsOneWidget);

    await tester.enterText(field('Mật khẩu mới'), 'abcdefgh');
    await tester.enterText(field('Nhập lại mật khẩu'), 'abcdefgx');
    await tapVisible(tester, button('Đặt lại mật khẩu'));
    await tester.pumpAndSettle();
    expect(find.text('Mật khẩu phải có cả chữ và số'), findsOneWidget);
    expect(find.text('Hai mật khẩu không khớp.'), findsOneWidget);
    expect(dao.calls, isNot(contains('resetPassword')));
  });

  testWidgets('bước 3: đặt lại xong thì đóng, trả về true và hiện câu của server', (tester) async {
    await open(tester);
    await toPasswordStep(tester);
    await tester.enterText(field('Mật khẩu mới'), 'reset123');
    await tester.enterText(field('Nhập lại mật khẩu'), 'reset123');
    await tapVisible(tester, button('Đặt lại mật khẩu'));
    await tester.pumpAndSettle();

    expect(find.byType(ForgotPasswordScreen), findsNothing);
    expect(results, [true]);
    expect(find.text('Đã đặt lại mật khẩu. Hãy đăng nhập bằng mật khẩu mới.'), findsOneWidget);
  });
}
