import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.model/place_review.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/media_image.dart';
import 'package:myasvsj/com.myasvsj.screen/place_rating_stars.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Một review trong chi tiết địa điểm (`PlaceReviewCard` của màn 09): thẻ bo 18, ảnh đại diện 40 + tên Label/M +
/// tag · hạng Caption, nút "⋮"; hàng sao + badge (Còn mới, Hữu ích, Hơn 1 năm…); nội dung Body/M; ảnh 88 bo 12;
/// hàng cuối: thời gian và Thích / Báo cáo (review của người khác) hoặc Sửa / Xóa (review của mình).
class PlaceReviewCard extends StatelessWidget {
  const PlaceReviewCard({
    super.key,
    required this.review,
    this.canAct = true,
    this.onLike,
    this.onReport,
    this.onEdit,
    this.onDelete,
    this.now,
  });

  final PlaceReview review;

  /// false khi người xem là tài khoản staff (chỉ xem): khóa Thích / Báo cáo. Khách vẫn bấm được (sang Đăng nhập).
  final bool canAct;
  final VoidCallback? onLike;
  final VoidCallback? onReport;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Giờ hiện tại để tính "Còn mới" (test truyền vào); mặc định là giờ máy.
  final DateTime? now;

  static const _tones = [SenpaiTone.brand, SenpaiTone.ai, SenpaiTone.lantern, SenpaiTone.ok];

  @override
  Widget build(BuildContext context) {
    final author = review.author;
    final at = now ?? DateTime.now();
    final badges = [
      ...author.tagNames,
      if (author.rankName.isNotEmpty) author.rankName,
      if (review.authorRoleLabel.isNotEmpty) review.authorRoleLabel,
    ];
    final actOnOthers = canAct && review.isPublished;
    final time = [if (review.createdAt != null) formatTimeAgo(review.createdAt!), if (review.edited) 'đã sửa'].join(' · ');
    return SenpaiCard(
      radius: 18,
      color: review.mine ? SenpaiColors.brandSoft.withValues(alpha: 0.4) : SenpaiColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            spacing: 10,
            children: [
              SenpaiAvatar(name: author.displayName, size: 40, tone: _tones[author.id % _tones.length]),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 1,
                  children: [
                    Text(
                      author.displayName,
                      style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (badges.isNotEmpty)
                      Text(
                        badges.join(' · '),
                        style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              _menu(actOnOthers),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PlaceRatingStars(rating: review.rating.toDouble()),
              if (review.isFresh(at)) const SenpaiBadge('Còn mới', tone: SenpaiTone.ok),
              if (review.isOld(at)) const SenpaiBadge('Hơn 1 năm, cần xác minh lại', tone: SenpaiTone.warn),
              if (review.helpful) const SenpaiBadge('Hữu ích', tone: SenpaiTone.lantern, icon: Symbols.verified_rounded),
              if (review.isProcessing)
                const SenpaiBadge('Đang xử lý ảnh', tone: SenpaiTone.neutral, icon: Symbols.hourglass_top_rounded),
            ],
          ),
          Text(review.content, style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink)),
          if (review.images.isNotEmpty)
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => showPlacePhoto(context, review.images[i]),
                  child: MediaImage(url: review.images[i].url, width: 88, height: 88, radius: 12),
                ),
              ),
            ),
          Row(
            spacing: 4,
            children: [
              Expanded(
                child: Text(
                  time,
                  style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (review.mine) ...[
                _action(icon: Symbols.edit_rounded, label: 'Sửa', onPressed: onEdit),
                _action(icon: Symbols.delete_rounded, label: 'Xóa', onPressed: onDelete, color: SenpaiColors.crit),
              ] else ...[
                _action(
                  icon: review.liked ? Icons.thumb_up_rounded : Symbols.thumb_up_rounded,
                  label: review.likeCount > 0 ? 'Thích (${review.likeCount})' : 'Thích',
                  onPressed: actOnOthers ? onLike : null,
                  color: review.liked ? SenpaiColors.brandText : SenpaiColors.muted,
                ),
                _action(icon: Symbols.flag_rounded, label: 'Báo cáo', onPressed: actOnOthers ? onReport : null),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// `iconStat` bấm được: icon 18 + Label/S (muted mặc định).
  static Widget _action({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color color = SenpaiColors.muted,
  }) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        textStyle: SenpaiText.labelS,
        iconSize: 18,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      icon: Icon(icon),
      label: Text(label),
    );
  }

  /// Nút "⋮": cùng các thao tác của hàng cuối (Sửa / Xóa, hoặc Thích / Báo cáo).
  Widget _menu(bool actOnOthers) {
    final enabled = review.mine || actOnOthers;
    return SizedBox.square(
      dimension: 32,
      child: PopupMenuButton<VoidCallback?>(
        tooltip: 'Thêm thao tác',
        enabled: enabled,
        padding: EdgeInsets.zero,
        iconSize: 20,
        icon: const Icon(Symbols.more_vert_rounded, color: SenpaiColors.muted),
        onSelected: (action) => action?.call(),
        itemBuilder: (_) => [
          if (review.mine) ...[
            PopupMenuItem(value: onEdit, child: const Text('Sửa review')),
            PopupMenuItem(value: onDelete, child: const Text('Xóa review')),
          ] else ...[
            PopupMenuItem(value: onLike, child: Text(review.liked ? 'Bỏ thích' : 'Thích')),
            PopupMenuItem(value: onReport, child: const Text('Báo cáo review')),
          ],
        ],
      ),
    );
  }
}

/// Ảnh lớn (phóng to được) khi bấm một ảnh của review / địa điểm.
void showPlacePhoto(BuildContext context, MediaItem image) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          InteractiveViewer(child: MediaImage(url: image.url, fit: BoxFit.contain, radius: 0)),
          Positioned(
            right: 8,
            top: 8,
            child: IconButton.filledTonal(
              tooltip: 'Đóng',
              icon: const Icon(Symbols.close_rounded),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ),
        ],
      ),
    ),
  );
}
