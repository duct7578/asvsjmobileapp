// Unit test NotificationController: DAO giả, luồng tức thì giả, thông báo trên máy giả; không cần server.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/app_notification.dart';
import 'package:myasvsj/com.myasvsj.model/live_event.dart';
import 'package:myasvsj/com.myasvsj.model/user.dart';

import 'live_fakes.dart';
import 'notification_fakes.dart';

const _user = User(id: 6, email: 'mentor@gmail.com', displayName: 'Lan Anh', role: 'USER');

/// Chờ các Future và Timer ngắn chạy xong.
Future<void> _settle([int ms = 5]) => Future<void>.delayed(Duration(milliseconds: ms));

AppNotification _newComment(int id) => AppNotification(
  id: id,
  type: 'NEW_COMMENT',
  content: 'Hoàng đã bình luận bài “Thuê nhà ở Tokyo” của bạn.',
  link: '/blog/3',
  createdAt: DateTime.now(),
);

void main() {
  late FakeNotificationDao dao;

  setUp(() => dao = FakeNotificationDao());

  group('danh sách', () {
    test('hàm tạo chỉ cần DAO và không gọi server', () {
      final controller = NotificationController(dao);
      expect(controller.unreadCount, 0);
      expect(dao.pagesAsked, isEmpty);
      expect(dao.summaryAfter, isEmpty);
      controller.dispose();
    });

    test('loadNotifications: trạng thái chờ, rồi thông báo và số chưa đọc', () async {
      final controller = NotificationController(dao);
      dao.hold = Completer<void>();
      final future = controller.loadNotifications();
      expect(controller.isLoading, isTrue);
      dao.hold!.complete();
      dao.hold = null;
      await future;
      expect(controller.isLoading, isFalse);
      expect(controller.items.map((n) => n.id), [5, 4, 3]);
      expect(controller.unreadCount, 2);
      expect(controller.hasMore, isFalse);
      expect(controller.error, isNull);
    });

    test('loadNotifications giữ câu báo lỗi của server', () async {
      dao.failWith = const ApiException('Không kết nối được tới server.');
      final controller = NotificationController(dao);
      await controller.loadNotifications();
      expect(controller.error, 'Không kết nối được tới server.');
      expect(controller.items, isEmpty);
      expect(controller.isLoading, isFalse);
    });

    test('loadMore nối trang sau, bỏ thông báo trùng, hết trang thì thôi', () async {
      dao = FakeNotificationDao(
        olderPage: [
          sampleNotifications().last, // trùng id 3
          AppNotification(id: 1, type: 'BEST_ANSWER', content: 'Câu trả lời của bạn được chọn.', link: '/qa/2'),
        ],
      );
      final controller = NotificationController(dao);
      await controller.loadNotifications();
      expect(controller.hasMore, isTrue);
      await controller.loadMore();
      expect(dao.pagesAsked, [0, 1]);
      expect(controller.items.map((n) => n.id), [5, 4, 3, 1]);
      expect(controller.hasMore, isFalse);
      await controller.loadMore();
      expect(dao.pagesAsked, [0, 1]);
    });
  });

  group('đã đọc', () {
    test('markRead đánh dấu ngay thông báo đó và các thông báo cũ hơn, rồi lấy số chưa đọc của server', () async {
      final controller = NotificationController(dao);
      await controller.loadNotifications();
      final tag = controller.items[1];

      final future = controller.markRead(tag);
      expect(controller.items.map((n) => n.read), [false, true, true]);
      expect(controller.unreadCount, 1);
      await future;
      expect(dao.markedUpTo, [4]);
      expect(controller.unreadCount, 1);
    });

    test('markRead hoàn tác khi server từ chối và giữ câu báo lỗi', () async {
      dao.failMarkWith = const ApiException('Server gặp lỗi (500). Hãy thử lại sau.');
      final controller = NotificationController(dao);
      await controller.loadNotifications();
      await controller.markRead(controller.items.first);
      expect(controller.items.map((n) => n.read), [false, false, true]);
      expect(controller.unreadCount, 2);
      expect(controller.takeMessage(), 'Server gặp lỗi (500). Hãy thử lại sau.');
      expect(controller.takeMessage(), isNull);
    });

    test('thông báo đã đọc thì không gọi server', () async {
      final controller = NotificationController(dao);
      await controller.loadNotifications();
      await controller.markRead(controller.items.last);
      expect(dao.markedUpTo, isEmpty);
    });

    test('markAllRead gửi upToId null và đưa số chưa đọc về 0', () async {
      final controller = NotificationController(dao);
      await controller.loadNotifications();
      await controller.markAllRead();
      expect(dao.markedUpTo, [null]);
      expect(controller.items.every((n) => n.read), isTrue);
      expect(controller.unreadCount, 0);
    });
  });

  group('luồng tức thì và thông báo trên máy', () {
    late FakeLiveDao live;
    late FakeNotificationDevice device;
    late NotificationController controller;

    setUp(() {
      live = FakeLiveDao();
      device = FakeNotificationDevice();
      controller = NotificationController(
        dao,
        live: live,
        device: device,
        retryFirst: const Duration(milliseconds: 10),
        retryMax: const Duration(milliseconds: 40),
        reopenDelay: const Duration(milliseconds: 5),
        silenceLimit: const Duration(seconds: 30),
      );
    });

    tearDown(() => controller.dispose());

    test('đăng nhập: xin quyền, lấy mốc summary (không hiện thông báo cũ), mở luồng', () async {
      controller.onSignedInChanged(_user);
      await _settle();
      expect(device.permissionRequests, 1);
      expect(dao.summaryAfter, [null]);
      expect(controller.unreadCount, 2);
      expect(device.shown, isEmpty);
      expect(live.opens, 1);
      expect(controller.isLiveConnected, isFalse);

      live.emit(const LiveEvent(LiveEvent.ready));
      await _settle();
      expect(controller.isLiveConnected, isTrue);
      // Mở luồng xong thì hỏi bù sau mốc
      expect(dao.summaryAfter, [null, 5]);
      expect(device.shown, isEmpty);
    });

    test(
      'sự kiện notification: hỏi summary, cập nhật số chưa đọc, hiện thông báo mới trên máy và đầu danh sách',
      () async {
        controller.onSignedInChanged(_user);
        await controller.loadNotifications();
        live.emit(const LiveEvent(LiveEvent.ready));
        await _settle();

        dao.arrive(_newComment(6));
        dao.arrive(_newComment(7));
        live.emit(const LiveEvent(LiveEvent.notification));
        await _settle();

        expect(dao.summaryAfter.last, 5);
        expect(controller.unreadCount, 4);
        expect(device.shown.map((n) => n.id), [6, 7]);
        expect(device.shown.first.title, 'Bình luận mới');
        expect(device.shown.first.body, contains('Hoàng đã bình luận'));
        expect(device.shown.first.link, '/blog/3');
        expect(controller.items.map((n) => n.id), [7, 6, 5, 4, 3]);

        // Hỏi lại không hiện trùng
        live.emit(const LiveEvent(LiveEvent.notification));
        await _settle();
        expect(device.shown, hasLength(2));
      },
    );

    test('thông báo tag không có link mở /profile; thông báo địa điểm không có link mở /notifications', () async {
      controller.onSignedInChanged(_user);
      await _settle();
      dao.arrive(const AppNotification(id: 8, type: 'TAG_EXPIRED', content: 'Yêu cầu tag Mentor đã quá hạn.'));
      dao.arrive(const AppNotification(id: 9, type: 'PLACE_CLOSED', content: 'Địa điểm “Sora” đã đóng cửa.'));
      live.emit(const LiveEvent(LiveEvent.notification));
      await _settle();
      expect(device.shown.map((n) => n.link), ['/profile', '/notifications']);
      expect(device.shown.map((n) => n.title), ['Tag định danh', 'Địa điểm']);
    });

    test('phát lại mọi sự kiện (trừ ping) ở liveEvents cho ChatController', () async {
      final seen = <String>[];
      final sub = controller.liveEvents.listen((e) => seen.add(e.type));
      controller.onSignedInChanged(_user);
      await _settle();
      live.emit(const LiveEvent(LiveEvent.ready));
      live.emit(const LiveEvent(LiveEvent.ping));
      live.emit(const LiveEvent(LiveEvent.chat, {'kind': 'message', 'conversationId': 1, 'messageId': 9}));
      await _settle();
      expect(seen, ['ready', 'chat']);
      await sub.cancel();
    });

    test('luồng kết thúc sau khi đã mở: mở lại sau reopenDelay', () async {
      controller.onSignedInChanged(_user);
      live.emit(const LiveEvent(LiveEvent.ready));
      await _settle();
      await live.closeCurrent();
      await _settle(1);
      expect(controller.isLiveConnected, isFalse);
      await _settle(60);
      expect(live.opens, 2);
      expect(live.isListened, isTrue);
    });

    test('không mở được: thử lại, chờ lâu dần (40 → 80 → 160 ms, tối đa retryMax)', () async {
      live.failNextOpens = 3;
      final retrying = NotificationController(
        dao,
        live: live,
        retryFirst: const Duration(milliseconds: 40),
        retryMax: const Duration(milliseconds: 160),
      );
      retrying.onSignedInChanged(_user);
      // Mở lúc 0 (lỗi), 40 (lỗi), 120 (lỗi), 280 (được)
      await _settle(20);
      expect(live.opens, 1);
      await _settle(50);
      expect(live.opens, 2);
      await _settle(30);
      expect(live.opens, 2, reason: 'lần chờ thứ hai dài gấp đôi');
      await _settle(50);
      expect(live.opens, 3);
      await _settle(180);
      expect(live.opens, 4);
      expect(live.isListened, isTrue);
      retrying.dispose();
    });

    test('im lặng quá silenceLimit (không cả ping): coi như rớt và mở lại', () async {
      final quiet = NotificationController(
        dao,
        live: live,
        reopenDelay: const Duration(milliseconds: 5),
        silenceLimit: const Duration(milliseconds: 100),
      );
      quiet.onSignedInChanged(_user);
      live.emit(const LiveEvent(LiveEvent.ready));
      await _settle(60);
      live.emit(const LiveEvent(LiveEvent.ping));
      await _settle(60);
      expect(live.opens, 1, reason: 'ping giữ kết nối');
      await _settle(150);
      expect(live.opens, 2);
      quiet.dispose();
    });

    test('đăng xuất: đóng luồng, không mở lại, xóa dữ liệu của người cũ', () async {
      controller.onSignedInChanged(_user);
      await controller.loadNotifications();
      live.emit(const LiveEvent(LiveEvent.ready));
      await _settle();

      controller.onSignedInChanged(null);
      await _settle(30);
      expect(live.isListened, isFalse);
      expect(live.opens, 1);
      expect(controller.unreadCount, 0);
      expect(controller.items, isEmpty);
      expect(controller.isLiveConnected, isFalse);
    });

    test('gọi lại với cùng người dùng thì không làm gì', () async {
      controller.onSignedInChanged(_user);
      await _settle();
      controller.onSignedInChanged(_user);
      await _settle();
      expect(live.opens, 1);
      expect(dao.summaryAfter, [null]);
    });

    test('bấm thông báo trên máy: takeOpenLink trả về đường dẫn đúng một lần', () async {
      device.launchLink = '/messages/1';
      var notified = 0;
      controller.addListener(() => notified++);
      controller.onSignedInChanged(_user);
      await _settle();
      expect(controller.takeOpenLink(), '/messages/1');

      device.tap('/blog/3');
      await _settle();
      expect(notified, greaterThan(0));
      expect(controller.takeOpenLink(), '/blog/3');
      expect(controller.takeOpenLink(), isNull);
    });

    test('mở lại app: hỏi summary một lần và mở lại luồng đã rớt', () async {
      live.failNextOpens = 1;
      final slow = NotificationController(dao, live: live, retryFirst: const Duration(seconds: 30));
      slow.onSignedInChanged(_user);
      await _settle();
      expect(live.opens, 1);

      slow.onAppResumed();
      await _settle();
      expect(dao.summaryAfter, [null, 5]);
      expect(live.opens, 2);
      expect(live.isListened, isTrue);
      slow.dispose();
    });

    test('summary lỗi thì giữ số cũ, không làm hỏng luồng', () async {
      controller.onSignedInChanged(_user);
      await _settle();
      dao.failWith = const ApiException('Server phản hồi quá lâu. Hãy thử lại.');
      live.emit(const LiveEvent(LiveEvent.notification));
      await _settle();
      expect(controller.unreadCount, 2);
      expect(live.isListened, isTrue);
    });
  });
}
