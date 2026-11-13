/// Dấu thẻ ghi nhớ của một mẫu câu sau khi thành viên trả lời hoặc bỏ đánh dấu (Marks của web), kèm câu thông báo
/// của server, ví dụ "Đã lưu: Đã thuộc.", "Đã bỏ đánh dấu.".
///
/// Không bao giờ cả hai cùng true; cả hai false là "Chưa luyện".
class PhraseMarks {
  const PhraseMarks({this.learning = false, this.learned = false, this.message = ''});

  /// "Chưa thuộc".
  final bool learning;

  /// "Đã thuộc".
  final bool learned;
  final String message;

  factory PhraseMarks.fromJson(Map<String, dynamic> json, {String message = ''}) => PhraseMarks(
    learning: (json['learning'] ?? false) as bool,
    learned: (json['learned'] ?? false) as bool,
    message: message,
  );
}
