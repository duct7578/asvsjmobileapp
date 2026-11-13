import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/home_event.dart';
import 'package:myasvsj/com.myasvsj.model/home_featured.dart';
import 'package:myasvsj/com.myasvsj.model/home_member.dart';
import 'package:myasvsj/com.myasvsj.model/home_review.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/event_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/event_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/home_for_you_section.dart';
import 'package:myasvsj/com.myasvsj.screen/home_format.dart';
import 'package:myasvsj/com.myasvsj.screen/home_next_card.dart';
import 'package:myasvsj/com.myasvsj.screen/home_phrase_card.dart';
import 'package:myasvsj/com.myasvsj.screen/home_search_box.dart';
import 'package:myasvsj/com.myasvsj.screen/home_tag_chips.dart';
import 'package:myasvsj/com.myasvsj.screen/place_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/recent_reviews_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Trang chủ của thành viên (màn 02 của thiết kế, một trang cuộn dài): lời chào, ô tìm kiếm, "Việc tiếp theo",
/// "Dành cho bạn" (và "Cẩm nang cho giai đoạn …"), "Review mới quanh …", sự kiện 2 tuần tới, câu tiếng Nhật
/// hôm nay, bài nổi bật. Các khối là thẻ trắng bo 20, cách nhau 16.
class HomeMemberView extends StatelessWidget {
  const HomeMemberView({
    super.key,
    required this.home,
    this.banner,
    this.notice,
    this.showAreaPrompt = false,
    required this.onHidePrompt,
    required this.onSettingsSaved,
  });

  final HomeMember home;

  /// Báo lỗi khi tải lại (giữ trang cũ); null khi không có.
  final Widget? banner;
  final String? notice;
  final bool showAreaPrompt;
  final VoidCallback onHidePrompt;
  final VoidCallback onSettingsSaved;

  @override
  Widget build(BuildContext context) {
    final stage = home.stage ?? '';
    final blocks = <Widget>[
      ?banner,
      _Greeting(home: home),
      const HomeSearchBox(),
      if (home.guide != null) HomeNextCard(guide: home.guide!),
      HomeForYouSection(
        home: home,
        notice: notice,
        showAreaPrompt: showAreaPrompt,
        onHidePrompt: onHidePrompt,
        onSettingsSaved: onSettingsSaved,
      ),
      if (home.stageGuides.isNotEmpty && stage.isNotEmpty) HomeStageGuidesCard(stage: stage, guides: home.stageGuides),
      _ReviewsCard(home: home),
      _EventsCard(events: home.events),
      if (home.phrase != null) HomePhraseCard(phrase: home.phrase!),
      if (home.featured != null) _FeaturedCard(featured: home.featured!),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        for (var i = 0; i < blocks.length; i++) ...[if (i > 0) const SizedBox(height: 16), blocks[i]],
      ],
    );
  }
}

/// Lời chào: ô hoa tròn 52 tone brand, "Chào (tên gọi), …" Title/M, badge giai đoạn và "điểm · hạng ›"
/// (bấm mở trang Tôi).
class _Greeting extends StatelessWidget {
  const _Greeting({required this.home});

  final HomeMember home;

  @override
  Widget build(BuildContext context) {
    final stage = home.stage ?? '';
    return Row(
      spacing: 12,
      children: [
        const IconTile(Symbols.local_florist_rounded, size: 52, radius: 26),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                homeGreeting(displayName: home.displayName, stage: home.stage, areaName: home.areaName),
                style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink),
              ),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (stage.isNotEmpty) SenpaiBadge(stageName(stage), icon: Symbols.flag_rounded),
                  InkWell(
                    onTap: () => pushScreen<void>(context, const ProfileScreen()),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 2,
                        children: [
                          Flexible(
                            child: Text(
                              '${groupDigits(home.points)} điểm · ${home.rankName}',
                              style: SenpaiText.labelS.copyWith(color: SenpaiColors.brandText),
                            ),
                          ),
                          const Icon(Symbols.chevron_right_rounded, size: 16, color: SenpaiColors.brandText),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Review mới quanh …": 3 review, trong khu vực trước rồi trong tỉnh. Tiêu đề chỉ nói "quanh" khi có review
/// thật sự ở khu vực; mỗi review mở địa điểm của nó. Thẻ trắng bo 20 p16, các dòng cách 14.
class _ReviewsCard extends StatelessWidget {
  const _ReviewsCard({required this.home});

  final HomeMember home;

  @override
  Widget build(BuildContext context) {
    final reviews = home.reviews;
    final area = home.areaName ?? '';
    final inArea = reviews.any((r) => r.near == 'AREA');
    final inPrefecture = reviews.any((r) => r.near == 'PREFECTURE');
    final title = area.isEmpty
        ? 'Review mới'
        : inArea
        ? 'Review mới quanh ${areaShort(area)}'
        : inPrefecture
        ? 'Review mới ở ${prefectureShort(area)}'
        : 'Review mới';
    final muted = SenpaiText.bodyS.copyWith(color: SenpaiColors.muted);
    return SenpaiCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          SectionHead(
            title,
            icon: Symbols.rate_review_rounded,
            action: 'Tất cả',
            onAction: () => pushScreen<void>(context, const RecentReviewsScreen()),
          ),
          if (area.isNotEmpty && reviews.isNotEmpty && !inArea)
            Text(
              'Chưa có review nào ở ${areaShort(area)}, đây là review mới '
              '${inPrefecture ? 'trong tỉnh' : 'ở nơi khác'}.',
              style: muted,
            ),
          if (reviews.isEmpty) Text('Chưa có review mới.', style: muted),
          for (final review in reviews) _ReviewRow(review: review),
        ],
      ),
    );
  }
}

/// Một review (`rv()` của thiết kế): ô icon tròn 40 theo loại địa điểm, tên địa điểm + sao, "Tác giả: trích đoạn"
/// 2 dòng, "khu vực · thời gian".
class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.review});

  final HomeReview review;

  @override
  Widget build(BuildContext context) {
    final where = areaRoman(review.placeArea);
    final meta = [if (where.isNotEmpty) where, if (review.createdAt != null) formatTimeAgo(review.createdAt!)].join(' · ');
    return InkWell(
      onTap: () => pushScreen<void>(context, PlaceDetailScreen(placeId: review.placeId)),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          IconTile(categoryIcon(review.categoryIcon), tone: categoryTone(review.categoryIcon), radius: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Row(
                  spacing: 6,
                  children: [
                    Expanded(
                      child: Text(review.placeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
                    ),
                    Semantics(
                      label: '${review.rating} sao',
                      child: ExcludeSemantics(child: StarRow(review.rating.toDouble(), size: 14)),
                    ),
                  ],
                ),
                Text(
                  '${review.authorName}: ${review.excerpt}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SenpaiText.bodyS.copyWith(color: SenpaiColors.ink),
                ),
                if (meta.isNotEmpty) Text(meta, style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Sự kiện 2 tuần tới": mỗi sự kiện có ô ngày brand-soft 52 × 56 (ngày Display/M, "Th11" Label/S), tên Title/S,
/// "Còn n ngày · nơi tổ chức" Caption và chevron.
class _EventsCard extends StatelessWidget {
  const _EventsCard({required this.events});

  final List<HomeEvent> events;

  @override
  Widget build(BuildContext context) {
    return SenpaiCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          SectionHead(
            'Sự kiện 2 tuần tới',
            icon: Symbols.celebration_rounded,
            action: 'Tất cả',
            onAction: () => pushScreen<void>(context, const EventListScreen()),
          ),
          if (events.isEmpty)
            Text('Chưa có sự kiện nào trong 2 tuần tới.', style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
          for (final event in events) _EventRow(event: event),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event});

  final HomeEvent event;

  @override
  Widget build(BuildContext context) {
    final date = event.startDate;
    return InkWell(
      onTap: () => pushScreen<void>(context, EventDetailScreen(eventId: event.id)),
      borderRadius: BorderRadius.circular(14),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 52,
            height: 56,
            decoration: BoxDecoration(color: SenpaiColors.brandSoft, borderRadius: BorderRadius.circular(14)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(date.day.toString().padLeft(2, '0'),
                    style: SenpaiText.displayM.copyWith(color: SenpaiColors.brandText)),
                Text('Th${date.month}', style: SenpaiText.labelS.copyWith(color: SenpaiColors.brandText)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(event.title,
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
                Text(
                  [eventWhen(event.daysUntil), if (event.locationName.isNotEmpty) event.locationName].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
                ),
              ],
            ),
          ),
          const Icon(Symbols.chevron_right_rounded, size: 22, color: SenpaiColors.muted),
        ],
      ),
    );
  }
}

/// "Bài nổi bật tuần này / tháng này": thẻ trắng bo 20, ảnh bìa minh hoạ cao 140 trên đầu, badge lantern, số phút
/// đọc, tiêu đề Title/M, trích đoạn 2 dòng, tác giả + tag định danh.
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.featured});

  final HomeFeatured featured;

  @override
  Widget build(BuildContext context) {
    return SenpaiCard(
      radius: 20,
      padding: EdgeInsets.zero,
      onTap: () => pushScreen<void>(context, BlogDetailScreen(blogId: featured.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CoverArt(scene: CoverScene.forSeed(featured.id), height: 140),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Row(
                  spacing: 6,
                  children: [
                    SenpaiBadge(
                      'Bài nổi bật ${featured.isThisWeek ? 'tuần này' : 'tháng này'}',
                      tone: SenpaiTone.lantern,
                      icon: Symbols.star_rounded,
                    ),
                    Expanded(
                      child: Text(
                        '${featured.readMinutes} phút đọc',
                        textAlign: TextAlign.right,
                        style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
                      ),
                    ),
                  ],
                ),
                Text(featured.title,
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink)),
                if (featured.excerpt.isNotEmpty)
                  Text(featured.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
                Row(
                  spacing: 6,
                  children: [
                    SenpaiAvatar(name: featured.authorName, size: 24, tone: SenpaiTone.lantern),
                    Flexible(
                      child: Text(featured.authorName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SenpaiText.labelS.copyWith(color: SenpaiColors.ink)),
                    ),
                    if (featured.authorTags.isNotEmpty) Flexible(child: HomeTagChips(tags: featured.authorTags)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
