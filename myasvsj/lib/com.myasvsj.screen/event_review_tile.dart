import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/event_review.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/event_photo_viewer.dart';
import 'package:myasvsj/com.myasvsj.screen/event_stars.dart';
import 'package:myasvsj/com.myasvsj.screen/media_image.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// `EventReviewTile` của màn 20: thẻ trắng bo 18, ảnh đại diện 40 + tên Label/M + badge tag / cấp bậc / năm, sao 14
/// và thời gian, nội dung Body/M, ảnh vuông 88 bo 12, hàng thao tác Label/S muted.
///
/// - [canAct]: hiện "Thích · n" và "Báo cáo" (review đã đăng của người khác; khách cũng thấy, bấm thì đăng nhập).
/// - Review của chính mình ([EventReview.mine]) có "Sửa" (khi [canEdit]) và "Xóa", kèm hộp trạng thái khi
///   review chưa hiện với người khác.
class EventReviewTile extends StatelessWidget {
  const EventReviewTile({
    super.key,
    required this.review,
    this.canAct = false,
    this.canEdit = false,
    this.liking = false,
    this.onLike,
    this.onReport,
    this.onEdit,
    this.onDelete,
  });

  final EventReview review;
  final bool canAct;
  final bool canEdit;

  /// Đang chờ server trả lời lượt thích: khóa nút.
  final bool liking;
  final VoidCallback? onLike;
  final VoidCallback? onReport;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// Màu ảnh đại diện theo người viết (cùng người luôn cùng màu).
  static const List<SenpaiTone> _avatarTones = [SenpaiTone.ok, SenpaiTone.brand, SenpaiTone.ai, SenpaiTone.lantern];

  @override
  Widget build(BuildContext context) {
    final author = review.author;
    final name = author?.displayName ?? 'Người dùng';
    final note = review.mine ? review.statusNote : null;
    final images = review.images;
    final created = review.createdAt;
    final when = [
      if (created != null) formatTimeAgo(created),
      if (review.edited) 'đã sửa',
    ].join(' · ');
    return SenpaiCard(
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          if (note != null)
            SenpaiNote(
              note,
              icon: review.status == EventReview.processing ? Symbols.hourglass_top_rounded : Symbols.info_rounded,
              tone: review.status == EventReview.processing ? SenpaiTone.lantern : SenpaiTone.crit,
            ),
          Row(
            spacing: 10,
            children: [
              SenpaiAvatar(
                name: name,
                size: 40,
                imageUrl: author?.avatarUrl ?? '',
                tone: _avatarTones[(author?.id ?? 0) % _avatarTones.length],
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        for (final tag in author?.tagNames ?? const <String>[]) SenpaiBadge(tag, tone: SenpaiTone.ai),
                        if (author != null && author.rankName.isNotEmpty)
                          SenpaiBadge(author.rankName, tone: SenpaiTone.lantern, icon: Symbols.military_tech_rounded),
                        SenpaiBadge('Năm ${review.year}', tone: SenpaiTone.neutral),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            spacing: 8,
            children: [
              EventStars(rating: review.rating.toDouble(), size: 14),
              if (when.isNotEmpty)
                Flexible(
                  child: Text(
                    when,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
                  ),
                ),
            ],
          ),
          if (review.content.isNotEmpty)
            Text(review.content, style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink)),
          if (images.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < images.length; i++)
                  Semantics(
                    button: true,
                    label: 'Xem ảnh ${i + 1}',
                    child: GestureDetector(
                      onTap: () => showEventPhotos(
                        context,
                        photos: [for (final m in images) (url: m.url, caption: name)],
                        initialIndex: i,
                      ),
                      child: MediaImage(url: images[i].url, width: 88, height: 88, radius: 12),
                    ),
                  ),
              ],
            ),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (canAct) ...[
                _TileAction(
                  icon: review.liked ? Icons.thumb_up_rounded : Symbols.thumb_up_rounded,
                  label: 'Thích · ${review.likeCount}',
                  color: review.liked ? SenpaiColors.brandText : SenpaiColors.muted,
                  onTap: liking ? null : onLike,
                ),
                _TileAction(label: 'Báo cáo', onTap: onReport),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: IconStat(Symbols.thumb_up_rounded, '${review.likeCount}'),
                ),
              if (review.mine) ...[
                if (canEdit) _TileAction(icon: Symbols.edit_rounded, label: 'Sửa', onTap: onEdit),
                _TileAction(icon: Symbols.delete_rounded, label: 'Xóa', color: SenpaiColors.crit, onTap: onDelete),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Một thao tác nhỏ dưới review (`iconStat` / chữ Label/S muted của thiết kế), vùng bấm cao 32.
class _TileAction extends StatelessWidget {
  const _TileAction({required this.label, this.icon, this.color = SenpaiColors.muted, this.onTap});

  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              if (icon != null) Icon(icon, size: 18, color: color),
              Text(label, style: SenpaiText.labelS.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
