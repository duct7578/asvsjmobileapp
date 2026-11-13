import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/legal_document.dart';
import 'package:myasvsj/com.myasvsj.model/register_code.dart';
import 'package:myasvsj/com.myasvsj.model/register_request.dart';
import 'package:myasvsj/com.myasvsj.model/register_ticket.dart';
import 'package:myasvsj/com.myasvsj.model/user.dart';

/// Truy cập dữ liệu tài khoản (bảng `users`) và văn bản pháp lý qua REST API của web.
///
/// | Hàm                  | API                                   |
/// |----------------------|---------------------------------------|
/// | login                | POST /api/auth/login                  |
/// | findCurrent          | GET /api/auth/me                      |
/// | logout               | POST /api/auth/logout                 |
/// | sendRegisterCode     | POST /api/auth/register/send-code     |
/// | verifyRegisterCode   | POST /api/auth/register/verify-code   |
/// | completeRegistration | POST /api/auth/register/complete      |
/// | forgotPassword       | POST /api/auth/password/forgot        |
/// | checkResetToken      | POST /api/auth/password/check         |
/// | resetPassword        | POST /api/auth/password/reset         |
/// | hasPassword          | GET /api/me/profile (`hasPassword`)   |
/// | changePassword       | PUT /api/me/password                  |
/// | deleteAccount        | DELETE /api/me                        |
/// | findLegal            | GET /api/legal/{tos|privacy|community} |
class AuthDao {
  AuthDao(this._api);

  final ApiClient _api;

  // ---------------------------------------------------------------- Đăng nhập, phiên

  /// `POST /api/auth/login`: server mở phiên mới, ApiClient lưu cookie `JSESSIONID`.
  /// Sai mật khẩu: 401 "Email hoặc mật khẩu không đúng."; 5 lần sai liền: 423 khóa 30 phút.
  Future<User> login(String email, String password) async {
    final response = await _api.post('/api/auth/login', {'email': email, 'password': password});
    _api.forgetCsrfToken();
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  /// `GET /api/auth/me`: người đang đăng nhập, null khi chưa đăng nhập hoặc phiên đã hết.
  Future<User?> findCurrent() async {
    try {
      return User.fromJson(await _api.get('/api/auth/me') as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        return null;
      }
      rethrow;
    }
  }

  /// `POST /api/auth/logout`: server trả 204 và xóa phiên.
  Future<void> logout() async {
    await _api.post('/api/auth/logout');
    _api.forgetCsrfToken();
  }

  // ---------------------------------------------------------------- Đăng ký bằng email (3 bước)

  /// Bước 1, `POST /api/auth/register/send-code {email}`: gửi mã 6 số tới email.
  /// Server từ chối khi email đã có tài khoản (409) hoặc gửi quá nhanh / quá nhiều (429, "Vui lòng đợi … giây").
  Future<RegisterCode> sendRegisterCode(String email) async {
    final response = await _api.post('/api/auth/register/send-code', {'email': email});
    return RegisterCode.fromJson(response.data as Map<String, dynamic>);
  }

  /// Bước 2, `POST /api/auth/register/verify-code {email, code}`: mã đúng thì nhận vé dùng một lần
  /// và độ dài tối thiểu của mật khẩu.
  Future<RegisterTicket> verifyRegisterCode(String email, String code) async {
    final response = await _api.post('/api/auth/register/verify-code', {'email': email, 'code': code});
    return RegisterTicket.fromJson(response.data as Map<String, dynamic>);
  }

  /// Bước 3, `POST /api/auth/register/complete`: tạo tài khoản và lưu đồng ý điều khoản.
  /// Server KHÔNG mở phiên ("Đăng ký thành công. Hãy đăng nhập."), nên sau đó phải gọi [login].
  Future<User> completeRegistration(RegisterRequest request) async {
    final response = await _api.post('/api/auth/register/complete', request.toJson());
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  // ---------------------------------------------------------------- Quên mật khẩu (UC-U05)

  /// `POST /api/auth/password/forgot {email}`: luôn trả cùng một câu, dù email có tài khoản hay không
  /// ("Nếu email này có tài khoản, chúng tôi đã gửi liên kết…").
  Future<String> forgotPassword(String email) async =>
      (await _api.post('/api/auth/password/forgot', {'email': email})).message;

  /// `POST /api/auth/password/check {token}`: email đã che của tài khoản ("a***@gmail.com") khi liên kết còn dùng
  /// được; liên kết hết hạn hoặc đã dùng thì ném lỗi 400.
  Future<String> checkResetToken(String token) async {
    final response = await _api.post('/api/auth/password/check', {'token': token});
    return ((response.data as Map<String, dynamic>)['email'] ?? '') as String;
  }

  /// `POST /api/auth/password/reset {token, password, confirmPassword}`: đặt mật khẩu mới và đăng xuất mọi thiết bị.
  /// Trả về "Đã đặt lại mật khẩu. Hãy đăng nhập bằng mật khẩu mới.".
  Future<String> resetPassword(String token, String password, String confirmPassword) async => (await _api.post(
    '/api/auth/password/reset',
    {'token': token, 'password': password, 'confirmPassword': confirmPassword},
  )).message;

  // ---------------------------------------------------------------- Đổi mật khẩu (UC-U06), xóa tài khoản

  /// `GET /api/me/profile`, trường `hasPassword`: false khi tài khoản tạo bằng Google/Facebook chưa có mật khẩu
  /// (màn hình thành "Tạo mật khẩu").
  Future<bool> hasPassword() async {
    final data = await _api.get('/api/me/profile') as Map<String, dynamic>;
    return data['hasPassword'] as bool? ?? true;
  }

  /// `PUT /api/me/password {currentPassword, password, confirmPassword}`. [currentPassword] là null khi tạo mật khẩu
  /// lần đầu. Server đổi id phiên và đăng xuất các thiết bị khác, nên token CSRF cũ bỏ đi.
  /// Trả về "Đã đổi mật khẩu." hoặc "Đã tạo mật khẩu. …".
  Future<String> changePassword({
    required String? currentPassword,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _api.put('/api/me/password', {
      'currentPassword': currentPassword,
      'password': password,
      'confirmPassword': confirmPassword,
    });
    _api.forgetCsrfToken();
    return response.message;
  }

  /// `DELETE /api/me`: xóa (ẩn danh) tài khoản đang đăng nhập và kết thúc phiên. Trả về "Đã xóa tài khoản.".
  Future<String> deleteAccount() async {
    final response = await _api.delete('/api/me');
    _api.forgetCsrfToken();
    return response.message;
  }

  // ---------------------------------------------------------------- Văn bản pháp lý

  /// `GET /api/legal/{type}` với type `tos`, `privacy` hoặc `community` (app gọi 'terms' cũng được).
  /// Chưa có văn bản: 404 "Không tìm thấy văn bản …".
  Future<LegalDocument> findLegal(String type) async =>
      LegalDocument.fromJson(await _api.get('/api/legal/${LegalDocument.apiType(type)}') as Map<String, dynamic>);
}
