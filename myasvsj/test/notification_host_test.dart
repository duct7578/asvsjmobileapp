// Widget test của NotificationHost: nối đăng nhập với luồng tức thì, số chưa đọc trên chuông (AppBarActions),
// thông báo trên máy, bấm thông báo trên máy để mở màn hình, app mở lại từ nền.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/chat_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';
import 'package:myasvsj/com.myasvsj.model/app_notification.dart';
import 'package:myasvsj/com.myasvsj.model/chat_counts.dart';
import 'package:myasvsj/com.myasvsj.model/live_event.dart';
import 'package:myasvsj/com.myasvsj.screen/app_bar_actions.dart';
import 'package:myasvsj/com.myasvsj.screen/chat_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/notification_host.dart';
import 'package:myasvsj/com.myasvsj.screen/notification_screen.dart';

import 'auth_fakes.dart';
import 'chat_fakes.dart';
import 'live_fakes.dart';
import 'notification_fakes.dart';
import 'notification_test_app.dart';

void main() {
  late FakeNotificationDao notificationDao;
  late FakeChatDao chatDao;
  late FakeLiveDao live;
  late FakeNotificationDevice device;

  setUp(() {
    notificationDao = FakeNotificationDao();
    chatDao = FakeChatDao();
    live = FakeLiveDao();
    device = FakeNotificationDevice();
  });

  /// Trang chủ giả có thanh tiêu đề như 5 tab chính.
  Widget home() => NotificationHost(
    child: Scaffold(
      appBar: AppBar(title: const Text('Trang chủ'), actions: const [AppBarActions()]),
      body: const Center(child: Text('Nội dung trang chủ')),
    ),
  );

  Future<AuthController> pumpHost(WidgetTester tester, {AuthController? auth}) async {
    final signedIn = auth ?? await signedInAuth();
    await tester.pumpWidget(
      notifyChatApp(
        home: home(),
        auth: signedIn,
        notifications: NotificationController(notificationDao, live: live, device: device),
        chat: ChatController(chatDao, device: device),
      ),
    );
    await tester.pumpAndSettle();
    return signedIn;
  }

  testWidgets('đã đăng nhập: mở luồng, xin quyền thông báo, chuông hiện số chưa đọc', (tester) async {
    await pumpHost(tester);
    expect(live.opens, 1);
    expect(live.isListened, isTrue);
    expect(device.permissionRequests, 1);
    expect(notificationDao.summaryAfter, [null]);
    expect(chatDao.calls, contains('findCounts'));
    expect(find.text('Nội dung trang chủ'), findsOneWidget);
    expect(find.descendant(of: find.byType(Badge), matching: find.text('2')), findsOneWidget);
  });

  testWidgets('khách: không mở luồng, không gọi API; đăng nhập xong thì mở', (tester) async {
    final auth = AuthController(FakeAuthDao());
    await pumpHost(tester, auth: auth);
    expect(live.opens, 0);
    expect(notificationDao.summaryAfter, isEmpty);

    await auth.login('an@example.com', '123456');
    await tester.pumpAndSettle();
    expect(live.opens, 1);
    expect(notificationDao.summaryAfter, [null]);
  });

  testWidgets('có thông báo mới (SSE): số trên chuông tăng và thông báo hiện trên máy', (tester) async {
    await pumpHost(tester);
    live.emit(const LiveEvent(LiveEvent.ready));
    await tester.pumpAndSettle();

    notificationDao.arrive(
      AppNotification(
        id: 6,
        type: 'BEST_ANSWER',
        content: 'Câu trả lời của bạn trong “Gia hạn visa” được chọn là hay nhất.',
        link: '/qa/8',
        createdAt: DateTime.now(),
      ),
    );
    live.emit(const LiveEvent(LiveEvent.notification));
    await tester.pumpAndSettle();

    // Chỉ xét số trên chuông: nút Tin nhắn bên cạnh cũng có Badge riêng
    expect(find.descendant(of: find.byTooltip('Thông báo'), matching: find.text('3')), findsOneWidget);
    expect(device.shown.single.title, 'Câu trả lời hay nhất');
    expect(device.shown.single.link, '/qa/8');
  });

  testWidgets('tin nhắn mới (SSE chat) tới ChatController: "Tin nhắn mới từ …" trên máy', (tester) async {
    await pumpHost(tester);
    chatDao.counts = const ChatCounts(
      unread: 1,
      latest: (conversationId: 1, messageId: 20, peerName: 'Lan Anh', request: false),
    );
    live.emit(const LiveEvent(LiveEvent.chat, {'kind': 'message', 'conversationId': 1, 'messageId': 20}));
    await tester.pumpAndSettle();
    expect(device.shown.single.title, 'Tin nhắn mới từ Lan Anh');
    expect(device.shown.single.link, '/messages/1');
  });

  testWidgets('bấm thông báo tin nhắn trên máy: mở đúng cuộc trò chuyện', (tester) async {
    await pumpHost(tester);
    device.tap('/messages/1');
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('Chào em, chị đây. Em hỏi đi.'), findsOneWidget);
  });

  testWidgets('bấm thông báo không có trang riêng trên máy: mở màn Thông báo', (tester) async {
    await pumpHost(tester);
    device.tap('/notifications');
    await tester.pumpAndSettle();
    expect(find.byType(NotificationScreen), findsOneWidget);
    expect(find.text('Bạn đã được cấp tag Mentor.'), findsOneWidget);
  });

  testWidgets('đăng xuất: đóng luồng, chuông về 0', (tester) async {
    final auth = await pumpHost(tester);
    await auth.logout();
    await tester.pumpAndSettle();
    expect(live.isListened, isFalse);
    expect(tester.element(find.byType(NotificationHost)).read<NotificationController>().unreadCount, 0);
    expect(find.descendant(of: find.byType(Badge), matching: find.text('2')), findsNothing);
  });

  testWidgets('app mở lại từ nền: hỏi summary một lần', (tester) async {
    await pumpHost(tester);
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(notificationDao.summaryAfter, [null, 5]);
  });
}
