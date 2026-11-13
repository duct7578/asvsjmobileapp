// Widget test của BlogListScreen: cấp Controller dùng DAO giả bằng Provider, rồi kiểm tra màn hình vẽ đúng.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_card.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';

import 'blog_fakes.dart';

void main() {
  /// Màn hình cao để thấy hết danh sách mà không phải cuộn.
  void tallScreen(WidgetTester tester, {double width = 800}) {
    tester.view.physicalSize = Size(width, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> open(WidgetTester tester, FakeBlogDao dao, {bool signedIn = false}) async {
    tallScreen(tester);
    await tester.pumpWidget(await blogTestApp(dao, home: const BlogListScreen(), signedIn: signedIn));
    await tester.pumpAndSettle();
  }

  testWidgets('hiện bài nổi bật, thống kê, các bài và nút của thanh tiêu đề', (tester) async {
    await open(tester, FakeBlogDao());

    expect(find.byType(BlogCard), findsNWidgets(2));
    expect(find.text('Mở tài khoản ngân hàng'), findsOneWidget);
    expect(find.text('Bài nổi bật tuần này'), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('Thống kê cộng đồng'), findsOneWidget);
    expect(find.text('2 bài'), findsOneWidget);
    expect(find.byTooltip('Tìm kiếm'), findsOneWidget);
    expect(find.byTooltip('Đăng nhập'), findsOneWidget);
  });

  testWidgets('đang tải lần đầu hiện vòng quay', (tester) async {
    tallScreen(tester);
    final dao = FakeBlogDao()..readHold = Completer<void>();
    await tester.pumpWidget(await blogTestApp(dao, home: const BlogListScreen()));
    await tester.pump();
    expect(find.byType(LoadingView), findsOneWidget);
    expect(find.text('Chưa có bài viết nào.'), findsNothing);

    dao.readHold!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LoadingView), findsNothing);
    expect(find.byType(BlogCard), findsNWidgets(2));
  });

  testWidgets('lỗi server hiện câu thông báo và nút Thử lại', (tester) async {
    final dao = FakeBlogDao()..failWith = const ApiException('Không kết nối được tới server.');
    await open(tester, dao);

    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Không kết nối được tới server.'), findsOneWidget);

    dao.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byType(BlogCard), findsNWidgets(2));
  });

  testWidgets('chưa có bài nào thì hiện câu MSG32', (tester) async {
    final dao = FakeBlogDao()..stored = [];
    await open(tester, dao);
    expect(find.text('Chưa có bài viết nào.'), findsOneWidget);
  });

  testWidgets('lọc theo chủ đề, xóa bộ lọc', (tester) async {
    final dao = FakeBlogDao();
    await open(tester, dao);

    await tester.tap(find.widgetWithText(FilterChip, 'Khác'));
    await tester.pumpAndSettle();
    expect(dao.calls.last, 'findAll q= topics=[3] sort=NEWEST page=0');
    expect(find.byType(BlogCard), findsOneWidget);
    expect(find.text('1 bài phù hợp'), findsOneWidget);
    // Đang lọc thì ẩn bài nổi bật như web
    expect(find.text('Bài nổi bật tuần này'), findsNothing);

    await tester.tap(find.text('Xóa bộ lọc'));
    await tester.pumpAndSettle();
    expect(find.byType(BlogCard), findsNWidgets(2));
  });

  testWidgets('tìm không thấy thì hiện MSG33 và nút Xóa bộ lọc', (tester) async {
    final dao = FakeBlogDao();
    await open(tester, dao);

    await tester.enterText(find.byType(TextField), 'osaka');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(dao.calls.last, 'findAll q=osaka topics=[] sort=NEWEST page=0');
    expect(find.text('Không có bài viết nào khớp với lựa chọn của bạn.'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Xóa bộ lọc'));
    await tester.pumpAndSettle();
    expect(find.byType(BlogCard), findsNWidgets(2));
    expect(find.text('osaka'), findsNothing);
  });

  testWidgets('đổi cách sắp xếp', (tester) async {
    final dao = FakeBlogDao();
    await open(tester, dao);

    await tester.tap(find.byTooltip('Sắp xếp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nhiều thích').last);
    await tester.pumpAndSettle();
    expect(dao.calls.last, 'findAll q= topics=[] sort=LIKES page=0');
    expect(find.text('Nhiều thích'), findsOneWidget);
  });

  testWidgets('bấm "Tải thêm" lấy trang sau', (tester) async {
    final dao = FakeBlogDao()..pageSize = 1;
    await open(tester, dao);
    expect(find.byType(BlogCard), findsOneWidget);

    await tester.tap(find.text('Tải thêm'));
    await tester.pumpAndSettle();
    expect(find.byType(BlogCard), findsNWidgets(2));
    expect(find.text('Tải thêm'), findsNothing);
  });

  testWidgets('bài đang quét ảnh của mình có nhãn', (tester) async {
    final dao = FakeBlogDao();
    dao.stored.insert(0, sampleBlog(id: 9, title: 'Bài có ảnh', status: 'PROCESSING', mine: true));
    await open(tester, dao, signedIn: true);
    expect(find.text('Đang quét ảnh'), findsOneWidget);
  });

  testWidgets('bấm một bài mở màn chi tiết', (tester) async {
    await open(tester, FakeBlogDao());
    await tester.tap(find.text('Mở tài khoản ngân hàng'));
    await tester.pumpAndSettle();
    expect(find.byType(BlogDetailScreen), findsOneWidget);
    expect(find.text('Cần thẻ cư trú'), findsOneWidget);
  });

  testWidgets('khách bấm Viết bài thì được đưa sang màn Đăng nhập', (tester) async {
    await open(tester, FakeBlogDao());

    await tester.tap(find.byTooltip('Viết bài'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('người đã đăng nhập bấm Viết bài thì mở form', (tester) async {
    await open(tester, FakeBlogDao(), signedIn: true);

    await tester.tap(find.byTooltip('Viết bài'));
    await tester.pumpAndSettle();
    expect(find.byType(BlogFormScreen), findsOneWidget);
    expect(find.text('Đăng bài'), findsOneWidget);
  });

  testWidgets('màn hẹp 360 dp không tràn chữ', (tester) async {
    final dao = FakeBlogDao();
    dao.stored.insert(
      0,
      sampleBlog(id: 9, title: 'Một tiêu đề rất dài ' * 6, status: 'PROCESSING', mine: true, author: an),
    );
    tallScreen(tester, width: 360);
    await tester.pumpWidget(await blogTestApp(dao, home: const BlogListScreen(), signedIn: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(BlogCard), findsNWidgets(3));
  });
}
