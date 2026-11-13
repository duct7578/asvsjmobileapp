import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/blog_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/author.dart';
import 'package:myasvsj/com.myasvsj.model/blog.dart';
import 'package:myasvsj/com.myasvsj.model/blog_comment.dart';
import 'package:myasvsj/com.myasvsj.model/blog_compose_options.dart';
import 'package:myasvsj/com.myasvsj.model/blog_dao.dart';
import 'package:myasvsj/com.myasvsj.model/blog_overview.dart';
import 'package:myasvsj/com.myasvsj.model/blog_place.dart';
import 'package:myasvsj/com.myasvsj.model/blog_topic_stat.dart';
import 'package:myasvsj/com.myasvsj.model/blog_writer.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.model/notification_dao.dart';
import 'package:myasvsj/com.myasvsj.model/page_result.dart';
import 'package:myasvsj/com.myasvsj.model/report_reason.dart';
import 'package:myasvsj/com.myasvsj.model/topic.dart';

import 'auth_fakes.dart';

/// App để widget test màn hình Blog: cấp AuthController (khách, hoặc [signedIn] là `testUser`),
/// NotificationController (cho AppBarActions) và BlogController dùng [dao].
Future<Widget> blogTestApp(FakeBlogDao dao, {required Widget home, bool signedIn = false}) async {
  final auth = AuthController(FakeAuthDao(current: signedIn ? testUser : null));
  await auth.restoreSession();
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider(create: (_) => NotificationController(SilentNotificationDao())),
      ChangeNotifierProvider(create: (_) => BlogController(dao)),
    ],
    child: MaterialApp(debugShowCheckedModeBanner: false, home: home),
  );
}

/// DAO thông báo giả cho thanh tiêu đề: không gọi gì (hàm nào bị gọi thì rơi vào noSuchMethod).
class SilentNotificationDao implements NotificationDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Dữ liệu mẫu cho test Controller và màn hình Blog (giống dữ liệu mẫu của server: Lan Anh, Trần Minh…).

const lanAnh = Author(id: 6, displayName: 'Lan Anh', tagNames: ['Mentor'], rankName: 'Senpai tin cậy');
const tranMinh = Author(id: 2, displayName: 'Trần Minh', rankName: 'Người mới');

/// Người đang đăng nhập trong test (cùng id với `testUser` của auth_fakes.dart).
const an = Author(id: 1, displayName: 'An', rankName: 'Người mới');

const sampleTopics = [Topic(id: 1, name: 'Nhà ở'), Topic(id: 2, name: 'Cảnh báo lừa đảo'), Topic(id: 3, name: 'Khác')];

const sampleReasons = [ReportReason(id: 1, label: 'Lừa đảo'), ReportReason(id: 4, label: 'Spam')];

const nippori = BlogPlace(
  id: 1,
  externalId: 'N772389775',
  name: 'Ga Nippori',
  category: 'Ga tàu',
  address: 'Higashi-Nippori 6, Arakawa, Tokyo',
  lat: 35.72892,
  lng: 139.771364,
);

/// Bình luận 10 của Trần Minh, có câu trả lời 11 của An (người đang đăng nhập).
final sampleComments = [
  BlogComment(
    id: 10,
    author: tranMinh,
    content: 'Cảm ơn chị, rất hữu ích.',
    likeCount: 2,
    createdAt: DateTime(2026, 11, 1, 9),
    replies: [
      BlogComment(
        id: 11,
        parentId: 10,
        author: an,
        content: 'Mình cũng thấy vậy.',
        mine: true,
        createdAt: DateTime(2026, 11, 1, 10),
      ),
    ],
  ),
];

/// Một bài như màn chi tiết nhận được. [signedIn]: cờ `viewer` của người đang đăng nhập (User).
Blog sampleBlog({
  int id = 1,
  String title = 'Thuê nhà ở Tokyo',
  String content = 'Kinh nghiệm thuê nhà: hỏi kỹ phí đầu vào.',
  Author author = lanAnh,
  String status = 'PUBLISHED',
  bool signedIn = true,
  bool mine = false,
  bool liked = false,
  bool saved = false,
  int likeCount = 3,
  List<BlogComment>? comments,
  List<MediaItem> media = const [],
  List<BlogPlace> places = const [nippori],
  List<Topic> topics = const [Topic(id: 1, name: 'Nhà ở')],
}) {
  final tree = comments ?? sampleComments;
  return Blog(
    id: id,
    title: title,
    content: content,
    status: status,
    author: author,
    topics: topics,
    places: places,
    media: media,
    likeCount: likeCount,
    commentCount: _count(tree),
    createdAt: DateTime(2026, 10, 30),
    isMine: mine,
    isSignedIn: signedIn,
    canInteract: signedIn && status == 'PUBLISHED',
    isLiked: liked,
    isSaved: saved,
    comments: tree,
    reportReasons: sampleReasons,
  );
}

int _count(List<BlogComment> nodes) => nodes.fold(0, (sum, c) => sum + (c.removed ? 0 : 1) + _count(c.replies));

/// DAO giả: giữ bài trong bộ nhớ thay vì gọi server, để test Controller và màn hình không cần mạng.
class FakeBlogDao implements BlogDao {
  FakeBlogDao({this.signedIn = true}) {
    stored = [
      sampleBlog(signedIn: signedIn),
      sampleBlog(
        id: 2,
        title: 'Mở tài khoản ngân hàng',
        content: 'Cần thẻ cư trú',
        author: tranMinh,
        signedIn: signedIn,
        comments: const [],
        places: const [],
        topics: const [Topic(id: 3, name: 'Khác')],
        likeCount: 0,
      ),
    ];
  }

  /// Cờ `viewer` của bài: người xem đã đăng nhập (User) hay là khách.
  final bool signedIn;

  late List<Blog> stored;

  /// Số bài mỗi trang của findAll (đặt nhỏ để thử tải thêm).
  int pageSize = 10;

  /// Đặt khác null để mọi lần gọi đều lỗi như server từ chối.
  ApiException? failWith;

  /// Chỉ các thao tác ghi (thích, lưu, bình luận, đăng bài…) bị lỗi; đọc vẫn bình thường.
  ApiException? writeError;

  /// Khác null: thao tác ghi chờ tới khi complete, để test xem trạng thái ở giữa (cập nhật lạc quan).
  Completer<void>? hold;

  /// Khác null: thao tác đọc chờ tới khi complete, để test thấy trạng thái đang tải.
  Completer<void>? readHold;

  /// Các lần gọi, ví dụ "findAll q= topics=[1] sort=LIKES page=0", "like 1", "addComment 1 parent=10".
  final List<String> calls = [];

  /// Bài đã gửi lên qua create / update kèm ảnh mới, để test kiểm tra Controller gửi gì.
  final List<({Blog blog, List<String> imagePaths})> created = [];
  final List<({Blog blog, List<String> imagePaths})> updated = [];

  Future<void> _read(String call) async {
    calls.add(call);
    _maybeFail();
    if (readHold != null) {
      await readHold!.future;
    }
  }

  void _maybeFail() {
    if (failWith != null) {
      throw failWith!;
    }
  }

  Future<void> _write(String call) async {
    calls.add(call);
    _maybeFail();
    if (hold != null) {
      await hold!.future;
    }
    if (writeError != null) {
      throw writeError!;
    }
  }

  Blog _find(int id) => stored.firstWhere(
    (b) => b.id == id,
    orElse: () => throw const ApiException(
      'Không tìm thấy nội dung bạn yêu cầu. Bài viết có thể đã bị gỡ hoặc đã bị xóa.',
      statusCode: 404,
    ),
  );

  void _replace(Blog blog) => stored[stored.indexWhere((b) => b.id == blog.id)] = blog;

  @override
  Future<PageResult<Blog>> findAll({
    String q = '',
    List<int> topicIds = const [],
    String sort = 'NEWEST',
    int page = 0,
  }) async {
    await _read('findAll q=$q topics=$topicIds sort=$sort page=$page');
    final found = stored
        .where((b) => q.isEmpty || b.title.toLowerCase().contains(q.toLowerCase()))
        .where((b) => topicIds.isEmpty || b.topicIds.any(topicIds.contains))
        .toList();
    final pages = found.isEmpty ? 1 : (found.length + pageSize - 1) ~/ pageSize;
    final current = page.clamp(0, pages - 1);
    return PageResult(
      items: found.skip(current * pageSize).take(pageSize).toList(),
      page: current,
      size: pageSize,
      totalItems: found.length,
      totalPages: pages,
    );
  }

  @override
  Future<BlogOverview> findOverview() async {
    calls.add('findOverview');
    _maybeFail();
    return BlogOverview(
      featuredPeriod: 'WEEK',
      featured: stored.take(1).toList(),
      topics: sampleTopics,
      popularTopics: const [BlogTopicStat(id: 1, name: 'Nhà ở', postCount: 4)],
      topWriters: const [BlogWriter(author: lanAnh, postCount: 2)],
    );
  }

  @override
  Future<Blog> findById(int id) async {
    await _read('findById $id');
    return _find(id);
  }

  @override
  Future<BlogComposeOptions> findComposeOptions() async {
    await _read('findComposeOptions');
    return const BlogComposeOptions(topics: sampleTopics, scamWarningTopicIds: {2}, canPostLinks: true);
  }

  @override
  Future<Blog> findForEdit(int id) async {
    calls.add('findForEdit $id');
    _maybeFail();
    final blog = _find(id);
    return Blog(
      id: blog.id,
      title: blog.title,
      content: blog.content,
      status: blog.status,
      topics: blog.topics,
      places: blog.places,
      media: blog.media,
      isMine: true,
    );
  }

  @override
  Future<List<BlogPlace>> searchPlaces(String q) async {
    calls.add('searchPlaces $q');
    _maybeFail();
    if (q == 'không có') {
      return const [];
    }
    return const [
      BlogPlace(id: 8, name: 'Bưu điện Nippori', category: 'Bưu điện và ngân hàng', address: 'Higashi-Nippori 4'),
      BlogPlace(externalId: 'N100', name: 'Ga Ueno', category: 'Ga tàu', source: 'OSM'),
    ];
  }

  @override
  Future<BlogSaveResult> create(Blog blog, {List<String> imagePaths = const []}) async {
    await _write('create');
    created.add((blog: blog, imagePaths: imagePaths));
    final id = 100 + created.length;
    final status = imagePaths.isEmpty ? 'PUBLISHED' : 'PROCESSING';
    stored.insert(0, sampleBlog(id: id, title: blog.title, content: blog.content, status: status, mine: true));
    return (
      id: id,
      status: status,
      message: status == 'PUBLISHED'
          ? 'Bài viết của bạn đã được đăng.'
          : 'Đã gửi. Ảnh và video đang được quét, trong lúc này chỉ bạn thấy bài.',
    );
  }

  @override
  Future<BlogSaveResult> update(Blog blog, {List<String> imagePaths = const []}) async {
    await _write('update ${blog.id}');
    updated.add((blog: blog, imagePaths: imagePaths));
    _replace(sampleBlog(id: blog.id!, title: blog.title, content: blog.content, mine: true, media: blog.media));
    return (id: blog.id!, status: 'PUBLISHED', message: 'Đã lưu thay đổi.');
  }

  @override
  Future<String> delete(int id) async {
    await _write('delete $id');
    stored.removeWhere((b) => b.id == id);
    return 'Đã xóa bài viết.';
  }

  @override
  Future<BlogLikeState> like(int id) => _likeBlog(id, true);

  @override
  Future<BlogLikeState> unlike(int id) => _likeBlog(id, false);

  Future<BlogLikeState> _likeBlog(int id, bool on) async {
    await _write('${on ? 'like' : 'unlike'} $id');
    final blog = _find(id);
    final count = blog.likeCount + (on == blog.isLiked ? 0 : (on ? 1 : -1));
    _replace(blog.copyWith(isLiked: on, likeCount: count));
    return (active: on, count: count);
  }

  @override
  Future<String> save(int id) async {
    await _write('save $id');
    _replace(_find(id).copyWith(isSaved: true));
    return 'Đã lưu bài viết.';
  }

  @override
  Future<String> unsave(int id) async {
    await _write('unsave $id');
    _replace(_find(id).copyWith(isSaved: false));
    return 'Đã bỏ lưu bài viết.';
  }

  @override
  Future<String> report(int id, {required int reasonId, String note = ''}) async {
    await _write('report $id reason=$reasonId note=$note');
    return 'Cảm ơn bạn. Báo cáo đã được gửi.';
  }

  @override
  Future<BlogCommentResult> addComment(int blogId, String content, {int? parentId}) async {
    await _write('addComment $blogId parent=$parentId');
    final blog = _find(blogId);
    final comment = BlogComment(id: 500 + calls.length, parentId: parentId, author: an, content: content, mine: true);
    final comments = parentId == null
        ? [...blog.comments, comment]
        : _map(blog.comments, parentId, (c) => c.copyWith(replies: [...c.replies, comment]));
    final next = sampleBlog(
      id: blog.id!,
      title: blog.title,
      content: blog.content,
      author: blog.author!,
      signedIn: blog.isSignedIn,
      mine: blog.isMine,
      liked: blog.isLiked,
      saved: blog.isSaved,
      likeCount: blog.likeCount,
      comments: comments,
      places: blog.places,
      topics: blog.topics,
    );
    _replace(next);
    return (blog: next, message: 'Đã đăng bình luận.');
  }

  @override
  Future<BlogCommentResult> updateComment(int commentId, String content) async {
    await _write('updateComment $commentId $content');
    return (blog: _withComment(commentId), message: 'Đã lưu bình luận.');
  }

  @override
  Future<BlogCommentResult> deleteComment(int commentId) async {
    await _write('deleteComment $commentId');
    final blog = _withComment(commentId);
    final next = blog.copyWith(comments: _remove(blog.comments, commentId));
    _replace(next);
    return (blog: next, message: 'Đã xóa bình luận.');
  }

  @override
  Future<BlogCommentResult> reportComment(int commentId, {required int reasonId, String note = ''}) async {
    await _write('reportComment $commentId reason=$reasonId');
    return (blog: _withComment(commentId), message: 'Cảm ơn bạn. Báo cáo đã được gửi.');
  }

  @override
  Future<BlogLikeState> likeComment(int commentId) => _likeComment(commentId, true);

  @override
  Future<BlogLikeState> unlikeComment(int commentId) => _likeComment(commentId, false);

  Future<BlogLikeState> _likeComment(int commentId, bool on) async {
    await _write('${on ? 'likeComment' : 'unlikeComment'} $commentId');
    final blog = _withComment(commentId);
    var count = 0;
    _replace(
      blog.copyWith(
        comments: _map(blog.comments, commentId, (c) {
          count = c.likeCount + (on == c.liked ? 0 : (on ? 1 : -1));
          return c.copyWith(liked: on, likeCount: count);
        }),
      ),
    );
    return (active: on, count: count);
  }

  /// Bài có bình luận [commentId].
  Blog _withComment(int commentId) => stored.firstWhere((b) => _has(b.comments, commentId));

  static bool _has(List<BlogComment> nodes, int id) => nodes.any((c) => c.id == id || _has(c.replies, id));

  static List<BlogComment> _map(List<BlogComment> nodes, int id, BlogComment Function(BlogComment) change) => [
    for (final c in nodes) c.id == id ? change(c) : c.copyWith(replies: _map(c.replies, id, change)),
  ];

  static List<BlogComment> _remove(List<BlogComment> nodes, int id) => [
    for (final c in nodes)
      if (c.id != id) c.copyWith(replies: _remove(c.replies, id)),
  ];
}
