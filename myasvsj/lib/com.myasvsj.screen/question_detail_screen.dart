import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/question_controller.dart';
import 'package:myasvsj/com.myasvsj.model/answer.dart';
import 'package:myasvsj/com.myasvsj.model/author.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.model/question.dart';
import 'package:myasvsj/com.myasvsj.screen/answer_tile.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/chat_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/media_image.dart';
import 'package:myasvsj/com.myasvsj.screen/place_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_author_row.dart';
import 'package:myasvsj/com.myasvsj.screen/question_badge.dart';
import 'package:myasvsj/com.myasvsj.screen/question_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/report_dialog.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/sign_in_gate.dart';

/// Màn chi tiết câu hỏi (`/qa/{id}` của web, màn 16 của thiết kế): nhãn, câu hỏi Display/L, người hỏi kèm nút
/// "Nhắn tin", chủ đề / địa điểm, ảnh, nội dung, thanh thao tác (thích, lưu, trả lời, báo cáo), ô trả lời và các
/// câu trả lời (câu hay nhất ở đầu, phản hồi lồng bên dưới) với: phản hồi, chọn câu trả lời hay nhất, sửa / xóa của
/// mình, nhắn tin cho người viết. Người hỏi sửa / xóa câu hỏi trên thanh tiêu đề. Khách bấm thao tác thì được đưa
/// sang Đăng nhập.
class QuestionDetailScreen extends StatefulWidget {
  const QuestionDetailScreen({super.key, required this.questionId});

  final int questionId;

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  static const _statusNotes = {
    'PROCESSING': 'Ảnh của câu hỏi đang được quét. Trong lúc này chỉ bạn thấy câu hỏi.',
    'HIDDEN': 'Câu hỏi đang tạm ẩn vì có nhiều báo cáo, chờ Moderator xem xét.',
    'REJECTED': 'Câu hỏi chưa được đăng vì vi phạm Quy tắc cộng đồng. Bạn có thể sửa rồi gửi lại.',
  };

  final _answer = TextEditingController();
  final _answerFocus = FocusNode();
  final _reply = TextEditingController();
  final _edit = TextEditingController();

  /// Câu trả lời đang mở ô phản hồi / đang sửa tại chỗ (trạng thái giao diện của riêng màn này).
  int? _replyTo;
  int? _editing;

  /// Người đang đăng nhập lần dựng trước: đổi thì tải lại, vì quyền và trạng thái thích / lưu theo người xem.
  int? _userId;
  bool _userSeen = false;

  int get _id => widget.questionId;

  QuestionController get _controller => context.read<QuestionController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _controller.loadQuestion(_id));
  }

  @override
  void dispose() {
    _answer.dispose();
    _answerFocus.dispose();
    _reply.dispose();
    _edit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final userId = auth.currentUser?.id;
    if (_userSeen && userId != _userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.loadQuestion(_id);
        }
      });
    }
    _userSeen = true;
    _userId = userId;

    final c = context.watch<QuestionController>();
    final q = c.questionOf(_id);
    return Scaffold(
      appBar: SenpaiAppBar(
        title: 'Câu hỏi',
        actions: [
          if (q != null && q.isMine) ...[
            if (QuestionController.editableStatuses.contains(q.status))
              IconButton(
                tooltip: 'Sửa câu hỏi',
                icon: const Icon(Symbols.edit_rounded),
                onPressed: () => _editQuestion(q),
              ),
            IconButton(
              tooltip: 'Xóa câu hỏi',
              icon: const Icon(Symbols.delete_rounded, color: SenpaiColors.crit),
              onPressed: () => _delete(q),
            ),
          ],
        ],
      ),
      body: _body(c, q, auth.isSignedIn),
    );
  }

  Widget _body(QuestionController c, Question? q, bool signedIn) {
    if (q == null) {
      final error = c.questionError(_id);
      if (error == null) {
        return const LoadingView();
      }
      return ErrorView(message: error, onRetry: () => c.loadQuestion(_id));
    }
    final note = _statusNotes[q.status];
    final items = <Widget>[
      if (note != null)
        SenpaiNote(
          note,
          icon: q.status == 'PROCESSING' ? Symbols.hourglass_top_rounded : Symbols.visibility_off_rounded,
          tone: q.status == 'PROCESSING' ? SenpaiTone.warn : SenpaiTone.crit,
        ),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          const QuestionBadge(label: 'Hỏi đáp', icon: Symbols.help_rounded, tone: SenpaiTone.ai),
          if (q.isSolved)
            const QuestionBadge(label: 'Đã giải quyết', icon: Symbols.check_circle_rounded, tone: SenpaiTone.ok)
          else if (q.isPublished)
            const QuestionBadge(
              label: 'Câu hỏi chờ trả lời',
              icon: Symbols.hourglass_empty_rounded,
              tone: SenpaiTone.lantern,
            ),
          if (q.pinned) const QuestionBadge(label: 'Đã ghim', icon: Symbols.push_pin_rounded, tone: SenpaiTone.lantern),
        ],
      ),
      SelectableText(q.title, style: SenpaiText.displayL.copyWith(color: SenpaiColors.ink)),
      QuestionAuthorRow(
        author: q.author,
        createdAt: q.createdAt,
        edited: q.edited,
        trailing: q.isMine || q.author == null
            ? null
            : SenpaiButton(
                label: 'Nhắn tin',
                kind: SenpaiButtonKind.soft,
                size: SenpaiButtonSize.small,
                icon: Symbols.chat_rounded,
                onPressed: () => _message(q.author!),
              ),
      ),
      if (q.topics.isNotEmpty || q.places.isNotEmpty)
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in q.topics) TopicChip(t.name),
            for (final p in q.places)
              PlaceChip(
                p.name,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => PlaceDetailScreen(placeId: p.id)),
                ),
              ),
          ],
        ),
      for (final image in q.images) _image(image),
      if (q.content.isNotEmpty) SelectableText(q.content, style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink)),
      _actionBar(q, signedIn),
      SectionHead('Câu trả lời (${q.answerCount})'),
      _answerForm(c, q, signedIn),
      if (q.answers.isEmpty)
        Text(
          'Chưa có câu trả lời. Bạn biết câu trả lời thì chia sẻ nhé.',
          style: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted),
        )
      else
        for (final a in q.answers)
          AnswerTile(
            key: ValueKey('answer-${a.id}'),
            answer: a,
            question: q,
            signedIn: signedIn,
            replyingTo: _replyTo,
            replyBox: _replyTo == null ? null : _replyBox(c, _replyTo!),
            editingId: _editing,
            editBox: _editing == null ? null : _editBox(c, _editing!),
            onLike: _likeAnswer,
            onReply: _openReply,
            onEdit: _openEdit,
            onDelete: _deleteAnswer,
            onReport: _reportAnswer,
            onBest: _chooseBest,
            onMessage: (answer) => _message(answer.author!),
          ),
    ];
    return RefreshIndicator(
      onRefresh: () => c.loadQuestion(_id),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            items[i],
          ],
        ],
      ),
    );
  }

  /// Ảnh của câu hỏi (bo 16); bấm để xem to, phóng to được.
  Widget _image(MediaItem image) {
    final ratio = (image.width ?? 0) > 0 && (image.height ?? 0) > 0 ? image.width! / image.height! : 4 / 3;
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog.fullscreen(
          backgroundColor: SenpaiColors.inkDeep,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  child: MediaImage(url: image.url, fit: BoxFit.contain, radius: 0),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: SafeArea(
                  child: IconButton.filledTonal(
                    tooltip: 'Đóng',
                    icon: const Icon(Symbols.close_rounded),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      child: AspectRatio(
        aspectRatio: ratio.clamp(0.75, 2.0),
        child: MediaImage(url: image.url, width: double.infinity, radius: 16),
      ),
    );
  }

  /// `ActionBar` của thiết kế: Thích, Lưu, Trả lời, Báo cáo (người hỏi chỉ thấy số lượt thích, không báo cáo câu
  /// của mình).
  Widget _actionBar(Question q, bool signedIn) {
    final locked = signedIn && !q.canInteract;
    return _ActionBar(
      children: [
        if (q.isMine)
          _ActionButton(icon: Symbols.favorite_rounded, label: '${q.likeCount} lượt thích')
        else
          _ActionButton(
            icon: q.liked ? Icons.favorite_rounded : Symbols.favorite_rounded,
            label: 'Thích · ${q.likeCount}',
            on: q.liked,
            onTap: locked ? null : () => _like(q),
          ),
        _ActionButton(
          icon: q.saved ? Icons.bookmark_rounded : Symbols.bookmark_rounded,
          label: q.saved ? 'Đã lưu' : 'Lưu',
          on: q.saved,
          onTap: locked ? null : () => _save(q),
        ),
        if (q.isPublished)
          _ActionButton(icon: Symbols.chat_bubble_rounded, label: 'Trả lời', onTap: locked ? null : _focusAnswer),
        if (!q.isMine && q.isPublished)
          _ActionButton(icon: Symbols.flag_rounded, label: 'Báo cáo', onTap: locked ? null : () => _report(q)),
      ],
    );
  }

  /// `AnswerBox` của thiết kế: ô trắng bo 16 cao 52 có nút gửi tròn màu brand; khách thấy lời mời đăng nhập.
  Widget _answerForm(QuestionController c, Question q, bool signedIn) {
    final muted = SenpaiText.bodyS.copyWith(color: SenpaiColors.muted);
    if (!q.isPublished) {
      return Text('Câu hỏi chưa được đăng nên chưa nhận câu trả lời.', style: muted);
    }
    // App còn nhớ đăng nhập nhưng server coi là khách: phiên trên server đã hết
    final expired = signedIn && !q.signedIn;
    if (!signedIn || expired) {
      return SenpaiCard(
        child: Row(
          spacing: 10,
          children: [
            Expanded(
              child: Text(
                expired ? 'Phiên đăng nhập đã hết. Đăng nhập lại để trả lời.' : 'Đăng nhập để trả lời và thích câu hỏi.',
                style: SenpaiText.bodyS.copyWith(color: SenpaiColors.ink),
              ),
            ),
            SenpaiButton(
              label: 'Đăng nhập',
              size: SenpaiButtonSize.small,
              icon: Symbols.login_rounded,
              onPressed: expired ? _signInAgain : _signedIn,
            ),
          ],
        ),
      );
    }
    if (!q.canInteract) {
      return Text('Tài khoản của bạn chỉ xem được, không trả lời được.', style: muted);
    }
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
    return TextField(
      controller: _answer,
      focusNode: _answerFocus,
      minLines: 1,
      maxLines: 6,
      maxLength: QuestionController.answerMax,
      decoration: InputDecoration(
        hintText: 'Viết câu trả lời của bạn',
        hintStyle: muted,
        counterText: '',
        errorText: c.answerErrorFor(null),
        errorMaxLines: 3,
        contentPadding: const EdgeInsets.fromLTRB(14, 15, 4, 15),
        border: border(SenpaiColors.line, 1),
        enabledBorder: border(SenpaiColors.line, 1),
        focusedBorder: border(SenpaiColors.brand, 2),
        errorBorder: border(SenpaiColors.crit, 1.5),
        focusedErrorBorder: border(SenpaiColors.crit, 2),
        suffixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 40),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: IconButton.filled(
            tooltip: 'Gửi',
            onPressed: c.isSendingAnswer ? null : _sendAnswer,
            style: IconButton.styleFrom(
              backgroundColor: SenpaiColors.brand,
              foregroundColor: SenpaiColors.onBrand,
              minimumSize: const Size(40, 40),
              fixedSize: const Size(40, 40),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: c.isSendingAnswer
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Symbols.send_rounded, size: 20),
          ),
        ),
      ),
      onChanged: (_) => c.clearAnswerError(null),
    );
  }

  /// Ô phản hồi một câu trả lời (mở ngay dưới câu đó).
  Widget _replyBox(QuestionController c, int parentId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 8,
      children: [
        TextField(
          controller: _reply,
          autofocus: true,
          minLines: 2,
          maxLines: 6,
          maxLength: QuestionController.answerMax,
          decoration: InputDecoration(
            hintText: 'Viết câu trả lời cho bình luận này',
            hintStyle: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
            errorText: c.answerErrorFor(parentId),
            errorMaxLines: 3,
          ),
          onChanged: (_) => c.clearAnswerError(parentId),
        ),
        Wrap(
          spacing: 8,
          children: [
            SenpaiButton(
              label: 'Hủy',
              kind: SenpaiButtonKind.ghost,
              size: SenpaiButtonSize.small,
              onPressed: () => setState(() => _replyTo = null),
            ),
            SenpaiButton(
              label: 'Gửi',
              size: SenpaiButtonSize.small,
              icon: Symbols.send_rounded,
              onPressed: c.isSendingAnswer ? null : () => _sendReply(parentId),
            ),
          ],
        ),
      ],
    );
  }

  /// Ô sửa câu trả lời tại chỗ (thay cho nội dung).
  Widget _editBox(QuestionController c, int answerId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 8,
      children: [
        TextField(
          controller: _edit,
          autofocus: true,
          minLines: 2,
          maxLines: 8,
          maxLength: QuestionController.answerMax,
          decoration: InputDecoration(
            labelText: 'Sửa câu trả lời',
            errorText: c.answerErrors[answerId],
            errorMaxLines: 3,
          ),
          onChanged: (_) => c.clearAnswerError(answerId),
        ),
        Wrap(
          spacing: 8,
          children: [
            SenpaiButton(
              label: 'Hủy',
              kind: SenpaiButtonKind.ghost,
              size: SenpaiButtonSize.small,
              onPressed: () => setState(() => _editing = null),
            ),
            SenpaiButton(
              label: 'Lưu',
              size: SenpaiButtonSize.small,
              icon: Symbols.check_rounded,
              onPressed: c.isSendingAnswer ? null : () => _saveEdit(answerId),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- Thao tác

  /// Hiện câu thông báo của Controller (của server) một lần.
  void _flush() {
    if (mounted) {
      showMessage(context, _controller.takeMessage());
    }
  }

  /// Thao tác cần tài khoản: khách được đưa sang Đăng nhập; đăng nhập xong thì tải lại câu hỏi (quyền và trạng
  /// thái thích / lưu đổi theo người xem). Trả về true khi được làm tiếp.
  Future<bool> _signedIn() async {
    if (context.read<AuthController>().isSignedIn) {
      return true;
    }
    if (!await requireSignIn(context) || !mounted) {
      return false;
    }
    _userId = context.read<AuthController>().currentUser?.id;
    await _controller.loadQuestion(_id);
    return mounted;
  }

  /// Phiên trên server đã hết dù app còn nhớ người dùng: mở màn Đăng nhập, xong thì tải lại câu hỏi.
  Future<void> _signInAgain() async {
    final ok = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    if (ok == true && mounted) {
      await _controller.loadQuestion(_id);
    }
  }

  bool get _isGuest => !context.read<AuthController>().isSignedIn;

  Future<void> _like(Question q) async {
    final wasGuest = _isGuest;
    if (!await _signedIn()) {
      return;
    }
    final now = _controller.questionOf(_id);
    // Vừa đăng nhập: không bỏ thích câu đã thích từ trước, không thích câu của chính mình
    if (now == null || now.isMine || !now.canInteract || (wasGuest && now.liked)) {
      return;
    }
    await _controller.toggleLike(_id);
    _flush();
  }

  Future<void> _save(Question q) async {
    final wasGuest = _isGuest;
    if (!await _signedIn()) {
      return;
    }
    final now = _controller.questionOf(_id);
    if (now == null || !now.canInteract || (wasGuest && now.saved)) {
      return;
    }
    await _controller.toggleSave(_id);
    _flush();
  }

  Future<void> _focusAnswer() async {
    if (!await _signedIn()) {
      return;
    }
    _answerFocus.requestFocus();
  }

  Future<void> _report(Question q) async {
    if (!await _signedIn()) {
      return;
    }
    final now = _controller.questionOf(_id);
    if (now == null || now.isMine || !mounted) {
      return;
    }
    final choice = await showReportDialog(context, reasons: now.reportReasons, title: 'Báo cáo câu hỏi');
    if (choice == null || !mounted) {
      return;
    }
    await _controller.reportQuestion(_id, choice.reasonId, choice.note);
    _flush();
  }

  Future<void> _editQuestion(Question q) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => QuestionFormScreen(questionId: q.id)),
    );
    if (saved == true) {
      _flush();
    }
  }

  Future<void> _delete(Question q) async {
    final ok = await _confirm(
      title: 'Xóa câu hỏi?',
      text: 'Bạn có chắc muốn xóa câu hỏi này? Các câu trả lời cũng bị xóa, và điểm câu hỏi đã nhận sẽ bị thu lại.',
      action: 'Xóa',
      danger: true,
    );
    if (!ok || !mounted) {
      return;
    }
    final deleted = await _controller.deleteQuestion(_id);
    _flush();
    if (deleted && mounted) {
      Navigator.pop(context);
    }
  }

  /// Nhắn tin riêng cho người hỏi / người trả lời.
  Future<void> _message(Author author) async {
    if (!await _signedIn() || !mounted) {
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

  Future<void> _sendAnswer() async {
    final sent = await _controller.sendAnswer(_id, _answer.text);
    if (sent && mounted) {
      _answer.clear();
      _answerFocus.unfocus();
      _flush();
    }
  }

  Future<void> _openReply(Answer answer) async {
    if (!await _signedIn() || !mounted) {
      return;
    }
    _reply.clear();
    _controller.clearAnswerError(answer.id);
    setState(() {
      _replyTo = answer.id;
      _editing = null;
    });
  }

  Future<void> _sendReply(int parentId) async {
    final sent = await _controller.sendAnswer(_id, _reply.text, parentId: parentId);
    if (sent && mounted) {
      _reply.clear();
      setState(() => _replyTo = null);
      _flush();
    }
  }

  void _openEdit(Answer answer) {
    _edit.text = answer.content;
    _controller.clearAnswerError(answer.id);
    setState(() {
      _editing = answer.id;
      _replyTo = null;
    });
  }

  Future<void> _saveEdit(int answerId) async {
    final saved = await _controller.updateAnswer(_id, answerId, _edit.text);
    if (saved && mounted) {
      setState(() => _editing = null);
      _flush();
    }
  }

  Future<void> _deleteAnswer(Answer answer) async {
    final ok = await _confirm(
      title: 'Xóa bình luận?',
      text: 'Bạn có chắc muốn xóa bình luận này?',
      action: 'Xóa',
      danger: true,
    );
    if (!ok || !mounted) {
      return;
    }
    await _controller.deleteAnswer(_id, answer.id);
    _flush();
  }

  Future<void> _likeAnswer(Answer answer) async {
    final wasGuest = _isGuest;
    if (!await _signedIn()) {
      return;
    }
    final now = Answer.find(_controller.questionOf(_id)?.answers ?? const [], answer.id);
    if (now == null || now.isMine || (wasGuest && now.liked)) {
      return;
    }
    await _controller.toggleAnswerLike(_id, answer.id);
    _flush();
  }

  Future<void> _reportAnswer(Answer answer) async {
    if (!await _signedIn() || !mounted) {
      return;
    }
    final q = _controller.questionOf(_id);
    final now = Answer.find(q?.answers ?? const [], answer.id);
    if (q == null || now == null || now.isMine) {
      return;
    }
    final choice = await showReportDialog(context, reasons: q.reportReasons, title: 'Báo cáo câu trả lời');
    if (choice == null || !mounted) {
      return;
    }
    await _controller.reportAnswer(_id, answer.id, choice.reasonId, choice.note);
    _flush();
  }

  Future<void> _chooseBest(Answer answer) async {
    final name = answer.author?.displayName ?? 'người trả lời';
    final ok = await _confirm(
      title: 'Chọn câu trả lời hay nhất?',
      text: 'Câu trả lời của $name sẽ hiện đầu tiên với nhãn “Câu trả lời hay nhất”. Người trả lời được +5 điểm.',
      action: 'Chọn',
    );
    if (!ok || !mounted) {
      return;
    }
    await _controller.chooseBest(_id, answer.id);
    _flush();
  }

  Future<bool> _confirm({
    required String title,
    required String text,
    required String action,
    bool danger = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
          FilledButton(
            style: danger
                ? SenpaiButtonStyle.danger(SenpaiButtonSize.medium)
                : SenpaiButtonStyle.size(SenpaiButtonSize.medium),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }
}

/// `actionBar(items)` của thiết kế: hộp trắng viền line bo 16, lề [2,4], các nút dàn đều chiều ngang. Màn hẹp
/// không đủ chỗ thì cả hàng thu nhỏ đều nhau (chữ các nút luôn cùng cỡ, không bị cắt).
class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: SenpaiColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SenpaiColors.line),
      ),
      child: LayoutBuilder(
        builder: (context, box) => FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            // Ít nhất bằng bề ngang hộp để chỗ thừa chia đều giữa các nút
            constraints: BoxConstraints(minWidth: box.maxWidth),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

/// `actionBtn(icon, label, on)`: icon 20 + chữ Label/M; đang bật (đã thích, đã lưu) thì icon đặc màu brand, chữ
/// brand-text. Không có [onTap] (chỉ để xem, hoặc bị khóa) thì màu muted.
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.icon, required this.label, this.on = false, this.onTap});

  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final iconColor = !enabled ? SenpaiColors.muted : (on ? SenpaiColors.brand : SenpaiColors.ink);
    final textColor = !enabled ? SenpaiColors.muted : (on ? SenpaiColors.brandText : SenpaiColors.ink);
    return Semantics(
      button: enabled,
      enabled: enabled,
      toggled: enabled && on,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Icon(icon, size: 20, color: iconColor),
              Text(label, maxLines: 1, style: SenpaiText.labelM.copyWith(color: textColor)),
            ],
          ),
        ),
      ),
    );
  }
}
