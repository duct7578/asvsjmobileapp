// Kiểm tra đường đi App → server thật: đăng nhập, đọc người đang đăng nhập, đăng xuất, từ chối staff,
// văn bản pháp lý, và trọn vòng đời một tài khoản mới:
// đăng ký 3 bước → đăng nhập → đổi mật khẩu → quên + đặt lại mật khẩu → xóa tài khoản.
//
// Server dev không gửi email thật mà in vào log (khối "===== EMAIL (not sent"); test đọc mã xác thực và đường link
// đặt lại mật khẩu từ file log đó. Đường dẫn log đổi bằng --dart-define=SERVER_LOG=<đường dẫn>.
// Mỗi lần chạy gửi đúng 1 mã đăng ký (server giới hạn 5 mã / giờ cho mỗi địa chỉ IP).
//
// KHÔNG đổi mật khẩu, xóa, hay thử sai mật khẩu với tài khoản mẫu: chỉ làm với tài khoản auth-<số>@example.com.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/auth_dao.dart';

import 'live_api.dart';

/// Log của server dev (stdout), nơi in các email "không gửi".
const serverLog = String.fromEnvironment(
  'SERVER_LOG',
  defaultValue:
      r'C:\Users\A\AppData\Local\Temp\claude\c57abd35fbdc8a69\70521ac7-a172-4fce-bcfa-cfb88760e92f\scratchpad\server\console.log',
);

void main() {
  test('đăng nhập user@gmail.com, đọc lại phiên, đăng xuất', () async {
    final api = liveGuest();
    final dao = AuthDao(api);

    expect(await dao.findCurrent(), isNull);

    final user = await dao.login('user@gmail.com', '123456');
    expect(user.role, 'USER');
    expect(user.isMember, isTrue);
    expect(user.displayName, isNotEmpty);
    expect(user.roleLabel, 'Người dùng');

    final current = await dao.findCurrent();
    expect(current?.email, 'user@gmail.com');

    await dao.logout();
    expect(await dao.findCurrent(), isNull);
  }, skip: liveSkip);

  // Dùng email không tồn tại: sai mật khẩu 5 lần với tài khoản thật sẽ khóa tài khoản 30 phút
  test('đăng nhập sai nhận câu báo lỗi tiếng Việt của server', () async {
    final dao = AuthDao(liveGuest());
    await expectLater(
      dao.login('khong-ton-tai@example.com', 'sai-mat-khau'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.message, 'message', 'Email hoặc mật khẩu không đúng.')
            .having((e) => e.statusCode, 'statusCode', 401),
      ),
    );
  }, skip: liveSkip);

  test('AuthController từ chối moderator@gmail.com và đóng phiên trên server', () async {
    final dao = AuthDao(liveGuest());
    final auth = AuthController(dao);
    expect(await auth.login('moderator@gmail.com', '123456'), isFalse);
    expect(auth.error, AuthController.staffMessage);
    expect(auth.isSignedIn, isFalse);
    expect(await dao.findCurrent(), isNull, reason: 'phiên staff phải bị đăng xuất phía server');
    auth.dispose();
  }, skip: liveSkip);

  test('restoreSession gặp phiên staff thì đăng xuất, coi là khách', () async {
    final dao = AuthDao(liveGuest());
    final staff = await dao.login('moderator@gmail.com', '123456');
    expect(staff.role, 'MODERATOR');
    final auth = AuthController(dao);
    await auth.restoreSession();
    expect(auth.isSignedIn, isFalse);
    expect(await dao.findCurrent(), isNull);
    auth.dispose();
  }, skip: liveSkip);

  test('văn bản pháp lý: terms (tos), privacy, community', () async {
    final dao = AuthDao(liveGuest());
    final tos = await dao.findLegal('terms');
    expect(tos.type, 'TOS');
    expect(tos.version, isNotEmpty);
    expect(tos.content, isNotEmpty);
    expect((await dao.findLegal('privacy')).type, 'PRIVACY');
    expect((await dao.findLegal('community')).type, 'COMMUNITY');
  }, skip: liveSkip);

  test('quên mật khẩu với email không có tài khoản: vẫn cùng một câu; link sai bị từ chối', () async {
    final dao = AuthDao(liveGuest());
    final message = await dao.forgotPassword('khong-ton-tai@example.com');
    expect(message, startsWith('Nếu email này có tài khoản'));
    await expectLater(
      dao.checkResetToken('khong-phai-token-that-1234567890'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('hết hạn'))),
    );
  }, skip: liveSkip);

  test('khách gửi mã cho email đã có tài khoản: 409', () async {
    await expectLater(
      AuthDao(liveGuest()).sendRegisterCode('user@gmail.com'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409)),
    );
  }, skip: liveSkip);

  test(
    'vòng đời tài khoản mới: đăng ký → đổi mật khẩu → quên + đặt lại → xóa',
    () async {
      final api = liveGuest();
      final dao = AuthDao(api);
      final auth = AuthController(dao);
      final email = 'auth-${DateTime.now().millisecondsSinceEpoch}@example.com';
      const pw1 = 'matkhau123';
      const pw2 = 'doimatkhau456';
      const pw3 = 'datlai789';

      // ----- Đăng ký 3 bước qua AuthController
      auth.startRegistration();
      expect(await auth.sendRegisterCode(email), isTrue, reason: auth.error);
      expect(auth.registerStep, 2);
      expect(auth.registerEmail, email);
      expect(auth.registerCode!.expiresInMinutes, greaterThan(0));
      expect(auth.resendSecondsLeft, greaterThan(0));
      expect(await auth.resendRegisterCode(), isFalse, reason: 'chưa hết thời gian đợi thì không gửi lại');

      final code = await _waitForEmail(email, RegExp(r'Subject: [^\r\n]*?(\d{6})'));
      expect(await auth.verifyRegisterCode(code == '000000' ? '111111' : '000000'), isFalse);
      expect(auth.fieldErrors['code'], contains('Mã xác thực không đúng'));
      expect(await auth.verifyRegisterCode(code), isTrue, reason: auth.error);
      expect(auth.registerStep, 3);
      expect(auth.passwordMinLength, greaterThanOrEqualTo(1));

      final created = await auth.completeRegistration(
        displayName: 'Auth Thử Nghiệm',
        password: pw1,
        confirmPassword: pw1,
        adultConfirmed: true,
        acceptTerms: true,
      );
      expect(created, isTrue, reason: auth.error);
      expect(auth.isSignedIn, isTrue, reason: 'app tự đăng nhập sau khi tạo tài khoản');
      expect(auth.currentUser!.email, email);
      expect(auth.currentUser!.displayName, 'Auth Thử Nghiệm');
      expect(auth.currentUser!.role, 'USER');
      expect((await dao.findCurrent())?.email, email);

      // ----- Đổi mật khẩu
      await auth.loadPasswordStatus();
      expect(auth.hasPassword, isTrue);
      expect(
        await auth.changePassword(currentPassword: 'sai-mat-khau-1', password: pw2, confirmPassword: pw2),
        isFalse,
      );
      expect(auth.fieldErrors['currentPassword'], 'Mật khẩu hiện tại không đúng.');
      expect(
        await auth.changePassword(currentPassword: pw1, password: pw2, confirmPassword: pw2),
        isTrue,
        reason: auth.error,
      );
      expect(auth.takeMessage(), 'Đã đổi mật khẩu.');
      // Phiên đổi id nhưng vẫn đăng nhập; lần ghi sau dùng token CSRF mới
      expect((await dao.findCurrent())?.email, email);
      await auth.logout();
      expect(await dao.findCurrent(), isNull);
      expect(await auth.login(email, pw2), isTrue, reason: auth.error);
      await auth.logout();

      // ----- Quên mật khẩu → dán đường link → đặt lại
      auth.startForgotPassword();
      expect(await auth.sendResetLink(email), isTrue, reason: auth.error);
      expect(auth.forgotNotice, startsWith('Nếu email này có tài khoản'));
      final link = await _waitForEmail(email, RegExp(r'(\S*/reset-password\?token=[A-Za-z0-9_\-%]+)'));
      expect(await auth.checkResetLink('Mở liên kết sau:\n$link\n'), isTrue, reason: auth.error);
      expect(auth.resetEmail, 'a***@example.com');
      expect(await auth.resetPassword(pw3, pw3), isTrue, reason: auth.error);
      expect(auth.takeMessage(), 'Đã đặt lại mật khẩu. Hãy đăng nhập bằng mật khẩu mới.');
      // Đường link chỉ dùng được một lần
      await expectLater(
        dao.checkResetToken(AuthController.tokenFromLink(link)!),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
      expect(await auth.login(email, pw2), isFalse, reason: 'mật khẩu cũ không dùng được nữa');
      expect(await auth.login(email, pw3), isTrue, reason: auth.error);

      // ----- Xóa tài khoản
      expect(await auth.deleteAccount(), isTrue, reason: auth.error);
      expect(auth.takeMessage(), 'Đã xóa tài khoản.');
      expect(auth.isSignedIn, isFalse);
      expect(await dao.findCurrent(), isNull);
      expect(await auth.login(email, pw3), isFalse, reason: 'tài khoản đã xóa không đăng nhập được');
      auth.dispose();
    },
    skip: liveSkip ?? (File(serverLog).existsSync() ? null : 'Không thấy log server: $serverLog'),
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

/// Đợi server in email gửi tới [email] (email gửi trên luồng nền) rồi lấy nhóm 1 của [pattern] trong khối email
/// mới nhất gửi tới địa chỉ đó.
Future<String> _waitForEmail(String email, RegExp pattern) async {
  for (var i = 0; i < 40; i++) {
    final log = utf8.decode(await File(serverLog).readAsBytes(), allowMalformed: true);
    final blocks = log.split('===== EMAIL').where((b) => b.contains('To: $email')).toList().reversed;
    for (final block in blocks) {
      final match = pattern.firstMatch(block);
      if (match != null) {
        return match.group(1)!;
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  fail('Không thấy email gửi tới $email trong $serverLog');
}
