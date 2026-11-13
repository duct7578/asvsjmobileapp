import 'package:myasvsj/com.myasvsj.model/author.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';

/// Một review trong danh sách review của địa điểm (`GET /api/map/places/{id}/reviews`), ứng với bảng `reviews`.
///
/// JSON: `{id, author: {id, displayName, avatarUrl, tags, rank, roleLabel}, rating, content, media, createdAt,
/// edited, status, likeCount, liked, mine, helpful}`.
class PlaceReview {
  const PlaceReview({
    required this.id,
    required this.author,
    this.authorRoleLabel = '',
    required this.rating,
    required this.content,
    this.media = const [],
    this.createdAt,
    this.edited = false,
    this.status = 'PUBLISHED',
    this.likeCount = 0,
    this.liked = false,
    this.mine = false,
    this.helpful = false,
  });

  /// Review "Hữu ích" khi có hơn 10 lượt thích (giống server).
  static const int helpfulLikes = 10;

  final int id;
  final Author author;

  /// Nhãn vai trò khi tác giả là staff, ví dụ "Moderator"; rỗng với User.
  final String authorRoleLabel;

  /// 1–5 sao.
  final int rating;
  final String content;
  final List<MediaItem> media;
  final DateTime? createdAt;
  final bool edited;

  /// PUBLISHED, hoặc PROCESSING khi ảnh của review của mình đang được quét.
  final String status;
  final int likeCount;
  final bool liked;

  /// Review của chính người xem (được Sửa / Xóa, không được thích, báo cáo).
  final bool mine;
  final bool helpful;

  bool get isPublished => status == 'PUBLISHED';
  bool get isProcessing => status == 'PROCESSING';

  /// Ảnh (bỏ video, app chỉ hiện ảnh).
  List<MediaItem> get images => [
    for (final m in media)
      if (m.isImage) m,
  ];

  /// Review trong 30 ngày qua: "Còn mới".
  bool isFresh(DateTime now) => createdAt != null && now.difference(createdAt!).inDays <= 30;

  /// Review hơn 1 năm: "Hơn 1 năm, cần xác minh lại".
  bool isOld(DateTime now) => createdAt != null && now.difference(createdAt!).inDays > 365;

  PlaceReview copyWith({bool? liked, int? likeCount}) {
    final count = likeCount ?? this.likeCount;
    return PlaceReview(
      id: id,
      author: author,
      authorRoleLabel: authorRoleLabel,
      rating: rating,
      content: content,
      media: media,
      createdAt: createdAt,
      edited: edited,
      status: status,
      likeCount: count,
      liked: liked ?? this.liked,
      mine: mine,
      helpful: count > helpfulLikes,
    );
  }

  factory PlaceReview.fromJson(Map<String, dynamic> json) {
    final author = (json['author'] as Map<String, dynamic>?) ?? const {};
    final created = json['createdAt'];
    return PlaceReview(
      id: json['id'] as int,
      // Tác giả của review trên bản đồ gửi cấp bậc trong `rank` (không phải `rankName`) và id null khi tài khoản đã xóa
      author: Author(
        id: (author['id'] ?? 0) as int,
        displayName: (author['displayName'] ?? '') as String,
        tagNames: [
          for (final tag in (author['tags'] as List?) ?? const [])
            if (tag is Map<String, dynamic>) (tag['name'] ?? '') as String,
        ],
        rankName: (author['rank'] ?? '') as String,
      ),
      authorRoleLabel: (author['roleLabel'] ?? '') as String,
      rating: (json['rating'] ?? 0) as int,
      content: (json['content'] ?? '') as String,
      media: [for (final m in (json['media'] as List?) ?? const []) MediaItem.fromJson(m as Map<String, dynamic>)],
      createdAt: created is String ? DateTime.tryParse(created)?.toLocal() : null,
      edited: (json['edited'] ?? false) as bool,
      status: (json['status'] ?? 'PUBLISHED') as String,
      likeCount: (json['likeCount'] ?? 0) as int,
      liked: (json['liked'] ?? false) as bool,
      mine: (json['mine'] ?? false) as bool,
      helpful: (json['helpful'] ?? false) as bool,
    );
  }
}
