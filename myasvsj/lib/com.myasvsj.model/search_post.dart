import 'package:myasvsj/com.myasvsj.model/home_tag.dart';

/// Một bài viết Blog tìm được (BlogCard trong `posts` của `GET /api/search`).
class SearchPost {
  const SearchPost({
    required this.id,
    required this.title,
    this.excerpt = '',
    this.status = 'PUBLISHED',
    this.topicNames = const [],
    this.authorName = '',
    this.authorTags = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.createdAt,
  });

  final int id;
  final String title;
  final String excerpt;

  /// PUBLISHED, hoặc PROCESSING với bài của chính người tìm đang được kiểm duyệt.
  final String status;
  final List<String> topicNames;
  final String authorName;
  final List<HomeTag> authorTags;
  final int likeCount;
  final int commentCount;
  final DateTime? createdAt;

  bool get isProcessing => status == 'PROCESSING';

  factory SearchPost.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final created = json['createdAt'];
    return SearchPost(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      excerpt: (json['excerpt'] ?? '') as String,
      status: (json['status'] ?? 'PUBLISHED') as String,
      topicNames: [
        for (final t in (json['topics'] as List?) ?? const []) ((t as Map<String, dynamic>)['name'] ?? '') as String,
      ],
      authorName: (author?['displayName'] ?? '') as String,
      authorTags: HomeTag.listFrom(author?['tags']),
      likeCount: (json['likeCount'] ?? 0) as int,
      commentCount: (json['commentCount'] ?? 0) as int,
      createdAt: created is String ? DateTime.tryParse(created)?.toLocal() : null,
    );
  }
}
