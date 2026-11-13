import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Năm ngôi sao màu lantern của một review hoặc điểm trung bình (`stars(n, size)` của thiết kế, làm tròn tới nửa
/// sao), đọc cho trình đọc màn hình là "4.5 trên 5 sao".
class EventStars extends StatelessWidget {
  const EventStars({super.key, required this.rating, this.size = 16});

  /// 0 đến 5.
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${rating.toStringAsFixed(rating == rating.roundToDouble() ? 0 : 1)} trên 5 sao',
      excludeSemantics: true,
      child: StarRow(rating, size: size, color: SenpaiColors.lantern),
    );
  }
}
