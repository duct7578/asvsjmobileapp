/// Địa điểm gắn với bài viết ("Địa điểm liên quan"), hoặc một kết quả khi tìm địa điểm trong form viết bài.
///
/// JSON của bài (PlaceRef): `{id, name, category, address, lat, lng, osmId}`.
/// JSON tìm kiếm (`GET /api/places/search`, PlaceOption): `{id, externalId, name, nameJa, category, address, source,
/// lat, lng}`; `id` null là địa điểm OpenStreetMap Senpai ơi chưa có, gửi lên bằng `externalId`.
class BlogPlace {
  const BlogPlace({
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

  /// Địa điểm của Senpai ơi; null khi là địa điểm OpenStreetMap mới (sẽ được thêm khi đăng bài).
  final int? id;

  /// Mã OpenStreetMap, ví dụ "N772389775".
  final String? externalId;
  final String name;
  final String nameJa;
  final String category;
  final String address;

  /// OSM, GOOGLE, TEAM, MODERATOR hoặc USER; rỗng ở địa điểm của bài.
  final String source;
  final double? lat;
  final double? lng;

  /// Địa điểm OpenStreetMap chưa có trên Senpai ơi.
  bool get isNew => id == null;

  /// Khóa để so trùng: cùng địa điểm thì cùng khóa.
  String get key => id != null ? 'p$id' : 'm$externalId';

  /// Dòng phụ dưới tên: loại địa điểm và địa chỉ.
  String get detail => [category, address].where((s) => s.isNotEmpty).join(' · ');

  /// Chỉ đường bằng Google Maps (mở app Google Maps trên điện thoại), như nút "Chỉ đường" của web.
  String get directionsUrl {
    final destination = lat != null && lng != null
        ? '$lat,$lng'
        : [name, address].where((s) => s.isNotEmpty).join(', ');
    return Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': destination}).toString();
  }

  factory BlogPlace.fromJson(Map<String, dynamic> json) => BlogPlace(
    id: json['id'] as int?,
    externalId: (json['externalId'] ?? json['osmId']) as String?,
    name: (json['name'] ?? '') as String,
    nameJa: (json['nameJa'] ?? '') as String,
    category: (json['category'] ?? '') as String,
    address: (json['address'] ?? '') as String,
    source: (json['source'] ?? '') as String,
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
  );
}
