/// Tiến độ của thành viên trong một giai đoạn (StageProgress của `GET /api/me/guides/progress`).
///
/// JSON: `{code, title, done, total, current}`.
class GuideStageProgress {
  const GuideStageProgress({
    required this.code,
    required this.title,
    this.done = 0,
    this.total = 0,
    this.current = false,
  });

  final String code;
  final String title;

  /// [done] trên [total] cẩm nang của giai đoạn đã xong.
  final int done;
  final int total;

  /// Giai đoạn của thành viên (chọn ở Tôi).
  final bool current;

  /// 0.0–1.0 cho thanh tiến độ.
  double get ratio => total == 0 ? 0 : done / total;

  factory GuideStageProgress.fromJson(Map<String, dynamic> json) => GuideStageProgress(
    code: (json['code'] ?? '') as String,
    title: (json['title'] ?? '') as String,
    done: (json['done'] ?? 0) as int,
    total: (json['total'] ?? 0) as int,
    current: (json['current'] ?? false) as bool,
  );
}
