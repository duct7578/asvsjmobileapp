/// Một cẩm nang trong "Cẩm nang cho giai đoạn …" của "Dành cho bạn" (GuideCard của `GET /api/me/home`).
class HomeGuideCard {
  const HomeGuideCard({
    required this.id,
    required this.title,
    this.topicName,
    this.excerpt,
    this.checklist = false,
    this.tasksDone = 0,
    this.tasksTotal = 0,
    this.percent = 0,
    this.nextTask,
    this.inProgress = false,
  });

  final int id;
  final String title;
  final String? topicName;

  /// Đầu phần tóm tắt; null khi cẩm nang không có tóm tắt.
  final String? excerpt;

  /// Có danh sách việc cần làm; khi đó có [tasksDone] / [tasksTotal], [percent] và [nextTask].
  final bool checklist;
  final int tasksDone;
  final int tasksTotal;

  /// 0–100.
  final int percent;
  final String? nextTask;

  /// Đã đánh dấu một vài việc nhưng chưa xong ("Đang làm dở").
  final bool inProgress;

  factory HomeGuideCard.fromJson(Map<String, dynamic> json) => HomeGuideCard(
    id: json['id'] as int,
    title: (json['title'] ?? '') as String,
    topicName: json['topicName'] as String?,
    excerpt: json['excerpt'] as String?,
    checklist: (json['checklist'] ?? false) as bool,
    tasksDone: (json['tasksDone'] ?? 0) as int,
    tasksTotal: (json['tasksTotal'] ?? 0) as int,
    percent: (json['percent'] ?? 0) as int,
    nextTask: json['nextTask'] as String?,
    inProgress: (json['inProgress'] ?? false) as bool,
  );
}
