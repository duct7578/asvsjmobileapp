import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

/// Các điều kiện của mật khẩu mới ("Từ 8 ký tự", "Có chữ", "Có số"), tự đánh dấu khi đang gõ như trang web.
///
/// Theo thiết kế (màn 41): xếp dọc cách 6, mỗi dòng icon 18 + chữ Body/S; đạt thì check_circle đặc màu ok, chưa
/// đạt thì vòng tròn rỗng màu muted.
class PasswordRules extends StatelessWidget {
  const PasswordRules({super.key, required this.controller, this.minLength = AuthController.defaultPasswordMinLength});

  /// Ô mật khẩu đang theo dõi.
  final TextEditingController controller;
  final int minLength;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          for (final rule in AuthController.passwordChecklist(controller.text, minLength: minLength))
            Row(
              spacing: 8,
              children: [
                Icon(
                  rule.ok ? Icons.check_circle_rounded : Symbols.radio_button_unchecked_rounded,
                  size: 18,
                  color: rule.ok ? SenpaiColors.ok : SenpaiColors.muted,
                ),
                Flexible(
                  child: Text(
                    rule.label,
                    style: SenpaiText.bodyS.copyWith(color: rule.ok ? SenpaiColors.ok : SenpaiColors.muted),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
