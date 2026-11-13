import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Thân màn hình khi việc này cần đăng nhập mà người dùng là khách (hoặc phiên vừa hết): ô icon khoá brand-soft,
/// câu giải thích và nút "Đăng nhập".
class AuthRequiredView extends StatelessWidget {
  const AuthRequiredView({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 14,
          children: [
            const IconTile(Symbols.lock_rounded, tone: SenpaiTone.brand, size: 64, radius: 32),
            Text(text, textAlign: TextAlign.center, style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink)),
            SenpaiButton(
              label: 'Đăng nhập',
              icon: Symbols.login_rounded,
              size: SenpaiButtonSize.medium,
              onPressed: () => Navigator.push(context, MaterialPageRoute<bool>(builder: (_) => const LoginScreen())),
            ),
          ],
        ),
      ),
    );
  }
}
