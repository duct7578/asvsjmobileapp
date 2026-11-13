// Test đầu-cuối: chạy app thật trên giả lập Android, gọi server web thật (http://10.0.2.2:8080, dữ liệu mẫu
// của profile local). Đi qua các tab khi là khách, đăng nhập bằng tài khoản mẫu, mở các màn cá nhân, đăng xuất.
//
// Chạy (server web đang chạy ở máy dev, giả lập đã mở):
//   flutter test integration_test/app_flow_test.dart -d emulator-5554
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:myasvsj/com.myasvsj.screen/blog_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/conversation_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/main_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/notification_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_screen.dart';
import 'package:myasvsj/main.dart' as app;

/// Bơm khung hình cho tới khi [finder] xuất hiện (app gọi mạng thật nên không dùng pumpAndSettle:
/// luồng SSE, vòng quay chờ… làm nó không bao giờ "yên").
Future<void> waitFor(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  throw TestFailure('Hết ${timeout.inSeconds}s mà chưa thấy: $finder');
}

/// Bơm khung hình cho tới khi [finder] không còn trên màn hình (ví dụ màn Đăng nhập đã đóng).
Future<void> waitGone(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 200));
    if (finder.evaluate().isEmpty) {
      return;
    }
  }
  throw TestFailure('Hết ${timeout.inSeconds}s mà vẫn còn: $finder');
}

Future<void> settle(WidgetTester tester, [int seconds = 2]) async {
  for (var i = 0; i < seconds * 5; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await settle(tester);
}

Future<void> back(WidgetTester tester) async {
  await tester.pageBack();
  await settle(tester, 1);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('khách duyệt app, đăng nhập user@gmail.com, mở các màn cá nhân, đăng xuất; staff bị từ chối', (
    tester,
  ) async {
    await app.main();
    await waitFor(tester, find.byType(MainScreen));
    await settle(tester, 3);

    // Lần chạy trước còn phiên (cookie lưu trên máy) thì đăng xuất trước
    if (find.byTooltip('Tôi').evaluate().isNotEmpty) {
      await tester.tap(find.byTooltip('Tôi').first);
      await waitFor(tester, find.text('Đăng xuất'));
      await tester.ensureVisible(find.text('Đăng xuất'));
      await settle(tester, 1);
      await tester.tap(find.text('Đăng xuất'));
      await settle(tester, 3);
    }
    await waitFor(tester, find.byTooltip('Đăng nhập'));

    // ----- Khách: Blog → chi tiết bài mẫu
    await openTab(tester, 'Blog');
    const sample = 'Năm điều mình ước biết trước tuần đầu ở Tokyo';
    await waitFor(tester, find.text(sample));
    await tester.tap(find.text(sample).first);
    await waitFor(tester, find.byType(BlogDetailScreen));
    await waitFor(tester, find.textContaining('Mua thẻ IC'));
    await back(tester);

    // ----- Hỏi-Đáp và FAQ, Bản đồ
    await openTab(tester, 'Hỏi-Đáp');
    await waitFor(tester, find.text('Câu hỏi thường gặp'));
    await tester.tap(find.text('Câu hỏi thường gặp').first);
    await settle(tester);
    await openTab(tester, 'Bản đồ');
    await settle(tester, 4);
    expect(tester.takeException(), isNull);

    // ----- Thêm → Nhật ngữ
    await openTab(tester, 'Thêm');
    await tester.tap(find.text('Nhật ngữ'));
    await waitFor(tester, find.byType(PhraseScreen));
    await settle(tester, 3);
    await back(tester);

    // ----- Đăng nhập
    await tester.tap(find.byTooltip('Đăng nhập').first);
    await waitFor(tester, find.byType(LoginScreen));
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'user@gmail.com');
    await tester.enterText(find.widgetWithText(TextField, 'Mật khẩu'), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await waitGone(tester, find.byType(LoginScreen));
    await waitFor(tester, find.byTooltip('Tôi'));

    // ----- Trang chủ thành viên
    await openTab(tester, 'Trang chủ');
    // Lời chào dùng tên gọi (chữ cuối của "Trần Minh")
    await waitFor(tester, find.textContaining('Chào Minh'));

    // ----- Thông báo, Tin nhắn, Tôi
    await tester.tap(find.byTooltip('Thông báo').first);
    await waitFor(tester, find.byType(NotificationScreen));
    await settle(tester, 3);
    await back(tester);

    await tester.tap(find.byTooltip('Tin nhắn').first);
    await waitFor(tester, find.byType(ConversationListScreen));
    await settle(tester, 3);
    await back(tester);

    await tester.tap(find.byTooltip('Tôi').first);
    await waitFor(tester, find.byType(ProfileScreen));
    await waitFor(tester, find.textContaining('user@gmail.com'));

    // ----- Đăng xuất (cuối trang Tôi, có thể chưa được dựng: cuộn tới)
    await tester.scrollUntilVisible(
      find.text('Đăng xuất'),
      300,
      scrollable: find.descendant(of: find.byType(ProfileScreen), matching: find.byType(Scrollable)).first,
    );
    await tester.ensureVisible(find.text('Đăng xuất'));
    await settle(tester, 1);
    await tester.tap(find.text('Đăng xuất'));
    await settle(tester, 3);
    await waitFor(tester, find.byTooltip('Đăng nhập'));
    expect(tester.takeException(), isNull);

    // ----- Tài khoản staff bị từ chối trên app (cùng phiên app: dựng app lần hai sẽ hủy Controller của lần
    // đầu trong lúc các lời gọi mạng của chúng chưa xong)
    await tester.tap(find.byTooltip('Đăng nhập').first);
    await waitFor(tester, find.byType(LoginScreen));
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'moderator@gmail.com');
    await tester.enterText(find.widgetWithText(TextField, 'Mật khẩu'), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await waitFor(tester, find.textContaining('Tài khoản quản lý chỉ dùng trên trang web'));
    expect(find.byType(LoginScreen), findsOneWidget);
    await back(tester);
    expect(find.byTooltip('Đăng nhập'), findsWidgets);

    // Chờ các lời gọi mạng còn dở kết thúc trước khi test đóng app
    await settle(tester, 3);
    expect(tester.takeException(), isNull);
  });
}
