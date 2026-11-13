/// Một review trong thẻ "Review mới quanh …" của trang chủ thành viên (ReviewItem của `GET /api/me/home`).
class HomeReview {
  const HomeReview({
    required this.id,
    required this.placeId,
    required this.placeName,
    this.categoryIcon = '',
    this.placeArea,
    this.near,
    this.rating = 0,
    this.authorName = '',
    this.excerpt = '',
    this.createdAt,
  });

  final int id;

  /// Địa điểm được review: bấm vào thì mở chi tiết địa điểm.
  final int placeId;
  final String placeName;

  /// Tên biểu tượng Material của loại địa điểm, ví dụ "school".
  final String categoryIcon;

  /// Khu vực của địa điểm, ví dụ "Arakawa-ku, Tokyo · 東京都荒川区"; null khi ở ngoài Nhật.
  final String? placeArea;

  /// AREA (cùng khu vực với người dùng), PREFECTURE (cùng tỉnh) hoặc null.
  final String? near;

  /// Số sao 1–5.
  final int rating;
  final String authorName;
  final String excerpt;
  final DateTime? createdAt;

  factory HomeReview.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    return HomeReview(
      id: json['id'] as int,
      placeId: json['placeId'] as int,
      placeName: (json['placeName'] ?? '') as String,
      categoryIcon: (json['categoryIcon'] ?? '') as String,
      placeArea: json['placeArea'] as String?,
      near: json['near'] as String?,
      rating: (json['rating'] ?? 0) as int,
      authorName: (json['authorName'] ?? '') as String,
      excerpt: (json['excerpt'] ?? '') as String,
      createdAt: created is String ? DateTime.tryParse(created)?.toLocal() : null,
    );
  }
}
