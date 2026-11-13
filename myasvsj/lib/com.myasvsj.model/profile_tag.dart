/// Tag định danh đã được cấp, ví dụ "Kouhai" màu xanh (TagResponse của `GET /api/me/profile`).
///
/// JSON: `{name, color}`; `color` là mã màu web dạng "#2E7D5B".
class ProfileTag {
  const ProfileTag({required this.name, this.color = ''});

  final String name;
  final String color;

  /// Màu dạng số ARGB để Screen vẽ (`Color(colorValue!)`); null khi server không gửi màu hợp lệ.
  int? get colorValue => parseColor(color);

  /// "#2E7D5B" hoặc "2E7D5B" → 0xFF2E7D5B; chuỗi khác trả về null.
  static int? parseColor(String? hex) {
    final digits = (hex ?? '').replaceFirst('#', '');
    if (digits.length != 6) {
      return null;
    }
    final rgb = int.tryParse(digits, radix: 16);
    return rgb == null ? null : 0xFF000000 | rgb;
  }

  factory ProfileTag.fromJson(Map<String, dynamic> json) =>
      ProfileTag(name: (json['name'] ?? '') as String, color: (json['color'] ?? '') as String);
}
