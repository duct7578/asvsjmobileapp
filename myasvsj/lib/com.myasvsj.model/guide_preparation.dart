import 'package:myasvsj/com.myasvsj.model/guide_task.dart';

/// Checklist "Hướng dẫn chuẩn bị" của một cẩm nang với dấu tick của người xem
/// (Progress của `GET /api/guides/{id}/preparation` và `PUT …/preparation/{taskId}`).
///
/// JSON: `{tasks: [{id, title, notes, completed}], completed, total, percent, signedIn}`.
class GuidePreparation {
  const GuidePreparation({
    this.tasks = const [],
    this.completed = 0,
    this.total = 0,
    this.percent = 0,
    this.signedIn = false,
  });

  final List<GuideTask> tasks;

  /// Số việc đã tick trên [total] việc; [percent] làm tròn xuống như server.
  final int completed;
  final int total;
  final int percent;

  /// Người xem đã đăng nhập nên dấu tick được lưu trên server.
  final bool signedIn;

  /// Checklist sau khi tick / bỏ tick một việc, tính lại số việc và phần trăm như server.
  /// Dùng cho cập nhật lạc quan, và cho khách (tick trên máy, không lưu).
  GuidePreparation withTask(int taskId, bool done) {
    final next = [for (final t in tasks) t.id == taskId ? t.copyWith(completed: done) : t];
    final count = next.where((t) => t.completed).length;
    return GuidePreparation(
      tasks: next,
      completed: count,
      total: next.length,
      percent: next.isEmpty ? 0 : count * 100 ~/ next.length,
      signedIn: signedIn,
    );
  }

  factory GuidePreparation.fromJson(Map<String, dynamic> json) => GuidePreparation(
    tasks: [for (final t in (json['tasks'] as List?) ?? const []) GuideTask.fromJson(t as Map<String, dynamic>)],
    completed: (json['completed'] ?? 0) as int,
    total: (json['total'] ?? 0) as int,
    percent: (json['percent'] ?? 0) as int,
    signedIn: (json['signedIn'] ?? false) as bool,
  );
}
