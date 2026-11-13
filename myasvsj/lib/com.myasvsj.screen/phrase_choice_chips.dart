import 'package:flutter/material.dart';

/// Một hàng lựa chọn của Nhật ngữ ("Từ vựng (4) / Mẫu câu (7)", "Tất cả / Chưa thuộc / Đã thuộc / Chưa luyện"):
/// các ChoiceChip của thiết kế (`chips()`: cao 36, viên thuốc, chọn thì nền brand, không dấu tích) tự xuống dòng
/// nên không tràn trên màn hẹp. [options] là (giá trị, nhãn), chọn đúng một.
class PhraseChoiceChips extends StatelessWidget {
  const PhraseChoiceChips({super.key, required this.options, required this.selected, required this.onSelected});

  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (value, label) in options)
          ChoiceChip(
            label: Text(label),
            selected: value == selected,
            showCheckmark: false,
            // Không thêm lề vùng chạm 48 quanh chip cao 36 (theme) làm các hàng cách xa nhau
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onSelected: (_) => onSelected(value),
          ),
      ],
    );
  }
}
