/// "Câu tiếng Nhật hôm nay" trên trang chủ (`phrase` của `GET /api/home` và `GET /api/me/home`).
class HomePhrase {
  const HomePhrase({
    required this.japanese,
    this.romaji = '',
    this.meaningVi = '',
    this.categoryId = '',
    this.categoryName = '',
    this.categoryIcon = '',
    this.topicId,
  });

  final String japanese;
  final String romaji;
  final String meaningVi;

  /// Loại địa điểm của mẫu câu, ví dụ "konbini" – "Cửa hàng tiện lợi".
  final String categoryId;
  final String categoryName;

  /// Tên biểu tượng Material của web, ví dụ "local_convenience_store".
  final String categoryIcon;

  /// Chủ đề học của mẫu câu (cho "Học thêm chủ đề này"); null khi không có.
  final String? topicId;

  /// null khi server không gửi mẫu câu (chưa có dữ liệu).
  static HomePhrase? tryParse(Object? json) => json is Map<String, dynamic> ? HomePhrase.fromJson(json) : null;

  factory HomePhrase.fromJson(Map<String, dynamic> json) => HomePhrase(
    japanese: (json['japanese'] ?? '') as String,
    romaji: (json['romaji'] ?? '') as String,
    meaningVi: (json['meaningVi'] ?? '') as String,
    categoryId: (json['categoryId'] ?? '') as String,
    categoryName: (json['categoryName'] ?? '') as String,
    categoryIcon: (json['categoryIcon'] ?? '') as String,
    topicId: json['topicId'] as String?,
  );
}
