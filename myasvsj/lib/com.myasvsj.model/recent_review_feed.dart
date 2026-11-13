import 'package:myasvsj/com.myasvsj.model/feed_scope.dart';
import 'package:myasvsj/com.myasvsj.model/recent_review.dart';

/// Một trang của "Review mới" (ReviewFeed của `GET /api/home/reviews`): 10 review mới nhất trong một phạm vi.
class RecentReviewFeed {
  const RecentReviewFeed({
    this.scope = 'ALL',
    this.areaName,
    this.prefectureName,
    this.scopes = const [],
    this.page = 0,
    this.hasMore = false,
    this.items = const [],
  });

  /// AREA ("Quanh …"), PREFECTURE ("Cả tỉnh …") hoặc ALL ("Tất cả").
  final String scope;

  /// Khu vực và tỉnh của người xem; null với khách và thành viên chưa chọn khu vực.
  final String? areaName;
  final String? prefectureName;

  /// Phạm vi người xem chọn được và số review của từng phạm vi (khách chỉ có ALL).
  final List<FeedScope> scopes;

  /// Trang đầu là 0.
  final int page;
  final bool hasMore;
  final List<RecentReview> items;

  int countOf(String code) {
    for (final s in scopes) {
      if (s.code == code) {
        return s.count;
      }
    }
    return 0;
  }

  factory RecentReviewFeed.fromJson(Map<String, dynamic> json) => RecentReviewFeed(
    scope: (json['scope'] ?? 'ALL') as String,
    areaName: json['areaName'] as String?,
    prefectureName: json['prefectureName'] as String?,
    scopes: FeedScope.listFrom(json['scopes']),
    page: (json['page'] ?? 0) as int,
    hasMore: (json['hasMore'] ?? false) as bool,
    items: [for (final r in (json['items'] as List?) ?? const []) RecentReview.fromJson(r as Map<String, dynamic>)],
  );
}
