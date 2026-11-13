import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/map_place.dart';
import 'package:myasvsj/com.myasvsj.model/place_detail.dart';
import 'package:myasvsj/com.myasvsj.model/place_option.dart';
import 'package:myasvsj/com.myasvsj.screen/place_category_icon.dart';
import 'package:myasvsj/com.myasvsj.screen/place_directions_button.dart';
import 'package:myasvsj/com.myasvsj.screen/place_rating_stars.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Bảng dưới (bottom sheet) khi bấm một ghim (`PlaceSummarySheet` của màn 08): badge danh mục và nguồn, tên
/// Display/M, tên Nhật / Anh, hàng sao + số review + khoảng cách, ghi chú (cảnh báo lừa đảo, OpenStreetMap), hai
/// nút cỡ M "Xem chi tiết" và "Chỉ đường".
///
/// Địa điểm OpenStreetMap chưa có trên Senpai ơi ([PlaceSummarySheet.option] không có id) có "Viết review đầu
/// tiên" thay cho "Xem chi tiết", giống bảng "chưa có trên Senpai ơi" của web.
///
/// Bảng tự vẽ thanh nắm kéo: mở bằng `showModalBottomSheet(showDragHandle: false, …)`.
class PlaceSummarySheet extends StatelessWidget {
  const PlaceSummarySheet({
    super.key,
    required this.name,
    this.subtitle = '',
    this.categoryName = '',
    this.categoryIcon = 'place',
    this.source = '',
    this.reviewCount = 0,
    this.rating,
    this.closed = false,
    this.scam = false,
    this.pending = false,
    this.onSenpai = true,
    this.distanceText = '',
    required this.directionsUrl,
    this.onOpenDetail,
    this.onWriteFirst,
  });

  /// Ghim của Senpai ơi.
  PlaceSummarySheet.place(
    MapPlace place, {
    Key? key,
    String categoryName = '',
    String categoryIcon = 'place',
    String distanceText = '',
    VoidCallback? onOpenDetail,
  }) : this(
         key: key,
         name: place.name,
         subtitle: [place.nameJa, place.nameEn].where((s) => s.isNotEmpty).join(' · '),
         categoryName: categoryName,
         categoryIcon: categoryIcon,
         source: place.source,
         reviewCount: place.reviewCount,
         rating: place.rating,
         closed: place.closed,
         scam: place.scam,
         pending: place.isPending,
         distanceText: distanceText,
         directionsUrl: place.directionsUrl,
         onOpenDetail: onOpenDetail,
       );

  /// Kết quả tìm kiếm / quanh đây chưa có ghim (địa điểm OpenStreetMap).
  PlaceSummarySheet.option(
    PlaceOption option, {
    Key? key,
    String categoryIcon = 'place',
    String distanceText = '',
    VoidCallback? onOpenDetail,
    VoidCallback? onWriteFirst,
  }) : this(
         key: key,
         name: option.name,
         subtitle: [
           if (option.nameJa != option.name) option.nameJa,
           option.address,
         ].where((s) => s.isNotEmpty).join(' · '),
         categoryName: option.category,
         categoryIcon: categoryIcon,
         onSenpai: option.isOnSenpai,
         distanceText: distanceText,
         directionsUrl: option.directionsUrl,
         onOpenDetail: onOpenDetail,
         onWriteFirst: onWriteFirst,
       );

  final String name;

  /// Tên tiếng Nhật, tiếng Anh, địa chỉ.
  final String subtitle;
  final String categoryName;
  final String categoryIcon;

  /// Nguồn của ghim (`source` của MapPlace: TEAM, USER, OSM…); rỗng thì không hiện.
  final String source;
  final int reviewCount;
  final double? rating;
  final bool closed;
  final bool scam;
  final bool pending;

  /// false: địa điểm OpenStreetMap chưa có trên Senpai ơi.
  final bool onSenpai;

  /// Khoảng cách từ vị trí của tôi, ví dụ "350 m"; rỗng khi chưa biết.
  final String distanceText;
  final String directionsUrl;
  final VoidCallback? onOpenDetail;
  final VoidCallback? onWriteFirst;

  @override
  Widget build(BuildContext context) {
    final rated = onSenpai && reviewCount > 0 && rating != null;
    final badges = [
      if (categoryName.isNotEmpty) SenpaiBadge(categoryName, icon: placeCategoryIcon(categoryIcon)),
      if (!onSenpai)
        const SenpaiBadge('OpenStreetMap', tone: SenpaiTone.neutral, icon: Symbols.public_rounded)
      else if (source.isNotEmpty)
        placeSourceBadge(source),
      if (pending) const SenpaiBadge('Chờ Moderator duyệt', tone: SenpaiTone.warn, icon: Symbols.schedule_rounded),
      if (closed) const SenpaiBadge('Đã đóng cửa', tone: SenpaiTone.crit, icon: Symbols.block_rounded),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            const SheetHandle(),
            if (badges.isNotEmpty) Wrap(spacing: 6, runSpacing: 6, children: badges),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SenpaiText.displayM.copyWith(color: SenpaiColors.ink),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (rated) ...[
                  PlaceRatingStars(rating: rating!, size: 18),
                  Text(
                    '${rating!.toStringAsFixed(1)} · $reviewCount review',
                    style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink),
                  ),
                ] else
                  Text('Chưa có review', style: SenpaiText.labelM.copyWith(color: SenpaiColors.muted)),
                if (distanceText.isNotEmpty)
                  Text('·  $distanceText', style: SenpaiText.labelM.copyWith(color: SenpaiColors.muted)),
              ],
            ),
            if (scam)
              const SenpaiNote('Có cảnh báo lừa đảo', icon: Symbols.warning_rounded, tone: SenpaiTone.crit),
            if (!onSenpai)
              const SenpaiNote(
                'Địa điểm này có trên OpenStreetMap nhưng chưa có trên Senpai ơi. Địa điểm sẽ được thêm khi có '
                'người viết review, lưu, hoặc gắn vào bài viết.',
                icon: Symbols.info_rounded,
                tone: SenpaiTone.ai,
              ),
            _buttons(),
          ],
        ),
      ),
    );
  }

  /// "Xem chi tiết" + "Chỉ đường" cùng hàng; "Viết review đầu tiên" dài nên nằm trên "Chỉ đường".
  Widget _buttons() {
    const size = SenpaiButtonSize.medium;
    final directions = PlaceDirectionsButton(url: directionsUrl, size: size, expand: true);
    if (onWriteFirst != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          SenpaiButton(
            label: 'Viết review đầu tiên',
            icon: Symbols.rate_review_rounded,
            size: size,
            expand: true,
            onPressed: onWriteFirst,
          ),
          directions,
        ],
      );
    }
    return Row(
      spacing: 10,
      children: [
        if (onOpenDetail != null)
          Expanded(
            child: SenpaiButton(
              label: 'Xem chi tiết',
              icon: Symbols.info_rounded,
              size: size,
              expand: true,
              onPressed: onOpenDetail,
            ),
          ),
        Expanded(child: directions),
      ],
    );
  }
}

/// Badge nguồn của địa điểm (tone ai): "Nhóm Senpai ơi thêm" có dấu verified, "Ghim cộng đồng" có icon groups,
/// "OpenStreetMap" / "Google Maps" có icon public.
Widget placeSourceBadge(String source) {
  final icon = switch (source) {
    'TEAM' || 'MODERATOR' => Symbols.verified_rounded,
    'USER' => Symbols.groups_rounded,
    _ => Symbols.public_rounded,
  };
  return SenpaiBadge(PlaceDetail.sourceLabels[source] ?? source, tone: SenpaiTone.ai, icon: icon);
}
