import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.model/guide.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// `guideCard` của màn 22: thẻ trắng bo 18, ảnh bìa 88 bo 14 (ảnh thật hoặc cảnh minh hoạ), chủ đề Overline brand,
/// tiêu đề Title/S 2 dòng, tóm tắt Body/S 2 dòng, "giai đoạn · ngày tạo" Caption.
class GuideCard extends StatelessWidget {
  const GuideCard({super.key, required this.guide, this.onTap});

  final Guide guide;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final created = guide.createdAt;
    final meta = [
      if (guide.stageName != null && guide.stageName!.isNotEmpty) guide.stageName!,
      if (created != null) formatDate(created),
    ].join(' · ');
    return SenpaiCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          CoverArt(
            scene: CoverScene.forSeed(guide.id),
            imageUrl: guide.coverImageUrl ?? '',
            width: 88,
            height: 88,
            radius: 14,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  (guide.topicName ?? 'Cẩm nang').toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SenpaiText.overline.copyWith(color: SenpaiColors.brand),
                ),
                Text(
                  guide.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink),
                ),
                Text(
                  guide.summary.isEmpty ? 'Hướng dẫn dành cho sinh viên Việt Nam tại Nhật Bản.' : guide.summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
                ),
                if (meta.isNotEmpty)
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
