import 'package:myasvsj/com.myasvsj.model/author.dart';
import 'package:myasvsj/com.myasvsj.model/topic.dart';

/// Phần không phụ thuộc bộ lọc của trang Hỏi-Đáp (Overview của `GET /api/questions/overview`):
/// chủ đề để lọc, thống kê, chủ đề hay được hỏi và các senpai trả lời nhiều.
///
/// JSON: `{topics: [{id, name}], stats: {total, unanswered, solved}, popularTopics: [{id, name, postCount}],
/// topAnswerers: [{author, answerCount, bestCount}], topAnswerersDays}`.
class QuestionOverview {
  const QuestionOverview({
    this.topics = const [],
    this.total = 0,
    this.unanswered = 0,
    this.solved = 0,
    this.popularTopics = const [],
    this.topAnswerers = const [],
    this.topAnswerersDays = 30,
  });

  /// Chủ đề để lọc danh sách (chủ đề của blog, dùng chung với Hỏi-Đáp).
  final List<Topic> topics;

  /// Câu hỏi đã đăng: tất cả, chưa ai trả lời, đã giải quyết.
  final int total;
  final int unanswered;
  final int solved;

  /// "Chủ đề hay được hỏi" kèm số câu hỏi.
  final List<({Topic topic, int count})> popularTopics;

  /// "Senpai giải đáp nhiều" trong [topAnswerersDays] ngày qua.
  final List<({Author author, int answerCount, int bestCount})> topAnswerers;
  final int topAnswerersDays;

  factory QuestionOverview.fromJson(Map<String, dynamic> json) {
    final stats = (json['stats'] as Map<String, dynamic>?) ?? const {};
    return QuestionOverview(
      topics: [for (final t in (json['topics'] as List?) ?? const []) Topic.fromJson(t as Map<String, dynamic>)],
      total: (stats['total'] ?? 0) as int,
      unanswered: (stats['unanswered'] ?? 0) as int,
      solved: (stats['solved'] ?? 0) as int,
      popularTopics: [
        for (final t in (json['popularTopics'] as List?) ?? const [])
          (topic: Topic.fromJson(t as Map<String, dynamic>), count: (t['postCount'] ?? 0) as int),
      ],
      topAnswerers: [
        for (final a in (json['topAnswerers'] as List?) ?? const [])
          if ((a as Map<String, dynamic>)['author'] is Map<String, dynamic>)
            (
              author: Author.fromJson(a['author'] as Map<String, dynamic>),
              answerCount: (a['answerCount'] ?? 0) as int,
              bestCount: (a['bestCount'] ?? 0) as int,
            ),
      ],
      topAnswerersDays: (json['topAnswerersDays'] ?? 30) as int,
    );
  }
}
