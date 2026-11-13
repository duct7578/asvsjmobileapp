/// Một mục nội dung của cẩm nang (bảng `guide_sections`): tiêu đề, nội dung, ảnh và nguồn tham khảo tùy chọn.
///
/// JSON: `{heading, content, imageUrl, referenceUrl, imageIndex, mediaId}`.
class GuideSection {
  const GuideSection({this.heading = '', this.content = '', this.imageUrl, this.referenceUrl});

  final String heading;

  /// Nội dung có định dạng nhẹ của trình soạn web: `**đậm**`, `*nghiêng*`, `__gạch chân__`, `[chữ](https://…)`,
  /// dòng `## tiêu đề`, dòng `- ý` hoặc `1. ý`.
  final String content;

  /// Ảnh minh họa (`/media/…` hoặc địa chỉ http đầy đủ); null khi không có.
  final String? imageUrl;

  /// Link "Tài liệu tham khảo"; null khi không có.
  final String? referenceUrl;

  factory GuideSection.fromJson(Map<String, dynamic> json) => GuideSection(
    heading: (json['heading'] ?? '') as String,
    content: (json['content'] ?? '') as String,
    imageUrl: _blankToNull(json['imageUrl'] as String?),
    referenceUrl: _blankToNull(json['referenceUrl'] as String?),
  );

  static String? _blankToNull(String? value) => value == null || value.trim().isEmpty ? null : value.trim();
}
