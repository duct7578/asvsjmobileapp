// Widget test của BlogDetailScreen: bài, địa điểm, cây bình luận, thích / lưu / báo cáo / bình luận / trả lời,
// khách bị đưa sang đăng nhập, tác giả thấy Sửa / Xóa.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_comment_tile.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_media_grid.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';

import 'blog_fakes.dart';

/// Màn trước màn chi tiết, để thấy màn chi tiết đóng lại sau khi xóa bài.
class _Home extends StatelessWidget {
  const _Home();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const BlogDetailScreen(blogId: 1))),
        child: const Text('Mở bài'),
      ),
    ),
  );
}

void main() {
  void screen(WidgetTester tester, {double width = 800}) {
    tester.view.physicalSize = Size(width, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<FakeBlogDao> open(WidgetTester tester, {bool signedIn = true, FakeBlogDao? dao, double width = 800}) async {
    final blogs = dao ?? FakeBlogDao(signedIn: signedIn);
    screen(tester, width: width);
    await tester.pumpWidget(await blogTestApp(blogs, home: const BlogDetailScreen(blogId: 1), signedIn: signedIn));
    await tester.pumpAndSettle();
    return blogs;
  }

  testWidgets('hiện bài, tác giả, chủ đề, địa điểm và cây bình luận', (tester) async {
    await open(tester);

    expect(find.text('Thuê nhà ở Tokyo'), findsOneWidget);
    expect(find.text('Kinh nghiệm thuê nhà: hỏi kỹ phí đầu vào.'), findsOneWidget);
    expect(find.text('Lan Anh'), findsOneWidget);
    expect(find.text('Mentor'), findsOneWidget);
    expect(find.text('Senpai tin cậy'), findsOneWidget);
    expect(find.text('Nhà ở'), findsOneWidget);
    expect(find.text('Địa điểm liên quan'), findsOneWidget);
    expect(find.text('Ga Nippori'), findsOneWidget);
    expect(find.text('Chỉ đường'), findsOneWidget);
    expect(find.text('Bình luận (2)'), findsOneWidget);
    expect(find.byType(BlogCommentTile), findsNWidgets(2));
    expect(find.text('Cảm ơn chị, rất hữu ích.'), findsOneWidget);
    expect(find.text('Mình cũng thấy vậy.'), findsOneWidget);
    // Không phải tác giả: không có Sửa / Xóa bài
    expect(find.byTooltip('Sửa bài'), findsNothing);
    expect(find.byTooltip('Xóa bài'), findsNothing);
  });

  testWidgets('đang tải hiện vòng quay; lỗi 404 hiện câu của server và Thử lại', (tester) async {
    final dao = FakeBlogDao()..readHold = Completer<void>();
    screen(tester);
    await tester.pumpWidget(await blogTestApp(dao, home: const BlogDetailScreen(blogId: 99), signedIn: true));
    await tester.pump();
    expect(find.byType(LoadingView), findsOneWidget);

    dao.readHold!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.textContaining('Không tìm thấy nội dung bạn yêu cầu'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('bài có ảnh hiện lưới ảnh', (tester) async {
    final dao = FakeBlogDao();
    dao.stored[0] = sampleBlog(
      media: const [
        MediaItem(id: 17, type: 'IMAGE', url: '/media/a.jpg', width: 120, height: 80),
        MediaItem(id: 18, type: 'IMAGE', url: '/media/b.jpg'),
      ],
    );
    await open(tester, dao: dao);
    expect(find.byType(BlogMediaGrid), findsOneWidget);
    expect(find.bySemanticsLabel('Xem ảnh 2'), findsOneWidget);
  });

  testWidgets('khách bấm Thích thì được đưa sang Đăng nhập', (tester) async {
    await open(tester, signedIn: false);

    expect(find.text('Đăng nhập để bình luận và thích bài viết.'), findsOneWidget);
    await tester.tap(find.text('Thích · 3'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('khách bấm Nhắn tin hoặc Trả lời cũng được đưa sang Đăng nhập', (tester) async {
    await open(tester, signedIn: false);
    // Khách thấy Nhắn tin ở bài, không thấy ở bình luận
    expect(find.text('Nhắn tin'), findsOneWidget);

    await tester.tap(find.text('Trả lời').first);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('thích bài: số tăng ngay', (tester) async {
    final dao = await open(tester);

    await tester.tap(find.text('Thích · 3'));
    await tester.pumpAndSettle();
    expect(dao.calls, contains('like 1'));
    expect(find.text('Thích · 4'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
  });

  testWidgets('lưu bài hiện câu của server', (tester) async {
    await open(tester);

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Đã lưu bài viết.'), findsOneWidget);
    expect(find.text('Đã lưu'), findsOneWidget);
  });

  testWidgets('gửi bình luận: bình luận mới hiện ra, ô trống lại', (tester) async {
    final dao = await open(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Chia sẻ thêm kinh nghiệm hoặc góp ý'), 'Hữu ích quá');
    await tester.tap(find.byTooltip('Gửi bình luận'));
    await tester.pumpAndSettle();
    expect(dao.calls, contains('addComment 1 parent=null'));
    expect(find.text('Hữu ích quá'), findsOneWidget);
    expect(find.text('Đã đăng bình luận.'), findsOneWidget);
    expect(find.text('Bình luận (3)'), findsOneWidget);
  });

  testWidgets('trả lời một bình luận', (tester) async {
    final dao = await open(tester);

    await tester.tap(find.text('Trả lời').first);
    await tester.pumpAndSettle();
    expect(find.text('Đang trả lời Trần Minh'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Viết câu trả lời cho bình luận này'), 'Đồng ý');
    await tester.tap(find.byTooltip('Gửi bình luận'));
    await tester.pumpAndSettle();
    expect(dao.calls, contains('addComment 1 parent=10'));
    expect(find.text('Đồng ý'), findsOneWidget);
    expect(find.text('Đang trả lời Trần Minh'), findsNothing);
  });

  testWidgets('bình luận quá nhanh: câu của server dưới ô, chữ đang viết còn nguyên', (tester) async {
    final dao = await open(tester);
    dao.writeError = const ApiException('Bạn bình luận hơi nhanh. Vui lòng đợi 7 giây rồi thử lại.', statusCode: 429);

    await tester.enterText(find.widgetWithText(TextField, 'Chia sẻ thêm kinh nghiệm hoặc góp ý'), 'Lần nữa');
    await tester.tap(find.byTooltip('Gửi bình luận'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn bình luận hơi nhanh. Vui lòng đợi 7 giây rồi thử lại.'), findsOneWidget);
    expect(find.text('Lần nữa'), findsOneWidget);
  });

  testWidgets('bình luận của mình có Sửa, Xóa; xóa hỏi xác nhận', (tester) async {
    final dao = await open(tester);
    // Bình luận của Trần Minh có Nhắn tin; bình luận của mình thì không
    expect(find.text('Nhắn tin'), findsNWidgets(2));
    expect(find.text('Sửa'), findsOneWidget);

    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn có chắc muốn xóa bình luận này?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();
    expect(dao.calls, contains('deleteComment 11'));
    expect(find.text('Mình cũng thấy vậy.'), findsNothing);
    expect(find.text('Đã xóa bình luận.'), findsOneWidget);
  });

  testWidgets('sửa bình luận của mình', (tester) async {
    final dao = await open(tester);

    await tester.tap(find.text('Sửa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), 'Đã sửa');
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('Lưu')));
    await tester.pumpAndSettle();
    expect(dao.calls, contains('updateComment 11 Đã sửa'));
    expect(find.text('Đã lưu bình luận.'), findsOneWidget);
  });

  testWidgets('báo cáo bài: chọn lý do trong hộp thoại rồi gửi', (tester) async {
    final dao = await open(tester);

    await tester.tap(find.text('Báo cáo').first);
    await tester.pumpAndSettle();
    expect(find.text('Báo cáo bài viết'), findsOneWidget);
    await tester.tap(find.text('Spam'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi báo cáo'));
    await tester.pumpAndSettle();
    expect(dao.calls, contains('report 1 reason=4 note='));
    expect(find.text('Cảm ơn bạn. Báo cáo đã được gửi.'), findsOneWidget);
  });

  testWidgets('tác giả thấy Sửa, Xóa; xóa bài xong quay về màn trước', (tester) async {
    final dao = FakeBlogDao();
    dao.stored[0] = sampleBlog(mine: true);
    screen(tester);
    await tester.pumpWidget(await blogTestApp(dao, home: const _Home(), signedIn: true));
    await tester.tap(find.text('Mở bài'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Sửa bài'), findsOneWidget);
    expect(find.text('♥ 3 lượt thích'), findsOneWidget);
    // Không báo cáo, không nhắn tin cho bài của chính mình
    expect(find.text('Báo cáo'), findsOneWidget); // chỉ ở bình luận của Trần Minh
    expect(find.text('Nhắn tin'), findsOneWidget);

    await tester.tap(find.byTooltip('Xóa bài'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();
    expect(dao.calls, contains('delete 1'));
    expect(find.byType(BlogDetailScreen), findsNothing);
    expect(find.text('Đã xóa bài viết.'), findsOneWidget);
  });

  testWidgets('tác giả bấm Sửa mở form sửa bài', (tester) async {
    final dao = FakeBlogDao();
    dao.stored[0] = sampleBlog(mine: true);
    await open(tester, dao: dao);

    await tester.tap(find.byTooltip('Sửa bài'));
    await tester.pumpAndSettle();
    expect(find.byType(BlogFormScreen), findsOneWidget);
    expect(find.text('Lưu thay đổi'), findsOneWidget);
  });

  testWidgets('bài đang quét ảnh: ghi chú, chưa nhận bình luận', (tester) async {
    final dao = FakeBlogDao();
    dao.stored[0] = sampleBlog(mine: true, status: 'PROCESSING', comments: const []);
    await open(tester, dao: dao);

    expect(find.text('Ảnh của bài đang được quét. Trong lúc này chỉ bạn thấy bài.'), findsOneWidget);
    expect(find.text('Bài chưa được đăng nên chưa nhận bình luận.'), findsOneWidget);
    expect(find.byTooltip('Gửi bình luận'), findsNothing);
  });

  testWidgets('màn hẹp 360 dp không tràn chữ', (tester) async {
    final dao = FakeBlogDao();
    dao.stored[0] = sampleBlog(title: 'Tiêu đề dài ' * 10, content: 'Nội dung dài ' * 80);
    await open(tester, dao: dao, width: 360);
    expect(tester.takeException(), isNull);
    await tester.dragUntilVisible(find.text('Mình cũng thấy vậy.'), find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(BlogCommentTile), findsNWidgets(2));
  });
}
