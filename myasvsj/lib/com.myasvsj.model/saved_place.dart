import 'package:myasvsj/com.myasvsj.model/saved_item.dart';
import 'package:myasvsj/com.myasvsj.model/saved_kind.dart';

/// Địa điểm đã lưu còn trên Bản đồ; địa điểm đã gộp hiện địa điểm được gộp vào.
///
/// JSON: `{id, name, categoryId, categoryName, icon, address, closed, savedAt}` (SavedPlace của `GET /api/me/saved`).
class SavedPlace implements SavedItem {
  const SavedPlace({
    required this.id,
    required this.name,
    this.categoryId = '',
    this.categoryName = '',
    this.icon = '',
    this.address,
    this.closed = false,
    this.savedAt,
  });

  @override
  final int id;
  final String name;

  /// Mã loại địa điểm, ví dụ "station".
  final String categoryId;

  /// Ví dụ "Ga tàu".
  final String categoryName;

  /// Tên biểu tượng Material Symbols của loại địa điểm, ví dụ "train".
  final String icon;
  final String? address;

  /// Moderator đã gắn nhãn "Đã đóng cửa" (vẫn nằm trong Đã lưu).
  final bool closed;

  @override
  final DateTime? savedAt;

  @override
  SavedKind get kind => SavedKind.place;

  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    final saved = json['savedAt'];
    return SavedPlace(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      categoryId: (json['categoryId'] ?? '') as String,
      categoryName: (json['categoryName'] ?? '') as String,
      icon: (json['icon'] ?? '') as String,
      address: json['address'] as String?,
      closed: (json['closed'] ?? false) as bool,
      savedAt: saved is String ? DateTime.tryParse(saved)?.toLocal() : null,
    );
  }
}
