import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

/// `info(icon, text)` của thiết kế: icon 18 muted và chữ Body/S (ngày, nơi tổ chức, chi phí), cắt bớt khi quá
/// [maxLines] dòng.
class EventInfoLine extends StatelessWidget {
  const EventInfoLine({super.key, required this.icon, required this.text, this.maxLines = 1, this.color = SenpaiColors.ink});

  final IconData icon;
  final String text;
  final int maxLines;

  /// Màu chữ (muted cho dòng phụ như "chưa gắn vị trí").
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Icon(icon, size: 18, color: SenpaiColors.muted),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: SenpaiText.bodyS.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
