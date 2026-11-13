import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Câu "chưa có gì" ở giữa màn hình: ô icon tròn brand-soft và câu Body/M muted. Đặt trong ListView để vẫn kéo
/// xuống làm mới được.
class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.text, this.icon = Symbols.inbox_rounded});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          IconTile(icon, tone: SenpaiTone.brand, size: 56, radius: 28),
          Text(text, textAlign: TextAlign.center, style: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted)),
        ],
      ),
    );
  }
}
