import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/phrase_controller.dart';
import 'package:myasvsj/com.myasvsj.model/phrase.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_group.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_overview.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_part.dart';
import 'package:myasvsj/com.myasvsj.screen/empty_view.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_card.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_icon.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_practice_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/sign_in_gate.dart';

/// Trang đầu Nhật ngữ (màn 25 của thiết kế, renderStart() của web): câu giới thiệu, ô tìm (tiếng Nhật, romaji,
/// nghĩa, chủ đề), nút "Luyện tập" (thành viên thêm "Chưa thuộc" / "Đã thuộc"), thẻ tổng kết màu ink ("Đã thuộc
/// x / y mục"; khách thấy số mục và lời mời đăng nhập), thanh chọn "Chủ đề" / "Địa điểm", rồi "Từ vựng" và "Mẫu câu",
/// mỗi phần một lưới thẻ nhóm 2 cột có tiến độ "đã thuộc" (thành viên). Khi đang tìm, kết quả thay chỗ phần duyệt.
///
/// [topicId] / [categoryId] (ví dụ "Học thêm chủ đề này" ở Trang chủ) mở thẳng bộ đó lên trên trang đầu;
/// [initialQuery] (từ Tìm kiếm) tìm ngay khi mở.
class PhraseScreen extends StatefulWidget {
  const PhraseScreen({super.key, this.topicId, this.categoryId, this.initialQuery = ''});

  final String? topicId;
  final String? categoryId;
  final String initialQuery;

  @override
  State<PhraseScreen> createState() => _PhraseScreenState();
}

class _PhraseScreenState extends State<PhraseScreen> {
  static const Duration _searchDelay = Duration(milliseconds: 250);

  /// Khoảng cách giữa các khối của thân trang (body gap 14 của thiết kế).
  static const double _gap = 14;

  late final TextEditingController _search = TextEditingController(text: widget.initialQuery);
  Timer? _debounce;

  /// "topic" = Chủ đề, "category" = Địa điểm.
  String _by = 'topic';
  bool _started = false;
  int? _userId;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Lần mở đầu: tìm theo [PhraseScreen.initialQuery] (chữ trống xóa kết quả của lần mở trước), tải trang đầu,
  /// rồi mở bộ được yêu cầu.
  void _open() {
    final phrases = context.read<PhraseController>();
    phrases.search(widget.initialQuery);
    phrases.loadOverview();
    if (widget.topicId != null || widget.categoryId != null) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PhraseListScreen(topicId: widget.topicId, categoryId: widget.categoryId),
        ),
      );
    }
  }

  /// Kéo xuống làm mới, hoặc người dùng vừa đăng nhập / đăng xuất: số "đã thuộc" là của từng người.
  Future<void> _reload() async {
    final phrases = context.read<PhraseController>();
    await Future.wait([phrases.loadOverview(), if (phrases.query.isNotEmpty) phrases.search(phrases.query)]);
  }

  void _onChanged(String text) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(_searchDelay, () => context.read<PhraseController>().search(text));
  }

  void _onSubmitted(String text) {
    _debounce?.cancel();
    context.read<PhraseController>().search(text);
  }

  void _clearSearch() {
    _search.clear();
    _onSubmitted('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.select<AuthController, int?>((a) => a.currentUser?.id);
    if (!_started || userId != _userId) {
      final first = !_started;
      _started = true;
      _userId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          first ? _open() : _reload();
        }
      });
    }
    final phrases = context.watch<PhraseController>();
    return Scaffold(
      appBar: const SenpaiAppBar(title: 'Nhật ngữ'),
      body: _body(phrases, userId != null),
    );
  }

  Widget _body(PhraseController phrases, bool signedIn) {
    final overview = phrases.overview;
    if (overview == null) {
      final error = phrases.overviewError;
      return error != null ? ErrorView(message: error, onRetry: phrases.loadOverview) : const LoadingView();
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            'Học trước những câu và từ bạn sẽ cần khi sống ở Nhật, theo loại địa điểm và chủ đề.',
            style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
          ),
          const SizedBox(height: _gap),
          TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            onChanged: _onChanged,
            onSubmitted: _onSubmitted,
            style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
            decoration: senpaiSearchDecoration(
              'Tìm câu tiếng Nhật, nghĩa, chủ đề',
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(tooltip: 'Xóa', icon: const Icon(Symbols.close_rounded), onPressed: _clearSearch),
            ),
          ),
          const SizedBox(height: _gap),
          if (phrases.query.isNotEmpty)
            ..._results(phrases, overview)
          else
            ..._browse(phrases.isMember, signedIn, overview),
        ],
      ),
    );
  }

  /// Kết quả tìm, chia "Từ vựng (n)" và "Mẫu câu (m)".
  List<Widget> _results(PhraseController phrases, PhraseOverview overview) {
    if (phrases.isSearching && phrases.results.isEmpty) {
      return const [LinearProgressIndicator(minHeight: 4)];
    }
    if (phrases.searchError != null) {
      return [SenpaiNote(phrases.searchError!, icon: Symbols.error_rounded, tone: SenpaiTone.crit)];
    }
    final found = phrases.results;
    return [
      Text('${found.length} kết quả', style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
      if (found.isEmpty)
        const EmptyView(text: 'Không tìm thấy mẫu câu hay từ vựng nào.', icon: Symbols.search_off_rounded),
      for (final kind in Phrase.kinds)
        if (found.any((p) => p.kind == kind)) ...[
          const SizedBox(height: _gap),
          _heading('${Phrase.kindName(kind)} (${found.where((p) => p.kind == kind).length})'),
          for (final p in found.where((p) => p.kind == kind)) ...[const SizedBox(height: 12), PhraseCard(phrase: p)],
        ],
    ];
  }

  /// Phần duyệt: các nút luyện, thẻ tổng kết (khách: lời mời đăng nhập), "Chủ đề" / "Địa điểm", rồi Từ vựng và
  /// Mẫu câu.
  List<Widget> _browse(bool member, bool signedIn, PhraseOverview overview) {
    return [
      SenpaiButton(
        label: 'Luyện tập',
        icon: Symbols.style_rounded,
        size: SenpaiButtonSize.medium,
        expand: true,
        onPressed: () => _push(const PhrasePracticeScreen()),
      ),
      if (member) ...[
        const SizedBox(height: 8),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: SenpaiButton(
                label: 'Chưa thuộc',
                kind: SenpaiButtonKind.secondary,
                size: SenpaiButtonSize.medium,
                icon: Symbols.replay_rounded,
                expand: true,
                onPressed: () => _push(const PhraseListScreen(mine: 'learning')),
              ),
            ),
            Expanded(
              child: SenpaiButton(
                label: 'Đã thuộc',
                kind: SenpaiButtonKind.secondary,
                size: SenpaiButtonSize.medium,
                icon: Symbols.task_alt_rounded,
                expand: true,
                onPressed: () => _push(const PhraseListScreen(mine: 'learned')),
              ),
            ),
          ],
        ),
      ],
      const SizedBox(height: _gap),
      _Summary(overview: overview, member: member, signedIn: signedIn),
      const SizedBox(height: _gap),
      SenpaiSegmented<String>(
        segments: [
          SenpaiSegment(
            value: 'topic',
            icon: Symbols.category_rounded,
            label: 'Chủ đề (${overview.groupsOf('topic').length})',
          ),
          SenpaiSegment(
            value: 'category',
            icon: Symbols.location_on_rounded,
            label: 'Địa điểm (${overview.groupsOf('category').length})',
          ),
        ],
        selected: _by,
        onChanged: (value) => setState(() => _by = value),
      ),
      for (final part in overview.shownParts) ..._section(part, member),
    ];
  }

  /// "Từ vựng" hoặc "Mẫu câu" trong cách xem đang chọn: lưới 2 cột các chủ đề hoặc loại địa điểm của nó.
  List<Widget> _section(PhrasePart part, bool member) {
    final groups = part.groupsOf(_by);
    final learned = member ? ' · ${part.learned}/${part.count} đã thuộc' : '';
    return [
      const SizedBox(height: _gap),
      _heading(part.name, trailing: '${part.count} mục$learned'),
      const SizedBox(height: _gap),
      if (groups.isEmpty)
        Text(
          'Chưa có ${part.name.toLowerCase()} nào.',
          style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
        )
      else
        _GroupGrid(
          groups: groups,
          member: member,
          onTap: (g) => _push(
            PhraseListScreen(
              topicId: _by == 'topic' ? g.id : null,
              categoryId: _by == 'category' ? g.id : null,
              kind: part.kind,
            ),
          ),
        ),
    ];
  }

  /// Tiêu đề phần: tên Title/M, bên phải số mục Caption muted.
  Widget _heading(String title, {String? trailing}) {
    return Row(
      spacing: 8,
      children: [
        Text(title, style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink)),
        if (trailing != null)
          Expanded(
            child: Text(
              trailing,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
            ),
          ),
      ],
    );
  }

  void _push(Widget screen) => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
}

/// Thẻ tổng kết nền ink bo 20: thành viên thấy "ĐÃ THUỘC x / y mục" và thanh tiến độ lantern; khách thấy số mục
/// của thư viện và lời mời đăng nhập để lưu kết quả lật thẻ. Chữ "あ" lớn ở bên phải.
class _Summary extends StatelessWidget {
  const _Summary({required this.overview, required this.member, required this.signedIn});

  final PhraseOverview overview;
  final bool member;
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final total = overview.parts.fold(0, (sum, p) => sum + p.count);
    final learned = overview.parts.fold(0, (sum, p) => sum + p.learned);
    final onInk = SenpaiText.bodyS.copyWith(color: SenpaiColors.onBrand);
    return Container(
      padding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: SenpaiColors.ink, borderRadius: BorderRadius.circular(20)),
      child: Row(
        spacing: 14,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                OverlineLabel(member ? 'Đã thuộc' : 'Thư viện', color: SenpaiColors.lantern),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  spacing: 4,
                  children: [
                    Text(member ? '$learned' : '$total',
                        style: SenpaiText.displayXL.copyWith(color: SenpaiColors.onBrand)),
                    Flexible(child: Text(member ? '/ $total mục' : 'mục', style: onInk)),
                  ],
                ),
                if (member)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: PhraseProgress(
                      learned: learned,
                      total: total,
                      color: SenpaiColors.lantern,
                      trackColor: SenpaiColors.inkDeep,
                    ),
                  )
                else if (!signedIn) ...[
                  Text('Đăng nhập để lưu kết quả lật thẻ (Chưa thuộc / Đã thuộc).', style: onInk),
                  TextButton.icon(
                    style: SenpaiButtonStyle.ghost(SenpaiButtonSize.small).copyWith(
                      foregroundColor: const WidgetStatePropertyAll(SenpaiColors.lantern),
                      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
                    ),
                    onPressed: () => requireSignIn(context),
                    icon: const Icon(Symbols.login_rounded),
                    label: const Text('Đăng nhập'),
                  ),
                ],
              ],
            ),
          ),
          Text(
            'あ',
            locale: const Locale('ja'),
            style: SenpaiText.jpL.copyWith(color: SenpaiColors.onBrand, fontSize: 64, height: 1),
          ),
        ],
      ),
    );
  }
}

/// Lưới 2 cột thẻ nhóm (`GroupCard` của thiết kế): ô biểu tượng 40, chevron, tên Title/S, thanh tiến độ và
/// "đã thuộc / tổng" (thành viên) hoặc "n mục" (khách). Hai thẻ cùng hàng cao bằng nhau.
class _GroupGrid extends StatelessWidget {
  const _GroupGrid({required this.groups, required this.member, required this.onTap});

  final List<PhraseGroup> groups;
  final bool member;
  final ValueChanged<PhraseGroup> onTap;

  @override
  Widget build(BuildContext context) {
    Widget tile(int i) {
      final g = groups[i];
      return SenpaiCard(
        radius: 18,
        onTap: () => onTap(g),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Row(
              children: [
                PhraseIconTile(g.icon, tone: PhraseIcon.toneAt(i)),
                const Spacer(),
                const Icon(Symbols.chevron_right_rounded, size: 20, color: SenpaiColors.muted),
              ],
            ),
            Expanded(
              child: Text(g.name,
                  maxLines: 2, overflow: TextOverflow.ellipsis, style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
            ),
            if (member) PhraseProgress(learned: g.learned, total: g.count),
            Text(
              member ? '${g.learned}/${g.count}' : '${g.count} mục',
              style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
            ),
          ],
        ),
      );
    }

    return Column(
      spacing: 12,
      children: [
        for (var i = 0; i < groups.length; i += 2)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Expanded(child: tile(i)),
                Expanded(child: i + 1 < groups.length ? tile(i + 1) : const SizedBox.shrink()),
              ],
            ),
          ),
      ],
    );
  }
}
