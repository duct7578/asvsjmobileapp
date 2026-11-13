/// Người viết một bài, câu hỏi, câu trả lời, bình luận hay review (`author` trong JSON của web).
///
/// JSON: `{id, displayName, avatarUrl, tags: [{name, color}], rankName | rank}`.
class Author {
  const Author({
    required this.id,
    required this.displayName,
    this.tagNames = const [],
    this.tagColors = const [],
    this.rankName = '',
    this.avatarUrl,
  });

  final int id;
  final String displayName;

  /// Tag định danh đã được cấp, ví dụ "Mentor", "Du học sinh".
  final List<String> tagNames;

  /// Màu của từng tag trong [tagNames] (cùng thứ tự), ví dụ "#C2456E"; rỗng khi server không gửi màu.
  final List<String> tagColors;

  /// Cấp bậc theo điểm, ví dụ "Senpai tin cậy"; rỗng khi server không gửi.
  final String rankName;

  /// Ảnh đại diện (đường dẫn của server); null khi người dùng chưa có ảnh.
  final String? avatarUrl;

  /// null khi JSON không có `author` (bài của tài khoản đã xóa).
  static Author? tryParse(Object? json) => json is Map<String, dynamic> ? Author.fromJson(json) : null;

  factory Author.fromJson(Map<String, dynamic> json) {
    final tags = [for (final tag in (json['tags'] as List?) ?? const []) if (tag is Map<String, dynamic>) tag];
    // Bản đồ gửi cấp bậc ở `rank`, các trang khác ở `rankName`
    final rank = json['rankName'] ?? json['rank'];
    return Author(
      id: (json['id'] ?? 0) as int,
      displayName: (json['displayName'] ?? '') as String,
      tagNames: [for (final tag in tags) (tag['name'] ?? '') as String],
      tagColors: [for (final tag in tags) (tag['color'] ?? '') as String],
      rankName: rank is String ? rank : '',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}
