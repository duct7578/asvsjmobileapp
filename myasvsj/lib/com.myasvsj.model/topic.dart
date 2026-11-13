/// Chủ đề của bài viết Blog, ví dụ "Nhà ở" hoặc "Khác" (bảng chủ đề blog của web).
class Topic {
  const Topic({required this.id, required this.name});

  final int id;
  final String name;

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json['id'] as int,
        name: json['name'] as String,
      );
}
