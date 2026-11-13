/// Kết quả bước 1 của đăng ký: mã 6 số đã được gửi tới email (SendCodeResponse của web).
class RegisterCode {
  const RegisterCode({required this.email, this.expiresInMinutes = 10, this.resendAfterSeconds = 60});

  /// Email như server đã chuẩn hóa (bỏ khoảng trắng, chữ thường).
  final String email;

  /// Mã còn hiệu lực bao nhiêu phút (cài đặt `email_code_minutes`).
  final int expiresInMinutes;

  /// Phải đợi bao nhiêu giây mới được gửi lại mã (cài đặt `email_code_resend_seconds`).
  final int resendAfterSeconds;

  factory RegisterCode.fromJson(Map<String, dynamic> json) => RegisterCode(
    email: (json['email'] ?? '') as String,
    expiresInMinutes: (json['expiresInMinutes'] as num? ?? 10).toInt(),
    resendAfterSeconds: (json['resendAfterSeconds'] as num? ?? 60).toInt(),
  );
}
