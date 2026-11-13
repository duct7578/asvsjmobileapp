import 'package:myasvsj/com.myasvsj.model/map_directions.dart';

/// Một kết quả tìm địa điểm (PlaceOption của web): địa điểm Senpai ơi (có [id]) hoặc địa điểm OpenStreetMap
/// chưa có trên Senpai ơi ([id] null, có [externalId]).
///
/// JSON: `{id, externalId, name, nameJa, category, address, source, lat, lng}`.
class PlaceOption {
  const PlaceOption({
    this.id,
    this.externalId,
    required this.name,
    this.nameJa = '',
    this.category = '',
    this.address = '',
    this.source = '',
    this.lat,
    this.lng,
  });

  final int? id;

  /// Mã OpenStreetMap ("N772389775"); gửi lên làm `externalPlaceId` khi viết review đầu tiên cho nơi này.
  final String? externalId;
  final String name;
  final String nameJa;

  /// Tên danh mục, ví dụ "Ga tàu".
  final String category;
  final String address;
  final String source;
  final double? lat;
  final double? lng;

  /// Địa điểm đã có trên Senpai ơi.
  bool get isOnSenpai => id != null;

  String get directionsUrl => mapDirectionsUrl(lat: lat, lng: lng, name: name, address: address);

  factory PlaceOption.fromJson(Map<String, dynamic> json) => PlaceOption(
    id: json['id'] as int?,
    externalId: json['externalId'] as String?,
    name: (json['name'] ?? '') as String,
    nameJa: (json['nameJa'] ?? '') as String,
    category: (json['category'] ?? '') as String,
    address: (json['address'] ?? '') as String,
    source: (json['source'] ?? '') as String,
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
  );
}
