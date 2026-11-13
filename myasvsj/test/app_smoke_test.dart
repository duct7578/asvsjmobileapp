// Smoke test cả app: dựng SenpaiApp thật (mọi Controller, DAO, NotificationHost như main.dart) trên server giả,
// rồi đi qua 5 tab và các mục của tab "Thêm" khi là khách. Bắt lỗi ghép nối: thiếu provider, màn hình ném lỗi
// khi dựng, điều hướng hỏng. Server giả trả 404 cho mọi API nên các màn hình phải hiện lỗi gọn, không sập.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/main_screen.dart';
import 'package:myasvsj/main.dart';

import 'fake_api.dart';

void main() {
  late FakeServer server;

  setUp(() {
    server = FakeServer({
      'GET /api/auth/me': (_) => apiError(401, 'Bạn cần đăng nhập.'),
    });
  });

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
    await tester.pumpAndSettle();
  }

  testWidgets('khách mở app: 5 tab đều dựng được, không có lỗi', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(SenpaiApp(api: server.api));
    await tester.pumpAndSettle();
    expect(find.byType(MainScreen), findsOneWidget);

    for (final tab in ['Blog', 'Hỏi-Đáp', 'Thêm', 'Trang chủ']) {
      await openTab(tester, tab);
      expect(tester.takeException(), isNull, reason: 'tab $tab');
    }
    // Khách không có nút "Tôi" mà có "Đăng nhập" trên thanh tiêu đề
    expect(find.byTooltip('Đăng nhập'), findsWidgets);
  });

  testWidgets('tab Thêm: mở từng mục công khai rồi quay lại', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(SenpaiApp(api: server.api));
    await tester.pumpAndSettle();
    await openTab(tester, 'Thêm');

    for (final item in [
      'Nhật ngữ',
      'Lễ hội và sự kiện',
      'Cẩm nang',
      'Câu hỏi thường gặp',
      'Đăng ký',
      'Điều khoản sử dụng',
      'Chính sách bảo mật',
      'Quy tắc cộng đồng',
    ]) {
      // "Đăng ký" nằm trong thẻ mời ở đầu tab, có thể đã cuộn khỏi màn hình: tìm cả phần tử chưa hiện
      await tester.ensureVisible(find.text(item, skipOffstage: false).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(item).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: item);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('tab Bản đồ dựng được khi là khách (server lỗi thì báo lỗi, không sập)', (tester) async {
    await tester.pumpWidget(SenpaiApp(api: server.api));
    await tester.pumpAndSettle();

    await openTab(tester, 'Bản đồ');
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('khách bấm Tin nhắn trên thanh tiêu đề thì sang Đăng nhập', (tester) async {
    await tester.pumpWidget(SenpaiApp(api: server.api));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Tin nhắn').first);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
