import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/feed_post.dart';
import 'package:myasvsj/com.myasvsj.model/feed_reason.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/home_format.dart';
import 'package:myasvsj/com.myasvsj.screen/search_highlight.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Một bài của "Dành cho bạn": lý do được chọn, tiêu đề, đoạn trích, chủ đề, tác giả, lượt thích, bình luận.
/// Bấm vào thì mở bài viết.
///
/// [compact] true (trong thẻ "Dành cho bạn" của trang chủ, thiết kế 02): ô nền surface-2 bo 14 p12, không ảnh.
/// false (màn "Dành cho bạn", thiết kế 04): thẻ trắng bo 18 viền line p14, ảnh minh hoạ 76 × 76 bên phải
/// tiêu đề, badge chủ đề.
class FeedPostCard extends StatelessWidget {
  const FeedPostCard({super.key, required this.post, this.showExcerpt = true, this.query = '', this.compact = false});

  final FeedPost post;

  /// Bài đầu của trang chủ và mọi bài ở màn "Dành cho bạn" có đoạn trích; các bài sau trên trang chủ thì không.
  final bool showExcerpt;

  /// Từ khóa đang tìm, được tô trong tiêu đề và đoạn trích.
  final String query;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final reasons = post.reasons.isEmpty
        ? null
        : Wrap(spacing: 6, runSpacing: 6, children: [for (final r in post.reasons) _ReasonBadge(reason: r)]);
    final title = SearchHighlight(
      text: post.title,
      query: query,
      style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink),
      maxLines: 2,
    );
    final excerpt = showExcerpt && post.excerpt.isNotEmpty
        ? SearchHighlight(
            text: post.excerpt,
            query: query,
            style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
            maxLines: compact ? 2 : 3,
          )
        : null;
    void open() => pushScreen<void>(context, BlogDetailScreen(blogId: post.id));

    if (compact) {
      return SenpaiCard(
        color: SenpaiColors.surface2,
        borderColor: null,
        radius: 14,
        padding: const EdgeInsets.all(12),
        onTap: open,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [?reasons, title, ?excerpt, _meta(filledHeart: true)],
        ),
      );
    }
    final topic = post.topicName ?? '';
    return SenpaiCard(
      radius: 18,
      onTap: open,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          ?reasons,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [title, ?excerpt],
                ),
              ),
              CoverArt(scene: CoverScene.forSeed(post.id), width: 76, height: 76, radius: 12),
            ],
          ),
          if (topic.isNotEmpty) SenpaiBadge(topic, tone: SenpaiTone.neutral, icon: Symbols.sell_rounded),
          _meta(filledHeart: false),
        ],
      ),
    );
  }

  /// "Tác giả · 2 giờ trước", tim + số thích, bong bóng + số bình luận (Caption muted, icon 16).
  Widget _meta({required bool filledHeart}) {
    final caption = SenpaiText.caption.copyWith(color: SenpaiColors.muted);
    return Row(
      spacing: 4,
      children: [
        Expanded(
          child: Text(
            [post.authorName, if (post.createdAt != null) formatTimeAgo(post.createdAt!)].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: caption,
          ),
        ),
        filledHeart
            ? const Icon(Icons.favorite_rounded, size: 16, color: SenpaiColors.brand)
            : const Icon(Symbols.favorite_rounded, size: 16, color: SenpaiColors.muted),
        Text('${post.likeCount}', style: caption, semanticsLabel: '${post.likeCount} lượt thích'),
        const SizedBox(width: 6),
        const Icon(Symbols.chat_bubble_rounded, size: 16, color: SenpaiColors.muted),
        Text('${post.commentCount}', style: caption, semanticsLabel: '${post.commentCount} bình luận'),
      ],
    );
  }
}

/// Một lý do: `badge("Gần khu vực của bạn · Ga Nippori", brand, icon)`; icon theo loại lý do.
class _ReasonBadge extends StatelessWidget {
  const _ReasonBadge({required this.reason});

  final FeedReason reason;

  @override
  Widget build(BuildContext context) {
    final icon = switch (reason.code) {
      'AREA' => Symbols.location_on_rounded,
      'PREFECTURE' => Symbols.map_rounded,
      'STAGE' => Symbols.flag_rounded,
      'INTEREST' => Symbols.interests_rounded,
      _ => Symbols.auto_awesome_rounded,
    };
    final detail = reason.detail;
    final text = detail == null || detail.isEmpty ? reason.label : '${reason.label} · $detail';
    return SenpaiBadge(text, tone: SenpaiTone.brand, icon: icon);
  }
}
