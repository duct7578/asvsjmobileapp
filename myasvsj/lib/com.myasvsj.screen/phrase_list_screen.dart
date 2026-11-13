import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/phrase_controller.dart';
import 'package:myasvsj/com.myasvsj.model/phrase.dart';
import 'package:myasvsj/com.myasvsj.screen/empty_view.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/flashcard_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_card.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_choice_chips.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_icon.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Một bộ Nhật ngữ (màn 26 "Danh sách mẫu câu"): một chủ đề [topicId], một loại địa điểm [categoryId], hoặc danh
/// sách riêng [mine] của thành viên ("learning" = Chưa thuộc, "learned" = Đã thuộc).
///
/// Từ trên xuống, như loadSet() / renderSetList() của web: ô biểu tượng 48 và tiến độ "đã thuộc" (thành viên),
/// "Từ vựng (n) / Mẫu câu (m)" khi bộ có cả hai, bộ lọc "Tất cả / Chưa thuộc / Đã thuộc / Chưa luyện" (thành viên),
/// nút "Luyện thẻ ghi nhớ", rồi các thẻ. Chủ đề / địa điểm hiện một loại một lúc; danh sách riêng có thêm "Tất cả".
class PhraseListScreen extends StatefulWidget {
  const PhraseListScreen({super.key, this.topicId, this.categoryId, this.mine, this.kind = ''});

  final String? topicId;
  final String? categoryId;
  final String? mine;

  /// Loại mở ra đầu tiên ("" = loại bộ có, Mẫu câu trước; ở danh sách riêng là cả hai).
  final String kind;

  @override
  State<PhraseListScreen> createState() => _PhraseListScreenState();
}

class _PhraseListScreenState extends State<PhraseListScreen> {
  late String _kind = widget.kind;
  String _status = '';
  bool _started = false;
  int? _userId;

  String get _key => PhraseController.setKey(topic: widget.topicId, category: widget.categoryId, mine: widget.mine);

  Future<void> _load() async {
    final phrases = context.read<PhraseController>();
    await Future.wait([
      phrases.loadSet(topic: widget.topicId, category: widget.categoryId, mine: widget.mine),
      phrases.loadOverview(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Tải khi mở và tải lại khi người dùng đăng nhập / đăng xuất (dấu thuộc là của từng người)
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
    final group = widget.mine == null
        ? phrases.overview?.findGroup(topicId: widget.topicId, categoryId: widget.categoryId)
        : null;
    final title = widget.mine != null
        ? PhraseController.mineNames[widget.mine] ?? 'Nhật ngữ'
        : group?.name ?? (widget.categoryId != null ? 'Địa điểm' : 'Chủ đề');
    final all = phrases.phrasesOf(_key);
    final kindLabel = widget.mine != null
        ? 'Danh sách của bạn'
        : widget.categoryId != null
            ? 'Địa điểm'
            : 'Chủ đề';
    return Scaffold(
      appBar: SenpaiAppBar(title: title, subtitle: all == null ? null : '$kindLabel · ${all.length} mục'),
      body: _body(phrases, all, group?.icon),
    );
  }

  Widget _body(PhraseController phrases, List<Phrase>? all, String? icon) {
    final error = phrases.setErrorOf(_key);
    if (all == null) {
      return error != null ? ErrorView(message: error, onRetry: _load) : const LoadingView();
    }
    final mine = widget.mine;
    final member = phrases.isMember;
    final kind = mine != null || _kind.isNotEmpty ? _kind : PhraseController.defaultKind(all);
    final status = member && mine == null ? _status : '';
    final layers = PhraseController.filter(all, mine: mine, kind: kind, status: status);
    final kinds = _kinds(layers.inList, kind);
    final learningOnly = mine == 'learning' || status == 'learning';
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          if (error != null) ...[
            SenpaiNote(error, icon: Symbols.error_rounded, tone: SenpaiTone.crit),
            const SizedBox(height: 14),
          ],
          _head(layers.ofKind, member, icon),
          if (kinds != null) ...[const SizedBox(height: 14), kinds],
          if (member && mine == null && layers.ofKind.isNotEmpty) ...[
            const SizedBox(height: 14),
            PhraseChoiceChips(
              options: [
                ('', 'Tất cả (${layers.ofKind.length})'),
                for (final entry in Phrase.statusNames.entries)
                  (entry.key, '${entry.value} (${layers.ofKind.where((p) => p.hasStatus(entry.key)).length})'),
              ],
              selected: status,
              onSelected: (value) => setState(() => _status = value),
            ),
          ],
          if (layers.list.isNotEmpty) ...[
            const SizedBox(height: 14),
            SenpaiButton(
              label: '${learningOnly ? 'Luyện lại thẻ chưa thuộc' : 'Luyện thẻ ghi nhớ'} (${layers.list.length} thẻ)',
              icon: Symbols.style_rounded,
              expand: true,
              onPressed: () => _startFlash(layers.list),
            ),
          ],
          const SizedBox(height: 14),
          if (layers.list.isEmpty)
            EmptyView(text: _emptyText(layers.inList, layers.ofKind, kind, status), icon: Symbols.style_rounded)
          else
            for (final (i, p) in layers.list.indexed) ...[
              if (i > 0) const SizedBox(height: 14),
              PhraseCard(phrase: p, showCategory: widget.categoryId == null),
            ],
        ],
      ),
    );
  }

  /// Ô biểu tượng 48 bo 16 và tiến độ: "n mục" ở danh sách riêng / khách, "x/y đã thuộc" kèm thanh tiến độ của loại
  /// đang xem (thành viên).
  Widget _head(List<Phrase> ofKind, bool member, String? icon) {
    final learned = ofKind.where((p) => p.learned).length;
    final progress = member && widget.mine == null;
    final text = progress ? '$learned/${ofKind.length} đã thuộc' : '${ofKind.length} mục';
    final Widget tile = switch (widget.mine) {
      null => PhraseIconTile(icon ?? 'label', size: 48, radius: 16),
      'learned' => const IconTile(Symbols.task_alt_rounded, tone: SenpaiTone.ok, size: 48, radius: 16),
      _ => const IconTile(Symbols.replay_rounded, tone: SenpaiTone.lantern, size: 48, radius: 16),
    };
    return Row(
      spacing: 12,
      children: [
        tile,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Text(text, style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
              if (progress) PhraseProgress(learned: learned, total: ofKind.length),
            ],
          ),
        ),
      ],
    );
  }

  /// "Từ vựng (n) / Mẫu câu (m)" khi bộ có cả hai loại; danh sách riêng có thêm "Tất cả (n)". null khi bộ chỉ có
  /// một loại.
  Widget? _kinds(List<Phrase> inList, String kind) {
    final counts = [for (final k in Phrase.kinds) (k, inList.where((p) => p.kind == k).length)];
    if (counts.any((c) => c.$2 == 0)) {
      return null;
    }
    return PhraseChoiceChips(
      options: [
        if (widget.mine != null) ('', 'Tất cả (${inList.length})'),
        for (final (k, n) in counts) (k, '${Phrase.kindName(k)} ($n)'),
      ],
      selected: kind,
      onSelected: (value) => setState(() => _kind = value),
    );
  }

  /// Câu khi không còn thẻ nào qua bộ lọc (giống renderSetList của web).
  String _emptyText(List<Phrase> inList, List<Phrase> ofKind, String kind, String status) {
    final unit = kind.isEmpty ? 'mục' : Phrase.kindName(kind).toLowerCase();
    if (status.isNotEmpty && ofKind.isNotEmpty) {
      return 'Không có $unit nào ${Phrase.statusNames[status]!.toLowerCase()} ở đây.';
    }
    if (widget.mine != null) {
      if (kind.isNotEmpty && inList.isNotEmpty) {
        return 'Không có $unit nào ở đây.';
      }
      return widget.mine == 'learning'
          ? 'Không còn thẻ nào chưa thuộc. Lật thẻ ở một chủ đề và chọn "Chưa thuộc" để lưu lại đây.'
          : 'Chưa có thẻ nào đã thuộc. Lật thẻ và chọn "Đã thuộc" khi bạn nhớ câu đó.';
    }
    return '${widget.categoryId != null ? 'Địa điểm' : 'Chủ đề'} này chưa có $unit nào.';
  }

  void _startFlash(List<Phrase> cards) {
    context.read<PhraseController>().startFlash(cards);
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => FlashcardScreen(fromLearningList: widget.mine == 'learning')),
    );
  }
}
