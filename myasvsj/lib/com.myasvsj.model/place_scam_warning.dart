/// Một bài "Cảnh báo lừa đảo" gắn với địa điểm (`scamWarnings` của chi tiết địa điểm).
///
/// JSON: `{blogId, title}`.
class PlaceScamWarning {
  const PlaceScamWarning({required this.blogId, required this.title});

  final int blogId;
  final String title;

  factory PlaceScamWarning.fromJson(Map<String, dynamic> json) =>
      PlaceScamWarning(blogId: json['blogId'] as int, title: (json['title'] ?? '') as String);
}
