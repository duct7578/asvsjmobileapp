import 'package:myasvsj/com.myasvsj.model/author.dart';

/// Một câu trả lời cho câu hỏi, hoặc một phản hồi lồng dưới câu trả lời (`comments` của web, CommentNode trong JSON).
///
/// JSON: `{id, parentId, author, content, edited, removed, best, mine, liked, likeCount, createdAt, replies: [...]}`.
/// Câu trả lời trực tiếp có `parentId` null; server xếp "Câu trả lời hay nhất" lên đầu.
class Answer {
  const Answer({
    required this.id,
    this.parentId,
    this.author,
    this.content = '',
    this.edited = false,
    this.removed = false,
    this.best = false,
    this.isMine = false,
    this.liked = false,
    this.likeCount = 0,
    this.createdAt,
    this.replies = const [],
  });

  final int id;

  /// null với câu trả lời trực tiếp; id câu trả lời cha với phản hồi lồng.
  final int? parentId;

  /// null khi tài khoản người viết không còn.
  final Author? author;
  final String content;

  /// Người viết đã sửa ("· đã sửa").
  final bool edited;

  /// Đã bị xóa nhưng còn phản hồi bên dưới: chỉ hiện dòng "Bình luận đã bị xóa.".
  final bool removed;

  /// Người hỏi đã chọn là "Câu trả lời hay nhất".
  final bool best;

  /// Người đang xem là người viết, nên được sửa và xóa (không thích, không báo cáo được).
  final bool isMine;
  final bool liked;
  final int likeCount;
  final DateTime? createdAt;
  final List<Answer> replies;

  factory Answer.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    return Answer(
      id: json['id'] as int,
      parentId: json['parentId'] as int?,
      author: Author.tryParse(json['author']),
      content: (json['content'] ?? '') as String,
      edited: (json['edited'] ?? false) as bool,
      removed: (json['removed'] ?? false) as bool,
      best: (json['best'] ?? false) as bool,
      isMine: (json['mine'] ?? false) as bool,
      liked: (json['liked'] ?? false) as bool,
      likeCount: (json['likeCount'] ?? 0) as int,
      createdAt: created is String ? DateTime.tryParse(created)?.toLocal() : null,
      replies: listFrom(json['replies']),
    );
  }

  /// Cây câu trả lời trong JSON (`comments` của câu hỏi, `replies` của một câu trả lời).
  static List<Answer> listFrom(Object? json) => [
    for (final item in (json as List?) ?? const []) Answer.fromJson(item as Map<String, dynamic>),
  ];

  Answer copyWith({bool? liked, int? likeCount, List<Answer>? replies}) => Answer(
    id: id,
    parentId: parentId,
    author: author,
    content: content,
    edited: edited,
    removed: removed,
    best: best,
    isMine: isMine,
    liked: liked ?? this.liked,
    likeCount: likeCount ?? this.likeCount,
    createdAt: createdAt,
    replies: replies ?? this.replies,
  );

  /// Tìm câu trả lời [id] ở mọi tầng của cây; null khi không có.
  static Answer? find(List<Answer> nodes, int id) {
    for (final node in nodes) {
      if (node.id == id) {
        return node;
      }
      final found = find(node.replies, id);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  /// Cây mới trong đó câu trả lời [id] được thay bằng `change(câu cũ)`; các nút khác giữ nguyên.
  static List<Answer> replace(List<Answer> nodes, int id, Answer Function(Answer old) change) => [
    for (final node in nodes) node.id == id ? change(node) : node.copyWith(replies: replace(node.replies, id, change)),
  ];
}
