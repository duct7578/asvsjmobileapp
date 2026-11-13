import 'package:myasvsj/com.myasvsj.model/tag_option.dart';
import 'package:myasvsj/com.myasvsj.model/tag_pending_request.dart';

/// Dữ liệu mở form "Xin tag định danh" (TagCompose của `GET /api/me/tag-requests/compose`).
///
/// JSON: `{tags: [...], pending: {...} | null, keepDays, photoMaxMb}`.
class TagCompose {
  const TagCompose({this.tags = const [], this.pending, this.keepDays = 14, this.photoMaxMb = 20});

  /// Các tag đang mở; tag đã có mang cờ `owned`.
  final List<TagOption> tags;

  /// Yêu cầu đang chờ duyệt; null khi được gửi yêu cầu mới.
  final TagPendingRequest? pending;

  /// Số ngày giữ ảnh minh chứng khi chưa được duyệt.
  final int keepDays;

  /// Dung lượng ảnh tối đa (MB).
  final int photoMaxMb;

  /// Bản sao có yêu cầu đang chờ mới (sau khi gửi xong).
  TagCompose withPending(TagPendingRequest? request) =>
      TagCompose(tags: tags, pending: request, keepDays: keepDays, photoMaxMb: photoMaxMb);

  factory TagCompose.fromJson(Map<String, dynamic> json) => TagCompose(
    tags: [for (final t in (json['tags'] as List?) ?? const []) TagOption.fromJson(t as Map<String, dynamic>)],
    pending: TagPendingRequest.tryParse(json['pending']),
    keepDays: (json['keepDays'] ?? 14) as int,
    photoMaxMb: (json['photoMaxMb'] ?? 20) as int,
  );
}
