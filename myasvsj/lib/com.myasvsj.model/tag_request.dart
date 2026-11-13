/// Yêu cầu cấp tag định danh gửi lên `POST /api/me/tag-requests` (bảng `tag_requests`).
///
/// Gửi dạng multipart: phần "request" là [toJson] (TagRequestForm `{tagId, proofTypeId, consent}`), phần "photo"
/// là ảnh minh chứng [photoPath].
class TagRequest {
  const TagRequest({this.tagId, this.proofTypeId, this.consent = false, this.photoPath});

  final int? tagId;

  /// Loại minh chứng; null với tag chỉ cần ảnh chân dung (server tự chọn).
  final int? proofTypeId;

  /// Đồng ý cho Kiểm duyệt viên xem ảnh.
  final bool consent;

  /// Đường dẫn ảnh trên máy (đã nén JPEG bằng PhotoPicker).
  final String? photoPath;

  Map<String, dynamic> toJson() => {'tagId': tagId, 'proofTypeId': proofTypeId, 'consent': consent};
}
