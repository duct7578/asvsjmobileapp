/// Một chủ đề học ("Thanh toán", bảng `learning_topics`) hoặc một loại địa điểm ("Cửa hàng tiện lợi",
/// bảng `place_categories`) của Nhật ngữ.
///
/// Ở trang đầu (`GET /api/phrases/overview`) có thêm số mục [count] và số mục thành viên đã thuộc [learned];
/// trên thẻ mẫu câu (`category`, `topics` của `GET /api/phrases`) hai số này là 0.
class PhraseGroup {
  const PhraseGroup({required this.id, required this.name, this.icon = 'label', this.count = 0, this.learned = 0});

  /// Mã chữ, ví dụ "pay", "konbini".
  final String id;
  final String name;

  /// Tên biểu tượng Material Symbols của web, ví dụ "payments" (xem PhraseIcon).
  final String icon;
  final int count;

  /// Số mục người xem giữ là "Đã thuộc" (0 với khách).
  final int learned;

  factory PhraseGroup.fromJson(Map<String, dynamic> json) => PhraseGroup(
    id: (json['id'] ?? '') as String,
    name: (json['name'] ?? '') as String,
    icon: (json['icon'] ?? 'label') as String,
    count: (json['count'] ?? 0) as int,
    learned: (json['learned'] ?? 0) as int,
  );

  static List<PhraseGroup> listFrom(Object? json) => [
    for (final item in (json as List?) ?? const []) PhraseGroup.fromJson(item as Map<String, dynamic>),
  ];

  PhraseGroup copyWith({int? learned}) =>
      PhraseGroup(id: id, name: name, icon: icon, count: count, learned: learned ?? this.learned);
}
