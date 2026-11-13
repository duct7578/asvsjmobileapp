import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/chat_controller.dart';
import 'package:myasvsj/com.myasvsj.model/chat_conversation.dart';
import 'package:myasvsj/com.myasvsj.model/chat_keyring.dart';
import 'package:myasvsj/com.myasvsj.model/chat_message.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/chat_avatar.dart';
import 'package:myasvsj/com.myasvsj.screen/chat_bubble.dart';
import 'package:myasvsj/com.myasvsj.screen/chat_guest_view.dart';
import 'package:myasvsj/com.myasvsj.screen/chat_key_dialog.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/report_dialog.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Một cuộc trò chuyện (trang `/messages/{id}` và `/messages?to={userId}` của web): tin nhắn văn bản, lời mời
/// (Chấp nhận / Từ chối / Chặn), "Đã xem", "đang soạn tin", sửa / thu hồi / báo cáo tin, chặn / bỏ chặn, xóa
/// cuộc trò chuyện. Hội thoại mã hóa đầu cuối: tin được giải mã để hiện, tin gửi / sửa được mã hóa; khi app chưa mở
/// khóa thì ô soạn tin thay bằng nút "Nhập mật khẩu khôi phục" (lần đầu trong phiên đăng nhập hộp thoại tự mở).
///
/// Màn 31 của thiết kế: thanh tiêu đề có ảnh 36 + tên + tag, lời nhắc an toàn (note tone ai), nhãn ngày, bong bóng
/// ChatBubble, "… đang soạn tin…" và thanh dưới trắng chứa ô soạn tin dạng viên thuốc với nút gửi tròn brand.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.conversationId, this.withUserId, this.title = 'Tin nhắn'});

  /// Mở hội thoại đã có [conversationId], hoặc nhắn cho người dùng [withUserId] (từ bài viết, bình luận).
  final int? conversationId;
  final int? withUserId;
  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const String _safety =
      'Senpai ơi không bao giờ hỏi mật khẩu hay mã OTP. Đừng gửi ảnh thẻ cư trú, hộ '
      'chiếu, số tài khoản hay chuyển tiền cho người bạn chưa gặp. Thấy đáng ngờ, hãy nhấn giữ tin nhắn đó rồi chọn '
      'Báo cáo.';

  final _text = TextEditingController();
  late final ChatController _chat;
  int? _openedFor;
  bool _wasVisible = true;

  @override
  void initState() {
    super.initState();
    _chat = context.read<ChatController>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Quay lại màn hình này sau khi một màn hình khác che kín nó (bấm thông báo tin nhắn khác, mở trang khác):
    // tải lại vì cuộc trò chuyện đang mở có thể đã đổi. Hộp thoại, bảng chọn không che kín nên không tải lại.
    final visible = TickerMode.valuesOf(context).enabled;
    if (visible && !_wasVisible && _openedFor != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open());
    }
    _wasVisible = visible;
  }

  @override
  void dispose() {
    _chat.closeRoom(this);
    _text.dispose();
    super.dispose();
  }

  void _open() {
    if (mounted) {
      _chat.openRoom(conversationId: widget.conversationId, withUserId: widget.withUserId, owner: this);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final chat = context.watch<ChatController>();
    final userId = auth.currentUser?.id;
    if (userId != null && userId != _openedFor) {
      _openedFor = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _open());
    }
    // Chỉ hiện cuộc trò chuyện màn hình này đã mở (một ChatScreen khác có thể đang mở chồng lên)
    final mine = auth.isSignedIn && chat.ownsRoom(this);
    final room = mine ? chat.room : null;
    if (room != null && chat.takeKeyPrompt()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showChatKeyDialog(context, _chat, mode: ChatKeyDialogMode.unlock);
        }
      });
    }
    return Scaffold(
      appBar: SenpaiAppBar(titleWidget: _title(chat, room), actions: [if (room != null) _menu(room)]),
      body: !auth.isSignedIn ? const ChatGuestView() : _body(chat, room),
    );
  }

  /// Ảnh 36 (cách 4) + tên Title/M + dòng phụ Caption muted (tag của người kia, hoặc "đang soạn tin…").
  Widget _title(ChatController chat, ChatConversation? room) {
    final name = room?.peer.displayName ?? widget.title;
    final tags = room?.peer.tags.map((t) => t.name).join(' · ') ?? '';
    final subtitle = room != null && chat.peerTyping ? 'đang soạn tin…' : tags;
    return Row(
      spacing: 4,
      children: [
        if (room != null)
          ChatAvatar(
            name: room.peer.displayName,
            url: room.peer.avatarUrl,
            radius: 18,
            tone: ChatAvatar.toneFor(room.peer.id, active: room.peer.active, blocked: room.status.blockedByMe),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menu(ChatConversation room) {
    final status = room.status;
    PopupMenuItem<String> item(String value, IconData icon, String text, {Color color = SenpaiColors.ink}) =>
        PopupMenuItem(
          value: value,
          child: Row(
            spacing: 12,
            children: [
              Icon(icon, size: 20, color: color),
              Flexible(
                child: Text(text, style: SenpaiText.bodyM.copyWith(color: color)),
              ),
            ],
          ),
        );
    return PopupMenuButton<String>(
      tooltip: 'Tùy chọn',
      icon: const Icon(Symbols.more_vert_rounded),
      onSelected: (action) => switch (action) {
        'block' => _block(room),
        'unblock' => _unblock(),
        _ => _delete(room),
      },
      itemBuilder: (_) => [
        if (status.noticeCode != 'DELETED')
          status.blockedByMe
              ? item('unblock', Symbols.lock_open_rounded, 'Bỏ chặn')
              : item('block', Symbols.block_rounded, 'Chặn'),
        if (room.id != null) item('delete', Symbols.delete_rounded, 'Xóa cuộc trò chuyện', color: SenpaiColors.crit),
      ],
    );
  }

  Widget _body(ChatController chat, ChatConversation? room) {
    if (room == null) {
      if (chat.roomError != null && chat.ownsRoom(this)) {
        return ErrorView(message: chat.roomError!, onRetry: _open);
      }
      return const LoadingView();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _thread(chat, room)),
        if (chat.peerTyping)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              '${room.peer.displayName} đang soạn tin…',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
            ),
          ),
        if (room.status.noticeCode != null) _notice(room) else ?_encryptionNotice(chat, room),
        _ChatBottomBar(child: _keyBlock(chat, room) ?? _composer(chat, room)),
      ],
    );
  }

  // ---------------------------------------------------------------- Mã hóa đầu cuối

  /// Hội thoại mã hóa mà app chưa mở khóa: thay ô soạn tin bằng lời giải thích và nút mở khóa (sửa một tin thường
  /// cũ vẫn được). null khi soạn tin được.
  Widget? _keyBlock(ChatController chat, ChatConversation room) {
    final editingPlain = chat.editing != null && !chat.editing!.isEncrypted;
    if (!room.status.isEncrypted || chat.keyState == ChatKeyState.ready || editingPlain) {
      return null;
    }
    const lead = 'Cuộc trò chuyện này đã được mã hóa đầu cuối.';
    return switch (chat.keyState) {
      ChatKeyState.loading => const SenpaiNote(
        '$lead Đang tải khóa mã hóa…',
        icon: Symbols.lock_rounded,
        tone: SenpaiTone.neutral,
      ),
      ChatKeyState.error => SenpaiNote(
        '',
        icon: Symbols.error_rounded,
        tone: SenpaiTone.crit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Text('Chưa tải được khóa mã hóa của bạn: ${chat.keyError ?? ''}'),
            SenpaiButton(
              label: 'Thử lại',
              icon: Symbols.refresh_rounded,
              kind: SenpaiButtonKind.secondary,
              size: SenpaiButtonSize.small,
              onPressed: _chat.retryKey,
            ),
          ],
        ),
      ),
      ChatKeyState.off => const SenpaiNote(
        '$lead Phiên bản app này chưa đọc và gửi được tin nhắn mã hóa.',
        icon: Symbols.lock_rounded,
        tone: SenpaiTone.neutral,
      ),
      _ => SenpaiNote(
        '',
        icon: Symbols.key_rounded,
        tone: SenpaiTone.brand,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Text(
              chat.keyState == ChatKeyState.none
                  ? '$lead Bật mã hóa trên app để đọc và gửi tin nhắn.'
                  : '$lead Nhập mật khẩu khôi phục để đọc và gửi tin nhắn trên app này.',
            ),
            SenpaiButton(
              label: chat.keyState == ChatKeyState.none ? 'Bật mã hóa' : 'Nhập mật khẩu khôi phục',
              icon: Symbols.key_rounded,
              size: SenpaiButtonSize.small,
              onPressed: () => showChatKeyDialog(context, _chat),
            ),
          ],
        ),
      ),
    };
  }

  /// Điều cần biết về mã hóa khi không có thông báo nào khác: mình chưa bật (nút "Bật mã hóa"), người kia chưa bật.
  Widget? _encryptionNotice(ChatController chat, ChatConversation room) {
    final code = room.status.encryptionNoticeCode;
    if ((code != 'NO_KEY_ME' && code != 'NO_KEY_PEER') || chat.keyState == ChatKeyState.off) {
      return null;
    }
    final canSetUp = code == 'NO_KEY_ME' && chat.keyState == ChatKeyState.none;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SenpaiNote(
        room.status.encryptionNoticeText,
        icon: Symbols.lock_open_rounded,
        tone: SenpaiTone.neutral,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Text(room.status.encryptionNoticeText),
            if (canSetUp)
              SenpaiButton(
                label: 'Bật mã hóa',
                icon: Symbols.lock_rounded,
                kind: SenpaiButtonKind.secondary,
                size: SenpaiButtonSize.small,
                onPressed: () => showChatKeyDialog(context, _chat, mode: ChatKeyDialogMode.setup),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Tin nhắn

  Widget _thread(ChatController chat, ChatConversation room) {
    final rows = <Widget>[
      const SenpaiNote(_safety, icon: Symbols.shield_rounded, tone: SenpaiTone.ai),
      if (room.hasOlder)
        Center(
          child: SenpaiButton(
            label: chat.isLoadingOlder ? 'Đang tải…' : 'Xem tin cũ hơn',
            kind: SenpaiButtonKind.ghost,
            size: SenpaiButtonSize.small,
            icon: Symbols.history_rounded,
            onPressed: chat.isLoadingOlder ? null : _loadOlder,
          ),
        ),
    ];
    DateTime? day;
    // Tin mã hóa hiện bản đã giải mã (hoặc "Đang giải mã…"), cả trong khung trích dẫn
    final shown = [for (final m in room.messages) chat.display(m)];
    final byId = {for (final m in shown) m.id: m};
    for (final m in shown) {
      final date = DateUtils.dateOnly(m.createdAt);
      if (date != day) {
        day = date;
        rows.add(Center(child: SenpaiBadge(_dayText(date), tone: SenpaiTone.neutral)));
      }
      final quoted = m.replyToId == null ? null : byId[m.replyToId];
      rows.add(
        ChatBubble(
          key: ValueKey('msg-${m.id}'),
          message: m,
          quoted: quoted,
          quotedName: quoted == null ? '' : (quoted.mine ? 'Bạn' : room.peer.displayName),
          delivery: chat.deliveryOf(m),
          onLongPress: () => _actions(chat, room, m),
        ),
      );
    }
    // Danh sách lật ngược: mở ra đã ở tin mới nhất, tin mới đến thì hiện ngay ở cuối
    return ListView.separated(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => rows[rows.length - 1 - i],
    );
  }

  String _dayText(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    if (date == today) {
      return 'Hôm nay';
    }
    if (date == today.subtract(const Duration(days: 1))) {
      return 'Hôm qua';
    }
    return formatDate(date);
  }

  Future<void> _loadOlder() async {
    await _chat.loadOlder();
    if (mounted) {
      showMessage(context, _chat.takeMessage());
    }
  }

  /// Nhấn giữ một tin: Sao chép, Sửa, Thu hồi, Báo cáo (chỉ những gì làm được lúc này).
  Future<void> _actions(ChatController chat, ChatConversation room, ChatMessage m) async {
    final canCopy = !m.recalled && (m.content ?? '').isNotEmpty;
    final canEdit = chat.canEdit(m);
    final canRecall = chat.canRecall(m);
    final canReport = chat.canReport(m);
    if (!canCopy && !canEdit && !canRecall && !canReport) {
      return;
    }
    Widget action(BuildContext sheetContext, String value, IconData icon, String label, {Color? color}) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: color ?? SenpaiColors.ink),
      title: Text(label, style: color == null ? null : SenpaiText.titleS.copyWith(color: color)),
      onTap: () => Navigator.pop(sheetContext, value),
    );
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canCopy) action(sheetContext, 'copy', Symbols.content_copy_rounded, 'Sao chép'),
              if (canEdit) action(sheetContext, 'edit', Symbols.edit_rounded, 'Sửa'),
              if (canRecall) action(sheetContext, 'recall', Symbols.undo_rounded, 'Thu hồi'),
              if (canReport) action(sheetContext, 'report', Symbols.flag_rounded, 'Báo cáo', color: SenpaiColors.crit),
            ],
          ),
        ),
      ),
    );
    if (!mounted || picked == null) {
      return;
    }
    switch (picked) {
      case 'copy':
        await Clipboard.setData(ClipboardData(text: m.content ?? ''));
        if (mounted) {
          showMessage(context, 'Đã sao chép tin nhắn.');
        }
      case 'edit':
        _chat.startEdit(m);
        _text.text = m.content ?? '';
        _text.selection = TextSelection.collapsed(offset: _text.text.length);
      case 'recall':
        await _recall(m);
      case 'report':
        await _report(room, m);
    }
  }

  Future<void> _recall(ChatMessage m) async {
    final ok = await _confirm('Thu hồi tin nhắn này?', 'Cả hai bạn sẽ thấy “Tin nhắn đã được thu hồi”.', 'Thu hồi');
    if (!ok || !mounted) {
      return;
    }
    final editingThis = _chat.editing?.id == m.id;
    await _chat.recallMessage(m);
    if (!mounted) {
      return;
    }
    if (editingThis) {
      _text.clear();
    }
    showMessage(context, _chat.takeMessage());
  }

  Future<void> _report(ChatConversation room, ChatMessage m) async {
    final choice = await showReportDialog(context, reasons: room.reportReasons, title: 'Báo cáo tin nhắn');
    if (choice == null || !mounted) {
      return;
    }
    await _chat.reportMessage(m, reasonId: choice.reasonId, note: choice.note);
    if (mounted) {
      showMessage(context, _chat.takeMessage());
    }
  }

  // ---------------------------------------------------------------- Thông báo trên ô soạn tin

  /// Thông báo trạng thái của server (lời mời, chờ trả lời, đã chặn…) trong hộp note: brand, bị cắt liên lạc thì
  /// crit; lời mời có Chấp nhận / Từ chối / Chặn, đã chặn có Bỏ chặn.
  Widget _notice(ChatConversation room) {
    final status = room.status;
    final critical = status.isCutOff;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SenpaiNote(
        status.noticeText,
        icon: critical ? Symbols.block_rounded : Symbols.info_rounded,
        tone: critical ? SenpaiTone.crit : SenpaiTone.brand,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Text(status.noticeText),
            if (status.isRequest)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SenpaiButton(
                    label: 'Chấp nhận',
                    icon: Symbols.check_rounded,
                    size: SenpaiButtonSize.small,
                    onPressed: _accept,
                  ),
                  SenpaiButton(
                    label: 'Từ chối',
                    kind: SenpaiButtonKind.secondary,
                    size: SenpaiButtonSize.small,
                    onPressed: () => _decline(room),
                  ),
                  SenpaiButton(
                    label: 'Chặn',
                    icon: Symbols.block_rounded,
                    kind: SenpaiButtonKind.ghost,
                    size: SenpaiButtonSize.small,
                    onPressed: () => _block(room),
                  ),
                ],
              ),
            if (status.noticeCode == 'BLOCKED_BY_ME')
              SenpaiButton(
                label: 'Bỏ chặn',
                icon: Symbols.lock_open_rounded,
                kind: SenpaiButtonKind.secondary,
                size: SenpaiButtonSize.small,
                onPressed: _unblock,
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Ô soạn tin

  /// `composer(hint)` + `sendBtn()`: viên thuốc surface-2 cao 48, chữ gợi ý Body/S muted, nút gửi tròn 40 brand.
  /// Đang sửa tin thì có dòng "Đang sửa tin nhắn" phía trên; lỗi gửi Caption crit phía dưới.
  Widget _composer(ChatController chat, ChatConversation room) {
    final editing = chat.editing;
    final enabled = room.status.canSend || editing != null;
    const none = InputBorder.none;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (editing != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Row(
              spacing: 8,
              children: [
                const Icon(Symbols.edit_rounded, size: 18, color: SenpaiColors.brandText),
                Expanded(
                  child: Text('Đang sửa tin nhắn', style: SenpaiText.labelM.copyWith(color: SenpaiColors.brandText)),
                ),
                IconButton(
                  tooltip: 'Hủy sửa',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Symbols.close_rounded, size: 20, color: SenpaiColors.muted),
                  onPressed: () {
                    _chat.cancelEdit();
                    _text.clear();
                  },
                ),
              ],
            ),
          ),
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
          decoration: BoxDecoration(color: SenpaiColors.surface2, borderRadius: BorderRadius.circular(24)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 8,
            children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: room.messageMax,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => _chat.onComposing(),
                  style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
                  decoration: InputDecoration(
                    hintText: enabled
                        ? (editing != null ? 'Sửa tin nhắn…' : 'Nhập tin nhắn…')
                        : 'Bạn chưa gửi được tin nhắn',
                    hintStyle: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
                    hintMaxLines: 1,
                    counterText: '',
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 9),
                    border: none,
                    enabledBorder: none,
                    focusedBorder: none,
                    disabledBorder: none,
                    errorBorder: none,
                    focusedErrorBorder: none,
                  ),
                ),
              ),
              IconButton.filled(
                tooltip: editing != null ? 'Lưu' : 'Gửi',
                style: IconButton.styleFrom(
                  backgroundColor: SenpaiColors.brand,
                  foregroundColor: SenpaiColors.onBrand,
                  disabledBackgroundColor: SenpaiColors.line,
                  disabledForegroundColor: SenpaiColors.muted,
                  fixedSize: const Size(40, 40),
                  minimumSize: const Size(40, 40),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(editing != null ? Symbols.check_rounded : Symbols.send_rounded, size: 20),
                onPressed: enabled && !chat.isSending ? _send : null,
              ),
            ],
          ),
        ),
        if (chat.sendError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: Text(chat.sendError!, style: SenpaiText.caption.copyWith(color: SenpaiColors.crit)),
          ),
      ],
    );
  }

  Future<void> _send() async {
    final ok = await _chat.sendMessage(_text.text);
    if (ok && mounted) {
      _text.clear();
    }
  }

  // ---------------------------------------------------------------- Lời mời, chặn, xóa

  Future<void> _accept() async {
    await _chat.acceptRequest();
    if (mounted) {
      showMessage(context, _chat.takeMessage());
    }
  }

  Future<void> _decline(ChatConversation room) async {
    final name = room.peer.displayName;
    final ok = await _confirm(
      'Từ chối lời mời?',
      'Từ chối lời mời nhắn tin của $name? Lời mời sẽ rời khỏi danh sách của bạn và $name không gửi thêm được, '
          'nhưng không được báo là bị từ chối.',
      'Từ chối',
    );
    if (!ok || !mounted) {
      return;
    }
    final done = await _chat.declineRequest();
    _afterLeave(done);
  }

  Future<void> _delete(ChatConversation room) async {
    final name = room.peer.displayName;
    final ok = await _confirm(
      'Xóa cuộc trò chuyện?',
      'Xóa cuộc trò chuyện với $name? Các tin nhắn hiện có sẽ không còn hiện với bạn; $name vẫn giữ tin nhắn của '
          'họ. Nếu có tin nhắn mới, cuộc trò chuyện sẽ hiện lại.',
      'Xóa',
      danger: true,
    );
    if (!ok || !mounted) {
      return;
    }
    final done = await _chat.deleteConversation();
    _afterLeave(done);
  }

  /// Sau Từ chối / Xóa: hiện câu của server; thành công thì quay về danh sách.
  void _afterLeave(bool done) {
    if (!mounted) {
      return;
    }
    showMessage(context, _chat.takeMessage());
    if (done) {
      Navigator.pop(context);
    }
  }

  Future<void> _block(ChatConversation room) async {
    final name = room.peer.displayName;
    final ok = await _confirm(
      'Chặn $name?',
      'Hai bạn sẽ không nhắn tin được cho nhau cho đến khi bạn bỏ chặn. $name không được báo.',
      'Chặn',
      danger: true,
    );
    if (!ok || !mounted) {
      return;
    }
    await _chat.blockPeer();
    if (mounted) {
      showMessage(context, _chat.takeMessage());
    }
  }

  Future<void> _unblock() async {
    await _chat.unblockPeer();
    if (mounted) {
      showMessage(context, _chat.takeMessage());
    }
  }

  /// Hộp xác nhận: "Hủy" (Ghost) và nút hành động (Primary, hoặc Danger khi xoá / chặn).
  Future<bool> _confirm(String title, String content, String action, {bool danger = false}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(content, style: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted)),
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

/// `bottomBar(s, kids)` của thiết kế cho ô soạn tin: nền trắng, bóng Bar, lề [12,16,12+đáy máy,16]. Khác
/// SenpaiBottomBar ở chỗ con xếp dọc (dòng "Đang sửa", ô soạn tin, lỗi).
class _ChatBottomBar extends StatelessWidget {
  const _ChatBottomBar({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: SenpaiColors.surface, boxShadow: SenpaiColors.shadowBar),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: child),
      ),
    );
  }
}
