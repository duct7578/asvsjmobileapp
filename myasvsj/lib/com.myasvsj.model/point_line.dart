/// Một lần cộng hoặc trừ điểm (bảng `point_transactions`), dòng của "Lịch sử điểm".
///
/// JSON: `{id, delta, reason, reasonLabel, title, link, createdAt}` (PointLine của `GET /api/me/points`).
class PointLine {
  const PointLine({
    required this.id,
    required this.delta,
    this.reason = '',
    this.reasonLabel = '',
    this.title,
    this.link,
    this.createdAt,
  });

  final int id;

  /// Số điểm cộng (dương) hoặc trừ (âm).
  final int delta;

  /// Mã lý do, ví dụ REVIEW_CREATED.
  final String reason;

  /// Lý do để hiện, ví dụ "Viết review".
  final String reasonLabel;

  /// Tên nội dung được cộng / trừ điểm; null khi nội dung không còn.
  final String? title;

  /// Đường dẫn web sạch tới nội dung (`/blog/12`, `/qa/3`, `/map?place=9`, `/events/5`);
  /// null khi nội dung không còn xem được.
  final String? link;

  final DateTime? createdAt;

  bool get isPlus => delta > 0;

  factory PointLine.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    return PointLine(
      id: json['id'] as int,
      delta: (json['delta'] ?? 0) as int,
      reason: (json['reason'] ?? '') as String,
      reasonLabel: (json['reasonLabel'] ?? json['reason'] ?? '') as String,
      title: json['title'] as String?,
      link: json['link'] as String?,
      createdAt: created is String ? DateTime.tryParse(created)?.toLocal() : null,
    );
  }
}
