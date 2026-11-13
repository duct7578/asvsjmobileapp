// Unit test của HomeController với DAO giả: trang chủ, "Dành cho bạn", "Review mới".
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/home_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';

import 'home_fakes.dart';

void main() {
  late FakeHomeDao dao;
  late HomeController controller;

  setUp(() {
    dao = FakeHomeDao();
    controller = HomeController(dao);
  });

  group('Trang chủ', () {
    test('khách: tải GET /api/home, có trạng thái chờ', () async {
      final future = controller.loadHome(signedIn: false);
      expect(controller.isLoadingHome, isTrue);
      await future;
      expect(controller.isLoadingHome, isFalse);
      expect(controller.guest?.reviewCount, 9);
      expect(controller.member, isNull);
      expect(controller.homeError, isNull);
      expect(dao.guestCalls, 1);
      expect(dao.memberCalls, 0);
    });

    test('thành viên: tải GET /api/me/home và câu báo đã lưu', () async {
      await controller.loadHome(signedIn: true, notice: HomeController.savedNotice);
      expect(controller.member?.displayName, 'Trần Minh');
      expect(controller.guest, isNull);
      expect(controller.homeNotice, HomeController.savedNotice);
      expect(dao.memberCalls, 1);

      // Tải lại bình thường thì không hiện câu báo nữa
      await controller.loadHome(signedIn: true);
      expect(controller.homeNotice, isNull);
    });

    test('lỗi server: giữ câu báo lỗi, tắt trạng thái chờ', () async {
      dao.failWith = const ApiException('Không kết nối được tới server.');
      await controller.loadHome(signedIn: false);
      expect(controller.homeError, 'Không kết nối được tới server.');
      expect(controller.guest, isNull);
      expect(controller.isLoadingHome, isFalse);
    });

    test('tải lại bị lỗi vẫn giữ trang chủ cũ', () async {
      await controller.loadHome(signedIn: true);
      dao.failWith = const ApiException('Server phản hồi quá lâu. Hãy thử lại.');
      await controller.loadHome(signedIn: true);
      expect(controller.member, isNotNull);
      expect(controller.homeError, 'Server phản hồi quá lâu. Hãy thử lại.');
    });

    test('đăng xuất: bỏ ngay trang chủ thành viên, không hiện nhầm trong lúc chờ', () async {
      await controller.loadHome(signedIn: true);
      dao.hold = true;
      final future = controller.loadHome(signedIn: false);
      expect(controller.member, isNull);
      expect(controller.guest, isNull);
      await dao.release();
      await future;
      expect(controller.guest, isNotNull);
    });

    test('câu trả lời của lần tải cũ bị bỏ (đăng nhập rồi đăng xuất khi đang chờ)', () async {
      dao.hold = true;
      final asMember = controller.loadHome(signedIn: true);
      final asGuest = controller.loadHome(signedIn: false);
      await dao.release(1);
      await asGuest;
      await dao.release(0);
      await asMember;
      expect(controller.guest, isNotNull);
      expect(controller.member, isNull);
      expect(controller.isLoadingHome, isFalse);
    });

    test('lời nhắc chọn khu vực: hiện khi thiếu khu vực hoặc giai đoạn, "Để sau" thì ẩn', () async {
      await controller.loadHome(signedIn: true);
      expect(controller.showAreaPrompt, isFalse);

      dao.member = memberWithoutArea;
      await controller.loadHome(signedIn: true);
      expect(controller.showAreaPrompt, isTrue);

      var notified = false;
      controller.addListener(() => notified = true);
      controller.hideAreaPrompt();
      expect(notified, isTrue);
      expect(controller.showAreaPrompt, isFalse);
      // Tải lại vẫn nhớ "Để sau"
      await controller.loadHome(signedIn: true);
      expect(controller.showAreaPrompt, isFalse);
    });
  });

  group('Dành cho bạn', () {
    test('mở: trang đầu 10 bài, phạm vi do server chọn', () async {
      final future = controller.openForYou();
      expect(controller.isLoadingForYou, isTrue);
      await future;
      expect(controller.isLoadingForYou, isFalse);
      expect(dao.forYouCalls.single, (scope: null, page: 0, q: ''));
      expect(controller.forYou?.scope, 'ALL');
      expect(controller.forYou?.countOf('ALL'), 25);
      expect(controller.forYouPosts.map((p) => p.id), [for (var i = 1; i <= 10; i++) i]);
      expect(controller.forYou?.hasMore, isTrue);
    });

    test('mở với từ khóa có sẵn', () async {
      await controller.openForYou(q: '  Bài số 2 ');
      expect(dao.forYouCalls.single.q, 'Bài số 2');
      expect(controller.forYouQuery, 'Bài số 2');
      expect(controller.forYouPosts.map((p) => p.id), [2, 20, 21, 22, 23, 24, 25]);
    });

    test('Xem thêm: nối trang sau, hết trang thì không gọi server nữa', () async {
      await controller.openForYou();
      await controller.loadMoreForYou();
      expect(dao.forYouCalls.last, (scope: 'ALL', page: 1, q: ''));
      expect(controller.forYouPosts, hasLength(20));
      await controller.loadMoreForYou();
      expect(controller.forYouPosts, hasLength(25));
      expect(controller.forYou?.hasMore, isFalse);

      final calls = dao.forYouCalls.length;
      await controller.loadMoreForYou();
      expect(dao.forYouCalls.length, calls);
    });

    test('bài đã có trên màn hình không thêm lần nữa khi thứ hạng đổi giữa hai trang', () async {
      dao.repeatLastOnNextPage = true;
      await controller.openForYou();
      await controller.loadMoreForYou();
      final ids = controller.forYouPosts.map((p) => p.id).toList();
      expect(ids, hasLength(20));
      expect(ids.toSet(), hasLength(20));
    });

    test('đổi phạm vi: tải lại từ trang đầu, giữ từ khóa', () async {
      await controller.openForYou(q: 'Bài');
      await controller.loadMoreForYou();
      await controller.loadForYou(scope: 'NEAR');
      expect(dao.forYouCalls.last, (scope: 'NEAR', page: 0, q: 'Bài'));
      expect(controller.forYou?.scope, 'NEAR');
      expect(controller.forYouPosts.every((p) => p.id.isEven), isTrue);
      expect(controller.forYouPosts, hasLength(10));
    });

    test('tìm: chỉ hỏi lại khi chữ đổi; Enter thì luôn hỏi', () async {
      await controller.openForYou();
      await controller.searchForYou('Bài số 1');
      expect(dao.forYouCalls.last.q, 'Bài số 1');
      final calls = dao.forYouCalls.length;

      await controller.searchForYou('  Bài số 1  ');
      expect(dao.forYouCalls.length, calls);

      await controller.searchForYou('Bài số 1', always: true);
      expect(dao.forYouCalls.length, calls + 1);
    });

    test('từ khóa quá 100 ký tự: báo lỗi, không gọi server, giữ danh sách', () async {
      await controller.openForYou();
      final calls = dao.forYouCalls.length;
      await controller.searchForYou('x' * 101);
      expect(dao.forYouCalls.length, calls);
      expect(controller.forYouError, HomeController.queryTooLong);
      expect(controller.forYouPosts, hasLength(10));
    });

    test('lỗi server: giữ câu báo lỗi; lỗi khi tải thêm vẫn giữ bài đã có', () async {
      dao.failWith = const ApiException('Bạn cần đăng nhập để làm việc này.', statusCode: 401);
      await controller.openForYou();
      expect(controller.forYouError, 'Bạn cần đăng nhập để làm việc này.');
      expect(controller.forYou, isNull);

      dao.failWith = null;
      await controller.loadForYou();
      expect(controller.forYouError, isNull);
      dao.failWith = const ApiException('Không kết nối được tới server.');
      await controller.loadMoreForYou();
      expect(controller.forYouError, 'Không kết nối được tới server.');
      expect(controller.forYouPosts, hasLength(10));
      expect(controller.isLoadingMoreForYou, isFalse);
    });

    test('đổi phạm vi khi trang cũ chưa về: bỏ câu trả lời cũ', () async {
      await controller.openForYou();
      dao.hold = true;
      final near = controller.loadForYou(scope: 'NEAR');
      final stage = controller.loadForYou(scope: 'STAGE');
      await dao.release(1);
      await stage;
      await dao.release(0);
      await near;
      expect(controller.forYou?.scope, 'STAGE');
      expect(controller.forYouPosts.every((p) => p.id.isOdd), isTrue);
    });

    test('tải thêm đang chờ thì bị bỏ khi người dùng đổi phạm vi', () async {
      await controller.openForYou();
      dao.hold = true;
      final more = controller.loadMoreForYou();
      final near = controller.loadForYou(scope: 'NEAR');
      await dao.release(1);
      await near;
      await dao.release(0);
      await more;
      expect(controller.forYou?.scope, 'NEAR');
      expect(controller.forYouPosts, hasLength(10));
      expect(controller.isLoadingMoreForYou, isFalse);
    });
  });

  group('Review mới', () {
    test('mở: server chọn phạm vi đầu tiên có review', () async {
      final future = controller.openReviews();
      expect(controller.isLoadingReviews, isTrue);
      await future;
      expect(dao.reviewCalls.single, (scope: null, page: 0));
      expect(controller.reviewFeed?.scope, 'AREA');
      expect(controller.reviews, hasLength(7));
      expect(controller.reviewFeed?.hasMore, isFalse);
    });

    test('phạm vi Tất cả: 10 review, Xem thêm nối trang sau', () async {
      await controller.openReviews();
      await controller.loadReviews(scope: 'ALL');
      expect(controller.reviews, hasLength(10));
      await controller.loadMoreReviews();
      expect(dao.reviewCalls.last, (scope: 'ALL', page: 1));
      expect(controller.reviews, hasLength(15));
      expect(controller.reviewFeed?.hasMore, isFalse);

      final calls = dao.reviewCalls.length;
      await controller.loadMoreReviews();
      expect(dao.reviewCalls.length, calls);
    });

    test('mở lại thì bỏ phạm vi cũ (ví dụ vừa đăng xuất)', () async {
      await controller.openReviews();
      await controller.loadReviews(scope: 'PREFECTURE');
      dao.reviewsAsGuest = true;
      await controller.openReviews();
      expect(dao.reviewCalls.last, (scope: null, page: 0));
      expect(controller.reviewFeed?.scope, 'ALL');
      expect(controller.reviewFeed?.scopes, hasLength(1));
    });

    test('lỗi server: giữ câu báo lỗi; tải thêm lỗi vẫn giữ review đã có', () async {
      dao.failWith = const ApiException('Đã có lỗi xảy ra. Vui lòng thử lại sau.');
      await controller.openReviews();
      expect(controller.reviewsError, 'Đã có lỗi xảy ra. Vui lòng thử lại sau.');
      expect(controller.isLoadingReviews, isFalse);

      dao.failWith = null;
      await controller.loadReviews(scope: 'ALL');
      dao.failWith = const ApiException('Không kết nối được tới server.');
      await controller.loadMoreReviews();
      expect(controller.reviewsError, 'Không kết nối được tới server.');
      expect(controller.reviews, hasLength(10));
    });
  });
}
