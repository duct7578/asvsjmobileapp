import 'package:myasvsj/com.myasvsj.model/map_directions.dart';

/// Một ghim địa điểm trên bản đồ (`places` của `GET /api/map`), ứng với một dòng bảng `places`.
///
/// JSON: `{id, name, nameJa, nameEn, categoryId, lat, lng, source, status, closed, reviewCount, rating, scam, osmId}`.
class MapPlace {
  const MapPlace({
    required this.id,
    required this.name,
    this.nameJa = '',
    this.nameEn = '',
    this.categoryId = 'other',
    required this.lat,
    required this.lng,
    this.source = 'TEAM',
    this.status = 'ACTIVE',
    this.closed = false,
    this.reviewCount = 0,
    this.rating,
    this.scam = false,
    this.osmId,
  });

  final int id;

  /// Tên tiếng Việt (hoặc tên hiển thị).
  final String name;
  final String nameJa;
  final String nameEn;
  final String categoryId;
  final double lat;
  final double lng;

  /// OSM, GOOGLE, TEAM, MODERATOR hoặc USER (ghim cộng đồng, vẽ hình vuông).
  final String source;

  /// ACTIVE, hoặc PENDING khi là ghim của chính mình đang chờ Moderator duyệt.
  final String status;

  /// Moderator đã xác nhận đóng cửa (ghim xám).
  final bool closed;

  /// Số review đã đăng; ghim sáng khi lớn hơn 0.
  final int reviewCount;

  /// Điểm trung bình (một chữ số thập phân); null khi chưa có review.
  final double? rating;

  /// Có bài "Cảnh báo lừa đảo" gắn địa điểm này (dấu "!" trên ghim).
  final bool scam;

  /// Mã OpenStreetMap, ví dụ "N772389775"; null với địa điểm nhóm tự thêm.
  final String? osmId;

  bool get isPending => status == 'PENDING';

  /// Ghim cộng đồng do người dùng cắm.
  bool get isCommunity => source == 'USER';

  /// Ghim sáng (tròn to, có số review): đang hoạt động, có ít nhất 1 review và chưa đóng cửa.
  bool get isLit => reviewCount > 0 && status == 'ACTIVE' && !closed;

  String get directionsUrl => mapDirectionsUrl(lat: lat, lng: lng, name: name);

  factory MapPlace.fromJson(Map<String, dynamic> json) => MapPlace(
    id: json['id'] as int,
    name: (json['name'] ?? '') as String,
    nameJa: (json['nameJa'] ?? '') as String,
    nameEn: (json['nameEn'] ?? '') as String,
    categoryId: (json['categoryId'] ?? 'other') as String,
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    source: (json['source'] ?? 'TEAM') as String,
    status: (json['status'] ?? 'ACTIVE') as String,
    closed: (json['closed'] ?? false) as bool,
    reviewCount: (json['reviewCount'] ?? 0) as int,
    rating: (json['rating'] as num?)?.toDouble(),
    scam: (json['scam'] ?? false) as bool,
    osmId: json['osmId'] as String?,
  );
}
