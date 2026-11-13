import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/app_notification.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Một dòng của màn hình "Thông báo" (NotificationTile của thiết kế 05): ô icon tròn 40 theo loại, nội dung,
/// thời gian, chấm brand 10 khi chưa đọc. Chưa đọc: thẻ trắng bo 16 viền line, nội dung Label/M, thời gian
/// brand-text; đã đọc: không nền, nội dung Body/S, thời gian muted.
class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification, this.onTap});

  final AppNotification notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final unread = !n.read;
    final (icon, tone) = _look(n.type);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: unread ? const BorderSide(color: SenpaiColors.line) : BorderSide.none,
    );
    return Material(
      color: unread ? SenpaiColors.surface : Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              IconTile(icon, tone: tone, radius: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      n.content,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: (unread ? SenpaiText.labelM : SenpaiText.bodyS).copyWith(color: SenpaiColors.ink),
                    ),
                    if (n.createdAt != null)
                      Text(
                        formatTimeAgo(n.createdAt!),
                        style: SenpaiText.caption.copyWith(color: unread ? SenpaiColors.brandText : SenpaiColors.muted),
                      ),
                  ],
                ),
              ),
              if (unread)
                Semantics(
                  label: 'Chưa đọc',
                  child: const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.circle, size: 10, color: SenpaiColors.brand),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Biểu tượng và tone của từng loại thông báo (như KINDS của trang web; màu theo thiết kế).
  static (IconData, SenpaiTone) _look(String type) => switch (type) {
    'CONTENT_PUBLISHED' => (Symbols.check_circle_rounded, SenpaiTone.ok),
    'CONTENT_REJECTED' => (Symbols.block_rounded, SenpaiTone.crit),
    'NEW_COMMENT' => (Symbols.chat_bubble_rounded, SenpaiTone.brand),
    'BEST_ANSWER' => (Symbols.workspace_premium_rounded, SenpaiTone.lantern),
    _ when type.startsWith('TAG_') => (Symbols.sell_rounded, SenpaiTone.ai),
    _ when type.startsWith('PIN_') || type.startsWith('PLACE_') => (Symbols.place_rounded, SenpaiTone.brand),
    _ => (Symbols.notifications_rounded, SenpaiTone.neutral),
  };
}
