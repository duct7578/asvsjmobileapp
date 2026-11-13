import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Hộp thông báo ở đầu các form tài khoản (giống ô "alert" của trang web), kiểu `note(icon, text, tone)` của thiết
/// kế: lỗi nền crit-soft icon error, tin tốt nền ok-soft icon check_circle.
class AuthNotice extends StatelessWidget {
  const AuthNotice({super.key, required this.text, this.isError = true, this.margin = const EdgeInsets.only(bottom: 12)});

  final String text;
  final bool isError;

  /// Khoảng cách quanh hộp; màn hình đã tự chia khoảng cách giữa các khối thì truyền EdgeInsets.zero.
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: SenpaiNote(
        text,
        icon: isError ? Symbols.error_rounded : Symbols.check_circle_rounded,
        tone: isError ? SenpaiTone.crit : SenpaiTone.ok,
      ),
    );
  }
}
