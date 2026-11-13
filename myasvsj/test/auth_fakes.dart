import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/auth_dao.dart';
import 'package:myasvsj/com.myasvsj.model/legal_document.dart';
import 'package:myasvsj/com.myasvsj.model/register_code.dart';
import 'package:myasvsj/com.myasvsj.model/register_request.dart';
import 'package:myasvsj/com.myasvsj.model/register_ticket.dart';
import 'package:myasvsj/com.myasvsj.model/user.dart';

/// Người dùng mẫu (role USER) cho test cần trạng thái đã đăng nhập.
const testUser = User(id: 1, email: 'an@example.com', displayName: 'An', role: 'USER', roleLabel: 'Người dùng');

/// DAO đăng nhập giả: mặc định là khách; truyền [current] để bắt đầu ở trạng thái đã đăng nhập.
///
/// Mọi test của mọi tính năng dùng lớp này, nên nó không được hỏng khi AuthDao có thêm hàm:
/// hàm chưa viết ở đây rơi vào [noSuchMethod] (chỉ lỗi khi test thật sự gọi tới).
///
/// Test của agent auth dùng thêm: [failures] (lỗi theo tên hàm), [loginRole], [calls], [legal]…
class FakeAuthDao implements AuthDao {
  FakeAuthDao({this.current});

  User? current;

  /// Lỗi server giả theo tên hàm, ví dụ `{'login': ApiException('Email hoặc mật khẩu không đúng.', statusCode: 401)}`.
  final Map<String, ApiException> failures = {};

  /// Vai trò của tài khoản khi [login]; đặt 'MODERATOR' để thử tài khoản staff.
  String loginRole = 'USER';

  /// Tên các hàm đã được gọi, theo thứ tự.
  final List<String> calls = [];

  /// Dữ liệu Controller đã gửi lên, để test kiểm tra.
  final List<String> codeEmails = [];
  RegisterRequest? registered;
  String? resetToken;
  ({String? current, String password, String confirm})? changed;

  /// Kết quả server giả.
  int resendAfterSeconds = 60;
  int passwordMinLength = 8;
  bool passwordSet = true;
  final Map<String, LegalDocument> legal = {
    'tos': const LegalDocument(type: 'TOS', version: '1.0', content: 'Điều khoản sử dụng Senpai ơi (bản nháp 1.0).'),
  };

  void _call(String name) {
    calls.add(name);
    final error = failures[name];
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<User?> findCurrent() async => current;

  @override
  Future<User> login(String email, String password) async {
    _call('login');
    return current = User(
      id: 1,
      email: email,
      displayName: 'An',
      role: loginRole,
      roleLabel: loginRole == 'USER' ? 'Người dùng' : 'Moderator',
    );
  }

  @override
  Future<void> logout() async {
    calls.add('logout');
    current = null;
  }

  @override
  Future<RegisterCode> sendRegisterCode(String email) async {
    _call('sendRegisterCode');
    codeEmails.add(email);
    return RegisterCode(email: email.toLowerCase(), expiresInMinutes: 10, resendAfterSeconds: resendAfterSeconds);
  }

  @override
  Future<RegisterTicket> verifyRegisterCode(String email, String code) async {
    _call('verifyRegisterCode');
    return RegisterTicket(ticket: 'ticket-1', expiresInMinutes: 30, passwordMinLength: passwordMinLength);
  }

  @override
  Future<User> completeRegistration(RegisterRequest request) async {
    _call('completeRegistration');
    registered = request;
    return User(id: 9, email: 'moi@example.com', displayName: request.displayName, role: 'USER');
  }

  @override
  Future<String> forgotPassword(String email) async {
    _call('forgotPassword');
    return 'Nếu email này có tài khoản, chúng tôi đã gửi liên kết đặt lại mật khẩu. Liên kết có hiệu lực 30 phút.';
  }

  @override
  Future<String> checkResetToken(String token) async {
    _call('checkResetToken');
    resetToken = token;
    return 'a***@example.com';
  }

  @override
  Future<String> resetPassword(String token, String password, String confirmPassword) async {
    _call('resetPassword');
    resetToken = token;
    return 'Đã đặt lại mật khẩu. Hãy đăng nhập bằng mật khẩu mới.';
  }

  @override
  Future<bool> hasPassword() async {
    _call('hasPassword');
    return passwordSet;
  }

  @override
  Future<String> changePassword({
    required String? currentPassword,
    required String password,
    required String confirmPassword,
  }) async {
    _call('changePassword');
    changed = (current: currentPassword, password: password, confirm: confirmPassword);
    final first = !passwordSet;
    passwordSet = true;
    return first ? 'Đã tạo mật khẩu. Từ giờ bạn đăng nhập được bằng email và mật khẩu.' : 'Đã đổi mật khẩu.';
  }

  @override
  Future<String> deleteAccount() async {
    _call('deleteAccount');
    current = null;
    return 'Đã xóa tài khoản.';
  }

  @override
  Future<LegalDocument> findLegal(String type) async {
    _call('findLegal');
    final doc = legal[LegalDocument.apiType(type)];
    if (doc == null) {
      throw ApiException('Không tìm thấy văn bản ${type.toUpperCase()}', statusCode: 404);
    }
    return doc;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
