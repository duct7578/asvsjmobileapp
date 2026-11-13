import 'package:myasvsj/com.myasvsj.model/feed_post.dart';
import 'package:myasvsj/com.myasvsj.model/home_event.dart';
import 'package:myasvsj/com.myasvsj.model/home_featured.dart';
import 'package:myasvsj/com.myasvsj.model/home_guide_card.dart';
import 'package:myasvsj/com.myasvsj.model/home_guide_progress.dart';
import 'package:myasvsj/com.myasvsj.model/home_phrase.dart';
import 'package:myasvsj/com.myasvsj.model/home_review.dart';

/// Trang chủ của thành viên (MemberHome của `GET /api/me/home`): "Dành cho bạn", "Việc tiếp theo",
/// "Review mới quanh …", sự kiện, mẫu câu và "Bài nổi bật".
class HomeMember {
  const HomeMember({
    required this.displayName,
    this.stage,
    this.areaId,
    this.areaName,
    this.points = 0,
    this.rankName = '',
    this.phrase,
    this.guide,
    this.events = const [],
    this.reviews = const [],
    this.featured,
    this.forYou = const [],
    this.interests = const [],
    this.chosenInterests = const [],
    this.stageGuides = const [],
  });

  final String displayName;

  /// Giai đoạn đã chọn (PRE, ARR, LEAVE, HOME); null khi chưa chọn.
  final String? stage;

  /// Khu vực đã chọn, ví dụ "Arakawa-ku, Tokyo · 東京都荒川区"; null khi chưa chọn.
  final int? areaId;
  final String? areaName;

  final int points;

  /// Cấp bậc theo điểm, ví dụ "Người mới".
  final String rankName;

  final HomePhrase? phrase;

  /// "Việc tiếp theo".
  final HomeGuideProgress? guide;

  /// Sự kiện trong 2 tuần tới.
  final List<HomeEvent> events;

  /// 3 review mới, ưu tiên khu vực rồi tỉnh của người dùng.
  final List<HomeReview> reviews;

  /// "Bài nổi bật tuần này / tháng này"; null khi không có.
  final HomeFeatured? featured;

  /// "Dành cho bạn": tối đa 5 bài của người khác, đã xếp hạng.
  final List<FeedPost> forYou;

  /// Chủ đề "Dựa trên": chủ đề đã chọn trước, rồi chủ đề rút ra từ những gì người dùng làm.
  final List<String> interests;

  /// Những chủ đề người dùng tự chọn trong [interests].
  final List<String> chosenInterests;

  /// "Cẩm nang cho giai đoạn …": tối đa 3 cẩm nang chưa xong của giai đoạn; rỗng khi chưa chọn giai đoạn.
  final List<HomeGuideCard> stageGuides;

  /// Đã chọn đủ khu vực và giai đoạn (khi chưa, trang chủ nhắc chọn).
  bool get hasAreaAndStage => (areaName ?? '').isNotEmpty && (stage ?? '').isNotEmpty;

  factory HomeMember.fromJson(Map<String, dynamic> json) => HomeMember(
    displayName: (json['displayName'] ?? '') as String,
    stage: json['stage'] as String?,
    areaId: json['areaId'] as int?,
    areaName: json['areaName'] as String?,
    points: (json['points'] ?? 0) as int,
    rankName: (json['rankName'] ?? '') as String,
    phrase: HomePhrase.tryParse(json['phrase']),
    guide: HomeGuideProgress.tryParse(json['guide']),
    events: [for (final e in (json['events'] as List?) ?? const []) HomeEvent.fromJson(e as Map<String, dynamic>)],
    reviews: [for (final r in (json['reviews'] as List?) ?? const []) HomeReview.fromJson(r as Map<String, dynamic>)],
    featured: HomeFeatured.tryParse(json['featured']),
    forYou: [for (final p in (json['forYou'] as List?) ?? const []) FeedPost.fromJson(p as Map<String, dynamic>)],
    interests: [for (final t in (json['interests'] as List?) ?? const []) t as String],
    chosenInterests: [for (final t in (json['chosenInterests'] as List?) ?? const []) t as String],
    stageGuides: [
      for (final g in (json['stageGuides'] as List?) ?? const []) HomeGuideCard.fromJson(g as Map<String, dynamic>),
    ],
  );
}
