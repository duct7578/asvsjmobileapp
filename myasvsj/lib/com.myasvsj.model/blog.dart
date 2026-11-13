import 'package:myasvsj/com.myasvsj.model/author.dart';
import 'package:myasvsj/com.myasvsj.model/blog_comment.dart';
import 'package:myasvsj/com.myasvsj.model/blog_place.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.model/report_reason.dart';
import 'package:myasvsj/com.myasvsj.model/topic.dart';

/// Một bài viết Blog, ứng với một dòng của bảng `blogs` trong database của web.
///
/// Cùng một lớp cho ba dạng JSON: thẻ trong danh sách (BlogCard), bài ở màn chi tiết (BlogDetail, có thêm media,
/// bình luận, cờ của người xem) và bài như đang lưu cho form sửa (EditData).
class Blog {
  const Blog({
    this.id,
    required this.title,
    this.content = '',
    this.status = 'PUBLISHED',
    this.pinned = false,
    this.edited = false,
    this.author,
    this.topics = const [],
    this.places = const [],
    this.media = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.createdAt,
    this.isMine = false,
    this.isSignedIn = false,
    this.canInteract = false,
    this.isLiked = false,
    this.isSaved = false,
    this.comments = const [],
    this.reportReasons = const [],
  });

  /// Trạng thái tác giả còn sửa được bài (BlogWriteService.EDITABLE của web).
  static const editableStatuses = {'PUBLISHED', 'PROCESSING', 'REJECTED'};

  /// null khi bài chưa lưu.
  final int? id;
  final String title;

  /// Nội dung đầy đủ ở màn chi tiết; ở danh sách server chỉ gửi đoạn trích (excerpt).
  final String content;

  /// PUBLISHED; PROCESSING khi ảnh đang được quét (chỉ tác giả thấy bài); HIDDEN, REJECTED chỉ tác giả thấy.
  final String status;

  /// Bài được Moderator ghim.
  final bool pinned;

  /// Đã sửa sau khi đăng ("· đã sửa").
  final bool edited;

  /// null khi tài khoản tác giả đã xóa.
  final Author? author;

  /// Chủ đề (1–3).
  final List<Topic> topics;

  /// Địa điểm liên quan (≤ 5). Khi sửa bài phải gửi lại đủ, vì server bỏ địa điểm không có trong danh sách.
  final List<BlogPlace> places;

  /// Ảnh (và video đăng từ web). Khi sửa bài, đây là các media giữ lại (`keepMediaIds`).
  final List<MediaItem> media;

  final int likeCount;
  final int commentCount;
  final DateTime? createdAt;

  /// Cờ của người đang xem (`viewer` của web). Khách: tất cả là false.
  final bool isMine;
  final bool isSignedIn;

  /// Đã đăng nhập bằng tài khoản User và bài đã đăng: được thích, lưu, bình luận, báo cáo.
  final bool canInteract;
  final bool isLiked;
  final bool isSaved;

  /// Cây bình luận (chỉ có ở màn chi tiết).
  final List<BlogComment> comments;

  /// Lý do báo cáo server cho chọn (chỉ có ở màn chi tiết).
  final List<ReportReason> reportReasons;

  String get authorName => author?.displayName ?? '';
  List<int> get topicIds => [for (final t in topics) t.id];
  List<String> get topicNames => [for (final t in topics) t.name];
  List<MediaItem> get images => [
    for (final m in media)
      if (m.isImage) m,
  ];
  bool get isPublished => status == 'PUBLISHED';
  bool get isProcessing => status == 'PROCESSING';

  /// Tác giả thấy nút "Sửa" (bài bị ẩn vì báo cáo thì không sửa được).
  bool get canEdit => isMine && editableStatuses.contains(status);

  Blog copyWith({int? likeCount, int? commentCount, bool? isLiked, bool? isSaved, List<BlogComment>? comments}) => Blog(
    id: id,
    title: title,
    content: content,
    status: status,
    pinned: pinned,
    edited: edited,
    author: author,
    topics: topics,
    places: places,
    media: media,
    likeCount: likeCount ?? this.likeCount,
    commentCount: commentCount ?? this.commentCount,
    createdAt: createdAt,
    isMine: isMine,
    isSignedIn: isSignedIn,
    canInteract: canInteract,
    isLiked: isLiked ?? this.isLiked,
    isSaved: isSaved ?? this.isSaved,
    comments: comments ?? this.comments,
    reportReasons: reportReasons,
  );

  /// Thẻ trong danh sách (BlogCard) hoặc bài ở màn chi tiết (BlogDetail).
  factory Blog.fromJson(Map<String, dynamic> json) {
    final viewer = (json['viewer'] as Map<String, dynamic>?) ?? const {};
    final created = json['createdAt'];
    return Blog(
      id: json['id'] as int?,
      title: (json['title'] ?? '') as String,
      content: (json['content'] ?? json['excerpt'] ?? '') as String,
      status: (json['status'] ?? 'PUBLISHED') as String,
      pinned: (json['pinned'] ?? false) as bool,
      edited: (json['edited'] ?? false) as bool,
      author: Author.tryParse(json['author']),
      topics: [for (final t in _maps(json['topics'])) Topic.fromJson(t)],
      places: [for (final p in _maps(json['places'])) BlogPlace.fromJson(p)],
      media: [for (final m in _maps(json['media'])) MediaItem.fromJson(m)],
      likeCount: (json['likeCount'] ?? 0) as int,
      commentCount: (json['commentCount'] ?? 0) as int,
      createdAt: created is String ? DateTime.tryParse(created)?.toLocal() : null,
      isMine: (viewer['author'] ?? false) as bool,
      isSignedIn: (viewer['signedIn'] ?? false) as bool,
      canInteract: (viewer['canInteract'] ?? false) as bool,
      isLiked: (viewer['liked'] ?? false) as bool,
      isSaved: (viewer['saved'] ?? false) as bool,
      comments: BlogComment.listFrom(json['comments']),
      reportReasons: ReportReason.listFrom(json['reportReasons']),
    );
  }

  /// Bài như đang lưu, cho form "Sửa bài" (EditData của `GET /api/blogs/{id}/edit`).
  /// Tên chủ đề lấy từ `options.topics` đi kèm.
  factory Blog.fromEditJson(Map<String, dynamic> json) {
    final options = (json['options'] as Map<String, dynamic>?) ?? const {};
    final names = {for (final t in _maps(options['topics'])) t['id'] as int: (t['name'] ?? '') as String};
    return Blog(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      content: (json['content'] ?? '') as String,
      status: (json['status'] ?? 'PUBLISHED') as String,
      topics: [for (final id in (json['topicIds'] as List?) ?? const []) Topic(id: id as int, name: names[id] ?? '')],
      places: [for (final p in _maps(json['places'])) BlogPlace.fromJson(p)],
      media: [for (final m in _maps(json['media'])) MediaItem.fromJson(m)],
      isMine: true,
    );
  }

  /// Phần JSON "post" gửi lên `POST /api/blogs` (CreateRequest) và `PUT /api/blogs/{id}` (UpdateRequest).
  Map<String, dynamic> toJson() => {
    'title': title,
    'content': content,
    'topicIds': topicIds,
    'placeIds': [
      for (final p in places)
        if (p.id != null) p.id,
    ],
    'externalPlaceIds': [
      for (final p in places)
        if (p.id == null && p.externalId != null) p.externalId,
    ],
    if (id != null) 'keepMediaIds': [for (final m in media) m.id],
  };

  static List<Map<String, dynamic>> _maps(Object? list) => [
    for (final item in (list as List?) ?? const []) item as Map<String, dynamic>,
  ];
}
