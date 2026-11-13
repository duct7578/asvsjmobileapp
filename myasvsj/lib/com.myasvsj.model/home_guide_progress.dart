import 'package:myasvsj/com.myasvsj.model/home_guide_next.dart';

/// Thẻ "Việc tiếp theo" (GuideProgress của `GET /api/me/home`): đã xong [done] / [total] cẩm nang của giai đoạn.
class HomeGuideProgress {
  const HomeGuideProgress({required this.stageCode, this.stageTitle = '', this.done = 0, this.total = 0, this.next});

  /// Giai đoạn của người dùng (ARR khi chưa chọn): PRE, ARR, LEAVE, HOME.
  final String stageCode;

  /// Tên đầy đủ, ví dụ "Khi mới đến (tuần đầu đến 3 tháng)".
  final String stageTitle;
  final int done;
  final int total;

  /// Cẩm nang nên mở tiếp; null khi đã xong cả giai đoạn hoặc giai đoạn chưa có cẩm nang.
  final HomeGuideNext? next;

  /// Tỉ lệ đã xong, 0–1.
  double get progress => total == 0 ? 0 : done / total;

  static HomeGuideProgress? tryParse(Object? json) =>
      json is Map<String, dynamic> ? HomeGuideProgress.fromJson(json) : null;

  factory HomeGuideProgress.fromJson(Map<String, dynamic> json) => HomeGuideProgress(
    stageCode: (json['stageCode'] ?? 'ARR') as String,
    stageTitle: (json['stageTitle'] ?? '') as String,
    done: (json['done'] ?? 0) as int,
    total: (json['total'] ?? 0) as int,
    next: HomeGuideNext.tryParse(json['next']),
  );
}
