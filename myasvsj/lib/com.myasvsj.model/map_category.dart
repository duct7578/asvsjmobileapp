/// Một danh mục địa điểm trên bản đồ, ví dụ "Quán ăn", "Ga tàu" (`categories` của `GET /api/map`).
///
/// JSON: `{id: "food", name: "Quán ăn", icon: "restaurant", count: 2}`.
class MapCategory {
  const MapCategory({required this.id, required this.name, this.icon = 'place', this.count = 0});

  /// Mã danh mục, ví dụ "food", "station", "konbini".
  final String id;
  final String name;

  /// Tên biểu tượng Material Symbols của web, ví dụ "restaurant".
  final String icon;

  /// Số địa điểm của danh mục đang có trên bản đồ.
  final int count;

  factory MapCategory.fromJson(Map<String, dynamic> json) => MapCategory(
    id: (json['id'] ?? '') as String,
    name: (json['name'] ?? '') as String,
    icon: (json['icon'] ?? 'place') as String,
    count: (json['count'] ?? 0) as int,
  );
}
