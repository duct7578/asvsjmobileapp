import 'package:myasvsj/com.myasvsj.model/home_tag.dart';

/// "Senpai nói gì" trên trang chủ của khách: một review "Hữu ích" (hơn 10 lượt thích) của người Việt.
class HomeQuote {
  const HomeQuote({required this.text, this.authorName = '', this.authorTags = const [], this.placeName = ''});

  final String text;
  final String authorName;
  final List<HomeTag> authorTags;

  /// Địa điểm được review, ví dụ "Ga Nippori".
  final String placeName;

  factory HomeQuote.fromJson(Map<String, dynamic> json) => HomeQuote(
    text: (json['text'] ?? '') as String,
    authorName: (json['authorName'] ?? '') as String,
    authorTags: HomeTag.listFrom(json['authorTags']),
    placeName: (json['placeName'] ?? '') as String,
  );
}
