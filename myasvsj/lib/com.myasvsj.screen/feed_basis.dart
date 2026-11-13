import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/home_format.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// "Dựa trên": những gì Senpai ơi dựa vào để gợi ý (khu vực, giai đoạn, chủ đề đã chọn, chủ đề rút ra từ những gì
/// người dùng làm), nút "Điều chỉnh" và dòng giải thích. Dùng ở trang chủ và màn "Dành cho bạn".
///
/// [boxed] false (trang chủ, thiết kế 02): một hàng xuống dòng "Dựa trên" + badge tone ai + link "Điều chỉnh".
/// [boxed] true (màn "Dành cho bạn", thiết kế 04): hộp ai-soft bo 18 p14, đầu hộp auto_awesome + "Dựa trên" + nút
/// "Điều chỉnh" viên thuốc trắng, rồi các badge tone brand. Chủ đề tự rút ra / chưa chọn dùng badge neutral.
class FeedBasis extends StatelessWidget {
  const FeedBasis({
    super.key,
    this.areaName,
    this.stage,
    this.interests = const [],
    this.chosenInterests = const [],
    required this.onAdjust,
    this.boxed = false,
  });

  final String? areaName;
  final String? stage;
  final List<String> interests;
  final List<String> chosenInterests;
  final VoidCallback onAdjust;
  final bool boxed;

  @override
  Widget build(BuildContext context) {
    final area = areaName ?? '';
    final stageCode = stage ?? '';
    final chosen = chosenInterests.toSet();
    final on = boxed ? SenpaiTone.brand : SenpaiTone.ai;
    final chips = <Widget>[
      area.isEmpty
          ? const _BasisChip(icon: Symbols.location_off_rounded, text: 'Chưa chọn khu vực', tone: SenpaiTone.neutral)
          : _BasisChip(icon: Symbols.location_on_rounded, text: areaShort(area), what: 'Khu vực', tone: on),
      stageCode.isEmpty
          ? const _BasisChip(icon: Symbols.flag_rounded, text: 'Chưa chọn giai đoạn', tone: SenpaiTone.neutral)
          : _BasisChip(icon: Symbols.flag_rounded, text: stageName(stageCode), what: 'Giai đoạn', tone: on),
      for (final topic in interests)
        chosen.contains(topic)
            ? _BasisChip(icon: Symbols.interests_rounded, text: topic, what: 'Chủ đề bạn chọn', tone: on)
            : _BasisChip(
                icon: Symbols.history_rounded,
                text: topic,
                what: 'Chủ đề bạn hay đọc',
                tone: SenpaiTone.neutral,
              ),
    ];
    final note = Text(
      interestNote(interests: interests.length, chosen: chosen.length),
      style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
    );

    if (!boxed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Dựa trên', style: SenpaiText.labelS.copyWith(color: SenpaiColors.muted)),
              ...chips,
              _AdjustLink(onTap: onAdjust),
            ],
          ),
          note,
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: SenpaiColors.aiSoft, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            spacing: 6,
            children: [
              const Icon(Symbols.auto_awesome_rounded, size: 18, color: SenpaiColors.brand),
              Expanded(child: Text('Dựa trên', style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink))),
              _AdjustLink(onTap: onAdjust, pill: true),
            ],
          ),
          Wrap(spacing: 6, runSpacing: 6, children: chips),
          note,
        ],
      ),
    );
  }
}

/// "Điều chỉnh": icon tune 16 + Label/S brand-text; [pill] thì nằm trong viên thuốc trắng p[6,12].
class _AdjustLink extends StatelessWidget {
  const _AdjustLink({required this.onTap, this.pill = false});

  final VoidCallback onTap;
  final bool pill;

  @override
  Widget build(BuildContext context) {
    final shape = pill ? const StadiumBorder() : RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    return Material(
      color: pill ? SenpaiColors.surface : Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: pill ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6) : const EdgeInsets.all(2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: pill ? 4 : 2,
            children: [
              const Icon(Symbols.tune_rounded, size: 16, color: SenpaiColors.brandText),
              Text('Điều chỉnh', style: SenpaiText.labelS.copyWith(color: SenpaiColors.brandText)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Một điều Senpai ơi dựa vào: `badge(text, tone, icon)`; trình đọc màn hình đọc "Khu vực: Arakawa-ku".
class _BasisChip extends StatelessWidget {
  const _BasisChip({required this.icon, required this.text, required this.tone, this.what = ''});

  final IconData icon;
  final String text;
  final SenpaiTone tone;

  /// Tên cho trình đọc màn hình, ví dụ "Khu vực".
  final String what;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: what.isEmpty ? text : '$what: $text',
      excludeSemantics: true,
      child: SenpaiBadge(text, tone: tone, icon: icon),
    );
  }
}
