import 'package:myasvsj/com.myasvsj.model/guide_progress.dart';

/// Người xem với một cẩm nang (Viewer của `GET /api/guides/{id}/viewer`): đã lưu chưa, tiến độ tới đâu.
///
/// JSON: `{signedIn, member, saved, progress: {checklist, tasksDone, tasksTotal, percent, done, nextTask}}`.
/// Khách nhận `signedIn: false` và tiến độ trống (checklist và số việc vẫn đúng).
class GuideViewer {
  const GuideViewer({
    this.signedIn = false,
    this.member = false,
    this.saved = false,
    this.progress = const GuideProgress(),
  });

  final bool signedIn;

  /// Tài khoản User được lưu và đánh dấu đã xong (khách và staff thì không).
  final bool member;

  /// Đã lưu vào "Đã lưu" (bảng `saved_guides`).
  final bool saved;
  final GuideProgress progress;

  GuideViewer copyWith({bool? saved, GuideProgress? progress}) =>
      GuideViewer(signedIn: signedIn, member: member, saved: saved ?? this.saved, progress: progress ?? this.progress);

  factory GuideViewer.fromJson(Map<String, dynamic> json) => GuideViewer(
    signedIn: (json['signedIn'] ?? false) as bool,
    member: (json['member'] ?? false) as bool,
    saved: (json['saved'] ?? false) as bool,
    progress: json['progress'] is Map<String, dynamic>
        ? GuideProgress.fromJson(json['progress'] as Map<String, dynamic>)
        : const GuideProgress(),
  );
}
