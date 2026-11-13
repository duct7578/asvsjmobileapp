/// Một thông báo của người đang đăng nhập, ứng với một dòng của bảng `notifications` (NotificationItem của web).
///
/// JSON: `{id, type, content, link, read, createdAt}`.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.content,
    this.link,
    this.read = false,
    this.createdAt,
  });

  final int id;

  /// CONTENT_PUBLISHED, CONTENT_REJECTED, NEW_COMMENT, BEST_ANSWER, TAG_GRANTED / TAG_REJECTED / TAG_EXPIRED,
  /// PIN_APPROVED / PIN_REJECTED / PIN_MERGED, PLACE_CLOSED / PLACE_UPDATED / PLACE_REMOVED / PLACE_MERGED.
  final String type;

  /// Câu thông báo của server, ví dụ "Trần Minh đã bình luận bài “…” của bạn.".
  final String content;

  /// Trang web mà thông báo mở (`/blog/12`, `/qa/7`, `/map?place=3`, `/events/5`). null khi bài, review, sự kiện
  /// đã bị xóa, hoặc loại thông báo không có trang riêng (tag, ghim địa điểm).
  final String? link;

  final bool read;
  final DateTime? createdAt;

  /// Thông báo về tag định danh: mở trang "Tôi" (nơi xem tag và yêu cầu tag).
  bool get isTag => type.startsWith('TAG_');

  /// Đường dẫn app mở khi bấm: [link] của server, thông báo tag mở `/profile`; null khi chỉ có nội dung để đọc.
  String? get target => link ?? (isTag ? '/profile' : null);

  /// Tiêu đề ngắn khi hiện trên máy (khay thông báo).
  String get title => switch (type) {
    'CONTENT_PUBLISHED' => 'Đã được đăng',
    'CONTENT_REJECTED' => 'Chưa được đăng',
    'NEW_COMMENT' => 'Bình luận mới',
    'BEST_ANSWER' => 'Câu trả lời hay nhất',
    _ when isTag => 'Tag định danh',
    _ when type.startsWith('PIN_') || type.startsWith('PLACE_') => 'Địa điểm',
    _ => 'Thông báo mới',
  };

  AppNotification copyWith({bool? read}) =>
      AppNotification(id: id, type: type, content: content, link: link, read: read ?? this.read, createdAt: createdAt);

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    final link = json['link'];
    return AppNotification(
      id: json['id'] as int,
      type: (json['type'] ?? '') as String,
      content: (json['content'] ?? '') as String,
      link: link is String && link.isNotEmpty ? link : null,
      read: (json['read'] ?? false) as bool,
      createdAt: created is String ? DateTime.tryParse(created)?.toLocal() : null,
    );
  }

  static List<AppNotification> listFrom(Object? json) => [
    for (final item in (json as List?) ?? const []) AppNotification.fromJson(item as Map<String, dynamic>),
  ];
}
