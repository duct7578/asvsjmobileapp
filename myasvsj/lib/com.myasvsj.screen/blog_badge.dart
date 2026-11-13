import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Nhãn nhỏ có biểu tượng trên thẻ bài và màn chi tiết (`badge(text, tone, icon)` của thiết kế), ví dụ
/// "Đã ghim", "#1" (tone lantern), "Đang quét ảnh" (tone warn).
///
/// [warning] dùng tone warn cho nhãn cần chú ý (bài đang quét, bị ẩn); [tone] đặt tone khác khi cần.
class BlogBadge extends StatelessWidget {
  const BlogBadge({super.key, required this.icon, required this.label, this.warning = false, this.tone});

  final IconData icon;
  final String label;
  final bool warning;

  /// Mặc định lantern (nhãn "Đã ghim", "#1" của thiết kế), hoặc warn khi [warning].
  final SenpaiTone? tone;

  @override
  Widget build(BuildContext context) {
    return SenpaiBadge(label, icon: icon, tone: tone ?? (warning ? SenpaiTone.warn : SenpaiTone.lantern));
  }
}
