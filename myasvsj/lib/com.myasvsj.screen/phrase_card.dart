import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/phrase_controller.dart';
import 'package:myasvsj/com.myasvsj.model/phrase.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_icon.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_staff_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/report_dialog.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/sign_in_gate.dart';

/// Thẻ một mẫu câu / từ vựng (kết quả tìm và các bộ), `phraseCard()` của thiết kế (màn 26): thẻ trắng bo 18, hàng
/// nhãn (loại · loại địa điểm · chủ đề · dấu "Đã thuộc" / "Chưa thuộc"), chữ Nhật JP/L, romaji Body/S brand-text,
/// nghĩa Body/M; dưới cùng các nút "Đưa cho nhân viên xem" (chỉ mẫu câu), "Nghe" và cờ "Báo lỗi" (khách được đưa
/// sang Đăng nhập). Nhãn loại địa điểm và chủ đề bấm được để mở bộ đó; thành viên có nút "Bỏ đánh dấu" cạnh dấu.
class PhraseCard extends StatelessWidget {
  const PhraseCard({super.key, required this.phrase, this.showCategory = true});

  final Phrase phrase;

  /// Ẩn loại địa điểm khi cả bộ đã là loại địa điểm đó.
  final bool showCategory;

  static final ButtonStyle _iconStyle = IconButton.styleFrom(
    foregroundColor: SenpaiColors.muted,
    minimumSize: const Size(36, 36),
    fixedSize: const Size(36, 36),
    padding: EdgeInsets.zero,
    iconSize: 20,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  @override
  Widget build(BuildContext context) {
    final member = context.select<PhraseController, bool>((c) => c.isMember);
    return SenpaiCard(
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SenpaiBadge(Phrase.kindName(phrase.kind)),
              if (showCategory && phrase.category.id.isNotEmpty)
                _TapBadge(
                  onTap: () => _openSet(context, categoryId: phrase.category.id),
                  child: SenpaiBadge(
                    phrase.category.name,
                    tone: SenpaiTone.ai,
                    icon: PhraseIcon.of(phrase.category.icon),
                  ),
                ),
              for (final topic in phrase.topics)
                _TapBadge(
                  onTap: () => _openSet(context, topicId: topic.id),
                  child: SenpaiOutlineBadge(topic.name),
                ),
              if (phrase.learned)
                const SenpaiBadge('Đã thuộc', tone: SenpaiTone.ok, icon: Symbols.check_circle_rounded)
              else if (phrase.learning)
                const SenpaiBadge('Chưa thuộc', tone: SenpaiTone.lantern, icon: Symbols.replay_rounded),
              if (member && !phrase.isNew)
                SizedBox(
                  height: 22,
                  child: IconButton(
                    tooltip: 'Bỏ đánh dấu',
                    style: _iconStyle.copyWith(
                      minimumSize: const WidgetStatePropertyAll(Size(28, 22)),
                      fixedSize: const WidgetStatePropertyAll(Size(28, 22)),
                      iconSize: const WidgetStatePropertyAll(18),
                    ),
                    onPressed: () => _clearMark(context),
                    icon: const Icon(Symbols.undo_rounded),
                  ),
                ),
            ],
          ),
          Text(phrase.japanese, locale: const Locale('ja'), style: SenpaiText.jpL.copyWith(color: SenpaiColors.ink)),
          if (phrase.romaji.isNotEmpty)
            Text(phrase.romaji, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.brandText)),
          Text(phrase.meaningVi, style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Expanded(
                // Màn hẹp: nút "Nghe" xuống dòng thay vì tràn
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (phrase.isPhrase)
                      SenpaiButton(
                        label: 'Đưa cho nhân viên xem',
                        kind: SenpaiButtonKind.soft,
                        size: SenpaiButtonSize.small,
                        icon: Symbols.front_hand_rounded,
                        onPressed: () => _showStaff(context),
                      ),
                    Tooltip(
                      message: 'Nghe',
                      excludeFromSemantics: true,
                      child: SenpaiButton(
                        label: 'Nghe',
                        kind: SenpaiButtonKind.secondary,
                        size: SenpaiButtonSize.small,
                        icon: Symbols.volume_up_rounded,
                        onPressed: () => _speak(context),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Báo lỗi',
                style: _iconStyle,
                onPressed: () => _report(context),
                icon: const Icon(Symbols.flag_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openSet(BuildContext context, {String? topicId, String? categoryId}) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PhraseListScreen(topicId: topicId, categoryId: categoryId),
      ),
    );
  }

  void _showStaff(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => PhraseStaffScreen(phrase: phrase)),
    );
  }

  Future<void> _speak(BuildContext context) async {
    final phrases = context.read<PhraseController>();
    final spoken = await phrases.speak(phrase.japanese);
    if (!spoken && context.mounted) {
      showMessage(context, phrases.takeMessage());
    }
  }

  Future<void> _clearMark(BuildContext context) async {
    final phrases = context.read<PhraseController>();
    await phrases.clearMark(phrase);
    if (context.mounted) {
      showMessage(context, phrases.takeMessage());
    }
  }

  /// "Báo lỗi": khách đăng nhập trước; lý do lấy từ trang đầu (Sai tiếng Nhật, Sai nghĩa, Xúc phạm, Spam).
  Future<void> _report(BuildContext context) async {
    if (!await requireSignIn(context) || !context.mounted) {
      return;
    }
    final phrases = context.read<PhraseController>();
    if (phrases.reportReasons.isEmpty) {
      await phrases.loadOverview();
      if (!context.mounted) {
        return;
      }
    }
    final choice = await showReportDialog(context, reasons: phrases.reportReasons, title: 'Báo lỗi mẫu câu');
    if (choice == null || !context.mounted) {
      return;
    }
    await phrases.report(phrase.id, choice.reasonId, choice.note);
    if (context.mounted) {
      showMessage(context, phrases.takeMessage());
    }
  }
}

/// Nhãn bấm được (loại địa điểm, chủ đề): gợn sóng trong viên thuốc.
class _TapBadge extends StatelessWidget {
  const _TapBadge({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}
