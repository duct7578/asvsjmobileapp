import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/place_phrase.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Một từ vựng / mẫu câu tiếng Nhật dùng ở địa điểm, có nút "Nghe" (giọng ja-JP). Cùng kiểu `phraseCard` của
/// thiết kế: thẻ bo 18, badge loại, câu tiếng Nhật JP/M, romaji brand-text, nghĩa tiếng Việt, nút Nghe cỡ S.
class PlacePhraseTile extends StatelessWidget {
  const PlacePhraseTile({super.key, required this.phrase, required this.onSpeak});

  final PlacePhrase phrase;
  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    return SenpaiCard(
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          SenpaiBadge(phrase.kindLabel, tone: phrase.kind == 'VOCAB' ? SenpaiTone.ai : SenpaiTone.brand),
          Text(phrase.japanese, style: SenpaiText.jpM.copyWith(color: SenpaiColors.ink)),
          if (phrase.romaji.isNotEmpty)
            Text(phrase.romaji, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.brandText)),
          if (phrase.meaningVi.isNotEmpty) Text(phrase.meaningVi, style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink)),
          Tooltip(
            message: 'Nghe',
            child: SenpaiButton(
              label: 'Nghe',
              icon: Symbols.volume_up_rounded,
              kind: SenpaiButtonKind.secondary,
              size: SenpaiButtonSize.small,
              onPressed: onSpeak,
            ),
          ),
        ],
      ),
    );
  }
}
