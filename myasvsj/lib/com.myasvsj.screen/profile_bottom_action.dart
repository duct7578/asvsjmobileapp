import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Thanh hành động dưới của các form cài đặt cá nhân (`bottomBar(s, [btn(...)])` của thiết kế): nền trắng, bóng
/// Bar, nút chính giãn hết chiều ngang. Lỗi của lần lưu / gửi vừa rồi ([error]) hiện ngay trên nút, để người dùng
/// thấy dù đang cuộn ở đâu trong form.
///
/// Dùng làm `Scaffold.bottomNavigationBar`.
class ProfileBottomAction extends StatelessWidget {
  const ProfileBottomAction({super.key, required this.button, this.error});

  /// Thường là `SenpaiButton(expand: true, …)`.
  final Widget button;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: SenpaiColors.surface, boxShadow: SenpaiColors.shadowBar),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: [
              if (error != null) SenpaiNote(error!, icon: Symbols.error_rounded, tone: SenpaiTone.crit),
              button,
            ],
          ),
        ),
      ),
    );
  }
}
