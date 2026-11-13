/// Một liên kết "Xem thêm" dưới câu trả lời của câu hỏi thường gặp (`resources` của FAQ trong JSON của web).
///
/// JSON: `{kind: GUIDE|BLOG|QUESTION|EXTERNAL, targetId, url, label}`. GUIDE / BLOG / QUESTION trỏ tới cẩm nang,
/// bài viết, câu hỏi theo [targetId]; EXTERNAL là địa chỉ web [url].
class FaqResource {
  const FaqResource({required this.kind, this.targetId, this.url, required this.label});

  final String kind;
  final int? targetId;
  final String? url;
  final String label;

  bool get isExternal => kind == 'EXTERNAL';

  factory FaqResource.fromJson(Map<String, dynamic> json) => FaqResource(
    kind: (json['kind'] ?? '') as String,
    targetId: json['targetId'] as int?,
    url: json['url'] as String?,
    label: (json['label'] ?? '') as String,
  );
}
