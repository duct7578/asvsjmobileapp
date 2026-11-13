import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/recent_review.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/home_format.dart';
import 'package:myasvsj/com.myasvsj.screen/map_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/media_image.dart';
import 'package:myasvsj/com.myasvsj.screen/place_category_icon.dart';
import 'package:myasvsj/com.myasvsj.screen/place_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/place_rating_stars.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Một review của màn "Review mới" (`RecentReviewCard` của màn 11): thẻ bo 18; ô icon tròn 44 của danh mục, tên
/// địa điểm Title/S, loại · khu vực Caption; hàng sao + badge "Gần bạn" / "Cùng tỉnh", "Đã đóng cửa", "Hữu ích";
/// đoạn trích Body/M 4 dòng; ảnh đầu tiên bo 14 có "+n"; tác giả (ảnh đại diện 24, tên, tag) và thời gian · ♥;
/// đường kẻ và link "Xem trên bản đồ". Bấm vào thẻ thì mở chi tiết địa điểm.
class RecentReviewCard extends StatelessWidget {
  const RecentReviewCard({super.key, required this.review});

  final RecentReview review;

  static const _tones = [SenpaiTone.brand, SenpaiTone.ai, SenpaiTone.lantern, SenpaiTone.ok];

  @override
  Widget build(BuildContext context) {
    final where = areaShort(review.placeArea);
    final sub = [review.categoryName, if (where.isNotEmpty) where].where((s) => s.isNotEmpty).join(' · ');
    final caption = SenpaiText.caption.copyWith(color: SenpaiColors.muted);
    final meta = [if (review.createdAt != null) formatTimeAgo(review.createdAt!), '♥ ${review.likeCount}'].join(' · ');
    return SenpaiCard(
      radius: 18,
      onTap: () => pushScreen<void>(context, PlaceDetailScreen(placeId: review.placeId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            spacing: 10,
            children: [
              IconTile(
                placeCategoryIcon(review.categoryIcon),
                tone: placeCategoryTone(review.categoryIcon),
                size: 44,
                radius: 22,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.placeName,
                      style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sub.isNotEmpty) Text(sub, style: caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PlaceRatingStars(rating: review.rating.toDouble()),
              if (review.near == 'AREA') const SenpaiBadge('Gần bạn', icon: Symbols.location_on_rounded),
              if (review.near == 'PREFECTURE') const SenpaiBadge('Cùng tỉnh', icon: Symbols.map_rounded),
              if (review.placeClosed) const SenpaiBadge('Đã đóng cửa', tone: SenpaiTone.crit, icon: Symbols.block_rounded),
              if (review.isHelpful) const SenpaiBadge('Hữu ích', tone: SenpaiTone.ok, icon: Symbols.verified_rounded),
            ],
          ),
          Text(
            review.excerpt,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
          ),
          if ((review.photoUrl ?? '').isNotEmpty)
            Stack(
              children: [
                MediaImage(url: review.photoUrl!, height: 150, width: double.infinity, radius: 14),
                if (review.mediaCount > 1)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: SenpaiColors.ink.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '+${review.mediaCount - 1}',
                        style: SenpaiText.labelS.copyWith(color: SenpaiColors.onBrand),
                      ),
                    ),
                  ),
              ],
            )
          else if (review.mediaCount > 0)
            IconStat(Symbols.videocam_rounded, '${review.mediaCount} video'),
          Row(
            spacing: 6,
            children: [
              SenpaiAvatar(
                name: review.authorName,
                size: 24,
                tone: _tones[review.authorName.codeUnits.fold(0, (sum, c) => sum + c) % _tones.length],
              ),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(review.authorName, style: SenpaiText.labelS.copyWith(color: SenpaiColors.ink)),
                    for (final tag in review.authorTags) SenpaiBadge(tag.name, tone: SenpaiTone.ai),
                  ],
                ),
              ),
              Text(meta, style: caption, textAlign: TextAlign.right),
            ],
          ),
          const Divider(),
          LinkText(
            'Xem trên bản đồ',
            icon: Symbols.map_rounded,
            onTap: () => pushScreen<void>(context, MapScreen(focusPlaceId: review.placeId)),
          ),
        ],
      ),
    );
  }
}
