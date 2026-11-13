// Cách hiện khoảng cách trên bản đồ (kiểu Việt Nam: dấu phẩy thập phân).

/// Khoảng cách, ví dụ "80 m", "1,2 km"; rỗng khi chưa biết.
String formatMapDistance(double? meters) {
  if (meters == null) {
    return '';
  }
  if (meters < 1000) {
    return '${meters.round()} m';
  }
  final km = meters / 1000;
  return '${km.toStringAsFixed(km < 10 ? 1 : 0).replaceAll('.', ',')} km';
}
