/// Một chủ đề của câu hỏi thường gặp (bảng `faq_topics` của web), kèm số câu đang có.
///
/// JSON (`GET /api/faqs/topics`): `{code, title, count}`.
class FaqTopic {
  const FaqTopic({required this.code, required this.title, this.count = 0});

  /// Mã để lọc (`GET /api/faqs?topic=<code>`), ví dụ PREPARATION, LIVING.
  final String code;
  final String title;

  /// Số câu đã đăng trong chủ đề (khớp với từ khóa đang tìm, nếu có).
  final int count;

  factory FaqTopic.fromJson(Map<String, dynamic> json) => FaqTopic(
    code: (json['code'] ?? '') as String,
    title: (json['title'] ?? '') as String,
    count: (json['count'] ?? 0) as int,
  );
}
