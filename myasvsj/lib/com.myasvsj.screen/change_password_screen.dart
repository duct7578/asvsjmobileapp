import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/auth_notice.dart';
import 'package:myasvsj/com.myasvsj.screen/auth_required_view.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/password_field.dart';
import 'package:myasvsj/com.myasvsj.screen/password_rules.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// "Đổi mật khẩu" (UC-U06, màn 41 của thiết kế) ở trang Tôi; tài khoản tạo bằng Google/Facebook chưa có mật khẩu
/// thì là "Tạo mật khẩu". Ghi chú xanh nhạt ở đầu, các ô mật khẩu, điều kiện của mật khẩu mới, nút "Lưu mật khẩu"
/// ở thanh dưới. Lưu xong thì đóng, trả về true và hiện câu của server ("Đã đổi mật khẩu.").
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  /// Người dùng đã hỏi trạng thái mật khẩu; đổi khi vừa đăng nhập (từ nút "Đăng nhập" của màn này).
  int? _loadedFor;

  void _load() {
    if (!mounted) {
      return;
    }
    final auth = context.read<AuthController>();
    if (auth.isSignedIn) {
      auth.loadPasswordStatus();
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final userId = auth.currentUser?.id;
    if (userId != null && userId != _loadedFor) {
      _loadedFor = userId;
      // Gọi sau khung hình: notifyListeners() không được chạy giữa lúc đang dựng giao diện
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
    final showForm = auth.isSignedIn && auth.hasPassword != null;
    return Scaffold(
      appBar: SenpaiAppBar(title: auth.hasPassword == false ? 'Tạo mật khẩu' : 'Đổi mật khẩu'),
      body: _body(auth),
      bottomNavigationBar: showForm
          ? SenpaiBottomBar(
              children: [
                Expanded(
                  child: SenpaiButton(
                    label: auth.isLoading ? 'Đang lưu…' : 'Lưu mật khẩu',
                    onPressed: auth.isLoading ? null : _save,
                    expand: true,
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _body(AuthController auth) {
    if (!auth.isSignedIn) {
      return const AuthRequiredView(text: 'Bạn cần đăng nhập để đổi mật khẩu.');
    }
    final hasPassword = auth.hasPassword;
    if (hasPassword == null) {
      if (auth.error != null && !auth.isLoading) {
        return ErrorView(message: auth.error!, onRetry: _load);
      }
      return const LoadingView();
    }
    final errors = auth.fieldErrors;
    final blocks = <Widget>[
      SenpaiNote(
        hasPassword
            ? 'Đổi mật khẩu sẽ đăng xuất bạn khỏi các thiết bị khác.'
            : 'Tài khoản này đăng nhập bằng Google/Facebook. Tạo mật khẩu để đăng nhập được cả bằng email.',
        icon: Symbols.info_rounded,
        tone: SenpaiTone.ai,
      ),
      if (auth.bannerError != null) AuthNotice(text: auth.bannerError!),
      if (hasPassword)
        PasswordField(
          controller: _current,
          label: 'Mật khẩu hiện tại',
          errorText: errors['currentPassword'],
          textInputAction: TextInputAction.next,
        ),
      PasswordField(
        controller: _password,
        label: 'Mật khẩu mới',
        isNewPassword: true,
        errorText: errors['password'],
        textInputAction: TextInputAction.next,
      ),
      PasswordRules(controller: _password),
      PasswordField(
        controller: _confirm,
        label: 'Nhập lại mật khẩu mới',
        isNewPassword: true,
        errorText: errors['confirmPassword'],
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          // Điều kiện mật khẩu nằm sát ô "Mật khẩu mới" hơn các khối khác
          if (i > 0) SizedBox(height: blocks[i] is PasswordRules ? 12 : 16),
          blocks[i],
        ],
      ],
    );
  }

  Future<void> _save() async {
    final auth = context.read<AuthController>();
    final ok = await auth.changePassword(
      currentPassword: _current.text,
      password: _password.text,
      confirmPassword: _confirm.text,
    );
    if (ok && mounted) {
      showMessage(context, auth.takeMessage());
      Navigator.pop(context, true);
    }
  }
}
