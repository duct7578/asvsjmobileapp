import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/phrase_controller.dart';
import 'package:myasvsj/com.myasvsj.model/phrase.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_group.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/flashcard_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_choice_chips.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// "Luyện tập" (màn 27 của thiết kế, renderPractice() của web): chọn thẻ trong cả thư viện theo "Luyện theo"
/// (Tất cả / Chủ đề / Địa điểm và chủ đề, địa điểm cụ thể), "Loại" (Cả hai / Từ vựng / Mẫu câu), "Thẻ" (Tất cả /
/// Chưa thuộc / Đã thuộc / Chưa luyện, chỉ thành viên), "Xáo trộn thứ tự thẻ", ô xem trước số thẻ, rồi nút
/// "Bắt đầu (n thẻ)" ở thanh dưới. Mỗi số đếm theo các lựa chọn phía trên.
/// Thư viện được đọc lại mỗi lần mở, lựa chọn được giữ trong lúc app mở.
class PhrasePracticeScreen extends StatefulWidget {
  const PhrasePracticeScreen({super.key});

  @override
  State<PhrasePracticeScreen> createState() => _PhrasePracticeScreenState();
}

class _PhrasePracticeScreenState extends State<PhrasePracticeScreen> {
  bool _started = false;
  int? _userId;

  Future<void> _load() async {
    final phrases = context.read<PhraseController>();
    if (phrases.overview == null) {
      await phrases.loadOverview();
    }
    await phrases.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.select<AuthController, int?>((a) => a.currentUser?.id);
    if (!_started || userId != _userId) {
      _started = true;
      _userId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _load();
        }
      });
    }
    final phrases = context.watch<PhraseController>();
    final ready = _ready(phrases);
    final pool = phrases.practicePool;
    return Scaffold(
      appBar: const SenpaiAppBar(title: 'Luyện tập'),
      body: _body(phrases),
      bottomNavigationBar: ready
          ? SenpaiBottomBar(
              children: [
                Expanded(
                  child: SenpaiButton(
                    label: 'Bắt đầu (${pool.length} thẻ)',
                    icon: Symbols.play_arrow_rounded,
                    expand: true,
                    onPressed: pool.isEmpty ? null : () => _start(phrases),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  /// Đã có thư viện và trang đầu: hiện các lựa chọn.
  static bool _ready(PhraseController phrases) =>
      !phrases.isLoadingLibrary &&
      !(phrases.isLoadingOverview && phrases.overview == null) &&
      phrases.libraryError == null &&
      !(phrases.overview == null && phrases.overviewError != null) &&
      phrases.library != null;

  Widget _body(PhraseController phrases) {
    if (phrases.isLoadingLibrary || (phrases.isLoadingOverview && phrases.overview == null)) {
      return const LoadingView();
    }
    final error = phrases.libraryError ?? (phrases.overview == null ? phrases.overviewError : null);
    if (error != null || phrases.library == null) {
      return ErrorView(message: error ?? 'Không tải được thư viện.', onRetry: _load);
    }
    final groups = phrases.practiceGroups();
    final scope = phrases.practiceScope;
    final ofKind = scope.where((p) => phrases.practiceKind.isEmpty || p.kind == phrases.practiceKind).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Chọn thẻ muốn luyện. Lật thẻ rồi chọn “Chưa thuộc” hoặc “Đã thuộc”.',
          style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
        ),
        const SizedBox(height: 18),
        _field('Luyện theo', [
          SenpaiSegmented<String>(
            segments: const [
              SenpaiSegment(value: '', label: 'Tất cả'),
              SenpaiSegment(value: 'topic', label: 'Chủ đề'),
              SenpaiSegment(value: 'category', label: 'Địa điểm'),
            ],
            selected: phrases.practiceBy,
            onChanged: (value) => phrases.choosePractice(by: value),
          ),
          if (phrases.practiceBy.isNotEmpty && groups.isNotEmpty) _groupPicker(phrases, groups),
        ]),
        const SizedBox(height: 18),
        _field('Loại', [
          PhraseChoiceChips(
            options: [
              ('', 'Cả hai (${scope.length})'),
              for (final k in Phrase.kinds) (k, '${Phrase.kindName(k)} (${scope.where((p) => p.kind == k).length})'),
            ],
            selected: phrases.practiceKind,
            onSelected: (value) => phrases.choosePractice(kind: value),
          ),
        ]),
        if (phrases.isMember) ...[
          const SizedBox(height: 18),
          _field('Thẻ', [
            PhraseChoiceChips(
              options: [
                ('', 'Tất cả (${ofKind.length})'),
                for (final entry in Phrase.statusNames.entries)
                  (entry.key, '${entry.value} (${ofKind.where((p) => p.hasStatus(entry.key)).length})'),
              ],
              selected: phrases.practiceStatus,
              onSelected: (value) => phrases.choosePractice(status: value),
            ),
          ]),
        ],
        const SizedBox(height: 18),
        SenpaiCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onTap: () => phrases.choosePractice(shuffle: !phrases.practiceShuffle),
          child: Row(
            spacing: 12,
            children: [
              const IconTile(Symbols.shuffle_rounded, tone: SenpaiTone.ai, size: 36, radius: 10),
              Expanded(
                child: Text('Xáo trộn thứ tự thẻ', style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
              ),
              Switch(
                // Thẻ cao 56 như thiết kế: không thêm lề vùng chạm 48 quanh công tắc (cả thẻ đều bấm được)
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                value: phrases.practiceShuffle,
                onChanged: (value) => phrases.choosePractice(shuffle: value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _preview(phrases, groups),
      ],
    );
  }

  /// Nhãn Label/M ink phía trên một nhóm lựa chọn, cách 8.
  Widget _field(String label, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [Text(label, style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink)), ...children],
    );
  }

  /// Ô chọn chủ đề / địa điểm (`dropdownField` của thiết kế): nền trắng viền line bo 12, cao 48, mũi tên expand_more.
  Widget _groupPicker(PhraseController phrases, List<PhraseGroup> groups) {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 12, right: 8),
      decoration: BoxDecoration(
        color: SenpaiColors.surface,
        border: Border.all(color: SenpaiColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: groups.any((g) => g.id == phrases.practiceGroup) ? phrases.practiceGroup : null,
          hint: Text(
            phrases.practiceBy == 'topic' ? 'Chọn chủ đề' : 'Chọn địa điểm',
            style: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted),
          ),
          icon: const Icon(Symbols.expand_more_rounded, size: 22, color: SenpaiColors.muted),
          style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
          dropdownColor: SenpaiColors.surface,
          borderRadius: BorderRadius.circular(12),
          items: [
            for (final g in groups)
              DropdownMenuItem(
                value: g.id,
                child: Text('${g.name} (${g.count})', maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (value) => phrases.choosePractice(group: value),
        ),
      ),
    );
  }

  /// Ô xem trước nền brand-soft bo 20: biểu tượng thẻ, số thẻ kèm mức thuộc ("5 thẻ chưa thuộc"), và phạm vi đang
  /// chọn (chủ đề / địa điểm, loại).
  Widget _preview(PhraseController phrases, List<PhraseGroup> groups) {
    final count = phrases.practicePool.length;
    final status = phrases.practiceStatus.isEmpty ? '' : ' ${Phrase.statusNames[phrases.practiceStatus]!.toLowerCase()}';
    String scopeName = 'Cả thư viện';
    if (phrases.practiceBy.isNotEmpty) {
      for (final g in groups) {
        if (g.id == phrases.practiceGroup) {
          scopeName = g.name;
        }
      }
    }
    final kindName = phrases.practiceKind.isEmpty ? 'Từ vựng và mẫu câu' : Phrase.kindName(phrases.practiceKind);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: SenpaiColors.brandSoft, borderRadius: BorderRadius.circular(20)),
      child: Column(
        spacing: 6,
        children: [
          const Icon(Symbols.style_rounded, size: 40, color: SenpaiColors.brand),
          Text(
            count == 0 ? 'Không có thẻ nào khớp lựa chọn' : '$count thẻ$status',
            textAlign: TextAlign.center,
            style: SenpaiText.titleM.copyWith(color: SenpaiColors.brandText),
          ),
          Text(
            '$scopeName · $kindName',
            textAlign: TextAlign.center,
            style: SenpaiText.caption.copyWith(color: SenpaiColors.brandText),
          ),
        ],
      ),
    );
  }

  void _start(PhraseController phrases) {
    phrases.startPractice();
    Navigator.pushReplacement(context, MaterialPageRoute<void>(builder: (_) => const FlashcardScreen()));
  }
}
