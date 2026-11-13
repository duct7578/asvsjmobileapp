import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/home_controller.dart';
import 'package:myasvsj/com.myasvsj.model/for_you_feed.dart';
import 'package:myasvsj/com.myasvsj.screen/auth_required_view.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/empty_view.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/feed_basis.dart';
import 'package:myasvsj/com.myasvsj.screen/feed_post_card.dart';
import 'package:myasvsj/com.myasvsj.screen/feed_settings_sheet.dart';
import 'package:myasvsj/com.myasvsj.screen/global_search_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/home_format.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// "Dành cho bạn" (màn 04 của thiết kế; "Xem tất cả" ở trang chủ thành viên, `GET /api/me/for-you`): mọi bài
/// Senpai ơi chọn cho người dùng, xếp như 5 bài trên trang chủ, 10 bài mỗi lần. Ô "Tìm trong bài dành cho bạn",
/// hộp "Dựa trên", hàng chip lọc theo lý do (Tất cả / Gần bạn / Hợp giai đoạn / Chủ đề quan tâm) cuộn ngang, rồi
/// các thẻ bài. Chỉ dành cho thành viên: khách được mời đăng nhập.
class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key, this.initialQuery = '', this.autofocusSearch = false});

  /// Tìm sẵn chữ này (từ "Chỉ tìm trong bài dành cho bạn" của màn Tìm kiếm).
  final String initialQuery;

  /// Đặt con trỏ vào ô tìm kiếm khi mở (kính lúp ở "Dành cho bạn" trên trang chủ).
  final bool autofocusSearch;

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> {
  /// Gõ xong chờ chừng này mới hỏi server (Enter thì hỏi ngay), như web.
  static const _typingDelay = Duration(milliseconds: 350);

  static const Map<String, String> _scopeNames = {
    'ALL': 'Tất cả',
    'NEAR': 'Gần bạn',
    'STAGE': 'Hợp giai đoạn',
    'INTEREST': 'Chủ đề quan tâm',
  };

  late final TextEditingController _search = TextEditingController(text: _clip(widget.initialQuery.trim()));
  Timer? _typing;
  bool _started = false;
  int? _userId;

  static String _clip(String text) =>
      text.length > HomeController.queryMax ? text.substring(0, HomeController.queryMax) : text;

  @override
  void dispose() {
    _typing?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.select<AuthController, int?>((auth) => auth.currentUser?.id);
    if (!_started || userId != _userId) {
      _started = true;
      _userId = userId;
      if (userId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<HomeController>().openForYou(q: _search.text);
          }
        });
      }
    }
    return Scaffold(
      appBar: const SenpaiAppBar(title: 'Dành cho bạn', subtitle: 'Chọn riêng theo khu vực, giai đoạn, chủ đề'),
      body: userId == null
          ? const AuthRequiredView(
              text:
                  'Đăng nhập để xem những bài viết Senpai ơi chọn riêng cho bạn, theo khu vực, giai đoạn và chủ đề '
                  'bạn quan tâm.',
            )
          : _member(context.watch<HomeController>()),
    );
  }

  Widget _member(HomeController home) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: TextField(
            key: const ValueKey('for-you-search'),
            controller: _search,
            autofocus: widget.autofocusSearch,
            textInputAction: TextInputAction.search,
            inputFormatters: [LengthLimitingTextInputFormatter(HomeController.queryMax)],
            onChanged: (text) {
              setState(() {});
              _typing?.cancel();
              _typing = Timer(_typingDelay, () => home.searchForYou(text));
            },
            onSubmitted: (text) {
              _typing?.cancel();
              home.searchForYou(text, always: true);
            },
            decoration: senpaiSearchDecoration(
              'Tìm trong bài dành cho bạn',
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa từ khóa',
                      icon: const Icon(Symbols.close_rounded, size: 20),
                      onPressed: () => _clear(home),
                    ),
            ),
          ),
        ),
        Expanded(child: _list(home)),
      ],
    );
  }

  void _clear(HomeController home) {
    _typing?.cancel();
    _search.clear();
    setState(() {});
    home.searchForYou('');
  }

  /// Lề ngang 16 của thân trang (hàng chip cuộn ngang thì tràn tới mép màn hình).
  static Widget _side(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

  Widget _list(HomeController home) {
    final feed = home.forYou;
    if (feed == null) {
      if (home.forYouError != null && !home.isLoadingForYou) {
        return ErrorView(message: home.forYouError!, onRetry: () => home.loadForYou());
      }
      return const LoadingView();
    }
    final posts = home.forYouPosts;
    final firstEngaged = posts.indexWhere((p) => p.engaged);
    final blocks = <Widget>[
      _side(Text(_summary(feed), style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted))),
      _side(
        FeedBasis(
          areaName: feed.areaName,
          stage: feed.stage,
          interests: feed.interests,
          chosenInterests: feed.chosenInterests,
          onAdjust: () => _adjust(home),
          boxed: true,
        ),
      ),
      if (feed.scopes.length >= 2)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            spacing: 8,
            children: [
              for (final s in feed.scopes)
                ChoiceChip(
                  showCheckmark: false,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text('${_scopeNames[s.code] ?? s.code} · ${s.count}'),
                  selected: s.code == feed.scope,
                  onSelected: (_) {
                    if (s.code != feed.scope) {
                      home.loadForYou(scope: s.code);
                    }
                  },
                ),
            ],
          ),
        ),
      if (home.isLoadingForYou) _side(const LinearProgressIndicator(minHeight: 4)),
      if (home.forYouError != null)
        _side(SenpaiNote(home.forYouError!, icon: Symbols.error_rounded, tone: SenpaiTone.crit)),
      if (posts.isEmpty && !home.isLoadingForYou) _side(_empty(home, feed)),
      for (var i = 0; i < posts.length; i++) ...[
        if (i == firstEngaged)
          _side(
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                spacing: 6,
                children: [
                  const Icon(Symbols.history_rounded, size: 18, color: SenpaiColors.muted),
                  Expanded(
                    child: Text('Bài bạn đã thích, lưu hoặc bình luận',
                        style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
                  ),
                ],
              ),
            ),
          ),
        _side(FeedPostCard(post: posts[i], query: home.forYouQuery)),
      ],
      if (feed.hasMore)
        Center(
          child: home.isLoadingMoreForYou
              ? const CircularProgressIndicator()
              : SenpaiButton(
                  label: 'Xem thêm bài viết',
                  kind: SenpaiButtonKind.secondary,
                  size: SenpaiButtonSize.medium,
                  onPressed: home.loadMoreForYou,
                ),
        ),
    ];
    return RefreshIndicator(
      onRefresh: home.loadForYou,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          // Cuộn gần tới cuối thì tải trang sau (sau khung hình đang vẽ)
          if (n is ScrollUpdateNotification && n.metrics.extentAfter < 200) {
            Future.microtask(home.loadMoreForYou);
          }
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.only(top: 14, bottom: 24),
          children: [
            for (var i = 0; i < blocks.length; i++) ...[if (i > 0) const SizedBox(height: 14), blocks[i]],
          ],
        ),
      ),
    );
  }

  /// Phạm vi đang xem có bao nhiêu bài và xếp thế nào (summaryText của web).
  static String _summary(ForYouFeed feed) {
    final posts = '${feed.countOf(feed.scope)} bài viết';
    final q = feed.q ?? '';
    final area = areaShort(feed.areaName);
    final stage = stageName(feed.stage);
    if (q.isNotEmpty) {
      final found = '$posts có “$q”';
      return switch (feed.scope) {
        'NEAR' => '$found, gắn với địa điểm ở $area hoặc trong cùng tỉnh.',
        'STAGE' => '$found, có chủ đề hợp giai đoạn “$stage”.',
        'INTEREST' => '$found, thuộc chủ đề bạn quan tâm.',
        _ => '$found trong các bài dành cho bạn, xếp như danh sách gợi ý.',
      };
    }
    return switch (feed.scope) {
      'NEAR' => '$posts gắn với địa điểm ở $area hoặc trong cùng tỉnh.',
      'STAGE' => '$posts có chủ đề hợp giai đoạn “$stage”.',
      'INTEREST' => '$posts thuộc chủ đề bạn quan tâm.',
      _ =>
        '$posts của các thành viên khác, xếp theo khu vực, giai đoạn và chủ đề bạn quan tâm. Bài trong 30 ngày '
            'qua đứng trước; bài bạn đã thích, lưu hoặc bình luận xếp cuối.',
    };
  }

  Widget _empty(HomeController home, ForYouFeed feed) {
    final q = feed.q ?? '';
    if (q.isNotEmpty) {
      final where = feed.scope == 'ALL' ? 'trong các bài dành cho bạn' : 'trong mục này';
      return Column(
        children: [
          EmptyView(text: 'Không có bài viết nào có “$q” $where.', icon: Symbols.search_off_rounded),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              SenpaiButton(
                label: 'Tìm “$q” trên toàn Senpai ơi',
                kind: SenpaiButtonKind.soft,
                size: SenpaiButtonSize.medium,
                onPressed: () => pushScreen<void>(context, GlobalSearchScreen(initialQuery: q)),
              ),
              SenpaiButton(
                label: 'Xóa từ khóa',
                kind: SenpaiButtonKind.ghost,
                size: SenpaiButtonSize.medium,
                onPressed: () => _clear(home),
              ),
            ],
          ),
        ],
      );
    }
    final text = switch (feed.scope) {
      'NEAR' => 'Chưa có bài viết nào gắn với địa điểm quanh bạn.',
      'STAGE' => 'Chưa có bài viết nào có chủ đề hợp giai đoạn của bạn.',
      'INTEREST' => 'Chưa có bài viết nào thuộc chủ đề bạn quan tâm.',
      _ => 'Chưa có bài viết phù hợp.',
    };
    return Column(
      children: [
        EmptyView(text: '$text Hãy xem thêm ở Blog.', icon: Symbols.auto_awesome_rounded),
        SenpaiButton(
          label: 'Mở Blog',
          icon: Symbols.article_rounded,
          kind: SenpaiButtonKind.ghost,
          size: SenpaiButtonSize.medium,
          onPressed: () => pushScreen<void>(context, const BlogListScreen()),
        ),
      ],
    );
  }

  /// "Điều chỉnh": đổi khu vực, giai đoạn hoặc chủ đề rồi tải lại gợi ý (cả trang chủ, để hai nơi khớp nhau).
  Future<void> _adjust(HomeController home) async {
    if (await showFeedSettings(context)) {
      home.loadForYou();
      home.loadHome(signedIn: true, notice: HomeController.savedNotice);
    }
  }
}
