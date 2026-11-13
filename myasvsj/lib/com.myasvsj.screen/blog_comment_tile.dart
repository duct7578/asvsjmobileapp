import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/blog_comment.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_author_line.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Thao tác trên một bình luận; màn chi tiết bài quyết định làm gì (khách thì đưa sang đăng nhập).
enum BlogCommentAction { like, reply, edit, delete, report, message }

/// Một bình luận và các câu trả lời lồng bên dưới (`comment(...)` của thiết kế): ảnh đại diện 32, bong bóng trắng
/// bo 16 viền line (tên Label/M, thời gian Caption, nội dung Body/S), dưới bong bóng là các thao tác chữ Label/S muted.
/// Câu trả lời thụt vào 42 (thẳng với bong bóng của bình luận cha), tối đa 3 bậc như web.
///
/// Bình luận của mình: Sửa, Xóa. Của người khác: Thích, Nhắn tin (khi đã đăng nhập), Báo cáo.
/// [canReply]: bài đã đăng nên nhận trả lời; [canEdit]: người xem được sửa bình luận của mình.
class BlogCommentTile extends StatelessWidget {
  const BlogCommentTile({
    super.key,
    required this.comment,
    required this.onAction,
    this.depth = 0,
    this.canReply = true,
    this.canEdit = true,
    this.isSignedIn = false,
  });

  static const int maxIndent = 3;

  /// Độ thụt của câu trả lời: ảnh đại diện 32 + khoảng cách 10.
  static const double _indent = 42;

  final BlogComment comment;
  final int depth;
  final bool canReply;
  final bool canEdit;
  final bool isSignedIn;
  final void Function(BlogComment comment, BlogCommentAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final c = comment;
    final replies = [
      for (final reply in c.replies)
        // Trả lời sâu hơn 3 bậc hiện thẳng hàng với bậc 3 để không bị đẩy ra ngoài màn hình hẹp
        Padding(
          padding: EdgeInsets.only(left: depth + 1 > maxIndent ? 0 : _indent),
          child: BlogCommentTile(
            comment: reply,
            onAction: onAction,
            depth: depth + 1,
            canReply: canReply,
            canEdit: canEdit,
            isSignedIn: isSignedIn,
          ),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [c.removed ? _removed() : _comment(context), ...replies],
    );
  }

  Widget _removed() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        BlogAuthorLine.avatarOf(null, 32),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: SenpaiColors.surface2, borderRadius: BorderRadius.circular(16)),
            child: Row(
              spacing: 6,
              children: [
                const Icon(Symbols.delete_rounded, size: 16, color: SenpaiColors.muted),
                Expanded(
                  child: Text('Bình luận đã bị xóa.', style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _comment(BuildContext context) {
    final c = comment;
    final tags = c.author?.tagNames ?? const <String>[];
    final time = c.createdAt == null ? null : [formatTimeAgo(c.createdAt!), if (c.edited) 'đã sửa'].join(' · ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        BlogAuthorLine.avatarOf(c.author, 32),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 6,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: SenpaiColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SenpaiColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          BlogAuthorLine.nameOf(c.author),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink),
                        ),
                        if (tags.isNotEmpty) SenpaiBadge(tags.first, tone: SenpaiTone.ai),
                        if (time != null) Text(time, style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
                      ],
                    ),
                    SelectableText(c.content, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.ink)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Wrap(spacing: 16, runSpacing: 2, children: _actions()),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _actions() {
    final c = comment;
    Widget action(String label, BlogCommentAction value, {bool on = false}) =>
        _ActionText(label: label, on: on, onTap: () => onAction(c, value));
    return [
      if (c.mine && c.likeCount > 0) _ActionText(label: '♥ ${c.likeCount}'),
      if (!c.mine) action(c.likeCount > 0 ? 'Thích · ${c.likeCount}' : 'Thích', BlogCommentAction.like, on: c.liked),
      if (canReply) action('Trả lời', BlogCommentAction.reply),
      if (c.mine && canEdit && canReply) action('Sửa', BlogCommentAction.edit),
      if (c.mine) action('Xóa', BlogCommentAction.delete),
      if (!c.mine && isSignedIn && c.author != null) action('Nhắn tin', BlogCommentAction.message),
      if (!c.mine) action('Báo cáo', BlogCommentAction.report),
    ];
  }
}

/// Thao tác chữ dưới bong bóng: Label/S muted (đã thích: brand-text), bấm được khi có [onTap].
class _ActionText extends StatelessWidget {
  const _ActionText({required this.label, this.onTap, this.on = false});

  final String label;
  final VoidCallback? onTap;
  final bool on;

  @override
  Widget build(BuildContext context) {
    final text = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(label, style: SenpaiText.labelS.copyWith(color: on ? SenpaiColors.brandText : SenpaiColors.muted)),
    );
    if (onTap == null) {
      return text;
    }
    return Semantics(
      button: true,
      selected: on,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(6), child: text),
    );
  }
}
