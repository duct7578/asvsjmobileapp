// Widget test của ForYouScreen ("Dành cho bạn"): khách được mời đăng nhập; thành viên lọc theo lý do, tìm, tải thêm.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/home_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/feed_post_card.dart';
import 'package:myasvsj/com.myasvsj.screen/for_you_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/global_search_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';

import 'home_fakes.dart';

void main() {
  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(finder, 300, scrollable: vertical);

  HomeController controllerOf(WidgetTester tester) =>
      Provider.of<HomeController>(tester.element(find.byType(ForYouScreen)), listen: false);

  testWidgets('khách: lời mời đăng nhập, bấm thì ra màn Đăng nhập', (tester) async {
    final dao = FakeHomeDao();
    await tester.pumpWidget(homeTestApp(home: const ForYouScreen(), homeDao: dao));
    await tester.pumpAndSettle();

    expect(find.textContaining('Đăng nhập để xem những bài viết'), findsOneWidget);
    expect(dao.forYouCalls, isEmpty);
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('thành viên: tóm tắt, Dựa trên, nút phạm vi kèm số bài, bài có lý do', (tester) async {
    final dao = FakeHomeDao();
    await tester.pumpWidget(homeTestApp(home: const ForYouScreen(), homeDao: dao, signedIn: true));
    await tester.pumpAndSettle();

    expect(dao.forYouCalls.single, (scope: null, page: 0, q: ''));
    expect(find.textContaining('25 bài viết của các thành viên khác'), findsOneWidget);
    expect(find.text('Dựa trên'), findsOneWidget);
    expect(find.text('Tất cả · 25'), findsOneWidget);
    expect(find.text('Gần bạn · 12'), findsOneWidget);
    expect(find.text('Hợp giai đoạn · 13'), findsOneWidget);
    expect(find.text('Chủ đề quan tâm · 0'), findsOneWidget);
    expect(find.text('Bài số 1'), findsOneWidget);
    expect(find.textContaining('Hợp giai đoạn của bạn'), findsWidgets);
  });

  testWidgets('chọn phạm vi Gần bạn thì tải lại chỉ bài gần khu vực', (tester) async {
    final dao = FakeHomeDao();
    await tester.pumpWidget(homeTestApp(home: const ForYouScreen(), homeDao: dao, signedIn: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Gần bạn · 12'));
    await tester.pumpAndSettle();
    expect(dao.forYouCalls.last, (scope: 'NEAR', page: 0, q: ''));
    expect(find.textContaining('12 bài viết gắn với địa điểm ở Arakawa-ku'), findsOneWidget);
    expect(find.text('Bài số 1'), findsNothing);
    expect(find.text('Bài số 2'), findsOneWidget);
  });

  testWidgets('nút Xem thêm bài viết: tải trang sau; bài đã tương tác có tiêu đề riêng', (tester) async {
    // Màn hình cao, cả trang vừa khung: không cuộn nên chỉ nút "Xem thêm" tải trang sau
    tester.view.physicalSize = const Size(800, 9000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final dao = FakeHomeDao();
    await tester.pumpWidget(homeTestApp(home: const ForYouScreen(), homeDao: dao, signedIn: true));
    await tester.pumpAndSettle();
    expect(find.text('Bài bạn đã thích, lưu hoặc bình luận'), findsNothing);

    await tester.tap(find.text('Xem thêm bài viết'));
    await tester.pumpAndSettle();
    expect(dao.forYouCalls.last, (scope: 'ALL', page: 1, q: ''));
    expect(controllerOf(tester).forYouPosts, hasLength(20));

    await tester.tap(find.text('Xem thêm bài viết'));
    await tester.pumpAndSettle();
    expect(controllerOf(tester).forYouPosts, hasLength(25));
    expect(find.text('Xem thêm bài viết'), findsNothing);
    expect(find.text('Bài bạn đã thích, lưu hoặc bình luận'), findsOneWidget);
  });

  testWidgets('cuộn tới cuối danh sách thì tự tải trang sau', (tester) async {
    final dao = FakeHomeDao();
    await tester.pumpWidget(homeTestApp(home: const ForYouScreen(), homeDao: dao, signedIn: true));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Bài số 15'));
    expect(dao.forYouCalls.any((c) => c.page == 1), isTrue);
  });

  testWidgets('gõ tìm: chờ một chút rồi hỏi server, tô chữ khớp', (tester) async {
    final dao = FakeHomeDao();
    await tester.pumpWidget(homeTestApp(home: const ForYouScreen(), homeDao: dao, signedIn: true));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('for-you-search')), 'Bài số 2');
    await tester.pump(const Duration(milliseconds: 100));
    expect(dao.forYouCalls, hasLength(1));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(dao.forYouCalls.last.q, 'Bài số 2');
    expect(find.textContaining('7 bài viết có “Bài số 2”'), findsOneWidget);
    expect(find.byType(FeedPostCard), findsWidgets);
  });

  testWidgets('không tìm thấy: mời tìm trên toàn Senpai ơi hoặc xóa từ khóa', (tester) async {
    final dao = FakeHomeDao();
    await tester.pumpWidget(homeTestApp(home: const ForYouScreen(), homeDao: dao, signedIn: true));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('for-you-search')), 'không có');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Không có bài viết nào có “không có” trong các bài dành cho bạn.'), findsOneWidget);

    await tester.tap(find.text('Xóa từ khóa'));
    await tester.pumpAndSettle();
    expect(dao.forYouCalls.last.q, '');
    expect(find.text('Bài số 1'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('for-you-search')), 'không có');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tìm “không có” trên toàn Senpai ơi'));
    await tester.pumpAndSettle();
    expect(find.byType(GlobalSearchScreen), findsOneWidget);
  });

  testWidgets('mở với từ khóa có sẵn (từ màn Tìm kiếm)', (tester) async {
    final dao = FakeHomeDao();
    await tester.pumpWidget(
      homeTestApp(
        home: const ForYouScreen(initialQuery: 'Bài số 2'),
        homeDao: dao,
        signedIn: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(dao.forYouCalls.single.q, 'Bài số 2');
    expect(find.text('Bài số 1'), findsNothing);
  });

  testWidgets('lỗi server: câu báo lỗi và Thử lại', (tester) async {
    final dao = FakeHomeDao()..failWith = const ApiException('Không kết nối được tới server.');
    await tester.pumpWidget(homeTestApp(home: const ForYouScreen(), homeDao: dao, signedIn: true));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Không kết nối được tới server.'), findsOneWidget);

    dao.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Bài số 1'), findsOneWidget);
  });
}
