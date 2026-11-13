// Ảnh màn 30–34 (Tin nhắn, Trò chuyện, Đăng nhập, Đăng ký bước 2, Quên mật khẩu bước 2) và vài trạng thái khác
// để so với design/figma-export/ref/30-*.png … 34-*.png.
// Chạy: flutter test test/design_shots/chat_auth_shot_test.dart --dart-define=SHOTS=true
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/chat_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';
import 'package:myasvsj/com.myasvsj.model/chat_conversation.dart';
import 'package:myasvsj/com.myasvsj.model/chat_counts.dart';
import 'package:myasvsj/com.myasvsj.model/chat_dao.dart';
import 'package:myasvsj/com.myasvsj.model/chat_message.dart';
import 'package:myasvsj/com.myasvsj.model/chat_peer.dart';
import 'package:myasvsj/com.myasvsj.model/chat_status.dart';
import 'package:myasvsj/com.myasvsj.model/conversation_item.dart';
import 'package:myasvsj/com.myasvsj.model/conversation_page.dart';
import 'package:myasvsj/com.myasvsj.screen/chat_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/conversation_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/forgot_password_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/register_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';

import '../auth_fakes.dart';
import '../chat_fakes.dart';
import '../notification_fakes.dart';
import 'shot_helper.dart';

/// DAO tin nhắn giả có "Xem thêm" (hasMore) như danh sách mẫu của thiết kế.
class _ShotChatDao extends FakeChatDao {
  @override
  Future<ConversationPage> findAll({String box = ChatDao.inbox, int page = 0}) async {
    final base = await super.findAll(box: box, page: page);
    return ConversationPage(items: base.items, counts: base.counts, hasMore: box == ChatDao.inbox);
  }
}

void main() {
  final now = DateTime.now();
  DateTime today(int h, int m) => DateTime(now.year, now.month, now.day, h, m);

  const vy = ChatPeer(id: 4, displayName: 'Thảo Vy', tags: [(name: 'Đã đi làm', color: ''), (name: 'Senpai vàng', color: '')]);

  _ShotChatDao chatDao() {
    final dao = _ShotChatDao()
      ..counts = const ChatCounts(unread: 2, requests: 2)
      ..inbox = [
        ConversationItem(
          id: 1,
          peer: vy,
          unread: 2,
          lastMessage: ChatMessage(
            id: 20,
            mine: false,
            content: 'Không em ơi, xe buýt Koedo Loop mua vé ngày riêng nhé.',
            createdAt: now.subtract(const Duration(minutes: 2)),
          ),
        ),
        ConversationItem(
          id: 2,
          peer: const ChatPeer(id: 5, displayName: 'Quang Huy'),
          lastMessage: ChatMessage(
            id: 19,
            mine: true,
            content: 'Em cảm ơn anh nhiều ạ!',
            createdAt: now.subtract(const Duration(minutes: 61)),
          ),
        ),
        ConversationItem(
          id: 3,
          peer: const ChatPeer(id: 6, displayName: 'Mai'),
          lastMessage: ChatMessage(id: 18, mine: false, isEncrypted: true, createdAt: now.subtract(const Duration(days: 1))),
        ),
        ConversationItem(
          id: 4,
          peer: const ChatPeer(id: 7, displayName: 'Khánh'),
          lastMessage: ChatMessage(id: 17, mine: false, hasFiles: true, createdAt: now.subtract(const Duration(days: 3))),
        ),
        ConversationItem(
          id: 5,
          peer: const ChatPeer(id: 8, displayName: 'Tuấn', active: false),
          lastMessage: ChatMessage(id: 16, mine: false, recalled: true, createdAt: DateTime(2026, 10, 12, 10)),
        ),
        ConversationItem(
          id: 6,
          peer: const ChatPeer(id: 9, displayName: 'Phong'),
          blockedByMe: true,
          lastMessage: ChatMessage(id: 15, mine: true, recalled: true, createdAt: DateTime(2026, 10, 3, 10)),
        ),
      ];
    dao.rooms[1] = ChatConversation(
      id: 1,
      peer: vy,
      status: const ChatStatus(state: 'ACCEPTED', canSend: true, canReact: true, peerTyping: true),
      messages: [
        ChatMessage(id: 1, mine: false, content: 'Chào em, chị thấy em hỏi về Kawagoe ở bài viết nè.', createdAt: today(9, 12)),
        ChatMessage(
          id: 2,
          mine: true,
          content: 'Dạ chị, pass 700 yên có dùng cho xe buýt vòng quanh phố cổ không ạ?',
          createdAt: today(9, 14),
        ),
        ChatMessage(
          id: 3,
          mine: false,
          content: 'Không em ơi, xe buýt Koedo Loop mua vé ngày riêng 500 yên nhé. Đi bộ cũng được, phố cổ nhỏ lắm.',
          replyToId: 2,
          reactions: const [(emoji: '👍', count: 1, mine: true)],
          createdAt: today(9, 20),
        ),
        ChatMessage(id: 4, mine: true, content: 'Em cảm ơn chị nhiều!', createdAt: today(9, 21)),
      ],
      reportReasons: reasons,
    );
    return dao;
  }

  /// App có màn trước để thanh tiêu đề có nút quay lại như thiết kế.
  Widget pushed(Widget screen) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: SenpaiTheme.light(),
    initialRoute: '/s',
    routes: {'/': (_) => const Scaffold(), '/s': (_) => screen},
  );

  Widget app(Widget screen, {required bool signedIn, ChatDao? chat, FakeAuthDao? auth}) => MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (_) => AuthController(auth ?? FakeAuthDao(current: signedIn ? testUser : null))..restoreSession(),
      ),
      ChangeNotifierProvider(create: (_) => NotificationController(FakeNotificationDao())),
      ChangeNotifierProvider(create: (_) => ChatController(chat ?? chatDao())),
    ],
    child: pushed(screen),
  );

  Future<void> clearSnack(WidgetTester tester) async {
    tester.state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger)).clearSnackBars();
    await tester.pumpAndSettle();
  }

  testWidgets('30 Tin nhắn', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const ConversationListScreen(), signedIn: true));
    await saveShot(tester, '30-conversation-list');
  });

  testWidgets('30 Tin nhắn — khách', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const ConversationListScreen(), signedIn: false));
    await saveShot(tester, '30-conversation-list-guest');
  });

  testWidgets('31 Trò chuyện', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const ChatScreen(conversationId: 1, title: 'Thảo Vy'), signedIn: true));
    await saveShot(tester, '31-chat');
  });

  testWidgets('31 Trò chuyện — lời mời', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const ChatScreen(conversationId: 2), signedIn: true, chat: FakeChatDao()));
    await saveShot(tester, '31-chat-request');
  });

  testWidgets('32 Đăng nhập', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const LoginScreen(), signedIn: false));
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'linh.nguyen@gmail.com');
    await tester.enterText(find.widgetWithText(TextField, 'Mật khẩu'), 'matkhau123');
    await settleShot(tester);
    await saveShot(tester, '32-login');
  });

  testWidgets('32 Đăng nhập — lỗi', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const LoginScreen(), signedIn: false));
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await settleShot(tester);
    await saveShot(tester, '32-login-errors');
  });

  testWidgets('33 Đăng ký — bước 1', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const RegisterScreen(), signedIn: false));
    await saveShot(tester, '33-register-step1');
  });

  testWidgets('33 Đăng ký — bước 2', skip: shotSkip != null, (tester) async {
    final auth = FakeAuthDao()..resendAfterSeconds = 45;
    await pumpShot(tester, app(const RegisterScreen(), signedIn: false, auth: auth));
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'linh.nguyen@gmail.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Gửi mã xác thực'));
    await tester.pump();
    await tester.pump();
    await clearSnack(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Mã xác thực'), '4829');
    await tester.pump();
    await saveShot(tester, '33-register-step2');
  });

  testWidgets('33 Đăng ký — bước 3', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const RegisterScreen(), signedIn: false), height: 1100);
    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'linh.nguyen@gmail.com');
    await tester.tap(find.widgetWithText(FilledButton, 'Gửi mã xác thực'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Mã xác thực'), '123456');
    await tester.pumpAndSettle();
    await clearSnack(tester);
    await tester.enterText(find.widgetWithText(TextField, 'Mật khẩu'), 'abcdefgh');
    await settleShot(tester);
    await saveShot(tester, '33-register-step3');
  });

  testWidgets('34 Quên mật khẩu — bước 1', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const ForgotPasswordScreen(initialEmail: 'linh.nguyen@gmail.com'), signedIn: false));
    await saveShot(tester, '34-forgot-password-step1');
  });

  testWidgets('34 Quên mật khẩu — bước 2', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const ForgotPasswordScreen(), signedIn: false));
    await tester.tap(find.text('Tôi đã có đường link trong email'));
    await settleShot(tester);
    await saveShot(tester, '34-forgot-password');
  });

  testWidgets('34 Quên mật khẩu — bước 3', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const ForgotPasswordScreen(), signedIn: false));
    await tester.tap(find.text('Tôi đã có đường link trong email'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'http://…/reset-password?token=…'),
      'http://localhost:8080/reset-password?token=Rgw3YMVgp66LygwJKdvg30LAOm1P1FXKu8dqiRWs5TU',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Tiếp tục'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Mật khẩu mới'), 'reset123');
    await settleShot(tester);
    await saveShot(tester, '34-forgot-password-step3');
  });
}
