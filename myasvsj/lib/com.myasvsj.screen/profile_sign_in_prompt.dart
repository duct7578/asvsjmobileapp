import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/sign_in_gate.dart';

/// Lời mời đăng nhập cho các màn hình cá nhân khi người xem là khách (Tôi, Đã lưu, Lịch sử điểm…): ô icon tròn
/// brand-soft 64, câu Body/M và nút Primary "Đăng nhập", cùng kiểu với AuthRequiredView.
/// Đăng nhập xong, màn hình tự tải dữ liệu vì nó theo dõi AuthController.
class ProfileSignInPrompt extends StatelessWidget {
  const ProfileSignInPrompt({super.key, this.text = 'Đăng nhập để dùng mục này.'});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 14,
          children: [
            const IconTile(Symbols.account_circle_rounded, tone: SenpaiTone.brand, size: 64, radius: 32),
            Text(text, textAlign: TextAlign.center, style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink)),
            SenpaiButton(
              label: 'Đăng nhập',
              icon: Symbols.login_rounded,
              size: SenpaiButtonSize.medium,
              onPressed: () => requireSignIn(context),
            ),
          ],
        ),
      ),
    );
  }
}
