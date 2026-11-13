import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/auth_dao.dart';
import 'package:myasvsj/com.myasvsj.model/legal_document.dart';
import 'package:myasvsj/com.myasvsj.model/register_code.dart';
import 'package:myasvsj/com.myasvsj.model/register_request.dart';
import 'package:myasvsj/com.myasvsj.model/register_ticket.dart';
import 'package:myasvsj/com.myasvsj.model/user.dart';

/// Controller của tài khoản: giữ người đang đăng nhập cho mọi màn hình, và trạng thái các màn hình
/// Đăng nhập, Đăng ký (3 bước), Quên mật khẩu, Đổi / tạo mật khẩu, Xóa tài khoản, Văn bản pháp lý.
///
/// Màn hình khác chỉ dùng [isSignedIn], [currentUser] và [logout].
/// App chỉ dành cho role USER: tài khoản staff bị đăng xuất ngay và nhận [staffMessage].
class AuthController extends ChangeNotifier {
  AuthController(this._dao);

  final AuthDao _dao;

  /// Câu báo khi tài khoản staff (Moderator, Academic Manager, Admin) đăng nhập vào app.
  static const String staffMessage = 'Tài khoản quản lý chỉ dùng trên trang web. Hãy đăng nhập bằng trình duyệt.';

  /// Luật nhập liệu, giống AuthDtos / PasswordService của server (server vẫn kiểm tra lại).
  static const int defaultPasswordMinLength = 8;
  static const int passwordMaxLength = 72;
  static const int displayNameMin = 2;
  static const int displayNameMax = 60;
  static const int codeLength = 6;
  static const int emailMax = 255;

  // ----- Phiên đăng nhập
  User? currentUser;

  bool get isSignedIn => currentUser != null;

  // ----- Form đang mở (đăng nhập, đăng ký, quên / đổi mật khẩu, xóa tài khoản)
  bool isLoading = false;

  /// Câu báo lỗi của server (hoặc của app) cho form đang mở.
  String? error;

  /// Lỗi theo từng ô nhập: 'email', 'password', 'confirmPassword', 'currentPassword', 'code', 'displayName',
  /// 'adultConfirmed', 'acceptTerms', 'token'.
  Map<String, String> fieldErrors = {};

  /// Câu thông báo sau khi làm xong; màn hình hiện một lần bằng [takeMessage].
  String? message;

  // ----- Đăng ký (RegisterScreen): 1 email → 2 mã xác thực → 3 tên + mật khẩu
  int registerStep = 1;
  RegisterCode? registerCode;
  RegisterTicket? registerTicket;

  /// Số giây còn phải đợi mới được bấm "Gửi lại mã" (đếm ngược theo `resendAfterSeconds` của server).
  int resendSecondsLeft = 0;
  Timer? _resendTimer;

  // ----- Quên mật khẩu (ForgotPasswordScreen): 1 email → 2 dán đường link → 3 mật khẩu mới
  int forgotStep = 1;

  /// Câu server trả sau khi gửi liên kết (luôn giống nhau dù email có tài khoản hay không).
  String? forgotNotice;

  /// Email đã che của tài khoản ("a***@gmail.com") khi đường link còn dùng được.
  String? resetEmail;
  String? _resetToken;

  // ----- Đổi mật khẩu (ChangePasswordScreen): null khi chưa biết
  bool? hasPassword;

  // ----- Văn bản pháp lý (LegalScreen), theo loại của server: tos, privacy, community
  final Map<String, LegalDocument> _legalDocs = {};
  final Set<String> _legalLoading = {};
  final Map<String, String> _legalErrors = {};

  /// Câu lỗi cần hiện ở đầu form: bỏ qua khi câu đó đã nằm dưới một ô nhập.
  String? get bannerError => error != null && !fieldErrors.values.contains(error) ? error : null;

  /// Lấy câu thông báo để hiện SnackBar, rồi xóa để không hiện lại lần nữa.
  String? takeMessage() {
    final text = message;
    message = null;
    return text;
  }

  /// Xóa lỗi của form trước (gọi khi mở hoặc quay lại một màn hình).
  void clearForm() {
    error = null;
    fieldErrors = {};
    notifyListeners();
  }

  // ---------------------------------------------------------------- Đăng nhập, phiên

  /// Lúc mở app: hỏi server phiên cũ (cookie đã lưu trên máy) còn dùng được không.
  /// Phiên của tài khoản staff bị đăng xuất, app coi như khách.
  Future<void> restoreSession() async {
    try {
      final user = await _dao.findCurrent();
      if (user != null && !user.isMember) {
        await _logoutQuietly();
        currentUser = null;
      } else {
        currentUser = user;
      }
    } on ApiException {
      currentUser = null;
    }
    notifyListeners();
  }

  /// Đăng nhập bằng email; trả về true khi thành công.
  /// Sai mật khẩu, tài khoản bị khóa 30 phút… hiện đúng câu của server ở [error].
  Future<bool> login(String email, String password) async {
    final errors = <String, String>{
      if (email.trim().isEmpty) 'email': 'Vui lòng nhập email',
      if (password.isEmpty) 'password': 'Vui lòng nhập mật khẩu',
    };
    if (errors.isNotEmpty) {
      return _invalid(errors, summary: 'Vui lòng nhập email và mật khẩu.');
    }
    return _submit(() => _signIn(email.trim(), password));
  }

  Future<void> logout() async {
    await _logoutQuietly();
    currentUser = null;
    hasPassword = null;
    notifyListeners();
  }

  Future<void> _signIn(String email, String password) async {
    final user = await _dao.login(email, password);
    if (!user.isMember) {
      // App chỉ dành cho người dùng: đóng phiên vừa mở trên server, không giữ lại
      await _logoutQuietly();
      currentUser = null;
      throw const ApiException(staffMessage, statusCode: 403);
    }
    currentUser = user;
  }

  Future<void> _logoutQuietly() async {
    try {
      await _dao.logout();
    } on ApiException {
      // Phiên đã hết hoặc mất mạng: trên app vẫn coi như đã đăng xuất
    }
  }

  // ---------------------------------------------------------------- Đăng ký bằng email

  /// Mở màn Đăng ký: về bước 1, bỏ mã và vé cũ.
  void startRegistration() {
    registerStep = 1;
    registerCode = null;
    registerTicket = null;
    _stopResendCountdown();
    error = null;
    fieldErrors = {};
    notifyListeners();
  }

  /// Email đang đăng ký, như server đã chuẩn hóa.
  String get registerEmail => registerCode?.email ?? '';

  /// Độ dài tối thiểu của mật khẩu: server gửi kèm bước 2, trước đó là 8.
  int get passwordMinLength => registerTicket?.passwordMinLength ?? defaultPasswordMinLength;

  /// Bước 1 → 2: gửi mã 6 số tới [email].
  Future<bool> sendRegisterCode(String email) async {
    final value = email.trim();
    final problem = validateEmail(value);
    if (problem != null) {
      return _invalid({'email': problem});
    }
    return _submit(() async {
      final sent = await _dao.sendRegisterCode(value);
      registerCode = sent;
      registerTicket = null;
      registerStep = 2;
      _startResendCountdown(sent.resendAfterSeconds);
      message = 'Đã gửi mã xác thực tới ${sent.email}.';
    }, field: 'email');
  }

  /// "Gửi lại mã" ở bước 2; không gọi server khi chưa hết thời gian đợi.
  Future<bool> resendRegisterCode() async {
    final sent = registerCode;
    if (sent == null || resendSecondsLeft > 0) {
      return false;
    }
    return _submit(() async {
      final again = await _dao.sendRegisterCode(sent.email);
      registerCode = again;
      _startResendCountdown(again.resendAfterSeconds);
      message = 'Đã gửi mã xác thực tới ${again.email}.';
    }, field: 'code');
  }

  /// Nút "Đổi" email ở bước 2: quay về bước 1.
  void changeRegisterEmail() {
    registerStep = 1;
    _stopResendCountdown();
    error = null;
    fieldErrors = {};
    notifyListeners();
  }

  /// Bước 2 → 3: kiểm tra mã 6 số, nhận vé và độ dài tối thiểu của mật khẩu.
  Future<bool> verifyRegisterCode(String code) async {
    final sent = registerCode;
    final value = code.trim();
    if (sent == null) {
      registerStep = 1;
      return _invalid({}, summary: 'Hãy nhập email để nhận mã xác thực.');
    }
    if (!RegExp('^\\d{$codeLength}\$').hasMatch(value)) {
      return _invalid({'code': 'Mã xác thực gồm $codeLength chữ số.'});
    }
    return _submit(() async {
      registerTicket = await _dao.verifyRegisterCode(sent.email, value);
      registerStep = 3;
      _stopResendCountdown();
      message = 'Email đã được xác thực. Hãy tạo mật khẩu.';
    }, field: 'code');
  }

  /// Bước 3: tạo tài khoản rồi đăng nhập luôn bằng email và mật khẩu vừa tạo (server không tự mở phiên).
  /// Trả về true khi tài khoản đã được tạo; [isSignedIn] cho biết đã đăng nhập được chưa.
  Future<bool> completeRegistration({
    required String displayName,
    required String password,
    required String confirmPassword,
    required bool adultConfirmed,
    required bool acceptTerms,
  }) async {
    final sent = registerCode;
    final ticket = registerTicket;
    if (sent == null || ticket == null) {
      registerStep = 1;
      return _invalid({}, summary: 'Phiên đăng ký đã hết hạn. Vui lòng nhập lại email để nhận mã mới.');
    }
    final errors = validateRegistration(
      displayName: displayName,
      password: password,
      confirmPassword: confirmPassword,
      adultConfirmed: adultConfirmed,
      acceptTerms: acceptTerms,
      minLength: passwordMinLength,
    );
    if (errors.isNotEmpty) {
      return _invalid(errors);
    }
    return _submit(() async {
      try {
        await _dao.completeRegistration(
          RegisterRequest(
            ticket: ticket.ticket,
            displayName: displayName.trim(),
            password: password,
            adultConfirmed: adultConfirmed,
            acceptTerms: acceptTerms,
          ),
        );
      } on ApiException catch (e) {
        // Vé hết hạn: phải nhận mã mới, như trang web
        if (e.statusCode == 400 && e.fields.isEmpty && e.message.contains('hết hạn')) {
          registerStep = 1;
          registerTicket = null;
        }
        rethrow;
      }
      registerStep = 1;
      registerTicket = null;
      try {
        await _signIn(sent.email, password);
        message = 'Đăng ký thành công. Chào mừng bạn đến với Senpai ơi!';
      } on ApiException {
        message = 'Đăng ký thành công. Hãy đăng nhập bằng email và mật khẩu vừa tạo.';
      }
    });
  }

  void _startResendCountdown(int seconds) {
    _resendTimer?.cancel();
    resendSecondsLeft = seconds < 0 ? 0 : seconds;
    if (resendSecondsLeft == 0) {
      return;
    }
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      resendSecondsLeft = resendSecondsLeft > 0 ? resendSecondsLeft - 1 : 0;
      if (resendSecondsLeft == 0) {
        timer.cancel();
        _resendTimer = null;
      }
      notifyListeners();
    });
  }

  void _stopResendCountdown() {
    _resendTimer?.cancel();
    _resendTimer = null;
    resendSecondsLeft = 0;
  }

  // ---------------------------------------------------------------- Quên mật khẩu

  /// Mở màn Quên mật khẩu: về bước 1.
  void startForgotPassword() {
    forgotStep = 1;
    forgotNotice = null;
    resetEmail = null;
    _resetToken = null;
    error = null;
    fieldErrors = {};
    notifyListeners();
  }

  /// Chuyển bước bằng tay: "Tôi đã có đường link" (2) hoặc "Gửi lại liên kết" (1).
  void goToForgotStep(int step) {
    forgotStep = step.clamp(1, 2);
    resetEmail = null;
    _resetToken = null;
    error = null;
    fieldErrors = {};
    notifyListeners();
  }

  /// Bước 1 → 2: xin liên kết đặt lại mật khẩu cho [email].
  Future<bool> sendResetLink(String email) async {
    final value = email.trim();
    final problem = validateEmail(value);
    if (problem != null) {
      return _invalid({'email': problem});
    }
    return _submit(() async {
      forgotNotice = await _dao.forgotPassword(value);
      forgotStep = 2;
    }, field: 'email');
  }

  /// Bước 2 → 3: tách token từ đường link người dùng dán vào và hỏi server link còn dùng được không.
  Future<bool> checkResetLink(String link) async {
    final token = tokenFromLink(link);
    if (token == null) {
      return _invalid({'token': 'Hãy dán đường link trong email (dạng …/reset-password?token=…).'});
    }
    return _submit(() async {
      resetEmail = await _dao.checkResetToken(token);
      _resetToken = token;
      forgotStep = 3;
    }, field: 'token');
  }

  /// Bước 3: đặt mật khẩu mới. Xong thì về bước 1, câu của server nằm ở [message].
  Future<bool> resetPassword(String password, String confirmPassword) async {
    final token = _resetToken;
    if (token == null) {
      forgotStep = 2;
      return _invalid({'token': 'Hãy dán đường link trong email.'});
    }
    final errors = validateNewPassword(password, confirmPassword);
    if (errors.isNotEmpty) {
      return _invalid(errors);
    }
    return _submit(() async {
      try {
        message = await _dao.resetPassword(token, password, confirmPassword);
      } on ApiException catch (e) {
        // Liên kết vừa hết hạn hoặc đã được dùng: quay lại bước dán link
        if (e.statusCode == 400 && e.fields.isEmpty) {
          forgotStep = 2;
          resetEmail = null;
          _resetToken = null;
          throw ApiException(e.message, statusCode: e.statusCode, fields: {'token': e.message});
        }
        rethrow;
      }
      forgotStep = 1;
      forgotNotice = null;
      resetEmail = null;
      _resetToken = null;
    });
  }

  /// Token trong đường link `…/reset-password?token=…` (dán cả đoạn chữ cũng được), hoặc chính token khi người
  /// dùng chỉ dán token. Null khi không tìm thấy.
  static String? tokenFromLink(String input) {
    final text = input.trim();
    if (text.isEmpty) {
      return null;
    }
    final match = RegExp(r'[?&]token=([A-Za-z0-9_\-%]+)').firstMatch(text);
    if (match != null) {
      try {
        return Uri.decodeComponent(match.group(1)!);
      } on ArgumentError {
        return null;
      }
    }
    return RegExp(r'^[A-Za-z0-9_\-]{16,200}$').hasMatch(text) ? text : null;
  }

  // ---------------------------------------------------------------- Đổi / tạo mật khẩu

  /// Mở màn Đổi mật khẩu: hỏi server tài khoản đã có mật khẩu chưa (chưa có thì là "Tạo mật khẩu").
  Future<void> loadPasswordStatus() async {
    hasPassword = null;
    isLoading = true;
    error = null;
    fieldErrors = {};
    notifyListeners();
    try {
      hasPassword = await _dao.hasPassword();
    } on ApiException catch (e) {
      error = e.message;
      if (e.isUnauthorized) {
        currentUser = null;
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Lưu mật khẩu mới. Server đăng xuất các thiết bị khác; máy này giữ phiên (id mới).
  Future<bool> changePassword({
    required String currentPassword,
    required String password,
    required String confirmPassword,
  }) async {
    final first = hasPassword == false;
    final errors = <String, String>{
      if (!first && currentPassword.isEmpty) 'currentPassword': 'Hãy nhập mật khẩu hiện tại.',
      ...validateNewPassword(password, confirmPassword),
    };
    if (!first && currentPassword.isNotEmpty && !errors.containsKey('password') && password == currentPassword) {
      errors['password'] = 'Mật khẩu mới phải khác mật khẩu hiện tại.';
    }
    if (errors.isNotEmpty) {
      return _invalid(errors);
    }
    return _submit(() async {
      try {
        message = await _dao.changePassword(
          currentPassword: first ? null : currentPassword,
          password: password,
          confirmPassword: confirmPassword,
        );
      } on ApiException catch (e) {
        if (e.isUnauthorized) {
          currentUser = null;
        }
        rethrow;
      }
      hasPassword = true;
    });
  }

  // ---------------------------------------------------------------- Xóa tài khoản

  /// Xóa tài khoản đang đăng nhập. Xong thì app về trạng thái khách; câu của server nằm ở [message].
  Future<bool> deleteAccount() async {
    return _submit(() async {
      try {
        message = await _dao.deleteAccount();
      } on ApiException catch (e) {
        if (e.isUnauthorized) {
          currentUser = null;
        }
        rethrow;
      }
      currentUser = null;
      hasPassword = null;
    });
  }

  // ---------------------------------------------------------------- Văn bản pháp lý

  LegalDocument? legalOf(String type) => _legalDocs[LegalDocument.apiType(type)];

  bool isLoadingLegal(String type) => _legalLoading.contains(LegalDocument.apiType(type));

  String? legalErrorOf(String type) => _legalErrors[LegalDocument.apiType(type)];

  /// Tải văn bản [type] ('terms' | 'privacy' | 'community'); văn bản đã tải vẫn hiện trong lúc tải lại.
  Future<void> loadLegal(String type) async {
    final key = LegalDocument.apiType(type);
    _legalLoading.add(key);
    _legalErrors.remove(key);
    notifyListeners();
    try {
      _legalDocs[key] = await _dao.findLegal(key);
    } on ApiException catch (e) {
      _legalErrors[key] = e.statusCode == 404 ? 'Chưa có ${LegalDocument.titleOf(key)}. Hãy quay lại sau.' : e.message;
    } finally {
      _legalLoading.remove(key);
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- Kiểm tra nhập

  /// Lỗi của ô email, null khi hợp lệ.
  static String? validateEmail(String email) {
    final value = email.trim();
    if (value.isEmpty) {
      return 'Vui lòng nhập email';
    }
    if (value.length > emailMax || !RegExp(r'^[^\s@]+@[^\s@]+$').hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  /// Luật mật khẩu mới của server: [minLength]–72 ký tự, tối đa 72 byte (BCrypt), có chữ và số, nhập lại khớp.
  static Map<String, String> validateNewPassword(
    String password,
    String confirmPassword, {
    int minLength = defaultPasswordMinLength,
  }) {
    final errors = <String, String>{};
    if (password.length < minLength || password.length > passwordMaxLength) {
      errors['password'] = 'Mật khẩu dài từ $minLength đến $passwordMaxLength ký tự';
    } else if (utf8.encode(password).length > passwordMaxLength) {
      errors['password'] = 'Mật khẩu quá dài (chữ có dấu được tính 2–3 ký tự). Hãy dùng mật khẩu ngắn hơn';
    } else if (!hasLetter(password) || !hasDigit(password)) {
      errors['password'] = 'Mật khẩu phải có cả chữ và số';
    }
    if (password != confirmPassword) {
      errors['confirmPassword'] = 'Hai mật khẩu không khớp.';
    }
    return errors;
  }

  /// Bước 3 của đăng ký: tên 2–60 ký tự, mật khẩu, đủ 18 tuổi, đồng ý điều khoản.
  static Map<String, String> validateRegistration({
    required String displayName,
    required String password,
    required String confirmPassword,
    required bool adultConfirmed,
    required bool acceptTerms,
    int minLength = defaultPasswordMinLength,
  }) {
    final name = displayName.trim();
    return {
      if (name.length < displayNameMin || name.length > displayNameMax)
        'displayName': 'Tên hiển thị dài từ $displayNameMin đến $displayNameMax ký tự.',
      ...validateNewPassword(password, confirmPassword, minLength: minLength),
      if (!adultConfirmed) 'adultConfirmed': 'Bạn phải từ đủ 18 tuổi để đăng ký.',
      if (!acceptTerms) 'acceptTerms': 'Bạn cần đồng ý Điều khoản, Chính sách bảo mật và Quy tắc cộng đồng.',
    };
  }

  /// Danh sách điều kiện để màn hình đánh dấu khi đang gõ: "Từ 8 ký tự", "Có chữ", "Có số".
  static List<({String label, bool ok})> passwordChecklist(
    String password, {
    int minLength = defaultPasswordMinLength,
  }) => [
    (label: 'Từ $minLength ký tự', ok: password.length >= minLength && password.length <= passwordMaxLength),
    (label: 'Có chữ', ok: hasLetter(password)),
    (label: 'Có số', ok: hasDigit(password)),
  ];

  static bool hasLetter(String value) => RegExp(r'\p{L}', unicode: true).hasMatch(value);

  static bool hasDigit(String value) => RegExp(r'\d').hasMatch(value);

  // ---------------------------------------------------------------- Chung

  /// Dữ liệu nhập sai: hiện lỗi theo ô, không gọi server.
  bool _invalid(Map<String, String> errors, {String? summary}) {
    fieldErrors = errors;
    error = summary;
    notifyListeners();
    return false;
  }

  /// Gửi một form: bật trạng thái chờ, xóa lỗi cũ, giữ câu lỗi và lỗi theo ô của server.
  /// Lỗi không gắn với ô nào thì hiện dưới ô [field] (nếu có).
  Future<bool> _submit(Future<void> Function() action, {String? field}) async {
    if (isLoading) {
      return false;
    }
    isLoading = true;
    error = null;
    fieldErrors = {};
    notifyListeners();
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      error = e.message;
      fieldErrors = e.fields.isEmpty && field != null ? {field: e.message} : Map.of(e.fields);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }
}
