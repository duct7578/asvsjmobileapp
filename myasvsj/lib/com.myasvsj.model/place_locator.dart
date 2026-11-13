import 'package:geolocator/geolocator.dart';

/// Lấy vị trí hiện tại của máy cho nút "Vị trí của tôi" (geolocator). Vị trí chỉ dùng trên máy, không gửi lên server.
///
/// Bọc plugin trong một lớp riêng để test thay bằng lớp giả. Chỉ gọi khi người dùng bấm nút.
class PlaceLocator {
  /// Xin quyền khi cần rồi trả về vị trí; null khi định vị đang tắt, người dùng từ chối quyền, hoặc lỗi.
  Future<({double lat, double lng})?> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      return (lat: position.latitude, lng: position.longitude);
    } catch (_) {
      // Hết giờ chờ, không có plugin, hoặc máy không hỗ trợ
      return null;
    }
  }
}
