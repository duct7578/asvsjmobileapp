/// Một câu hỏi Hỏi-Đáp tìm được (QuestionCard trong `questions` của `GET /api/search`).
class SearchQuestion {
  const SearchQuestion({
    required this.id,
    required this.title,
    this.excerpt = '',
    this.status = 'PUBLISHED',
    this.solved = false,
    this.unanswered = false,
    this.topicNames = const [],
    this.authorName = '',
    this.likeCount = 0,
    this.answerCount = 0,
    this.createdAt,
  });

  final int id;
  final String title;
  final String excerpt;

  /// PUBLISHED, hoặc PROCESSING với câu hỏi của chính người tìm đang được kiểm duyệt.
  final String status;

  /// "Đã giải quyết" (đã có câu trả lời hay nhất).
  final bool solved;

  /// "Chưa ai trả lời".
  final bool unanswered;
  final List<String> topicNames;
  final String authorName;
  final int likeCount;
  final int answerCount;
  final DateTime? createdAt;

  bool get isProcessing => status == 'PROCESSING';

  factory SearchQuestion.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;
    final created = json['createdAt'];
    return SearchQuestion(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      excerpt: (json['excerpt'] ?? '') as String,
      status: (json['status'] ?? 'PUBLISHED') as String,
      solved: (json['solved'] ?? false) as bool,
      unanswered: (json['unanswered'] ?? false) as bool,
      topicNames: [
        for (final t in (json['topics'] as List?) ?? const []) ((t as Map<String, dynamic>)['name'] ?? '') as String,
      ],
      authorName: (author?['displayName'] ?? '') as String,
      likeCount: (json['likeCount'] ?? 0) as int,
      answerCount: (json['answerCount'] ?? 0) as int,
      createdAt: created is String ? DateTime.tryParse(created)?.toLocal() : null,
    );
  }
}
