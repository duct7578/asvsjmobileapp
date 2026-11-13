/// Một khu vực sống: thành phố, thị trấn hoặc quận của 20 thành phố lớn (bảng `areas`).
///
/// JSON: `{id, prefectureCode, nameJa, nameEn, name, lat, lng}` (AreaOption của `/api/areas/...`).
class AreaOption {
  const AreaOption({
    required this.id,
    required this.prefectureCode,
    this.nameJa = '',
    this.nameEn = '',
    this.name = '',
    this.lat,
    this.lng,
  });

  final int id;

  /// Mã tỉnh, ví dụ "13".
  final String prefectureCode;

  /// Ví dụ "荒川区".
  final String nameJa;

  /// Ví dụ "Arakawa-ku" hoặc "Kita-ku, Osaka-shi".
  final String nameEn;

  /// Tên đầy đủ, ví dụ "Arakawa-ku, Tokyo · 東京都荒川区".
  final String name;
  final double? lat;
  final double? lng;

  /// Tên ngắn trong danh sách của một tỉnh, ví dụ "Arakawa-ku · 荒川区".
  String get label => '$nameEn · $nameJa';

  factory AreaOption.fromJson(Map<String, dynamic> json) => AreaOption(
    id: json['id'] as int,
    prefectureCode: (json['prefectureCode'] ?? '') as String,
    nameJa: (json['nameJa'] ?? '') as String,
    nameEn: (json['nameEn'] ?? '') as String,
    name: (json['name'] ?? '') as String,
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
  );
}
