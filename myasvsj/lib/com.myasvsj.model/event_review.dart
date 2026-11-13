import 'package:myasvsj/com.myasvsj.model/author.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';

/// Một review sự kiện, ứng với một dòng của bảng `reviews` có `event_id` (ReviewItem của web).
///
/// JSON: `{id, author, rating, content, year, status, edited, createdAt, likeCount, media, mine, liked}`.
/// Review của chính người xem trong form sửa (OwnReview) chỉ có `{id, rating, content, status, media}`.
class EventReview {
  const EventReview({
    required this.id,
    this.author,
    required this.rating,
    this.content = '',
    this.year = 0,
    this.status = published,
    this.edited = false,
    this.createdAt,
    this.likeCount = 0,
    this.media = const [],
    this.mine = false,
    this.liked = false,
  });

  /// Trạng thái review. Người khác chỉ thấy PUBLISHED; tác giả thấy thêm review của mình đang quét ảnh
  /// (PROCESSING), bị từ chối (REJECTED) hoặc đang bị ẩn vì nhiều báo cáo (HIDDEN).
  static const String published = 'PUBLISHED';
  static const String processing = 'PROCESSING';
  static const String rejected = 'REJECTED';
  static const String hidden = 'HIDDEN';

  final int id;

  /// null ở review trong form sửa (không gửi tác giả).
  final Author? author;

  /// 1 đến 5 sao.
  final int rating;
  final String content;

  /// Năm của lần tổ chức được review.
  final int year;
  final String status;

  /// Đã sửa sau khi đăng (hiện "· đã sửa").
  final bool edited;
  final DateTime? createdAt;
  final int likeCount;

  /// Ảnh / video đính kèm, theo thứ tự tác giả chọn.
  final List<MediaItem> media;

  /// Người xem là tác giả.
  final bool mine;

  /// Người xem đã bấm "Thích".
  final bool liked;

  bool get isPublished => status == published;

  /// Ảnh (bỏ video, app chỉ hiện ảnh).
  List<MediaItem> get images => [
    for (final m in media)
      if (m.isImage) m,
  ];

  /// Câu cho tác giả khi review chưa hiện với người khác; null khi review đã đăng.
  String? get statusNote => switch (status) {
    processing => 'Ảnh đang được quét. Trong lúc này chỉ bạn thấy review.',
    rejected =>
      'Review chưa được đăng vì nội dung hoặc ảnh vi phạm Quy tắc cộng đồng. '
          'Bạn có thể sửa rồi gửi lại.',
    hidden => 'Review đang bị ẩn vì có nhiều báo cáo, chờ Moderator xem xét.',
    _ => null,
  };

  EventReview copyWith({bool? liked, int? likeCount}) => EventReview(
    id: id,
    author: author,
    rating: rating,
    content: content,
    year: year,
    status: status,
    edited: edited,
    createdAt: createdAt,
    likeCount: likeCount ?? this.likeCount,
    media: media,
    mine: mine,
    liked: liked ?? this.liked,
  );

  factory EventReview.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    return EventReview(
      id: json['id'] as int,
      author: Author.tryParse(json['author']),
      rating: (json['rating'] ?? 0) as int,
      content: (json['content'] ?? '') as String,
      year: (json['year'] ?? 0) as int,
      status: (json['status'] ?? published) as String,
      edited: (json['edited'] ?? false) as bool,
      createdAt: created is String ? DateTime.tryParse(created)?.toLocal() : null,
      likeCount: (json['likeCount'] ?? 0) as int,
      media: [for (final m in (json['media'] as List?) ?? const []) MediaItem.fromJson(m as Map<String, dynamic>)],
      mine: (json['mine'] ?? false) as bool,
      liked: (json['liked'] ?? false) as bool,
    );
  }
}
