import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';

/// Chữ có tô chỗ khớp với từ khóa tìm kiếm (như `markHits` của web; `hl()` của thiết kế: chữ đậm màu brand-text,
/// gạch chân): không phân biệt hoa thường, có dấu hay không dấu đều khớp ("nha o" khớp "Nhà ở"). Không có từ khóa
/// thì hiện chữ thường.
class SearchHighlight extends StatelessWidget {
  const SearchHighlight({super.key, required this.text, this.query = '', this.style, this.maxLines});

  final String text;
  final String query;
  final TextStyle? style;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final overflow = maxLines == null ? null : TextOverflow.ellipsis;
    final ranges = matchRanges(text, query);
    if (ranges.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: overflow);
    }
    const mark = TextStyle(
      fontWeight: FontWeight.w700,
      color: SenpaiColors.brandText,
      decoration: TextDecoration.underline,
      decorationColor: SenpaiColors.brandText,
    );
    final spans = <TextSpan>[];
    var at = 0;
    for (final (start, end) in ranges) {
      if (start > at) {
        spans.add(TextSpan(text: text.substring(at, start)));
      }
      spans.add(TextSpan(text: text.substring(start, end), style: mark));
      at = end;
    }
    if (at < text.length) {
      spans.add(TextSpan(text: text.substring(at)));
    }
    return Text.rich(
      TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  /// Các đoạn [start, end) của [text] khớp với [query] (đã gấp dấu và chữ hoa), không chồng nhau.
  static List<(int, int)> matchRanges(String text, String query) {
    final needle = fold(query.trim());
    if (needle.isEmpty) {
      return const [];
    }
    final haystack = fold(text);
    if (haystack.length != text.length) {
      // Vài chữ hiếm đổi độ dài khi viết thường: không tô, để không lệch vị trí
      return const [];
    }
    final ranges = <(int, int)>[];
    var from = 0;
    while (true) {
      final index = haystack.indexOf(needle, from);
      if (index < 0) {
        break;
      }
      ranges.add((index, index + needle.length));
      from = index + needle.length;
    }
    return ranges;
  }

  /// Bỏ dấu tiếng Việt và đổi sang chữ thường, giữ nguyên độ dài để vị trí khớp trùng với chữ gốc.
  static String fold(String value) {
    final out = StringBuffer();
    for (final unit in value.toLowerCase().split('')) {
      out.write(_plain[unit] ?? unit);
    }
    return out.toString();
  }

  static final Map<String, String> _plain = {
    for (final entry in const {
      'a': 'àáảãạăằắẳẵặâầấẩẫậ',
      'e': 'èéẻẽẹêềếểễệ',
      'i': 'ìíỉĩị',
      'o': 'òóỏõọôồốổỗộơờớởỡợ',
      'u': 'ùúủũụưừứửữự',
      'y': 'ỳýỷỹỵ',
      'd': 'đ',
    }.entries)
      for (final ch in entry.value.split('')) ch: entry.key,
  };
}
