import 'package:myasvsj/com.myasvsj.model/author.dart';

/// Một bình luận của bài viết, kèm các câu trả lời lồng bên dưới (CommentNode của web, bảng `comments`).
class BlogComment {
  const BlogComment({
    required this.id,
    this.parentId,
    this.author,
    this.content = '',
    this.edited = false,
    this.removed = false,
    this.mine = false,
    this.liked = false,
    this.likeCount = 0,
    this.createdAt,
    this.replies = const [],
  });

  final int id;

  /// Bình luận được trả lời; null với bình luận gốc.
  final int? parentId;

  /// null khi bình luận đã bị xóa hoặc tài khoản đã xóa.
  final Author? author;
  final String content;

  /// Đã sửa ("· đã sửa").
  final bool edited;

  /// Đã bị xóa nhưng còn câu trả lời: chỉ hiện dòng "Bình luận đã bị xóa.".
  final bool removed;

  /// Người đang xem viết bình luận này: được sửa, xóa; không thích, không báo cáo.
  final bool mine;
  final bool liked;
  final int likeCount;
  final DateTime? createdAt;
  final List<BlogComment> replies;

  BlogComment copyWith({bool? liked, int? likeCount, List<BlogComment>? replies}) => BlogComment(
    id: id,
    parentId: parentId,
    author: author,
    content: content,
    edited: edited,
    removed: removed,
    mine: mine,
    liked: liked ?? this.liked,
    likeCount: likeCount ?? this.likeCount,
    createdAt: createdAt,
    replies: replies ?? this.replies,
  );

  factory BlogComment.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    return BlogComment(
      id: json['id'] as int,
      parentId: json['parentId'] as int?,
      author: Author.tryParse(json['author']),
      content: (json['content'] ?? '') as String,
      edited: (json['edited'] ?? false) as bool,
      removed: (json['removed'] ?? false) as bool,
      mine: (json['mine'] ?? false) as bool,
      liked: (json['liked'] ?? false) as bool,
      likeCount: (json['likeCount'] ?? 0) as int,
      createdAt: created is String ? DateTime.tryParse(created)?.toLocal() : null,
      replies: listFrom(json['replies']),
    );
  }

  static List<BlogComment> listFrom(Object? json) => [
    for (final item in (json as List?) ?? const []) BlogComment.fromJson(item as Map<String, dynamic>),
  ];
}
