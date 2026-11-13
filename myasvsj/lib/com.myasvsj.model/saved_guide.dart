import 'package:myasvsj/com.myasvsj.model/saved_item.dart';
import 'package:myasvsj/com.myasvsj.model/saved_kind.dart';

/// Cẩm nang đã lưu, còn đang đăng (bảng `saved_guides`).
///
/// JSON: `{id, title, summary, stageName, topicName, savedAt}` (SavedGuide của `GET /api/me/saved`).
class SavedGuide implements SavedItem {
  const SavedGuide({
    required this.id,
    required this.title,
    this.summary,
    this.stageName = '',
    this.topicName = '',
    this.savedAt,
  });

  @override
  final int id;
  final String title;

  /// Đoạn tóm tắt chữ thường, server cắt còn 160 ký tự kèm "…"; null khi trống.
  final String? summary;

  /// Giai đoạn của cẩm nang, ví dụ "Khi mới đến (tuần đầu đến 3 tháng)".
  final String stageName;

  /// Chủ đề, hoặc giai đoạn khi cẩm nang không có chủ đề.
  final String topicName;

  @override
  final DateTime? savedAt;

  @override
  SavedKind get kind => SavedKind.guide;

  factory SavedGuide.fromJson(Map<String, dynamic> json) {
    final saved = json['savedAt'];
    return SavedGuide(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      summary: json['summary'] as String?,
      stageName: (json['stageName'] ?? '') as String,
      topicName: (json['topicName'] ?? '') as String,
      savedAt: saved is String ? DateTime.tryParse(saved)?.toLocal() : null,
    );
  }
}
