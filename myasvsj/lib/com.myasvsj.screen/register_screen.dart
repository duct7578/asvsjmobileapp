import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/auth_field.dart';
import 'package:myasvsj/com.myasvsj.screen/auth_notice.dart';
import 'package:myasvsj/com.myasvsj.screen/legal_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/password_field.dart';
import 'package:myasvsj/com.myasvsj.screen/password_rules.dart';
import 'package:myasvsj/com.myasvsj.screen/register_code_field.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Đăng ký bằng email trong 3 bước như trang /register: 1. Email → 2. Mã xác thực → 3. Mật khẩu (màn 33 của thiết
/// kế: tiêu đề "Tạo tài khoản" Display/L, thanh 3 bước, nội dung của bước, dòng "Đã có tài khoản? Đăng nhập").
///
/// Tạo xong tài khoản, app đăng nhập luôn rồi đóng màn hình, trả về true khi đã đăng nhập.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.fromLogin = false});

  /// Mở từ màn Đăng nhập: link "Đăng nhập" chỉ cần quay lại màn trước.
  final bool fromLogin;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _steps = ['Email', 'Mã xác thực', 'Mật khẩu'];

  final _email = TextEditingController();
  final _code = TextEditingController();
  final _displayName = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _adult = false;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AuthController>().startRegistration());
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _displayName.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final step = auth.registerStep.clamp(1, _steps.length);
    return Scaffold(
      appBar: const SenpaiAppBar(title: 'Đăng ký'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          Text('Tạo tài khoản', style: SenpaiText.displayL.copyWith(color: SenpaiColors.ink)),
          const SizedBox(height: 4),
          Text(
            'Miễn phí, dành cho người từ 18 tuổi. Chỉ mất khoảng một phút.',
            style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
          ),
          const SizedBox(height: 20),
          SenpaiStepper(steps: _steps, current: step - 1),
          const SizedBox(height: 20),
          if (auth.bannerError != null) ...[
            AuthNotice(text: auth.bannerError!, margin: EdgeInsets.zero),
            const SizedBox(height: 20),
          ],
          ...switch (step) {
            2 => _codeStep(auth),
            3 => _passwordStep(auth),
            _ => _emailStep(auth),
          },
          // Link cao 32 thay cho dòng chữ 20 của thiết kế: bớt 6 để giữ khoảng cách 20
          const SizedBox(height: 14),
          AuthFooter(question: 'Đã có tài khoản?', action: 'Đăng nhập', onPressed: auth.isLoading ? null : _openLogin),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Bước 1: email

  List<Widget> _emailStep(AuthController auth) => [
    SenpaiLabeledField(
      label: 'Email',
      child: TextField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        autocorrect: false,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _sendCode(),
        decoration: authInputDecoration(
          'Email',
          icon: Symbols.mail_rounded,
          helperText: 'Chúng tôi sẽ gửi mã xác thực 6 số tới email này.',
          errorText: auth.fieldErrors['email'],
        ),
      ),
    ),
    const SizedBox(height: 20),
    SenpaiButton(
      label: auth.isLoading ? 'Đang gửi…' : 'Gửi mã xác thực',
      onPressed: auth.isLoading ? null : _sendCode,
      expand: true,
    ),
  ];

  Future<void> _sendCode() async {
    final auth = context.read<AuthController>();
    final sent = await auth.sendRegisterCode(_email.text);
    if (sent && mounted) {
      _code.clear();
      showMessage(context, auth.takeMessage());
    }
  }

  // ---------------------------------------------------------------- Bước 2: mã xác thực

  List<Widget> _codeStep(AuthController auth) {
    final sent = auth.registerCode;
    final wait = auth.resendSecondsLeft;
    final codeError = auth.fieldErrors['code'];
    return [
      // Email đã nhập, "Đổi" quay về bước 1
      Container(
        padding: const EdgeInsets.fromLTRB(14, 5, 10, 5),
        decoration: BoxDecoration(
          color: SenpaiColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SenpaiColors.line),
        ),
        child: Row(
          spacing: 10,
          children: [
            const Icon(Symbols.mail_rounded, size: 20, color: SenpaiColors.muted),
            Expanded(
              child: Text(
                auth.registerEmail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
              ),
            ),
            TextButton(
              style: authLinkStyle,
              onPressed: auth.isLoading ? null : auth.changeRegisterEmail,
              child: const Text('Đổi'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text('Mã xác thực', style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink)),
          RegisterCodeField(
            controller: _code,
            length: AuthController.codeLength,
            hasError: codeError != null,
            onChanged: (value) {
              // Đủ 6 số thì tự gửi, như trang web
              if (value.length == AuthController.codeLength) {
                _verify();
              }
            },
            onSubmitted: (_) => _verify(),
          ),
          Text(
            codeError ?? 'Mã có hiệu lực trong ${sent?.expiresInMinutes ?? 10} phút. Nhớ kiểm tra cả hộp thư Spam.',
            style: SenpaiText.caption.copyWith(color: codeError != null ? SenpaiColors.crit : SenpaiColors.muted),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Chưa nhận được mã?', style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
          TextButton(
            style: authLinkStyle,
            onPressed: auth.isLoading || wait > 0 ? null : _resend,
            child: Text(wait > 0 ? 'Gửi lại sau ${wait}s' : 'Gửi lại mã'),
          ),
        ],
      ),
      const SizedBox(height: 14),
      SenpaiButton(
        label: auth.isLoading ? 'Đang kiểm tra…' : 'Xác nhận',
        onPressed: auth.isLoading ? null : _verify,
        expand: true,
      ),
    ];
  }

  Future<void> _resend() async {
    final auth = context.read<AuthController>();
    final sent = await auth.resendRegisterCode();
    if (sent && mounted) {
      _code.clear();
      showMessage(context, auth.takeMessage());
    }
  }

  Future<void> _verify() async {
    final auth = context.read<AuthController>();
    if (auth.isLoading) {
      return;
    }
    final ok = await auth.verifyRegisterCode(_code.text);
    if (!mounted) {
      return;
    }
    if (ok) {
      showMessage(context, auth.takeMessage());
    } else {
      _code.selection = TextSelection(baseOffset: 0, extentOffset: _code.text.length);
    }
  }

  // ---------------------------------------------------------------- Bước 3: tên, mật khẩu, đồng ý

  List<Widget> _passwordStep(AuthController auth) {
    final errors = auth.fieldErrors;
    return [
      SenpaiLabeledField(
        label: 'Tên hiển thị',
        child: TextField(
          controller: _displayName,
          maxLength: AuthController.displayNameMax,
          autofillHints: const [AutofillHints.nickname],
          textInputAction: TextInputAction.next,
          decoration: authInputDecoration(
            'Tên hiển thị',
            icon: Symbols.person_rounded,
            helperText: 'Tên này hiện trên review và bài viết của bạn.',
            errorText: errors['displayName'],
          ),
        ),
      ),
      const SizedBox(height: 16),
      PasswordField(
        controller: _password,
        label: 'Mật khẩu',
        isNewPassword: true,
        errorText: errors['password'],
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 10),
      PasswordRules(controller: _password, minLength: auth.passwordMinLength),
      const SizedBox(height: 16),
      PasswordField(
        controller: _confirm,
        label: 'Nhập lại mật khẩu',
        isNewPassword: true,
        errorText: errors['confirmPassword'],
        textInputAction: TextInputAction.done,
      ),
      const SizedBox(height: 12),
      _consent(
        value: _adult,
        onChanged: (on) => setState(() => _adult = on),
        text: 'Tôi xác nhận mình đã đủ 18 tuổi.',
        error: errors['adultConfirmed'],
      ),
      _consent(
        value: _acceptTerms,
        onChanged: (on) => setState(() => _acceptTerms = on),
        text: 'Tôi đồng ý với Điều khoản sử dụng, Chính sách bảo mật và Quy tắc cộng đồng.',
        error: errors['acceptTerms'],
      ),
      const SizedBox(height: 4),
      Wrap(
        spacing: 12,
        children: [
          _legalLink('Điều khoản sử dụng', 'terms'),
          _legalLink('Chính sách bảo mật', 'privacy'),
          _legalLink('Quy tắc cộng đồng', 'community'),
        ],
      ),
      const SizedBox(height: 16),
      SenpaiButton(
        label: auth.isLoading ? 'Đang tạo tài khoản…' : 'Tạo tài khoản',
        onPressed: auth.isLoading ? null : _complete,
        expand: true,
      ),
    ];
  }

  /// `checkbox(on, label)` của thiết kế: ô 22 bo 6 + chữ Body/S; lỗi Caption crit phía dưới.
  Widget _consent({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String text,
    String? error,
  }) {
    return CheckboxListTile(
      value: value,
      onChanged: (on) => onChanged(on ?? false),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      horizontalTitleGap: 8,
      title: Text(text, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.ink)),
      subtitle: error == null ? null : Text(error, style: SenpaiText.caption.copyWith(color: SenpaiColors.crit)),
    );
  }

  Widget _legalLink(String label, String type) => TextButton.icon(
    style: authLinkStyle,
    icon: const Icon(Symbols.open_in_new_rounded, size: 16),
    label: Text(label),
    onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => LegalScreen(type: type))),
  );

  Future<void> _complete() async {
    final auth = context.read<AuthController>();
    final created = await auth.completeRegistration(
      displayName: _displayName.text,
      password: _password.text,
      confirmPassword: _confirm.text,
      adultConfirmed: _adult,
      acceptTerms: _acceptTerms,
    );
    if (!created || !mounted) {
      return;
    }
    TextInput.finishAutofillContext();
    showMessage(context, auth.takeMessage());
    Navigator.pop(context, auth.isSignedIn);
  }

  void _openLogin() {
    if (widget.fromLogin) {
      Navigator.pop(context, false);
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute<bool>(builder: (_) => const LoginScreen()));
    }
  }
}
