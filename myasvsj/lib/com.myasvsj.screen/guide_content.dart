import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

/// Nội dung một mục cẩm nang, với định dạng nhẹ của trình soạn web (như `guide-content.js`): dòng `## tiêu đề`,
/// dòng `- ý` / `* ý` / `1. ý`, và trong dòng `**đậm**`, `*nghiêng*`, `__gạch chân__`, `[chữ](https://…)`.
/// Chữ của server không bao giờ được hiểu là HTML.
///
/// Kiểu chữ: thân Body/M ink, tiêu đề phụ Title/S, dấu đầu dòng brand, link brand-text gạch chân.
class GuideContent extends StatelessWidget {
  const GuideContent({super.key, required this.text, this.onOpenLink});

  final String text;

  /// Bấm vào một link trong nội dung; null thì link chỉ hiện như chữ.
  final ValueChanged<String>? onOpenLink;

  static final RegExp _bullet = RegExp(r'^\s*([-*]|\d+\.)\s+(.*)$');
  static final RegExp _heading = RegExp(r'^##\s+(.*)$');
  static final RegExp _inline = RegExp(r'(\*\*([^*]+)\*\*|__([^_]+)__|\*([^*]+)\*|\[([^\]]+)\]\((https?://[^\s)]+)\))');

  static final TextStyle _body = SenpaiText.bodyM.copyWith(color: SenpaiColors.ink);

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];
    for (final line in text.split('\n')) {
      final bullet = _bullet.firstMatch(line);
      final heading = _heading.firstMatch(line);
      if (bullet != null) {
        final marker = bullet.group(1)!;
        final dot = marker == '-' || marker == '*';
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    dot ? '•' : marker,
                    style: dot
                        ? _body.copyWith(color: SenpaiColors.brand)
                        : SenpaiText.labelM.copyWith(color: SenpaiColors.brandText, height: 22 / 14),
                  ),
                ),
                Expanded(child: Text.rich(TextSpan(children: _spans(context, bullet.group(2)!)), style: _body)),
              ],
            ),
          ),
        );
      } else if (heading != null) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text.rich(
              TextSpan(children: _spans(context, heading.group(1)!)),
              style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink),
            ),
          ),
        );
      } else if (line.trim().isEmpty) {
        blocks.add(const SizedBox(height: 8));
      } else {
        blocks.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text.rich(TextSpan(children: _spans(context, line)), style: _body),
          ),
        );
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: blocks);
  }

  /// Một dòng thành các đoạn chữ thường / đậm / nghiêng / gạch chân / link.
  List<InlineSpan> _spans(BuildContext context, String line) {
    final spans = <InlineSpan>[];
    var end = 0;
    for (final match in _inline.allMatches(line)) {
      if (match.start > end) {
        spans.add(TextSpan(text: line.substring(end, match.start)));
      }
      if (match.group(2) != null) {
        spans.add(TextSpan(text: match.group(2), style: const TextStyle(fontWeight: FontWeight.w700)));
      } else if (match.group(3) != null) {
        spans.add(TextSpan(text: match.group(3), style: const TextStyle(decoration: TextDecoration.underline)));
      } else if (match.group(4) != null) {
        spans.add(TextSpan(text: match.group(4), style: const TextStyle(fontStyle: FontStyle.italic)));
      } else {
        spans.add(_link(context, match.group(5)!, match.group(6)!));
      }
      end = match.end;
    }
    if (end < line.length) {
      spans.add(TextSpan(text: line.substring(end)));
    }
    return spans;
  }

  InlineSpan _link(BuildContext context, String label, String url) {
    final style = _body.copyWith(
      color: SenpaiColors.brandText,
      decoration: TextDecoration.underline,
      decorationColor: SenpaiColors.brandText,
    );
    final open = onOpenLink;
    if (open == null) {
      return TextSpan(text: label, style: style);
    }
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: InkWell(onTap: () => open(url), child: Text(label, style: style)),
    );
  }
}
