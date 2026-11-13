/// Một địa điểm Senpai ơi tìm được (PlaceHit của `GET /api/search`).
class SearchPlace {
  const SearchPlace({
    required this.id,
    required this.name,
    this.nameJa,
    this.nameEn,
    this.categoryName = '',
    this.categoryIcon = '',
    this.areaName,
    this.address,
    this.closed = false,
    this.reviewCount = 0,
    this.rating,
  });

  final int id;
  final String name;
  final String? nameJa;
  final String? nameEn;
  final String categoryName;

  /// Tên biểu tượng Material của loại địa điểm, ví dụ "train".
  final String categoryIcon;

  /// Ví dụ "Arakawa-ku, Tokyo · 東京都荒川区"; null khi ở ngoài Nhật.
  final String? areaName;
  final String? address;

  /// Địa điểm đã đóng cửa.
  final bool closed;
  final int reviewCount;

  /// Điểm trung bình; null khi chưa có review.
  final double? rating;

  /// Tên tiếng Nhật (hoặc tiếng Anh) khác tên chính, để hiện bên cạnh; null khi trùng hoặc không có.
  String? get otherName {
    for (final n in [nameJa, nameEn]) {
      if (n != null && n.isNotEmpty && n != name) {
        return n;
      }
    }
    return null;
  }

  factory SearchPlace.fromJson(Map<String, dynamic> json) => SearchPlace(
    id: json['id'] as int,
    name: (json['name'] ?? '') as String,
    nameJa: json['nameJa'] as String?,
    nameEn: json['nameEn'] as String?,
    categoryName: (json['categoryName'] ?? '') as String,
    categoryIcon: (json['categoryIcon'] ?? '') as String,
    areaName: json['areaName'] as String?,
    address: json['address'] as String?,
    closed: (json['closed'] ?? false) as bool,
    reviewCount: (json['reviewCount'] ?? 0) as int,
    rating: (json['rating'] as num?)?.toDouble(),
  );
}
