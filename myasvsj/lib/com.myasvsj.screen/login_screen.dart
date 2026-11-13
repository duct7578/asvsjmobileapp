import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.screen/auth_field.dart';
import 'package:myasvsj/com.myasvsj.screen/auth_notice.dart';
import 'package:myasvsj/com.myasvsj.screen/forgot_password_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/password_field.dart';
import 'package:myasvsj/com.myasvsj.screen/register_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Màn hình đăng nhập bằng email (UC đăng nhập của web, màn 32 của thiết kế). Đăng nhập xong thì đóng và trả về true.
///
/// Logo hoa anh đào, lời chào Display/L, ô Email và Mật khẩu (nhãn phía trên, icon phía trước), link "Quên mật khẩu?",
/// nút "Đăng nhập", dòng "Chưa có tài khoản? Đăng ký" và tranh núi Phú Sĩ phía dưới.
/// Đăng ký xong app đăng nhập luôn nên màn này cũng đóng với true. Tài khoản staff bị từ chối
/// (AuthController.staffMessage hiện trong hộp lỗi).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Lỗi của lần mở trước không hiện lại
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AuthController>().clearForm());
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: const SenpaiAppBar(title: 'Đăng nhập'),
      body: AutofillGroup(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            const Align(alignment: AlignmentDirectional.centerStart, child: SenpaiLogo(size: 60)),
            const SizedBox(height: 18),
            Text('Chào mừng bạn quay lại Senpai ơi.', style: SenpaiText.displayL.copyWith(color: SenpaiColors.ink)),
            const SizedBox(height: 6),
            Text(
              'Đăng nhập để lưu địa điểm, viết review và hỏi các senpai.',
              style: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted),
            ),
            const SizedBox(height: 18),
            if (auth.bannerError != null) ...[
              AuthNotice(text: auth.bannerError!, margin: EdgeInsets.zero),
              const SizedBox(height: 18),
            ],
            SenpaiLabeledField(
              label: 'Email',
              child: TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: authInputDecoration(
                  'Email',
                  icon: Symbols.mail_rounded,
                  errorText: auth.fieldErrors['email'],
                ),
              ),
            ),
            const SizedBox(height: 18),
            PasswordField(
              controller: _password,
              label: 'Mật khẩu',
              errorText: auth.fieldErrors['password'],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _login(),
            ),
            // Link cao 32 thay cho dòng chữ 20 của thiết kế: bớt 6 ở trên và dưới để giữ nhịp 18
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                style: authLinkStyle,
                onPressed: auth.isLoading ? null : _forgot,
                child: const Text('Quên mật khẩu?'),
              ),
            ),
            const SizedBox(height: 12),
            SenpaiButton(
              label: auth.isLoading ? 'Đang đăng nhập…' : 'Đăng nhập',
              onPressed: auth.isLoading ? null : _login,
              expand: true,
            ),
            const SizedBox(height: 12),
            AuthFooter(
              question: 'Chưa có tài khoản?',
              action: 'Đăng ký',
              onPressed: auth.isLoading ? null : _register,
            ),
            const SizedBox(height: 12),
            const CoverArt(scene: CoverScene.fuji, width: double.infinity, height: 150, radius: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    final auth = context.read<AuthController>();
    final ok = await auth.login(_email.text, _password.text);
    if (!mounted) {
      return;
    }
    if (ok) {
      TextInput.finishAutofillContext();
      Navigator.pop(context, true);
    } else {
      // Như trang web: nhập lại mật khẩu sau mỗi lần thất bại
      _password.clear();
    }
  }

  Future<void> _forgot() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ForgotPasswordScreen(initialEmail: _email.text.trim())),
    );
    if (!mounted) {
      return;
    }
    context.read<AuthController>().clearForm();
  }

  Future<void> _register() async {
    final signedIn = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen(fromLogin: true)),
    );
    if (!mounted) {
      return;
    }
    if (signedIn == true) {
      Navigator.pop(context, true);
      return;
    }
    context.read<AuthController>().clearForm();
  }
}
