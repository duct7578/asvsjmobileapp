import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/faq_controller.dart';
import 'package:myasvsj/com.myasvsj.screen/empty_view.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/faq_tile.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/question_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_style.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/sign_in_gate.dart';

/// Nội dung "Câu hỏi thường gặp" (thân màn 18), dùng chung cho tab thứ hai của Hỏi-Đáp và màn FaqScreen: lời giới
/// thiệu, ô tìm, chủ đề kèm số câu, danh sách mở rộng tại chỗ, thẻ "Chưa thấy câu trả lời?", tải thêm, kéo xuống làm
/// mới.
///
/// Có [faqId]: mở sẵn đúng câu đó (như `/qa?tab=faq&id=` của web), kèm nút "Xem tất cả câu hỏi thường gặp".
class FaqView extends StatefulWidget {
  const FaqView({super.key, this.faqId, this.bottomPadding = 24});

  final int? faqId;

  /// Lề dưới của danh sách (tab Hỏi-Đáp chừa chỗ cho nút "Đặt câu hỏi" nổi).
  final double bottomPadding;

  @override
  State<FaqView> createState() => _FaqViewState();
}

class _FaqViewState extends State<FaqView> {
  static const _searchDelay = Duration(milliseconds: 400);

  final _search = TextEditingController();
  Timer? _debounce;

  /// Đang hiện riêng câu [FaqView.faqId] thay vì cả danh sách.
  late bool _single = widget.faqId != null;

  /// Từ khóa của Controller lần cuối màn hình thấy: đổi từ nơi khác (nút "Tìm trong Câu hỏi thường gặp" của tab
  /// câu hỏi) thì chép vào ô tìm.
  String _seenQuery = '';

  @override
  void initState() {
    super.initState();
    final faq = context.read<FaqController>();
    _search.text = faq.query;
    _seenQuery = faq.query;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!faq.hasLoaded && !faq.isLoading) {
        faq.loadFaqs();
      }
      if (widget.faqId != null) {
        faq.loadEntry(widget.faqId!);
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faq = context.watch<FaqController>();
    if (faq.query != _seenQuery) {
      _seenQuery = faq.query;
      if (_search.text.trim() != faq.query) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _search.text = faq.query;
          }
        });
      }
    }
    final items = <Widget>[
      _pad(
        Text(
          'Những thắc mắc phổ biến được Moderator tổng hợp và kiểm tra, nhiều câu lấy từ câu trả lời hay nhất '
          'của cộng đồng.',
          style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
        ),
      ),
      _pad(_searchBox(faq)),
      if (faq.topics.isNotEmpty) _topicChips(faq),
      if (_single) ..._singleEntry(faq) else ..._list(faq),
    ];
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        // Cuộn dọc gần tới cuối: tải trang sau (bỏ qua hàng chủ đề cuộn ngang)
        if (!_single && n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 300) {
          faq.loadMore();
        }
        return false;
      },
      child: RefreshIndicator(
        onRefresh: () => Future.wait([faq.loadFaqs(), if (_single) faq.loadEntry(widget.faqId!)]),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(top: 8, bottom: widget.bottomPadding),
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              items[i],
            ],
          ],
        ),
      ),
    );
  }

  /// Lề ngang 16 của thân màn hình (hàng chủ đề cuộn ngang thì tràn sát mép).
  static Widget _pad(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

  Widget _searchBox(FaqController faq) {
    return TextField(
      controller: _search,
      maxLength: 200,
      textInputAction: TextInputAction.search,
      decoration: senpaiSearchDecoration(
        'Tìm câu hỏi thường gặp, ví dụ: mua SIM, đổ rác',
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Xóa từ khóa',
                icon: const Icon(Symbols.close_rounded),
                onPressed: () {
                  _search.clear();
                  _runSearch(faq, '');
                },
              ),
      ).copyWith(counterText: ''),
      onChanged: (text) {
        setState(() {});
        _debounce?.cancel();
        _debounce = Timer(_searchDelay, () => _runSearch(faq, text));
      },
      onSubmitted: (text) => _runSearch(faq, text),
    );
  }

  void _runSearch(FaqController faq, String text) {
    _debounce?.cancel();
    if (_single) {
      setState(() => _single = false);
    }
    if (text.trim() != faq.query || faq.error != null) {
      faq.search(text);
    }
  }

  Widget _topicChips(FaqController faq) {
    // "Tất cả" và các chủ đề đang có câu (khớp từ khóa), như web
    final chips = [
      (code: '', title: 'Tất cả', count: faq.allCount),
      for (final t in faq.topics)
        if (t.count > 0 || t.code == faq.topicCode) (code: t.code, title: t.title, count: t.count),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        spacing: 8,
        children: [
          for (final t in chips)
            ChoiceChip(
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              label: Text('${t.title} (${t.count})'),
              selected: !_single && faq.topicCode == t.code,
              onSelected: (_) {
                setState(() => _single = false);
                faq.selectTopic(t.code);
              },
            ),
        ],
      ),
    );
  }

  /// Một câu mở riêng.
  List<Widget> _singleEntry(FaqController faq) {
    final id = widget.faqId!;
    final entry = faq.entryOf(id);
    final showAll = _pad(
      SenpaiButton(
        label: 'Xem tất cả câu hỏi thường gặp',
        kind: SenpaiButtonKind.secondary,
        size: SenpaiButtonSize.medium,
        icon: Symbols.arrow_back_rounded,
        expand: true,
        onPressed: () {
          setState(() => _single = false);
          if (faq.isFiltered) {
            _search.clear();
            faq.clearFilters();
          }
        },
      ),
    );
    if (entry == null && faq.isLoadingEntry(id)) {
      return const [Padding(padding: EdgeInsets.all(32), child: LoadingView())];
    }
    if (entry == null) {
      return [
        EmptyView(
          text: faq.entryError(id) ?? 'Câu hỏi thường gặp này không còn hoặc đã được ẩn.',
          icon: Symbols.search_off_rounded,
        ),
        showAll,
      ];
    }
    return [
      _pad(Text('Chủ đề: ${entry.topicName}', style: SenpaiText.labelM.copyWith(color: SenpaiColors.muted))),
      _pad(FaqTile(entry: entry, initiallyExpanded: true, showOpenLink: false)),
      showAll,
    ];
  }

  /// Danh sách theo bộ lọc.
  List<Widget> _list(FaqController faq) {
    final q = faq.query.trim();
    if (faq.isLoading && faq.entries.isEmpty && faq.related.isEmpty) {
      return const [Padding(padding: EdgeInsets.all(32), child: LoadingView())];
    }
    if (faq.error != null) {
      return [ErrorView(message: faq.error!, onRetry: faq.loadFaqs)];
    }
    if (faq.entries.isEmpty) {
      if (faq.related.isNotEmpty) {
        return [
          _pad(
            Text(
              'Không có câu nào chứa đúng “$q”${faq.topicCode.isNotEmpty ? ' trong chủ đề này' : ''}. '
              'Những câu có thể liên quan:',
              style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
            ),
          ),
          for (final entry in faq.related) _pad(FaqTile(entry: entry)),
          _pad(_askCard()),
        ];
      }
      return [
        EmptyView(
          text: faq.isFiltered
              ? 'Không có câu hỏi thường gặp nào khớp với lựa chọn của bạn. Chưa thấy lời giải? Hãy hỏi các senpai.'
              : 'Chưa có câu hỏi thường gặp nào.',
          icon: Symbols.quiz_rounded,
        ),
        _pad(
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              SenpaiButton(
                label: 'Đặt câu hỏi',
                size: SenpaiButtonSize.medium,
                icon: Symbols.contact_support_rounded,
                onPressed: _ask,
              ),
              if (faq.isFiltered)
                SenpaiButton(
                  label: 'Xóa bộ lọc',
                  kind: SenpaiButtonKind.secondary,
                  size: SenpaiButtonSize.medium,
                  onPressed: () {
                    _search.clear();
                    faq.clearFilters();
                  },
                ),
            ],
          ),
        ),
      ];
    }
    return [
      _pad(
        Text(
          '${formatQaCount(faq.totalItems)} câu hỏi thường gặp${faq.isFiltered ? ' phù hợp' : ''}',
          style: SenpaiText.labelM.copyWith(color: SenpaiColors.muted),
        ),
      ),
      for (final entry in faq.entries) _pad(FaqTile(entry: entry)),
      if (faq.isLoadingMore)
        const Padding(padding: EdgeInsets.all(16), child: LoadingView())
      else if (faq.hasMore)
        Center(
          child: SenpaiButton(
            label: faq.moreError ?? 'Tải thêm',
            kind: SenpaiButtonKind.ghost,
            size: SenpaiButtonSize.medium,
            onPressed: faq.loadMore,
          ),
        ),
      _pad(_askCard()),
    ];
  }

  /// `AskCard` của thiết kế ("Chưa thấy câu trả lời?" như cột bên của web): nền brand-soft bo 18 lề 16.
  Widget _askCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: SenpaiColors.brandSoft, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text('Chưa thấy câu trả lời?', style: SenpaiText.titleM.copyWith(color: SenpaiColors.brandText)),
          Text(
            'Hỏi cộng đồng, các senpai đã trải qua sẽ trả lời bạn.',
            style: SenpaiText.bodyS.copyWith(color: SenpaiColors.brandText),
          ),
          SenpaiButton(
            label: 'Đặt câu hỏi',
            size: SenpaiButtonSize.medium,
            icon: Symbols.contact_support_rounded,
            onPressed: _ask,
          ),
        ],
      ),
    );
  }

  Future<void> _ask() async {
    if (!await requireSignIn(context) || !mounted) {
      return;
    }
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const QuestionFormScreen()));
  }
}
