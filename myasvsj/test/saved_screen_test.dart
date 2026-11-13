// Widget test của màn "Đã lưu" (SavedScreen) với DAO giả.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/saved_kind.dart';
import 'package:myasvsj/com.myasvsj.model/saved_list.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/place_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/saved_screen.dart';

import 'profile_test_app.dart';
import 'saved_fakes.dart';

/// TabBar cuộn ngang trên màn hẹp: cuộn tới tab rồi mới bấm.
Future<void> _tapTab(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pumpAndSettle();
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tab có số mục; tab Địa điểm hiện địa điểm đã lưu', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(profileTestApp(const SavedScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Địa điểm (2)'), findsOneWidget);
    expect(find.text('Bài viết (1)'), findsOneWidget);
    expect(find.text('Câu hỏi (1)'), findsOneWidget);
    expect(find.text('Cẩm nang (1)'), findsOneWidget);
    expect(find.text('Ga Nippori'), findsOneWidget);
    expect(find.text('Ga tàu · Higashi-Nippori 6, Arakawa, Tokyo'), findsOneWidget);
    expect(find.text('Đã đóng cửa'), findsOneWidget);
    expect(find.byIcon(Symbols.train_rounded), findsOneWidget);
  });

  testWidgets('các tab khác hiện bài viết, câu hỏi đã giải quyết, cẩm nang', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(profileTestApp(const SavedScreen()));
    await tester.pumpAndSettle();

    await _tapTab(tester, 'Bài viết (1)');
    await tester.pumpAndSettle();
    expect(find.text('Năm điều mình ước biết trước tuần đầu ở Tokyo'), findsOneWidget);
    expect(find.text('Lan Anh'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);

    await _tapTab(tester, 'Câu hỏi (1)');
    await tester.pumpAndSettle();
    expect(find.text('Đã giải quyết'), findsOneWidget);

    await _tapTab(tester, 'Cẩm nang (1)');
    await tester.pumpAndSettle();
    expect(find.text('Cách phân loại và bỏ rác tại Nhật Bản'), findsOneWidget);
    expect(find.text('Khi mới đến (tuần đầu đến 3 tháng)'), findsOneWidget);
    expect(find.text('Sinh hoạt'), findsOneWidget);
  });

  testWidgets('chưa lưu gì thì mỗi tab có câu "chưa lưu"', (tester) async {
    await tester.pumpWidget(profileTestApp(const SavedScreen(), savedDao: FakeSavedDao(const SavedList())));
    await tester.pumpAndSettle();
    expect(find.text('Địa điểm'), findsOneWidget, reason: 'không có số khi trống');
    expect(find.text('Chưa lưu địa điểm nào.'), findsOneWidget);

    await _tapTab(tester, 'Cẩm nang');
    await tester.pumpAndSettle();
    expect(find.text('Chưa lưu cẩm nang nào.'), findsOneWidget);
  });

  testWidgets('Bỏ lưu gỡ mục, hiện câu của server; Hoàn tác trả mục lại', (tester) async {
    usePhoneScreen(tester);
    final dao = FakeSavedDao();
    await tester.pumpWidget(profileTestApp(const SavedScreen(), savedDao: dao));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bỏ lưu').first);
    await tester.pumpAndSettle();
    expect(find.text('Ga Nippori'), findsNothing);
    expect(find.text('Địa điểm (1)'), findsOneWidget);
    expect(find.text('Đã bỏ lưu địa điểm.'), findsOneWidget);
    expect(dao.unsaved.single, (SavedKind.place, 1));

    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();
    expect(find.text('Ga Nippori'), findsOneWidget);
    expect(find.text('Đã lưu địa điểm.'), findsOneWidget);
    expect(dao.resaved.single, (SavedKind.place, 1));
  });

  testWidgets('Bỏ lưu bị server từ chối thì mục quay lại và hiện câu lỗi', (tester) async {
    final dao = FakeSavedDao()..failWrites = const ApiException('Không tìm thấy nội dung bạn yêu cầu.');
    await tester.pumpWidget(profileTestApp(const SavedScreen(), savedDao: dao));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bỏ lưu').first);
    await tester.pumpAndSettle();
    expect(find.text('Ga Nippori'), findsOneWidget);
    expect(find.text('Không tìm thấy nội dung bạn yêu cầu.'), findsOneWidget);
    expect(find.text('Hoàn tác'), findsNothing);
  });

  testWidgets('lỗi server hiện câu thông báo và Thử lại', (tester) async {
    final dao = FakeSavedDao()..failWith = const ApiException('Không kết nối được tới server.');
    await tester.pumpWidget(profileTestApp(const SavedScreen(), savedDao: dao));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);

    dao.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Ga Nippori'), findsOneWidget);
  });

  testWidgets('khách thấy lời mời đăng nhập; bấm Đăng nhập thì sang LoginScreen', (tester) async {
    await tester.pumpWidget(profileTestApp(const SavedScreen(), signedIn: false));
    await tester.pumpAndSettle();
    expect(find.text('Ga Nippori'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('bấm một mục mở màn chi tiết của loại đó', (tester) async {
    usePhoneScreen(tester);
    final recorder = PushRecorder();
    await tester.pumpWidget(profileTestApp(const SavedScreen(), observer: recorder));
    await tester.pumpAndSettle();

    Future<Widget> open(String text) async {
      await tester.tap(find.text(text));
      final screen = recorder.takeScreen();
      await tester.pumpAndSettle();
      return screen;
    }

    expect(await open('Ga Nippori'), isA<PlaceDetailScreen>().having((s) => s.placeId, 'placeId', 1));
    await _tapTab(tester, 'Bài viết (1)');
    await tester.pumpAndSettle();
    expect(
      await open('Năm điều mình ước biết trước tuần đầu ở Tokyo'),
      isA<BlogDetailScreen>().having((s) => s.blogId, 'blogId', 1),
    );
    await _tapTab(tester, 'Câu hỏi (1)');
    await tester.pumpAndSettle();
    expect(
      await open('Mua SIM data giá rẻ ở đâu gần Nippori ạ?'),
      isA<QuestionDetailScreen>().having((s) => s.questionId, 'questionId', 6),
    );
    await _tapTab(tester, 'Cẩm nang (1)');
    await tester.pumpAndSettle();
    expect(
      await open('Cách phân loại và bỏ rác tại Nhật Bản'),
      isA<GuideDetailScreen>().having((s) => s.guideId, 'guideId', 24),
    );
  });
}
