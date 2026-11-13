import 'package:myasvsj/com.myasvsj.model/home_tag.dart';

/// Một review trên màn "Review mới" (FeedReview của `GET /api/home/reviews`).
class RecentReview {
  const RecentReview({
    required this.id,
    required this.placeId,
    required this.placeName,
    this.categoryName = '',
    this.categoryIcon = '',
    this.placeArea,
    this.placeClosed = false,
    this.near,
    this.rating = 0,
    this.authorName = '',
    this.authorTags = const [],
    this.excerpt = '',
    this.likeCount = 0,
    this.createdAt,
    this.photoUrl,
    this.mediaCount = 0,
  });

  final int id;

  /// Địa điểm được review: bấm vào thì mở chi tiết địa điểm.
  final int placeId;
  final String placeName;
  final String categoryName;

  /// Tên biểu tượng Material của loại địa điểm, ví dụ "restaurant".
  final String categoryIcon;

  /// Khu vực của địa điểm, ví dụ "Arakawa-ku, Tokyo · 東京都荒川区"; null khi ở ngoài Nhật.
  final String? placeArea;

  /// Địa điểm đã đóng cửa.
  final bool placeClosed;

  /// AREA ("Gần bạn"), PREFECTURE ("Cùng tỉnh") hoặc null.
  final String? near;

  /// Số sao 1–5.
  final int rating;
  final String authorName;
  final List<HomeTag> authorTags;

  /// Đầu nội dung review (tối đa 240 ký tự).
  final String excerpt;
  final int likeCount;
  final DateTime? createdAt;

  /// Ảnh đầu tiên đã qua kiểm duyệt (`/media/…`); null khi không có.
  final String? photoUrl;

  /// Số ảnh và video đã qua kiểm duyệt.
  final int mediaCount;

  /// Nhãn "Hữu ích" của web: hơn 10 lượt thích.
  bool get isHelpful => likeCount > 10;

  factory RecentReview.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    return RecentReview(
      id: json['id'] as int,
      placeId: json['placeId'] as int,
      placeName: (json['placeName'] ?? '') as String,
      categoryName: (json['categoryName'] ?? '') as String,
      categoryIcon: (json['categoryIcon'] ?? '') as String,
      placeArea: json['placeArea'] as String?,
      placeClosed: (json['placeClosed'] ?? false) as bool,
      near: json['near'] as String?,
      rating: (json['rating'] ?? 0) as int,
      authorName: (json['authorName'] ?? '') as String,
      authorTags: HomeTag.listFrom(json['authorTags']),
      excerpt: (json['excerpt'] ?? '') as String,
      likeCount: (json['likeCount'] ?? 0) as int,
      createdAt: created is String ? DateTime.tryParse(created)?.toLocal() : null,
      photoUrl: json['photoUrl'] as String?,
      mediaCount: (json['mediaCount'] ?? 0) as int,
    );
  }
}
