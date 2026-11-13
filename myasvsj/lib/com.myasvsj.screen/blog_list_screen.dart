import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/blog_controller.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_card.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_featured_list.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_stats_card.dart';
import 'package:myasvsj/com.myasvsj.screen/empty_view.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/sign_in_gate.dart';

/// Tab Blog (màn 12 của thiết kế): ô tìm kiếm, nút sắp xếp và chip chủ đề, bài nổi bật, thống kê cộng đồng,
/// số bài và danh sách bài (tải thêm khi cuộn tới cuối). Nút nổi "Viết bài" mở form tạo bài (khách được đưa sang
/// đăng nhập trước).
class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});

  /// Nhãn của các cách sắp xếp (giống web).
  static const sortLabels = {'NEWEST': 'Mới nhất', 'LIKES': 'Nhiều thích', 'COMMENTS': 'Nhiều bình luận'};

  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  /// Khoảng cách giữa các khối của thân màn hình (body gap 14 của thiết kế).
  static const double _gap = 14;

  final _search = TextEditingController();
  final _scroll = ScrollController();

  /// Người đang đăng nhập lần vẽ trước: đổi thì tải lại (tác giả thấy thêm bài đang quét ảnh của mình).
  int? _userId;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _userId = context.read<AuthController>().currentUser?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final blogs = context.read<BlogController>();
      _search.text = blogs.query;
      blogs.openList();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 400) {
      context.read<BlogController>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final blogs = context.watch<BlogController>();
    final userId = context.select<AuthController, int?>((auth) => auth.currentUser?.id);
    if (userId != _userId) {
      _userId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<BlogController>().loadBlogs();
        }
      });
    }
    return Scaffold(
      appBar: const SenpaiLargeAppBar(title: 'Blog'),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Viết bài',
        onPressed: _openForm,
        icon: const Icon(Symbols.edit_rounded),
        label: const Text('Viết bài'),
      ),
      body: RefreshIndicator(onRefresh: blogs.refresh, child: _list(blogs)),
    );
  }

  /// Lề ngang 16 của thân màn hình.
  static Widget _pad(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

  Widget _list(BlogController blogs) {
    final header = <Widget>[
      _pad(_searchField(blogs)),
      _filterBar(blogs),
      if (blogs.isFiltered) _pad(_filterSummary(blogs)),
      ..._overview(blogs),
      if (!blogs.isFiltered && blogs.blogs.isNotEmpty)
        _pad(Text('${blogs.totalItems} bài', style: SenpaiText.labelM.copyWith(color: SenpaiColors.muted))),
    ];
    final body = _bodyState(blogs);
    final items = blogs.blogs;
    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      // Chừa chỗ cho nút "Viết bài" ở đáy
      padding: const EdgeInsets.only(top: 4, bottom: 96),
      itemCount: header.length + (body != null ? 1 : items.length + 1),
      itemBuilder: (context, i) {
        if (i < header.length) {
          return Padding(padding: const EdgeInsets.only(bottom: _gap), child: header[i]);
        }
        if (body != null) {
          return body;
        }
        final index = i - header.length;
        if (index < items.length) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, _gap),
            child: BlogCard(blog: items[index], onTopicTap: (topic) => blogs.filterByTopic(topic.id)),
          );
        }
        return _footer(blogs);
      },
    );
  }

  /// Trạng thái thay cho danh sách: đang tải lần đầu, lỗi, rỗng. null khi có bài để hiện.
  Widget? _bodyState(BlogController blogs) {
    if (blogs.error != null) {
      return ErrorView(message: blogs.error!, onRetry: blogs.loadBlogs);
    }
    if (blogs.blogs.isEmpty && (blogs.isLoading || !blogs.isListLoaded)) {
      return const SizedBox(height: 240, child: LoadingView());
    }
    if (blogs.blogs.isEmpty) {
      if (blogs.isFiltered) {
        return Column(
          children: [
            const EmptyView(text: 'Không có bài viết nào khớp với lựa chọn của bạn.', icon: Symbols.search_off_rounded),
            SenpaiButton(
              label: 'Xóa bộ lọc',
              kind: SenpaiButtonKind.secondary,
              size: SenpaiButtonSize.medium,
              icon: Symbols.filter_alt_off_rounded,
              onPressed: _clearFilters,
            ),
          ],
        );
      }
      return const EmptyView(text: 'Chưa có bài viết nào.', icon: Symbols.forum_rounded);
    }
    return null;
  }

  /// `search(...)` của thiết kế, gõ được: viên thuốc cao 48, icon search, nút xoá từ khóa khi đã gõ.
  Widget _searchField(BlogController blogs) {
    return TextField(
      controller: _search,
      maxLength: 100,
      textInputAction: TextInputAction.search,
      onSubmitted: blogs.search,
      onChanged: (_) => setState(() {}),
      style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
      decoration: senpaiSearchDecoration(
        'Tìm theo tiêu đề, nội dung hoặc địa điểm',
        suffixIcon: _search.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Xóa từ khóa',
                icon: const Icon(Symbols.close_rounded, size: 20),
                onPressed: () {
                  _search.clear();
                  blogs.search('');
                  setState(() {});
                },
              ),
      ).copyWith(counterText: ''),
    );
  }

  /// Nút sắp xếp (pill) và các chip chủ đề, cuộn ngang sát mép màn hình.
  Widget _filterBar(BlogController blogs) {
    final topics = blogs.overview?.topics ?? const [];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          PopupMenuButton<String>(
            tooltip: 'Sắp xếp',
            initialValue: blogs.sort,
            onSelected: blogs.setSort,
            position: PopupMenuPosition.under,
            itemBuilder: (_) => [
              for (final entry in BlogListScreen.sortLabels.entries)
                PopupMenuItem(value: entry.key, child: Text(entry.value)),
            ],
            child: _SortPill(label: BlogListScreen.sortLabels[blogs.sort] ?? ''),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Tất cả'),
            selected: blogs.filterTopicIds.isEmpty,
            showCheckmark: false,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onSelected: (_) => _allTopics(blogs),
          ),
          for (final topic in topics) ...[
            const SizedBox(width: 8),
            FilterChip(
              label: Text(topic.name),
              selected: blogs.filterTopicIds.contains(topic.id),
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onSelected: (_) => blogs.toggleTopic(topic.id),
            ),
          ],
        ],
      ),
    );
  }

  /// Chip "Tất cả": bỏ chọn mọi chủ đề, giữ nguyên từ khóa đang tìm.
  void _allTopics(BlogController blogs) {
    for (final id in [...blogs.filterTopicIds]) {
      blogs.toggleTopic(id);
    }
  }

  Widget _filterSummary(BlogController blogs) {
    return Row(
      children: [
        Expanded(
          child: Text(
            blogs.isLoading ? 'Đang tìm…' : '${blogs.totalItems} bài phù hợp',
            style: SenpaiText.labelM.copyWith(color: SenpaiColors.muted),
          ),
        ),
        TextButton.icon(
          style: SenpaiButtonStyle.ghost(SenpaiButtonSize.small),
          onPressed: _clearFilters,
          icon: const Icon(Symbols.close_rounded),
          label: const Text('Xóa bộ lọc'),
        ),
      ],
    );
  }

  /// Bài nổi bật và thống kê: chỉ hiện khi không lọc, như web.
  List<Widget> _overview(BlogController blogs) {
    final overview = blogs.overview;
    if (overview == null || blogs.isFiltered) {
      return const [];
    }
    return [
      if (overview.featured.isNotEmpty) BlogFeaturedList(period: overview.featuredPeriod, posts: overview.featured),
      _pad(BlogStatsCard(overview: overview, onTopicTap: blogs.filterByTopic)),
    ];
  }

  Widget _footer(BlogController blogs) {
    if (blogs.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (blogs.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          spacing: 4,
          children: [
            Text(
              blogs.loadMoreError!,
              textAlign: TextAlign.center,
              style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
            ),
            TextButton(onPressed: blogs.loadMore, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    if (blogs.hasMore) {
      return Center(
        child: TextButton.icon(
          onPressed: blogs.loadMore,
          icon: const Icon(Symbols.expand_more_rounded),
          label: const Text('Tải thêm'),
        ),
      );
    }
    return const SizedBox(height: 16);
  }

  void _clearFilters() {
    _search.clear();
    context.read<BlogController>().clearFilters();
  }

  /// Viết bài cần tài khoản User: khách được đưa sang đăng nhập trước.
  Future<void> _openForm() async {
    if (!await requireSignIn(context) || !mounted) {
      return;
    }
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const BlogFormScreen()));
    if (saved == true && mounted) {
      showMessage(context, context.read<BlogController>().takeMessage());
    }
  }
}

/// `pill('sort', label)` của thiết kế: viên thuốc trắng viền line cao 36, icon sort 18, chữ Label/M,
/// mũi tên arrow_drop_down muted.
class _SortPill extends StatelessWidget {
  const _SortPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(label, style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink)),
          const Icon(Symbols.arrow_drop_down_rounded, size: 20, color: SenpaiColors.muted),
        ],
      ),
    );
  }
}
