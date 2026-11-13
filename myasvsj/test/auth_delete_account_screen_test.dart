// Widget test của DeleteAccountScreen: giải thích hậu quả, hỏi xác nhận, xóa xong về khách và về màn hình gốc.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/delete_account_screen.dart';

import 'auth_fakes.dart';
import 'auth_widget_helpers.dart';

/// Màn gốc → màn trung gian (như trang Tôi) → DeleteAccountScreen, để kiểm tra "về màn hình gốc".
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(auth.isSignedIn ? 'Đang đăng nhập' : 'Khách'),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Tôi')),
                    body: Builder(
                      builder: (inner) => TextButton(
                        onPressed: () =>
                            Navigator.push(inner, MaterialPageRoute<void>(builder: (_) => const DeleteAccountScreen())),
                        child: const Text('Mở xóa tài khoản'),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('Mở trang Tôi'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  late FakeAuthDao dao;

  setUp(() => dao = FakeAuthDao(current: testUser));

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthController(dao)..restoreSession(),
        child: const MaterialApp(home: _Root()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mở trang Tôi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mở xóa tài khoản'));
    await tester.pumpAndSettle();
  }

  final deleteButton = find.widgetWithText(FilledButton, 'Xóa tài khoản');

  testWidgets('giải thích hậu quả như web và email của tài khoản', (tester) async {
    await open(tester);
    expect(find.text('Xóa tài khoản?'), findsOneWidget);
    expect(find.text('an@example.com'), findsOneWidget);
    for (final line in DeleteAccountScreen.consequences) {
      expect(find.text(line), findsOneWidget);
    }
    expect(deleteButton, findsOneWidget);
  });

  testWidgets('bấm Xóa rồi Hủy trong hộp xác nhận: không gọi server', (tester) async {
    await open(tester);
    await tapVisible(tester, deleteButton);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Tài khoản an@example.com sẽ bị xóa và không thể khôi phục.'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Hủy'));
    await tester.pumpAndSettle();
    expect(dao.calls, isNot(contains('deleteAccount')));
    expect(find.byType(DeleteAccountScreen), findsOneWidget);
  });

  testWidgets('xác nhận xóa: về khách, quay về màn hình gốc, hiện câu của server', (tester) async {
    await open(tester);
    await tapVisible(tester, deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Xóa tài khoản')));
    await tester.pumpAndSettle();

    expect(dao.calls, contains('deleteAccount'));
    expect(find.byType(DeleteAccountScreen), findsNothing);
    expect(find.text('Tôi'), findsNothing);
    expect(find.text('Khách'), findsOneWidget);
    expect(find.text('Đã xóa tài khoản.'), findsOneWidget);
  });

  testWidgets('server lỗi: vẫn ở màn hình, hiện câu lỗi', (tester) async {
    dao.failures['deleteAccount'] = const ApiException('Server gặp lỗi (500). Hãy thử lại sau.', statusCode: 500);
    await open(tester);
    await tapVisible(tester, deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Xóa tài khoản')));
    await tester.pumpAndSettle();

    expect(find.byType(DeleteAccountScreen), findsOneWidget);
    expect(find.text('Server gặp lỗi (500). Hãy thử lại sau.'), findsOneWidget);
  });

  testWidgets('khách: thấy câu cần đăng nhập, không có nút xóa', (tester) async {
    dao = FakeAuthDao();
    await open(tester);
    expect(find.text('Bạn cần đăng nhập để xóa tài khoản.'), findsOneWidget);
    expect(deleteButton, findsNothing);
  });
}
