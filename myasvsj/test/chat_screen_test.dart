// Widget test của ChatScreen: đọc / gửi tin, lời mời, sửa / thu hồi / báo cáo, chặn, hội thoại mã hóa đầu cuối.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/chat_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/chat_message.dart';
import 'package:myasvsj/com.myasvsj.model/chat_status.dart';
import 'package:myasvsj/com.myasvsj.model/live_event.dart';
import 'package:myasvsj/com.myasvsj.screen/chat_bubble.dart';
import 'package:myasvsj/com.myasvsj.screen/chat_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';

import 'chat_fakes.dart';
import 'notification_test_app.dart';

void main() {
  late FakeChatDao dao;

  setUp(() => dao = FakeChatDao());

  Future<ChatController> pumpChat(WidgetTester tester, {int? conversationId = 1, int? withUserId}) async {
    final chat = ChatController(dao, typingShow: const Duration(milliseconds: 200));
    await tester.pumpWidget(
      notifyChatApp(
        home: ChatScreen(conversationId: conversationId, withUserId: withUserId, title: 'Lan Anh'),
        auth: await signedInAuth(),
        chat: chat,
      ),
    );
    await tester.pumpAndSettle();
    return chat;
  }

  Future<void> longPress(WidgetTester tester, String text) async {
    await tester.longPress(find.text(text));
    await tester.pumpAndSettle();
  }

  testWidgets('khách thấy lời mời đăng nhập; bấm Đăng nhập thì sang màn Đăng nhập', (tester) async {
    await tester.pumpWidget(notifyChatApp(home: const ChatScreen(withUserId: 6), chat: ChatController(dao)));
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập để nhắn tin với thành viên khác.'), findsOneWidget);
    expect(dao.calls, isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('hiện tên, tag, tin nhắn, lời nhắc an toàn, rồi đánh dấu đã đọc', (tester) async {
    await pumpChat(tester);
    expect(find.text('Lan Anh'), findsOneWidget);
    expect(find.text('Mentor'), findsOneWidget);
    expect(find.byType(ChatBubble), findsNWidgets(2));
    expect(find.text('Chào chị, em là Minh. Em muốn hỏi về thuê nhà ở Tokyo ạ.'), findsOneWidget);
    expect(find.textContaining('không bao giờ hỏi mật khẩu'), findsOneWidget);
    expect(find.text('Hôm nay'), findsOneWidget);
    expect(dao.reads.single, (conversationId: 1, upToId: 5));
  });

  testWidgets('đang tải hiện vòng quay; lỗi hiện câu của server và Thử lại', (tester) async {
    dao.hold = Completer<void>();
    final chat = ChatController(dao);
    await tester.pumpWidget(
      notifyChatApp(home: const ChatScreen(conversationId: 1), auth: await signedInAuth(), chat: chat),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    dao.failWith = const ApiException('Không tìm thấy cuộc trò chuyện này.', statusCode: 404);
    dao.hold!.complete();
    dao.hold = null;
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy cuộc trò chuyện này.'), findsOneWidget);

    dao.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatBubble), findsNWidgets(2));
  });

  testWidgets('gửi tin: tin mới hiện ở cuối, ô soạn tin được xóa, "Đã gửi"', (tester) async {
    await pumpChat(tester);
    await tester.enterText(find.byType(TextField), 'Dạ em cảm ơn chị');
    await tester.tap(find.byTooltip('Gửi'));
    await tester.pumpAndSettle();
    expect(dao.calls, contains('send 1 Dạ em cảm ơn chị'));
    expect(find.text('Dạ em cảm ơn chị'), findsOneWidget);
    expect(find.textContaining('Đã gửi'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, isEmpty);
  });

  testWidgets('gửi lỗi: câu của server hiện dưới ô soạn tin, chữ vẫn còn', (tester) async {
    dao.failSendWith = const ApiException('Bạn gửi tin nhắn hơi nhanh. Vui lòng đợi một lát rồi thử lại.');
    await pumpChat(tester);
    await tester.enterText(find.byType(TextField), 'Tin thứ 31');
    await tester.tap(find.byTooltip('Gửi'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn gửi tin nhắn hơi nhanh. Vui lòng đợi một lát rồi thử lại.'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Tin thứ 31');
  });

  testWidgets('tin trống không gửi', (tester) async {
    await pumpChat(tester);
    dao.calls.clear();
    await tester.tap(find.byTooltip('Gửi'));
    await tester.pumpAndSettle();
    expect(find.text('Hãy nhập tin nhắn.'), findsOneWidget);
    expect(dao.calls, isEmpty);
  });

  testWidgets('lời mời: câu của server, Chấp nhận thì nhắn tự do', (tester) async {
    await pumpChat(tester, conversationId: 2);
    expect(find.textContaining('Chat Stranger muốn nhắn tin với bạn.'), findsOneWidget);
    expect(find.text('Từ chối'), findsOneWidget);

    await tester.tap(find.text('Chấp nhận'));
    await tester.pumpAndSettle();
    expect(dao.calls, contains('accept 2'));
    expect(find.text('Đã chấp nhận lời mời nhắn tin.'), findsOneWidget);
    expect(find.text('Từ chối'), findsNothing);
  });

  testWidgets('Từ chối lời mời hỏi xác nhận rồi quay về màn hình trước', (tester) async {
    final chat = ChatController(dao);
    await tester.pumpWidget(
      notifyChatApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ChatScreen(conversationId: 2))),
              child: const Text('Mở'),
            ),
          ),
        ),
        auth: await signedInAuth(),
        chat: chat,
      ),
    );
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Từ chối'));
    await tester.pumpAndSettle();
    expect(find.textContaining('không được báo là bị từ chối'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Từ chối'));
    await tester.pumpAndSettle();

    expect(dao.calls, contains('decline 2'));
    expect(find.byType(ChatScreen), findsNothing);
    expect(find.text('Đã từ chối lời mời nhắn tin.'), findsOneWidget);
  });

  testWidgets('nhắn cho người chưa từng nhắn: thông báo NEW, tin đầu tiên tạo cuộc trò chuyện', (tester) async {
    await pumpChat(tester, conversationId: null, withUserId: 7);
    expect(find.textContaining('Tin nhắn đầu tiên sẽ đến Hoàng'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Chào bạn, mình muốn hỏi về bài viết');
    await tester.tap(find.byTooltip('Gửi'));
    await tester.pumpAndSettle();
    expect(dao.calls, contains('sendTo 7 Chào bạn, mình muốn hỏi về bài viết'));
    expect(find.textContaining('Bạn còn gửi được 2 tin nhắn'), findsOneWidget);
  });

  testWidgets('hết lượt lời mời: ô soạn tin bị khóa', (tester) async {
    dao.rooms[1] = acceptedRoom().copyWith(
      status: const ChatStatus(
        state: 'ACCEPTED',
        noticeCode: 'WAITING_FULL',
        noticeText: 'Lan Anh chưa nhận lời mời nhắn tin của bạn. Bạn gửi thêm được khi Lan Anh trả lời.',
      ),
    );
    await pumpChat(tester);
    expect(find.textContaining('Bạn gửi thêm được khi Lan Anh trả lời.'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(find.text('Bạn chưa gửi được tin nhắn'), findsOneWidget);
  });

  testWidgets('hội thoại mã hóa đầu cuối khi không có khóa: khóa ô soạn tin, tin mã hóa không hiện nội dung', (
    tester,
  ) async {
    dao.rooms[1] = acceptedRoom().copyWith(
      status: const ChatStatus(state: 'ACCEPTED', canSend: true, canReact: true, isEncrypted: true),
      messages: [
        ...acceptedRoom().messages,
        ChatMessage(id: 8, mine: false, isEncrypted: true, createdAt: DateTime.now()),
      ],
    );
    await pumpChat(tester);
    expect(find.textContaining('Cuộc trò chuyện này đã được mã hóa đầu cuối.'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('Tin nhắn đã mã hóa'), findsOneWidget);
    expect(find.text('Chào em, chị đây. Em hỏi đi.'), findsOneWidget, reason: 'tin thường cũ vẫn đọc được');
  });

  testWidgets('nhấn giữ tin của mình: Sửa đưa chữ vào ô soạn tin, Lưu gửi bản đã sửa', (tester) async {
    await pumpChat(tester);
    await longPress(tester, 'Chào chị, em là Minh. Em muốn hỏi về thuê nhà ở Tokyo ạ.');
    expect(find.text('Sửa'), findsOneWidget);
    expect(find.text('Thu hồi'), findsOneWidget);
    expect(find.text('Báo cáo'), findsNothing);

    await tester.tap(find.text('Sửa'));
    await tester.pumpAndSettle();
    expect(find.text('Đang sửa tin nhắn'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Chào chị, em là Minh (đã sửa).');
    await tester.tap(find.byTooltip('Lưu'));
    await tester.pumpAndSettle();
    expect(dao.calls, contains('update 1 1 Chào chị, em là Minh (đã sửa).'));
    expect(find.text('Chào chị, em là Minh (đã sửa).'), findsOneWidget);
    expect(find.textContaining('đã sửa'), findsWidgets);
    expect(find.text('Đang sửa tin nhắn'), findsNothing);
  });

  testWidgets('Thu hồi hỏi xác nhận rồi hiện "Bạn đã thu hồi một tin nhắn"', (tester) async {
    await pumpChat(tester);
    await longPress(tester, 'Chào chị, em là Minh. Em muốn hỏi về thuê nhà ở Tokyo ạ.');
    await tester.tap(find.text('Thu hồi'));
    await tester.pumpAndSettle();
    expect(find.text('Thu hồi tin nhắn này?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Thu hồi'));
    await tester.pumpAndSettle();
    expect(dao.calls, contains('recall 1 1'));
    expect(find.text(ChatBubble.recalledMine), findsOneWidget);
    expect(find.text('Đã thu hồi tin nhắn.'), findsOneWidget);
  });

  testWidgets('nhấn giữ tin nhận được: Báo cáo chọn lý do rồi gửi', (tester) async {
    await pumpChat(tester);
    await longPress(tester, 'Chào em, chị đây. Em hỏi đi.');
    expect(find.text('Sửa'), findsNothing);
    await tester.tap(find.text('Báo cáo'));
    await tester.pumpAndSettle();
    expect(find.text('Báo cáo tin nhắn'), findsOneWidget);
    await tester.tap(find.text('Spam'));
    await tester.pump();
    await tester.tap(find.text('Gửi báo cáo'));
    await tester.pumpAndSettle();
    expect(dao.reports.single.messageId, 5);
    expect(dao.reports.single.reasonId, 4);
    expect(find.text('Cảm ơn bạn. Báo cáo đã được gửi.'), findsOneWidget);
  });

  testWidgets('menu Chặn hỏi xác nhận; đã chặn thì có Bỏ chặn', (tester) async {
    await pumpChat(tester);
    await tester.tap(find.byTooltip('Tùy chọn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chặn'));
    await tester.pumpAndSettle();
    expect(find.text('Chặn Lan Anh?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Chặn'));
    await tester.pumpAndSettle();
    expect(dao.calls, contains('block 6'));
    expect(find.text('Đã chặn. Hai bạn không nhắn tin được cho nhau nữa.'), findsOneWidget);
    expect(find.text('Bạn đã chặn Lan Anh. Bỏ chặn để nhắn tin tiếp.'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Bỏ chặn'));
    await tester.pumpAndSettle();
    expect(dao.calls, contains('unblock 6'));
    expect(find.text('Bạn đã chặn Lan Anh. Bỏ chặn để nhắn tin tiếp.'), findsNothing);
  });

  testWidgets('sự kiện typing hiện "đang soạn tin…" rồi tự tắt; tin mới đến thì hiện ngay', (tester) async {
    final chat = await pumpChat(tester);
    final live = StreamController<LiveEvent>.broadcast();
    addTearDown(live.close);
    chat.attachLive(live.stream);

    live.add(const LiveEvent(LiveEvent.chat, {'kind': 'typing', 'conversationId': 1}));
    await tester.pump();
    await tester.pump();
    expect(find.text('Lan Anh đang soạn tin…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Lan Anh đang soạn tin…'), findsNothing);

    dao.rooms[1] = acceptedRoom();
    dao.nextUpdates = null;
    live.add(const LiveEvent(LiveEvent.chat, {'kind': 'message', 'conversationId': 1, 'messageId': 9}));
    await tester.pumpAndSettle();
    expect(dao.calls, contains('findUpdates 1 5 2026-11-07T18:54:00Z'));
  });

  testWidgets('hai ChatScreen chồng nhau: màn trên hiện đúng cuộc trò chuyện, quay về thì màn dưới tải lại của nó', (
    tester,
  ) async {
    await pumpChat(tester);
    expect(find.text('Chào em, chị đây. Em hỏi đi.'), findsOneWidget);

    final context = tester.element(find.byType(ChatScreen));
    unawaited(Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ChatScreen(conversationId: 2))));
    await tester.pumpAndSettle();
    expect(find.text('Xin chao, tin nhan thu 3 cua nguoi la.'), findsOneWidget);
    expect(find.text('Chào em, chị đây. Em hỏi đi.'), findsNothing);

    dao.calls.clear();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(dao.calls, contains('findById 1'));
    expect(find.text('Chào em, chị đây. Em hỏi đi.'), findsOneWidget);
    expect(find.text('Xin chao, tin nhan thu 3 cua nguoi la.'), findsNothing);
  });

  testWidgets('màn hẹp 360 dp: tin dài không tràn', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    dao.rooms[1] = acceptedRoom().copyWith(messages: [chatMessage(5, 'Rất dài ' * 80)]);
    await pumpChat(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(ChatBubble), findsOneWidget);
  });
}
