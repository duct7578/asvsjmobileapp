import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/question.dart';
import 'package:myasvsj/com.myasvsj.screen/question_author_row.dart';
import 'package:myasvsj/com.myasvsj.screen/question_badge.dart';
import 'package:myasvsj/com.myasvsj.screen/question_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Một câu hỏi trong danh sách Hỏi-Đáp (`qCard` của màn 15): ô số câu trả lời bên trái, bên phải là nhãn trạng
/// thái, câu hỏi Title/S (3 dòng), đoạn trích Body/S muted (2 dòng), chủ đề / địa điểm, người hỏi và lượt thích.
/// Thẻ trắng bo 18, viền line, lề 14. Bấm vào mở màn chi tiết.
class QuestionCard extends StatelessWidget {
  const QuestionCard({super.key, required this.question, this.onTopicTap});

  final Question question;

  /// Bấm một chủ đề trên thẻ: lọc danh sách theo chủ đề đó. null = chủ đề chỉ để xem.
  final ValueChanged<int>? onTopicTap;

  @override
  Widget build(BuildContext context) {
    final q = question;
    final badges = [
      if (q.pinned) const QuestionBadge(label: 'Đã ghim', icon: Symbols.push_pin_rounded, tone: SenpaiTone.lantern),
      if (q.isSolved)
        const QuestionBadge(label: 'Đã giải quyết', icon: Symbols.check_circle_rounded, tone: SenpaiTone.ok)
      else if (q.unanswered)
        const QuestionBadge(label: 'Chưa ai trả lời', icon: Symbols.hourglass_empty_rounded, tone: SenpaiTone.lantern),
      if (q.status == 'PROCESSING')
        const QuestionBadge(label: 'Đang quét ảnh/video', icon: Symbols.hourglass_top_rounded, tone: SenpaiTone.warn),
    ];
    return SenpaiCard(
      radius: 18,
      onTap: q.id == null
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => QuestionDetailScreen(questionId: q.id!)),
            ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          _AnswerCount(question: q),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                if (badges.isNotEmpty) Wrap(spacing: 6, runSpacing: 6, children: badges),
                Text(q.title,
                    maxLines: 3, overflow: TextOverflow.ellipsis, style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
                if (q.content.isNotEmpty)
                  Text(q.content,
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
                if (q.topics.isNotEmpty || q.places.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final t in q.topics)
                        InkWell(
                          onTap: onTopicTap == null ? null : () => onTopicTap!(t.id),
                          customBorder: const StadiumBorder(),
                          child: TopicChip(t.name),
                        ),
                      for (final p in q.places) PlaceChip(p.name),
                    ],
                  ),
                Row(
                  spacing: 6,
                  children: [
                    Expanded(
                      child: QuestionAuthorRow(
                        author: q.author,
                        createdAt: q.createdAt,
                        showRank: false,
                        showTags: false,
                        compact: true,
                      ),
                    ),
                    Semantics(
                      label: '${q.likeCount} lượt thích',
                      excludeSemantics: true,
                      child: IconStat(Symbols.favorite_rounded, '${q.likeCount}'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `countBox` của thiết kế: ô 52 × 64 bo 14 ghi số câu trả lời. Đã giải quyết: nền ok, dấu tích, chữ trắng;
/// chưa ai trả lời: nền lantern-soft; đã có trả lời: nền trắng viền line.
class _AnswerCount extends StatelessWidget {
  const _AnswerCount({required this.question});

  final Question question;

  @override
  Widget build(BuildContext context) {
    final solved = question.isSolved;
    final none = !solved && (question.unanswered || question.answerCount == 0);
    final (Color fill, Color number, Color label) = solved
        ? (SenpaiColors.ok, SenpaiColors.onBrand, SenpaiColors.onBrand)
        : none
            ? (SenpaiColors.lanternSoft, SenpaiColors.lanternText, SenpaiColors.lanternText)
            : (SenpaiColors.surface, SenpaiColors.ink, SenpaiColors.muted);
    // Chữ "trả lời" cỡ 10 đúng như spec (Caption thu nhỏ để vừa ô 52)
    final small = SenpaiText.caption.copyWith(fontSize: 10, color: label);
    return Semantics(
      label: solved ? 'Đã giải quyết, ${question.answerCount} câu trả lời' : '${question.answerCount} câu trả lời',
      excludeSemantics: true,
      child: Container(
        width: 52,
        height: 64,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(14),
          border: solved || none ? null : Border.all(color: SenpaiColors.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (solved) const Icon(Symbols.check_rounded, size: 18, color: SenpaiColors.onBrand),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${question.answerCount}',
                style: (solved ? SenpaiText.labelM : SenpaiText.titleM).copyWith(color: number),
              ),
            ),
            Text('trả lời', style: small),
          ],
        ),
      ),
    );
  }
}
