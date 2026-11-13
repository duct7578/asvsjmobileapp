import 'package:myasvsj/com.myasvsj.model/guide_section.dart';
import 'package:myasvsj/com.myasvsj.model/guide_task.dart';

/// Một cẩm nang (bảng `guide_items`), như danh sách và trang chi tiết của web trả về (GuideResponse).
///
/// JSON: `{id, title, summary, category, topicName, published, createdBy, creatorName, createdAt, sections,
/// stageName, topicCode, sourceUrl, coverImageUrl, status, preparationEnabled, preparationTasks}`.
/// Ở danh sách `sections` và `preparationTasks` luôn rỗng; chỉ trang chi tiết mới có.
class Guide {
  const Guide({
    required this.id,
    required this.title,
    this.summary = '',
    this.stageCode,
    this.stageName,
    this.topicCode,
    this.topicName,
    this.creatorName,
    this.createdAt,
    this.coverImageUrl,
    this.sourceUrl,
    this.sections = const [],
    this.preparationEnabled = false,
    this.preparationTasks = const [],
  });

  final int id;
  final String title;
  final String summary;

  /// Mã giai đoạn (PRE, ARR, LEAVE, HOME – trường `category` của web) và tên để hiện.
  final String? stageCode;
  final String? stageName;

  /// Mã chủ đề (LIVING, HOUSING…) và tên để hiện.
  final String? topicCode;
  final String? topicName;

  final String? creatorName;
  final DateTime? createdAt;

  /// Ảnh bìa (`/media/…`); null khi không có.
  final String? coverImageUrl;

  /// "Đường dẫn gốc" của bài; null khi không có.
  final String? sourceUrl;

  final List<GuideSection> sections;

  /// Cẩm nang có tab "Hướng dẫn chuẩn bị" (checklist). Cẩm nang có checklist xong khi tick hết các việc,
  /// không bấm "Đánh dấu đã xong" được.
  final bool preparationEnabled;

  /// Các việc của checklist (chưa có dấu tick của người xem; dấu tick lấy ở GuidePreparation).
  final List<GuideTask> preparationTasks;

  factory Guide.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    final source = json['sourceUrl'] as String?;
    return Guide(
      id: json['id'] as int,
      title: (json['title'] ?? '') as String,
      summary: (json['summary'] ?? '') as String,
      stageCode: json['category'] as String?,
      stageName: json['stageName'] as String?,
      topicCode: json['topicCode'] as String?,
      topicName: json['topicName'] as String?,
      creatorName: json['creatorName'] as String?,
      createdAt: created is String ? DateTime.tryParse(created)?.toLocal() : null,
      coverImageUrl: json['coverImageUrl'] as String?,
      sourceUrl: source == null || source.trim().isEmpty ? null : source.trim(),
      sections: [
        for (final s in (json['sections'] as List?) ?? const []) GuideSection.fromJson(s as Map<String, dynamic>),
      ],
      preparationEnabled: (json['preparationEnabled'] ?? false) as bool,
      preparationTasks: [
        for (final t in (json['preparationTasks'] as List?) ?? const []) GuideTask.fromJson(t as Map<String, dynamic>),
      ],
    );
  }
}
