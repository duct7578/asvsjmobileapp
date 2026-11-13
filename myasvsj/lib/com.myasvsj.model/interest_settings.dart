import 'package:myasvsj/com.myasvsj.model/interest_topic.dart';

/// Mọi chủ đề chọn được làm "Chủ đề quan tâm" (theo thứ tự của Blog) và số chủ đề chọn tối đa.
///
/// JSON: `{max, topics: [...]}` (InterestSettings của `GET|PUT /api/me/interests`).
class InterestSettings {
  const InterestSettings({this.max = 5, this.topics = const []});

  final int max;
  final List<InterestTopic> topics;

  /// Chủ đề đã chọn, theo thứ tự của Blog.
  List<InterestTopic> get chosen => [
    for (final t in topics)
      if (t.chosen) t,
  ];

  factory InterestSettings.fromJson(Map<String, dynamic> json) => InterestSettings(
    max: (json['max'] ?? 5) as int,
    topics: [for (final t in (json['topics'] as List?) ?? const []) InterestTopic.fromJson(t as Map<String, dynamic>)],
  );
}
