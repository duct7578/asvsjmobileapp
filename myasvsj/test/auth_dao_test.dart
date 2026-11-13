// Test AuthDao với server giả: đúng phương thức, đường dẫn, body; đọc đúng JSON chép từ server thật
// (curl tới http://localhost:8080, 2026-11-08); ném ApiException mang câu của server khi lỗi.
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/auth_dao.dart';
import 'package:myasvsj/com.myasvsj.model/register_request.dart';

import 'fake_api.dart';

// ----- JSON thật (phần `data`)
const userJson = {
  'id': 2,
  'email': 'user@gmail.com',
  'displayName': 'Trần Minh',
  'role': 'USER',
  'roleLabel': 'Người dùng',
  'homePath': '/',
  'avatarUrl': null,
};
const moderatorJson = {
  'id': 3,
  'email': 'moderator@gmail.com',
  'displayName': 'Thu',
  'role': 'MODERATOR',
  'roleLabel': 'Moderator',
  'homePath': '/moderator',
  'avatarUrl': null,
};
const sendCodeJson = {'email': 'auth-1794077554@example.com', 'expiresInMinutes': 10, 'resendAfterSeconds': 60};
const verifyCodeJson = {
  'ticket': 'RCCeUtPd_DJAdkDDUjNq-IUmCLsdiAj1H34f2dF3-sM',
  'expiresInMinutes': 30,
  'passwordMinLength': 8,
};
const forgotMessage =
    'Nếu email này có tài khoản, chúng tôi đã gửi liên kết đặt lại mật khẩu. Liên kết có hiệu lực 30 phút.';
const tosJson = {
  'type': 'TOS',
  'version': '1.0',
  'content': 'Điều khoản sử dụng Senpai ơi (bản nháp 1.0). Người dùng phải từ đủ 18 tuổi.',
};

void main() {
  group('đăng nhập, phiên', () {
    test('login gửi email + mật khẩu và đọc CurrentUserResponse', () async {
      final server = FakeServer({'POST /api/auth/login': (_) => apiOk(userJson, message: 'Đăng nhập thành công.')});
      final user = await AuthDao(server.api).login('user@gmail.com', '123456');

      final req = server.last('POST', '/api/auth/login');
      expect(req.data, {'email': 'user@gmail.com', 'password': '123456'});
      expect(req.headers['X-XSRF-TOKEN'], 'csrf-test');
      expect(user.id, 2);
      expect(user.email, 'user@gmail.com');
      expect(user.displayName, 'Trần Minh');
      expect(user.role, 'USER');
      expect(user.roleLabel, 'Người dùng');
      expect(user.avatarUrl, isNull);
      expect(user.isMember, isTrue);
    });

    test('login tài khoản staff vẫn đọc được role (Controller mới từ chối)', () async {
      final server = FakeServer({'POST /api/auth/login': (_) => apiOk(moderatorJson)});
      final user = await AuthDao(server.api).login('moderator@gmail.com', '123456');
      expect(user.role, 'MODERATOR');
      expect(user.isMember, isFalse);
    });

    test('login sai: ném câu của server và lỗi theo ô', () async {
      final server = FakeServer({
        'POST /api/auth/login': (_) => apiError(
          400,
          'Vui lòng nhập mật khẩu',
          fields: {'password': 'Vui lòng nhập mật khẩu', 'email': 'Email không hợp lệ'},
        ),
      });
      await expectLater(
        AuthDao(server.api).login('abc', ''),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.message, 'message', 'Vui lòng nhập mật khẩu')
              .having((e) => e.fields['email'], 'fields.email', 'Email không hợp lệ'),
        ),
      );
    });

    test('login bị khóa 30 phút: 423 với câu của server', () async {
      final server = FakeServer({
        'POST /api/auth/login': (_) =>
            apiError(423, 'Bạn đã nhập sai mật khẩu quá nhiều lần. Vui lòng thử lại sau 30 phút.'),
      });
      await expectLater(
        AuthDao(server.api).login('user@gmail.com', 'sai'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('30 phút'))),
      );
    });

    test('findCurrent đọc /api/auth/me; 401 thì là khách (null)', () async {
      var signedIn = true;
      final server = FakeServer({
        'GET /api/auth/me': (_) => signedIn ? apiOk(userJson) : apiError(401, 'Bạn chưa đăng nhập.'),
      });
      final dao = AuthDao(server.api);
      expect((await dao.findCurrent())?.email, 'user@gmail.com');
      signedIn = false;
      expect(await dao.findCurrent(), isNull);
    });

    test('findCurrent ném lỗi khác 401 (server hỏng)', () async {
      final server = FakeServer({'GET /api/auth/me': (_) => apiError(500, 'Server gặp lỗi.')});
      await expectLater(AuthDao(server.api).findCurrent(), throwsA(isA<ApiException>()));
    });

    test('logout gửi POST và chấp nhận 204 không có body', () async {
      final server = FakeServer({'POST /api/auth/logout': (_) => const FakeReply(204, null)});
      await AuthDao(server.api).logout();
      expect(server.requests.single.method, 'POST');
      expect(server.requests.single.uri.path, '/api/auth/logout');
    });
  });

  group('đăng ký 3 bước', () {
    test('sendRegisterCode gửi {email} và đọc thời hạn + số giây đợi', () async {
      final server = FakeServer({
        'POST /api/auth/register/send-code': (_) =>
            apiOk(sendCodeJson, message: 'Đã gửi mã xác thực tới email của bạn.'),
      });
      final sent = await AuthDao(server.api).sendRegisterCode('auth-1794077554@example.com');
      expect(server.last('POST', '/api/auth/register/send-code').data, {'email': 'auth-1794077554@example.com'});
      expect(sent.email, 'auth-1794077554@example.com');
      expect(sent.expiresInMinutes, 10);
      expect(sent.resendAfterSeconds, 60);
    });

    test('sendRegisterCode: email đã có tài khoản (409) và gửi quá nhanh (429)', () async {
      var status = 409;
      final server = FakeServer({
        'POST /api/auth/register/send-code': (_) => status == 409
            ? apiError(409, 'Email này đã được đăng ký. Hãy đăng nhập hoặc dùng email khác.')
            : apiError(429, 'Vui lòng đợi 51 giây rồi gửi lại mã.'),
      });
      final dao = AuthDao(server.api);
      await expectLater(
        dao.sendRegisterCode('user@gmail.com'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409)),
      );
      status = 429;
      await expectLater(
        dao.sendRegisterCode('a@example.com'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Vui lòng đợi 51 giây rồi gửi lại mã.')),
      );
    });

    test('verifyRegisterCode gửi {email, code} và nhận vé + độ dài tối thiểu mật khẩu', () async {
      final server = FakeServer({
        'POST /api/auth/register/verify-code': (_) => apiOk(verifyCodeJson, message: 'Xác thực email thành công.'),
      });
      final ticket = await AuthDao(server.api).verifyRegisterCode('a@example.com', '747659');
      expect(server.last('POST', '/api/auth/register/verify-code').data, {'email': 'a@example.com', 'code': '747659'});
      expect(ticket.ticket, 'RCCeUtPd_DJAdkDDUjNq-IUmCLsdiAj1H34f2dF3-sM');
      expect(ticket.expiresInMinutes, 30);
      expect(ticket.passwordMinLength, 8);
    });

    test('verifyRegisterCode sai mã: câu "Bạn còn 4 lần thử"', () async {
      final server = FakeServer({
        'POST /api/auth/register/verify-code': (_) => apiError(400, 'Mã xác thực không đúng. Bạn còn 4 lần thử.'),
      });
      await expectLater(
        AuthDao(server.api).verifyRegisterCode('a@example.com', '000000'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('còn 4 lần'))),
      );
    });

    test('completeRegistration gửi đủ 5 trường và đọc tài khoản mới', () async {
      final server = FakeServer({
        'POST /api/auth/register/complete': (_) => apiOk({
          'id': 8,
          'email': 'auth-1794077554@example.com',
          'displayName': 'Auth Thử',
          'role': 'USER',
          'roleLabel': 'Người dùng',
          'homePath': '/',
          'avatarUrl': null,
        }, message: 'Đăng ký thành công. Hãy đăng nhập.'),
      });
      final user = await AuthDao(server.api).completeRegistration(
        const RegisterRequest(
          ticket: 'tk',
          displayName: 'Auth Thử',
          password: 'abc12345',
          adultConfirmed: true,
          acceptTerms: true,
        ),
      );
      expect(server.last('POST', '/api/auth/register/complete').data, {
        'ticket': 'tk',
        'displayName': 'Auth Thử',
        'password': 'abc12345',
        'adultConfirmed': true,
        'acceptTerms': true,
      });
      expect(user.id, 8);
      expect(user.displayName, 'Auth Thử');
    });

    test('completeRegistration: lỗi theo ô của server', () async {
      final server = FakeServer({
        'POST /api/auth/register/complete': (_) => apiError(
          400,
          'Mật khẩu phải có cả chữ và số',
          fields: {
            'password': 'Mật khẩu phải có cả chữ và số',
            'displayName': 'Tên hiển thị dài từ 2 đến 60 ký tự',
            'acceptTerms': 'Bạn cần đồng ý Điều khoản, Chính sách bảo mật và Quy tắc cộng đồng',
            'adultConfirmed': 'Bạn phải từ đủ 18 tuổi để đăng ký',
          },
        ),
      });
      await expectLater(
        AuthDao(server.api).completeRegistration(
          const RegisterRequest(
            ticket: 'tk',
            displayName: 'A',
            password: 'abc',
            adultConfirmed: false,
            acceptTerms: false,
          ),
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.fields.keys,
            'fields',
            containsAll(['password', 'displayName', 'acceptTerms', 'adultConfirmed']),
          ),
        ),
      );
    });
  });

  group('quên mật khẩu', () {
    test('forgotPassword gửi {email} và trả câu của server', () async {
      final server = FakeServer({
        'POST /api/auth/password/forgot': (_) => apiOk(forgotMessage, message: forgotMessage),
      });
      final message = await AuthDao(server.api).forgotPassword('a@example.com');
      expect(server.last('POST', '/api/auth/password/forgot').data, {'email': 'a@example.com'});
      expect(message, forgotMessage);
    });

    test('checkResetToken gửi token trong body và đọc email đã che', () async {
      final server = FakeServer({
        'POST /api/auth/password/check': (_) => apiOk({'email': 'a***@example.com'}),
      });
      final email = await AuthDao(server.api).checkResetToken('Rgw3YMVgp66LygwJKdvg30LAOm1P1FXKu8dqiRWs5TU');
      final req = server.last('POST', '/api/auth/password/check');
      expect(req.data, {'token': 'Rgw3YMVgp66LygwJKdvg30LAOm1P1FXKu8dqiRWs5TU'});
      expect(req.uri.query, isEmpty);
      expect(email, 'a***@example.com');
    });

    test('checkResetToken: liên kết hết hạn → 400', () async {
      final server = FakeServer({
        'POST /api/auth/password/check': (_) =>
            apiError(400, 'Liên kết đã hết hạn hoặc đã được sử dụng. Hãy yêu cầu liên kết mới.'),
      });
      await expectLater(
        AuthDao(server.api).checkResetToken('abc'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('hết hạn'))),
      );
    });

    test('resetPassword gửi {token, password, confirmPassword}', () async {
      final server = FakeServer({
        'POST /api/auth/password/reset': (_) =>
            apiOk(null, message: 'Đã đặt lại mật khẩu. Hãy đăng nhập bằng mật khẩu mới.'),
      });
      final message = await AuthDao(server.api).resetPassword('tk', 'reset123', 'reset123');
      expect(server.last('POST', '/api/auth/password/reset').data, {
        'token': 'tk',
        'password': 'reset123',
        'confirmPassword': 'reset123',
      });
      expect(message, 'Đã đặt lại mật khẩu. Hãy đăng nhập bằng mật khẩu mới.');
    });

    test('resetPassword: lỗi theo ô password + confirmPassword', () async {
      final server = FakeServer({
        'POST /api/auth/password/reset': (_) => apiError(
          400,
          'Mật khẩu dài từ 8 đến 72 ký tự',
          fields: {'password': 'Mật khẩu dài từ 8 đến 72 ký tự', 'confirmPassword': 'Hai mật khẩu không khớp.'},
        ),
      });
      await expectLater(
        AuthDao(server.api).resetPassword('abc', 'a', 'b'),
        throwsA(isA<ApiException>().having((e) => e.fields['confirmPassword'], 'confirm', 'Hai mật khẩu không khớp.')),
      );
    });
  });

  group('đổi mật khẩu, xóa tài khoản', () {
    test('hasPassword đọc cờ hasPassword của /api/me/profile', () async {
      var has = true;
      final server = FakeServer({
        'GET /api/me/profile': (_) => apiOk({
          'id': 2,
          'email': 'user@gmail.com',
          'displayName': 'Trần Minh',
          'role': 'USER',
          'points': 40,
          'hasPassword': has,
          'linkedProviders': <String>[],
          'savedCount': 0,
        }),
      });
      final dao = AuthDao(server.api);
      expect(await dao.hasPassword(), isTrue);
      has = false;
      expect(await dao.hasPassword(), isFalse);
    });

    test('changePassword gửi PUT đủ 3 trường; tạo mật khẩu lần đầu gửi currentPassword null', () async {
      final server = FakeServer({
        'PUT /api/me/password': (req) => (req.data as Map)['currentPassword'] == null
            ? apiOk('Đã tạo mật khẩu.', message: 'Đã tạo mật khẩu. Từ giờ bạn đăng nhập được bằng email và mật khẩu.')
            : apiOk('Đã đổi mật khẩu.', message: 'Đã đổi mật khẩu.'),
      });
      final dao = AuthDao(server.api);
      final changed = await dao.changePassword(
        currentPassword: 'abc12345',
        password: 'xyz12345',
        confirmPassword: 'xyz12345',
      );
      expect(server.last('PUT', '/api/me/password').data, {
        'currentPassword': 'abc12345',
        'password': 'xyz12345',
        'confirmPassword': 'xyz12345',
      });
      expect(changed, 'Đã đổi mật khẩu.');
      final created = await dao.changePassword(
        currentPassword: null,
        password: 'xyz12345',
        confirmPassword: 'xyz12345',
      );
      expect(created, startsWith('Đã tạo mật khẩu.'));
    });

    test('changePassword xong thì lấy token CSRF mới cho lần ghi sau (phiên đổi id)', () async {
      final counter = _CsrfCounter(
        FakeServer({
          'PUT /api/me/password': (_) => apiOk('Đã đổi mật khẩu.', message: 'Đã đổi mật khẩu.'),
          'POST /api/auth/password/forgot': (_) => apiOk(forgotMessage, message: forgotMessage),
        }),
      );
      final dao = AuthDao(counter.api);
      await dao.forgotPassword('a@example.com');
      await dao.forgotPassword('a@example.com');
      expect(counter.csrfLoads, 1, reason: 'token được dùng lại khi phiên không đổi');
      await dao.changePassword(currentPassword: 'abc12345', password: 'xyz12345', confirmPassword: 'xyz12345');
      await dao.forgotPassword('a@example.com');
      expect(counter.csrfLoads, 2, reason: 'đổi mật khẩu đổi id phiên nên phải lấy token mới');
    });

    test('deleteAccount xong cũng bỏ token CSRF cũ', () async {
      final counter = _CsrfCounter(
        FakeServer({
          'DELETE /api/me': (_) => apiOk(null, message: 'Đã xóa tài khoản.'),
          'POST /api/auth/password/forgot': (_) => apiOk(forgotMessage, message: forgotMessage),
        }),
      );
      final dao = AuthDao(counter.api);
      await dao.deleteAccount();
      await dao.forgotPassword('a@example.com');
      expect(counter.csrfLoads, 2);
    });

    test('changePassword sai mật khẩu hiện tại: lỗi ô currentPassword', () async {
      final server = FakeServer({
        'PUT /api/me/password': (_) => apiError(
          400,
          'Mật khẩu hiện tại không đúng.',
          fields: {'currentPassword': 'Mật khẩu hiện tại không đúng.'},
        ),
      });
      await expectLater(
        AuthDao(server.api).changePassword(currentPassword: 'sai', password: 'xyz12345', confirmPassword: 'xyz12345'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.fields['currentPassword'],
            'currentPassword',
            'Mật khẩu hiện tại không đúng.',
          ),
        ),
      );
    });

    test('deleteAccount gửi DELETE /api/me và trả "Đã xóa tài khoản."', () async {
      final server = FakeServer({'DELETE /api/me': (_) => apiOk(null, message: 'Đã xóa tài khoản.')});
      expect(await AuthDao(server.api).deleteAccount(), 'Đã xóa tài khoản.');
      expect(server.requests.single.method, 'DELETE');
    });

    test('deleteAccount khi phiên đã hết: 401', () async {
      final server = FakeServer({'DELETE /api/me': (_) => const FakeReply(401, null)});
      await expectLater(
        AuthDao(server.api).deleteAccount(),
        throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
      );
    });
  });

  group('văn bản pháp lý', () {
    test("findLegal('terms') gọi /api/legal/tos và đọc type, version, content", () async {
      final server = FakeServer({'GET /api/legal/tos': (_) => apiOk(tosJson)});
      final doc = await AuthDao(server.api).findLegal('terms');
      expect(server.requests.single.uri.path, '/api/legal/tos');
      expect(doc.type, 'TOS');
      expect(doc.version, '1.0');
      expect(doc.content, startsWith('Điều khoản sử dụng Senpai ơi'));
    });

    test('findLegal privacy / community giữ nguyên tên loại', () async {
      final server = FakeServer({
        'GET /api/legal/privacy': (_) => apiOk({'type': 'PRIVACY', 'version': '1.0', 'content': 'Chính sách'}),
        'GET /api/legal/community': (_) => apiOk({'type': 'COMMUNITY', 'version': '1.0', 'content': 'Quy tắc'}),
      });
      final dao = AuthDao(server.api);
      expect((await dao.findLegal('privacy')).type, 'PRIVACY');
      expect((await dao.findLegal('community')).content, 'Quy tắc');
    });

    test('findLegal: văn bản chưa có → 404 "Không tìm thấy văn bản …"', () async {
      final server = FakeServer({'GET /api/legal/tos': (_) => apiError(404, 'Không tìm thấy văn bản TOS')});
      await expectLater(
        AuthDao(server.api).findLegal('terms'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });
}

/// Bọc FakeServer để đếm số lần ApiClient lấy token CSRF (`GET /api/auth/csrf`).
class _CsrfCounter implements HttpClientAdapter {
  _CsrfCounter(this._server) {
    api = ApiClient(
      Dio(BaseOptions(baseUrl: 'http://fake.local', validateStatus: (_) => true))..httpClientAdapter = this,
    );
  }

  final FakeServer _server;
  late final ApiClient api;
  int csrfLoads = 0;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    if (options.uri.path == '/api/auth/csrf') {
      csrfLoads++;
    }
    return _server.fetch(options, requestStream, cancelFuture);
  }

  @override
  void close({bool force = false}) {}
}
