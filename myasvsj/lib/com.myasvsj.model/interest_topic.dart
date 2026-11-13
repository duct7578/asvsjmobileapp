/// Một chủ đề blog người dùng chọn được làm "Chủ đề quan tâm" (bảng `user_interest_topics`).
///
/// JSON: `{id, name, chosen, learnt}` (InterestTopic của `GET /api/me/interests`).
class InterestTopic {
  const InterestTopic({required this.id, required this.name, this.chosen = false, this.learnt = false});

  final int id;
  final String name;

  /// Người dùng đã chọn chủ đề này.
  final bool chosen;

  /// Gợi ý: server học được từ những gì người dùng hay đọc, thích, lưu gần đây (không bao giờ đã chọn).
  final bool learnt;

  factory InterestTopic.fromJson(Map<String, dynamic> json) => InterestTopic(
    id: json['id'] as int,
    name: (json['name'] ?? '') as String,
    chosen: (json['chosen'] ?? false) as bool,
    learnt: (json['learnt'] ?? false) as bool,
  );
}
