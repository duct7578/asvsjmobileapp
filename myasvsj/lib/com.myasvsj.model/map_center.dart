/// Một điểm trên bản đồ có mức phóng to và nhãn: nơi bản đồ mở ra (`center` của `GET /api/map`: khu vực của
/// tôi, không có thì Tokyo) hoặc vị trí giả lập của môi trường thử nghiệm (`devLocation`).
///
/// JSON `center`: `{lat, lng, zoom, areaName}`; JSON `devLocation`: `{lat, lng, label}`.
class MapCenter {
  const MapCenter({required this.lat, required this.lng, this.zoom = 12, this.label = ''});

  /// Ga Tokyo: nơi bản đồ mở khi chưa biết khu vực của người xem (giống MapService.TOKYO của web).
  static const tokyo = MapCenter(lat: 35.681236, lng: 139.767125);

  final double lat;
  final double lng;
  final double zoom;

  /// Tên khu vực (ví dụ "Arakawa-ku, Tokyo") hoặc nhãn vị trí giả lập; rỗng khi không có.
  final String label;

  factory MapCenter.fromJson(Map<String, dynamic> json) => MapCenter(
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
    zoom: ((json['zoom'] ?? 12) as num).toDouble(),
    label: (json['areaName'] ?? json['label'] ?? '') as String,
  );

  /// null khi JSON không có (ví dụ `devLocation` ở môi trường thật). Thiếu `zoom` thì phóng to mức 16 (cấp phố).
  static MapCenter? tryParse(Object? json) =>
      json is Map<String, dynamic> ? MapCenter.fromJson({'zoom': 16, ...json}) : null;
}
