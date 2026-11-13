/// Vỏ JSON chung của mọi API web: `{success, message, data, timestamp}` (ApiResponse.java).
class ApiResponse {
  const ApiResponse({required this.success, required this.message, this.data});

  final bool success;

  /// Câu thông báo tiếng Việt của server, ví dụ "Đã lưu thay đổi.".
  final String message;

  /// Phần dữ liệu: một Map, một List, hoặc null.
  final dynamic data;

  /// Đọc body của một response; null khi body không phải ApiResponse
  /// (401 không có body, 403 CSRF của Spring Security, 204 của đăng xuất).
  static ApiResponse? tryParse(dynamic body) {
    if (body is Map<String, dynamic> && body['success'] is bool) {
      return ApiResponse(
        success: body['success'] as bool,
        message: (body['message'] ?? '') as String,
        data: body['data'],
      );
    }
    return null;
  }
}
