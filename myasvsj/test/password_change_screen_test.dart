// Widget test của ChangePasswordScreen: Đổi mật khẩu / Tạo mật khẩu, lỗi theo ô, khách thấy nút Đăng nhập.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/change_password_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';

import 'auth_fakes.dart';
import 'auth_widget_helpers.dart';

class _Host extends StatelessWidget {
  const _Host(this.results);

  final List<bool?> results;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: ElevatedButton(
        onPressed: () async => results.add(
          await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
        ),
        child: const Text('Mở đổi mật khẩu'),
      ),
    ),
  );
}

void main() {
  late FakeAuthDao dao;
  late List<bool?> results;

  setUp(() {
    dao = FakeAuthDao(current: testUser);
    results = [];
  });

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthController(dao)..restoreSession(),
        child: MaterialApp(home: _Host(results)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mở đổi mật khẩu'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextField, label);
  final save = find.widgetWithText(FilledButton, 'Lưu mật khẩu');

  testWidgets('đã có mật khẩu: "Đổi mật khẩu" có ô mật khẩu hiện tại', (tester) async {
    await open(tester);
    expect(find.text('Đổi mật khẩu'), findsOneWidget);
    expect(find.text('Đổi mật khẩu sẽ đăng xuất bạn khỏi các thiết bị khác.'), findsOneWidget);
    expect(field('Mật khẩu hiện tại'), findsOneWidget);
    expect(field('Mật khẩu mới'), findsOneWidget);
    expect(field('Nhập lại mật khẩu mới'), findsOneWidget);
  });

  testWidgets('chưa có mật khẩu (tài khoản Google): "Tạo mật khẩu", không có ô mật khẩu hiện tại', (tester) async {
    dao.passwordSet = false;
    await open(tester);
    expect(find.text('Tạo mật khẩu'), findsOneWidget);
    expect(field('Mật khẩu hiện tại'), findsNothing);

    await tester.enterText(field('Mật khẩu mới'), 'xyz12345');
    await tester.enterText(field('Nhập lại mật khẩu mới'), 'xyz12345');
    await tapVisible(tester, save);
    await tester.pumpAndSettle();
    expect(dao.changed?.current, isNull);
    expect(find.textContaining('Đã tạo mật khẩu.'), findsOneWidget);
    expect(results, [true]);
  });

  testWidgets('đang hỏi server thì hiện vòng chờ; lỗi thì có Thử lại', (tester) async {
    final slow = _SlowDao(current: testUser)
      ..failures['hasPassword'] = const ApiException('Không kết nối được tới server.');
    dao = slow;
    await open(tester);
    expect(find.text('Không kết nối được tới server.'), findsOneWidget);

    slow.failures.clear();
    slow.gate = Completer<void>();
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    slow.gate!.complete();
    await tester.pumpAndSettle();
    expect(field('Mật khẩu hiện tại'), findsOneWidget);
  });

  testWidgets('nhập sai luật: lỗi dưới từng ô, không gọi server', (tester) async {
    await open(tester);
    await tester.enterText(field('Mật khẩu mới'), 'abc');
    await tester.enterText(field('Nhập lại mật khẩu mới'), 'abd');
    await tapVisible(tester, save);
    await tester.pumpAndSettle();
    expect(find.text('Hãy nhập mật khẩu hiện tại.'), findsOneWidget);
    expect(find.text('Mật khẩu dài từ 8 đến 72 ký tự'), findsOneWidget);
    expect(find.text('Hai mật khẩu không khớp.'), findsOneWidget);
    expect(dao.calls, isNot(contains('changePassword')));
  });

  testWidgets('sai mật khẩu hiện tại: câu của server dưới ô đó', (tester) async {
    dao.failures['changePassword'] = const ApiException(
      'Mật khẩu hiện tại không đúng.',
      statusCode: 400,
      fields: {'currentPassword': 'Mật khẩu hiện tại không đúng.'},
    );
    await open(tester);
    await tester.enterText(field('Mật khẩu hiện tại'), 'sai12345');
    await tester.enterText(field('Mật khẩu mới'), 'xyz12345');
    await tester.enterText(field('Nhập lại mật khẩu mới'), 'xyz12345');
    await tapVisible(tester, save);
    await tester.pumpAndSettle();
    expect(find.text('Mật khẩu hiện tại không đúng.'), findsOneWidget);
    expect(find.byType(ChangePasswordScreen), findsOneWidget);
  });

  testWidgets('đổi thành công: đóng màn hình, hiện "Đã đổi mật khẩu."', (tester) async {
    await open(tester);
    await tester.enterText(field('Mật khẩu hiện tại'), 'abc12345');
    await tester.enterText(field('Mật khẩu mới'), 'xyz12345');
    await tester.enterText(field('Nhập lại mật khẩu mới'), 'xyz12345');
    await tapVisible(tester, save);
    await tester.pumpAndSettle();
    expect(dao.changed, (current: 'abc12345', password: 'xyz12345', confirm: 'xyz12345'));
    expect(find.byType(ChangePasswordScreen), findsNothing);
    expect(find.text('Đã đổi mật khẩu.'), findsOneWidget);
    expect(results, [true]);
  });

  testWidgets('khách: thấy nút Đăng nhập, bấm thì ra LoginScreen', (tester) async {
    dao = FakeAuthDao();
    await open(tester);
    expect(find.text('Bạn cần đăng nhập để đổi mật khẩu.'), findsOneWidget);
    expect(dao.calls, isNot(contains('hasPassword')));
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}

/// DAO giả trả lời chậm: hasPassword chờ [gate] để test thấy được trạng thái chờ.
class _SlowDao extends FakeAuthDao {
  _SlowDao({super.current});

  Completer<void>? gate;

  @override
  Future<bool> hasPassword() async {
    await gate?.future;
    return super.hasPassword();
  }
}
