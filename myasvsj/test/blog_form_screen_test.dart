// Widget test của BlogFormScreen: kiểm tra nhập, gắn địa điểm, đăng bài, sửa bài giữ / bỏ ảnh cũ, lỗi của server.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/photo_picker.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

import 'blog_fakes.dart';

/// Màn trước form: mở form và hiện kết quả form trả về.
class _Home extends StatefulWidget {
  const _Home({this.blogId});

  final int? blogId;

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  String _result = '';

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () async {
              final saved = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => BlogFormScreen(blogId: widget.blogId)),
              );
              setState(() => _result = 'kết quả: $saved');
            },
            child: const Text('Mở form'),
          ),
          Text(_result),
        ],
      ),
    ),
  );
}

void main() {
  Future<FakeBlogDao> open(WidgetTester tester, {int? blogId, FakeBlogDao? dao}) async {
    final blogs = dao ?? FakeBlogDao();
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(await blogTestApp(blogs, home: _Home(blogId: blogId), signedIn: true));
    await tester.tap(find.text('Mở form'));
    await tester.pumpAndSettle();
    return blogs;
  }

  /// Ô nhập theo nhãn: nhãn nằm trên ô (SenpaiLabeledField của thiết kế) hoặc là chữ gợi ý trong ô.
  Finder field(String label) {
    final labeled = find.descendant(
      of: find.widgetWithText(SenpaiLabeledField, label),
      matching: find.byType(TextField),
    );
    return labeled.evaluate().isNotEmpty ? labeled : find.widgetWithText(TextField, label);
  }

  testWidgets('form viết bài: chủ đề, địa điểm, ảnh, ghi chú về link', (tester) async {
    await open(tester);

    expect(find.text('Viết bài'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Nhà ở'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Khác'), findsOneWidget);
    expect(find.text('Địa điểm liên quan (0/5)'), findsOneWidget);
    expect(find.byType(PhotoPicker), findsOneWidget);
    expect(find.textContaining('Bạn có tag định danh nên được chèn link'), findsOneWidget);
    expect(find.text('Đăng bài'), findsOneWidget);
  });

  testWidgets('bấm Đăng bài khi còn trống: hiện lỗi từng ô, không gọi server', (tester) async {
    final dao = await open(tester);

    await tester.tap(find.text('Đăng bài'));
    await tester.pumpAndSettle();
    expect(find.text('Hãy nhập tiêu đề và nội dung cho bài viết.'), findsOneWidget);
    expect(find.text('Hãy nhập tiêu đề.'), findsOneWidget);
    expect(find.text('Hãy nhập nội dung bài viết.'), findsOneWidget);
    expect(find.textContaining('Hãy chọn ít nhất 1 chủ đề'), findsOneWidget);
    expect(dao.calls.where((c) => c == 'create'), isEmpty);
  });

  testWidgets('viết bài có địa điểm rồi đăng: form đóng và trả về true', (tester) async {
    final dao = await open(tester);

    await tester.enterText(field('Tiêu đề *'), 'Hỏi về visa');
    await tester.enterText(field('Nội dung *'), 'Gia hạn visa thế nào?');
    await tester.tap(find.widgetWithText(FilterChip, 'Khác'));
    await tester.enterText(field('Tìm địa điểm (không bắt buộc)'), 'nippori');
    await tester.tap(find.byTooltip('Tìm địa điểm'));
    await tester.pumpAndSettle();
    expect(find.text('Ga Ueno'), findsOneWidget);
    await tester.tap(find.text('Bưu điện Nippori'));
    await tester.pumpAndSettle();
    expect(find.text('Địa điểm liên quan (1/5)'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Bưu điện Nippori'), findsOneWidget);

    await tester.tap(find.text('Đăng bài'));
    await tester.pumpAndSettle();
    final sent = dao.created.single.blog;
    expect(sent.title, 'Hỏi về visa');
    expect(sent.topicIds, [3]);
    expect(sent.toJson()['placeIds'], [8]);
    expect(find.byType(BlogFormScreen), findsNothing);
    expect(find.text('kết quả: true'), findsOneWidget);
  });

  testWidgets('chọn chủ đề "Cảnh báo lừa đảo" hiện ghi chú về dấu "!" trên bản đồ', (tester) async {
    await open(tester);
    await tester.tap(find.widgetWithText(FilterChip, 'Cảnh báo lừa đảo'));
    await tester.pumpAndSettle();
    expect(find.textContaining('sẽ hiện dấu “!”'), findsOneWidget);
  });

  testWidgets('lỗi của server hiện trên cùng và dưới ô nội dung', (tester) async {
    final dao = await open(tester);
    dao.writeError = const ApiException(
      'Nội dung có từ ngữ không phù hợp: "vay nóng".',
      statusCode: 400,
      fields: {'content': 'Nội dung có từ ngữ không phù hợp: "vay nóng".'},
    );

    await tester.enterText(field('Tiêu đề *'), 'Vay tiền');
    await tester.enterText(field('Nội dung *'), 'vay nóng lãi thấp');
    await tester.tap(find.widgetWithText(FilterChip, 'Khác'));
    await tester.tap(find.text('Đăng bài'));
    await tester.pumpAndSettle();
    expect(find.text('Nội dung có từ ngữ không phù hợp: "vay nóng".'), findsNWidgets(2));
    expect(find.byType(BlogFormScreen), findsOneWidget);
  });

  testWidgets('sửa bài: điền sẵn, bỏ một ảnh cũ, lưu với keepMediaIds còn lại', (tester) async {
    final dao = FakeBlogDao();
    dao.stored[0] = sampleBlog(
      mine: true,
      media: const [
        MediaItem(id: 17, type: 'IMAGE', url: '/media/a.jpg'),
        MediaItem(id: 18, type: 'IMAGE', url: '/media/b.jpg'),
      ],
    );
    await open(tester, blogId: 1, dao: dao);

    expect(find.text('Sửa bài'), findsOneWidget);
    expect(find.text('Thuê nhà ở Tokyo'), findsOneWidget);
    expect(find.widgetWithText(InputChip, 'Ga Nippori'), findsOneWidget);
    expect(find.text('Ảnh đang có'), findsOneWidget);
    expect(find.byTooltip('Bỏ ảnh này'), findsNWidgets(2));

    await tester.tap(find.byTooltip('Bỏ ảnh này').first);
    await tester.pumpAndSettle();
    expect(find.byTooltip('Bỏ ảnh này'), findsOneWidget);

    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    final sent = dao.updated.single.blog;
    expect(sent.id, 1);
    expect(sent.toJson()['keepMediaIds'], [18]);
    expect(sent.toJson()['placeIds'], [1]);
    expect(find.text('kết quả: true'), findsOneWidget);
  });

  testWidgets('không mở được form (khách, staff): hiện câu của server', (tester) async {
    final dao = FakeBlogDao()..failWith = const ApiException('Bạn cần đăng nhập để viết bài.', statusCode: 401);
    await open(tester, dao: dao);
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Bạn cần đăng nhập để viết bài.'), findsOneWidget);
  });

  testWidgets('quay lại khi đã gõ: hỏi "Bỏ thay đổi?"', (tester) async {
    await open(tester);
    await tester.enterText(field('Tiêu đề *'), 'Nháp');

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ thay đổi?'), findsOneWidget);

    await tester.tap(find.text('Ở lại'));
    await tester.pumpAndSettle();
    expect(find.byType(BlogFormScreen), findsOneWidget);

    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ thay đổi'));
    await tester.pumpAndSettle();
    expect(find.byType(BlogFormScreen), findsNothing);
    expect(find.text('kết quả: null'), findsOneWidget);
  });

  testWidgets('quay lại khi chưa gõ gì: đóng ngay', (tester) async {
    await open(tester);
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.byType(BlogFormScreen), findsNothing);
  });
}
