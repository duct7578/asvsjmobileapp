import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/for_you_feed.dart';
import 'package:myasvsj/com.myasvsj.model/home_guest.dart';
import 'package:myasvsj/com.myasvsj.model/home_member.dart';
import 'package:myasvsj/com.myasvsj.model/recent_review_feed.dart';

/// Đọc dữ liệu trang chủ, "Dành cho bạn" và "Review mới" qua REST API của web (chỉ đọc).
///
/// | Hàm               | API                                   | Ai gọi được        |
/// |-------------------|---------------------------------------|--------------------|
/// | findGuest         | GET /api/home                         | mọi người          |
/// | findMember        | GET /api/me/home                      | người đã đăng nhập |
/// | findForYou        | GET /api/me/for-you?scope=&page=&q=   | người đã đăng nhập |
/// | findRecentReviews | GET /api/home/reviews?scope=&page=    | mọi người          |
class HomeDao {
  HomeDao(this._api);

  final ApiClient _api;

  /// Số bài / review mỗi trang của "Dành cho bạn" và "Review mới" (server cố định).
  static const int pageSize = 10;

  /// Trang chủ của khách: số liệu, review "Hữu ích" ("Senpai nói gì"), câu tiếng Nhật hôm nay.
  Future<HomeGuest> findGuest() async => HomeGuest.fromJson(await _api.get('/api/home') as Map<String, dynamic>);

  /// Trang chủ của thành viên. Khách nhận 401.
  Future<HomeMember> findMember() async => HomeMember.fromJson(await _api.get('/api/me/home') as Map<String, dynamic>);

  /// Một trang "Dành cho bạn" (trang đầu là 0). [scope] ALL, NEAR, STAGE hoặc INTEREST (null: server chọn ALL);
  /// [q] chỉ giữ bài có chữ đó (tối đa 100 ký tự, dài hơn server trả 400). Khách nhận 401.
  Future<ForYouFeed> findForYou({String? scope, int page = 0, String? q}) async {
    final data =
        await _api.get(
              '/api/me/for-you',
              query: {
                if (scope != null && scope.isNotEmpty) 'scope': scope,
                'page': page,
                if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
              },
            )
            as Map<String, dynamic>;
    return ForYouFeed.fromJson(data);
  }

  /// Một trang "Review mới" (trang đầu là 0). [scope] AREA, PREFECTURE hoặc ALL; null: server mở phạm vi đầu tiên
  /// có review. Khách và thành viên chưa chọn khu vực chỉ có ALL.
  Future<RecentReviewFeed> findRecentReviews({String? scope, int page = 0}) async {
    final data =
        await _api.get(
              '/api/home/reviews',
              query: {if (scope != null && scope.isNotEmpty) 'scope': scope, 'page': page},
            )
            as Map<String, dynamic>;
    return RecentReviewFeed.fromJson(data);
  }
}
