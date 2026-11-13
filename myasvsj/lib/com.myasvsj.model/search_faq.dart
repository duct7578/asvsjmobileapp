/// Một câu hỏi thường gặp tìm được (FaqHit của `GET /api/search`).
class SearchFaq {
  const SearchFaq({required this.id, required this.question, this.answer = '', this.topicName});

  final int id;
  final String question;

  /// Đầu câu trả lời (một đoạn ngắn).
  final String answer;
  final String? topicName;

  factory SearchFaq.fromJson(Map<String, dynamic> json) => SearchFaq(
    id: json['id'] as int,
    question: (json['question'] ?? '') as String,
    answer: (json['answer'] ?? '') as String,
    topicName: json['topicName'] as String?,
  );
}
