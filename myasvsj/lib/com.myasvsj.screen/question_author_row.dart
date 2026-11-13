import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/author.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/question_badge.dart';
import 'package:myasvsj/com.myasvsj.screen/question_style.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Dòng người viết của câu hỏi / câu trả lời: ảnh đại diện, tên, tag định danh, cấp bậc, thời gian, "đã sửa".
///
/// - Mặc định là `authorLine` của thiết kế: ảnh đại diện 32, tên Label/M kèm tag (badge ai) và cấp bậc (badge
///   lantern), dòng thời gian Caption muted bên dưới; [trailing] (ví dụ nút "Nhắn tin") ở cuối dòng.
/// - [compact]: một dòng nhỏ như chân thẻ câu hỏi / phản hồi lồng: ảnh đại diện 22 (ẩn khi [showAvatar] false),
///   tên Label/S, tag, "· thời gian" Caption; tự xuống dòng khi hết chỗ.
class QuestionAuthorRow extends StatelessWidget {
  const QuestionAuthorRow({
    super.key,
    required this.author,
    this.createdAt,
    this.edited = false,
    this.showRank = true,
    this.trailing,
    this.compact = false,
    this.showAvatar = true,
    this.showTags = true,
  });

  /// null khi tài khoản không còn.
  final Author? author;
  final DateTime? createdAt;
  final bool edited;
  final bool showRank;

  /// Nút thêm ở cuối dòng (ví dụ "Nhắn tin").
  final Widget? trailing;

  /// Kiểu một dòng nhỏ.
  final bool compact;
  final bool showAvatar;

  /// false: không hiện tag định danh (chân thẻ câu hỏi trong danh sách, như thiết kế).
  final bool showTags;

  @override
  Widget build(BuildContext context) {
    final name = author?.displayName.isNotEmpty == true ? author!.displayName : 'Tài khoản không còn';
    final when = [if (createdAt != null) formatTimeAgo(createdAt!), if (edited) 'đã sửa'].join(' · ');
    final badges = [
      if (showTags)
        for (final tag in author?.tagNames ?? const <String>[]) QuestionBadge(label: tag, tone: SenpaiTone.ai),
      if (showRank && (author?.rankName.isNotEmpty ?? false))
        QuestionBadge(label: author!.rankName, icon: Symbols.military_tech_rounded, tone: SenpaiTone.lantern),
    ];
    final avatar = SenpaiAvatar(
      name: name,
      imageUrl: author?.avatarUrl ?? '',
      size: compact ? 22 : 32,
      tone: questionAvatarTone(author?.id),
    );

    if (compact && badges.isEmpty && trailing == null) {
      // Chỉ có tên và thời gian: một dòng; hết chỗ thì cắt ở cuối (tên luôn hiện trước)
      return Row(
        spacing: 6,
        children: [
          if (showAvatar) avatar,
          Flexible(
            child: Text.rich(
              TextSpan(
                text: name,
                style: SenpaiText.labelS.copyWith(color: SenpaiColors.ink),
                children: [
                  if (when.isNotEmpty)
                    TextSpan(text: '  · $when', style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    if (compact) {
      return Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (showAvatar) avatar,
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: SenpaiText.labelS.copyWith(color: SenpaiColors.ink)),
          ...badges,
          if (when.isNotEmpty) Text('· $when', style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
          ?trailing,
        ],
      );
    }

    return Row(
      spacing: 8,
      children: [
        avatar,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(name,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink)),
                  ...badges,
                ],
              ),
              if (when.isNotEmpty) Text(when, style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
            ],
          ),
        ),
        if (trailing != null) Padding(padding: const EdgeInsets.only(left: 2), child: trailing),
      ],
    );
  }
}
