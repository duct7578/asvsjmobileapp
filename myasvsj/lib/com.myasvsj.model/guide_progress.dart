import 'package:myasvsj/com.myasvsj.model/guide_preparation.dart';

/// Tiến độ của người xem với một cẩm nang (Progress của `GET /api/guides/{id}/viewer`, `POST|DELETE …/done`).
///
/// JSON: `{checklist, tasksDone, tasksTotal, percent, done, nextTask}`.
class GuideProgress {
  const GuideProgress({
    this.checklist = false,
    this.tasksDone = 0,
    this.tasksTotal = 0,
    this.percent = 0,
    this.done = false,
    this.nextTask,
  });

  /// Cẩm nang có checklist: xong khi tick hết; không có thì xong khi bấm "Đánh dấu đã xong".
  final bool checklist;
  final int tasksDone;
  final int tasksTotal;

  /// 0–100.
  final int percent;
  final bool done;

  /// Việc đầu tiên chưa tick; null khi không có checklist hoặc đã tick hết.
  final String? nextTask;

  /// Tiến độ suy ra từ checklist vừa tải hoặc vừa tick (như sự kiện "guide-progress" của web).
  factory GuideProgress.fromPreparation(GuidePreparation preparation) {
    String? next;
    for (final task in preparation.tasks) {
      if (!task.completed) {
        next = task.title;
        break;
      }
    }
    return GuideProgress(
      checklist: preparation.total > 0,
      tasksDone: preparation.completed,
      tasksTotal: preparation.total,
      percent: preparation.percent,
      done: preparation.total > 0 && preparation.completed == preparation.total,
      nextTask: next,
    );
  }

  factory GuideProgress.fromJson(Map<String, dynamic> json) => GuideProgress(
    checklist: (json['checklist'] ?? false) as bool,
    tasksDone: (json['tasksDone'] ?? 0) as int,
    tasksTotal: (json['tasksTotal'] ?? 0) as int,
    percent: (json['percent'] ?? 0) as int,
    done: (json['done'] ?? false) as bool,
    nextTask: json['nextTask'] as String?,
  );
}
