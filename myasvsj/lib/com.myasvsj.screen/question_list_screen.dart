import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/faq_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/question_controller.dart';
import 'package:myasvsj/com.myasvsj.model/question_overview.dart';
import 'package:myasvsj/com.myasvsj.model/topic.dart';
import 'package:myasvsj/com.myasvsj.screen/empty_view.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/faq_tile.dart';
import 'package:myasvsj/com.myasvsj.screen/faq_view.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/question_card.dart';
import 'package:myasvsj/com.myasvsj.screen/question_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_style.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/sign_in_gate.dart';

/// Tab Hỏi-Đáp (tab thứ 4 của app, màn 15 của thiết kế), hai tab con giống trang `/qa` của web:
/// - "Câu hỏi": câu hỏi của cộng đồng, tìm, lọc trạng thái và chủ đề, sắp xếp, thống kê, FAQ liên quan khi tìm,
///   tải thêm khi cuộn, kéo xuống làm mới;
/// - "Câu hỏi thường gặp": FaqView.
///
/// Nút nổi "Đặt câu hỏi" cần tài khoản: khách được đưa sang Đăng nhập trước.
class QuestionListScreen extends StatefulWidget {
  const QuestionListScreen({super.key, this.initialTab = 0, this.initialQuery = ''});

  /// 0 = Câu hỏi, 1 = Câu hỏi thường gặp.
  final int initialTab;

  /// Mở sẵn kết quả tìm từ khóa này trong tab [initialTab] (ví dụ "Xem tất cả … câu hỏi" của Tìm kiếm, như
  /// `/qa?q=` và `/qa?tab=faq&q=` của web). Rỗng = giữ bộ lọc đang có.
  final String initialQuery;

  @override
  State<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> with SingleTickerProviderStateMixin {
  static const _searchDelay = Duration(milliseconds: 400);
  static const _statusLabels = {
    'ALL': 'Tất cả',
    'UNANSWERED': 'Chưa ai trả lời',
    'UNSOLVED': 'Chưa giải quyết',
    'SOLVED': 'Đã giải quyết',
  };
  static const _sortLabels = {'NEWEST': 'Mới nhất', 'LIKES': 'Nhiều thích', 'ANSWERS': 'Nhiều trả lời'};

  late final TabController _tabs = TabController(length: 2, vsync: this, initialIndex: widget.initialTab.clamp(0, 1));
  final _search = TextEditingController();
  Timer? _debounce;

  /// Đang mở phần thống kê chi tiết (chủ đề hay được hỏi, senpai giải đáp nhiều).
  bool _statsOpen = false;

  /// Người đang đăng nhập lần dựng trước: đổi (đăng nhập / đăng xuất) thì tải lại, vì người hỏi thấy cả câu hỏi
  /// của mình đang được quét ảnh.
  int? _userId;
  bool _userSeen = false;

  /// Từ khóa của Controller lần cuối màn hình thấy: đổi từ nơi khác (một màn Hỏi-Đáp khác) thì chép vào ô tìm.
  String _seenQuery = '';

  @override
  void initState() {
    super.initState();
    final questions = context.read<QuestionController>();
    final faq = context.read<FaqController>();
    final query = widget.initialQuery.trim();
    final searchQuestions = query.isNotEmpty && _tabs.index == 0;
    _search.text = searchQuestions ? query : questions.query;
    _seenQuery = _search.text;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (searchQuestions) {
        questions.search(query);
        faq.loadHits(query);
      } else if (!questions.hasLoaded && !questions.isLoading) {
        questions.loadQuestions();
      }
      if (query.isNotEmpty && _tabs.index == 1) {
        faq.search(query);
      }
      if (questions.overview == null) {
        questions.loadOverview();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthController>().currentUser?.id;
    if (_userSeen && userId != _userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<QuestionController>().loadQuestions();
        }
      });
    }
    _userSeen = true;
    _userId = userId;

    return Scaffold(
      appBar: SenpaiLargeAppBar(
        title: 'Hỏi-Đáp',
        bottom: TabBar(
          controller: _tabs,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          tabs: const [
            Tab(text: 'Câu hỏi', height: 44),
            Tab(text: 'Câu hỏi thường gặp', height: 44),
          ],
        ),
      ),
      // Tab "Câu hỏi thường gặp" (màn 18 của thiết kế) không có FAB: thẻ "Chưa thấy câu trả lời?" đã có nút
      // Đặt câu hỏi, FAB nổi chỉ che nội dung
      floatingActionButton: ListenableBuilder(
        listenable: _tabs,
        builder: (context, child) => _tabs.index == 1 ? const SizedBox.shrink() : child!,
        child: DecoratedBox(
          // Bóng "Shadow/Float" của thiết kế thay cho bóng xám mặc định
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: SenpaiColors.shadowFloat),
          child: FloatingActionButton.extended(
            heroTag: 'qa-ask',
            tooltip: 'Đặt câu hỏi',
            elevation: 0,
            focusElevation: 0,
            hoverElevation: 0,
            highlightElevation: 0,
            onPressed: _ask,
            icon: const Icon(Symbols.contact_support_rounded),
            label: const Text('Đặt câu hỏi'),
          ),
        ),
      ),
      body: TabBarView(controller: _tabs, children: [_questionsTab(), const FaqView(bottomPadding: 96)]),
    );
  }

  // ---------------------------------------------------------------- Tab "Câu hỏi"

  /// Lề ngang 16 của thân màn hình (hàng chip trạng thái cuộn ngang thì tràn sát mép).
  static Widget _pad(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

  Widget _questionsTab() {
    final c = context.watch<QuestionController>();
    final faq = context.watch<FaqController>();
    if (c.query != _seenQuery) {
      _seenQuery = c.query;
      if (_search.text.trim() != c.query) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _search.text = c.query;
          }
        });
      }
    }
    // Phần đầu: ô tìm, chip trạng thái, chủ đề + sắp xếp, thống kê, FAQ liên quan (cách nhau 14 như thiết kế)
    final header = <Widget>[
      _pad(_searchBox()),
      _statusChips(c),
      _pad(_filters(c)),
      if (c.overview != null && !c.isFiltered) _pad(_statsCard(c, c.overview!)),
      if (_showHits(c, faq)) _pad(_faqHits(c, faq)),
    ];
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 300) {
          c.loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => Future.wait([c.loadQuestions(), c.loadOverview(), faq.loadHits(c.query)]),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.only(top: 12, bottom: 14),
              sliver: SliverToBoxAdapter(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 14, children: header),
              ),
            ),
            ..._results(c),
            const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
          ],
        ),
      ),
    );
  }

  Widget _searchBox() {
    return TextField(
      controller: _search,
      maxLength: 100,
      textInputAction: TextInputAction.search,
      decoration: senpaiSearchDecoration(
        'Tìm câu hỏi theo nội dung hoặc địa điểm',
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Xóa từ khóa',
                icon: const Icon(Symbols.close_rounded),
                onPressed: () {
                  _search.clear();
                  _runSearch('');
                },
              ),
      ).copyWith(counterText: ''),
      onChanged: (text) {
        setState(() {});
        _debounce?.cancel();
        _debounce = Timer(_searchDelay, () => _runSearch(text));
      },
      onSubmitted: _runSearch,
    );
  }

  /// Tìm câu hỏi và các câu hỏi thường gặp giống từ khóa.
  void _runSearch(String text) {
    _debounce?.cancel();
    final c = context.read<QuestionController>();
    if (text.trim() == c.query && c.error == null) {
      return;
    }
    c.search(text);
    context.read<FaqController>().loadHits(text);
  }

  /// Chip trạng thái "Tất cả / Chưa ai trả lời / Chưa giải quyết / Đã giải quyết", cuộn ngang.
  Widget _statusChips(QuestionController c) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        spacing: 8,
        children: [
          for (final entry in _statusLabels.entries)
            ChoiceChip(
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              label: Text(entry.value),
              selected: c.status == entry.key,
              onSelected: (_) {
                if (c.status != entry.key) {
                  c.setStatus(entry.key);
                }
              },
            ),
        ],
      ),
    );
  }

  /// Hai nút dạng viên thuốc "Chủ đề (n)" và "Mới nhất" (`pill` của thiết kế); đang lọc thì thêm các chủ đề đã
  /// chọn (bỏ được từng cái) và "Xóa bộ lọc".
  Widget _filters(QuestionController c) {
    final topicCount = c.topicIds.length;
    final names = {for (final t in c.overview?.topics ?? const <Topic>[]) t.id: t.name};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(
              icon: Symbols.sell_rounded,
              label: topicCount == 0 ? 'Chủ đề' : 'Chủ đề ($topicCount)',
              onTap: () => _pickTopics(c),
            ),
            PopupMenuButton<String>(
              tooltip: 'Sắp xếp',
              initialValue: c.sort,
              borderRadius: BorderRadius.circular(99),
              onSelected: (value) {
                if (value != c.sort) {
                  c.setSort(value);
                }
              },
              itemBuilder: (_) => [
                for (final entry in _sortLabels.entries) PopupMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              child: _Pill(icon: Symbols.sort_rounded, label: _sortLabels[c.sort] ?? 'Mới nhất'),
            ),
          ],
        ),
        if (c.isFiltered)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final id in c.topicIds)
                InputChip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  color: const WidgetStatePropertyAll(SenpaiColors.brandSoft),
                  side: BorderSide.none,
                  avatar: const Icon(Symbols.sell_rounded, size: 16, color: SenpaiColors.brandText),
                  label: Text(names[id] ?? 'Chủ đề $id'),
                  labelStyle: SenpaiText.labelS.copyWith(color: SenpaiColors.brandText),
                  deleteIcon: const Icon(Symbols.close_rounded, size: 16),
                  deleteIconColor: SenpaiColors.brandText,
                  onDeleted: () => c.toggleTopic(id),
                  deleteButtonTooltipMessage: 'Bỏ chủ đề ${names[id] ?? id}',
                ),
              SenpaiButton(
                label: 'Xóa bộ lọc',
                kind: SenpaiButtonKind.ghost,
                size: SenpaiButtonSize.small,
                icon: Symbols.filter_alt_off_rounded,
                onPressed: _clearFilters,
              ),
            ],
          ),
      ],
    );
  }

  void _clearFilters() {
    _search.clear();
    context.read<QuestionController>().clearFilters();
    context.read<FaqController>().loadHits('');
  }

  /// Bảng chọn chủ đề: bấm chủ đề nào danh sách lọc ngay theo chủ đề đó.
  Future<void> _pickTopics(QuestionController c) async {
    if (c.overview == null) {
      await c.loadOverview();
    }
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => Consumer<QuestionController>(
        builder: (_, controller, _) {
          final topics = controller.overview?.topics ?? const <Topic>[];
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Text('Chọn chủ đề', style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink)),
                  if (topics.isEmpty)
                    Text(
                      controller.overviewError ?? 'Chưa có chủ đề.',
                      style: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in topics)
                          FilterChip(
                            showCheckmark: false,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            label: Text(t.name),
                            selected: controller.topicIds.contains(t.id),
                            onSelected: (_) => controller.toggleTopic(t.id),
                          ),
                      ],
                    ),
                  SenpaiButton(label: 'Xong', expand: true, onPressed: () => Navigator.pop(sheetContext)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// `Stats` của thiết kế: hộp ai-soft bo 18, ba số Display/M (câu hỏi, chưa ai trả lời, đã giải quyết). Bấm số
  /// "chưa ai trả lời" / "đã giải quyết" để lọc; bấm số câu hỏi hay mũi tên để mở thống kê chi tiết.
  Widget _statsCard(QuestionController c, QuestionOverview o) {
    Widget stat(int value, String label, Color color, VoidCallback onTap) => Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Text(formatQaCount(value), style: SenpaiText.displayM.copyWith(color: color)),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
            ),
          ],
        ),
      ),
    );
    void toggle() => setState(() => _statsOpen = !_statsOpen);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: SenpaiColors.aiSoft, borderRadius: BorderRadius.circular(18)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  stat(o.total, 'câu hỏi', SenpaiColors.ink, toggle),
                  stat(o.unanswered, 'chưa ai trả lời', SenpaiColors.lanternText, () => c.setStatus('UNANSWERED')),
                  stat(o.solved, 'đã giải quyết', SenpaiColors.ok, () => c.setStatus('SOLVED')),
                ],
              ),
              if (_statsOpen) ...[const SizedBox(height: 12), ..._statsDetails(c, o)],
            ],
          ),
          // Mũi tên mở / thu thống kê chi tiết nằm ở góc trên phải, trong phần lề của hộp (không đè lên số)
          Positioned(
            right: -12,
            top: -12,
            child: IconButton(
              tooltip: _statsOpen ? 'Thu gọn thống kê' : 'Xem thêm thống kê',
              onPressed: toggle,
              style: IconButton.styleFrom(
                minimumSize: const Size(32, 32),
                fixedSize: const Size(32, 32),
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: SenpaiColors.muted,
              ),
              icon: Icon(_statsOpen ? Symbols.expand_less_rounded : Symbols.expand_more_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  /// Thống kê chi tiết: chủ đề hay được hỏi (bấm để lọc) và senpai giải đáp nhiều trong N ngày qua.
  List<Widget> _statsDetails(QuestionController c, QuestionOverview o) {
    final caption = SenpaiText.caption.copyWith(color: SenpaiColors.muted);
    return [
      if (o.unanswered > 0)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Bạn biết câu trả lời? Giúp người hỏi trong mục “Chưa ai trả lời”.',
            style: SenpaiText.bodyS.copyWith(color: SenpaiColors.ink),
          ),
        ),
      Text('Chủ đề hay được hỏi', style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink)),
      const SizedBox(height: 6),
      if (o.popularTopics.isEmpty)
        Text('Chưa có dữ liệu.', style: caption)
      else
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final p in o.popularTopics)
              ActionChip(
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label: Text('${p.topic.name} · ${p.count}'),
                onPressed: () => c.showTopic(p.topic.id),
              ),
          ],
        ),
      const SizedBox(height: 12),
      Text('Senpai giải đáp nhiều', style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink)),
      Text('Trong ${o.topAnswerersDays} ngày qua', style: caption),
      const SizedBox(height: 4),
      if (o.topAnswerers.isEmpty)
        Text('Chưa có ai trả lời trong thời gian này.', style: caption)
      else
        for (final a in o.topAnswerers)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              spacing: 6,
              children: [
                const Icon(Symbols.workspace_premium_rounded, size: 18, color: SenpaiColors.lantern),
                Expanded(
                  child: Text(
                    a.author.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink),
                  ),
                ),
                Text('${a.answerCount} trả lời${a.bestCount > 0 ? ' · ${a.bestCount} hay nhất' : ''}', style: caption),
              ],
            ),
          ),
    ];
  }

  bool _showHits(QuestionController c, FaqController faq) =>
      faq.hits.isNotEmpty && c.query.isNotEmpty && faq.hitsQuery == c.query && c.error == null;

  /// "Câu hỏi thường gặp liên quan" phía trên kết quả tìm câu hỏi: hộp ai-soft như gợi ý của form đặt câu hỏi.
  Widget _faqHits(QuestionController c, FaqController faq) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: SenpaiColors.aiSoft, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            spacing: 8,
            children: [
              const Icon(Symbols.quiz_rounded, size: 20, color: SenpaiColors.ink),
              Expanded(
                child: Text('Câu hỏi thường gặp liên quan', style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
              ),
            ],
          ),
          Text('Có thể câu trả lời bạn cần đã có ở đây.', style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
          for (final entry in faq.hits) FaqTile(entry: entry, compact: true),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: SenpaiButtonStyle.ghost(SenpaiButtonSize.small).copyWith(
                fixedSize: const WidgetStatePropertyAll(Size.fromHeight(34)),
                padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 4)),
              ),
              onPressed: () {
                faq.search(c.query);
                _tabs.animateTo(1);
              },
              icon: const Icon(Symbols.quiz_rounded),
              label: Text('Tìm “${c.query}” trong Câu hỏi thường gặp', maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }

  /// Danh sách câu hỏi, hoặc trạng thái chờ / lỗi / rỗng.
  List<Widget> _results(QuestionController c) {
    if (c.isLoading && c.questions.isEmpty) {
      return const [
        SliverToBoxAdapter(
          child: Padding(padding: EdgeInsets.all(32), child: LoadingView()),
        ),
      ];
    }
    if (c.error != null) {
      return [
        SliverToBoxAdapter(
          child: ErrorView(message: c.error!, onRetry: c.loadQuestions),
        ),
      ];
    }
    if (c.questions.isEmpty) {
      final searching = c.query.isNotEmpty;
      return [
        SliverToBoxAdapter(
          child: Column(
            children: [
              EmptyView(
                text: !c.isFiltered
                    ? 'Chưa có câu hỏi nào.'
                    : searching
                    ? 'Không có câu hỏi nào khớp với lựa chọn của bạn. Chưa thấy lời giải? Hãy hỏi các senpai.'
                    : 'Không có câu hỏi nào khớp với lựa chọn của bạn.',
                icon: Symbols.contact_support_rounded,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (!c.isFiltered || searching)
                    SenpaiButton(
                      label: 'Đặt câu hỏi',
                      size: SenpaiButtonSize.medium,
                      icon: Symbols.contact_support_rounded,
                      onPressed: _ask,
                    ),
                  if (c.isFiltered)
                    SenpaiButton(
                      label: 'Xóa bộ lọc',
                      kind: SenpaiButtonKind.secondary,
                      size: SenpaiButtonSize.medium,
                      onPressed: _clearFilters,
                    ),
                ],
              ),
            ],
          ),
        ),
      ];
    }
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Text(
            '${formatQaCount(c.totalItems)} câu hỏi${c.isFiltered ? ' phù hợp' : ''}',
            style: SenpaiText.labelM.copyWith(color: SenpaiColors.muted),
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList.separated(
          itemCount: c.questions.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (_, i) => QuestionCard(question: c.questions[i], onTopicTap: c.showTopic),
        ),
      ),
      SliverToBoxAdapter(
        child: c.isLoadingMore
            ? const Padding(padding: EdgeInsets.all(16), child: LoadingView())
            : c.hasMore
            ? Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: SenpaiButton(
                    label: 'Tải thêm',
                    kind: SenpaiButtonKind.ghost,
                    size: SenpaiButtonSize.medium,
                    onPressed: c.loadMore,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    ];
  }

  /// "Đặt câu hỏi": khách đăng nhập trước. Form đặt xong tự mở câu hỏi vừa đăng.
  Future<void> _ask() async {
    if (!await requireSignIn(context) || !mounted) {
      return;
    }
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const QuestionFormScreen()));
  }
}

/// `pill(icon, label)` của thiết kế: nút viên thuốc trắng viền line cao 36, icon 18, chữ Label/M, mũi tên
/// arrow_drop_down muted. Không có [onTap] thì để widget cha (PopupMenuButton) nhận bấm.
class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const shape = StadiumBorder(side: BorderSide(color: SenpaiColors.line));
    final content = Container(
      height: 36,
      padding: const EdgeInsets.fromLTRB(12, 0, 10, 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(icon, size: 18, color: SenpaiColors.ink),
          Text(label, style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink)),
          const Icon(Symbols.arrow_drop_down_rounded, size: 20, color: SenpaiColors.muted),
        ],
      ),
    );
    return Material(
      color: SenpaiColors.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
  }
}
