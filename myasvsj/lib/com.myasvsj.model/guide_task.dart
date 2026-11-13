/// Một việc trong "Hướng dẫn chuẩn bị" của cẩm nang (bảng `guide_preparation_tasks`), kèm dấu tick của người xem
/// (bảng `guide_preparation_progress`).
///
/// JSON: `{id, title, notes, completed}`.
class GuideTask {
  const GuideTask({required this.id, required this.title, this.notes = '', this.completed = false});

  final int id;
  final String title;

  /// Ghi chú thêm; rỗng khi không có.
  final String notes;

  /// Người xem đã tick việc này.
  final bool completed;

  GuideTask copyWith({bool? completed}) =>
      GuideTask(id: id, title: title, notes: notes, completed: completed ?? this.completed);

  factory GuideTask.fromJson(Map<String, dynamic> json) => GuideTask(
    id: json['id'] as int,
    title: (json['title'] ?? '') as String,
    notes: (json['notes'] ?? '') as String,
    completed: (json['completed'] ?? false) as bool,
  );
}
