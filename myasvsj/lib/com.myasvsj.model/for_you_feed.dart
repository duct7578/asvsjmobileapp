import 'package:myasvsj/com.myasvsj.model/feed_post.dart';
import 'package:myasvsj/com.myasvsj.model/feed_scope.dart';

/// Một trang của "Dành cho bạn" (ForYouFeed của `GET /api/me/for-you`): 10 bài, phạm vi đang lọc, số bài từng phạm
/// vi, và những gì gợi ý dựa vào (khu vực, giai đoạn, chủ đề quan tâm).
class ForYouFeed {
  const ForYouFeed({
    this.scope = 'ALL',
    this.q,
    this.areaName,
    this.stage,
    this.interests = const [],
    this.chosenInterests = const [],
    this.scopes = const [],
    this.page = 0,
    this.hasMore = false,
    this.items = const [],
  });

  /// ALL, NEAR (khu vực hoặc tỉnh), STAGE hoặc INTEREST.
  final String scope;

  /// Từ khóa đã lọc bài; null khi không tìm.
  final String? q;

  final String? areaName;
  final String? stage;
  final List<String> interests;
  final List<String> chosenInterests;

  /// Phạm vi người dùng chọn được và số bài của từng phạm vi (đã tính theo [q]).
  final List<FeedScope> scopes;

  /// Trang đầu là 0.
  final int page;
  final bool hasMore;
  final List<FeedPost> items;

  /// Số bài của phạm vi [code]; 0 khi không có phạm vi đó.
  int countOf(String code) {
    for (final s in scopes) {
      if (s.code == code) {
        return s.count;
      }
    }
    return 0;
  }

  factory ForYouFeed.fromJson(Map<String, dynamic> json) => ForYouFeed(
    scope: (json['scope'] ?? 'ALL') as String,
    q: json['q'] as String?,
    areaName: json['areaName'] as String?,
    stage: json['stage'] as String?,
    interests: [for (final t in (json['interests'] as List?) ?? const []) t as String],
    chosenInterests: [for (final t in (json['chosenInterests'] as List?) ?? const []) t as String],
    scopes: FeedScope.listFrom(json['scopes']),
    page: (json['page'] ?? 0) as int,
    hasMore: (json['hasMore'] ?? false) as bool,
    items: [for (final p in (json['items'] as List?) ?? const []) FeedPost.fromJson(p as Map<String, dynamic>)],
  );
}
