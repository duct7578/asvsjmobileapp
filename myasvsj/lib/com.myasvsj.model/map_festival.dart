/// Một lễ hội / sự kiện có vị trí, vẽ thành ghim đèn lồng (`GET /api/map/events?days=15|30`).
/// Ứng với MapEvent của web; đặt tên khác để không trùng lớp MapEvent của flutter_map.
///
/// JSON: `{id, title, startDate: "2026-11-06", endDate, locationName, lat, lng, daysUntil}`.
class MapFestival {
  const MapFestival({
    required this.id,
    required this.title,
    this.startDate,
    this.endDate,
    this.locationName = '',
    required this.lat,
    required this.lng,
    this.daysUntil = 0,
  });

  final int id;
  final String title;
  final DateTime? startDate;
  final DateTime? endDate;
  final String locationName;
  final double lat;
  final double lng;

  /// Số ngày nữa thì bắt đầu (giờ Nhật); 0 khi đang diễn ra.
  final int daysUntil;

  /// Nhãn dưới ghim, giống web: "Đang diễn ra" hoặc "Còn N ngày".
  String get whenLabel => daysUntil <= 0 ? 'Đang diễn ra' : 'Còn $daysUntil ngày';

  factory MapFestival.fromJson(Map<String, dynamic> json) => MapFestival(
    id: json['id'] as int,
    title: (json['title'] ?? '') as String,
    startDate: DateTime.tryParse((json['startDate'] ?? '') as String),
    endDate: DateTime.tryParse((json['endDate'] ?? '') as String),
    locationName: (json['locationName'] ?? '') as String,
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    daysUntil: ((json['daysUntil'] ?? 0) as num).toInt(),
  );
}
