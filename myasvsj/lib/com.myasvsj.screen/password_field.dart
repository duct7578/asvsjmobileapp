import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/auth_field.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Ô nhập mật khẩu có nút Hiện / Ẩn, dùng ở Đăng nhập, Đăng ký, Đặt lại và Đổi mật khẩu.
///
/// Theo `field(label, '••••', {icon: 'lock', trail: 'visibility'})` của thiết kế: nhãn [label] Label/M phía trên,
/// ô cao 52 bo 12 có icon khoá phía trước và nút con mắt phía sau; lỗi / gợi ý Caption phía dưới. Bên trong ô vẫn
/// có chữ [label] (gợi ý khi ô trống) nên `find.widgetWithText(TextField, label)` vẫn tìm được ô.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.helperText,
    this.isNewPassword = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? errorText;
  final String? helperText;

  /// Mật khẩu mới: giới hạn 72 ký tự và gợi ý tự điền "mật khẩu mới".
  final bool isNewPassword;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return SenpaiLabeledField(
      label: widget.label,
      child: TextField(
        controller: widget.controller,
        obscureText: !_visible,
        enableSuggestions: false,
        autocorrect: false,
        maxLength: widget.isNewPassword ? 72 : null,
        autofillHints: [widget.isNewPassword ? AutofillHints.newPassword : AutofillHints.password],
        textInputAction: widget.textInputAction,
        onSubmitted: widget.onSubmitted,
        decoration: authInputDecoration(
          widget.label,
          icon: Symbols.lock_rounded,
          errorText: widget.errorText,
          helperText: widget.helperText,
          counterText: '',
          suffixIcon: IconButton(
            tooltip: _visible ? 'Ẩn mật khẩu' : 'Hiện mật khẩu',
            icon: Icon(_visible ? Symbols.visibility_off_rounded : Symbols.visibility_rounded, size: 22),
            onPressed: () => setState(() => _visible = !_visible),
          ),
        ),
      ),
    );
  }
}
