/// Một chủ đề trong khối "Chủ đề phổ biến" của Blog: tên và số bài (TopicCount của web).
class BlogTopicStat {
  const BlogTopicStat({required this.id, required this.name, this.postCount = 0});

  final int id;
  final String name;
  final int postCount;

  factory BlogTopicStat.fromJson(Map<String, dynamic> json) => BlogTopicStat(
    id: json['id'] as int,
    name: (json['name'] ?? '') as String,
    postCount: (json['postCount'] ?? 0) as int,
  );
}
