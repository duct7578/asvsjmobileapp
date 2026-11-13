/// Tag định danh cạnh tên người viết, ví dụ "Mentor" (`{name, color}` trong JSON trang chủ, review mới, tìm kiếm).
class HomeTag {
  const HomeTag({required this.name, this.color = ''});

  final String name;

  /// Màu server gửi, dạng "#C2456E"; rỗng khi không có.
  final String color;

  factory HomeTag.fromJson(Map<String, dynamic> json) =>
      HomeTag(name: (json['name'] ?? '') as String, color: (json['color'] ?? '') as String);

  /// Đọc một mảng tag; null hoặc phần tử lạ thì bỏ qua.
  static List<HomeTag> listFrom(Object? json) => [
    for (final tag in (json as List?) ?? const [])
      if (tag is Map<String, dynamic>) HomeTag.fromJson(tag),
  ];
}
