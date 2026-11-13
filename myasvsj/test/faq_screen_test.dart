// Widget test của FaqScreen (và FaqView dùng chung với tab "Câu hỏi thường gặp" của Hỏi-Đáp).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/faq_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/faq_tile.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';

import 'faq_fakes.dart';
import 'qa_test_app.dart';
import 'question_fakes.dart';

Future<void> _open(WidgetTester tester, FakeFaqDao faqs, {int? faqId}) async {
  useTallScreen(tester);
  await tester.pumpWidget(
    qaTestApp(
      home: FaqScreen(faqId: faqId),
      questions: FakeQuestionDao(),
      faqs: faqs,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('hiện chủ đề kèm số câu và danh sách; bấm một câu thì mở câu trả lời tại chỗ', (tester) async {
    await _open(tester, FakeFaqDao());

    expect(find.text('Câu hỏi thường gặp'), findsOneWidget);
    expect(find.text('Tất cả (3)'), findsOneWidget);
    expect(find.text('Sinh hoạt và đời sống (2)'), findsOneWidget);
    expect(find.text('Khác (1)'), findsOneWidget);
    // Chủ đề chưa có câu nào không hiện
    expect(find.textContaining('Ngôn ngữ và giao tiếp'), findsNothing);
    expect(find.text('3 câu hỏi thường gặp'), findsOneWidget);
    expect(find.byType(FaqTile), findsNWidgets(3));

    await tester.tap(find.text('Phân loại và đổ rác tại Nhật như thế nào?'));
    await tester.pumpAndSettle();
    expect(find.text('Rác thường được chia thành rác cháy được và rác không cháy được.'), findsOneWidget);
    expect(find.text('Xem thêm'), findsOneWidget);
    expect(find.text('Xem chi tiết về phân loại rác tại Nhật'), findsOneWidget);
    expect(find.text('Cập nhật 7/11/2026'), findsOneWidget);
  });

  testWidgets('câu trả lời có định dạng: gạch đầu dòng, chữ đậm, liên kết', (tester) async {
    await _open(tester, FakeFaqDao());

    await tester.tap(find.text('Làm thế nào để mua SIM điện thoại khi mới sang Nhật?'));
    await tester.pumpAndSettle();
    expect(find.text('•'), findsNWidgets(2));
    expect(find.textContaining('thẻ cư trú', findRichText: true), findsOneWidget);
    expect(find.text('IIJmio'), findsOneWidget);
    expect(find.textContaining('**'), findsNothing);
  });

  testWidgets('lọc theo chủ đề', (tester) async {
    final faqs = FakeFaqDao();
    await _open(tester, faqs);

    await tester.tap(find.text('Khác (1)'));
    await tester.pumpAndSettle();
    expect(faqs.lastQuery['topic'], 'OTHER');
    expect(find.byType(FaqTile), findsOneWidget);
    expect(find.text('1 câu hỏi thường gặp phù hợp'), findsOneWidget);
  });

  testWidgets('tìm không có câu khớp nguyên văn: hiện các câu có thể liên quan', (tester) async {
    final faqs = FakeFaqDao();
    await _open(tester, faqs);

    await tester.enterText(find.byType(TextField), 'điện thoại di động');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(faqs.lastQuery['q'], 'điện thoại di động');
    expect(find.text('Không có câu nào chứa đúng “điện thoại di động”. Những câu có thể liên quan:'), findsOneWidget);
    expect(find.byType(FaqTile), findsOneWidget);
  });

  testWidgets('mở sẵn một câu theo faqId, rồi xem tất cả', (tester) async {
    final faqs = FakeFaqDao();
    await _open(tester, faqs, faqId: 5);

    expect(find.text('Chủ đề: Sinh hoạt và đời sống'), findsOneWidget);
    expect(find.text('Rác thường được chia thành rác cháy được và rác không cháy được.'), findsOneWidget);
    expect(find.text('Mở riêng câu này'), findsNothing);
    expect(faqs.calls, contains('findById'));

    await tester.tap(find.text('Xem tất cả câu hỏi thường gặp'));
    await tester.pumpAndSettle();
    expect(find.byType(FaqTile), findsNWidgets(3));
  });

  testWidgets('faqId không còn: báo câu dễ hiểu', (tester) async {
    await _open(tester, FakeFaqDao(), faqId: 99);

    expect(find.text('Câu hỏi thường gặp này không còn hoặc đã được ẩn.'), findsOneWidget);
    expect(find.text('Xem tất cả câu hỏi thường gặp'), findsOneWidget);
  });

  testWidgets('đang tải hiện vòng chờ; lỗi hiện câu của server và Thử lại', (tester) async {
    final faqs = FakeFaqDao()
      ..gate = Completer<void>()
      ..failWith = const ApiException('Không kết nối được tới server.');
    useTallScreen(tester);
    await tester.pumpWidget(qaTestApp(home: const FaqScreen(), questions: FakeQuestionDao(), faqs: faqs));
    await tester.pump();
    expect(find.byType(LoadingView), findsOneWidget);

    faqs.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Không kết nối được tới server.'), findsOneWidget);

    faqs.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byType(FaqTile), findsNWidgets(3));
  });

  testWidgets('chưa có câu nào: khách bấm Đặt câu hỏi thì sang Đăng nhập', (tester) async {
    final faqs = FakeFaqDao()..entries.clear();
    await _open(tester, faqs);

    expect(find.text('Chưa có câu hỏi thường gặp nào.'), findsOneWidget);
    await tester.tap(find.text('Đặt câu hỏi'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('tải thêm khi cuộn tới cuối danh sách', (tester) async {
    final faqs = FakeFaqDao(perPage: 2);
    await _open(tester, faqs);
    expect(find.byType(FaqTile), findsNWidgets(2));

    await tester.tap(find.text('Tải thêm'));
    await tester.pumpAndSettle();
    expect(find.byType(FaqTile), findsNWidgets(3));
    expect(faqs.lastQuery['page'], 1);
  });
}
