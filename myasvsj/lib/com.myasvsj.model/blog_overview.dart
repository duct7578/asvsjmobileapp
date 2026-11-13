import 'package:myasvsj/com.myasvsj.model/blog.dart';
import 'package:myasvsj/com.myasvsj.model/blog_topic_stat.dart';
import 'package:myasvsj/com.myasvsj.model/blog_writer.dart';
import 'package:myasvsj/com.myasvsj.model/topic.dart';

/// Phần của màn Blog không phụ thuộc bộ lọc (`GET /api/blogs/overview`): bài nổi bật, danh sách chủ đề để lọc,
/// chủ đề phổ biến và "Senpai viết nhiều".
class BlogOverview {
  const BlogOverview({
    this.featuredPeriod,
    this.featured = const [],
    this.topics = const [],
    this.popularTopics = const [],
    this.topWriters = const [],
    this.topWritersDays = 30,
  });

  /// WEEK (bài nổi bật tuần này) hoặc MONTH (tháng này, khi tuần chưa có bài đủ điểm); null khi không có bài.
  final String? featuredPeriod;
  final List<Blog> featured;

  /// Chủ đề đang dùng, cho bộ lọc.
  final List<Topic> topics;
  final List<BlogTopicStat> popularTopics;
  final List<BlogWriter> topWriters;

  /// "Senpai viết nhiều" tính trong bấy nhiêu ngày gần đây.
  final int topWritersDays;

  factory BlogOverview.fromJson(Map<String, dynamic> json) {
    final featured = (json['featured'] as Map<String, dynamic>?) ?? const {};
    List<Map<String, dynamic>> maps(Object? list) => [
      for (final item in (list as List?) ?? const []) item as Map<String, dynamic>,
    ];
    return BlogOverview(
      featuredPeriod: featured['period'] as String?,
      featured: [for (final post in maps(featured['posts'])) Blog.fromJson(post)],
      topics: [for (final t in maps(json['topics'])) Topic.fromJson(t)],
      popularTopics: [for (final t in maps(json['popularTopics'])) BlogTopicStat.fromJson(t)],
      topWriters: [for (final w in maps(json['topWriters'])) BlogWriter.fromJson(w)],
      topWritersDays: (json['topWritersDays'] ?? 30) as int,
    );
  }
}
