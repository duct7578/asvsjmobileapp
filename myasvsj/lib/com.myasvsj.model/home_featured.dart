import 'package:myasvsj/com.myasvsj.model/home_tag.dart';

/// "Bài nổi bật tuần này / tháng này" trên trang chủ thành viên (Featured của `GET /api/me/home`).
class HomeFeatured {
  const HomeFeatured({
    required this.id,
    required this.title,
    this.excerpt = '',
    this.authorName = '',
    this.authorTags = const [],
    this.readMinutes = 1,
    this.period = 'WEEK',
  });

  /// Mã bài viết Blog.
  final int id;
  final String title;
  final String excerpt;
  final String authorName;
  final List<HomeTag> authorTags;
  final int readMinutes;

  /// WEEK hoặc MONTH.
  final String period;

  bool get isThisWeek => period == 'WEEK';

  static HomeFeatured? tryParse(Object? json) => json is Map<String, dynamic> ? HomeFeatured.fromJson(json) : null;

  factory HomeFeatured.fromJson(Map<String, dynamic> json) => HomeFeatured(
    id: json['id'] as int,
    title: (json['title'] ?? '') as String,
    excerpt: (json['excerpt'] ?? '') as String,
    authorName: (json['authorName'] ?? '') as String,
    authorTags: HomeTag.listFrom(json['authorTags']),
    readMinutes: (json['readMinutes'] ?? 1) as int,
    period: (json['period'] ?? 'WEEK') as String,
  );
}
