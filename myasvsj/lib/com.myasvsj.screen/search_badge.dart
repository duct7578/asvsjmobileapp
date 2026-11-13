import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Nhãn nhỏ trong dòng phụ của kết quả ("Đã giải quyết", "Đang kiểm duyệt", tên chủ đề…): `badge()` của thiết kế.
/// [warn] dùng tone warn; không thì [tone] (mặc định neutral).
class SearchBadge extends StatelessWidget {
  const SearchBadge({super.key, required this.text, this.warn = false, this.tone = SenpaiTone.neutral, this.icon});

  final String text;
  final bool warn;
  final SenpaiTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SenpaiBadge(text, tone: warn ? SenpaiTone.warn : tone, icon: icon);
}
