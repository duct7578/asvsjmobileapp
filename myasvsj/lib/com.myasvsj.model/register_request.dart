/// Bước 3 của đăng ký: tên hiển thị, mật khẩu và hai xác nhận (CompleteRegistrationRequest của web).
///
/// Mật khẩu nhập lại chỉ được so trên app (server không nhận ô này), như trang web.
class RegisterRequest {
  const RegisterRequest({
    required this.ticket,
    required this.displayName,
    required this.password,
    required this.adultConfirmed,
    required this.acceptTerms,
  });

  final String ticket;
  final String displayName;
  final String password;

  /// "Tôi xác nhận mình đã đủ 18 tuổi."
  final bool adultConfirmed;

  /// Đồng ý Điều khoản sử dụng, Chính sách bảo mật và Quy tắc cộng đồng.
  final bool acceptTerms;

  Map<String, dynamic> toJson() => {
    'ticket': ticket,
    'displayName': displayName,
    'password': password,
    'adultConfirmed': adultConfirmed,
    'acceptTerms': acceptTerms,
  };
}
