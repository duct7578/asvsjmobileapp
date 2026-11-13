import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/home_guide_progress.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/home_format.dart';
import 'package:myasvsj/com.myasvsj.screen/my_guides_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/place_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Thẻ "Việc tiếp theo" (NextCard của thiết kế 02): thẻ trắng bo 20 p16; đầu thẻ ô icon menu_book tone lantern,
/// "Việc tiếp theo" và "đã xong/tổng · giai đoạn" (bấm mở "Cẩm nang của tôi"); thanh tiến độ; rồi cẩm nang nên mở
/// tiếp (server chọn) kèm phần còn lại, hạn chót, địa điểm, "Mở cẩm nang này" và "Cả giai đoạn".
class HomeNextCard extends StatelessWidget {
  const HomeNextCard({super.key, required this.guide});

  final HomeGuideProgress guide;

  @override
  Widget build(BuildContext context) {
    final next = guide.next;
    final whole = SenpaiButton(
      label: 'Cả giai đoạn',
      kind: SenpaiButtonKind.secondary,
      size: SenpaiButtonSize.medium,
      onPressed: () => pushScreen<void>(context, GuideListScreen(stage: guide.stageCode)),
    );
    final body = SenpaiText.bodyS.copyWith(color: SenpaiColors.muted);
    return SenpaiCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          InkWell(
            onTap: () => pushScreen<void>(context, const MyGuidesScreen()),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              spacing: 10,
              children: [
                const IconTile(Symbols.menu_book_rounded, tone: SenpaiTone.lantern),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Việc tiếp theo', style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink)),
                      Text(
                        '${guide.done}/${guide.total} · ${guide.stageTitle}',
                        style: SenpaiText.labelS.copyWith(color: SenpaiColors.brandText),
                      ),
                    ],
                  ),
                ),
                const Icon(Symbols.chevron_right_rounded, size: 22, color: SenpaiColors.muted),
              ],
            ),
          ),
          Semantics(
            label: 'Cẩm nang đã xong',
            value: '${(guide.progress * 100).round()}%',
            child: SenpaiProgressBar(value: guide.progress),
          ),
          if (next != null) ...[
            InkWell(
              onTap: () => pushScreen<void>(context, GuideDetailScreen(guideId: next.guideId, openChecklist: true)),
              borderRadius: BorderRadius.circular(8),
              child: Text(next.title, style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
            ),
            Text(
              next.checklist
                  ? '${next.tasksDone}/${next.tasksTotal} việc'
                        '${(next.nextTask ?? '').isNotEmpty ? ' · Tiếp theo: ${next.nextTask}' : ''}'
                  : 'Đọc xong thì bấm “Đánh dấu đã xong” trong cẩm nang.',
              style: body,
            ),
            if ((next.dueNote ?? '').isNotEmpty)
              Row(
                spacing: 6,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Symbols.schedule_rounded, size: 16, color: SenpaiColors.crit),
                  Expanded(child: Text(next.dueNote!, style: SenpaiText.labelS.copyWith(color: SenpaiColors.crit))),
                ],
              ),
            if (next.placeId != null && (next.placeName ?? '').isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: ActionChip(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  avatar: const Icon(Symbols.location_on_rounded),
                  label: Text(next.placeName!, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onPressed: () => pushScreen<void>(context, PlaceDetailScreen(placeId: next.placeId!)),
                ),
              ),
            LayoutBuilder(
              builder: (context, box) {
                final open = SenpaiButton(
                  label: 'Mở cẩm nang này',
                  icon: Symbols.menu_book_rounded,
                  size: SenpaiButtonSize.medium,
                  expand: true,
                  onPressed: () =>
                      pushScreen<void>(context, GuideDetailScreen(guideId: next.guideId, openChecklist: true)),
                );
                // Màn hẹp: hai nút xếp dọc để chữ không bị cắt
                if (box.maxWidth < 310) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: [open, whole],
                  );
                }
                return Row(spacing: 10, children: [Expanded(child: open), whole]);
              },
            ),
          ] else if (guide.total > 0) ...[
            Text('Bạn đã xong giai đoạn này.', style: body),
            Align(alignment: Alignment.centerLeft, child: whole),
          ] else
            Text('Cẩm nang cho giai đoạn này đang được biên soạn.', style: body),
        ],
      ),
    );
  }
}
