import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/home_controller.dart';
import 'package:myasvsj/com.myasvsj.model/recent_review_feed.dart';
import 'package:myasvsj/com.myasvsj.screen/empty_view.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/feed_settings_sheet.dart';
import 'package:myasvsj/com.myasvsj.screen/home_format.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/map_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/recent_review_card.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/sign_in_gate.dart';

/// "Review mới" (màn 11; "Tất cả" của thẻ "Review mới quanh …", `GET /api/home/reviews`): review địa điểm của
/// người khác, mới nhất trước, 10 mỗi lần, trong phạm vi Quanh khu vực / Cả tỉnh / Tất cả (hàng chip cuộn ngang).
/// Khách và thành viên chưa chọn khu vực chỉ có "Tất cả" (kèm lời mời). Mỗi review mở địa điểm của nó.
class RecentReviewsScreen extends StatefulWidget {
  const RecentReviewsScreen({super.key});

  @override
  State<RecentReviewsScreen> createState() => _RecentReviewsScreenState();
}

class _RecentReviewsScreenState extends State<RecentReviewsScreen> {
  bool _started = false;
  int? _userId;

  static const _side = EdgeInsets.symmetric(horizontal: 16);

  @override
  Widget build(BuildContext context) {
    final userId = context.select<AuthController, int?>((auth) => auth.currentUser?.id);
    if (!_started || userId != _userId) {
      // Lần đầu, hoặc vừa đăng nhập / đăng xuất: phạm vi chọn được đã đổi, mở lại từ đầu
      _started = true;
      _userId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<HomeController>().openReviews();
        }
      });
    }
    return Scaffold(
      appBar: const SenpaiAppBar(title: 'Review mới'),
      body: _body(context.watch<HomeController>(), signedIn: userId != null),
    );
  }

  Widget _body(HomeController home, {required bool signedIn}) {
    final feed = home.reviewFeed;
    if (feed == null) {
      if (home.reviewsError != null && !home.isLoadingReviews) {
        return ErrorView(message: home.reviewsError!, onRetry: home.openReviews);
      }
      return const LoadingView();
    }
    final reviews = home.reviews;
    // Mỗi khối có lề ngang 16, riêng hàng chip cuộn ngang chạm mép màn hình như thiết kế
    final sections = <Widget>[
      Padding(
        padding: _side,
        child: Text(
          '${feed.countOf(feed.scope)} review ${_scopeText(feed, feed.scope)}, mới nhất trước. '
          'Bấm vào một review để xem địa điểm.',
          style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
        ),
      ),
      if ((feed.areaName ?? '').isEmpty) Padding(padding: _side, child: _areaHint(home, signedIn: signedIn)),
      if (feed.scopes.length >= 2)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: _side,
          child: Row(
            spacing: 8,
            children: [
              for (final s in feed.scopes)
                ChoiceChip(
                  label: Text('${_scopeName(feed, s.code)} · ${s.count}'),
                  selected: s.code == feed.scope,
                  showCheckmark: false,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: (_) {
                    if (s.code != feed.scope) {
                      home.loadReviews(scope: s.code);
                    }
                  },
                ),
            ],
          ),
        ),
      if (home.isLoadingReviews) const Padding(padding: _side, child: LinearProgressIndicator(minHeight: 3)),
      if (home.reviewsError != null)
        Padding(
          padding: _side,
          child: Text(home.reviewsError!, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.crit)),
        ),
      if (reviews.isEmpty && !home.isLoadingReviews)
        Column(
          children: [
            EmptyView(
              text: feed.scope == 'ALL'
                  ? 'Chưa có review nào. Mở Bản đồ để viết review đầu tiên.'
                  : 'Chưa có review nào ${_scopeText(feed, feed.scope)}. Mở Bản đồ để viết review đầu tiên.',
              icon: Symbols.rate_review_rounded,
            ),
            SenpaiButton(
              label: 'Mở Bản đồ',
              icon: Symbols.map_rounded,
              kind: SenpaiButtonKind.ghost,
              size: SenpaiButtonSize.medium,
              onPressed: () => pushScreen<void>(context, const MapScreen()),
            ),
          ],
        ),
      for (final review in reviews) Padding(padding: _side, child: RecentReviewCard(review: review)),
      if (feed.hasMore)
        Center(
          child: home.isLoadingMoreReviews
              ? const CircularProgressIndicator()
              : SenpaiButton(
                  label: 'Xem thêm review',
                  kind: SenpaiButtonKind.ghost,
                  size: SenpaiButtonSize.small,
                  onPressed: home.loadMoreReviews,
                ),
        ),
    ];
    return RefreshIndicator(
      onRefresh: home.loadReviews,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          // Cuộn gần tới cuối thì tải trang sau (sau khung hình đang vẽ); chỉ theo danh sách dọc
          if (n is ScrollUpdateNotification && n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 200) {
            Future.microtask(home.loadMoreReviews);
          }
          return false;
        },
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          children: [
            for (var i = 0; i < sections.length; i++) ...[
              if (i > 0) const SizedBox(height: 14),
              sections[i],
            ],
          ],
        ),
      ),
    );
  }

  /// Khách và thành viên chưa chọn khu vực chỉ thấy "Tất cả": cách xem review quanh mình.
  Widget _areaHint(HomeController home, {required bool signedIn}) {
    return SenpaiCard(
      color: SenpaiColors.brandSoft,
      borderColor: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              const Icon(Symbols.location_on_rounded, size: 20, color: SenpaiColors.brandText),
              Expanded(
                child: Text(
                  signedIn
                      ? 'Chọn khu vực để xem review quanh bạn.'
                      : 'Đăng nhập và chọn khu vực để xem review quanh bạn.',
                  style: SenpaiText.bodyS.copyWith(color: SenpaiColors.brandText),
                ),
              ),
            ],
          ),
          signedIn
              ? SenpaiButton(
                  label: 'Chọn khu vực',
                  icon: Symbols.edit_location_alt_rounded,
                  kind: SenpaiButtonKind.secondary,
                  size: SenpaiButtonSize.small,
                  onPressed: () async {
                    if (await openFeedSetting(context, areaAndStage: true)) {
                      home.openReviews();
                    }
                  },
                )
              : SenpaiButton(
                  label: 'Đăng nhập',
                  icon: Symbols.login_rounded,
                  size: SenpaiButtonSize.small,
                  onPressed: () => requireSignIn(context),
                ),
        ],
      ),
    );
  }

  /// Tên nút phạm vi: "Quanh Arakawa-ku", "Cả tỉnh Tokyo", "Tất cả".
  static String _scopeName(RecentReviewFeed feed, String code) => switch (code) {
    'AREA' => 'Quanh ${areaShort(feed.areaName)}',
    'PREFECTURE' => 'Cả tỉnh ${feed.prefectureName ?? ''}',
    _ => 'Tất cả',
  };

  /// "quanh Arakawa-ku", "trong tỉnh Tokyo", "trên Senpai ơi".
  static String _scopeText(RecentReviewFeed feed, String code) => switch (code) {
    'AREA' => 'quanh ${areaShort(feed.areaName)}',
    'PREFECTURE' => 'trong tỉnh ${feed.prefectureName ?? ''}',
    _ => 'trên Senpai ơi',
  };
}
