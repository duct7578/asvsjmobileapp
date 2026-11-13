import 'package:myasvsj/com.myasvsj.model/phrase_group.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_marks.dart';

/// Một mẫu câu hoặc từ vựng tiếng Nhật (bảng `phrases`, PhraseCard của web), do Biên tập viên nội dung tiếng Nhật
/// biên soạn. Thuộc đúng một loại địa điểm và có thể thuộc nhiều chủ đề.
class Phrase {
  const Phrase({
    required this.id,
    required this.kind,
    required this.japanese,
    this.romaji = '',
    this.meaningVi = '',
    this.category = const PhraseGroup(id: '', name: ''),
    this.topics = const [],
    this.learning = false,
    this.learned = false,
  });

  /// Hai loại mục: "Mẫu câu" và "Từ vựng".
  static const String phraseKind = 'PHRASE';
  static const String vocabKind = 'VOCAB';

  /// Thứ tự trang Nhật ngữ hiện hai loại: Từ vựng, rồi Mẫu câu.
  static const List<String> kinds = [vocabKind, phraseKind];

  /// Bộ lọc theo mức thuộc của thành viên ("" = tất cả): khóa → tên trên giao diện.
  static const Map<String, String> statusNames = {'learning': 'Chưa thuộc', 'learned': 'Đã thuộc', 'new': 'Chưa luyện'};

  static String kindName(String kind) => kind == vocabKind ? 'Từ vựng' : 'Mẫu câu';

  final int id;

  /// [phraseKind] hoặc [vocabKind].
  final String kind;
  final String japanese;

  /// Có thể rỗng.
  final String romaji;
  final String meaningVi;
  final PhraseGroup category;
  final List<PhraseGroup> topics;

  /// Câu trả lời thẻ ghi nhớ gần nhất của thành viên: "Chưa thuộc" / "Đã thuộc"; cả hai false là chưa luyện.
  final bool learning;
  final bool learned;

  bool get isPhrase => kind == phraseKind;

  /// "Chưa luyện": chưa trả lời thẻ nào.
  bool get isNew => !learning && !learned;

  /// Qua bộ lọc mức thuộc [status] ("" = tất cả, learning, learned, new).
  bool hasStatus(String status) => switch (status) {
    'learning' => learning,
    'learned' => learned,
    'new' => isNew,
    _ => true,
  };

  /// Thuộc chủ đề ([by] = "topic") hoặc loại địa điểm ([by] = "category") có mã [id].
  bool inGroup(String by, String id) => by == 'topic' ? topics.any((t) => t.id == id) : category.id == id;

  /// Cùng mục với dấu mới.
  Phrase withMarks(PhraseMarks marks) => Phrase(
    id: id,
    kind: kind,
    japanese: japanese,
    romaji: romaji,
    meaningVi: meaningVi,
    category: category,
    topics: topics,
    learning: marks.learning,
    learned: marks.learned,
  );

  factory Phrase.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    return Phrase(
      id: json['id'] as int,
      kind: (json['kind'] ?? phraseKind) as String,
      japanese: (json['japanese'] ?? '') as String,
      romaji: (json['romaji'] ?? '') as String,
      meaningVi: (json['meaningVi'] ?? '') as String,
      category: category == null ? const PhraseGroup(id: '', name: '') : PhraseGroup.fromJson(category),
      topics: PhraseGroup.listFrom(json['topics']),
      learning: (json['learning'] ?? false) as bool,
      learned: (json['learned'] ?? false) as bool,
    );
  }
}
