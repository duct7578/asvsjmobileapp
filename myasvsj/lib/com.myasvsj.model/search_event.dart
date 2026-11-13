/// Một sự kiện tìm được (EventCard trong `events` của `GET /api/search`).
class SearchEvent {
  const SearchEvent({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.locationName,
    this.state = 'UPCOMING',
    this.daysUntil = 0,
    this.costNote,
  });

  final int id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;

  /// null khi sự kiện chưa gắn vị trí.
  final String? locationName;

  /// NOW (đang diễn ra), UPCOMING (sắp tới) hoặc PAST (đã qua).
  final String state;

  /// Số ngày nữa thì bắt đầu.
  final int daysUntil;

  /// Ví dụ "Miễn phí".
  final String? costNote;

  factory SearchEvent.fromJson(Map<String, dynamic> json) => SearchEvent(
    id: json['id'] as int,
    title: (json['title'] ?? '') as String,
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: DateTime.parse((json['endDate'] ?? json['startDate']) as String),
    locationName: json['locationName'] as String?,
    state: (json['state'] ?? 'UPCOMING') as String,
    daysUntil: (json['daysUntil'] ?? 0) as int,
    costNote: json['costNote'] as String?,
  );
}
