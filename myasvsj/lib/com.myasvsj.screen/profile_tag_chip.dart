import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.model/profile_tag.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Nhãn tag định danh (`outlineBadge()` của thiết kế): viên thuốc chỉ có viền, chữ Label/S, có thể kèm icon 14.
/// Chữ và viền mang màu của tag do server gửi, như trên web; màu sai hoặc trống thì dùng brand-text.
class ProfileTagChip extends StatelessWidget {
  const ProfileTagChip({super.key, required this.name, this.color = '', this.icon});

  final String name;

  /// Mã màu web, ví dụ "#2E7D5B"; sai hoặc trống thì dùng brand-text.
  final String color;

  /// Icon đứng trước tên (trang Tôi dùng icon "verified").
  final IconData? icon;

  /// Màu của tag [color]; null khi server không gửi màu hợp lệ.
  static Color? tintOf(String color) {
    final value = ProfileTag.parseColor(color);
    return value == null ? null : Color(value);
  }

  @override
  Widget build(BuildContext context) {
    final tint = tintOf(color) ?? SenpaiColors.brandText;
    return SenpaiOutlineBadge(name, color: tint, borderColor: tint, icon: icon);
  }
}
