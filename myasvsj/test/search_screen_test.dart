// Widget test của GlobalSearchScreen ("Tìm kiếm"): gợi ý, kết quả theo phần, quá ngắn, không thấy gì, lỗi.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/for_you_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/global_search_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';

import 'home_fakes.dart';

void main() {
  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.scrollUntilVisible(finder, 300, scrollable: vertical);

  testWidgets('ô trống: gợi ý; bấm gợi ý thì tìm chữ đó', (tester) async {
    final dao = FakeSearchDao();
    await tester.pumpWidget(homeTestApp(home: const GlobalSearchScreen(), searchDao: dao));
    await tester.pumpAndSettle();

    expect(dao.asked, isEmpty);
    expect(find.text('Thử tìm:'), findsOneWidget);
    await tester.tap(find.text('Thẻ cư trú'));
    await tester.pumpAndSettle();
    expect(dao.asked, ['Thẻ cư trú']);
    expect(find.text('Tìm thấy 6 kết quả cho “thẻ cư trú”.'), findsOneWidget);
    expect(find.text('Cẩm nang'), findsWidgets);
    await scrollTo(tester, find.text('Nếu làm mất thẻ cư trú tại Nhật thì phải làm gì?'));
  });

  testWidgets('mở với chữ của trang chủ: tóm tắt, nút nhảy, các phần', (tester) async {
    final dao = FakeSearchDao();
    await tester.pumpWidget(
      homeTestApp(
        home: const GlobalSearchScreen(initialQuery: 'Nippori'),
        searchDao: dao,
      ),
    );
    await tester.pumpAndSettle();

    expect(dao.asked, ['Nippori']);
    expect(find.text('Tìm thấy 16 kết quả cho “Nippori”.'), findsOneWidget);
    expect(find.text('Địa điểm 7'), findsOneWidget);
    expect(find.text('Bài viết 5'), findsOneWidget);
    expect(find.text('Hỏi-Đáp 1'), findsOneWidget);
    expect(find.text('Sự kiện 3'), findsOneWidget);
    expect(find.text('Ga Nippori'), findsOneWidget);
    // Khách không có "Chỉ tìm trong bài dành cho bạn"
    expect(find.text('Chỉ tìm trong bài dành cho bạn', skipOffstage: false), findsNothing);

    // Nút nhảy cuộn tới phần Sự kiện
    await tester.tap(find.text('Sự kiện 3'));
    await tester.pumpAndSettle();
    expect(find.text('Lễ hội phố vải Nippori'), findsOneWidget);
    expect(find.text('Chưa ai trả lời', skipOffstage: false), findsOneWidget);
  });

  testWidgets('thành viên: "Chỉ tìm trong bài dành cho bạn" mở Dành cho bạn với chữ đó', (tester) async {
    final home = FakeHomeDao();
    await tester.pumpWidget(
      homeTestApp(
        home: const GlobalSearchScreen(initialQuery: 'Nippori'),
        homeDao: home,
        signedIn: true,
      ),
    );
    await tester.pumpAndSettle();

    final onlyMine = find.text('Chỉ tìm trong bài dành cho bạn');
    await scrollTo(tester, onlyMine);
    await tester.tap(onlyMine);
    await tester.pumpAndSettle();
    expect(find.byType(ForYouScreen), findsOneWidget);
    expect(home.forYouCalls.single.q, 'Nippori');
  });

  testWidgets('gõ: chờ một chút rồi tìm; chữ quá ngắn thì nhắc', (tester) async {
    final dao = FakeSearchDao();
    await tester.pumpWidget(homeTestApp(home: const GlobalSearchScreen(), searchDao: dao));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('global-search')), 'a');
    await tester.pump(const Duration(milliseconds: 100));
    expect(dao.asked, isEmpty);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(dao.asked, ['a']);
    expect(find.text('Hãy gõ ít nhất 2 chữ hoặc số (một chữ tiếng Nhật cũng được).'), findsOneWidget);
  });

  testWidgets('không thấy gì: gợi ý; khách bấm Đặt câu hỏi thì ra màn Đăng nhập', (tester) async {
    await tester.pumpWidget(homeTestApp(home: const GlobalSearchScreen(initialQuery: 'xyz không có')));
    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy kết quả nào cho “xyz không có”.'), findsOneWidget);
    expect(find.text('Gợi ý'), findsOneWidget);
    await tester.tap(find.text('Đặt câu hỏi cho các senpai'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('lỗi server: câu báo lỗi và Thử lại', (tester) async {
    final dao = FakeSearchDao()..failWith = const ApiException('Không kết nối được tới server.');
    await tester.pumpWidget(
      homeTestApp(
        home: const GlobalSearchScreen(initialQuery: 'Nippori'),
        searchDao: dao,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Không kết nối được tới server.'), findsOneWidget);

    dao.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Ga Nippori'), findsOneWidget);
  });
}
