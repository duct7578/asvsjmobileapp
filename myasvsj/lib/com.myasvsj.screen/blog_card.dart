import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/blog.dart';
import 'package:myasvsj/com.myasvsj.model/topic.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_author_line.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_badge.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Một bài trong danh sách Blog (BlogCard của thiết kế): thẻ trắng bo 18; dòng nhãn "Đã ghim" + thời gian;
/// tiêu đề Title/S 2 dòng, trích đoạn Body/S 3 dòng và ảnh bìa 84 × 84 bo 12; chip chủ đề và địa điểm; dòng tác giả
/// với số thích, số bình luận. Bấm vào mở màn chi tiết.
///
/// Ảnh bìa là ảnh đầu tiên của bài, bài không có ảnh thì dùng cảnh minh hoạ cố định theo id bài.
///
/// [onTopicTap]: bấm chủ đề trên thẻ để lọc theo chủ đề đó (màn danh sách Blog); null thì chủ đề chỉ để xem.
class BlogCard extends StatelessWidget {
  const BlogCard({super.key, required this.blog, this.onTopicTap});

  final Blog blog;
  final ValueChanged<Topic>? onTopicTap;

  @override
  Widget build(BuildContext context) {
    final images = blog.images;
    return SenpaiCard(
      radius: 18,
      onTap: blog.id == null
          ? null
          : () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => BlogDetailScreen(blogId: blog.id!))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            spacing: 6,
            children: [
              if (blog.pinned) const BlogBadge(icon: Symbols.push_pin_rounded, label: 'Đã ghim'),
              if (blog.isProcessing)
                const Flexible(
                  child: BlogBadge(icon: Symbols.hourglass_top_rounded, label: 'Đang quét ảnh', warning: true),
                ),
              Expanded(
                child: Text(
                  blog.createdAt == null ? '' : formatTimeAgo(blog.createdAt!),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      blog.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink),
                    ),
                    if (blog.content.isNotEmpty)
                      Text(
                        blog.content,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
                      ),
                  ],
                ),
              ),
              CoverArt(
                scene: CoverScene.forSeed(blog.id),
                imageUrl: images.isEmpty ? '' : images.first.url,
                width: 84,
                height: 84,
                radius: 12,
              ),
            ],
          ),
          if (blog.topics.isNotEmpty || blog.places.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final topic in blog.topics) _topicChip(topic),
                for (final place in blog.places) PlaceChip(place.name),
              ],
            ),
          Row(
            spacing: 6,
            children: [
              Expanded(child: BlogAuthorLine(author: blog.author, dense: true)),
              IconStat(Symbols.favorite_rounded, '${blog.likeCount}'),
              IconStat(Symbols.chat_bubble_rounded, '${blog.commentCount}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topicChip(Topic topic) {
    final onTap = onTopicTap;
    if (onTap == null) {
      return TopicChip(topic.name);
    }
    return Tooltip(message: 'Lọc theo chủ đề này', child: BlogTopicTag(topic.name, onTap: () => onTap(topic)));
  }
}

/// `topicChip(name)` bấm được: chip chủ đề nền surface-2, icon sell 14, chữ Label/S muted, có gợn sóng khi bấm.
class BlogTopicTag extends StatelessWidget {
  const BlogTopicTag(this.name, {super.key, this.onTap});

  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SenpaiColors.surface2,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              const Icon(Symbols.sell_rounded, size: 14, color: SenpaiColors.muted),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SenpaiText.labelS.copyWith(color: SenpaiColors.muted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
