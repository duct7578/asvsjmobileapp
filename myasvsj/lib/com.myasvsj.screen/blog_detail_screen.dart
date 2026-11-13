import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/blog_controller.dart';
import 'package:myasvsj/com.myasvsj.model/author.dart';
import 'package:myasvsj/com.myasvsj.model/blog.dart';
import 'package:myasvsj/com.myasvsj.model/blog_comment.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_author_line.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_badge.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_comment_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_comment_tile.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_media_grid.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_place_list.dart';
import 'package:myasvsj/com.myasvsj.screen/chat_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/report_dialog.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/sign_in_gate.dart';

/// Màn hình chi tiết bài viết (màn 13 của thiết kế): ảnh bìa, nhãn và chủ đề, tiêu đề Display/L, tác giả, nội dung,
/// ảnh, địa điểm liên quan, thanh Thích / Lưu / Báo cáo, cây bình luận và ô bình luận dính đáy.
///
/// Khách đọc được; bấm thao tác thì được đưa sang đăng nhập. Tác giả thấy thêm Sửa và Xóa trên thanh tiêu đề.
class BlogDetailScreen extends StatefulWidget {
  const BlogDetailScreen({super.key, required this.blogId});

  final int blogId;

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  static const _statusNotes = {
    'PROCESSING': 'Ảnh của bài đang được quét. Trong lúc này chỉ bạn thấy bài.',
    'HIDDEN': 'Bài đang tạm ẩn vì có nhiều báo cáo, chờ Moderator xem xét.',
    'REJECTED': 'Bài chưa được đăng vì vi phạm Quy tắc cộng đồng. Bạn có thể sửa rồi gửi lại.',
  };

  final _comment = TextEditingController();
  final _commentFocus = FocusNode();

  /// Bình luận đang được trả lời; null khi viết bình luận mới.
  BlogComment? _replyTo;

  /// Người đang đăng nhập lần vẽ trước: đổi (vừa đăng nhập, đăng xuất) thì tải lại cờ thích, lưu, tác giả.
  int? _userId;

  int get _id => widget.blogId;

  @override
  void initState() {
    super.initState();
    _userId = context.read<AuthController>().currentUser?.id;
    // Gọi sau khung hình đầu: notifyListeners() không được chạy giữa lúc đang dựng giao diện
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final blogs = context.read<BlogController>()..clearCommentError();
      blogs.loadBlog(_id);
    });
  }

  @override
  void dispose() {
    _comment.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blogs = context.watch<BlogController>();
    final userId = context.select<AuthController, int?>((auth) => auth.currentUser?.id);
    if (userId != _userId) {
      _userId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<BlogController>().loadBlog(_id, quiet: true);
        }
      });
    }
    final blog = blogs.blogById(_id);
    return Scaffold(
      appBar: SenpaiAppBar(
        title: 'Bài viết',
        actions: [
          if (blog != null && blog.canEdit)
            IconButton(tooltip: 'Sửa bài', icon: const Icon(Symbols.edit_rounded), onPressed: () => _edit(blog)),
          if (blog != null && blog.isMine)
            IconButton(
              tooltip: 'Xóa bài',
              style: IconButton.styleFrom(foregroundColor: SenpaiColors.crit),
              icon: const Icon(Symbols.delete_rounded),
              onPressed: () => _delete(blog),
            ),
        ],
      ),
      body: _body(blogs, blog),
    );
  }

  Widget _body(BlogController blogs, Blog? blog) {
    if (blog == null) {
      final error = blogs.blogError(_id);
      if (error == null) {
        return const LoadingView();
      }
      return ErrorView(message: error, onRetry: () => blogs.loadBlog(_id));
    }
    final children = [..._post(blog), ..._comments(blog)];
    // Ô bình luận nằm dưới danh sách (không dùng bottomNavigationBar) để bàn phím mở thì ô được đẩy lên theo
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => blogs.loadBlog(_id, quiet: true),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // Các khối cách nhau 16 (body gap của thiết kế)
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  children[i],
                ],
              ],
            ),
          ),
        ),
        ?_composer(blogs, blog),
      ],
    );
  }

  // ---------------------------------------------------------------- bài

  List<Widget> _post(Blog blog) {
    final note = _statusNotes[blog.status];
    final author = blog.author;
    final time = [if (blog.createdAt != null) formatTimeAgo(blog.createdAt!), if (blog.edited) 'đã sửa'].join(' · ');
    final canMessage = author != null && !blog.isMine && author.id != _userId;
    final images = BlogMediaGrid.imagesOf(blog.media);
    return [
      if (note != null)
        SenpaiNote(
          note,
          icon: blog.isProcessing ? Symbols.hourglass_top_rounded : Symbols.block_rounded,
          tone: blog.isProcessing ? SenpaiTone.warn : SenpaiTone.crit,
        ),
      BlogHeroImage(media: blog.media, seed: blog.id),
      if (blog.pinned || blog.isProcessing || blog.topics.isNotEmpty)
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (blog.pinned) const BlogBadge(icon: Symbols.push_pin_rounded, label: 'Đã ghim'),
            if (blog.isProcessing)
              const BlogBadge(icon: Symbols.hourglass_top_rounded, label: 'Đang quét ảnh', warning: true),
            for (final topic in blog.topics) TopicChip(topic.name),
          ],
        ),
      Text(blog.title, style: SenpaiText.displayL.copyWith(color: SenpaiColors.ink)),
      BlogAuthorLine(
        author: author,
        showRank: true,
        subtitle: time,
        trailing: canMessage
            ? SenpaiButton(
                label: 'Nhắn tin',
                kind: SenpaiButtonKind.soft,
                size: SenpaiButtonSize.small,
                icon: Symbols.chat_rounded,
                onPressed: () => _openChat(author),
              )
            : null,
      ),
      SelectableText(blog.content, style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink)),
      // Ảnh đầu đã là ảnh bìa; lưới hiện các ảnh còn lại và ghi chú video
      if (images.length > 1 || images.length < blog.media.length) BlogMediaGrid(media: blog.media, skip: 1),
      if (blog.places.isNotEmpty) BlogPlaceList(places: blog.places),
      _actionBar(blog),
    ];
  }

  /// `actionBar([...])` của thiết kế: hộp trắng bo 16 viền line, các nút chia đều (Thích, Lưu, Báo cáo).
  Widget _actionBar(Blog blog) {
    // Đã đăng nhập nhưng không thao tác được (bài chưa đăng): nút mờ. Khách vẫn bấm được để sang đăng nhập.
    final blocked = _userId != null && !blog.canInteract;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: SenpaiColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SenpaiColors.line),
      ),
      child: Row(
        spacing: 2,
        children: [
          Expanded(
            child: blog.isMine
                ? Center(
                    child: Text(
                      '♥ ${blog.likeCount} lượt thích',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink),
                    ),
                  )
                : _ActionButton(
                    icon: blog.isLiked ? Icons.favorite_rounded : Symbols.favorite_rounded,
                    label: 'Thích · ${blog.likeCount}',
                    on: blog.isLiked,
                    onPressed: blocked ? null : () => _like(blog),
                  ),
          ),
          Expanded(
            child: _ActionButton(
              icon: blog.isSaved ? Icons.bookmark_rounded : Symbols.bookmark_rounded,
              label: blog.isSaved ? 'Đã lưu' : 'Lưu',
              on: blog.isSaved,
              onPressed: blocked ? null : () => _save(blog),
            ),
          ),
          if (!blog.isMine && blog.isPublished)
            Expanded(
              child: _ActionButton(
                icon: Symbols.flag_rounded,
                label: 'Báo cáo',
                onPressed: blocked ? null : () => _reportBlog(blog),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- bình luận

  List<Widget> _comments(Blog blog) {
    final note = SenpaiText.bodyS.copyWith(color: SenpaiColors.muted);
    return [
      SectionHead('Bình luận (${blog.commentCount})'),
      if (!blog.isPublished) Text('Bài chưa được đăng nên chưa nhận bình luận.', style: note),
      if (blog.comments.isEmpty && blog.isPublished) Text('Chưa có bình luận nào.', style: note),
      for (final comment in blog.comments)
        BlogCommentTile(
          comment: comment,
          canReply: blog.isPublished,
          canEdit: blog.canInteract,
          isSignedIn: _userId != null,
          onAction: (c, action) => _onCommentAction(blog, c, action),
        ),
    ];
  }

  /// Ô bình luận dưới cùng: khách thấy nút Đăng nhập; tài khoản chỉ xem được thì thấy ghi chú. Bài chưa đăng thì
  /// không có thanh dưới.
  Widget? _composer(BlogController blogs, Blog blog) {
    if (!blog.isPublished) {
      return null;
    }
    if (_userId == null || !blog.canInteract) {
      final guest = _userId == null;
      return BlogBottomPanel(
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: Text(
                guest
                    ? 'Đăng nhập để bình luận và thích bài viết.'
                    : 'Tài khoản của bạn chỉ xem được, không bình luận được.',
                style: SenpaiText.bodyS.copyWith(color: SenpaiColors.ink),
              ),
            ),
            if (guest)
              SenpaiButton(
                label: 'Đăng nhập',
                size: SenpaiButtonSize.medium,
                icon: Symbols.login_rounded,
                onPressed: () => requireSignIn(context),
              ),
          ],
        ),
      );
    }
    return BlogCommentBar(
      controller: _comment,
      focusNode: _commentFocus,
      replyName: _replyTo == null ? null : (_replyTo!.author?.displayName ?? 'bình luận'),
      isSending: blogs.isSendingComment,
      error: blogs.commentError,
      maxLength: BlogController.commentMax,
      onChanged: (_) => blogs.clearCommentError(),
      onCancelReply: () => setState(() => _replyTo = null),
      onSend: () => _sendComment(blogs),
    );
  }

  Future<void> _sendComment(BlogController blogs) async {
    final sent = await blogs.addComment(_id, _comment.text, parentId: _replyTo?.id);
    if (!sent || !mounted) {
      return;
    }
    _comment.clear();
    _commentFocus.unfocus();
    setState(() => _replyTo = null);
    showMessage(context, blogs.takeMessage());
  }

  Future<void> _onCommentAction(Blog blog, BlogComment comment, BlogCommentAction action) async {
    final blogs = context.read<BlogController>();
    switch (action) {
      case BlogCommentAction.like:
        if (await _signedIn()) {
          await blogs.toggleCommentLike(_id, comment.id);
        }
      case BlogCommentAction.reply:
        if (await _signedIn() && mounted) {
          setState(() => _replyTo = comment);
          _commentFocus.requestFocus();
        }
      case BlogCommentAction.edit:
        await _editComment(comment);
      case BlogCommentAction.delete:
        if (await _confirm('Xóa bình luận?', 'Bạn có chắc muốn xóa bình luận này?')) {
          await blogs.deleteComment(_id, comment.id);
        }
      case BlogCommentAction.report:
        if (await _signedIn() && mounted) {
          final choice = await showReportDialog(context, reasons: blog.reportReasons, title: 'Báo cáo bình luận');
          if (choice != null) {
            await blogs.reportComment(_id, comment.id, reasonId: choice.reasonId, note: choice.note);
          }
        }
      case BlogCommentAction.message:
        if (comment.author != null) {
          await _openChat(comment.author!);
        }
    }
    if (mounted) {
      showMessage(context, blogs.takeMessage());
    }
  }

  Future<void> _editComment(BlogComment comment) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _EditCommentDialog(initial: comment.content),
    );
    if (text == null || text.trim() == comment.content || !mounted) {
      return;
    }
    await context.read<BlogController>().updateComment(_id, comment.id, text);
  }

  // ---------------------------------------------------------------- thao tác với bài

  /// Thao tác cần tài khoản. Khách vừa đăng nhập xong thì chưa làm ngay: bài được tải lại (cờ thích, lưu, tác giả
  /// mới đúng với người vừa đăng nhập), người dùng bấm lại.
  Future<bool> _signedIn() async {
    final wasGuest = _userId == null;
    if (!await requireSignIn(context) || !mounted) {
      return false;
    }
    return !wasGuest;
  }

  Future<void> _like(Blog blog) async {
    if (!await _signedIn() || !mounted) {
      return;
    }
    final blogs = context.read<BlogController>();
    await blogs.toggleLike(_id);
    if (mounted) {
      showMessage(context, blogs.takeMessage());
    }
  }

  Future<void> _save(Blog blog) async {
    if (!await _signedIn() || !mounted) {
      return;
    }
    final blogs = context.read<BlogController>();
    await blogs.toggleSave(_id);
    if (mounted) {
      showMessage(context, blogs.takeMessage());
    }
  }

  Future<void> _reportBlog(Blog blog) async {
    if (!await _signedIn() || !mounted) {
      return;
    }
    final choice = await showReportDialog(context, reasons: blog.reportReasons, title: 'Báo cáo bài viết');
    if (choice == null || !mounted) {
      return;
    }
    final blogs = context.read<BlogController>();
    await blogs.reportBlog(_id, reasonId: choice.reasonId, note: choice.note);
    if (mounted) {
      showMessage(context, blogs.takeMessage());
    }
  }

  /// Nhắn tin riêng cho tác giả hoặc người bình luận (không phải chính mình).
  Future<void> _openChat(Author author) async {
    if (!await requireSignIn(context) || !mounted) {
      return;
    }
    if (context.read<AuthController>().currentUser?.id == author.id) {
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(withUserId: author.id, title: author.displayName),
      ),
    );
  }

  Future<void> _edit(Blog blog) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => BlogFormScreen(blogId: blog.id)),
    );
    if (saved == true && mounted) {
      showMessage(context, context.read<BlogController>().takeMessage());
    }
  }

  Future<void> _delete(Blog blog) async {
    final confirmed = await _confirm(
      'Xóa bài viết?',
      'Bạn có chắc muốn xóa bài viết này? Bình luận của bài cũng bị xóa, và điểm bài đã nhận sẽ bị thu lại.',
    );
    if (!confirmed || !mounted) {
      return;
    }
    final blogs = context.read<BlogController>();
    final deleted = await blogs.deleteBlog(_id);
    if (!mounted) {
      return;
    }
    showMessage(context, blogs.takeMessage());
    if (deleted) {
      Navigator.pop(context);
    }
  }

  /// Hộp thoại xác nhận xoá: nút "Hủy" (Ghost) và "Xóa" (Danger).
  Future<bool> _confirm(String title, String text) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(text, style: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
          FilledButton(
            style: SenpaiButtonStyle.danger(SenpaiButtonSize.medium),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }
}

/// `actionBtn(icon, label, on)` của thiết kế: nút chữ có icon 20 và chữ Label/M; đang bật thì icon đặc brand,
/// chữ brand-text; tắt thì icon viền và chữ ink; khoá thì muted.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, required this.onPressed, this.on = false});

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: on ? SenpaiColors.brandText : SenpaiColors.ink,
        iconColor: on ? SenpaiColors.brand : SenpaiColors.ink,
        disabledForegroundColor: SenpaiColors.muted,
        disabledIconColor: SenpaiColors.muted,
        textStyle: SenpaiText.labelM,
        iconSize: 20,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        minimumSize: const Size(0, 44),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
      icon: Icon(icon),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

/// Hộp thoại sửa bình luận của mình: chữ cũ sẵn trong ô, "Lưu" / "Hủy".
class _EditCommentDialog extends StatefulWidget {
  const _EditCommentDialog({required this.initial});

  final String initial;

  @override
  State<_EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends State<_EditCommentDialog> {
  late final _text = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sửa bình luận'),
      content: TextField(
        controller: _text,
        autofocus: true,
        minLines: 2,
        maxLines: 6,
        maxLength: BlogController.commentMax,
        style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(
          style: SenpaiButtonStyle.size(SenpaiButtonSize.medium),
          onPressed: () => Navigator.pop(context, _text.text),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

