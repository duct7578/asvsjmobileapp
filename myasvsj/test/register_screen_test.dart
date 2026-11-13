// Widget test của RegisterScreen: 3 bước Email → Mã xác thực → Mật khẩu, đếm ngược "Gửi lại mã",
// lỗi dưới từng ô, link văn bản pháp lý, đăng ký xong thì tự đăng nhập và đóng.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/legal_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/register_screen.dart';

import 'auth_fakes.dart';
import 'auth_widget_helpers.dart';

class _Host extends StatelessWidget {
  const _Host(this.results);

  final List<bool?> results;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ElevatedButton(
        onPressed: () async =>
            results.add(await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const RegisterScreen()))),
        child: const Text('Mở đăng ký'),
      ),
    ),
  );
}

void main() {
  late FakeAuthDao dao;
  late List<bool?> results;

  setUp(() {
    dao = FakeAuthDao()..resendAfterSeconds = 1;
    results = [];
  });

  Future<void> openRegister(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthController(dao),
        child: MaterialApp(home: _Host(results)),
      ),
    );
    await tester.tap(find.text('Mở đăng ký'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);
  Finder button(String label) => find.widgetWithText(FilledButton, label);

  Future<void> toStep3(WidgetTester tester) async {
    await tester.enterText(field('Email'), 'moi@example.com');
    await tester.tap(button('Gửi mã xác thực'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Mã xác thực'), '123456');
    await tester.pumpAndSettle();
  }

  testWidgets('bước 1: vẽ thanh 3 bước và ô email', (tester) async {
    await openRegister(tester);
    expect(find.text('Tạo tài khoản'), findsOneWidget);
    expect(find.text('Email'), findsWidgets);
    expect(find.text('Mã xác thực'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.text('Chúng tôi sẽ gửi mã xác thực 6 số tới email này.'), findsOneWidget);
    expect(button('Gửi mã xác thực'), findsOneWidget);
  });

  testWidgets('bước 1: email sai hiện lỗi dưới ô, không gọi server', (tester) async {
    await openRegister(tester);
    await tester.enterText(field('Email'), 'khong-phai-email');
    await tester.tap(button('Gửi mã xác thực'));
    await tester.pumpAndSettle();
    expect(find.text('Email không hợp lệ'), findsOneWidget);
    expect(dao.calls, isEmpty);
  });

  testWidgets('bước 1: email đã có tài khoản → câu của server dưới ô email', (tester) async {
    dao.failures['sendRegisterCode'] = const ApiException(
      'Email này đã được đăng ký. Hãy đăng nhập hoặc dùng email khác.',
      statusCode: 409,
    );
    await openRegister(tester);
    await tester.enterText(field('Email'), 'user@gmail.com');
    await tester.tap(button('Gửi mã xác thực'));
    await tester.pumpAndSettle();
    expect(find.text('Email này đã được đăng ký. Hãy đăng nhập hoặc dùng email khác.'), findsOneWidget);
    expect(field('Mã xác thực'), findsNothing);
  });

  testWidgets('bước 2: hiện email, đếm ngược "Gửi lại sau …s" theo server rồi mới cho gửi lại', (tester) async {
    dao.resendAfterSeconds = 60;
    await openRegister(tester);
    await tester.enterText(field('Email'), 'moi@example.com');
    await tester.tap(button('Gửi mã xác thực'));
    await tester.pump();
    await tester.pump();

    expect(find.text('moi@example.com'), findsOneWidget);
    expect(find.text('Đã gửi mã xác thực tới moi@example.com.'), findsOneWidget);
    expect(find.text('Gửi lại sau 60s'), findsOneWidget);
    expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Gửi lại sau 60s')).onPressed, isNull);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Gửi lại sau 59s'), findsOneWidget);

    await tester.pump(const Duration(seconds: 59));
    final resend = find.widgetWithText(TextButton, 'Gửi lại mã');
    expect(resend, findsOneWidget);
    await tester.tap(resend);
    await tester.pump();
    expect(dao.codeEmails, ['moi@example.com', 'moi@example.com']);
    expect(find.text('Gửi lại sau 60s'), findsOneWidget);
  });

  testWidgets('bước 2: "Đổi" quay về bước 1', (tester) async {
    await openRegister(tester);
    await tester.enterText(field('Email'), 'moi@example.com');
    await tester.tap(button('Gửi mã xác thực'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Đổi'));
    await tester.pumpAndSettle();
    expect(button('Gửi mã xác thực'), findsOneWidget);
  });

  testWidgets('bước 2: mã sai hiện câu của server dưới ô mã, vẫn ở bước 2', (tester) async {
    dao.failures['verifyRegisterCode'] = const ApiException(
      'Mã xác thực không đúng. Bạn còn 4 lần thử.',
      statusCode: 400,
    );
    await openRegister(tester);
    await toStep3(tester);
    expect(find.text('Mã xác thực không đúng. Bạn còn 4 lần thử.'), findsOneWidget);
    expect(field('Mã xác thực'), findsOneWidget);
  });

  testWidgets('bước 3: nhập sai hiện lỗi dưới từng ô và từng ô đánh dấu, không gọi server', (tester) async {
    await openRegister(tester);
    await toStep3(tester);
    expect(find.text('Email đã được xác thực. Hãy tạo mật khẩu.'), findsOneWidget);
    expect(find.text('Từ 8 ký tự'), findsOneWidget);

    await tester.enterText(field('Tên hiển thị'), 'A');
    await tester.enterText(field('Mật khẩu'), '12345678');
    await tester.enterText(field('Nhập lại mật khẩu'), '1234');
    await tapVisible(tester, button('Tạo tài khoản'));
    await tester.pumpAndSettle();

    // Ô nhập có nhãn phía trên (thiết kế) nên form bước 3 dài hơn màn hình: cuộn tới từng câu lỗi
    await expectVisibleOnce(tester, find.text('Tên hiển thị dài từ 2 đến 60 ký tự.'));
    await expectVisibleOnce(tester, find.text('Mật khẩu phải có cả chữ và số'));
    await expectVisibleOnce(tester, find.text('Hai mật khẩu không khớp.'));
    await expectVisibleOnce(tester, find.text('Bạn phải từ đủ 18 tuổi để đăng ký.'));
    await expectVisibleOnce(tester, find.text('Bạn cần đồng ý Điều khoản, Chính sách bảo mật và Quy tắc cộng đồng.'));
    expect(dao.calls, isNot(contains('completeRegistration')));
  });

  testWidgets('bước 3: link "Điều khoản sử dụng" mở LegalScreen', (tester) async {
    await openRegister(tester);
    await toStep3(tester);
    await tapVisible(tester, find.widgetWithText(TextButton, 'Điều khoản sử dụng'));
    await tester.pumpAndSettle();
    expect(find.byType(LegalScreen), findsOneWidget);
    expect(find.text('Phiên bản 1.0'), findsOneWidget);
    expect(find.textContaining('Điều khoản sử dụng Senpai ơi'), findsOneWidget);
  });

  testWidgets('đăng ký xong: tự đăng nhập, hiện câu chào, đóng màn hình với true', (tester) async {
    await openRegister(tester);
    await toStep3(tester);
    await tester.enterText(field('Tên hiển thị'), 'Bạn Mới');
    await tester.enterText(field('Mật khẩu'), 'abc12345');
    await tester.enterText(field('Nhập lại mật khẩu'), 'abc12345');
    await tapVisible(tester, find.text('Tôi xác nhận mình đã đủ 18 tuổi.'));
    await tapVisible(tester, find.textContaining('Tôi đồng ý với'));
    await tapVisible(tester, button('Tạo tài khoản'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsNothing);
    expect(results, [true]);
    expect(dao.registered?.displayName, 'Bạn Mới');
    expect(find.text('Đăng ký thành công. Chào mừng bạn đến với Senpai ơi!'), findsOneWidget);
  });

  testWidgets('vé hết hạn: quay về bước 1 và hiện câu của server', (tester) async {
    dao.failures['completeRegistration'] = const ApiException(
      'Phiên đăng ký đã hết hạn. Vui lòng nhập lại email để nhận mã mới.',
      statusCode: 400,
    );
    await openRegister(tester);
    await toStep3(tester);
    await tester.enterText(field('Tên hiển thị'), 'Bạn Mới');
    await tester.enterText(field('Mật khẩu'), 'abc12345');
    await tester.enterText(field('Nhập lại mật khẩu'), 'abc12345');
    await tapVisible(tester, find.text('Tôi xác nhận mình đã đủ 18 tuổi.'));
    await tapVisible(tester, find.textContaining('Tôi đồng ý với'));
    await tapVisible(tester, button('Tạo tài khoản'));
    await tester.pumpAndSettle();

    expect(find.text('Phiên đăng ký đã hết hạn. Vui lòng nhập lại email để nhận mã mới.'), findsOneWidget);
    expect(button('Gửi mã xác thực'), findsOneWidget);
  });

  testWidgets('màn hẹp 360 dp: cả 3 bước không tràn chữ', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    dao.resendAfterSeconds = 60;
    await openRegister(tester);
    await tester.enterText(field('Email'), 'mot-dia-chi-email-rat-dai-de-thu@example.com');
    await tester.tap(button('Gửi mã xác thực'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Gửi lại sau 60s'), findsOneWidget);
    await tester.enterText(field('Mã xác thực'), '123456');
    await tester.pump();
    await tester.pump();
    expect(field('Tên hiển thị'), findsOneWidget);
    await tapVisible(tester, button('Tạo tài khoản'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('mở từ tab Thêm: "Đăng nhập" thay màn này bằng LoginScreen', (tester) async {
    await openRegister(tester);
    await tapVisible(tester, find.widgetWithText(TextButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(RegisterScreen), findsNothing);
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
