// Unit test của AuthController với DAO giả (test/auth_fakes.dart), không cần server.
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/user.dart';

import 'auth_fakes.dart';

void main() {
  late FakeAuthDao dao;
  late AuthController auth;

  setUp(() {
    dao = FakeAuthDao();
    auth = AuthController(dao);
  });

  tearDown(() => auth.dispose());

  group('đăng nhập, phiên', () {
    test('hàm tạo không gọi DAO; bắt đầu là khách', () {
      expect(dao.calls, isEmpty);
      expect(auth.isSignedIn, isFalse);
      expect(auth.currentUser, isNull);
    });

    test('login thành công: bật rồi tắt trạng thái chờ, giữ người dùng', () async {
      final future = auth.login(' an@example.com ', 'abc12345');
      expect(auth.isLoading, isTrue);
      expect(await future, isTrue);
      expect(auth.isLoading, isFalse);
      expect(auth.isSignedIn, isTrue);
      expect(auth.currentUser?.email, 'an@example.com');
      expect(auth.error, isNull);
    });

    test('login thiếu email / mật khẩu: lỗi theo ô, không gọi server', () async {
      expect(await auth.login('  ', ''), isFalse);
      expect(auth.fieldErrors.keys, containsAll(['email', 'password']));
      expect(auth.error, 'Vui lòng nhập email và mật khẩu.');
      expect(dao.calls, isEmpty);
    });

    test('login sai: giữ đúng câu của server (khóa 30 phút)', () async {
      dao.failures['login'] = const ApiException(
        'Bạn đã nhập sai mật khẩu 5 lần. Tài khoản tạm khóa 30 phút.',
        statusCode: 423,
      );
      expect(await auth.login('an@example.com', 'sai'), isFalse);
      expect(auth.error, 'Bạn đã nhập sai mật khẩu 5 lần. Tài khoản tạm khóa 30 phút.');
      expect(auth.bannerError, auth.error);
      expect(auth.isSignedIn, isFalse);
      expect(auth.isLoading, isFalse);
    });

    test('login lỗi theo ô của server: câu đã nằm dưới ô thì không hiện lại ở đầu form', () async {
      dao.failures['login'] = const ApiException(
        'Email không hợp lệ',
        statusCode: 400,
        fields: {'email': 'Email không hợp lệ'},
      );
      await auth.login('abc', '123');
      expect(auth.fieldErrors['email'], 'Email không hợp lệ');
      expect(auth.bannerError, isNull);
    });

    test('login tài khoản staff: đăng xuất phía server, không giữ phiên, báo dùng trang web', () async {
      dao.loginRole = 'MODERATOR';
      expect(await auth.login('moderator@gmail.com', '123456'), isFalse);
      expect(dao.calls, ['login', 'logout']);
      expect(auth.isSignedIn, isFalse);
      expect(auth.error, AuthController.staffMessage);
      expect(dao.current, isNull);
    });

    test('restoreSession: phiên USER còn dùng được', () async {
      dao.current = testUser;
      await auth.restoreSession();
      expect(auth.currentUser?.id, testUser.id);
    });

    test('restoreSession: phiên staff bị đăng xuất, coi là khách', () async {
      dao.current = const User(id: 3, email: 'moderator@gmail.com', displayName: 'Thu', role: 'MODERATOR');
      await auth.restoreSession();
      expect(dao.calls, contains('logout'));
      expect(auth.isSignedIn, isFalse);
    });

    test('logout: về khách và báo cho màn hình', () async {
      dao.current = testUser;
      await auth.restoreSession();
      var notified = 0;
      auth.addListener(() => notified++);
      await auth.logout();
      expect(auth.isSignedIn, isFalse);
      expect(notified, greaterThan(0));
    });

    test('logout vẫn về khách khi server lỗi', () async {
      final failing = _FailingLogoutDao(current: testUser);
      final controller = AuthController(failing);
      await controller.restoreSession();
      await controller.logout();
      expect(controller.isSignedIn, isFalse);
      controller.dispose();
    });
  });

  group('đăng ký', () {
    Future<void> toStep3() async {
      auth.startRegistration();
      await auth.sendRegisterCode('Moi@Example.com');
      await auth.verifyRegisterCode('123456');
    }

    test('bước 1: email sai thì không gọi server', () async {
      auth.startRegistration();
      expect(await auth.sendRegisterCode(''), isFalse);
      expect(auth.fieldErrors['email'], 'Vui lòng nhập email');
      expect(await auth.sendRegisterCode('khong-phai-email'), isFalse);
      expect(auth.fieldErrors['email'], 'Email không hợp lệ');
      expect(dao.calls, isEmpty);
      expect(auth.registerStep, 1);
    });

    test('bước 1 → 2: gửi mã, đếm ngược theo số giây server trả, có câu thông báo', () async {
      dao.resendAfterSeconds = 60;
      auth.startRegistration();
      expect(await auth.sendRegisterCode(' moi@example.com '), isTrue);
      expect(dao.codeEmails, ['moi@example.com']);
      expect(auth.registerStep, 2);
      expect(auth.registerEmail, 'moi@example.com');
      expect(auth.resendSecondsLeft, 60);
      expect(auth.takeMessage(), 'Đã gửi mã xác thực tới moi@example.com.');
      expect(auth.takeMessage(), isNull);
    });

    test('Gửi lại mã bị khóa khi còn đếm ngược; hết giờ thì gửi được', () async {
      dao.resendAfterSeconds = 1;
      auth.startRegistration();
      await auth.sendRegisterCode('moi@example.com');
      expect(await auth.resendRegisterCode(), isFalse);
      expect(dao.codeEmails.length, 1);

      await Future<void>.delayed(const Duration(milliseconds: 1200));
      expect(auth.resendSecondsLeft, 0);
      expect(await auth.resendRegisterCode(), isTrue);
      expect(dao.codeEmails, ['moi@example.com', 'moi@example.com']);
    });

    test('gửi mã bị server từ chối (429): câu hiện dưới ô email', () async {
      dao.failures['sendRegisterCode'] = const ApiException('Vui lòng đợi 51 giây rồi gửi lại mã.', statusCode: 429);
      auth.startRegistration();
      expect(await auth.sendRegisterCode('moi@example.com'), isFalse);
      expect(auth.fieldErrors['email'], 'Vui lòng đợi 51 giây rồi gửi lại mã.');
      expect(auth.bannerError, isNull);
      expect(auth.registerStep, 1);
    });

    test('bước 2: mã không đủ 6 số thì không gọi server', () async {
      auth.startRegistration();
      await auth.sendRegisterCode('moi@example.com');
      expect(await auth.verifyRegisterCode('12a4'), isFalse);
      expect(auth.fieldErrors['code'], 'Mã xác thực gồm 6 chữ số.');
      expect(dao.calls, isNot(contains('verifyRegisterCode')));
    });

    test('bước 2: mã sai hiện câu của server dưới ô mã', () async {
      dao.failures['verifyRegisterCode'] = const ApiException(
        'Mã xác thực không đúng. Bạn còn 4 lần thử.',
        statusCode: 400,
      );
      auth.startRegistration();
      await auth.sendRegisterCode('moi@example.com');
      expect(await auth.verifyRegisterCode('000000'), isFalse);
      expect(auth.fieldErrors['code'], 'Mã xác thực không đúng. Bạn còn 4 lần thử.');
      expect(auth.registerStep, 2);
    });

    test('bước 2 → 3: nhận vé, độ dài mật khẩu theo server, dừng đếm ngược', () async {
      dao.passwordMinLength = 10;
      await toStep3();
      expect(auth.registerStep, 3);
      expect(auth.registerTicket?.ticket, 'ticket-1');
      expect(auth.passwordMinLength, 10);
      expect(auth.resendSecondsLeft, 0);
    });

    test('Đổi email: quay về bước 1', () async {
      auth.startRegistration();
      await auth.sendRegisterCode('moi@example.com');
      auth.changeRegisterEmail();
      expect(auth.registerStep, 1);
      expect(auth.resendSecondsLeft, 0);
    });

    test('bước 3: kiểm tra tên, mật khẩu, xác nhận 18+, điều khoản trước khi gửi', () async {
      await toStep3();
      final ok = await auth.completeRegistration(
        displayName: ' A ',
        password: 'abcdefgh',
        confirmPassword: 'khac',
        adultConfirmed: false,
        acceptTerms: false,
      );
      expect(ok, isFalse);
      expect(auth.fieldErrors, {
        'displayName': 'Tên hiển thị dài từ 2 đến 60 ký tự.',
        'password': 'Mật khẩu phải có cả chữ và số',
        'confirmPassword': 'Hai mật khẩu không khớp.',
        'adultConfirmed': 'Bạn phải từ đủ 18 tuổi để đăng ký.',
        'acceptTerms': 'Bạn cần đồng ý Điều khoản, Chính sách bảo mật và Quy tắc cộng đồng.',
      });
      expect(dao.registered, isNull);
    });

    test('bước 3: mật khẩu ngắn hơn độ dài server yêu cầu', () async {
      dao.passwordMinLength = 10;
      await toStep3();
      await auth.completeRegistration(
        displayName: 'Bạn Mới',
        password: 'abc12345',
        confirmPassword: 'abc12345',
        adultConfirmed: true,
        acceptTerms: true,
      );
      expect(auth.fieldErrors['password'], 'Mật khẩu dài từ 10 đến 72 ký tự');
    });

    test('bước 3: tạo tài khoản rồi tự đăng nhập bằng email + mật khẩu vừa tạo', () async {
      await toStep3();
      final ok = await auth.completeRegistration(
        displayName: '  Bạn Mới ',
        password: 'abc12345',
        confirmPassword: 'abc12345',
        adultConfirmed: true,
        acceptTerms: true,
      );
      expect(ok, isTrue);
      final sent = dao.registered!;
      expect(sent.ticket, 'ticket-1');
      expect(sent.displayName, 'Bạn Mới');
      expect(sent.password, 'abc12345');
      expect(sent.adultConfirmed && sent.acceptTerms, isTrue);
      expect(dao.calls.last, 'login');
      expect(auth.isSignedIn, isTrue);
      expect(auth.currentUser?.email, 'moi@example.com');
      expect(auth.takeMessage(), startsWith('Đăng ký thành công.'));
    });

    test('bước 3: tạo được tài khoản nhưng đăng nhập lỗi → vẫn true, nhắc đăng nhập', () async {
      await toStep3();
      dao.failures['login'] = const ApiException('Không kết nối được tới server.');
      final ok = await auth.completeRegistration(
        displayName: 'Bạn Mới',
        password: 'abc12345',
        confirmPassword: 'abc12345',
        adultConfirmed: true,
        acceptTerms: true,
      );
      expect(ok, isTrue);
      expect(auth.isSignedIn, isFalse);
      expect(auth.takeMessage(), 'Đăng ký thành công. Hãy đăng nhập bằng email và mật khẩu vừa tạo.');
    });

    test('bước 3: vé hết hạn → quay về bước 1 như web', () async {
      await toStep3();
      dao.failures['completeRegistration'] = const ApiException(
        'Phiên đăng ký đã hết hạn. Vui lòng nhập lại email để nhận mã mới.',
        statusCode: 400,
      );
      final ok = await auth.completeRegistration(
        displayName: 'Bạn Mới',
        password: 'abc12345',
        confirmPassword: 'abc12345',
        adultConfirmed: true,
        acceptTerms: true,
      );
      expect(ok, isFalse);
      expect(auth.registerStep, 1);
      expect(auth.bannerError, contains('hết hạn'));
      expect(auth.isSignedIn, isFalse);
    });

    test('bước 3: email vừa được đăng ký ở nơi khác (409) → báo lỗi, giữ bước 3', () async {
      await toStep3();
      dao.failures['completeRegistration'] = const ApiException(
        'Email này đã được đăng ký. Hãy đăng nhập.',
        statusCode: 409,
      );
      await auth.completeRegistration(
        displayName: 'Bạn Mới',
        password: 'abc12345',
        confirmPassword: 'abc12345',
        adultConfirmed: true,
        acceptTerms: true,
      );
      expect(auth.registerStep, 3);
      expect(auth.error, 'Email này đã được đăng ký. Hãy đăng nhập.');
    });
  });

  group('quên mật khẩu', () {
    const link = 'http://localhost:8080/reset-password?token=Rgw3YMVgp66LygwJKdvg30LAOm1P1FXKu8dqiRWs5TU';

    test('tách token từ đường link, từ đoạn chữ, hoặc token dán thẳng', () {
      expect(AuthController.tokenFromLink(link), 'Rgw3YMVgp66LygwJKdvg30LAOm1P1FXKu8dqiRWs5TU');
      expect(
        AuthController.tokenFromLink('Mở liên kết sau:\n\n$link\n\nNếu bạn không yêu cầu…'),
        'Rgw3YMVgp66LygwJKdvg30LAOm1P1FXKu8dqiRWs5TU',
      );
      expect(AuthController.tokenFromLink('https://senpai.vn/reset-password?a=1&token=abc%2Ddef'), 'abc-def');
      expect(
        AuthController.tokenFromLink('  Rgw3YMVgp66LygwJKdvg30LAOm1P1FXKu8dqiRWs5TU '),
        'Rgw3YMVgp66LygwJKdvg30LAOm1P1FXKu8dqiRWs5TU',
      );
      expect(AuthController.tokenFromLink(''), isNull);
      expect(AuthController.tokenFromLink('http://localhost:8080/login'), isNull);
      expect(AuthController.tokenFromLink('xin chào'), isNull);
    });

    test('bước 1: email sai thì không gọi server', () async {
      auth.startForgotPassword();
      expect(await auth.sendResetLink('abc'), isFalse);
      expect(auth.fieldErrors['email'], 'Email không hợp lệ');
      expect(dao.calls, isEmpty);
    });

    test('bước 1 → 2: hiện câu chung của server', () async {
      auth.startForgotPassword();
      expect(await auth.sendResetLink('a@example.com'), isTrue);
      expect(auth.forgotStep, 2);
      expect(auth.forgotNotice, startsWith('Nếu email này có tài khoản'));
    });

    test('bước 2: dán chữ không có token thì không gọi server', () async {
      auth.startForgotPassword();
      auth.goToForgotStep(2);
      expect(await auth.checkResetLink('xin chào'), isFalse);
      expect(auth.fieldErrors['token'], isNotNull);
      expect(dao.calls, isEmpty);
    });

    test('bước 2 → 3: kiểm tra link, hiện email đã che', () async {
      auth.startForgotPassword();
      auth.goToForgotStep(2);
      expect(await auth.checkResetLink(link), isTrue);
      expect(dao.resetToken, 'Rgw3YMVgp66LygwJKdvg30LAOm1P1FXKu8dqiRWs5TU');
      expect(auth.forgotStep, 3);
      expect(auth.resetEmail, 'a***@example.com');
    });

    test('bước 2: link hết hạn → câu của server dưới ô dán link', () async {
      dao.failures['checkResetToken'] = const ApiException(
        'Liên kết đã hết hạn hoặc đã được sử dụng. Hãy yêu cầu liên kết mới.',
        statusCode: 400,
      );
      auth.startForgotPassword();
      auth.goToForgotStep(2);
      expect(await auth.checkResetLink(link), isFalse);
      expect(auth.fieldErrors['token'], contains('hết hạn'));
      expect(auth.forgotStep, 2);
    });

    test('bước 3: mật khẩu sai luật thì không gọi server', () async {
      auth.startForgotPassword();
      auth.goToForgotStep(2);
      await auth.checkResetLink(link);
      expect(await auth.resetPassword('ngan1', 'ngan1'), isFalse);
      expect(auth.fieldErrors['password'], 'Mật khẩu dài từ 8 đến 72 ký tự');
      expect(dao.calls, isNot(contains('resetPassword')));
    });

    test('bước 3: đặt lại xong về bước 1 với câu của server', () async {
      auth.startForgotPassword();
      auth.goToForgotStep(2);
      await auth.checkResetLink(link);
      expect(await auth.resetPassword('reset123', 'reset123'), isTrue);
      expect(dao.resetToken, 'Rgw3YMVgp66LygwJKdvg30LAOm1P1FXKu8dqiRWs5TU');
      expect(auth.forgotStep, 1);
      expect(auth.resetEmail, isNull);
      expect(auth.takeMessage(), 'Đã đặt lại mật khẩu. Hãy đăng nhập bằng mật khẩu mới.');
    });

    test('bước 3: link vừa hết hạn trong lúc nhập → quay lại bước 2', () async {
      auth.startForgotPassword();
      auth.goToForgotStep(2);
      await auth.checkResetLink(link);
      dao.failures['resetPassword'] = const ApiException(
        'Liên kết đã hết hạn hoặc đã được sử dụng. Hãy yêu cầu liên kết mới.',
        statusCode: 400,
      );
      expect(await auth.resetPassword('reset123', 'reset123'), isFalse);
      expect(auth.forgotStep, 2);
      expect(auth.fieldErrors['token'], contains('hết hạn'));
    });
  });

  group('đổi mật khẩu', () {
    setUp(() async {
      dao.current = testUser;
      await auth.restoreSession();
    });

    test('loadPasswordStatus: trạng thái chờ rồi biết đã có mật khẩu', () async {
      final future = auth.loadPasswordStatus();
      expect(auth.isLoading, isTrue);
      expect(auth.hasPassword, isNull);
      await future;
      expect(auth.hasPassword, isTrue);
    });

    test('loadPasswordStatus: phiên hết (401) → về khách', () async {
      dao.failures['hasPassword'] = const ApiException('Bạn chưa đăng nhập.', statusCode: 401);
      await auth.loadPasswordStatus();
      expect(auth.error, 'Bạn chưa đăng nhập.');
      expect(auth.isSignedIn, isFalse);
    });

    test('thiếu mật khẩu hiện tại, mật khẩu mới trùng mật khẩu cũ: không gọi server', () async {
      await auth.loadPasswordStatus();
      expect(
        await auth.changePassword(currentPassword: '', password: 'xyz12345', confirmPassword: 'xyz12345'),
        isFalse,
      );
      expect(auth.fieldErrors['currentPassword'], 'Hãy nhập mật khẩu hiện tại.');
      expect(
        await auth.changePassword(currentPassword: 'abc12345', password: 'abc12345', confirmPassword: 'abc12345'),
        isFalse,
      );
      expect(auth.fieldErrors['password'], 'Mật khẩu mới phải khác mật khẩu hiện tại.');
      expect(dao.calls, isNot(contains('changePassword')));
    });

    test('đổi thành công: gửi đủ 3 trường, giữ câu của server, vẫn đăng nhập', () async {
      await auth.loadPasswordStatus();
      expect(
        await auth.changePassword(currentPassword: 'abc12345', password: 'xyz12345', confirmPassword: 'xyz12345'),
        isTrue,
      );
      expect(dao.changed, (current: 'abc12345', password: 'xyz12345', confirm: 'xyz12345'));
      expect(auth.takeMessage(), 'Đã đổi mật khẩu.');
      expect(auth.isSignedIn, isTrue);
    });

    test('sai mật khẩu hiện tại: lỗi dưới ô currentPassword', () async {
      await auth.loadPasswordStatus();
      dao.failures['changePassword'] = const ApiException(
        'Mật khẩu hiện tại không đúng.',
        statusCode: 400,
        fields: {'currentPassword': 'Mật khẩu hiện tại không đúng.'},
      );
      await auth.changePassword(currentPassword: 'sai', password: 'xyz12345', confirmPassword: 'xyz12345');
      expect(auth.fieldErrors['currentPassword'], 'Mật khẩu hiện tại không đúng.');
      expect(auth.bannerError, isNull);
    });

    test('tài khoản chưa có mật khẩu: "Tạo mật khẩu", không cần mật khẩu hiện tại', () async {
      dao.passwordSet = false;
      await auth.loadPasswordStatus();
      expect(auth.hasPassword, isFalse);
      expect(await auth.changePassword(currentPassword: '', password: 'xyz12345', confirmPassword: 'xyz12345'), isTrue);
      expect(dao.changed?.current, isNull);
      expect(auth.hasPassword, isTrue);
      expect(auth.takeMessage(), startsWith('Đã tạo mật khẩu.'));
    });
  });

  group('xóa tài khoản', () {
    setUp(() async {
      dao.current = testUser;
      await auth.restoreSession();
    });

    test('xóa xong về khách, giữ câu của server', () async {
      final future = auth.deleteAccount();
      expect(auth.isLoading, isTrue);
      expect(await future, isTrue);
      expect(auth.isSignedIn, isFalse);
      expect(auth.takeMessage(), 'Đã xóa tài khoản.');
    });

    test('server lỗi: vẫn đăng nhập, hiện câu lỗi', () async {
      dao.failures['deleteAccount'] = const ApiException('Server gặp lỗi (500). Hãy thử lại sau.', statusCode: 500);
      expect(await auth.deleteAccount(), isFalse);
      expect(auth.isSignedIn, isTrue);
      expect(auth.bannerError, 'Server gặp lỗi (500). Hãy thử lại sau.');
    });
  });

  group('văn bản pháp lý', () {
    test("loadLegal('terms') đọc văn bản TOS, có trạng thái chờ", () async {
      final future = auth.loadLegal('terms');
      expect(auth.isLoadingLegal('terms'), isTrue);
      await future;
      expect(auth.isLoadingLegal('terms'), isFalse);
      expect(auth.legalOf('terms')?.version, '1.0');
      expect(auth.legalOf('tos')?.type, 'TOS');
    });

    test('văn bản chưa có (404): câu gọn gàng thay vì tên kỹ thuật', () async {
      await auth.loadLegal('privacy');
      expect(auth.legalOf('privacy'), isNull);
      expect(auth.legalErrorOf('privacy'), 'Chưa có Chính sách bảo mật. Hãy quay lại sau.');
    });

    test('lỗi mạng: giữ câu của ApiClient', () async {
      dao.failures['findLegal'] = const ApiException('Không kết nối được tới server.');
      await auth.loadLegal('community');
      expect(auth.legalErrorOf('community'), 'Không kết nối được tới server.');
    });
  });

  group('luật mật khẩu', () {
    test('validateNewPassword giống server', () {
      expect(AuthController.validateNewPassword('abc12345', 'abc12345'), isEmpty);
      expect(AuthController.validateNewPassword('12345678', '12345678')['password'], 'Mật khẩu phải có cả chữ và số');
      expect(AuthController.validateNewPassword('a' * 73, 'a' * 73)['password'], 'Mật khẩu dài từ 8 đến 72 ký tự');
      // 40 chữ "ệ" (3 byte mỗi chữ) + số: đủ ký tự nhưng quá 72 byte
      final accented = '${'ệ' * 40}1';
      expect(AuthController.validateNewPassword(accented, accented)['password'], startsWith('Mật khẩu quá dài'));
      expect(AuthController.validateNewPassword('mậtkhẩu1', 'mậtkhẩu1'), isEmpty);
    });

    test('passwordChecklist đánh dấu từng điều kiện', () {
      final checks = AuthController.passwordChecklist('abc', minLength: 8);
      expect(checks.map((c) => c.label), ['Từ 8 ký tự', 'Có chữ', 'Có số']);
      expect(checks.map((c) => c.ok), [false, true, false]);
    });
  });
}

/// DAO giả có đăng xuất lỗi (mất mạng).
class _FailingLogoutDao extends FakeAuthDao {
  _FailingLogoutDao({super.current});

  @override
  Future<void> logout() async => throw const ApiException('Không kết nối được tới server.');
}
