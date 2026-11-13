import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/author.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Người viết bài hoặc bình luận: ảnh đại diện, tên, tag định danh và (khi [showRank]) cấp bậc.
///
/// [dense] (thẻ bài trong danh sách, "Senpai viết nhiều"): một dòng như dòng tác giả của BlogCard trong thiết kế:
/// ảnh đại diện 28, tên Label/S, tag đầu tiên (badge ai).
///
/// Ngược lại (màn chi tiết, khối AuthorLine của thiết kế): ảnh đại diện 44, tên Title/S, các tag (badge ai) và cấp
/// bậc (badge lantern), dòng [subtitle] Caption muted (thời gian), [trailing] bên phải (nút "Nhắn tin").
class BlogAuthorLine extends StatelessWidget {
  const BlogAuthorLine({
    super.key,
    required this.author,
    this.dense = false,
    this.showRank = false,
    this.subtitle,
    this.trailing,
  });

  final Author? author;
  final bool dense;
  final bool showRank;

  /// Dòng nhỏ dưới tên, ví dụ "hôm qua · đã sửa" (chỉ dùng khi không [dense]).
  final String? subtitle;

  /// Nút bên phải (chỉ dùng khi không [dense]).
  final Widget? trailing;

  /// Tone ảnh đại diện cố định theo người: cùng người luôn cùng màu, người khác nhau khác màu như thiết kế.
  static SenpaiTone toneOf(Author? author) {
    const tones = [SenpaiTone.brand, SenpaiTone.lantern, SenpaiTone.ok, SenpaiTone.ai];
    return author == null ? SenpaiTone.neutral : tones[author.id.abs() % tones.length];
  }

  /// Ảnh đại diện tròn cỡ [size]: ảnh thật nếu có, không thì chữ cái đầu ('?' khi tài khoản đã xóa).
  static Widget avatarOf(Author? author, double size) {
    return SenpaiAvatar(
      name: author?.displayName ?? '',
      imageUrl: author?.avatarUrl ?? '',
      size: size,
      tone: toneOf(author),
    );
  }

  /// Tên hiện ra; tài khoản đã xóa thì "Tài khoản đã xóa".
  static String nameOf(Author? author) {
    final name = author?.displayName ?? '';
    return name.isEmpty ? 'Tài khoản đã xóa' : name;
  }

  @override
  Widget build(BuildContext context) {
    final tags = author?.tagNames ?? const <String>[];
    if (dense) {
      return Row(
        spacing: 6,
        children: [
          avatarOf(author, 28),
          Flexible(
            child: Text(
              nameOf(author),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SenpaiText.labelS.copyWith(color: SenpaiColors.ink),
            ),
          ),
          if (tags.isNotEmpty) Flexible(child: SenpaiBadge(tags.first, tone: SenpaiTone.ai)),
        ],
      );
    }
    final rank = author?.rankName ?? '';
    final showBadges = tags.isNotEmpty || (showRank && rank.isNotEmpty);
    return Row(
      spacing: 10,
      children: [
        avatarOf(author, 44),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Text(
                nameOf(author),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink),
              ),
              if (showBadges)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final tag in tags) SenpaiBadge(tag, tone: SenpaiTone.ai),
                    if (showRank && rank.isNotEmpty)
                      SenpaiBadge(rank, tone: SenpaiTone.lantern, icon: Symbols.military_tech_rounded),
                  ],
                ),
              if (subtitle != null && subtitle!.isNotEmpty)
                Text(subtitle!, style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}
