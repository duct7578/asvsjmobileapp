import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/event.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Các cảnh minh hoạ hợp với lễ hội, dùng khi sự kiện không có ảnh bìa.
const List<CoverScene> _eventScenes = [
  CoverScene.festival,
  CoverScene.torii,
  CoverScene.sakura,
  CoverScene.fuji,
  CoverScene.park,
  CoverScene.city,
];

/// Cảnh minh hoạ cố định của một sự kiện (cùng id luôn ra cùng cảnh).
CoverScene eventCoverScene(Event event) => _eventScenes[CoverScene.forSeed(event.id).index % _eventScenes.length];

/// Icon của trạng thái: celebration (đang diễn ra), schedule (sắp tới), history (đã qua).
IconData eventStateIcon(Event event) => event.isNow
    ? Symbols.celebration_rounded
    : event.isPast
        ? Symbols.history_rounded
        : Symbols.schedule_rounded;

/// Tone của nhãn trạng thái: ok (đang diễn ra), brand (sắp tới), neutral (đã qua).
SenpaiTone eventStateTone(Event event) => event.isNow
    ? SenpaiTone.ok
    : event.isPast
        ? SenpaiTone.neutral
        : SenpaiTone.brand;

/// Ảnh bìa của sự kiện (`cover()` của thiết kế): ảnh thật khi Moderator có tải, không thì cảnh minh hoạ.
/// [showState] thêm `stateChip` ở góc trên trái: viên thuốc trắng có bóng, icon 16 + Label/S theo trạng thái
/// ("Đang diễn ra", "Còn 12 ngày", "Đã qua").
class EventCover extends StatelessWidget {
  const EventCover({super.key, required this.event, this.height = 140, this.radius = 0, this.showState = true});

  final Event event;
  final double height;
  final double radius;
  final bool showState;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CoverArt(
            scene: eventCoverScene(event),
            imageUrl: event.coverUrl ?? '',
            width: double.infinity,
            height: height,
            radius: radius,
          ),
          if (showState)
            Positioned(
              left: 12,
              top: 12,
              right: 12,
              child: Align(alignment: Alignment.topLeft, child: _StateChip(event: event)),
            ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final color = event.isNow
        ? SenpaiColors.ok
        : event.isPast
            ? SenpaiColors.muted
            : SenpaiColors.brandText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: const ShapeDecoration(
        color: SenpaiColors.surface,
        shape: StadiumBorder(),
        shadows: SenpaiColors.shadowCard,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(eventStateIcon(event), size: 16, color: color),
          Flexible(
            child: Text(
              event.stateLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SenpaiText.labelS.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
