import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.model/home_tag.dart';
import 'package:myasvsj/com.myasvsj.screen/home_format.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

/// Các tag định danh nhỏ cạnh tên người viết ("Mentor", "Kouhai"…): viên thuốc `badge()` p[3,8], chữ Label/S.
/// Màu lấy theo màu moderator đặt cho tag (server gửi): nền nhạt 12%, chữ đậm; tag không có màu dùng tone brand.
class HomeTagChips extends StatelessWidget {
  const HomeTagChips({super.key, required this.tags});

  final List<HomeTag> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        for (final tag in tags) _TagPill(tag: tag),
      ],
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.tag});

  final HomeTag tag;

  @override
  Widget build(BuildContext context) {
    final color = tagColor(tag.color);
    final background = color?.withValues(alpha: 0.12) ?? SenpaiTone.brand.background;
    final foreground = color ?? SenpaiTone.brand.foreground;
    return DecoratedBox(
      decoration: ShapeDecoration(color: background, shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(
          tag.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: SenpaiText.labelS.copyWith(color: foreground),
        ),
      ),
    );
  }
}
