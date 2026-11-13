/// Một lý do báo cáo nội dung, ví dụ "Lừa đảo", "Spam" (`reportReasons` trong JSON chi tiết của web).
///
/// Gửi báo cáo: `POST …/report` với body `{reasonId, note}`.
class ReportReason {
  const ReportReason({required this.id, required this.label});

  final int id;
  final String label;

  factory ReportReason.fromJson(Map<String, dynamic> json) => ReportReason(
        id: json['id'] as int,
        label: (json['label'] ?? '') as String,
      );

  static List<ReportReason> listFrom(Object? json) => [
        for (final item in (json as List?) ?? const []) ReportReason.fromJson(item as Map<String, dynamic>),
      ];
}
