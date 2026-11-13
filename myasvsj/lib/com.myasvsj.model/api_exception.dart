/// Lỗi khi gọi server: server từ chối (có câu thông báo tiếng Việt) hoặc không tới được server.
///
/// Controller bắt lỗi này và đưa [message] cho màn hình hiện thẳng cho người dùng.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.fields = const {}});

  /// Câu thông báo của server, ví dụ "Bạn không có quyền thực hiện thao tác này." (MSG18).
  final String message;

  /// Mã HTTP (400, 401, 403, 404…); null khi không tới được server.
  final int? statusCode;

  /// Lỗi theo từng ô nhập, ví dụ {'title': 'Hãy nhập tiêu đề…'}; rỗng khi lỗi không gắn với ô nào.
  final Map<String, String> fields;

  /// Chưa đăng nhập hoặc phiên đã hết hạn.
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
