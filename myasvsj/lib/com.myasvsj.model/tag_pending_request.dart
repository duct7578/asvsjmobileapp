/// Yêu cầu tag đang chờ Moderator duyệt (mỗi người chỉ có một). Có yêu cầu này thì màn hình hiện nó thay cho form.
///
/// JSON: `{tagName, submittedAt, expiresAt}` (PendingRequest của `/api/me/tag-requests`).
class TagPendingRequest {
  const TagPendingRequest({required this.tagName, this.submittedAt, this.expiresAt});

  final String tagName;
  final DateTime? submittedAt;

  /// Ngày ảnh minh chứng tự xóa nếu chưa được duyệt.
  final DateTime? expiresAt;

  /// null khi JSON không có yêu cầu đang chờ.
  static TagPendingRequest? tryParse(Object? json) =>
      json is Map<String, dynamic> ? TagPendingRequest.fromJson(json) : null;

  factory TagPendingRequest.fromJson(Map<String, dynamic> json) => TagPendingRequest(
    tagName: (json['tagName'] ?? '') as String,
    submittedAt: _date(json['submittedAt']),
    expiresAt: _date(json['expiresAt']),
  );

  static DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
