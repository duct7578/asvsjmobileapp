import 'package:myasvsj/com.myasvsj.model/saved_item.dart';
import 'package:myasvsj/com.myasvsj.model/saved_kind.dart';
import 'package:myasvsj/com.myasvsj.model/topic.dart';

/// Bài viết hoặc câu hỏi đã lưu, còn đang đăng.
///
/// JSON: `{id, type, title, author: {id, displayName, avatarUrl}, topics: [{id, name}], likeCount, commentCount,
/// solved, createdAt, savedAt}` (SavedBlog của `GET /api/me/saved`).
class SavedBlog implements SavedItem {
  const SavedBlog({
    required this.id,
    required this.title,
    this.type = 'POST',
    this.authorName = '',
    this.topics = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    this.solved = false,
    this.createdAt,
    this.savedAt,
  });

  @override
  final int id;
  final String title;

  /// POST (bài viết Blog) hoặc QA (câu hỏi).
  final String type;
  final String authorName;
  final List<Topic> topics;
  final int likeCount;

  /// Số bình luận (bài viết) hoặc câu trả lời (câu hỏi).
  final int commentCount;

  /// Chỉ câu hỏi: đã có câu trả lời hay nhất.
  final bool solved;
  final DateTime? createdAt;

  @override
  final DateTime? savedAt;

  bool get isQuestion => type == 'QA';

  @override
  SavedKind get kind => isQuestion ? SavedKind.question : SavedKind.post;

  factory SavedBlog.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    return SavedBlog(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      type: (json['type'] ?? 'POST') as String,
      authorName: (author?['displayName'] ?? '') as String,
      topics: [for (final t in (json['topics'] as List?) ?? const []) Topic.fromJson(t as Map<String, dynamic>)],
      likeCount: (json['likeCount'] ?? 0) as int,
      commentCount: (json['commentCount'] ?? 0) as int,
      solved: (json['solved'] ?? false) as bool,
      createdAt: _date(json['createdAt']),
      savedAt: _date(json['savedAt']),
    );
  }

  static DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
