import 'package:myasvsj/com.myasvsj.model/faq_resource.dart';

/// Một câu hỏi thường gặp do Moderator viết (bảng `faq_entries` của web). Không thích, bình luận, báo cáo được.
///
/// JSON (Entry của `GET /api/faqs`, `/api/faqs/{id}`, `/api/faqs/related`):
/// `{id, question, answer, topicCode, topicName, published, createdAt, updatedAt, resources: [...]}`.
class FaqEntry {
  const FaqEntry({
    required this.id,
    required this.question,
    this.answer = '',
    this.topicCode = '',
    this.topicName = '',
    this.updatedAt,
    this.resources = const [],
  });

  final int id;
  final String question;

  /// Câu trả lời, định dạng nhẹ của trình soạn cẩm nang: `## tiêu đề`, `- gạch đầu dòng`, `**đậm**`, `[chữ](link)`.
  final String answer;

  /// Mã chủ đề (ví dụ LIVING) để lọc, và tên chủ đề để hiện.
  final String topicCode;
  final String topicName;
  final DateTime? updatedAt;

  /// Liên kết "Xem thêm".
  final List<FaqResource> resources;

  factory FaqEntry.fromJson(Map<String, dynamic> json) {
    final updated = json['updatedAt'];
    return FaqEntry(
      id: json['id'] as int,
      question: (json['question'] ?? '') as String,
      answer: (json['answer'] ?? '') as String,
      topicCode: (json['topicCode'] ?? '') as String,
      topicName: (json['topicName'] ?? '') as String,
      updatedAt: updated is String ? DateTime.tryParse(updated)?.toLocal() : null,
      resources: [
        for (final r in (json['resources'] as List?) ?? const []) FaqResource.fromJson(r as Map<String, dynamic>),
      ],
    );
  }
}
