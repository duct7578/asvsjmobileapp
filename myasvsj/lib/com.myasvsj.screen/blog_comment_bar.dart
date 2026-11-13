import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

/// Ô viết bình luận ở cuối màn chi tiết bài (`bottomBar` + `composer(hint)` của thiết kế): thanh trắng có bóng Bar,
/// ô viên thuốc nền surface-2 cao 48 và nút gửi tròn brand 40.
///
/// Khi đang trả lời một bình luận, hiện "Đang trả lời Tên" có nút hủy. Lỗi của server (ví dụ "Bạn bình luận hơi
/// nhanh…") hiện ngay dưới ô, chữ đang viết vẫn được giữ.
class BlogCommentBar extends StatelessWidget {
  const BlogCommentBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSend,
    required this.onCancelReply,
    this.replyName,
    this.isSending = false,
    this.error,
    this.maxLength = 2000,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onCancelReply;

  /// Tên người được trả lời; null khi viết bình luận mới.
  final String? replyName;
  final bool isSending;
  final String? error;
  final int maxLength;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return BlogBottomPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (replyName != null)
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 6),
              child: Row(
                spacing: 6,
                children: [
                  const Icon(Symbols.reply_rounded, size: 18, color: SenpaiColors.brandText),
                  Expanded(
                    child: Text(
                      'Đang trả lời $replyName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SenpaiText.labelS.copyWith(color: SenpaiColors.brandText),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hủy trả lời',
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(foregroundColor: SenpaiColors.muted),
                    icon: const Icon(Symbols.close_rounded, size: 18),
                    onPressed: onCancelReply,
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
            decoration: BoxDecoration(color: SenpaiColors.surface2, borderRadius: BorderRadius.circular(24)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 8,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: maxLength,
                    onChanged: onChanged,
                    textCapitalization: TextCapitalization.sentences,
                    style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
                    decoration: InputDecoration(
                      hintText: replyName != null
                          ? 'Viết câu trả lời cho bình luận này'
                          : 'Chia sẻ thêm kinh nghiệm hoặc góp ý',
                      hintStyle: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
                      hintMaxLines: 1,
                      counterText: '',
                      isDense: true,
                      filled: false,
                      contentPadding: const EdgeInsets.symmetric(vertical: 9),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Gửi bình luận',
                  onPressed: isSending ? null : onSend,
                  style: IconButton.styleFrom(
                    backgroundColor: SenpaiColors.brand,
                    disabledBackgroundColor: SenpaiColors.brand,
                    foregroundColor: SenpaiColors.onBrand,
                    disabledForegroundColor: SenpaiColors.onBrand,
                    fixedSize: const Size(40, 40),
                    minimumSize: const Size(40, 40),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: SenpaiColors.onBrand),
                        )
                      : const Icon(Symbols.send_rounded, size: 20),
                ),
              ],
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Text(error!, maxLines: 3, style: SenpaiText.caption.copyWith(color: SenpaiColors.crit)),
            ),
        ],
      ),
    );
  }
}

/// Thanh dính đáy màn hình của thiết kế (`bottomBar`): nền trắng, bóng Bar, lề [12,16,12+đáy máy,16].
/// Giống SenpaiBottomBar nhưng nhận một [child] bất kỳ (ô bình luận nhiều dòng, câu mời đăng nhập).
class BlogBottomPanel extends StatelessWidget {
  const BlogBottomPanel({super.key, required this.child});

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
