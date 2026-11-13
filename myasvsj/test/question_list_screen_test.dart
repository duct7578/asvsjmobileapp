// Widget test của QuestionListScreen (tab Hỏi-Đáp): Controller dùng DAO giả, cấp bằng Provider.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/faq_tile.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_card.dart';
import 'package:myasvsj/com.myasvsj.screen/question_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_list_screen.dart';

import 'auth_fakes.dart';
import 'faq_fakes.dart';
import 'qa_test_app.dart';
import 'question_fakes.dart';

void main() {
  testWidgets('hiện các câu hỏi, số câu hỏi và thống kê', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(qaTestApp(home: const QuestionListScreen(), questions: FakeQuestionDao()));
    await tester.pumpAndSettle();

    expect(find.text('Hỏi-Đáp'), findsOneWidget);
    expect(find.byType(QuestionCard), findsNWidgets(3));
    expect(find.text('Mua SIM data giá rẻ ở đâu gần Nippori ạ?'), findsOneWidget);
    expect(find.text('3 câu hỏi'), findsOneWidget);
    expect(find.text('chưa ai trả lời'), findsOneWidget);
    expect(find.text('Chưa ai trả lời'), findsWidgets);
    // Nút của thanh tiêu đề dùng chung
    expect(find.byTooltip('Tìm kiếm'), findsOneWidget);
  });

  testWidgets('đang tải hiện vòng chờ, tải xong hiện danh sách', (tester) async {
    useTallScreen(tester);
    final dao = FakeQuestionDao()..gate = Completer<void>();
    await tester.pumpWidget(qaTestApp(home: const QuestionListScreen(), questions: dao));
    await tester.pump();
    expect(find.byType(LoadingView), findsOneWidget);

    dao.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LoadingView), findsNothing);
    expect(find.byType(QuestionCard), findsNWidgets(3));
  });

  testWidgets('lỗi server hiện câu thông báo và nút Thử lại', (tester) async {
    useTallScreen(tester);
    final dao = FakeQuestionDao()..failWith = const ApiException('Không kết nối được tới server.');
    await tester.pumpWidget(qaTestApp(home: const QuestionListScreen(), questions: dao));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Không kết nối được tới server.'), findsOneWidget);

    dao.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byType(QuestionCard), findsNWidgets(3));
  });

  testWidgets('lọc "Đã giải quyết" gửi trạng thái cho server; không có câu nào thì có nút Xóa bộ lọc', (tester) async {
    useTallScreen(tester);
    final dao = FakeQuestionDao();
    await tester.pumpWidget(qaTestApp(home: const QuestionListScreen(), questions: dao));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Đã giải quyết'));
    await tester.pumpAndSettle();
    expect(dao.lastQuery['status'], 'SOLVED');
    expect(find.text('Không có câu hỏi nào khớp với lựa chọn của bạn.'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Xóa bộ lọc'));
    await tester.pumpAndSettle();
    expect(dao.lastQuery['status'], 'ALL');
    expect(find.byType(QuestionCard), findsNWidgets(3));
  });

  testWidgets('tìm kiếm hiện câu hỏi thường gặp liên quan và chuyển sang tab FAQ', (tester) async {
    final dao = FakeQuestionDao();
    final faqs = FakeFaqDao();
    await tester.pumpWidget(qaTestApp(home: const QuestionListScreen(), questions: dao, faqs: faqs));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'SIM');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(dao.lastQuery['q'], 'SIM');
    expect(find.byType(QuestionCard), findsOneWidget);
    expect(find.text('Câu hỏi thường gặp liên quan'), findsOneWidget);
    expect(find.byType(FaqTile), findsOneWidget);
    expect(faqs.relatedCalls.single, (q: 'SIM', limit: 3));

    await tester.tap(find.text('Tìm “SIM” trong Câu hỏi thường gặp'));
    await tester.pumpAndSettle();
    expect(faqs.lastQuery['q'], 'SIM');
    expect(find.text('1 câu hỏi thường gặp phù hợp'), findsOneWidget);
  });

  testWidgets('initialTab: 1 mở sẵn tab Câu hỏi thường gặp', (tester) async {
    await tester.pumpWidget(
      qaTestApp(home: const QuestionListScreen(initialTab: 1), questions: FakeQuestionDao(), faqs: FakeFaqDao()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FaqTile), findsNWidgets(3));
    expect(find.text('Tất cả (3)'), findsOneWidget);
  });

  testWidgets('initialQuery mở sẵn kết quả tìm (từ màn Tìm kiếm)', (tester) async {
    final dao = FakeQuestionDao();
    await tester.pumpWidget(
      qaTestApp(
        home: const QuestionListScreen(initialQuery: 'SIM'),
        questions: dao,
      ),
    );
    await tester.pumpAndSettle();
    expect(dao.lastQuery['q'], 'SIM');
    expect(find.byType(QuestionCard), findsOneWidget);
    expect(find.widgetWithText(TextField, 'SIM'), findsOneWidget);
  });

  testWidgets('initialTab: 1 kèm initialQuery tìm sẵn trong Câu hỏi thường gặp', (tester) async {
    final faqs = FakeFaqDao();
    await tester.pumpWidget(
      qaTestApp(
        home: const QuestionListScreen(initialTab: 1, initialQuery: 'hộ chiếu'),
        questions: FakeQuestionDao(),
        faqs: faqs,
      ),
    );
    await tester.pumpAndSettle();
    expect(faqs.lastQuery['q'], 'hộ chiếu');
    expect(find.byType(FaqTile), findsOneWidget);
    expect(find.widgetWithText(TextField, 'hộ chiếu'), findsOneWidget);
  });

  testWidgets('khách bấm Đặt câu hỏi thì được đưa sang màn Đăng nhập', (tester) async {
    await tester.pumpWidget(qaTestApp(home: const QuestionListScreen(), questions: FakeQuestionDao()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('người đã đăng nhập bấm Đặt câu hỏi thì mở form', (tester) async {
    await tester.pumpWidget(qaTestApp(home: const QuestionListScreen(), questions: FakeQuestionDao(), user: testUser));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(QuestionFormScreen), findsOneWidget);
    expect(find.text('Câu hỏi *'), findsOneWidget);
  });

  testWidgets('bấm một câu hỏi mở màn chi tiết', (tester) async {
    await tester.pumpWidget(qaTestApp(home: const QuestionListScreen(), questions: FakeQuestionDao()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mua SIM data giá rẻ ở đâu gần Nippori ạ?'));
    await tester.pumpAndSettle();
    expect(find.byType(QuestionDetailScreen), findsOneWidget);
    expect(find.text('Ra BicCamera mua SIM của IIJmio nhé.'), findsOneWidget);
  });

  testWidgets('màn hẹp 360 dp không tràn chữ', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 740 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(qaTestApp(home: const QuestionListScreen(), questions: FakeQuestionDao()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(QuestionCard), findsWidgets);
  });
}
