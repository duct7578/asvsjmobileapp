import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/auth_field.dart';
import 'package:myasvsj/com.myasvsj.screen/auth_notice.dart';
import 'package:myasvsj/com.myasvsj.screen/password_field.dart';
import 'package:myasvsj/com.myasvsj.screen/password_rules.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Quên mật khẩu (UC-U05) gộp hai trang /forgot-password và /reset-password của web:
/// 1. nhập email để nhận liên kết → 2. dán đường link trong email (app chưa mở được link) → 3. đặt mật khẩu mới.
/// Đặt xong thì đóng và trả về true; câu của server nằm ở AuthController.message.
///
/// Màn 34 của thiết kế: ô icon lock_reset 64, thanh 3 bước, câu hướng dẫn Body/M muted, ô nhập có nhãn phía trên,
/// nút chính, nút Ghost và link "← Quay lại Đăng nhập".
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  /// Email đã gõ ở màn Đăng nhập, điền sẵn vào ô.
  final String initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _steps = ['Email', 'Dán đường link', 'Mật khẩu mới'];

  /// Gợi ý trong ô dán link (cũng là tên của ô đó).
  static const linkHint = 'http://…/reset-password?token=…';

  late final _email = TextEditingController(text: widget.initialEmail);
  final _link = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AuthController>().startForgotPassword());
  }

  @override
  void dispose() {
    _email.dispose();
    _link.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final step = auth.forgotStep.clamp(1, _steps.length);
    return Scaffold(
      appBar: SenpaiAppBar(title: step == 3 ? 'Đặt lại mật khẩu' : 'Quên mật khẩu'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconTile(Symbols.lock_reset_rounded, tone: SenpaiTone.brand, size: 64, radius: 20),
          ),
          const SizedBox(height: 20),
          SenpaiStepper(steps: _steps, current: step - 1),
          const SizedBox(height: 20),
          if (auth.bannerError != null) ...[
            AuthNotice(text: auth.bannerError!, margin: EdgeInsets.zero),
            const SizedBox(height: 20),
          ],
          ...switch (step) {
            2 => _linkStep(auth),
            3 => _passwordStep(auth),
            _ => _emailStep(auth),
          },
          const SizedBox(height: 14),
          Center(
            child: TextButton.icon(
              style: authLinkStyle,
              onPressed: auth.isLoading ? null : () => Navigator.pop(context, false),
              icon: const Icon(Symbols.arrow_back_rounded, size: 18),
              label: const Text('Quay lại Đăng nhập'),
            ),
          ),
        ],
      ),
    );
  }

  /// Câu hướng dẫn đầu mỗi bước: Body/M muted.
  static Widget _lead(String text) => Text(text, style: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted));

  // ---------------------------------------------------------------- Bước 1: email

  List<Widget> _emailStep(AuthController auth) => [
    _lead('Nhập email bạn dùng để đăng ký. Chúng tôi sẽ gửi liên kết đặt lại mật khẩu.'),
    const SizedBox(height: 20),
    SenpaiLabeledField(
      label: 'Email',
      child: TextField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        autocorrect: false,
        maxLength: AuthController.emailMax,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _sendLink(),
        decoration: authInputDecoration(
          'Email',
          icon: Symbols.mail_rounded,
          errorText: auth.fieldErrors['email'],
          counterText: '',
        ),
      ),
    ),
    const SizedBox(height: 20),
    SenpaiButton(
      label: auth.isLoading ? 'Đang gửi…' : 'Gửi liên kết',
      onPressed: auth.isLoading ? null : _sendLink,
      expand: true,
    ),
    const SizedBox(height: 8),
    SenpaiButton(
      label: 'Tôi đã có đường link trong email',
      kind: SenpaiButtonKind.ghost,
      onPressed: auth.isLoading ? null : () => auth.goToForgotStep(2),
      expand: true,
    ),
  ];

  Future<void> _sendLink() => context.read<AuthController>().sendResetLink(_email.text);

  // ---------------------------------------------------------------- Bước 2: dán đường link

  List<Widget> _linkStep(AuthController auth) => [
    if (auth.forgotNotice != null) ...[
      AuthNotice(text: auth.forgotNotice!, isError: false, margin: EdgeInsets.zero),
      const SizedBox(height: 20),
    ],
    _lead(
      'Mở email “Đặt lại mật khẩu”, sao chép đường link trong thư rồi dán vào ô dưới đây. '
      'Đường link chỉ dùng được một lần.',
    ),
    const SizedBox(height: 20),
    SenpaiLabeledField(
      label: 'Đường link trong email',
      child: TextField(
        controller: _link,
        keyboardType: TextInputType.url,
        autocorrect: false,
        minLines: 1,
        maxLines: 3,
        decoration: authInputDecoration(
          linkHint,
          icon: Symbols.link_rounded,
          errorText: auth.fieldErrors['token'],
          suffixIcon: IconButton(
            tooltip: 'Dán',
            icon: const Icon(Symbols.content_paste_rounded, size: 22),
            onPressed: _paste,
          ),
        ).copyWith(hintMaxLines: 2),
      ),
    ),
    const SizedBox(height: 20),
    SenpaiButton(
      label: auth.isLoading ? 'Đang kiểm tra…' : 'Tiếp tục',
      onPressed: auth.isLoading ? null : _checkLink,
      expand: true,
    ),
    const SizedBox(height: 20),
    SenpaiButton(
      label: 'Gửi lại liên kết',
      kind: SenpaiButtonKind.ghost,
      onPressed: auth.isLoading ? null : () => auth.goToForgotStep(1),
      expand: true,
    ),
  ];

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty && mounted) {
      _link.text = text.trim();
    }
  }

  Future<void> _checkLink() async {
    final ok = await context.read<AuthController>().checkResetLink(_link.text);
    if (ok && mounted) {
      _password.clear();
      _confirm.clear();
    }
  }

  // ---------------------------------------------------------------- Bước 3: mật khẩu mới

  List<Widget> _passwordStep(AuthController auth) => [
    _lead('Đặt mật khẩu mới cho tài khoản ${auth.resetEmail ?? ''}.'),
    const SizedBox(height: 20),
    PasswordField(
      controller: _password,
      label: 'Mật khẩu mới',
      isNewPassword: true,
      errorText: auth.fieldErrors['password'],
      textInputAction: TextInputAction.next,
    ),
    const SizedBox(height: 10),
    PasswordRules(controller: _password),
    const SizedBox(height: 16),
    PasswordField(
      controller: _confirm,
      label: 'Nhập lại mật khẩu',
      isNewPassword: true,
      errorText: auth.fieldErrors['confirmPassword'],
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _reset(),
    ),
    const SizedBox(height: 20),
    SenpaiButton(
      label: auth.isLoading ? 'Đang lưu…' : 'Đặt lại mật khẩu',
      onPressed: auth.isLoading ? null : _reset,
      expand: true,
    ),
  ];

  Future<void> _reset() async {
    final auth = context.read<AuthController>();
    final ok = await auth.resetPassword(_password.text, _confirm.text);
    if (!mounted) {
      return;
    }
    if (ok) {
      TextInput.finishAutofillContext();
      // "Đã đặt lại mật khẩu. Hãy đăng nhập bằng mật khẩu mới."
      showMessage(context, auth.takeMessage());
      Navigator.pop(context, true);
    } else if (auth.forgotStep == 2) {
      // Liên kết vừa hết hạn hoặc đã dùng: câu lỗi hiện dưới ô dán link
      _link.clear();
    }
  }
}
