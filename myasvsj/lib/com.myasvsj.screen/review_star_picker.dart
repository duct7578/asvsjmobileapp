import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

/// Chọn số sao 1–5 cho review (`ratingPicker` của màn 10): 5 sao đặc 40 (đã chọn màu lantern, chưa chọn viền
/// muted), bên phải "4/5" Title/M và lời đánh giá Caption ("Rất tốt"). [value] 0 là chưa chọn ("Chọn số sao").
/// [errorText] hiện dưới hàng sao.
class ReviewStarPicker extends StatelessWidget {
  const ReviewStarPicker({super.key, required this.value, required this.onChanged, this.errorText});

  final int value;
  final ValueChanged<int> onChanged;
  final String? errorText;

  /// Lời đánh giá theo số sao.
  static const labels = {1: 'Tệ', 2: 'Chưa tốt', 3: 'Tạm được', 4: 'Rất tốt', 5: 'Tuyệt vời'};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Row(
          spacing: 4,
          children: [
            for (var n = 1; n <= 5; n++)
              Tooltip(
                message: '$n sao',
                child: Semantics(
                  button: true,
                  selected: n <= value,
                  child: InkResponse(
                    onTap: () => onChanged(n),
                    radius: 24,
                    child: Icon(
                      n <= value ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 40,
                      color: n <= value ? SenpaiColors.lantern : SenpaiColors.muted,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 2),
            Flexible(
              child: value > 0
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$value/5', style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink)),
                        if (labels[value] != null)
                          Text(labels[value]!, style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
                      ],
                    )
                  : Text('Chọn số sao', style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
            ),
          ],
        ),
        if (errorText != null) Text(errorText!, style: SenpaiText.caption.copyWith(color: SenpaiColors.crit)),
      ],
    );
  }
}
