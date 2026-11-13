/// Kết quả bước 2 của đăng ký: mã đúng, server cấp vé dùng một lần cho bước 3 (VerifyCodeResponse của web).
class RegisterTicket {
  const RegisterTicket({required this.ticket, this.expiresInMinutes = 30, this.passwordMinLength = 8});

  /// Vé chứng minh email đã xác thực; gửi kèm ở bước "Tạo tài khoản".
  final String ticket;

  /// Vé còn hiệu lực bao nhiêu phút (cài đặt `register_ticket_minutes`).
  final int expiresInMinutes;

  /// Độ dài tối thiểu của mật khẩu (cài đặt `password_min_length` của Admin).
  final int passwordMinLength;

  factory RegisterTicket.fromJson(Map<String, dynamic> json) => RegisterTicket(
    ticket: json['ticket'] as String,
    expiresInMinutes: (json['expiresInMinutes'] as num? ?? 30).toInt(),
    passwordMinLength: (json['passwordMinLength'] as num? ?? 8).toInt(),
  );
}
