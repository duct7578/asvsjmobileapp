import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/guide_controller.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/empty_view.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_card.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Danh sách "Cẩm nang" (màn 22 của thiết kế, `GET /api/guides/browse`): câu giới thiệu, ô tìm dạng viên thuốc có
/// nút →, hai hàng chip cuộn ngang "GIAI ĐOẠN" (mã và tên lấy từ server) và "CHỦ ĐỀ", số kết quả + nút sắp xếp,
/// rồi các [GuideCard]; cuộn tới cuối để tải thêm.
class GuideListScreen extends StatefulWidget {
  const GuideListScreen({super.key, this.stage});

  /// Mở sẵn giai đoạn này (mã giai đoạn của web, ví dụ "ARR"); null = mọi giai đoạn.
  final String? stage;

  @override
  State<GuideListScreen> createState() => _GuideListScreenState();
}

class _GuideListScreenState extends State<GuideListScreen> {
  static const Map<String, String> _sortLabels = {'NEWEST': 'Mới nhất', 'OLDEST': 'Cũ nhất', 'TITLE': 'Tiêu đề A–Z'};

  /// Lề ngang của nội dung; hai hàng chip cuộn tràn tới mép màn hình.
  static const EdgeInsets _side = EdgeInsets.symmetric(horizontal: 16);

  final _search = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<GuideController>().openList(stage: widget.stage));
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guides = context.watch<GuideController>();
    final children = [..._filters(guides), ..._results(guides)];
    return Scaffold(
      appBar: const SenpaiAppBar(title: 'Cẩm nang'),
      body: RefreshIndicator(
        onRefresh: guides.loadGuides,
        child: ListView.separated(
          controller: _scroll,
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          itemCount: children.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (_, i) => children[i],
        ),
      ),
    );
  }

  List<Widget> _filters(GuideController guides) {
    return [
      Padding(
        padding: _side,
        child: Text(
          'Hướng dẫn thiết thực cho việc học tập và cuộc sống tại Nhật Bản.',
          style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
        ),
      ),
      Padding(
        padding: _side,
        child: TextField(
          controller: _search,
          maxLength: 200,
          textInputAction: TextInputAction.search,
          style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
          decoration: senpaiSearchDecoration(
            'Tìm theo tiêu đề, chủ đề hoặc từ khóa…',
            suffixIcon: IconButton(
              tooltip: 'Tìm kiếm',
              icon: const Icon(Symbols.arrow_forward_rounded, size: 22, color: SenpaiColors.brand),
              onPressed: () => guides.search(_search.text),
            ),
          ).copyWith(counterText: ''),
          onSubmitted: guides.search,
        ),
      ),
      _chipRow(
        label: 'Giai đoạn',
        selected: guides.stage,
        options: [for (final s in guides.stages) (s.code, s.title)],
        onSelect: guides.selectStage,
      ),
      _chipRow(
        label: 'Chủ đề',
        selected: guides.topic,
        options: [for (final t in guides.topics) (t.code, t.title)],
        onSelect: guides.selectTopic,
      ),
      Padding(
        padding: _side,
        child: Row(
          spacing: 8,
          children: [
            Expanded(
              child: Text(
                guides.isLoading ? 'Đang tải cẩm nang…' : '${guides.totalItems} cẩm nang phù hợp',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SenpaiText.labelM.copyWith(color: SenpaiColors.muted),
              ),
            ),
            _sortButton(guides),
          ],
        ),
      ),
    ];
  }

  /// Hàng chip cuộn ngang có tiêu đề Overline: "Tất cả" và các lựa chọn của server (ít nên dựng hết một lần).
  Widget _chipRow({
    required String label,
    required String? selected,
    required List<(String, String)> options,
    required ValueChanged<String?> onSelect,
  }) {
    // Mã trên link (từ "Cẩm nang của tôi") không còn trong danh sách của server
    final unknown = selected != null && options.isNotEmpty && !options.any((o) => o.$1 == selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Padding(padding: _side, child: OverlineLabel(label)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: _side,
          child: Row(
            spacing: 8,
            children: [
              _chip('Tất cả', selected == null, () => onSelect(null)),
              for (final (code, title) in options) _chip(title, selected == code, () => onSelect(code)),
              if (unknown) _chip('$label không tồn tại', true, () => onSelect(null)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chip(String text, bool selected, VoidCallback onTap) => ChoiceChip(
    label: Text(text),
    selected: selected,
    showCheckmark: false,
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    onSelected: (_) => onTap(),
  );

  /// `pill('sort', 'Mới nhất')`: viên thuốc trắng viền line cao 36, bấm mở menu chọn cách sắp xếp.
  Widget _sortButton(GuideController guides) {
    return PopupMenuButton<String>(
      tooltip: 'Sắp xếp',
      initialValue: guides.sort,
      onSelected: guides.selectSort,
      itemBuilder: (_) => [
        for (final entry in _sortLabels.entries) PopupMenuItem(value: entry.key, child: Text(entry.value)),
      ],
      child: Container(
        height: 36,
        padding: const EdgeInsets.only(left: 12, right: 10),
        decoration: const ShapeDecoration(
          color: SenpaiColors.surface,
          shape: StadiumBorder(side: BorderSide(color: SenpaiColors.line)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            const Icon(Symbols.sort_rounded, size: 18, color: SenpaiColors.ink),
            Text(_sortLabels[guides.sort] ?? 'Mới nhất', style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink)),
            const Icon(Symbols.arrow_drop_down_rounded, size: 20, color: SenpaiColors.muted),
          ],
        ),
      ),
    );
  }

  List<Widget> _results(GuideController guides) {
    if (guides.isLoading && guides.guides.isEmpty) {
      return const [SizedBox(height: 240, child: LoadingView())];
    }
    if (guides.error != null) {
      return [ErrorView(message: guides.error!, onRetry: guides.loadGuides)];
    }
    if (guides.guides.isEmpty) {
      return const [
        EmptyView(text: 'Không có cẩm nang phù hợp. Hãy thử từ khóa hoặc chủ đề khác.', icon: Symbols.menu_book_rounded),
      ];
    }
    return [
      for (final guide in guides.guides)
        Padding(padding: _side, child: GuideCard(guide: guide, onTap: () => _open(guide.id))),
      if (guides.isLoadingMore)
        const Center(child: CircularProgressIndicator(color: SenpaiColors.brand, strokeWidth: 3))
      else if (guides.hasMore)
        Center(child: TextButton(onPressed: _loadMore, child: const Text('Tải thêm'))),
    ];
  }

  void _onScroll() {
    if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
      final guides = context.read<GuideController>();
      if (guides.hasMore && !guides.isLoadingMore && !guides.isLoading) {
        _loadMore();
      }
    }
  }

  Future<void> _loadMore() async {
    final guides = context.read<GuideController>();
    await guides.loadMore();
    if (mounted) {
      showMessage(context, guides.takeMessage());
    }
  }

  Future<void> _open(int guideId) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => GuideDetailScreen(guideId: guideId)));
}
