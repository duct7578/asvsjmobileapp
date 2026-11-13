import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/blog_overview.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_author_line.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Thống kê cộng đồng của Blog (cột bên phải trên web): "Chủ đề phổ biến" và "Senpai viết nhiều".
///
/// Thiết kế (khối Stats): hộp trắng bo 16 viền line, lề [12,14], ô icon insights tone ai 36, tiêu đề Title/S,
/// dòng phụ Caption, mũi tên expand_more. Thu gọn mặc định; bấm để mở. Bấm một chủ đề để lọc theo chủ đề đó.
class BlogStatsCard extends StatefulWidget {
  const BlogStatsCard({super.key, required this.overview, required this.onTopicTap});

  final BlogOverview overview;
  final ValueChanged<int> onTopicTap;

  @override
  State<BlogStatsCard> createState() => _BlogStatsCardState();
}

class _BlogStatsCardState extends State<BlogStatsCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return SenpaiCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            child: InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  spacing: 12,
                  children: [
                    const IconTile(Symbols.insights_rounded, tone: SenpaiTone.ai, size: 36, radius: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Thống kê cộng đồng', style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
                          Text(
                            'Chủ đề phổ biến, Senpai viết nhiều',
                            style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Symbols.expand_more_rounded, size: 24, color: SenpaiColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _open ? _details() : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _details() {
    final overview = widget.overview;
    final note = SenpaiText.bodyS.copyWith(color: SenpaiColors.muted);
    final count = SenpaiText.caption.copyWith(color: SenpaiColors.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const OverlineLabel('Chủ đề phổ biến'),
              const SizedBox(height: 4),
              if (overview.popularTopics.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Chưa có dữ liệu.', style: note))
              else
                for (final topic in overview.popularTopics)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => widget.onTopicTap(topic.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        spacing: 10,
                        children: [
                          const Icon(Symbols.sell_rounded, size: 18, color: SenpaiColors.muted),
                          Expanded(
                            child: Text(
                              topic.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink),
                            ),
                          ),
                          Text('${topic.postCount} bài', style: count),
                          const Icon(Symbols.chevron_right_rounded, size: 20, color: SenpaiColors.muted),
                        ],
                      ),
                    ),
                  ),
              const SizedBox(height: 12),
              const OverlineLabel('Senpai viết nhiều'),
              const SizedBox(height: 2),
              Text('Trong ${overview.topWritersDays} ngày qua', style: count),
              const SizedBox(height: 4),
              if (overview.topWriters.isEmpty)
                Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Chưa có dữ liệu.', style: note))
              else
                for (final writer in overview.topWriters)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      spacing: 8,
                      children: [
                        Expanded(child: BlogAuthorLine(author: writer.author, dense: true)),
                        Text('${writer.postCount} bài', style: count),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
