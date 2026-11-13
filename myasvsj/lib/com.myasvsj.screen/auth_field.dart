import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

// Mảnh giao diện dùng chung của các màn tài khoản (Đăng nhập, Đăng ký, Quên mật khẩu, ô mật khẩu): ô nhập kiểu
// `field(label, value, {icon, trail})`, link chữ gọn và dòng cuối `authFooter(q, link)` của thiết kế.

/// InputDecoration của ô nhập trên các màn tài khoản: icon 22 phía trước (lề 14, cách chữ 10), [hint] bên trong,
/// lỗi / gợi ý Caption phía dưới. Nhãn Label/M đặt phía trên bằng SenpaiLabeledField.
///
/// [hint] thường trùng nhãn để ô vẫn mang tên của nó (trình đọc màn hình, `find.widgetWithText(TextField, 'Email')`).
InputDecoration authInputDecoration(
  String hint, {
  IconData? icon,
  Widget? suffixIcon,
  String? errorText,
  String? helperText,
  String? counterText,
}) {
  return InputDecoration(
    hintText: hint,
    hintMaxLines: 1,
    prefixIcon: icon == null
        ? null
        : Padding(
            // Ô cách chữ 4 sẵn (Material 3): 14 + 22 + 6 + 4 = chữ bắt đầu ở 46 như thiết kế
            padding: const EdgeInsetsDirectional.only(start: 14, end: 6),
            child: Icon(icon, size: 22),
          ),
    prefixIconConstraints: const BoxConstraints(minHeight: 48),
    // Có icon thì lề trái của chữ do icon quyết định; lề trái 0 để dòng gợi ý / lỗi bên dưới thẳng mép ô như
    // `field(…, {help})` của thiết kế (Material thêm 4)
    contentPadding: icon == null ? null : const EdgeInsetsDirectional.fromSTEB(0, 15, 14, 15),
    suffixIcon: suffixIcon,
    errorText: errorText,
    errorMaxLines: 3,
    helperText: helperText,
    helperMaxLines: 3,
    counterText: counterText,
  );
}

/// Link chữ gọn của form ("Quên mật khẩu?", "Đăng ký", "Đổi", "Gửi lại mã"): TextButton chữ Label/M brand-text
/// (khoá thì muted), cao 32, lề ngang 4.
final ButtonStyle authLinkStyle = TextButton.styleFrom(
  foregroundColor: SenpaiColors.brandText,
  disabledForegroundColor: SenpaiColors.muted,
  textStyle: SenpaiText.labelM,
  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
  minimumSize: const Size(0, 32),
  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  visualDensity: VisualDensity.standard,
  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
);

/// `authFooter(q, link)`: câu hỏi Body/S muted + link Label/M brand-text ở giữa ("Chưa có tài khoản? Đăng ký").
class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key, required this.question, required this.action, required this.onPressed});

  final String question;
  final String action;

  /// null: link bị khoá (đang gửi yêu cầu).
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(question, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
        TextButton(style: authLinkStyle, onPressed: onPressed, child: Text(action)),
      ],
    );
  }
}
