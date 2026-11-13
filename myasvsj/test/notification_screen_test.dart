// Widget test của NotificationScreen: Controller dùng DAO giả, kiểm tra màn hình vẽ đúng và chuyển đúng thao tác.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/app_notification.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/notification_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/notification_tile.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

import 'notification_fakes.dart';
import 'notification_test_app.dart';

void main() {
  late FakeNotificationDao dao;
  late List<String?> opened;

  Future<bool> recordOpen(BuildContext _, String? link) async {
    opened.add(link);
    return true;
  }

  setUp(() {
    dao = FakeNotificationDao();
    opened = [];
  });

  Future<void> pumpSignedIn(WidgetTester tester) async {
    final auth = await signedInAuth();
    await tester.pumpWidget(
      notifyChatApp(
        home: NotificationScreen(linkOpener: recordOpen),
        auth: auth,
        notifications: NotificationController(dao),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('khách thấy lời mời đăng nhập; bấm Đăng nhập thì sang màn Đăng nhập', (tester) async {
    await tester.pumpWidget(
      notifyChatApp(home: const NotificationScreen(), notifications: NotificationController(dao)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập để xem thông báo của bạn.'), findsOneWidget);
    expect(dao.pagesAsked, isEmpty, reason: 'khách không gọi API');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('hiện thông báo, chưa đọc in đậm, dòng tóm tắt số chưa đọc', (tester) async {
    await pumpSignedIn(tester);

    expect(find.byType(NotificationTile), findsNWidgets(3));
    expect(find.text('2 thông báo chưa đọc.'), findsOneWidget);
    // Chưa đọc: chữ đậm Label/M (SemiBold) như thiết kế; đã đọc: Body/S thường
    final unread = tester.widget<Text>(find.textContaining('Trần Minh đã bình luận'));
    expect(unread.style?.fontWeight, SenpaiText.labelM.fontWeight);
    final read = tester.widget<Text>(find.textContaining('Ghim “Tiệm giặt Sora”'));
    expect(read.style?.fontWeight, isNot(SenpaiText.labelM.fontWeight));
    expect(find.byIcon(Icons.circle), findsNWidgets(2), reason: 'chấm chưa đọc');
  });

  testWidgets('đang tải hiện vòng quay', (tester) async {
    dao.hold = Completer<void>();
    await pumpSignedInWithoutSettle(tester, dao);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    dao.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(NotificationTile), findsNWidgets(3));
  });

  testWidgets('lỗi server hiện câu thông báo và nút Thử lại', (tester) async {
    dao.failWith = const ApiException('Không kết nối được tới server.');
    await pumpSignedIn(tester);
    expect(find.text('Không kết nối được tới server.'), findsOneWidget);

    dao.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationTile), findsNWidgets(3));
  });

  testWidgets('chưa có thông báo', (tester) async {
    dao.stored = [];
    await pumpSignedIn(tester);
    expect(find.text('Chưa có thông báo.'), findsWidgets);
    expect(find.byType(NotificationTile), findsNothing);
  });

  testWidgets('bấm thông báo bình luận: đánh dấu đã đọc rồi mở bài viết', (tester) async {
    await pumpSignedIn(tester);
    await tester.tap(find.textContaining('Trần Minh đã bình luận'));
    await tester.pumpAndSettle();

    expect(dao.markedUpTo, [5]);
    expect(opened, ['/blog/1']);
    expect(find.text('Bạn đã xem hết thông báo.'), findsOneWidget);
  });

  testWidgets('bấm thông báo tag mở trang Tôi; thông báo địa điểm không có link thì chỉ hiện nội dung', (tester) async {
    await pumpSignedIn(tester);
    await tester.tap(find.text('Bạn đã được cấp tag Mentor.'));
    await tester.pumpAndSettle();
    expect(opened, ['/profile']);
    expect(dao.markedUpTo, [4]);

    await tester.tap(find.textContaining('Ghim “Tiệm giặt Sora”'));
    await tester.pumpAndSettle();
    expect(opened, ['/profile'], reason: 'không có trang để mở');
    expect(dao.markedUpTo, [4], reason: 'đã đọc rồi thì không gọi server');
  });

  testWidgets('Đánh dấu tất cả đã đọc', (tester) async {
    await pumpSignedIn(tester);
    await tester.tap(find.byTooltip('Đánh dấu tất cả đã đọc'));
    await tester.pumpAndSettle();
    expect(dao.markedUpTo, [null]);
    expect(find.text('Bạn đã xem hết thông báo.'), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsNothing);
    final button = tester.widget<IconButton>(find.widgetWithIcon(IconButton, Symbols.done_all_rounded));
    expect(button.onPressed, isNull);
  });

  testWidgets('đánh dấu đã đọc lỗi: hoàn tác và hiện câu báo lỗi', (tester) async {
    dao.failMarkWith = const ApiException('Server gặp lỗi (500). Hãy thử lại sau.');
    await pumpSignedIn(tester);
    await tester.tap(find.byTooltip('Đánh dấu tất cả đã đọc'));
    await tester.pumpAndSettle();
    expect(find.text('Server gặp lỗi (500). Hãy thử lại sau.'), findsOneWidget);
    expect(find.text('2 thông báo chưa đọc.'), findsOneWidget);
  });

  testWidgets('Xem thêm tải trang sau', (tester) async {
    dao.olderPage = [
      const AppNotification(
        id: 1,
        type: 'BEST_ANSWER',
        content: 'Câu trả lời của bạn được chọn là hay nhất.',
        read: true,
      ),
    ];
    await pumpSignedIn(tester);
    await tester.scrollUntilVisible(find.text('Xem thêm'), 100);
    await tester.tap(find.text('Xem thêm'));
    await tester.pumpAndSettle();
    expect(dao.pagesAsked, [0, 1]);
    expect(find.text('Câu trả lời của bạn được chọn là hay nhất.'), findsOneWidget);
    expect(find.text('Xem thêm'), findsNothing);
  });

  testWidgets('màn hẹp 360 dp: nội dung dài không tràn', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    dao.stored = [
      AppNotification(
        id: 9,
        type: 'CONTENT_REJECTED',
        content: 'Bài viết “${'Rất dài ' * 30}” chưa được đăng vì ảnh không qua kiểm duyệt.',
        createdAt: DateTime.now(),
      ),
    ];
    await pumpSignedIn(tester);
    expect(tester.takeException(), isNull);
    expect(find.byType(NotificationTile), findsOneWidget);
  });
}

/// Đã đăng nhập nhưng chưa chờ tải xong (để thấy trạng thái chờ).
Future<void> pumpSignedInWithoutSettle(WidgetTester tester, FakeNotificationDao dao) async {
  final auth = await signedInAuth();
  await tester.pumpWidget(
    notifyChatApp(home: const NotificationScreen(), auth: auth, notifications: NotificationController(dao)),
  );
  await tester.pump();
  await tester.pump();
}
