import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/home_phrase.dart';
import 'package:myasvsj/com.myasvsj.screen/home_format.dart';
import 'package:myasvsj/com.myasvsj.screen/home_speak_button.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

/// "Câu tiếng Nhật hôm nay" (`phraseCard()` của thiết kế): thẻ nền ink bo 20, chữ "あ" mờ 6% ở góc phải, nhãn
/// loại mẫu câu, câu tiếng Nhật JP/L, romaji màu lantern, nghĩa tiếng Việt, nút "Nghe" và "Học thêm chủ đề này"
/// (mở Nhật ngữ).
class HomePhraseCard extends StatelessWidget {
  const HomePhraseCard({super.key, required this.phrase});

  final HomePhrase phrase;

  @override
  Widget build(BuildContext context) {
    final onInk = SenpaiText.bodyM.copyWith(color: SenpaiColors.onBrand);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: SenpaiColors.ink, borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          Positioned(
            // Như spec: hộp chữ cao 34 đặt ở y = -10, chữ 120 tràn lên trên nên chỉ thấy nửa dưới ở góc phải
            top: -50,
            right: -12,
            child: ExcludeSemantics(
              child: Text(
                'あ',
                style: SenpaiText.jpL.copyWith(
                  fontSize: 120,
                  height: 1,
                  color: SenpaiColors.onBrand.withValues(alpha: 0.06),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    const Icon(Symbols.translate_rounded, size: 20, color: SenpaiColors.lantern),
                    Expanded(
                      child: Text('Câu tiếng Nhật hôm nay',
                          style: SenpaiText.labelM.copyWith(color: SenpaiColors.onBrand)),
                    ),
                    if (phrase.categoryName.isNotEmpty) Flexible(child: _CategoryPill(phrase: phrase)),
                  ],
                ),
                Text(phrase.japanese, style: SenpaiText.jpL.copyWith(color: SenpaiColors.onBrand)),
                if (phrase.romaji.isNotEmpty)
                  Text(phrase.romaji, style: SenpaiText.bodyM.copyWith(color: SenpaiColors.lantern)),
                Text(phrase.meaningVi, style: onInk),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      HomeSpeakButton(text: phrase.japanese),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: SenpaiColors.onBrand,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: const Size(48, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => pushScreen<void>(
                          context,
                          PhraseScreen(
                            topicId: phrase.topicId,
                            categoryId: phrase.topicId == null ? phrase.categoryId : null,
                          ),
                        ),
                        icon: const Icon(Symbols.school_rounded, size: 18),
                        label: const Text('Học thêm chủ đề này'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Nhãn loại mẫu câu ("Cửa hàng tiện lợi"): viên thuốc trắng 14% p[3,10], icon 14, chữ Label/S.
class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.phrase});

  final HomePhrase phrase;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: ShapeDecoration(
        color: SenpaiColors.surface.withValues(alpha: 0.14),
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(categoryIcon(phrase.categoryIcon), size: 14, color: SenpaiColors.onBrand),
          Flexible(
            child: Text(
              phrase.categoryName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SenpaiText.labelS.copyWith(color: SenpaiColors.onBrand),
            ),
          ),
        ],
      ),
    );
  }
}
