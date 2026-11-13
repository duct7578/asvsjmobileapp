/// Lý do một bài nằm trong "Dành cho bạn" (FeedReason của web), ví dụ "Gần khu vực của bạn · Ga Nippori".
class FeedReason {
  const FeedReason({required this.code, required this.label, this.detail});

  /// AREA, PREFECTURE, STAGE hoặc INTEREST.
  final String code;

  /// Chữ trên nhãn, ví dụ "Hợp giai đoạn của bạn".
  final String label;

  /// Điều khớp: địa điểm gắn với bài (AREA, PREFECTURE) hoặc chủ đề (STAGE, INTEREST); null khi không có.
  final String? detail;

  factory FeedReason.fromJson(Map<String, dynamic> json) => FeedReason(
    code: (json['code'] ?? '') as String,
    label: (json['label'] ?? '') as String,
    detail: json['detail'] as String?,
  );
}
