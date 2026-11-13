import 'package:flutter/foundation.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/feed_post.dart';
import 'package:myasvsj/com.myasvsj.model/for_you_feed.dart';
import 'package:myasvsj/com.myasvsj.model/home_dao.dart';
import 'package:myasvsj/com.myasvsj.model/home_guest.dart';
import 'package:myasvsj/com.myasvsj.model/home_member.dart';
import 'package:myasvsj/com.myasvsj.model/recent_review.dart';
import 'package:myasvsj/com.myasvsj.model/recent_review_feed.dart';

/// Controller của ba màn hình: Trang chủ (khách và thành viên), "Dành cho bạn", "Review mới".
///
/// Mỗi màn hình có một nhóm trạng thái riêng. Mỗi lần tải có một "vé" (ticket): khi người dùng đổi phạm vi, từ khóa
/// hay đăng nhập / đăng xuất trong lúc chờ, câu trả lời của lần tải cũ bị bỏ, không ghi đè dữ liệu mới.
class HomeController extends ChangeNotifier {
  HomeController(this._dao);

  final HomeDao _dao;

  /// Từ khóa "Tìm trong bài dành cho bạn" tối đa 100 ký tự (giống server).
  static const int queryMax = 100;
  static const String queryTooLong = 'Từ khóa tìm kiếm tối đa $queryMax ký tự.';

  /// Câu hiện trong "Dành cho bạn" sau khi người dùng lưu khu vực, giai đoạn hoặc chủ đề quan tâm.
  static const String savedNotice = 'Đã lưu. Gợi ý bên dưới đã theo lựa chọn mới của bạn.';

  // ----- Trang chủ (HomeScreen)

  /// Trang chủ của khách; null khi đang là thành viên hoặc chưa tải.
  HomeGuest? guest;

  /// Trang chủ của thành viên; null khi đang là khách hoặc chưa tải.
  HomeMember? member;
  bool isLoadingHome = false;
  String? homeError;

  /// Câu báo thành công hiện một lần trong "Dành cho bạn" (sau khi lưu khu vực, giai đoạn, chủ đề).
  String? homeNotice;

  /// "Để sau": không tự mở lời nhắc chọn khu vực và giai đoạn nữa cho tới khi tắt app (web giữ trong sessionStorage).
  bool areaPromptHidden = false;
  int _homeTicket = 0;

  // ----- Dành cho bạn (ForYouScreen)

  /// Trang cuối cùng nhận được: phạm vi đang xem, số bài từng phạm vi, những gì gợi ý dựa vào, còn trang sau không.
  ForYouFeed? forYou;

  /// Mọi bài đã tải, không lặp (lượt thích có thể đổi thứ hạng giữa hai trang).
  List<FeedPost> forYouPosts = [];

  /// Từ khóa đang lọc (đã bỏ khoảng trắng hai đầu); rỗng khi không tìm.
  String forYouQuery = '';
  bool isLoadingForYou = false;
  bool isLoadingMoreForYou = false;
  String? forYouError;
  int _forYouTicket = 0;

  // ----- Review mới (RecentReviewsScreen)

  RecentReviewFeed? reviewFeed;
  List<RecentReview> reviews = [];
  bool isLoadingReviews = false;
  bool isLoadingMoreReviews = false;
  String? reviewsError;
  int _reviewsTicket = 0;

  // ---------------------------------------------------------------- Trang chủ

  /// Có lời nhắc chọn khu vực và giai đoạn: thành viên chưa chọn đủ hai thứ và chưa bấm "Để sau".
  bool get showAreaPrompt {
    final home = member;
    return home != null && !home.hasAreaAndStage && !areaPromptHidden;
  }

  /// Tải trang chủ đúng loại: thành viên khi [signedIn], ngược lại là khách. [notice] hiện sau khi tải xong
  /// (ví dụ [savedNotice]).
  Future<void> loadHome({required bool signedIn, String? notice}) async {
    final ticket = ++_homeTicket;
    // Đổi loại trang chủ (vừa đăng nhập / đăng xuất) thì bỏ trang cũ, để không hiện nhầm trong lúc chờ
    if (signedIn) {
      guest = null;
    } else {
      member = null;
    }
    isLoadingHome = true;
    homeError = null;
    homeNotice = null;
    notifyListeners();
    try {
      if (signedIn) {
        final home = await _dao.findMember();
        if (ticket == _homeTicket) {
          member = home;
          homeNotice = notice;
        }
      } else {
        final home = await _dao.findGuest();
        if (ticket == _homeTicket) {
          guest = home;
        }
      }
    } on ApiException catch (e) {
      if (ticket == _homeTicket) {
        homeError = e.message;
      }
    } finally {
      if (ticket == _homeTicket) {
        isLoadingHome = false;
        notifyListeners();
      }
    }
  }

  /// "Để sau" của lời nhắc chọn khu vực và giai đoạn.
  void hideAreaPrompt() {
    areaPromptHidden = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------- Dành cho bạn

  /// Mở "Dành cho bạn" từ đầu: phạm vi do server chọn (Tất cả), tìm sẵn [q] khi có.
  Future<void> openForYou({String q = ''}) {
    forYou = null;
    forYouPosts = [];
    forYouQuery = '';
    forYouError = null;
    return loadForYou(q: q);
  }

  /// Tải trang đầu. [scope] null: giữ phạm vi đang xem; [q] null: giữ từ khóa đang tìm.
  /// Từ khóa quá 100 ký tự thì báo lỗi, không gọi server.
  Future<void> loadForYou({String? scope, String? q}) async {
    final text = (q ?? forYouQuery).trim();
    if (text.length > queryMax) {
      forYouError = queryTooLong;
      notifyListeners();
      return;
    }
    final ticket = ++_forYouTicket;
    forYouQuery = text;
    isLoadingForYou = true;
    isLoadingMoreForYou = false;
    forYouError = null;
    notifyListeners();
    try {
      final feed = await _dao.findForYou(scope: scope ?? forYou?.scope, q: text);
      if (ticket == _forYouTicket) {
        forYou = feed;
        forYouPosts = _appendNew(const [], feed.items);
      }
    } on ApiException catch (e) {
      if (ticket == _forYouTicket) {
        forYouError = e.message;
      }
    } finally {
      if (ticket == _forYouTicket) {
        isLoadingForYou = false;
        notifyListeners();
      }
    }
  }

  /// "Tìm trong bài dành cho bạn": chỉ hỏi lại khi từ khóa thật sự đổi; [always] khi bấm Enter (hỏi lại cả sau lỗi).
  Future<void> searchForYou(String text, {bool always = false}) async {
    if (text.trim() == forYouQuery && !always) {
      return;
    }
    await loadForYou(q: text);
  }

  /// "Xem thêm bài viết": trang sau, cùng phạm vi và từ khóa; bài đã có trên màn hình không thêm lần nữa.
  Future<void> loadMoreForYou() async {
    final feed = forYou;
    if (feed == null || !feed.hasMore || isLoadingForYou || isLoadingMoreForYou) {
      return;
    }
    final ticket = _forYouTicket;
    isLoadingMoreForYou = true;
    forYouError = null;
    notifyListeners();
    try {
      final next = await _dao.findForYou(scope: feed.scope, page: feed.page + 1, q: forYouQuery);
      if (ticket == _forYouTicket) {
        forYou = next;
        forYouPosts = _appendNew(forYouPosts, next.items);
      }
    } on ApiException catch (e) {
      if (ticket == _forYouTicket) {
        forYouError = e.message;
      }
    } finally {
      if (ticket == _forYouTicket) {
        isLoadingMoreForYou = false;
        notifyListeners();
      }
    }
  }

  static List<FeedPost> _appendNew(List<FeedPost> shown, List<FeedPost> next) {
    final ids = {for (final p in shown) p.id};
    return [
      ...shown,
      for (final p in next)
        if (ids.add(p.id)) p,
    ];
  }

  // ---------------------------------------------------------------- Review mới

  /// Mở "Review mới" từ đầu: server mở phạm vi đầu tiên có review (khách: Tất cả).
  Future<void> openReviews() {
    reviewFeed = null;
    reviews = [];
    reviewsError = null;
    return loadReviews();
  }

  /// Tải trang đầu. [scope] null: giữ phạm vi đang xem.
  Future<void> loadReviews({String? scope}) async {
    final ticket = ++_reviewsTicket;
    isLoadingReviews = true;
    isLoadingMoreReviews = false;
    reviewsError = null;
    notifyListeners();
    try {
      final feed = await _dao.findRecentReviews(scope: scope ?? reviewFeed?.scope);
      if (ticket == _reviewsTicket) {
        reviewFeed = feed;
        reviews = feed.items;
      }
    } on ApiException catch (e) {
      if (ticket == _reviewsTicket) {
        reviewsError = e.message;
      }
    } finally {
      if (ticket == _reviewsTicket) {
        isLoadingReviews = false;
        notifyListeners();
      }
    }
  }

  /// "Xem thêm review": trang sau của phạm vi đang xem.
  Future<void> loadMoreReviews() async {
    final feed = reviewFeed;
    if (feed == null || !feed.hasMore || isLoadingReviews || isLoadingMoreReviews) {
      return;
    }
    final ticket = _reviewsTicket;
    isLoadingMoreReviews = true;
    reviewsError = null;
    notifyListeners();
    try {
      final next = await _dao.findRecentReviews(scope: feed.scope, page: feed.page + 1);
      if (ticket == _reviewsTicket) {
        reviewFeed = next;
        final ids = {for (final r in reviews) r.id};
        reviews = [
          ...reviews,
          for (final r in next.items)
            if (ids.add(r.id)) r,
        ];
      }
    } on ApiException catch (e) {
      if (ticket == _reviewsTicket) {
        reviewsError = e.message;
      }
    } finally {
      if (ticket == _reviewsTicket) {
        isLoadingMoreReviews = false;
        notifyListeners();
      }
    }
  }
}
