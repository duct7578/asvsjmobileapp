/// Vị trí cố định mà "Vị trí của tôi" dùng ở môi trường thử của server (`app.map.dev-location`), vì máy thử
/// thường không ở Nhật. Null ở server thật.
///
/// JSON: `{lat, lng, label}` (DevLocation trong `GET /api/areas`).
class AreaDevLocation {
  const AreaDevLocation({required this.lat, required this.lng, this.label = ''});

  final double lat;
  final double lng;
  final String label;

  /// null khi JSON không có vị trí thử.
  static AreaDevLocation? tryParse(Object? json) => json is Map<String, dynamic>
      ? AreaDevLocation(
          lat: (json['lat'] as num).toDouble(),
          lng: (json['lng'] as num).toDouble(),
          label: (json['label'] ?? '') as String,
        )
      : null;
}
