import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/chat_message.dart';
import 'package:myasvsj/com.myasvsj.model/conversation_item.dart';
import 'package:myasvsj/com.myasvsj.screen/chat_avatar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Một dòng của danh sách "Tin nhắn" / "Lời mời" (ConversationTile của thiết kế, màn 30): ảnh 52, tên, nhãn
/// "Đã chặn", thời gian bên phải, tin cuối một dòng (icon khoá / ghim / thu hồi khi cần) và số tin chưa đọc.
/// Dòng có tin chưa đọc nằm trên nền trắng bo 16, tên Title/S, thời gian màu brand-text.
class ConversationTile extends StatelessWidget {
  const ConversationTile({super.key, required this.item, this.shownLast, this.onTap});

  final ConversationItem item;

  /// Tin cuối để hiện thay cho `item.lastMessage` (bản đã giải mã của tin mã hóa, xem ChatController.previewOf).
  final ChatMessage? shownLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final last = item.lastMessage;
    final unread = item.unread > 0;
    final icon = previewIcon(item, shownLast);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    return Material(
      color: unread ? SenpaiColors.surface : Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            spacing: 12,
            children: [
              ChatAvatar(
                name: item.peer.displayName,
                url: item.peer.avatarUrl,
                radius: 26,
                tone: ChatAvatar.toneFor(item.peer.id, active: item.peer.active, blocked: item.blockedByMe),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            spacing: 6,
                            children: [
                              Flexible(
                                child: Text(
                                  item.peer.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: (unread ? SenpaiText.titleS : SenpaiText.labelM).copyWith(
                                    color: SenpaiColors.ink,
                                  ),
                                ),
                              ),
                              if (item.blockedByMe) const SenpaiBadge('Đã chặn', tone: SenpaiTone.crit),
                            ],
                          ),
                        ),
                        if (last != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            shortTime(last.createdAt),
                            style: SenpaiText.caption.copyWith(
                              color: unread ? SenpaiColors.brandText : SenpaiColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: Row(
                            spacing: 4,
                            children: [
                              if (icon != null) Icon(icon, size: 16, color: SenpaiColors.muted),
                              Expanded(
                                child: Text(
                                  preview(item, shownLast),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: SenpaiText.bodyS.copyWith(
                                    color: unread ? SenpaiColors.ink : SenpaiColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (unread) SenpaiBadge(item.unread > 99 ? '99+' : '${item.unread}', tone: SenpaiTone.solid),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tin cuối trên một dòng, như trang web: "Bạn: …", thu hồi, tin mã hóa, tệp đính kèm (icon đi kèm ở
  /// [previewIcon]).
  static String preview(ConversationItem item, [ChatMessage? shown]) {
    final last = shown ?? item.lastMessage;
    if (last == null) {
      return '';
    }
    if (last.recalled) {
      return last.mine ? 'Bạn đã thu hồi một tin nhắn' : 'Tin nhắn đã được thu hồi';
    }
    final who = last.mine ? 'Bạn: ' : '';
    if (last.isEncrypted && last.content == null) {
      return '${who}Tin nhắn đã mã hóa';
    }
    final text = last.content ?? '';
    return '$who${text.isEmpty && last.hasFiles ? 'Tệp đính kèm' : text}';
  }

  /// Icon 16 trước tin cuối: undo (thu hồi), lock (mã hóa), attach_file (chỉ có tệp); null với tin thường.
  static IconData? previewIcon(ConversationItem item, [ChatMessage? shown]) {
    final last = shown ?? item.lastMessage;
    if (last == null) {
      return null;
    }
    if (last.recalled) {
      return Symbols.undo_rounded;
    }
    if (last.isEncrypted) {
      return Symbols.lock_rounded;
    }
    return (last.content ?? '').isEmpty && last.hasFiles ? Symbols.attach_file_rounded : null;
  }

  /// Thời gian gọn của danh sách như thiết kế: "vừa xong", "2 phút", "1 giờ", "hôm qua", thứ trong tuần ("T2",
  /// "CN") khi trong 7 ngày, còn lại ngày/tháng (thêm năm nếu khác năm nay).
  static String shortTime(DateTime date, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final local = date.toLocal();
    final diff = current.difference(local);
    if (diff.inMinutes < 1) {
      return 'vừa xong';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes} phút';
    }
    final today = DateUtils.dateOnly(current);
    final day = DateUtils.dateOnly(local);
    final days = today.difference(day).inDays;
    if (days == 0) {
      return '${diff.inHours} giờ';
    }
    if (days == 1) {
      return 'hôm qua';
    }
    if (days < 7) {
      return local.weekday == DateTime.sunday ? 'CN' : 'T${local.weekday + 1}';
    }
    return local.year == current.year ? '${local.day}/${local.month}' : '${local.day}/${local.month}/${local.year}';
  }
}
