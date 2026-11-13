import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/blog.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_badge.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// "Bài nổi bật tuần này / tháng này": các bài được chọn tự động theo lượt thích và bình luận, cuộn ngang.
///
/// Thiết kế: sectionHead có icon local_florist, dòng chú thích Caption, rồi các thẻ FeaturedCard rộng 250 (ảnh bìa
/// cao 96, nhãn "#hạng", tiêu đề 2 dòng, tác giả, thích, bình luận). Widget tự lề ngang 16 để hàng thẻ cuộn sát mép.
class BlogFeaturedList extends StatelessWidget {
  const BlogFeaturedList({super.key, required this.period, required this.posts});

  /// WEEK hoặc MONTH.
  final String? period;
  final List<Blog> posts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 14,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              SectionHead(
                'Bài nổi bật ${period == 'MONTH' ? 'tháng này' : 'tuần này'}',
                icon: Symbols.local_florist_rounded,
              ),
              Text(
                'Tự động chọn theo lượt thích và bình luận',
                style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // Các thẻ cùng hàng cao bằng nhau dù tiêu đề dài ngắn khác nhau
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [for (var i = 0; i < posts.length; i++) _FeaturedTile(blog: posts[i], rank: i + 1)],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeaturedTile extends StatelessWidget {
  const _FeaturedTile({required this.blog, required this.rank});

  final Blog blog;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final images = blog.images;
    return SizedBox(
      width: 250,
      child: SenpaiCard(
        radius: 18,
        padding: EdgeInsets.zero,
        onTap: blog.id == null
            ? null
            : () =>
                  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => BlogDetailScreen(blogId: blog.id!))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CoverArt(
              scene: CoverScene.forSeed(blog.id),
              imageUrl: images.isEmpty ? '' : images.first.url,
              width: 250,
              height: 96,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    BlogBadge(icon: Symbols.star_rounded, label: '#$rank'),
                    // Thẻ có tiêu đề ngắn vẫn đẩy dòng tác giả xuống đáy, thẳng hàng với thẻ bên cạnh
                    Expanded(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          blog.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink),
                        ),
                      ),
                    ),
                    Row(
                      spacing: 6,
                      children: [
                        Expanded(
                          child: Text(
                            blog.authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
                          ),
                        ),
                        IconStat(Icons.favorite_rounded, '${blog.likeCount}', color: SenpaiColors.brand),
                        IconStat(Symbols.chat_bubble_rounded, '${blog.commentCount}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
