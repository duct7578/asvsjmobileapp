/// Một cẩm nang tìm được (GuideHit của `GET /api/search`).
class SearchGuide {
  const SearchGuide({
    required this.id,
    required this.title,
    this.summary = '',
    this.stageName,
    this.topicName,
    this.coverImageUrl,
  });

  final int id;
  final String title;

  /// Một đoạn ngắn đầu phần tóm tắt; có thể rỗng.
  final String summary;

  /// Giai đoạn, ví dụ "Khi mới đến (tuần đầu đến 3 tháng)".
  final String? stageName;
  final String? topicName;

  /// Ảnh bìa (`/media/…`); null khi không có.
  final String? coverImageUrl;

  factory SearchGuide.fromJson(Map<String, dynamic> json) => SearchGuide(
    id: json['id'] as int,
    title: (json['title'] ?? '') as String,
    summary: (json['summary'] ?? '') as String,
    stageName: json['stageName'] as String?,
    topicName: json['topicName'] as String?,
    coverImageUrl: json['coverImageUrl'] as String?,
  );
}
