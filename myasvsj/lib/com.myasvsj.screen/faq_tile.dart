import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:myasvsj/com.myasvsj.model/faq_entry.dart';
import 'package:myasvsj/com.myasvsj.model/faq_resource.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/faq_answer_text.dart';
import 'package:myasvsj/com.myasvsj.screen/faq_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Một câu hỏi thường gặp mở rộng tại chỗ (giống `faqItem` của web): câu hỏi và chủ đề; bấm vào hiện câu trả lời,
/// các liên kết "Xem thêm", ngày cập nhật và "Mở riêng câu này".
///
/// Kiểu `FaqTile` của màn 18: thẻ trắng bo 16 lề 14, ô icon quiz 36 (neutral; brand khi mở), câu hỏi Title/S,
/// chủ đề Caption, expand_more. Khi mở: viền brand, bo 18, đường kẻ rồi câu trả lời.
///
/// [compact]: kiểu `faqMini` (ô trắng bo 12 lề [10,12], câu hỏi Label/M, chevron) dùng trong hộp gợi ý của form
/// đặt câu hỏi và phần FAQ liên quan trên kết quả tìm câu hỏi.
///
/// Dùng ở tab "Câu hỏi thường gặp", màn FaqScreen, phần FAQ liên quan trên kết quả tìm câu hỏi và gợi ý khi đặt câu
/// hỏi.
class FaqTile extends StatefulWidget {
  const FaqTile({
    super.key,
    required this.entry,
    this.initiallyExpanded = false,
    this.showOpenLink = true,
    this.compact = false,
  });

  final FaqEntry entry;
  final bool initiallyExpanded;

  /// Hiện nút "Mở riêng câu này" (ẩn khi câu đã đang được mở riêng).
  final bool showOpenLink;

  /// Kiểu nhỏ `faqMini` đặt trong hộp màu.
  final bool compact;

  @override
  State<FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<FaqTile> {
  late bool _open;

  /// Khóa lưu trạng thái mở trong PageStorage của trang: cuộn khỏi màn hình rồi quay lại vẫn giữ.
  String get _storageId => 'faq-${widget.entry.id}${widget.compact ? '-mini' : ''}';

  @override
  void initState() {
    super.initState();
    final saved = PageStorage.maybeOf(context)?.readState(context, identifier: _storageId);
    _open = saved is bool ? saved : widget.initiallyExpanded;
  }

  void _toggle() {
    setState(() => _open = !_open);
    PageStorage.maybeOf(context)?.writeState(context, _open, identifier: _storageId);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final compact = widget.compact;
    final header = Semantics(
      button: true,
      expanded: _open,
      child: InkWell(
        onTap: _toggle,
        child: Padding(
          padding: compact
              ? EdgeInsets.fromLTRB(12, 10, 12, _open ? 8 : 10)
              : EdgeInsets.fromLTRB(14, 14, 14, _open ? 10 : 14),
          child: Row(
            spacing: compact ? 8 : 12,
            children: [
              if (!compact)
                IconTile(Symbols.quiz_rounded, tone: _open ? SenpaiTone.brand : SenpaiTone.neutral, size: 36, radius: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.question,
                      style: (compact ? SenpaiText.labelM : SenpaiText.titleS).copyWith(color: SenpaiColors.ink),
                    ),
                    if (entry.topicName.isNotEmpty)
                      Text(entry.topicName, style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
                  ],
                ),
              ),
              if (compact)
                AnimatedRotation(
                  turns: _open ? 0.25 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(Symbols.chevron_right_rounded, size: 20, color: SenpaiColors.muted),
                )
              else
                Icon(_open ? Symbols.expand_less_rounded : Symbols.expand_more_rounded, size: 24, color: SenpaiColors.muted),
            ],
          ),
        ),
      ),
    );
    final radius = BorderRadius.circular(compact ? 12 : (_open ? 18 : 16));
    // Hộp trắng có viền (gợn sóng của dòng câu hỏi cắt theo góc bo)
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SenpaiColors.surface,
        borderRadius: radius,
        border: compact ? null : Border.all(color: _open ? SenpaiColors.brand : SenpaiColors.line),
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                header,
                if (_open) _answer(context, entry),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Câu trả lời, "Xem thêm", ngày cập nhật và "Mở riêng câu này".
  Widget _answer(BuildContext context, FaqEntry entry) {
    final resources = entry.resources.where(_usable).toList();
    final side = widget.compact ? 12.0 : 14.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(side, 0, side, widget.compact ? 8 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          const Divider(height: 1),
          FaqAnswerText(text: entry.answer),
          if (resources.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text('Xem thêm', style: SenpaiText.labelS.copyWith(color: SenpaiColors.muted)),
                for (final r in resources)
                  LinkText(
                    r.label,
                    icon: r.isExternal ? Symbols.open_in_new_rounded : Symbols.link_rounded,
                    onTap: () => _openResource(context, r),
                  ),
              ],
            ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: entry.updatedAt == null
                    ? const SizedBox.shrink()
                    : Text('Cập nhật ${formatDate(entry.updatedAt!)}',
                        style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
              ),
              if (widget.showOpenLink)
                SenpaiButton(
                  label: 'Mở riêng câu này',
                  kind: SenpaiButtonKind.ghost,
                  size: SenpaiButtonSize.small,
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => FaqScreen(faqId: entry.id))),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Liên kết mở được: web chỉ hiện địa chỉ http(s) và cẩm nang / bài viết / câu hỏi có id.
  static bool _usable(FaqResource r) {
    if (r.isExternal) {
      final uri = Uri.tryParse(r.url ?? '');
      return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') && uri.host.isNotEmpty;
    }
    return r.targetId != null && const {'GUIDE', 'BLOG', 'QUESTION'}.contains(r.kind);
  }

  static void _openResource(BuildContext context, FaqResource r) {
    if (r.isExternal) {
      launchUrl(Uri.parse(r.url!), mode: LaunchMode.externalApplication);
      return;
    }
    final id = r.targetId!;
    final Widget screen = switch (r.kind) {
      'GUIDE' => GuideDetailScreen(guideId: id),
      'BLOG' => BlogDetailScreen(blogId: id),
      _ => QuestionDetailScreen(questionId: id),
    };
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
  }
}
