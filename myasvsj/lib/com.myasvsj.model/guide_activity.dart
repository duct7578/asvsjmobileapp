/// Một cẩm nang trong "Cẩm nang của tôi": checklist đang làm dở (GuideInProgress) hoặc cẩm nang đã xong
/// (GuideDone) của `GET /api/me/guides/progress`.
///
/// JSON đang làm: `{id, title, topicName, stageCode, stageTitle, checklist, tasksDone, tasksTotal, percent, nextTask,
/// lastActivityAt}`; đã xong: `{id, title, stageCode, stageTitle, doneAt}`.
class GuideActivity {
  const GuideActivity({
    required this.id,
    required this.title,
    this.topicName,
    this.stageCode,
    this.stageTitle,
    this.tasksDone = 0,
    this.tasksTotal = 0,
    this.percent = 0,
    this.nextTask,
    this.at,
  });

  final int id;
  final String title;
  final String? topicName;

  /// null với cẩm nang không thuộc giai đoạn nào.
  final String? stageCode;
  final String? stageTitle;

  final int tasksDone;
  final int tasksTotal;

  /// 0–100.
  final int percent;

  /// Việc tiếp theo chưa tick.
  final String? nextTask;

  /// Lần tick gần nhất (đang làm) hoặc lúc xong (đã xong).
  final DateTime? at;

  factory GuideActivity.fromJson(Map<String, dynamic> json) {
    final at = json['lastActivityAt'] ?? json['doneAt'];
    return GuideActivity(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      topicName: json['topicName'] as String?,
      stageCode: json['stageCode'] as String?,
      stageTitle: json['stageTitle'] as String?,
      tasksDone: (json['tasksDone'] ?? 0) as int,
      tasksTotal: (json['tasksTotal'] ?? 0) as int,
      percent: (json['percent'] ?? 0) as int,
      nextTask: json['nextTask'] as String?,
      at: at is String ? DateTime.tryParse(at)?.toLocal() : null,
    );
  }
}
