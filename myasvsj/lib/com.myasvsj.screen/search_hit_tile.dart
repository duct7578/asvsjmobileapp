import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Một kết quả tìm kiếm (`hit()` của thiết kế): ô icon tròn 40 bên trái khi có [icon] (địa điểm), tiêu đề Title/S,
/// các dòng phụ cách 2; p[10,0]. Cả dòng mở mục đó. [trailing] là nút phụ (ví dụ "Nghe" của mẫu câu).
class SearchHitTile extends StatelessWidget {
  const SearchHitTile({
    super.key,
    this.icon,
    this.tone = SenpaiTone.ai,
    required this.title,
    this.children = const [],
    required this.onTap,
    this.trailing,
  });

  /// Biểu tượng trong ô tròn 40; null thì không có ô (bài viết, câu hỏi… như thiết kế).
  final IconData? icon;
  final SenpaiTone tone;
  final Widget title;
  final List<Widget> children;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          spacing: 12,
          children: [
            if (icon != null) IconTile(icon!, tone: tone, radius: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  DefaultTextStyle.merge(style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink), child: title),
                  ...children,
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
