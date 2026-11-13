/// Sự kiện trong 2 tuần tới trên trang chủ thành viên (EventItem của `GET /api/me/home`).
class HomeEvent {
  const HomeEvent({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.locationName = '',
    this.daysUntil = 0,
  });

  final int id;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String locationName;

  /// Số ngày nữa thì bắt đầu; 0 khi sự kiện đang diễn ra hôm nay.
  final int daysUntil;

  bool get isHappening => daysUntil <= 0;

  factory HomeEvent.fromJson(Map<String, dynamic> json) => HomeEvent(
    id: json['id'] as int,
    title: (json['title'] ?? '') as String,
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: DateTime.parse((json['endDate'] ?? json['startDate']) as String),
    locationName: (json['locationName'] ?? '') as String,
    daysUntil: (json['daysUntil'] ?? 0) as int,
  );
}
