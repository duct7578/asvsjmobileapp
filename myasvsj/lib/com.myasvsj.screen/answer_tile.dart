import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/answer.dart';
import 'package:myasvsj/com.myasvsj.model/question.dart';
import 'package:myasvsj/com.myasvsj.screen/question_author_row.dart';
import 'package:myasvsj/com.myasvsj.screen/question_badge.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Một câu trả lời ở màn chi tiết câu hỏi (màn 16), kèm các phản hồi lồng bên dưới.
///
/// - Câu trả lời gốc ([depth] 0) là thẻ trắng bo 18 lề 14 (`AnswerTile` của thiết kế); câu hay nhất có viền brand
///   dày 2 và nhãn "Câu trả lời hay nhất" (`BestAnswer`).
/// - Phản hồi là hộp nền surface-2 bo 14 lề [10,12] nằm trong thẻ của câu gốc (`reply`), mỗi bậc thụt thêm 12,
///   tối đa [maxIndent] bậc như web; sâu hơn vẫn hiện ở bậc cuối.
///
/// Chỉ vẽ và báo sự kiện bấm ra ngoài; màn hình QuestionDetailScreen quyết định (đăng nhập, hỏi xác nhận, gọi
/// Controller). Khách cũng thấy các nút; bấm vào thì màn hình đưa sang Đăng nhập.
class AnswerTile extends StatelessWidget {
  const AnswerTile({
    super.key,
    required this.answer,
    required this.question,
    this.depth = 0,
    this.signedIn = false,
    this.replyingTo,
    this.replyBox,
    this.editingId,
    this.editBox,
    this.onLike,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.onReport,
    this.onBest,
    this.onMessage,
    this.showReplies = true,
  });

  /// Thụt vào tối đa ngần này bậc; sâu hơn vẫn hiện ở bậc cuối.
  static const int maxIndent = 3;

  final Answer answer;

  /// Câu hỏi chứa câu trả lời: quyền của người xem (người hỏi, được tương tác) và trạng thái đăng.
  final Question question;
  final int depth;

  /// Người xem đã đăng nhập trên app (khách không thấy nút "Nhắn tin" ở từng câu trả lời, như web).
  final bool signedIn;

  /// Câu trả lời đang mở ô phản hồi, và ô đó.
  final int? replyingTo;
  final Widget? replyBox;

  /// Câu trả lời đang sửa tại chỗ, và ô sửa (thay cho nội dung).
  final int? editingId;
  final Widget? editBox;

  final ValueChanged<Answer>? onLike;
  final ValueChanged<Answer>? onReply;
  final ValueChanged<Answer>? onEdit;
  final ValueChanged<Answer>? onDelete;
  final ValueChanged<Answer>? onReport;
  final ValueChanged<Answer>? onBest;
  final ValueChanged<Answer>? onMessage;

  /// false: chỉ vẽ riêng câu này, không vẽ các phản hồi (câu gốc tự xếp các phản hồi thành danh sách thụt lề).
  final bool showReplies;

  @override
  Widget build(BuildContext context) {
    final a = answer;
    final children = <Widget>[
      if (a.removed)
        Row(
          spacing: 6,
          children: [
            const Icon(Symbols.delete_rounded, size: 16, color: SenpaiColors.muted),
            Expanded(child: Text('Bình luận đã bị xóa.', style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted))),
          ],
        )
      else
        ..._content(),
      if (replyingTo == a.id && replyBox != null) replyBox!,
    ];

    if (depth > 0) {
      // Phản hồi: hộp surface-2, thụt theo bậc (bậc 1 sát lề thẻ của câu gốc)
      final indent = (depth.clamp(1, maxIndent) - 1) * 12.0;
      return Container(
        margin: EdgeInsets.only(left: indent),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: SenpaiColors.surface2, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 4, children: children),
      );
    }

    // Câu gốc: thẻ chứa nội dung rồi tới các phản hồi (xếp phẳng theo thứ tự, thụt theo bậc)
    final replies = showReplies ? _flatten(a.replies, 1) : const <({Answer answer, int depth})>[];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SenpaiColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: a.best ? SenpaiColors.brand : SenpaiColors.line, width: a.best ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          ...children,
          for (final r in replies)
            AnswerTile(
              key: ValueKey('answer-${r.answer.id}'),
              answer: r.answer,
              question: question,
              depth: r.depth,
              signedIn: signedIn,
              replyingTo: replyingTo,
              replyBox: replyBox,
              editingId: editingId,
              editBox: editBox,
              onLike: onLike,
              onReply: onReply,
              onEdit: onEdit,
              onDelete: onDelete,
              onReport: onReport,
              onBest: onBest,
              onMessage: onMessage,
              showReplies: false,
            ),
        ],
      ),
    );
  }

  /// Các phản hồi theo thứ tự đọc (cha trước con), kèm bậc.
  static List<({Answer answer, int depth})> _flatten(List<Answer> nodes, int depth) => [
        for (final n in nodes) ...[
          (answer: n, depth: depth),
          ..._flatten(n.replies, depth + 1),
        ],
      ];

  List<Widget> _content() {
    final a = answer;
    final reply = depth > 0;
    final published = question.isPublished;
    // Đã đăng nhập nhưng tài khoản không tương tác được (staff, câu hỏi chưa đăng): nút bị khóa
    final locked = signedIn && !question.canInteract;
    final editable = a.isMine && question.canInteract && published;
    final canChooseBest = question.isMine && question.canInteract && depth == 0 && !a.isMine && !a.best;
    final actions = <Widget>[
      // Không thích được câu của chính mình, chỉ thấy số lượt thích
      if (!a.isMine)
        _action(
          icon: a.liked ? Icons.thumb_up_rounded : Symbols.thumb_up_rounded,
          label: a.likeCount > 0 ? 'Thích · ${a.likeCount}' : 'Thích',
          onPressed: locked || onLike == null ? null : () => onLike!(a),
          color: a.liked ? SenpaiColors.brandText : null,
        )
      else if (a.likeCount > 0)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: IconStat(Symbols.thumb_up_rounded, '${a.likeCount}'),
        ),
      if (published) _action(label: 'Trả lời', onPressed: locked || onReply == null ? null : () => onReply!(a)),
      if (a.isMine) ...[
        if (editable) _action(label: 'Sửa', onPressed: onEdit == null ? null : () => onEdit!(a)),
        _action(label: 'Xóa', onPressed: onDelete == null ? null : () => onDelete!(a)),
      ] else ...[
        if (signedIn && a.author != null)
          _action(label: 'Nhắn tin', onPressed: locked || onMessage == null ? null : () => onMessage!(a)),
        _action(label: 'Báo cáo', onPressed: locked || onReport == null ? null : () => onReport!(a)),
      ],
      if (canChooseBest)
        _action(
          icon: Symbols.verified_rounded,
          label: 'Chọn là câu trả lời hay nhất',
          onPressed: onBest == null ? null : () => onBest!(a),
          color: SenpaiColors.brandText,
        ),
    ];
    return [
      if (a.best) const QuestionBadge(label: 'Câu trả lời hay nhất', icon: Symbols.verified_rounded, tone: SenpaiTone.ok),
      QuestionAuthorRow(
        author: a.author,
        createdAt: a.createdAt,
        edited: a.edited,
        compact: reply,
        showAvatar: !reply,
        showRank: !reply,
      ),
      if (editingId == a.id && editBox != null)
        editBox!
      else ...[
        SelectableText(
          a.content,
          style: (reply ? SenpaiText.bodyS : SenpaiText.bodyM).copyWith(color: SenpaiColors.ink),
        ),
        // Nút đầu tiên thẳng lề với nội dung (bù lề trong của nút)
        Transform.translate(
          offset: const Offset(-6, 0),
          child: Wrap(spacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: actions),
        ),
      ],
    ];
  }

  /// Nút chữ nhỏ Label/S muted của hàng thao tác (`Thích · 21  Trả lời  Nhắn tin  Báo cáo` trong thiết kế).
  Widget _action({IconData? icon, required String label, VoidCallback? onPressed, Color? color}) {
    final style = TextButton.styleFrom(
      foregroundColor: color ?? SenpaiColors.muted,
      textStyle: SenpaiText.labelS,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      iconSize: 18,
    );
    final text = Text(label);
    if (icon == null) {
      return TextButton(style: style, onPressed: onPressed, child: text);
    }
    return TextButton.icon(style: style, onPressed: onPressed, icon: Icon(icon), label: text);
  }
}
