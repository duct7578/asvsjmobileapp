import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

/// Nhãn nhỏ có biểu tượng trên câu hỏi / câu trả lời: "Đã giải quyết", "Chưa ai trả lời", "Đã ghim",
/// "Câu trả lời hay nhất", tag và cấp bậc của người viết… Kiểu `badge(text, tone, icon)` của thiết kế: viên thuốc
/// p[3,8], icon 14, chữ Label/S.
///
/// Màu theo [tone] (mặc định neutral); [background] / [foreground] khác null thì dùng thay cho màu của tone.
class QuestionBadge extends StatelessWidget {
  const QuestionBadge({
    super.key,
    required this.label,
    this.icon,
    this.background,
    this.foreground,
    this.tone = SenpaiTone.neutral,
  });

  final String label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;
  final SenpaiTone tone;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? tone.foreground;
    return DecoratedBox(
      decoration: ShapeDecoration(color: background ?? tone.background, shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            if (icon != null) Icon(icon, size: 14, color: fg),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: SenpaiText.labelS.copyWith(color: fg)),
            ),
          ],
        ),
      ),
    );
  }
}
