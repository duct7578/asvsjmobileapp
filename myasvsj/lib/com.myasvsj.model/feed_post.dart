import 'package:myasvsj/com.myasvsj.model/feed_reason.dart';

/// Một bài viết Senpai ơi chọn cho người dùng (FeedPost của `GET /api/me/home` và `GET /api/me/for-you`).
class FeedPost {
  const FeedPost({
    required this.id,
    required this.title,
    this.excerpt = '',
    this.authorName = '',
    this.topicName,
    this.likeCount = 0,
    this.commentCount = 0,
    this.createdAt,
    this.reason,
    this.reasons = const [],
    this.engaged = false,
  });

  /// Mã bài viết Blog.
  final int id;
  final String title;
  final String excerpt;
  final String authorName;
  final String? topicName;
  final int likeCount;
  final int commentCount;
  final DateTime? createdAt;

  /// Chữ của lý do đầu tiên; null khi bài chỉ được thêm cho đủ danh sách.
  final String? reason;

  /// Mọi lý do khớp, theo thứ tự xếp hạng.
  final List<FeedReason> reasons;

  /// Người dùng đã thích, lưu hoặc bình luận bài này (những bài này xếp cuối).
  final bool engaged;

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    return FeedPost(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      excerpt: (json['excerpt'] ?? '') as String,
      authorName: (json['authorName'] ?? '') as String,
      topicName: json['topicName'] as String?,
      likeCount: (json['likeCount'] ?? 0) as int,
      commentCount: (json['commentCount'] ?? 0) as int,
      createdAt: created is String ? DateTime.tryParse(created)?.toLocal() : null,
      reason: json['reason'] as String?,
      reasons: [for (final r in (json['reasons'] as List?) ?? const []) FeedReason.fromJson(r as Map<String, dynamic>)],
      engaged: (json['engaged'] ?? false) as bool,
    );
  }
}
