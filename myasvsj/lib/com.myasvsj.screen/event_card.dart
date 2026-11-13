import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/event.dart';
import 'package:myasvsj/com.myasvsj.screen/event_cover.dart';
import 'package:myasvsj/com.myasvsj.screen/event_info_line.dart';
import 'package:myasvsj/com.myasvsj.screen/event_stars.dart';
import 'package:myasvsj/com.myasvsj.screen/event_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// `eventCard` của màn 19: thẻ trắng bo 20, ảnh bìa cao 130 có nhãn trạng thái ở góc, tên Title/M, ba dòng
/// ngày · nơi tổ chức · chi phí, rồi điểm review (sao 14 + Caption) và link "Viết review".
/// Link "Viết review" chỉ hiện khi sự kiện đã bắt đầu và có [onWriteReview].
class EventCard extends StatelessWidget {
  const EventCard({super.key, required this.event, this.onTap, this.onWriteReview});

  final Event event;
  final VoidCallback? onTap;
  final VoidCallback? onWriteReview;

  @override
  Widget build(BuildContext context) {
    final avg = event.avgRating;
    final rated = event.reviewCount > 0 && avg != null;
    return SenpaiCard(
      radius: 20,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EventCover(event: event, height: 130),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink),
                ),
                EventInfoLine(icon: Symbols.event_rounded, text: eventDateRange(event)),
                EventInfoLine(icon: Symbols.location_on_rounded, text: event.locationName),
                if (event.costNote.isNotEmpty) EventInfoLine(icon: Symbols.payments_rounded, text: event.costNote),
                // Hàng cuối: cao tối thiểu bằng link "Viết review" để thẻ có và không có link cao như nhau
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 30),
                  child: Row(
                    spacing: 6,
                    children: [
                      if (rated) EventStars(rating: avg, size: 14),
                      Expanded(
                        child: Text(
                          rated ? '${avg.toStringAsFixed(1)} · ${event.reviewCount} review' : 'Chưa có review',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
                        ),
                      ),
                      if (event.canReview && onWriteReview != null)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.fromLTRB(6, 4, 2, 4),
                            minimumSize: const Size(0, 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            iconSize: 18,
                          ),
                          onPressed: onWriteReview,
                          icon: const Icon(Symbols.rate_review_rounded),
                          label: const Text('Viết review'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
