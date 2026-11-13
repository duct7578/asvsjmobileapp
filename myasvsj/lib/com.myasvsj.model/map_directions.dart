// Đường dẫn chỉ đường Google Maps và khoảng cách giữa hai điểm, dùng chung cho ghim, kết quả tìm và chi tiết địa điểm.
import 'dart:math' as math;

/// Đường dẫn "Chỉ đường" của Google Maps (không cần khóa API, mở app Google Maps trên điện thoại), giống
/// `googleDirectionsUrl` của web: theo tọa độ khi có, không thì theo tên và địa chỉ.
String mapDirectionsUrl({double? lat, double? lng, String name = '', String? address}) {
  final destination = lat != null && lng != null
      ? '$lat,$lng'
      : [name, address].where((s) => s != null && s.isNotEmpty).join(', ');
  return Uri.https('www.google.com', '/maps/dir/', {'api': '1', 'destination': destination}).toString();
}

/// Khoảng cách (mét) giữa hai điểm trên mặt đất, công thức haversine.
double mapDistanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0;
  double rad(double degree) => degree * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * earthRadius * math.asin(math.min(1, math.sqrt(a)));
}
