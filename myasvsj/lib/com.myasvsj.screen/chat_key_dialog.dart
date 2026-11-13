import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.controller/chat_controller.dart';
import 'package:myasvsj/com.myasvsj.model/chat_keyring.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/password_field.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Hộp thoại mật khẩu khôi phục đang làm gì.
enum ChatKeyDialogMode {
  /// "Nhập mật khẩu khôi phục" để mở khóa đã có.
  unlock,

  /// "Bật mã hóa đầu cuối" lần đầu.
  setup,

  /// "Tạo khóa mã hóa mới" khi quên mật khẩu (tin mã hóa cũ không đọc được nữa).
  replace,
}

/// Mở hộp thoại hợp với trạng thái khóa hiện tại: chưa bật thì "Bật mã hóa", có khóa thì "Nhập mật khẩu khôi phục".
/// Xong thì hiện câu báo của controller ("Đã mở khóa…").
Future<void> showChatKeyDialog(BuildContext context, ChatController chat, {ChatKeyDialogMode? mode}) async {
  final start = mode ?? (chat.keyState == ChatKeyState.none ? ChatKeyDialogMode.setup : ChatKeyDialogMode.unlock);
  final done = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ChatKeyDialog(chat: chat, mode: start),
  );
  if (done == true && context.mounted) {
    showMessage(context, chat.takeMessage());
  }
}

/// Hộp thoại `overlay()` của thiết kế cho khóa mã hóa đầu cuối, giống hai hộp thoại "key-unlock" / "key-setup" của
/// trang Tin nhắn trên web: ô icon khóa, tiêu đề, lời giải thích, ô mật khẩu (có Hiện / Ẩn), lỗi Caption crit, nút
/// "Hủy" và nút chính (đang chạy thì "Đang mở khóa…" / "Đang tạo khóa…"). Từ "Nhập mật khẩu khôi phục" có link
/// "Quên mật khẩu? Tạo khóa mới" (hỏi lại trước vì tin cũ sẽ mất).
class ChatKeyDialog extends StatefulWidget {
  const ChatKeyDialog({super.key, required this.chat, this.mode = ChatKeyDialogMode.unlock});

  final ChatController chat;
  final ChatKeyDialogMode mode;

  static const String setupIntro =
      'Khi bật, chỉ bạn và người bạn nhắn tin đọc được tin nhắn, kể cả Senpai ơi cũng không đọc được.';
  static const String replaceIntro =
      'Khóa mới thay cho khóa cũ trên mọi máy của bạn. Tin nhắn mã hóa trước đây sẽ không đọc được nữa; tin nhắn từ '
      'nay được mã hóa bằng khóa mới.';
  static const String unlockIntro =
      'Mật khẩu khôi phục là mật khẩu bạn đặt khi bật mã hóa đầu cuối (khác mật khẩu đăng nhập). Nhập để đọc và gửi '
      'tin nhắn mã hóa trên app này; khóa được lưu an toàn trên điện thoại nên lần sau không cần nhập lại.';
  static const String remember =
      'Hãy ghi nhớ mật khẩu này: bạn cần nó để đọc tin nhắn mã hóa trên máy khác. Senpai ơi không lấy lại được mật '
      'khẩu khôi phục cho bạn.';

  @override
  State<ChatKeyDialog> createState() => _ChatKeyDialogState();
}

class _ChatKeyDialogState extends State<ChatKeyDialog> {
  final _pass = TextEditingController();
  final _again = TextEditingController();
  late ChatKeyDialogMode _mode = widget.mode;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _pass.dispose();
    _again.dispose();
    super.dispose();
  }

  bool get _unlocking => _mode == ChatKeyDialogMode.unlock;

  Future<void> _submit() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final chat = widget.chat;
    final error = _unlocking
        ? await chat.unlockKey(_pass.text)
        : await chat.createKey(_pass.text, _again.text, replace: _mode == ChatKeyDialogMode.replace);
    if (!mounted) {
      return;
    }
    if (error == null) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _busy = false;
      _error = error;
      // Bật lần đầu mà tài khoản đã có khóa (máy khác): chuyển sang nhập mật khẩu khôi phục của khóa đó
      if (_mode == ChatKeyDialogMode.setup && chat.keyState == ChatKeyState.locked) {
        _mode = ChatKeyDialogMode.unlock;
        _pass.clear();
        _again.clear();
      } else if (_unlocking && chat.keyState == ChatKeyState.none) {
        _mode = ChatKeyDialogMode.setup;
      }
    });
  }

  Future<void> _forgot() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tạo khóa mã hóa mới?'),
        content: Text(
          'Các tin nhắn mã hóa trước đây sẽ không đọc được nữa, trên mọi máy của bạn. Những người bạn nhắn tin sẽ thấy '
          'mã an toàn của bạn thay đổi.',
          style: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
          FilledButton(
            style: SenpaiButtonStyle.danger(SenpaiButtonSize.medium),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Tạo khóa mới'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() {
        _mode = ChatKeyDialogMode.replace;
        _error = null;
        _pass.clear();
        _again.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_mode) {
      ChatKeyDialogMode.unlock => 'Nhập mật khẩu khôi phục',
      ChatKeyDialogMode.setup => 'Bật mã hóa đầu cuối',
      ChatKeyDialogMode.replace => 'Tạo khóa mã hóa mới',
    };
    final intro = switch (_mode) {
      ChatKeyDialogMode.unlock => ChatKeyDialog.unlockIntro,
      ChatKeyDialogMode.setup => ChatKeyDialog.setupIntro,
      ChatKeyDialogMode.replace => ChatKeyDialog.replaceIntro,
    };
    final action = switch (_mode) {
      ChatKeyDialogMode.unlock => _busy ? 'Đang mở khóa…' : 'Mở khóa',
      ChatKeyDialogMode.setup => _busy ? 'Đang tạo khóa…' : 'Bật mã hóa',
      ChatKeyDialogMode.replace => _busy ? 'Đang tạo khóa…' : 'Tạo khóa mới',
    };
    return AlertDialog(
      icon: Center(
        child: IconTile(
          _unlocking ? Symbols.key_rounded : Symbols.lock_rounded,
          tone: _mode == ChatKeyDialogMode.replace ? SenpaiTone.crit : SenpaiTone.brand,
          size: 48,
          radius: 24,
        ),
      ),
      title: Text(title, textAlign: TextAlign.center),
      titleTextStyle: SenpaiText.titleM.copyWith(color: SenpaiColors.ink),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      content: SingleChildScrollView(
        child: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Text(intro, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
              PasswordField(
                key: ValueKey('key-pass-$_mode'),
                controller: _pass,
                label: 'Mật khẩu khôi phục',
                isNewPassword: !_unlocking,
                helperText: _unlocking ? null : 'Ít nhất 8 ký tự.',
                textInputAction: _unlocking ? TextInputAction.done : TextInputAction.next,
                onSubmitted: _unlocking ? (_) => _submit() : null,
              ),
              if (!_unlocking)
                PasswordField(
                  key: ValueKey('key-again-$_mode'),
                  controller: _again,
                  label: 'Nhập lại mật khẩu khôi phục',
                  isNewPassword: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
              if (!_unlocking) SenpaiNote(ChatKeyDialog.remember, icon: Symbols.warning_rounded, tone: SenpaiTone.warn),
              if (_error != null) Text(_error!, style: SenpaiText.caption.copyWith(color: SenpaiColors.crit)),
              if (_busy) const LinearProgressIndicator(),
              if (_unlocking)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _busy ? null : _forgot,
                    child: const Text('Quên mật khẩu? Tạo khóa mới'),
                  ),
                ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(
          style: SenpaiButtonStyle.ghost(SenpaiButtonSize.medium),
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: _mode == ChatKeyDialogMode.replace
              ? SenpaiButtonStyle.danger(SenpaiButtonSize.medium)
              : SenpaiButtonStyle.size(SenpaiButtonSize.medium),
          onPressed: _busy ? null : _submit,
          child: Text(action),
        ),
      ],
    );
  }
}
