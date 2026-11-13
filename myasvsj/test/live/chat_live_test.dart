// Tin nhắn với server thật (user@gmail.com ↔ mentor@gmail.com): đọc mọi thứ, gửi tin rồi thấy sự kiện chat tới qua
// SSE thật, đã đọc, đang soạn tin, sửa, thu hồi, chặn / bỏ chặn, các lỗi của server; Controller hiện "Tin nhắn mới
// từ …" trên máy (giả). Tin thử được thu hồi sau khi chạy.
//
//   flutter test test/live/chat_live_test.dart --dart-define=LIVE_API=http://localhost:8080
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/chat_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/auth_dao.dart';
import 'package:myasvsj/com.myasvsj.model/chat_dao.dart';
import 'package:myasvsj/com.myasvsj.model/live_dao.dart';
import 'package:myasvsj/com.myasvsj.model/live_event.dart';
import 'package:myasvsj/com.myasvsj.model/notification_dao.dart';
import 'package:myasvsj/com.myasvsj.model/user.dart';

import '../notification_fakes.dart';
import 'live_api.dart';

Future<void> _until(bool Function() condition, {int seconds = 10, String reason = ''}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!condition()) {
    if (DateTime.now().isAfter(end)) {
      fail('Hết giờ chờ: $reason');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

String _now() => DateTime.now().toIso8601String().substring(11, 19);

/// Hai phiên đăng nhập thật.
Future<({ApiClient api, User user})> _signIn(String email) async {
  final api = ApiClient.inMemory(liveBaseUrl);
  final user = await AuthDao(api).login(email, '123456');
  return (api: api, user: user);
}

void main() {
  test('đọc: hộp thư, lời mời, các con số, người đã chặn, cuộc trò chuyện với mentor', () async {
    final me = await _signIn('user@gmail.com');
    final mentor = await _signIn('mentor@gmail.com');
    final dao = ChatDao(me.api);

    final inbox = await dao.findAll();
    final requests = await dao.findAll(box: ChatDao.requests);
    final counts = await dao.findCounts();
    final blocks = await dao.findBlocks();
    expect(requests.counts.requests, counts.requests);
    expect(blocks, isA<List<Object>>());

    final room = await dao.findWith(mentor.user.id);
    expect(room.peer.id, mentor.user.id);
    expect(room.peer.displayName, 'Lan Anh');
    expect(room.reportReasons, isNotEmpty);
    expect(room.messageMax, 2000);
    expect(room.serverTime, isNotNull);
    if (room.id == null) {
      return; // database mới: chưa từng nhắn (test ghi bên dưới sẽ tạo)
    }
    expect(inbox.items.map((c) => c.id), contains(room.id));
    final item = inbox.items.firstWhere((c) => c.id == room.id);
    expect(item.peer.displayName, 'Lan Anh');
    expect(item.state, 'ACCEPTED');

    final byId = await dao.findById(room.id!);
    expect(byId.messages.length, room.messages.length);
    final older = await dao.findOlder(room.id!, limit: 2);
    expect(older.messages.length, lessThanOrEqualTo(2));
    final updates = await dao.findUpdates(room.id!, changedSince: room.serverTime);
    expect(updates.serverTime, isNotNull);
  }, skip: liveSkip);

  test(
    'ghi + SSE thật: gửi, sự kiện chat, đã đọc, đang soạn tin, sửa, thu hồi, chặn / bỏ chặn, lỗi',
    () async {
      final me = await _signIn('user@gmail.com');
      final mentor = await _signIn('mentor@gmail.com');
      final mine = ChatDao(me.api);
      final theirs = ChatDao(mentor.api);

      final mentorEvents = <LiveEvent>[];
      final myEvents = <LiveEvent>[];
      final mentorSub = LiveDao(mentor.api).open().listen(mentorEvents.add);
      final mySub = LiveDao(me.api).open().listen(myEvents.add);
      int? sentId;
      int? conversationId;
      try {
        await _until(() => mentorEvents.any((e) => e.isReady) && myEvents.any((e) => e.isReady), reason: 'ready');

        final sent = await mine.sendTo(mentor.user.id, 'Chị ơi, em thử app nhắn tin lúc ${_now()} ạ.');
        sentId = sent.message.id;
        conversationId = sent.conversationId;
        expect(sent.message.mine, isTrue);
        expect(sent.message.content, startsWith('Chị ơi, em thử app'));

        await _until(
          () => mentorEvents.any((e) => e.isChat && e.kind == 'message' && e.messageId == sentId),
          reason: 'sự kiện chat message tới mentor',
        );
        expect(mentorEvents.lastWhere((e) => e.isChat).conversationId, conversationId);

        // Mentor: nhận lời (đã nhận rồi thì vẫn được), đọc, soạn tin
        expect(await theirs.accept(conversationId), 'Đã chấp nhận lời mời nhắn tin.');
        final room = await theirs.findById(conversationId);
        expect(room.messages.map((m) => m.id), contains(sentId));
        expect(room.messages.firstWhere((m) => m.id == sentId).mine, isFalse);
        final counts = await theirs.markRead(conversationId, upToId: sentId);
        expect(counts.unread, greaterThanOrEqualTo(0));
        await _until(() => myEvents.any((e) => e.isChat && e.kind == 'read'), reason: 'sự kiện read tới user');
        await theirs.typing(conversationId);
        await _until(() => myEvents.any((e) => e.isChat && e.kind == 'typing'), reason: 'sự kiện typing tới user');

        // User: sửa rồi thu hồi
        final edited = await mine.update(conversationId, sentId, 'Chị ơi, em thử app (đã sửa) lúc ${_now()} ạ.');
        expect(edited.message, 'Đã sửa tin nhắn.');
        expect(edited.chatMessage.edited, isTrue);
        await _until(
          () => mentorEvents.any((e) => e.isChat && e.kind == 'changed' && e.messageId == sentId),
          reason: 'sự kiện changed tới mentor',
        );
        final updates = await theirs.findUpdates(conversationId, after: sentId, changedSince: room.serverTime);
        expect(updates.changed.map((m) => m.id), contains(sentId));

        final recalled = await mine.recall(conversationId, sentId);
        expect(recalled.message, 'Đã thu hồi tin nhắn.');
        expect(recalled.chatMessage.recalled, isTrue);
        sentId = null;

        // Chặn: không gửi được; bỏ chặn: gửi lại được
        expect(await mine.block(mentor.user.id), 'Đã chặn. Hai bạn không nhắn tin được cho nhau nữa.');
        expect((await mine.findBlocks()).map((b) => b.peer.id), contains(mentor.user.id));
        final blockedRoom = await mine.findById(conversationId);
        expect(blockedRoom.status.blockedByMe, isTrue);
        expect(blockedRoom.status.noticeCode, 'BLOCKED_BY_ME');
        await expectLater(
          mine.send(conversationId, 'Không gửi được đâu'),
          throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('Bỏ chặn để nhắn tin tiếp'))),
        );
        expect(await mine.unblock(mentor.user.id), 'Đã bỏ chặn.');
        expect((await mine.findById(conversationId)).status.canSend, isTrue);

        // Các lỗi của server đi đúng đường dẫn
        await expectLater(
          mine.decline(conversationId),
          throwsA(
            isA<ApiException>().having((e) => e.message, 'message', 'Chỉ từ chối được lời mời nhắn tin chưa trả lời.'),
          ),
        );
        await expectLater(
          mine.delete(999999),
          throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
        );
        final lastTheirs = room.messages.where((m) => !m.mine).toList();
        await expectLater(
          theirs.report(lastTheirs.isEmpty ? recalled.chatMessage.id : lastTheirs.last.id, reasonId: 999999),
          throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', anyOf(400, 404))),
        );
      } finally {
        // Không chờ: kết nối SSE chỉ thật sự đóng khi server gửi dòng tiếp theo (ping 25 giây)
        unawaited(mentorSub.cancel());
        unawaited(mySub.cancel());
        if (sentId != null && conversationId != null) {
          await mine.recall(conversationId, sentId);
        }
      }
    },
    skip: liveSkip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'Controller với server thật: tin mới → "Tin nhắn mới từ Trần Minh" trên máy của mentor, cuộc trò chuyện đang '
    'mở tự cập nhật',
    () async {
      final me = await _signIn('user@gmail.com');
      final mentor = await _signIn('mentor@gmail.com');
      final mine = ChatDao(me.api);

      final device = FakeNotificationDevice();
      final notifications = NotificationController(NotificationDao(mentor.api), live: LiveDao(mentor.api));
      final chat = ChatController(ChatDao(mentor.api), device: device);
      chat.attachLive(notifications.liveEvents);
      notifications.onSignedInChanged(mentor.user);
      chat.onSignedInChanged(mentor.user);
      final sent = <({int conversationId, int messageId})>[];
      try {
        await _until(() => notifications.isLiveConnected, reason: 'luồng của mentor');
        await Future<void>.delayed(const Duration(milliseconds: 500)); // mốc tin chưa đọc lúc đăng nhập

        final first = await mine.sendTo(mentor.user.id, 'Chị ơi, tin thử thông báo lúc ${_now()} ạ.');
        sent.add((conversationId: first.conversationId, messageId: first.message.id));
        await _until(() => device.shown.isNotEmpty, reason: 'thông báo trên máy');
        expect(device.shown.last.title, 'Tin nhắn mới từ Trần Minh');
        expect(device.shown.last.link, '/messages/${first.conversationId}');

        // Mentor mở cuộc trò chuyện: tin tiếp theo hiện ngay, không báo trên máy
        final owner = Object();
        await chat.openRoom(conversationId: first.conversationId, owner: owner);
        expect(chat.room!.messages.map((m) => m.id), contains(first.message.id));
        final shownBefore = device.shown.length;
        final second = await mine.send(first.conversationId, 'Tin thứ hai lúc ${_now()} ạ.');
        sent.add((conversationId: second.conversationId, messageId: second.message.id));
        await _until(
          () => chat.room!.messages.any((m) => m.id == second.message.id),
          reason: 'tin thứ hai hiện trong cuộc trò chuyện đang mở',
        );
        expect(device.shown.length, shownBefore);
        chat.closeRoom(owner);
      } finally {
        notifications.dispose();
        chat.dispose();
        for (final s in sent) {
          await mine.recall(s.conversationId, s.messageId);
        }
      }
    },
    skip: liveSkip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
