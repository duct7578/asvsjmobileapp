import 'package:myasvsj/com.myasvsj.model/answer.dart';
import 'package:myasvsj/com.myasvsj.model/author.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.model/report_reason.dart';
import 'package:myasvsj/com.myasvsj.model/topic.dart';

/// Một câu hỏi của Hỏi-Đáp: dòng của bảng `blogs` có `blog_type = 'QA'` trong database của web.
///
/// Đọc từ ba dạng JSON của server:
/// - thẻ danh sách (QuestionCard của `GET /api/questions`): có `excerpt`, `solved`, `unanswered`, `answerCount`;
/// - chi tiết (BlogDetail của `GET /api/questions/{id}`): có `content`, `media`, `viewer`, `comments`, `reportReasons`;
/// - form sửa (EditData của `GET /api/questions/{id}/edit`), xem [Question.fromEditJson].
class Question {
  const Question({
    this.id,
    required this.title,
    this.content = '',
    this.status = 'PUBLISHED',
    this.pinned = false,
    this.solved = false,
    this.unanswered = false,
    this.edited = false,
    this.author,
    this.topics = const [],
    this.topicIds = const [],
    this.places = const [],
    this.media = const [],
    this.likeCount = 0,
    this.answerCount = 0,
    this.bestAnswerId,
    this.createdAt,
    this.signedIn = false,
    this.isMine = false,
    this.canInteract = false,
    this.liked = false,
    this.saved = false,
    this.answers = const [],
    this.reportReasons = const [],
  });

  /// null khi câu hỏi chưa lưu.
  final int? id;

  /// Câu hỏi (tiêu đề), tối đa 150 ký tự.
  final String title;

  /// Mô tả chi tiết (không bắt buộc). Ở danh sách server chỉ gửi đoạn trích.
  final String content;

  /// PUBLISHED; PROCESSING (ảnh đang được quét), HIDDEN, REJECTED chỉ người hỏi thấy.
  final String status;
  final bool pinned;

  /// Người hỏi đã chọn câu trả lời hay nhất ("Đã giải quyết").
  final bool solved;

  /// "Chưa ai trả lời" theo luật của server (phản hồi lồng hay câu trả lời bị ẩn không tính).
  final bool unanswered;

  /// Người hỏi đã sửa ("· đã sửa").
  final bool edited;

  /// null khi tài khoản người hỏi không còn.
  final Author? author;
  final List<Topic> topics;

  /// Chủ đề đã chọn (1–3), gửi lên khi đặt hoặc sửa câu hỏi.
  final List<int> topicIds;

  /// Địa điểm liên quan đã gắn. Khi sửa phải gửi lại id, vì server bỏ địa điểm không có trong danh sách.
  final List<({int id, String name})> places;

  /// Ảnh (và video) đã đính kèm.
  final List<MediaItem> media;
  final int likeCount;

  /// Số câu trả lời và phản hồi (`answerCount` ở danh sách, `commentCount` ở chi tiết).
  final int answerCount;

  /// Câu trả lời hay nhất; null khi chưa chọn.
  final int? bestAnswerId;
  final DateTime? createdAt;

  // ----- Những gì người đang xem được làm (`viewer` của chi tiết)
  final bool signedIn;

  /// Người đang xem là người hỏi: được sửa, xóa, chọn câu trả lời hay nhất.
  final bool isMine;

  /// Đã đăng nhập bằng tài khoản User và câu hỏi đã đăng: được thích, lưu, trả lời, báo cáo.
  final bool canInteract;
  final bool liked;
  final bool saved;

  /// Câu trả lời (cây, câu hay nhất ở đầu).
  final List<Answer> answers;
  final List<ReportReason> reportReasons;

  bool get isPublished => status == 'PUBLISHED';

  /// Đã giải quyết: thẻ danh sách gửi `solved`, chi tiết gửi `bestCommentId`.
  bool get isSolved => solved || bestAnswerId != null;

  /// Ảnh để hiện (app không phát video).
  List<MediaItem> get images => [
    for (final m in media)
      if (m.isImage) m,
  ];

  /// Câu hỏi trong danh sách hoặc ở màn chi tiết.
  factory Question.fromJson(Map<String, dynamic> json) {
    final topics = [for (final t in (json['topics'] as List?) ?? const []) Topic.fromJson(t as Map<String, dynamic>)];
    final viewer = json['viewer'] as Map<String, dynamic>?;
    final created = json['createdAt'];
    final best = json['bestCommentId'] as int?;
    return Question(
      id: json['id'] as int?,
      title: (json['title'] ?? '') as String,
      content: (json['content'] ?? json['excerpt'] ?? '') as String,
      status: (json['status'] ?? 'PUBLISHED') as String,
      pinned: (json['pinned'] ?? false) as bool,
      solved: (json['solved'] ?? best != null) as bool,
      unanswered: (json['unanswered'] ?? false) as bool,
      edited: (json['edited'] ?? false) as bool,
      author: Author.tryParse(json['author']),
      topics: topics,
      topicIds: [for (final t in topics) t.id],
      places: placesFrom(json['places']),
      media: [for (final m in (json['media'] as List?) ?? const []) MediaItem.fromJson(m as Map<String, dynamic>)],
      likeCount: (json['likeCount'] ?? 0) as int,
      answerCount: (json['answerCount'] ?? json['commentCount'] ?? 0) as int,
      bestAnswerId: best,
      createdAt: created is String ? DateTime.tryParse(created)?.toLocal() : null,
      signedIn: (viewer?['signedIn'] ?? false) as bool,
      isMine: (viewer?['author'] ?? false) as bool,
      canInteract: (viewer?['canInteract'] ?? false) as bool,
      liked: (viewer?['liked'] ?? false) as bool,
      saved: (viewer?['saved'] ?? false) as bool,
      answers: Answer.listFrom(json['comments']),
      reportReasons: ReportReason.listFrom(json['reportReasons']),
    );
  }

  /// Câu hỏi như đang lưu, cho form "Sửa câu hỏi" (EditData của `GET /api/questions/{id}/edit`).
  factory Question.fromEditJson(Map<String, dynamic> json) => Question(
    id: json['id'] as int,
    title: (json['title'] ?? '') as String,
    content: (json['content'] ?? '') as String,
    status: (json['status'] ?? 'PUBLISHED') as String,
    topicIds: [for (final id in (json['topicIds'] as List?) ?? const []) id as int],
    places: placesFrom(json['places']),
    media: [for (final m in (json['media'] as List?) ?? const []) MediaItem.fromJson(m as Map<String, dynamic>)],
    isMine: true,
  );

  /// Địa điểm (PlaceRef `{id, name, …}`); bỏ địa điểm thiếu id.
  static List<({int id, String name})> placesFrom(Object? json) => [
    for (final p in (json as List?) ?? const [])
      if (p is Map<String, dynamic> && p['id'] is int) (id: p['id'] as int, name: (p['name'] ?? '') as String),
  ];

  /// Phần JSON "question" gửi lên `POST /api/questions` (CreateRequest) và `PUT /api/questions/{id}` (UpdateRequest).
  /// Khi sửa, [keepMediaIds] là ảnh đã gắn muốn giữ (theo thứ tự); ảnh không có trong danh sách bị gỡ.
  Map<String, dynamic> toJson({List<int> keepMediaIds = const []}) => {
    'title': title,
    'content': content,
    'topicIds': topicIds,
    'placeIds': [for (final p in places) p.id],
    'externalPlaceIds': const <String>[],
    if (id != null) 'keepMediaIds': keepMediaIds,
  };

  /// Bản sao đổi vài trường, cho cập nhật lạc quan (thích, lưu) và thay cây câu trả lời.
  Question copyWith({bool? liked, int? likeCount, bool? saved, List<Answer>? answers}) => Question(
    id: id,
    title: title,
    content: content,
    status: status,
    pinned: pinned,
    solved: solved,
    unanswered: unanswered,
    edited: edited,
    author: author,
    topics: topics,
    topicIds: topicIds,
    places: places,
    media: media,
    likeCount: likeCount ?? this.likeCount,
    answerCount: answerCount,
    bestAnswerId: bestAnswerId,
    createdAt: createdAt,
    signedIn: signedIn,
    isMine: isMine,
    canInteract: canInteract,
    liked: liked ?? this.liked,
    saved: saved ?? this.saved,
    answers: answers ?? this.answers,
    reportReasons: reportReasons,
  );

  /// Thẻ danh sách cập nhật theo chi tiết mới nhất (số thích, số trả lời, đã giải quyết).
  Question withCountsOf(Question detail) => Question(
    id: id,
    title: title,
    content: content,
    status: status,
    pinned: pinned,
    solved: detail.isSolved,
    unanswered: unanswered && detail.answerCount == 0,
    edited: edited,
    author: author,
    topics: topics,
    topicIds: topicIds,
    places: places,
    media: media,
    likeCount: detail.likeCount,
    answerCount: detail.answerCount,
    bestAnswerId: bestAnswerId,
    createdAt: createdAt,
  );
}
