// Widget test của ConversationListScreen: hai hộp "Tin nhắn" / "Lời mời", trạng thái chờ / lỗi / rỗng, mở cuộc trò
// chuyện, người đã chặn, cập nhật khi có sự kiện chat.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/chat_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/chat_blocked_member.dart';
import 'package:myasvsj/com.myasvsj.model/chat_counts.dart';
import 'package:myasvsj/com.myasvsj.model/chat_message.dart';
import 'package:myasvsj/com.myasvsj.model/conversation_item.dart';
import 'package:myasvsj/com.myasvsj.model/live_event.dart';
import 'package:myasvsj/com.myasvsj.screen/chat_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/conversation_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/conversation_tile.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';

import 'chat_fakes.dart';
import 'notification_test_app.dart';

void main() {
  late FakeChatDao dao;

  setUp(() => dao = FakeChatDao());

  Future<ChatController> pumpSignedIn(WidgetTester tester) async {
    final chat = ChatController(dao);
    await tester.pumpWidget(
      notifyChatApp(home: const ConversationListScreen(), auth: await signedInAuth(), chat: chat),
    );
    await tester.pumpAndSettle();
    return chat;
  }

  testWidgets('khách thấy lời mời đăng nhập; bấm Đăng nhập thì sang màn Đăng nhập', (tester) async {
    await tester.pumpWidget(notifyChatApp(home: const ConversationListScreen(), chat: ChatController(dao)));
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập để nhắn tin với thành viên khác.'), findsOneWidget);
    expect(dao.calls, isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('hộp Tin nhắn: tên, tin cuối, số chưa đọc; tab Lời mời có số lời mời', (tester) async {
    await pumpSignedIn(tester);
    expect(dao.calls, containsAll(['findAll INBOX 0', 'findAll REQUESTS 0']));

    expect(find.byType(ConversationTile), findsOneWidget);
    expect(find.text('Lan Anh'), findsOneWidget);
    expect(find.text('Chào em, chị đây. Em hỏi đi.'), findsOneWidget);
    expect(find.descendant(of: find.byType(ConversationTile), matching: find.text('1')), findsOneWidget);
    expect(find.descendant(of: find.byType(Tab), matching: find.text('1')), findsOneWidget);

    await tester.tap(find.text('Lời mời'));
    await tester.pumpAndSettle();
    expect(find.text('Chat Stranger'), findsOneWidget);
    expect(find.text('Xin chao, tin nhan thu 3 cua nguoi la.'), findsOneWidget);
  });

  testWidgets('tin cuối của mình có "Bạn: ", tin đã thu hồi, người đã chặn', (tester) async {
    dao.inbox = [
      ConversationItem(id: 1, peer: lanAnh, lastMessage: chatMessage(6, 'Dạ em cảm ơn', mine: true)),
      ConversationItem(
        id: 3,
        peer: stranger,
        blockedByMe: true,
        lastMessage: ChatMessage(id: 8, mine: false, recalled: true, createdAt: DateTime.now()),
      ),
    ];
    await pumpSignedIn(tester);
    expect(find.text('Bạn: Dạ em cảm ơn'), findsOneWidget);
    expect(find.text('Tin nhắn đã được thu hồi'), findsOneWidget);
    expect(find.text('Đã chặn'), findsOneWidget);
  });

  testWidgets('hộp trống: câu của trang web (nhắc lời mời đang chờ)', (tester) async {
    dao.inbox = [];
    await pumpSignedIn(tester);
    expect(find.textContaining('Bạn có 1 lời mời nhắn tin đang chờ'), findsOneWidget);

    dao.requests = [];
    dao.counts = const ChatCounts();
    await tester.tap(find.text('Lời mời'));
    await tester.pumpAndSettle();
    await tester.fling(find.byType(ListView).last, const Offset(0, 300), 1000);
    await tester.pumpAndSettle();
    expect(find.textContaining('Không có lời mời nhắn tin nào.'), findsOneWidget);
  });

  testWidgets('đang tải hiện vòng quay; lỗi hiện câu của server và Thử lại', (tester) async {
    dao.hold = Completer<void>();
    final chat = ChatController(dao);
    await tester.pumpWidget(
      notifyChatApp(home: const ConversationListScreen(), auth: await signedInAuth(), chat: chat),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    dao.failWith = const ApiException('Bạn cần đăng nhập để nhắn tin.', statusCode: 401);
    dao.hold!.complete();
    dao.hold = null;
    await tester.pumpAndSettle();
    expect(find.text('Bạn cần đăng nhập để nhắn tin.'), findsOneWidget);

    dao.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Lan Anh'), findsOneWidget);
  });

  testWidgets('bấm một cuộc trò chuyện mở ChatScreen; quay về thì tải lại danh sách', (tester) async {
    await pumpSignedIn(tester);
    dao.calls.clear();
    await tester.tap(find.text('Lan Anh'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.text('Chào em, chị đây. Em hỏi đi.'), findsOneWidget);
    expect(dao.calls, contains('findById 1'));

    dao.calls.clear();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(dao.calls, contains('findAll INBOX 0'));
  });

  testWidgets('Người đã chặn: danh sách và Bỏ chặn', (tester) async {
    dao.blocks = [const ChatBlockedMember(peer: stranger)];
    await pumpSignedIn(tester);
    await tester.tap(find.byTooltip('Người đã chặn'));
    await tester.pumpAndSettle();
    expect(find.text('Chat Stranger'), findsOneWidget);

    await tester.tap(find.text('Bỏ chặn'));
    await tester.pumpAndSettle();
    expect(dao.calls, contains('unblock 9'));
    expect(find.text('Đã bỏ chặn.'), findsOneWidget);
    expect(find.text('Bạn chưa chặn ai.'), findsOneWidget);
  });

  testWidgets('có tin mới (sự kiện chat): danh sách tự cập nhật', (tester) async {
    final chat = await pumpSignedIn(tester);
    final live = StreamController<LiveEvent>.broadcast();
    addTearDown(live.close);
    chat.attachLive(live.stream);

    dao.inbox = [ConversationItem(id: 1, peer: lanAnh, lastMessage: chatMessage(9, 'Em ở quận nào?'), unread: 2)];
    live.add(const LiveEvent(LiveEvent.chat, {'kind': 'message', 'conversationId': 1, 'messageId': 9}));
    await tester.pumpAndSettle();
    expect(find.text('Em ở quận nào?'), findsOneWidget);
    expect(find.descendant(of: find.byType(ConversationTile), matching: find.text('2')), findsOneWidget);
  });
}
