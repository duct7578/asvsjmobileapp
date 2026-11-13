// Ảnh màn 12 "Blog", 13 "Bài viết", 14 "Viết bài" (và vài trạng thái phụ) để so với design/figma-export/ref/12-14.
// Chạy: flutter test test/design_shots/blog_shot_test.dart --dart-define=SHOTS=true
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/author.dart';
import 'package:myasvsj/com.myasvsj.model/blog.dart';
import 'package:myasvsj/com.myasvsj.model/blog_comment.dart';
import 'package:myasvsj/com.myasvsj.model/blog_compose_options.dart';
import 'package:myasvsj/com.myasvsj.model/blog_overview.dart';
import 'package:myasvsj/com.myasvsj.model/blog_place.dart';
import 'package:myasvsj/com.myasvsj.model/blog_topic_stat.dart';
import 'package:myasvsj/com.myasvsj.model/blog_writer.dart';
import 'package:myasvsj/com.myasvsj.model/page_result.dart';
import 'package:myasvsj/com.myasvsj.model/topic.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/photo_picker.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

import '../blog_fakes.dart';
import 'shot_helper.dart';

// Dữ liệu mẫu lấy từ thiết kế (chỉ dùng để chụp). Id chọn để cảnh minh hoạ trùng với thiết kế:
// bài 10 → Study, bài 12 → Torii, bài 14 → City; id tác giả chọn để màu ảnh đại diện giống thiết kế.
const _vy = Author(id: 4, displayName: 'Thảo Vy', tagNames: ['Đã đi làm'], rankName: 'Senpai vàng');
const _tuan = Author(id: 5, displayName: 'Tuấn', tagNames: ['Du học sinh']);
const _minhAnh = Author(id: 6, displayName: 'Minh Anh');
const _hoang = Author(id: 10, displayName: 'Hoàng');
const _linh = Author(id: 9, displayName: 'Linh');

const _topics = [
  Topic(id: 1, name: 'Nhà ở'),
  Topic(id: 2, name: 'Thủ tục'),
  Topic(id: 3, name: 'Du lịch'),
  Topic(id: 4, name: 'Ngân hàng'),
  Topic(id: 5, name: 'Kinh nghiệm'),
];

const _hikawa = BlogPlace(id: 31, name: 'Đền Hikawa Kawagoe', category: 'Saitama', address: '2-11-3 Miyashita-machi');
const _kashiya = BlogPlace(externalId: 'N55', name: 'Kashiya Yokocho', category: 'Phố kẹo', address: 'Motomachi, Kawagoe');

DateTime _ago(Duration d) => DateTime.now().subtract(d);

final _yuucho = Blog(
  id: 10,
  title: 'Hướng dẫn mở tài khoản Yuucho cho du học sinh mới',
  content:
      'Mang thẻ cư trú, số điện thoại Nhật và giấy chứng nhận đi học. Mình đi bưu điện Arakawa, mất 40 phút, '
      'nhân viên rất nhiệt tình.',
  pinned: true,
  author: _tuan,
  topics: const [Topic(id: 4, name: 'Ngân hàng')],
  places: const [BlogPlace(id: 40, name: 'Bưu điện Arakawa')],
  likeCount: 56,
  commentCount: 14,
  createdAt: _ago(const Duration(hours: 2, minutes: 5)),
);

final _kawagoe = Blog(
  id: 12,
  title: 'Đi Kawagoe một ngày: tiểu Edo cách Tokyo 30 phút',
  content: 'Từ Ikebukuro đi Tobu Tojo Line khoảng 30 phút. Mua vé Kawagoe Discount Pass 700 yên, đi khứ hồi.',
  author: _vy,
  topics: const [Topic(id: 3, name: 'Du lịch')],
  places: const [BlogPlace(id: 41, name: 'Kawagoe')],
  likeCount: 128,
  commentCount: 36,
  createdAt: _ago(const Duration(days: 1, hours: 1)),
);

final _rent = Blog(
  id: 14,
  title: 'Thuê nhà không cần người bảo lãnh',
  author: _minhAnh,
  likeCount: 96,
  commentCount: 41,
  createdAt: _ago(const Duration(days: 3)),
);

/// Bài ở màn chi tiết như thiết kế: đã ghim, 2 chủ đề, 2 địa điểm, người xem đã thích, 3 bình luận.
Blog _detail({required bool signedIn}) => Blog(
  id: 12,
  title: 'Đi Kawagoe một ngày: tiểu Edo cách Tokyo 30 phút',
  content:
      'Từ Ikebukuro đi Tobu Tojo Line khoảng 30 phút là tới Kawagoe. Mình mua vé Kawagoe Discount Pass 700 yên, '
      'đi khứ hồi và được giảm giá vài quán.\n\nPhố Kurazukuri buổi sáng còn vắng, chụp ảnh rất đẹp. Đến trưa nên '
      'ghé Kashiya Yokocho mua kẹo truyền thống và khoai lang nướng.',
  pinned: true,
  edited: true,
  author: _vy,
  topics: const [Topic(id: 3, name: 'Du lịch'), Topic(id: 5, name: 'Kinh nghiệm')],
  places: const [_hikawa, _kashiya],
  likeCount: 88,
  commentCount: 21,
  createdAt: _ago(const Duration(days: 1, hours: 2)),
  isSignedIn: signedIn,
  canInteract: signedIn,
  isLiked: signedIn,
  comments: [
    BlogComment(
      id: 70,
      author: _hoang,
      content: 'Pass 700 yên có dùng cho xe buýt vòng quanh phố cổ không chị?',
      likeCount: 3,
      createdAt: _ago(const Duration(hours: 2, minutes: 3)),
      replies: [
        BlogComment(
          id: 71,
          parentId: 70,
          author: _vy,
          content: 'Không em ơi, xe buýt Koedo Loop mua vé ngày riêng 500 yên nhé.',
          likeCount: 5,
          createdAt: _ago(const Duration(hours: 1, minutes: 3)),
        ),
      ],
    ),
    BlogComment(
      id: 72,
      author: _linh,
      content: 'Lưu lại cho mùa lá đỏ, cảm ơn chị!',
      likeCount: 1,
      createdAt: _ago(const Duration(minutes: 30)),
    ),
  ],
  reportReasons: sampleReasons,
);

/// DAO giả cho ảnh chụp: dữ liệu của thiết kế (248 bài, 2 bài nổi bật, form của tài khoản mới).
class _ShotBlogDao extends FakeBlogDao {
  _ShotBlogDao({super.signedIn}) {
    stored = [_yuucho, _kawagoe, _detail(signedIn: signedIn)];
  }

  @override
  Future<PageResult<Blog>> findAll({
    String q = '',
    List<int> topicIds = const [],
    String sort = 'NEWEST',
    int page = 0,
  }) async => PageResult(items: [_yuucho, _kawagoe], page: 0, size: 10, totalItems: 248, totalPages: 25);

  @override
  Future<BlogOverview> findOverview() async => BlogOverview(
    featuredPeriod: 'WEEK',
    featured: [_kawagoe, _rent],
    topics: _topics,
    popularTopics: const [
      BlogTopicStat(id: 3, name: 'Du lịch', postCount: 64),
      BlogTopicStat(id: 2, name: 'Thủ tục', postCount: 41),
    ],
    topWriters: const [BlogWriter(author: _vy, postCount: 9), BlogWriter(author: _tuan, postCount: 6)],
  );

  @override
  Future<Blog> findById(int id) async => _detail(signedIn: signedIn);

  @override
  Future<BlogComposeOptions> findComposeOptions() async => const BlogComposeOptions(
    topics: [
      Topic(id: 3, name: 'Du lịch'),
      Topic(id: 5, name: 'Kinh nghiệm'),
      Topic(id: 1, name: 'Nhà ở'),
      Topic(id: 2, name: 'Thủ tục'),
      Topic(id: 6, name: 'Ẩm thực'),
      Topic(id: 7, name: 'Việc làm thêm'),
      Topic(id: 8, name: 'Cảnh báo lừa đảo'),
      Topic(id: 9, name: 'Khác'),
    ],
    scamWarningTopicIds: {8},
    contentMax: 10000,
    imagesMax: 10,
    imageMaxMb: 10,
    newAccount: true,
    postsUsed: 1,
    postsLimit: 3,
  );

  @override
  Future<List<BlogPlace>> searchPlaces(String q) async => const [_hikawa, _kashiya];
}

/// Ghi một ảnh PNG nhỏ (nền brand-soft, hình tròn) ra file tạm để PhotoPicker có ảnh thật để hiện.
Future<String> _samplePhoto(WidgetTester tester, String name, Color dot) async {
  final path = '${Directory.systemTemp.path}/senpai_shot_$name.png';
  await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 160, 160), Paint()..color = SenpaiColors.brandSoft);
    canvas.drawCircle(const Offset(80, 96), 46, Paint()..color = dot);
    final image = await recorder.endRecording().toImage(160, 160);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
  return path;
}

/// Màn trước: mở [screen] ngay sau khung hình đầu, để màn được chụp có nút quay lại / đóng như trong app.
class _Launcher extends StatefulWidget {
  const _Launcher(this.screen);

  final Widget screen;

  @override
  State<_Launcher> createState() => _LauncherState();
}

class _LauncherState extends State<_Launcher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => shotTheme(widget.screen))),
    );
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}

/// Lưu ảnh rồi trả cờ debugDisableShadows về mặc định ngay trong thân test: pumpShot bật bóng thật và chỉ trả lại
/// trong addTearDown, chạy sau bước kiểm tra biến debug của flutter test nên test bị báo lỗi.
Future<void> _save(WidgetTester tester, String name) async {
  await saveShot(tester, name);
  debugDisableShadows = true;
}

void main() {
  testWidgets('12 Blog — thành viên', skip: shotSkip != null, (tester) async {
    final app = await blogTestApp(_ShotBlogDao(), home: shotTheme(const BlogListScreen()), signedIn: true);
    await pumpShot(tester, app, height: 800);
    await _save(tester, '12-blog');
  });

  testWidgets('12 Blog — mở thống kê', skip: shotSkip != null, (tester) async {
    final app = await blogTestApp(_ShotBlogDao(), home: shotTheme(const BlogListScreen()), signedIn: true);
    await pumpShot(tester, app, height: 1400);
    await tester.tap(find.text('Thống kê cộng đồng'));
    await settleShot(tester);
    await _save(tester, '12-blog-stats');
  });

  testWidgets('13 Bài viết — thành viên', skip: shotSkip != null, (tester) async {
    final app = await blogTestApp(_ShotBlogDao(), home: const _Launcher(BlogDetailScreen(blogId: 12)), signedIn: true);
    await pumpShot(tester, app, height: 1535);
    await _save(tester, '13-blog-detail');
  });

  testWidgets('13 Bài viết — khách', skip: shotSkip != null, (tester) async {
    final app = await blogTestApp(_ShotBlogDao(signedIn: false), home: const _Launcher(BlogDetailScreen(blogId: 12)));
    await pumpShot(tester, app, height: 844);
    await _save(tester, '13-blog-detail-guest');
  });

  testWidgets('13 Bài viết — hộp thoại báo cáo', skip: shotSkip != null, (tester) async {
    final app = await blogTestApp(_ShotBlogDao(), home: const _Launcher(BlogDetailScreen(blogId: 12)), signedIn: true);
    await pumpShot(tester, app, height: 1000);
    await tester.tap(find.text('Báo cáo').first);
    await settleShot(tester);
    await tester.tap(find.text('Spam'));
    await settleShot(tester);
    await _save(tester, '13-blog-report-dialog');
  });

  testWidgets('14 Viết bài — tài khoản mới', skip: shotSkip != null, (tester) async {
    final app = await blogTestApp(_ShotBlogDao(), home: const _Launcher(BlogFormScreen()), signedIn: true);
    await pumpShot(tester, app, height: 1094);
    Finder field(String label) =>
        find.descendant(of: find.widgetWithText(SenpaiLabeledField, label), matching: find.byType(TextField));
    await tester.enterText(
      field('Nội dung *'),
      'Từ Ikebukuro đi Tobu Tojo Line khoảng 30 phút là tới Kawagoe. Mình mua vé Kawagoe Discount Pass 700 yên…',
    );
    await tester.tap(find.widgetWithText(FilterChip, 'Du lịch'));
    await tester.tap(find.widgetWithText(FilterChip, 'Kinh nghiệm'));
    for (final (query, name) in [('kawagoe', 'Đền Hikawa Kawagoe'), ('kashiya', 'Kashiya Yokocho')]) {
      await tester.enterText(find.widgetWithText(TextField, 'Tìm địa điểm (không bắt buộc)'), query);
      await tester.tap(find.byTooltip('Tìm địa điểm'));
      await settleShot(tester);
      await tester.tap(find.text(name));
      await settleShot(tester);
    }
    final photos = [
      await _samplePhoto(tester, 'a', SenpaiColors.brand),
      await _samplePhoto(tester, 'b', SenpaiColors.lantern),
    ];
    final element = tester.element(find.byType(PhotoPicker));
    await tester.runAsync(() async {
      for (final path in photos) {
        await precacheImage(FileImage(File(path)), element);
      }
    });
    tester.widget<PhotoPicker>(find.byType(PhotoPicker)).onChanged(photos);
    // Tiêu đề nhập sau cùng để ô tiêu đề đang focus như thiết kế
    await tester.enterText(field('Tiêu đề *'), 'Đi Kawagoe một ngày: tiểu Edo cách Tokyo 30 phút');
    await settleShot(tester);
    await _save(tester, '14-blog-form');
  });
}
