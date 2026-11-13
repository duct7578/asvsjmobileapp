import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/chat_message.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

/// Một tin nhắn trong cuộc trò chuyện (`bubble(mine, text, meta, quote)` của thiết kế, màn 31): tin của mình bên
/// phải nền brand chữ trắng, của người kia bên trái nền trắng viền line; bo 18, góc phía người gửi bo 6; chữ Body/M,
/// giờ + "đã sửa" + "Đã xem / Đã gửi" Caption bên dưới. Tin trả lời có khung trích dẫn, cảm xúc nằm trong viên thuốc
/// nhỏ ngay dưới bong bóng. Nhấn giữ để mở các thao tác (Sao chép, Sửa, Thu hồi, Báo cáo).
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.quoted,
    this.quotedName = '',
    this.delivery,
    this.onLongPress,
  });

  final ChatMessage message;

  /// Tin được trả lời (đã tải), nếu có.
  final ChatMessage? quoted;

  /// Tên người viết tin được trả lời ("Bạn" hoặc tên người kia).
  final String quotedName;

  /// "Đã xem" / "Đã gửi" dưới tin mới nhất của mình.
  final String? delivery;
  final VoidCallback? onLongPress;

  static const String recalledMine = 'Bạn đã thu hồi một tin nhắn';
  static const String recalledTheirs = 'Tin nhắn đã được thu hồi';

  /// Câu của tin mã hóa chưa đọc được khi controller không cho câu riêng ([ChatMessage.lockedText]).
  static const String encryptedText = 'Tin nhắn đã mã hóa';

  @override
  Widget build(BuildContext context) {
    final m = message;
    final mine = m.mine;
    final foreground = mine ? SenpaiColors.onBrand : SenpaiColors.ink;
    final metaColor = mine ? SenpaiColors.onBrand : SenpaiColors.muted;
    final hh = m.createdAt.hour.toString().padLeft(2, '0');
    final mm = m.createdAt.minute.toString().padLeft(2, '0');
    final meta = ['$hh:$mm', if (m.edited && !m.recalled) 'đã sửa', ?delivery].join(' · ');
    // Tin dài xuống dòng ở bề rộng chữ 240 trên màn 390 như thiết kế
    final maxWidth = (MediaQuery.sizeOf(context).width - 32) * 0.75;
    const big = Radius.circular(18);
    const small = Radius.circular(6);

    final bubble = GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? SenpaiColors.brand : SenpaiColors.surface,
          border: mine ? null : Border.all(color: SenpaiColors.line),
          borderRadius: BorderRadius.only(
            topLeft: big,
            topRight: big,
            bottomLeft: mine ? big : small,
            bottomRight: mine ? small : big,
          ),
        ),
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            if (m.replyToId != null && !m.recalled) _quote(),
            _body(m, foreground),
            if (m.decrypted)
              // Tin mã hóa đầu cuối đã giải mã: ổ khóa nhỏ trước giờ gửi
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 3,
                children: [
                  Icon(Symbols.lock_rounded, size: 12, color: metaColor, semanticLabel: 'Đã mã hóa đầu cuối'),
                  Text(meta, style: SenpaiText.caption.copyWith(color: metaColor)),
                ],
              )
            else
              Text(meta, style: SenpaiText.caption.copyWith(color: metaColor)),
          ],
        ),
      ),
    );

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 10,
          children: [
            bubble,
            if (m.reactions.isNotEmpty && !m.recalled)
              Padding(
                padding: EdgeInsets.only(left: mine ? 0 : 12, right: mine ? 12 : 0),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [for (final r in m.reactions) _ReactionPill(emoji: r.emoji, count: r.count, mine: r.mine)],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body(ChatMessage m, Color foreground) {
    final muted = SenpaiText.bodyM.copyWith(
      color: m.mine ? SenpaiColors.onBrand.withValues(alpha: 0.85) : SenpaiColors.muted,
      fontStyle: FontStyle.italic,
    );
    if (m.recalled) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Icon(Symbols.undo_rounded, size: 18, color: muted.color),
          Flexible(child: Text(m.mine ? recalledMine : recalledTheirs, style: muted)),
        ],
      );
    }
    if (m.isEncrypted && m.content == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Icon(Symbols.lock_rounded, size: 18, color: muted.color),
          Flexible(child: Text(m.lockedText ?? encryptedText, style: muted)),
        ],
      );
    }
    final text = m.content ?? '';
    if (text.isEmpty && m.hasFiles) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Icon(Symbols.attach_file_rounded, size: 18, color: muted.color),
          Flexible(child: Text('Tệp đính kèm (app chưa hiển thị được)', style: muted)),
        ],
      );
    }
    return Text(text, style: SenpaiText.bodyM.copyWith(color: foreground));
  }

  /// Khung trích dẫn: nền brand-strong (tin của mình) / surface-2, bo 10, tên Label/S và một dòng Caption.
  Widget _quote() {
    final mine = message.mine;
    final q = quoted;
    final text = q == null
        ? 'Tin nhắn cũ'
        : q.recalled
        ? recalledTheirs
        : (q.isEncrypted && q.content == null ? encryptedText : (q.content ?? ''));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: mine ? SenpaiColors.brandStrong : SenpaiColors.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (quotedName.isNotEmpty)
            Text(
              quotedName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SenpaiText.labelS.copyWith(color: mine ? SenpaiColors.onBrand : SenpaiColors.brandText),
            ),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SenpaiText.caption.copyWith(color: mine ? SenpaiColors.onBrand : SenpaiColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Viên thuốc cảm xúc dưới bong bóng: nền trắng viền line (của mình: viền brand), emoji + số Label/S.
class _ReactionPill extends StatelessWidget {
  const _ReactionPill({required this.emoji, required this.count, required this.mine});

  final String emoji;
  final int count;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: ShapeDecoration(
        color: SenpaiColors.surface,
        shape: StadiumBorder(side: BorderSide(color: mine ? SenpaiColors.brand : SenpaiColors.line)),
      ),
      child: Text('$emoji $count', style: SenpaiText.labelS.copyWith(color: SenpaiColors.ink)),
    );
  }
}
