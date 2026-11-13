// DAO giả và khung app cho test Trang chủ, "Dành cho bạn", "Review mới", "Tìm kiếm": không cần mạng.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/global_search_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/home_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/feed_post.dart';
import 'package:myasvsj/com.myasvsj.model/feed_reason.dart';
import 'package:myasvsj/com.myasvsj.model/feed_scope.dart';
import 'package:myasvsj/com.myasvsj.model/for_you_feed.dart';
import 'package:myasvsj/com.myasvsj.model/home_dao.dart';
import 'package:myasvsj/com.myasvsj.model/home_guest.dart';
import 'package:myasvsj/com.myasvsj.model/home_member.dart';
import 'package:myasvsj/com.myasvsj.model/notification_dao.dart';
import 'package:myasvsj/com.myasvsj.model/recent_review.dart';
import 'package:myasvsj/com.myasvsj.model/recent_review_feed.dart';
import 'package:myasvsj/com.myasvsj.model/search_dao.dart';
import 'package:myasvsj/com.myasvsj.model/search_result.dart';

import 'auth_fakes.dart';
import 'home_samples.dart';
import 'search_samples.dart';

/// Thành viên chưa chọn khu vực và giai đoạn (để thử lời nhắc "Mong bạn cho Senpai ơi biết khu vực…").
const memberWithoutArea = HomeMember(displayName: 'Trần Minh', points: 0, rankName: 'Người mới');

/// Một bài của "Dành cho bạn": bài chẵn gần khu vực, bài lẻ hợp giai đoạn; bài từ [engagedFrom] trở đi đã tương tác.
FeedPost fakeFeedPost(int id, {int engagedFrom = 1 << 30}) => FeedPost(
  id: id,
  title: 'Bài số $id',
  excerpt: 'Đoạn trích của bài số $id',
  authorName: 'Lan Anh',
  topicName: 'Kinh nghiệm',
  likeCount: id,
  reasons: [
    id.isEven
        ? const FeedReason(code: 'AREA', label: 'Gần khu vực của bạn', detail: 'Ga Nippori')
        : const FeedReason(code: 'STAGE', label: 'Hợp giai đoạn của bạn', detail: 'Kinh nghiệm'),
  ],
  engaged: id >= engagedFrom,
);

/// Một review của "Review mới": review chẵn ở khu vực, review lẻ trong tỉnh.
RecentReview fakeReview(int id) => RecentReview(
  id: id,
  placeId: 100 + id,
  placeName: 'Quán số $id',
  categoryName: 'Quán ăn',
  categoryIcon: 'restaurant',
  placeArea: 'Arakawa-ku, Tokyo · 東京都荒川区',
  near: id.isEven ? 'AREA' : 'PREFECTURE',
  rating: 4,
  authorName: 'Hoàng',
  excerpt: 'Review số $id',
  likeCount: id,
);

/// DAO giả của Trang chủ: trả dữ liệu mẫu (chép từ server thật) và ghi lại mọi lần gọi.
class FakeHomeDao implements HomeDao {
  HomeGuest guest = HomeGuest.fromJson(sampleData(guestHomeJson));
  HomeMember member = HomeMember.fromJson(sampleData(memberHomeJson));

  /// Mọi bài của "Dành cho bạn" (đã xếp hạng); mặc định 25 bài, 5 bài cuối đã tương tác.
  List<FeedPost> feed = [for (var i = 1; i <= 25; i++) fakeFeedPost(i, engagedFrom: 21)];

  /// Mọi review của "Review mới", mới nhất trước.
  List<RecentReview> recent = [for (var i = 1; i <= 15; i++) fakeReview(i)];

  /// Khách: "Review mới" chỉ có phạm vi Tất cả, không có khu vực.
  bool reviewsAsGuest = false;

  /// Trang sau lặp lại bài cuối của trang trước (thứ hạng đổi giữa hai lần tải).
  bool repeatLastOnNextPage = false;

  /// Đặt khác null để mọi lần gọi đều lỗi như server từ chối.
  ApiException? failWith;

  /// Bật để mỗi lần gọi phải chờ test mở [pending] (thử trạng thái chờ và câu trả lời cũ bị bỏ).
  bool hold = false;
  final List<Completer<void>> pending = [];

  int guestCalls = 0;
  int memberCalls = 0;
  final List<({String? scope, int page, String? q})> forYouCalls = [];
  final List<({String? scope, int page})> reviewCalls = [];

  Future<void> _wait() async {
    if (hold) {
      final gate = Completer<void>();
      pending.add(gate);
      await gate.future;
    }
    if (failWith != null) {
      throw failWith!;
    }
  }

  /// Mở lần gọi đang chờ thứ [index] (theo thứ tự gọi).
  Future<void> release([int index = 0]) async {
    pending[index].complete();
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Future<HomeGuest> findGuest() async {
    guestCalls++;
    await _wait();
    return guest;
  }

  @override
  Future<HomeMember> findMember() async {
    memberCalls++;
    await _wait();
    return member;
  }

  @override
  Future<ForYouFeed> findForYou({String? scope, int page = 0, String? q}) async {
    forYouCalls.add((scope: scope, page: page, q: q));
    await _wait();
    final text = (q ?? '').trim().toLowerCase();
    bool matches(FeedPost p) => text.isEmpty || p.title.toLowerCase().contains(text);
    List<FeedPost> inScope(String code) => [
      for (final p in feed)
        if (matches(p) &&
            (code == 'ALL' ||
                (code == 'NEAR' && p.reasons.any((r) => r.code == 'AREA' || r.code == 'PREFECTURE')) ||
                p.reasons.any((r) => r.code == code)))
          p,
    ];
    const codes = ['ALL', 'NEAR', 'STAGE', 'INTEREST'];
    final shown = codes.contains(scope) ? scope! : 'ALL';
    final all = inScope(shown);
    final start = page * HomeDao.pageSize;
    final from = repeatLastOnNextPage && page > 0 ? start - 1 : start;
    final items = all.skip(from).take(HomeDao.pageSize + (from < start ? 1 : 0)).toList();
    return ForYouFeed(
      scope: shown,
      q: text.isEmpty ? null : q!.trim(),
      areaName: member.areaName,
      stage: member.stage,
      interests: member.interests,
      chosenInterests: member.chosenInterests,
      scopes: [for (final c in codes) FeedScope(code: c, count: inScope(c).length)],
      page: page,
      hasMore: start + HomeDao.pageSize < all.length,
      items: items,
    );
  }

  @override
  Future<RecentReviewFeed> findRecentReviews({String? scope, int page = 0}) async {
    reviewCalls.add((scope: scope, page: page));
    await _wait();
    List<RecentReview> inScope(String code) => [
      for (final r in recent)
        if (code == 'ALL' || (code == 'PREFECTURE' && r.near != null) || r.near == code) r,
    ];
    final codes = reviewsAsGuest ? const ['ALL'] : const ['AREA', 'PREFECTURE', 'ALL'];
    final shown = codes.contains(scope) ? scope! : codes.first;
    final all = inScope(shown);
    final start = page * HomeDao.pageSize;
    return RecentReviewFeed(
      scope: shown,
      areaName: reviewsAsGuest ? null : 'Arakawa-ku, Tokyo · 東京都荒川区',
      prefectureName: reviewsAsGuest ? null : 'Tokyo',
      scopes: [for (final c in codes) FeedScope(code: c, count: inScope(c).length)],
      page: page,
      hasMore: start + HomeDao.pageSize < all.length,
      items: all.skip(start).take(HomeDao.pageSize).toList(),
    );
  }
}

/// DAO giả của Tìm kiếm: "Nippori" và "thẻ cư trú" trả JSON mẫu của server; chữ khác không tìm thấy gì.
class FakeSearchDao implements SearchDao {
  final List<String> asked = [];
  ApiException? failWith;

  bool hold = false;
  final List<Completer<void>> pending = [];

  @override
  Future<SearchResult> search(String q) async {
    asked.add(q);
    if (hold) {
      final gate = Completer<void>();
      pending.add(gate);
      await gate.future;
    }
    if (failWith != null) {
      throw failWith!;
    }
    final text = q.trim();
    if (text.toLowerCase() == 'nippori') {
      return SearchResult.fromJson(searchData(searchNipporiJson));
    }
    if (text.toLowerCase() == 'thẻ cư trú') {
      return SearchResult.fromJson(searchData(searchResidenceCardJson));
    }
    if (text.length < 2) {
      return SearchResult(q: text, tooShort: true);
    }
    return SearchResult(q: text);
  }
}

/// DAO thông báo giả cho AppBarActions (NotificationController chỉ cần tạo được, không gọi mạng).
class FakeHomeNotificationDao implements NotificationDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// App thu nhỏ để test màn hình: cấp AuthController (khách, hoặc [signedIn] với testUser), NotificationController,
/// HomeController, GlobalSearchController bằng DAO giả.
Widget homeTestApp({
  required Widget home,
  FakeHomeDao? homeDao,
  FakeSearchDao? searchDao,
  bool signedIn = false,
  AuthController? auth,
}) {
  final authController = auth ?? homeTestAuth(signedIn: signedIn);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: authController),
      ChangeNotifierProvider(create: (_) => NotificationController(FakeHomeNotificationDao())),
      ChangeNotifierProvider(create: (_) => HomeController(homeDao ?? FakeHomeDao())),
      ChangeNotifierProvider(create: (_) => GlobalSearchController(searchDao ?? FakeSearchDao())),
    ],
    child: MaterialApp(debugShowCheckedModeBanner: false, home: home),
  );
}

/// Danh sách cuộn dọc của màn hình (bỏ qua ô nhập chữ và hàng nút cuộn ngang), cho `scrollUntilVisible`.
final Finder vertical = find.byWidgetPredicate((w) => w is Scrollable && w.axisDirection == AxisDirection.down).first;

/// AuthController của test: khách, hoặc đã đăng nhập bằng testUser (đọc lại phiên như lúc mở app).
AuthController homeTestAuth({bool signedIn = false}) {
  final auth = AuthController(FakeAuthDao(current: signedIn ? testUser : null));
  if (signedIn) {
    auth.restoreSession();
  }
  return auth;
}
