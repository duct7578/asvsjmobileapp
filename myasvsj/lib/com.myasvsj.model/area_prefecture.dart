/// Một tỉnh / thành phố của Nhật (bảng `prefectures`, 47 dòng), ví dụ "Tokyo · 東京都".
///
/// JSON: `{code, nameJa, nameEn, lat, lng}` (Prefecture của `GET /api/areas`).
class AreaPrefecture {
  const AreaPrefecture({required this.code, required this.nameJa, required this.nameEn, this.lat, this.lng});

  /// Mã hai chữ số, ví dụ "13" là Tokyo.
  final String code;
  final String nameJa;
  final String nameEn;
  final double? lat;
  final double? lng;

  /// Tên để hiện trong danh sách, ví dụ "Tokyo · 東京都".
  String get label => '$nameEn · $nameJa';

  factory AreaPrefecture.fromJson(Map<String, dynamic> json) => AreaPrefecture(
    code: json['code'] as String,
    nameJa: (json['nameJa'] ?? '') as String,
    nameEn: (json['nameEn'] ?? '') as String,
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
  );
}
