// Unit test ChatController: DAO giả, luồng tức thì giả, thông báo trên máy giả; không cần server.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/chat_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/chat_blocked_member.dart';
import 'package:myasvsj/com.myasvsj.model/chat_counts.dart';
import 'package:myasvsj/com.myasvsj.model/chat_message.dart';
import 'package:myasvsj/com.myasvsj.model/chat_status.dart';
import 'package:myasvsj/com.myasvsj.model/chat_updates.dart';
import 'package:myasvsj/com.myasvsj.model/live_event.dart';
import 'package:myasvsj/com.myasvsj.model/user.dart';

import 'chat_fakes.dart';
import 'notification_fakes.dart';

const _me = User(id: 2, email: 'user@gmail.com', displayName: 'Trần Minh', role: 'USER');

Future<void> _settle([int ms = 5]) => Future<void>.delayed(Duration(milliseconds: ms));

LiveEvent _chat(String kind, int conversationId, [int? messageId]) =>
    LiveEvent(LiveEvent.chat, {'kind': kind, 'conversationId': conversationId, 'messageId': ?messageId});

void main() {
  late FakeChatDao dao;
  late ChatController chat;
  final owner = Object();

  setUp(() {
    dao = FakeChatDao();
    chat = ChatController(dao);
  });

  group('danh sách', () {
    test('loadConversations: trạng thái chờ, rồi cuộc trò chuyện và các con số', () async {
      dao.hold = Completer<void>();
      final future = chat.loadConversations(ChatController.inbox);
      expect(chat.isLoadingOf(ChatController.inbox), isTrue);
      dao.hold!.complete();
      dao.hold = null;
      await future;
      expect(chat.isLoadingOf(ChatController.inbox), isFalse);
      expect(chat.conversationsOf(ChatController.inbox).single.peer.displayName, 'Lan Anh');
      expect(chat.counts.requests, 1);
      expect(dao.calls, ['findAll INBOX 0']);

      await chat.loadConversations(ChatController.requests);
      expect(chat.conversationsOf(ChatController.requests).single.state, 'REQUEST');
    });

    test('loadConversations giữ câu báo lỗi của server theo từng hộp', () async {
      dao.failWith = const ApiException('Bạn không có quyền thực hiện thao tác này.', statusCode: 403);
      await chat.loadConversations(ChatController.requests);
      expect(chat.errorOf(ChatController.requests), 'Bạn không có quyền thực hiện thao tác này.');
      expect(chat.errorOf(ChatController.inbox), isNull);
    });

    test('sự kiện chat làm mới lặng lẽ các hộp đã tải (không làm mới khi chỉ là "đang soạn tin")', () async {
      final live = StreamController<LiveEvent>.broadcast();
      chat.attachLive(live.stream);
      await chat.loadConversations(ChatController.inbox);
      dao.calls.clear();

      live.add(_chat('typing', 1));
      await _settle();
      expect(dao.calls, isEmpty);

      live.add(_chat('message', 1, 7));
      await _settle();
      expect(dao.calls, contains('findAll INBOX 0'));
      expect(dao.calls, isNot(contains('findAll REQUESTS 0')), reason: 'hộp chưa mở thì không tải');
      await live.close();
    });

    test('đăng xuất xóa danh sách và các con số', () async {
      chat.onSignedInChanged(_me);
      await chat.loadConversations(ChatController.inbox);
      chat.onSignedInChanged(null);
      expect(chat.conversationsOf(ChatController.inbox), isEmpty);
      expect(chat.counts.requests, 0);
    });
  });

  group('mở cuộc trò chuyện', () {
    test('openRoom tải tin nhắn và đánh dấu đã đọc tới tin mới nhất của người kia', () async {
      dao.hold = Completer<void>();
      final future = chat.openRoom(conversationId: 1, owner: owner);
      expect(chat.isLoadingRoom, isTrue);
      dao.hold!.complete();
      dao.hold = null;
      await future;
      await _settle();
      expect(chat.isLoadingRoom, isFalse);
      expect(chat.room!.peer.displayName, 'Lan Anh');
      expect(chat.room!.messages.map((m) => m.id), [1, 5]);
      expect(dao.reads.single, (conversationId: 1, upToId: 5));
    });

    test('openRoom lỗi: giữ câu của server', () async {
      await chat.openRoom(conversationId: 999, owner: owner);
      expect(chat.room, isNull);
      expect(chat.roomError, 'Không tìm thấy cuộc trò chuyện này.');
    });

    test('lưới an toàn: cuộc trò chuyện đang mở tự hỏi /updates định kỳ, đóng thì thôi', () async {
      chat = ChatController(dao, pollEvery: const Duration(milliseconds: 40));
      await chat.openRoom(conversationId: 1, owner: owner);
      await _settle(110);
      final polls = dao.calls.where((c) => c.startsWith('findUpdates 1')).length;
      expect(polls, greaterThanOrEqualTo(1));
      chat.closeRoom(owner);
      await _settle(100);
      expect(dao.calls.where((c) => c.startsWith('findUpdates 1')).length, polls);
      chat.dispose();
    });

    test('closeRoom chỉ có tác dụng với màn hình đã mở cuộc trò chuyện', () async {
      await chat.openRoom(conversationId: 1, owner: owner);
      chat.closeRoom(Object());
      expect(chat.room, isNotNull);
      chat.closeRoom(owner);
      expect(chat.room, isNull);
    });

    test('loadOlder thêm tin cũ vào đầu', () async {
      dao.rooms[1] = acceptedRoom().copyWith(hasOlder: true);
      dao.older = [chatMessage(0, 'Tin cũ nhất', minutesAgo: 60)];
      await chat.openRoom(conversationId: 1, owner: owner);
      await chat.loadOlder();
      expect(dao.calls, contains('findOlder 1 1'));
      expect(chat.room!.messages.map((m) => m.id), [0, 1, 5]);
      expect(chat.room!.hasOlder, isFalse);
    });

    test('deliveryOf: "Đã xem" / "Đã gửi" chỉ dưới tin mới nhất của mình khi chưa có tin trả lời sau nó', () async {
      dao.rooms[1] = acceptedRoom().copyWith(
        messages: [...acceptedRoom().messages, chatMessage(6, 'Dạ em cảm ơn chị', mine: true)],
      );
      await chat.openRoom(conversationId: 1, owner: owner);
      final messages = chat.room!.messages;
      expect(chat.deliveryOf(messages.first), isNull);
      expect(chat.deliveryOf(messages.last), 'Đã gửi');

      dao.rooms[1] = dao.rooms[1]!.copyWith(
        status: const ChatStatus(state: 'ACCEPTED', canSend: true, canReact: true, peerReadUpTo: 6),
      );
      await chat.openRoom(conversationId: 1, owner: owner);
      expect(chat.deliveryOf(chat.room!.messages.last), 'Đã xem');
    });
  });

  group('gửi tin', () {
    test('không gọi server khi tin trống hoặc quá 2.000 ký tự', () async {
      await chat.openRoom(conversationId: 1, owner: owner);
      dao.calls.clear();
      expect(await chat.sendMessage('   '), isFalse);
      expect(chat.sendError, 'Hãy nhập tin nhắn.');
      expect(await chat.sendMessage('a' * 2001), isFalse);
      expect(chat.sendError, 'Tin nhắn tối đa 2000 ký tự.');
      expect(dao.calls, isEmpty);
    });

    test('gửi vào cuộc trò chuyện đã có: tin mới nằm cuối', () async {
      await chat.openRoom(conversationId: 1, owner: owner);
      expect(await chat.sendMessage('  Dạ em cảm ơn chị  '), isTrue);
      expect(dao.calls, contains('send 1 Dạ em cảm ơn chị'));
      expect(chat.room!.messages.last.content, 'Dạ em cảm ơn chị');
      expect(chat.room!.messages.last.mine, isTrue);
      expect(chat.isSending, isFalse);
      expect(chat.sendError, isNull);
    });

    test('tin đầu tiên cho một thành viên tạo cuộc trò chuyện (thành lời mời)', () async {
      await chat.openRoom(withUserId: 7, owner: owner);
      expect(chat.room!.id, isNull);
      expect(chat.room!.status.noticeCode, 'NEW');

      expect(await chat.sendMessage('Chào bạn'), isTrue);
      expect(dao.calls, contains('sendTo 7 Chào bạn'));
      expect(chat.room!.id, 50);
      expect(chat.room!.status.noticeCode, 'WAITING');
      expect(chat.room!.messages.single.content, 'Chào bạn');
    });

    test('server từ chối: giữ câu báo lỗi, không thêm tin', () async {
      dao.failSendWith = const ApiException('Chưa gửi được: tin nhắn chứa từ khóa không được phép “x”.');
      await chat.openRoom(conversationId: 1, owner: owner);
      expect(await chat.sendMessage('x'), isFalse);
      expect(chat.sendError, startsWith('Chưa gửi được'));
      expect(chat.room!.messages, hasLength(2));
      expect(chat.isSending, isFalse);
    });

    test('hội thoại đã mã hóa đầu cuối mà app chưa mở khóa: không gửi gì, báo nhập mật khẩu khôi phục', () async {
      dao.rooms[1] = acceptedRoom().copyWith(
        status: const ChatStatus(state: 'ACCEPTED', canSend: true, canReact: true, isEncrypted: true),
      );
      await chat.openRoom(conversationId: 1, owner: owner);
      dao.calls.clear();
      expect(await chat.sendMessage('Xin chào'), isFalse);
      expect(chat.sendError, ChatController.lockedNotice);
      expect(dao.calls, isEmpty);
    });

    test('onComposing báo "đang soạn tin" nhiều nhất mỗi 3 giây, chỉ khi hai người đã nhận lời', () async {
      await chat.openRoom(conversationId: 1, owner: owner);
      final start = DateTime(2026, 11, 8, 9);
      chat.onComposing(now: start);
      chat.onComposing(now: start.add(const Duration(seconds: 1)));
      chat.onComposing(now: start.add(const Duration(seconds: 4)));
      await _settle();
      expect(dao.calls.where((c) => c == 'typing 1'), hasLength(2));

      await chat.openRoom(conversationId: 2, owner: owner);
      chat.onComposing(now: start.add(const Duration(seconds: 10)));
      await _settle();
      expect(dao.calls.where((c) => c == 'typing 2'), isEmpty, reason: 'lời mời chưa nhận: không báo');
    });
  });

  group('sửa, thu hồi, báo cáo', () {
    test('canEdit / canRecall / canReport theo luật của server', () async {
      dao.rooms[1] = acceptedRoom().copyWith(
        messages: [
          chatMessage(1, 'Tin cũ của mình', mine: true, minutesAgo: 20),
          chatMessage(5, 'Tin của Lan Anh', minutesAgo: 10),
          chatMessage(6, 'Tin mới của mình', mine: true, minutesAgo: 2),
          ChatMessage(id: 7, mine: false, isEncrypted: true, createdAt: DateTime.now()),
          ChatMessage(id: 8, mine: true, recalled: true, createdAt: DateTime.now()),
        ],
      );
      await chat.openRoom(conversationId: 1, owner: owner);
      final m = {for (final x in chat.room!.messages) x.id: x};

      expect(chat.canEdit(m[6]!), isTrue);
      expect(chat.canEdit(m[1]!), isFalse, reason: 'quá 15 phút');
      expect(chat.canEdit(m[5]!), isFalse, reason: 'tin của người khác');
      expect(chat.canEdit(m[8]!), isFalse, reason: 'đã thu hồi');
      expect(chat.canRecall(m[1]!), isTrue, reason: 'thu hồi lúc nào cũng được');
      expect(chat.canRecall(m[8]!), isFalse);
      expect(chat.canReport(m[5]!), isTrue);
      expect(chat.canReport(m[6]!), isFalse);
      expect(chat.canReport(m[7]!), isFalse, reason: 'tin mã hóa: app không có nội dung để báo cáo');
    });

    test('cuộc trò chuyện bị cắt (đã chặn) thì không sửa được', () async {
      dao.rooms[1] = acceptedRoom().copyWith(
        status: const ChatStatus(state: 'ACCEPTED', blockedByMe: true, noticeCode: 'BLOCKED_BY_ME'),
        messages: [chatMessage(6, 'Tin mới của mình', mine: true)],
      );
      await chat.openRoom(conversationId: 1, owner: owner);
      expect(chat.canEdit(chat.room!.messages.single), isFalse);
    });

    test('sửa: startEdit rồi sendMessage gửi PUT và thay tin cũ', () async {
      await chat.openRoom(conversationId: 1, owner: owner);
      final mine = chat.room!.messages.first;
      chat.startEdit(mine);
      expect(chat.editing, mine);
      expect(await chat.sendMessage('Chào chị (đã sửa)'), isTrue);
      expect(dao.calls, contains('update 1 1 Chào chị (đã sửa)'));
      expect(chat.editing, isNull);
      expect(chat.room!.messages.first.content, 'Chào chị (đã sửa)');
      expect(chat.room!.messages.first.edited, isTrue);
      expect(chat.room!.messages, hasLength(2));
    });

    test('sửa bị server từ chối (quá 5 lần): giữ chế độ sửa và câu báo lỗi', () async {
      dao.failSendWith = const ApiException('Mỗi tin nhắn chỉ sửa được tối đa 5 lần.');
      await chat.openRoom(conversationId: 1, owner: owner);
      chat.startEdit(chat.room!.messages.first);
      expect(await chat.sendMessage('Lần thứ 6'), isFalse);
      expect(chat.sendError, 'Mỗi tin nhắn chỉ sửa được tối đa 5 lần.');
      expect(chat.editing, isNotNull);
      chat.cancelEdit();
      expect(chat.editing, isNull);
      expect(chat.sendError, isNull);
    });

    test('thu hồi: tin thành "đã thu hồi" và có câu của server', () async {
      await chat.openRoom(conversationId: 1, owner: owner);
      expect(await chat.recallMessage(chat.room!.messages.first), isTrue);
      expect(chat.room!.messages.first.recalled, isTrue);
      expect(chat.takeMessage(), 'Đã thu hồi tin nhắn.');
    });

    test('báo cáo gửi lý do và ghi chú', () async {
      await chat.openRoom(conversationId: 1, owner: owner);
      final theirs = chat.room!.messages.last;
      expect(await chat.reportMessage(theirs, reasonId: 4, note: 'Quảng cáo'), isTrue);
      expect(dao.reports.single, (messageId: 5, reasonId: 4, note: 'Quảng cáo', block: false));
      expect(chat.takeMessage(), 'Cảm ơn bạn. Báo cáo đã được gửi.');
    });
  });

  group('lời mời, chặn, xóa', () {
    test('chấp nhận lời mời: câu của server, tải lại trạng thái', () async {
      await chat.openRoom(conversationId: 2, owner: owner);
      expect(chat.room!.status.isRequest, isTrue);
      expect(await chat.acceptRequest(), isTrue);
      expect(chat.takeMessage(), 'Đã chấp nhận lời mời nhắn tin.');
      expect(chat.room!.status.isRequest, isFalse);
      expect(chat.room!.status.canReact, isTrue);
    });

    test('từ chối và xóa trả về true cùng câu của server', () async {
      await chat.openRoom(conversationId: 2, owner: owner);
      expect(await chat.declineRequest(), isTrue);
      expect(chat.takeMessage(), 'Đã từ chối lời mời nhắn tin.');
      expect(await chat.deleteConversation(), isTrue);
      expect(chat.takeMessage(), 'Đã xóa cuộc trò chuyện.');
    });

    test('từ chối lỗi: trả về false và giữ câu báo lỗi', () async {
      await chat.openRoom(conversationId: 2, owner: owner);
      dao.failWith = const ApiException('Chỉ từ chối được lời mời nhắn tin chưa trả lời.');
      expect(await chat.declineRequest(), isFalse);
      expect(chat.takeMessage(), 'Chỉ từ chối được lời mời nhắn tin chưa trả lời.');
    });

    test('chặn rồi bỏ chặn người kia', () async {
      await chat.openRoom(conversationId: 1, owner: owner);
      expect(await chat.blockPeer(), isTrue);
      expect(chat.room!.status.blockedByMe, isTrue);
      expect(chat.room!.status.noticeCode, 'BLOCKED_BY_ME');
      expect(chat.takeMessage(), 'Đã chặn. Hai bạn không nhắn tin được cho nhau nữa.');
      expect(await chat.unblockPeer(), isTrue);
      expect(chat.room!.status.blockedByMe, isFalse);
      expect(chat.takeMessage(), 'Đã bỏ chặn.');
    });

    test('danh sách người đã chặn: tải và bỏ chặn', () async {
      dao.blocks = [const ChatBlockedMember(peer: stranger)];
      await chat.loadBlocks();
      expect(chat.blocked.single.peer.displayName, 'Chat Stranger');
      expect(await chat.unblock(chat.blocked.single), isTrue);
      expect(chat.blocked, isEmpty);
      expect(dao.calls, contains('unblock 9'));
    });
  });

  group('luồng tức thì', () {
    late StreamController<LiveEvent> live;
    late FakeNotificationDevice device;

    setUp(() {
      live = StreamController<LiveEvent>.broadcast();
      device = FakeNotificationDevice();
      chat = ChatController(dao, device: device, typingShow: const Duration(milliseconds: 60));
      chat.attachLive(live.stream);
    });

    tearDown(() => live.close());

    test('tin mới ở cuộc trò chuyện đang mở: hỏi /updates sau tin mới nhất và đánh dấu đã đọc', () async {
      await chat.openRoom(conversationId: 1, owner: owner);
      await _settle();
      dao.nextUpdates = ChatUpdates(
        messages: [chatMessage(9, 'Em ở quận nào?', minutesAgo: 0)],
        changed: [chatMessage(1, 'Chào chị (đã sửa)', mine: true, edited: true)],
        status: acceptedStatus,
        serverTime: '2026-11-07T18:56:00Z',
      );
      live.add(_chat('message', 1, 9));
      await _settle();

      expect(dao.calls, contains('findUpdates 1 5 2026-11-07T18:54:00Z'));
      expect(chat.room!.messages.map((m) => m.id), [1, 5, 9]);
      expect(chat.room!.messages.first.content, 'Chào chị (đã sửa)');
      expect(chat.room!.serverTime, '2026-11-07T18:56:00Z');
      expect(dao.reads.last, (conversationId: 1, upToId: 9));
      expect(device.shown, isEmpty, reason: 'đang đọc cuộc trò chuyện này');
    });

    test('"đang soạn tin" hiện khi có sự kiện typing rồi tự tắt', () async {
      await chat.openRoom(conversationId: 1, owner: owner);
      live.add(_chat('typing', 1));
      await _settle();
      expect(chat.peerTyping, isTrue);
      expect(dao.calls.where((c) => c.startsWith('findUpdates')), isEmpty, reason: 'không cần hỏi server');
      await _settle(120);
      expect(chat.peerTyping, isFalse);
    });

    test('tin mới ở cuộc trò chuyện khác: hiện "Tin nhắn mới từ …" trên máy, mỗi tin một lần', () async {
      chat.onSignedInChanged(_me);
      await _settle();
      // Mốc lúc đăng nhập là tin 4: không báo lại
      live.add(_chat('message', 2, 4));
      await _settle();
      expect(device.shown, isEmpty);

      dao.counts = const ChatCounts(
        unread: 1,
        latest: (conversationId: 1, messageId: 10, peerName: 'Lan Anh', request: false),
      );
      live.add(_chat('message', 1, 10));
      await _settle();
      expect(device.shown.single.title, 'Tin nhắn mới từ Lan Anh');
      expect(device.shown.single.link, '/messages/1');
      expect(device.shown.single.id, ChatController.deviceIdBase + 1);

      live.add(_chat('message', 1, 10));
      await _settle();
      expect(device.shown, hasLength(1));
    });

    test('lời mời mới: "… muốn nhắn tin với bạn"', () async {
      dao.counts = const ChatCounts(
        unread: 1,
        requests: 1,
        latest: (conversationId: 3, messageId: 12, peerName: 'Hoàng', request: true),
      );
      live.add(_chat('message', 3, 12));
      await _settle();
      expect(device.shown.single.title, 'Hoàng muốn nhắn tin với bạn');
    });

    test('luồng mở lại (ready): hỏi bù cuộc trò chuyện đang mở', () async {
      await chat.openRoom(conversationId: 1, owner: owner);
      dao.calls.clear();
      live.add(const LiveEvent(LiveEvent.ready));
      await _settle();
      expect(dao.calls.first, startsWith('findUpdates 1'));
    });

    test('attachLive với cùng luồng không nghe hai lần', () async {
      chat.attachLive(live.stream);
      await chat.openRoom(conversationId: 1, owner: owner);
      dao.calls.clear();
      live.add(_chat('status', 1));
      await _settle();
      expect(dao.calls.where((c) => c.startsWith('findUpdates')), hasLength(1));
    });
  });
}
