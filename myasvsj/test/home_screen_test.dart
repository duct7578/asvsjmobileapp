// Widget test của HomeScreen: khách và thành viên, trạng thái chờ / lỗi, lời nhắc chọn khu vực,
// tải lại khi đăng nhập / đăng xuất, ô tìm kiếm và "Xem tất cả".
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/feed_basis.dart';
import 'package:myasvsj/com.myasvsj.screen/feed_post_card.dart';
import 'package:myasvsj/com.myasvsj.screen/for_you_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/global_search_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/home_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/recent_reviews_screen.dart';

import 'home_fakes.dart';

void main() {
  /// Cuộn danh sách trang chủ tới khi thấy [finder].
  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(finder, 300, scrollable: vertical);

  group('Khách', () {
    testWidgets('hiện lời mời, số liệu, review "Hữu ích", mẫu câu; không gọi API thành viên', (tester) async {
      final dao = FakeHomeDao();
      await tester.pumpWidget(homeTestApp(home: const HomeScreen(), homeDao: dao));
      await tester.pumpAndSettle();

      expect(find.text('Ở Nhật, bạn không đi một mình.'), findsOneWidget);
      expect(find.text('Đăng ký miễn phí'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('review của người Việt'), findsOneWidget);
      expect(dao.guestCalls, 1);
      expect(dao.memberCalls, 0);

      await scrollTo(tester, find.text('Senpai nói gì'));
      expect(find.textContaining('Đăng ký cư trú ở tầng 1'), findsOneWidget);
      await scrollTo(tester, find.text('温めてください。'));
      expect(find.text('Câu tiếng Nhật hôm nay'), findsOneWidget);
      expect(find.text('Nghe'), findsOneWidget);
      await scrollTo(tester, find.text('Quy tắc cộng đồng'));
    });

    testWidgets('đang tải thì hiện vòng quay', (tester) async {
      final dao = FakeHomeDao()..hold = true;
      await tester.pumpWidget(homeTestApp(home: const HomeScreen(), homeDao: dao));
      await tester.pump();
      expect(find.byType(LoadingView), findsOneWidget);

      dao.pending.single.complete();
      await tester.pumpAndSettle();
      expect(find.byType(LoadingView), findsNothing);
      expect(find.text('Ở Nhật, bạn không đi một mình.'), findsOneWidget);
    });

    testWidgets('lỗi server: câu báo lỗi và Thử lại', (tester) async {
      final dao = FakeHomeDao()..failWith = const ApiException('Không kết nối được tới server.');
      await tester.pumpWidget(homeTestApp(home: const HomeScreen(), homeDao: dao));
      await tester.pumpAndSettle();
      expect(find.byType(ErrorView), findsOneWidget);
      expect(find.text('Không kết nối được tới server.'), findsOneWidget);

      dao.failWith = null;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('Ở Nhật, bạn không đi một mình.'), findsOneWidget);
    });

    testWidgets('khách bấm Tin nhắn trên thanh tiêu đề thì được đưa sang Đăng nhập', (tester) async {
      await tester.pumpWidget(homeTestApp(home: const HomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Tin nhắn'));
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('ô tìm kiếm: trống thì không mở; có chữ thì mở Tìm kiếm với chữ đó', (tester) async {
      final search = FakeSearchDao();
      await tester.pumpWidget(homeTestApp(home: const HomeScreen(), searchDao: search));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Tìm'));
      await tester.pumpAndSettle();
      expect(find.byType(GlobalSearchScreen), findsNothing);

      await tester.enterText(find.byKey(const ValueKey('home-search')), 'Nippori');
      await tester.tap(find.text('Tìm'));
      await tester.pumpAndSettle();
      expect(find.byType(GlobalSearchScreen), findsOneWidget);
      expect(search.asked, ['Nippori']);
      expect(find.text('Ga Nippori'), findsOneWidget);
    });
  });

  group('Thành viên', () {
    testWidgets('hiện lời chào, Dành cho bạn với lý do, cẩm nang, Việc tiếp theo, review, sự kiện, bài nổi bật', (
      tester,
    ) async {
      final dao = FakeHomeDao();
      await tester.pumpWidget(homeTestApp(home: const HomeScreen(), homeDao: dao, signedIn: true));
      await tester.pumpAndSettle();

      expect(dao.memberCalls, 1);
      expect(find.text('Chào Minh, dạo này ở Arakawa-ku thế nào rồi?'), findsOneWidget);
      expect(find.text('45 điểm · Người mới'), findsOneWidget);
      // Giai đoạn hiện ở lời chào (badge) và trong "Dựa trên"
      expect(find.text('Mới đến'), findsNWidgets(2));

      // Thứ tự như thiết kế: "Việc tiếp theo" ngay dưới ô tìm kiếm, rồi "Dành cho bạn"
      await scrollTo(tester, find.text('Việc tiếp theo'));
      await scrollTo(tester, find.text('0/10 · Khi mới đến (tuần đầu đến 3 tháng)'));
      await scrollTo(tester, find.text('Mở cẩm nang này'));
      expect(find.text('0/6 việc · Tiếp theo: Hộ chiếu còn hiệu lực'), findsOneWidget);

      await scrollTo(tester, find.text('Dành cho bạn'));
      expect(find.text('Dành cho bạn'), findsOneWidget);
      expect(find.text('Dựa trên'), findsOneWidget);
      expect(find.text('Arakawa-ku'), findsOneWidget);
      expect(find.descendant(of: find.byType(FeedBasis), matching: find.text('Mới đến')), findsOneWidget);
      expect(find.text('Mua sắm'), findsOneWidget);
      expect(find.textContaining('Chủ đề quan tâm được rút ra từ'), findsOneWidget);
      // Không có lời nhắc khi đã chọn đủ khu vực và giai đoạn
      expect(find.byKey(const ValueKey('area-prompt')), findsNothing);

      await scrollTo(tester, find.text('Tin nhắn tuyển việc làm thêm lương cao quanh ga'));
      expect(find.textContaining('Gần khu vực của bạn'), findsWidgets);
      // Bài đầu có đoạn trích
      expect(find.textContaining('Gần đây có tài khoản'), findsOneWidget);

      await scrollTo(tester, find.text('Cẩm nang cho giai đoạn Mới đến'));
      await scrollTo(tester, find.text('Review mới quanh Arakawa-ku'));
      await scrollTo(tester, find.text('Sự kiện 2 tuần tới'));
      await scrollTo(tester, find.text('Chợ phiên cuối tuần phố Yanaka Ginza'));
      expect(find.text('Đang diễn ra · Phố Yanaka Ginza'), findsOneWidget);
      await scrollTo(tester, find.text('Bài nổi bật tuần này'));
    });

    testWidgets('chưa chọn khu vực và giai đoạn: lời nhắc; "Để sau" thì ẩn', (tester) async {
      final dao = FakeHomeDao()..member = memberWithoutArea;
      await tester.pumpWidget(homeTestApp(home: const HomeScreen(), homeDao: dao, signedIn: true));
      await tester.pumpAndSettle();

      expect(find.text('Chào Minh!'), findsOneWidget);
      expect(find.text('Chưa chọn khu vực'), findsOneWidget);
      expect(find.text('Chưa chọn giai đoạn'), findsOneWidget);
      expect(find.text('Mong bạn cho Senpai ơi biết khu vực bạn đang sinh sống'), findsOneWidget);
      expect(find.text('Chọn khu vực và giai đoạn'), findsOneWidget);
      expect(find.text('Chưa có bài viết phù hợp. Hãy xem thêm ở Blog.'), findsOneWidget);

      await tester.ensureVisible(find.text('Để sau'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Để sau'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('area-prompt')), findsNothing);
    });

    testWidgets('Điều chỉnh mở bảng chọn khu vực, giai đoạn hoặc chủ đề quan tâm', (tester) async {
      await tester.pumpWidget(homeTestApp(home: const HomeScreen(), signedIn: true));
      await tester.pumpAndSettle();

      // "Dành cho bạn" nằm dưới "Việc tiếp theo" (như thiết kế): cuộn tới nút trước khi bấm
      await tester.ensureVisible(find.text('Điều chỉnh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Điều chỉnh'));
      await tester.pumpAndSettle();
      expect(find.text('Điều chỉnh gợi ý dành cho bạn'), findsOneWidget);
      expect(find.text('Khu vực và giai đoạn'), findsOneWidget);
      expect(find.text('Chủ đề quan tâm'), findsOneWidget);
    });

    testWidgets('Xem tất cả mở Dành cho bạn; kính lúp mở với ô tìm kiếm', (tester) async {
      final dao = FakeHomeDao();
      await tester.pumpWidget(homeTestApp(home: const HomeScreen(), homeDao: dao, signedIn: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Xem tất cả').first);
      await tester.pumpAndSettle();
      expect(find.byType(ForYouScreen), findsOneWidget);
      expect(find.byType(FeedPostCard), findsWidgets);
      expect(dao.forYouCalls.single.page, 0);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Tìm trong bài dành cho bạn'));
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(find.byKey(const ValueKey('for-you-search')));
      expect(field.autofocus, isTrue);
    });

    testWidgets('"Tất cả" của Review mới mở màn Review mới', (tester) async {
      final dao = FakeHomeDao();
      await tester.pumpWidget(homeTestApp(home: const HomeScreen(), homeDao: dao, signedIn: true));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Review mới quanh Arakawa-ku'));
      await tester.tap(find.text('Tất cả').first);
      await tester.pumpAndSettle();
      expect(find.byType(RecentReviewsScreen), findsOneWidget);
      expect(dao.reviewCalls.single.scope, isNull);
    });

    testWidgets('tải lại bị lỗi: giữ trang cũ và báo lỗi ở đầu', (tester) async {
      final dao = FakeHomeDao();
      await tester.pumpWidget(homeTestApp(home: const HomeScreen(), homeDao: dao, signedIn: true));
      await tester.pumpAndSettle();

      dao.failWith = const ApiException('Server phản hồi quá lâu. Hãy thử lại.');
      await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
      await tester.pumpAndSettle();
      expect(find.text('Server phản hồi quá lâu. Hãy thử lại.'), findsOneWidget);
      expect(find.text('Dành cho bạn'), findsOneWidget);
    });
  });

  group('Màn hẹp 360 dp: không tràn', () {
    Future<void> pumpNarrow(WidgetTester tester, Widget app) async {
      tester.view.physicalSize = const Size(360, 3200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    testWidgets('khách', (tester) async {
      await pumpNarrow(tester, homeTestApp(home: const HomeScreen()));
      expect(find.text('Ở Nhật, bạn không đi một mình.'), findsOneWidget);
    });

    testWidgets('thành viên', (tester) async {
      await pumpNarrow(tester, homeTestApp(home: const HomeScreen(), signedIn: true));
      expect(find.text('Mở cẩm nang này'), findsOneWidget);
    });

    testWidgets('thành viên chưa chọn khu vực', (tester) async {
      await pumpNarrow(
        tester,
        homeTestApp(home: const HomeScreen(), homeDao: FakeHomeDao()..member = memberWithoutArea, signedIn: true),
      );
      expect(find.byKey(const ValueKey('area-prompt')), findsOneWidget);
    });

    testWidgets('Dành cho bạn và Tìm kiếm', (tester) async {
      await pumpNarrow(tester, homeTestApp(home: const ForYouScreen(), signedIn: true));
      expect(find.byType(FeedPostCard), findsWidgets);
      await pumpNarrow(tester, homeTestApp(home: const GlobalSearchScreen(initialQuery: 'Nippori')));
      expect(find.text('Ga Nippori'), findsOneWidget);
    });
  });

  testWidgets('đăng nhập thì tải trang chủ thành viên, đăng xuất thì về trang chủ khách', (tester) async {
    final dao = FakeHomeDao();
    final auth = homeTestAuth();
    await tester.pumpWidget(homeTestApp(home: const HomeScreen(), homeDao: dao, auth: auth));
    await tester.pumpAndSettle();
    expect(find.text('Ở Nhật, bạn không đi một mình.'), findsOneWidget);

    await auth.login('an@example.com', '123456');
    await tester.pumpAndSettle();
    expect(dao.memberCalls, 1);
    expect(find.text('Dành cho bạn'), findsOneWidget);
    expect(find.text('Ở Nhật, bạn không đi một mình.'), findsNothing);

    await auth.logout();
    await tester.pumpAndSettle();
    expect(dao.guestCalls, 2);
    expect(find.text('Ở Nhật, bạn không đi một mình.'), findsOneWidget);
    expect(find.text('Dành cho bạn'), findsNothing);
  });
}
