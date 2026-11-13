import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Hàng 5 ngôi sao cho điểm [rating] (làm tròn tới nửa sao), chỉ để xem: `stars(n, size)` của thiết kế (sao đặc
/// màu lantern). Trình đọc màn hình đọc "4.5 trên 5 sao".
class PlaceRatingStars extends StatelessWidget {
  const PlaceRatingStars({super.key, required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final halves = (rating * 2).round() / 2;
    return Semantics(
      label: '${rating.toStringAsFixed(rating == rating.roundToDouble() ? 0 : 1)} trên 5 sao',
      child: ExcludeSemantics(child: StarRow(halves, size: size, color: SenpaiColors.lantern)),
    );
  }
}
