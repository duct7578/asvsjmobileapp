/// Một lễ hội / sự kiện do Moderator đăng, ứng với một dòng của bảng `events` (EventCard của web).
///
/// JSON: `{id, title, startDate, endDate, locationName, lat, lng, costNote, coverUrl, state, daysUntil,
/// reviewYear, canReview, avgRating, reviewCount}`. Ngày là ngày Nhật Bản, dạng "2026-09-08".
class Event {
  const Event({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.locationName = '',
    this.lat,
    this.lng,
    this.costNote = '',
    this.coverUrl,
    this.state = upcoming,
    this.daysUntil = 0,
    this.reviewYear = 0,
    this.canReview = false,
    this.avgRating,
    this.reviewCount = 0,
  });

  /// Ba trạng thái server tính theo ngày Nhật Bản.
  static const String now = 'NOW';
  static const String upcoming = 'UPCOMING';
  static const String past = 'PAST';

  final int id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;

  /// Tên nơi tổ chức; server tự đặt "Vị trí trên bản đồ" / "Chưa gắn vị trí" khi Moderator bỏ trống.
  final String locationName;

  /// Tọa độ nơi tổ chức; null khi sự kiện chưa gắn vị trí.
  final double? lat;
  final double? lng;

  /// Chi phí, ví dụ "Miễn phí"; server gửi "Chưa rõ" khi bỏ trống.
  final String costNote;

  /// Ảnh bìa (`/media/…`); null khi Moderator không tải ảnh.
  final String? coverUrl;

  /// NOW (đang diễn ra), UPCOMING (sắp tới) hoặc PAST (đã qua).
  final String state;

  /// Số ngày tới lúc bắt đầu; 0 khi đang diễn ra hoặc đã qua.
  final int daysUntil;

  /// Năm của lần tổ chức này: review viết bây giờ tính cho năm đó.
  final int reviewYear;

  /// Sự kiện đã bắt đầu nên người đã đi viết review được.
  final bool canReview;

  /// Điểm trung bình (một chữ số thập phân) của review mọi năm; null khi chưa có review.
  final double? avgRating;
  final int reviewCount;

  bool get isNow => state == now;
  bool get isUpcoming => state == upcoming;
  bool get isPast => state == past;

  /// Có tọa độ để chỉ đường.
  bool get hasLocation => lat != null && lng != null;

  /// Nhãn trạng thái như web: "Đang diễn ra", "Còn 12 ngày", "Đã qua".
  String get stateLabel => switch (state) {
    now => 'Đang diễn ra',
    past => 'Đã qua',
    _ => 'Còn $daysUntil ngày',
  };

  /// Một ngày duy nhất (sự kiện trong ngày).
  bool get isOneDay => startDate == endDate;

  /// Link chỉ đường bằng Google Maps tới nơi tổ chức; null khi chưa gắn vị trí.
  Uri? get directionsUri =>
      hasLocation ? Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng') : null;

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'] as int,
    title: (json['title'] ?? '') as String,
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: DateTime.parse(json['endDate'] as String),
    locationName: (json['locationName'] ?? '') as String,
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    costNote: (json['costNote'] ?? '') as String,
    coverUrl: json['coverUrl'] as String?,
    state: (json['state'] ?? upcoming) as String,
    daysUntil: (json['daysUntil'] as num? ?? 0).toInt(),
    reviewYear: (json['reviewYear'] ?? 0) as int,
    canReview: (json['canReview'] ?? false) as bool,
    avgRating: (json['avgRating'] as num?)?.toDouble(),
    reviewCount: (json['reviewCount'] as num? ?? 0).toInt(),
  );
}
