/// Một cấp bậc theo điểm (bảng `ranks`), ví dụ "Người chỉ đường" từ 100 điểm.
///
/// JSON: `{name, minPoints, featuredBonus}` (RankResponse của `GET /api/me/profile`).
class ProfileRank {
  const ProfileRank({required this.name, required this.minPoints, this.featuredBonus = 0});

  final String name;

  /// Số điểm tối thiểu để đạt cấp này.
  final int minPoints;

  /// Điểm ưu tiên cộng thêm khi xếp hạng "Bài nổi bật".
  final int featuredBonus;

  /// Đặc quyền của cấp, theo số điểm tối thiểu, chép từ trang Tôi của web (PERKS trong profile.js).
  static const Map<int, List<String>> _perks = {
    0: ['Viết review, blog', 'Xin tag định danh'],
    100: ['Bài viết được cộng 5 điểm ưu tiên khi xếp hạng Bài nổi bật', 'Huy hiệu trên hồ sơ'],
    300: ['Bài viết được cộng 10 điểm ưu tiên khi xếp hạng Bài nổi bật', 'Câu trả lời trong Hỏi đáp được hiện trước'],
  };

  List<String> get perks => _perks[minPoints] ?? const [];

  factory ProfileRank.fromJson(Map<String, dynamic> json) => ProfileRank(
    name: (json['name'] ?? '') as String,
    minPoints: (json['minPoints'] ?? 0) as int,
    featuredBonus: (json['featuredBonus'] ?? 0) as int,
  );
}
