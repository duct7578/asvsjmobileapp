import 'package:myasvsj/com.myasvsj.model/guide_activity.dart';
import 'package:myasvsj/com.myasvsj.model/guide_stage_progress.dart';

/// Thẻ "Cẩm nang của tôi" (MyGuides của `GET /api/me/guides/progress`, chỉ thành viên).
///
/// JSON: `{stage, stages: [4 giai đoạn], inProgress: [≤ 10], recentlyDone: [≤ 5]}`.
class GuideMyProgress {
  const GuideMyProgress({this.stage, this.stages = const [], this.inProgress = const [], this.recentlyDone = const []});

  /// Mã giai đoạn của thành viên; null khi chưa chọn.
  final String? stage;

  /// Bốn giai đoạn theo thứ tự, mỗi giai đoạn bao nhiêu cẩm nang đã xong.
  final List<GuideStageProgress> stages;

  /// Checklist đã tick một phần, tick gần nhất trước.
  final List<GuideActivity> inProgress;

  /// Cẩm nang vừa xong, xong gần nhất trước.
  final List<GuideActivity> recentlyDone;

  bool get hasActivity => inProgress.isNotEmpty || recentlyDone.isNotEmpty;

  factory GuideMyProgress.fromJson(Map<String, dynamic> json) => GuideMyProgress(
    stage: json['stage'] as String?,
    stages: [
      for (final s in (json['stages'] as List?) ?? const []) GuideStageProgress.fromJson(s as Map<String, dynamic>),
    ],
    inProgress: [
      for (final g in (json['inProgress'] as List?) ?? const []) GuideActivity.fromJson(g as Map<String, dynamic>),
    ],
    recentlyDone: [
      for (final g in (json['recentlyDone'] as List?) ?? const []) GuideActivity.fromJson(g as Map<String, dynamic>),
    ],
  );
}
