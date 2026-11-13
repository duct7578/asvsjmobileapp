// Widget test của RecentReviewsScreen ("Review mới"): khách chỉ có Tất cả; thành viên chọn phạm vi, tải thêm.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/empty_view.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/recent_review_card.dart';
import 'package:myasvsj/com.myasvsj.screen/recent_reviews_screen.dart';

import 'home_fakes.dart';

void main() {
  testWidgets('khách: chỉ Tất cả, lời mời đăng nhập; bấm Đăng nhập ra màn Đăng nhập', (tester) async {
    final dao = FakeHomeDao()..reviewsAsGuest = true;
    await tester.pumpWidget(homeTestApp(home: const RecentReviewsScreen(), homeDao: dao));
    await tester.pumpAndSettle();

    expect(dao.reviewCalls.single, (scope: null, page: 0));
    expect(find.textContaining('15 review trên Senpai ơi, mới nhất trước.'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(find.text('Đăng nhập và chọn khu vực để xem review quanh bạn.'), findsOneWidget);
    expect(find.byType(RecentReviewCard), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('thành viên: ba phạm vi kèm số; chọn Cả tỉnh thì tải lại', (tester) async {
    final dao = FakeHomeDao();
    await tester.pumpWidget(homeTestApp(home: const RecentReviewsScreen(), homeDao: dao, signedIn: true));
    await tester.pumpAndSettle();

    expect(find.text('Quanh Arakawa-ku · 7'), findsOneWidget);
    expect(find.text('Cả tỉnh Tokyo · 15'), findsOneWidget);
    expect(find.text('Tất cả · 15'), findsOneWidget);
    expect(find.textContaining('7 review quanh Arakawa-ku'), findsOneWidget);
    expect(find.text('Gần bạn'), findsWidgets);

    await tester.tap(find.text('Cả tỉnh Tokyo · 15'));
    await tester.pumpAndSettle();
    expect(dao.reviewCalls.last, (scope: 'PREFECTURE', page: 0));
    expect(find.textContaining('15 review trong tỉnh Tokyo'), findsOneWidget);
    expect(find.text('Cùng tỉnh'), findsWidgets);
  });

  testWidgets('review: số sao, Hữu ích (hơn 10 lượt thích), nút Xem thêm review', (tester) async {
    // Màn hình cao, cả trang vừa khung: không cuộn nên chỉ nút "Xem thêm" tải trang sau
    tester.view.physicalSize = const Size(800, 9000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final dao = FakeHomeDao();
    await tester.pumpWidget(homeTestApp(home: const RecentReviewsScreen(), homeDao: dao, signedIn: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tất cả · 15'));
    await tester.pumpAndSettle();

    expect(find.text('Quán số 1'), findsOneWidget);
    // Hàng sao đọc được bằng trình đọc màn hình (nhãn nằm trong nhãn của cả thẻ)
    expect(find.bySemanticsLabel(RegExp('4 trên 5 sao')), findsWidgets);
    expect(find.text('Hữu ích'), findsNothing);

    await tester.tap(find.text('Xem thêm review'));
    await tester.pumpAndSettle();
    expect(dao.reviewCalls.last, (scope: 'ALL', page: 1));
    expect(find.text('Xem thêm review'), findsNothing);
    // Review 11–15 có hơn 10 lượt thích
    expect(find.text('Hữu ích'), findsNWidgets(5));
  });

  testWidgets('cuộn tới cuối danh sách thì tự tải trang sau', (tester) async {
    final dao = FakeHomeDao();
    await tester.pumpWidget(homeTestApp(home: const RecentReviewsScreen(), homeDao: dao, signedIn: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tất cả · 15'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Quán số 13'), 300, scrollable: vertical);
    expect(dao.reviewCalls.last, (scope: 'ALL', page: 1));
  });

  testWidgets('chưa có review: câu rỗng và Mở Bản đồ', (tester) async {
    final dao = FakeHomeDao()..recent = [];
    await tester.pumpWidget(homeTestApp(home: const RecentReviewsScreen(), homeDao: dao, signedIn: true));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyView), findsOneWidget);
    expect(find.textContaining('Chưa có review nào quanh Arakawa-ku'), findsOneWidget);
    expect(find.text('Mở Bản đồ'), findsOneWidget);
  });

  testWidgets('lỗi server: câu báo lỗi và Thử lại', (tester) async {
    final dao = FakeHomeDao()..failWith = const ApiException('Không kết nối được tới server.');
    await tester.pumpWidget(homeTestApp(home: const RecentReviewsScreen(), homeDao: dao));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);

    dao.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byType(RecentReviewCard), findsWidgets);
  });

  testWidgets('đăng nhập khi đang xem: mở lại với phạm vi của thành viên', (tester) async {
    final dao = FakeHomeDao()..reviewsAsGuest = true;
    final auth = homeTestAuth();
    await tester.pumpWidget(homeTestApp(home: const RecentReviewsScreen(), homeDao: dao, auth: auth));
    await tester.pumpAndSettle();
    expect(find.byType(ChoiceChip), findsNothing);

    dao.reviewsAsGuest = false;
    await auth.login('an@example.com', '123456');
    await tester.pumpAndSettle();
    expect(dao.reviewCalls, hasLength(2));
    expect(find.text('Quanh Arakawa-ku · 7'), findsOneWidget);
  });
}
