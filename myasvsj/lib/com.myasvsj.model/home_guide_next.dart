/// Cẩm nang nên mở tiếp trong thẻ "Việc tiếp theo" (GuideNext của `GET /api/me/home`).
class HomeGuideNext {
  const HomeGuideNext({
    required this.guideId,
    required this.title,
    this.dueNote,
    this.placeName,
    this.placeId,
    this.checklist = false,
    this.tasksDone = 0,
    this.tasksTotal = 0,
    this.nextTask,
  });

  final int guideId;
  final String title;

  /// Ghi chú hạn, ví dụ "Trong 14 ngày"; null khi không có.
  final String? dueNote;

  /// Địa điểm của cẩm nang (mở chi tiết địa điểm); null khi không có hoặc đã đóng.
  final String? placeName;
  final int? placeId;

  /// Cẩm nang có "Hướng dẫn chuẩn bị" (danh sách việc cần làm).
  final bool checklist;
  final int tasksDone;
  final int tasksTotal;

  /// Việc đầu tiên chưa đánh dấu; chỉ có với cẩm nang có danh sách việc.
  final String? nextTask;

  static HomeGuideNext? tryParse(Object? json) => json is Map<String, dynamic> ? HomeGuideNext.fromJson(json) : null;

  factory HomeGuideNext.fromJson(Map<String, dynamic> json) => HomeGuideNext(
    guideId: json['guideId'] as int,
    title: (json['title'] ?? '') as String,
    dueNote: json['dueNote'] as String?,
    placeName: json['placeName'] as String?,
    placeId: json['placeId'] as int?,
    checklist: (json['checklist'] ?? false) as bool,
    tasksDone: (json['tasksDone'] ?? 0) as int,
    tasksTotal: (json['tasksTotal'] ?? 0) as int,
    nextTask: json['nextTask'] as String?,
  );
}
