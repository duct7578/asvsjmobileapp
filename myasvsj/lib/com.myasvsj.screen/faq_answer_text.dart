import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

/// Câu trả lời của câu hỏi thường gặp, vẽ theo định dạng nhẹ của trình soạn trên web (guide-content.js):
/// dòng `## …` là tiêu đề nhỏ, `- …` / `* …` / `1. …` là gạch đầu dòng, `**đậm**`, `__gạch chân__`, `*nghiêng*`,
/// `[chữ](https://…)` là liên kết mở bằng trình duyệt. Chữ được giữ nguyên, không bao giờ đọc như HTML.
///
/// Chữ Body/M màu ink như thân câu trả lời của màn 18, tiêu đề nhỏ Title/S, liên kết brand-text gạch chân.
class FaqAnswerText extends StatelessWidget {
  const FaqAnswerText({super.key, required this.text});

  final String text;

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
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: Text(marker.endsWith('.') ? marker : '•', style: _body.copyWith(color: SenpaiColors.brand)),
                ),
                Expanded(
                  child: Text.rich(TextSpan(children: _spans(bullet.group(2)!)), style: _body),
                ),
              ],
            ),
          ),
        );
      } else if (heading != null) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Text.rich(
              TextSpan(children: _spans(heading.group(1)!)),
              style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink),
            ),
          ),
        );
      } else if (line.trim().isEmpty) {
        blocks.add(const SizedBox(height: 8));
      } else {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text.rich(TextSpan(children: _spans(line)), style: _body),
          ),
        );
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: blocks);
  }

  /// Một dòng thành các đoạn chữ thường, đậm, gạch chân, nghiêng và liên kết.
  List<InlineSpan> _spans(String value) {
    final spans = <InlineSpan>[];
    var end = 0;
    for (final match in _inline.allMatches(value)) {
      if (match.start > end) {
        spans.add(TextSpan(text: value.substring(end, match.start)));
      }
      if (match.group(2) != null) {
        spans.add(TextSpan(text: match.group(2), style: const TextStyle(fontWeight: FontWeight.w700)));
      } else if (match.group(3) != null) {
        spans.add(TextSpan(text: match.group(3), style: const TextStyle(decoration: TextDecoration.underline)));
      } else if (match.group(4) != null) {
        spans.add(TextSpan(text: match.group(4), style: const TextStyle(fontStyle: FontStyle.italic)));
      } else {
        spans.add(_link(match.group(5)!, match.group(6)!));
      }
      end = match.end;
    }
    if (end < value.length) {
      spans.add(TextSpan(text: value.substring(end)));
    }
    return spans;
  }

  InlineSpan _link(String label, String url) {
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Semantics(
        link: true,
        child: InkWell(
          onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
          child: Text(
            label,
            style: _body.copyWith(
              color: SenpaiColors.brandText,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
              decorationColor: SenpaiColors.brandText,
            ),
          ),
        ),
      ),
    );
  }
}
