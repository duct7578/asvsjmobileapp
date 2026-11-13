import 'package:myasvsj/com.myasvsj.model/phrase_group.dart';

/// Một trong hai phần của trang đầu Nhật ngữ: "Mẫu câu" (kind PHRASE) hoặc "Từ vựng" (VOCAB), với các chủ đề và
/// loại địa điểm có mục thuộc loại đó (Part của `GET /api/phrases/overview`). Mọi số chỉ đếm mục thuộc loại này.
class PhrasePart {
  const PhrasePart({
    required this.kind,
    required this.name,
    this.icon = 'label',
    this.count = 0,
    this.learned = 0,
    this.topics = const [],
    this.categories = const [],
  });

  final String kind;
  final String name;
  final String icon;
  final int count;

  /// Số mục thành viên giữ là "Đã thuộc".
  final int learned;

  /// Chủ đề, nhiều mục nhất trước.
  final List<PhraseGroup> topics;

  /// Loại địa điểm, theo thứ tự của Bản đồ.
  final List<PhraseGroup> categories;

  /// Chủ đề ([by] = "topic") hoặc loại địa điểm ([by] = "category").
  List<PhraseGroup> groupsOf(String by) => by == 'category' ? categories : topics;

  factory PhrasePart.fromJson(Map<String, dynamic> json) => PhrasePart(
    kind: (json['kind'] ?? '') as String,
    name: (json['name'] ?? '') as String,
    icon: (json['icon'] ?? 'label') as String,
    count: (json['count'] ?? 0) as int,
    learned: (json['learned'] ?? 0) as int,
    topics: PhraseGroup.listFrom(json['topics']),
    categories: PhraseGroup.listFrom(json['categories']),
  );

  PhrasePart copyWith({int? learned, List<PhraseGroup>? topics, List<PhraseGroup>? categories}) => PhrasePart(
    kind: kind,
    name: name,
    icon: icon,
    count: count,
    learned: learned ?? this.learned,
    topics: topics ?? this.topics,
    categories: categories ?? this.categories,
  );
}
