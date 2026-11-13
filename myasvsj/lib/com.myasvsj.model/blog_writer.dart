import 'package:myasvsj/com.myasvsj.model/author.dart';

/// Một người trong khối "Senpai viết nhiều" của Blog: tác giả và số bài trong những ngày gần đây (Writer của web).
class BlogWriter {
  const BlogWriter({required this.author, this.postCount = 0});

  final Author author;
  final int postCount;

  factory BlogWriter.fromJson(Map<String, dynamic> json) => BlogWriter(
    author: Author.fromJson(json['author'] as Map<String, dynamic>),
    postCount: (json['postCount'] ?? 0) as int,
  );
}
