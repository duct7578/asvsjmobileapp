import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/sign_in_gate.dart';

/// Thân màn "Tin nhắn" / "Trò chuyện" khi là khách: ô icon forum brand-soft, câu mời và nút "Đăng nhập" (mở màn
/// Đăng nhập qua requireSignIn).
class ChatGuestView extends StatelessWidget {
  const ChatGuestView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 14,
          children: [
            const IconTile(Symbols.forum_rounded, tone: SenpaiTone.brand, size: 64, radius: 32),
            Text(
              'Đăng nhập để nhắn tin với thành viên khác.',
              textAlign: TextAlign.center,
              style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
            ),
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
