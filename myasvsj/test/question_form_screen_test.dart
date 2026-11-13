// Widget test của QuestionFormScreen: đặt câu hỏi mới (kiểm tra nhập, gợi ý FAQ, mở câu vừa đăng) và sửa câu hỏi.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/faq_tile.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/media_image.dart';
import 'package:myasvsj/com.myasvsj.screen/question_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

import 'auth_fakes.dart';
import 'faq_fakes.dart';
import 'qa_test_app.dart';
import 'question_fakes.dart';

/// Màn trước mở form và ghi lại kết quả trả về.
class _Launcher extends StatefulWidget {
  const _Launcher(this.questionId);

  final int? questionId;

  @override
  State<_Launcher> createState() => _LauncherState();
}

class _LauncherState extends State<_Launcher> {
  String result = 'chưa';

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Text('Kết quả: $result'),
        TextButton(
          onPressed: () async {
            final saved = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => QuestionFormScreen(questionId: widget.questionId)),
            );
            setState(() => result = '$saved');
          },
          child: const Text('Mở form'),
        ),
      ],
    ),
  );
}

/// Ô nhập nằm dưới nhãn [label] (nhãn đứng trên ô như thiết kế, không nằm trong ô).
Finder _field(String label) =>
    find.descendant(of: find.widgetWithText(SenpaiLabeledField, label), matching: find.byType(TextField));

void main() {
  testWidgets('đặt câu hỏi: kiểm tra nhập, gợi ý FAQ, đăng xong mở câu vừa đăng', (tester) async {
    useTallScreen(tester);
    final dao = FakeQuestionDao();
    final faqs = FakeFaqDao();
    await tester.pumpWidget(qaTestApp(home: const QuestionFormScreen(), questions: dao, faqs: faqs, user: testUser));
    await tester.pumpAndSettle();

    expect(find.text('Đặt câu hỏi'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Visa và cư trú'), findsOneWidget);
    expect(find.text('Mô tả chi tiết (không bắt buộc)'), findsOneWidget);

    // Gửi khi chưa nhập gì: lỗi dưới từng ô, không gọi server
    await tester.tap(find.text('Đăng câu hỏi'));
    await tester.pumpAndSettle();
    expect(find.text('Hãy nhập câu hỏi.'), findsWidgets);
    expect(find.text('Hãy chọn ít nhất 1 chủ đề. Không có chủ đề phù hợp thì chọn “Khác”.'), findsOneWidget);
    expect(dao.saved, isEmpty);

    // Gõ câu hỏi đủ dài: hiện câu hỏi thường gặp giống điều định hỏi
    await tester.enterText(_field('Câu hỏi *'), 'Mua SIM điện thoại ở đâu?');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('Có thể đã có câu trả lời'), findsOneWidget);
    expect(find.byType(FaqTile), findsOneWidget);
    expect(faqs.relatedCalls.single, (q: 'Mua SIM điện thoại ở đâu?', limit: 3));

    // Bấm câu gợi ý: mở rộng tại chỗ
    await tester.tap(find.text('Làm thế nào để mua SIM điện thoại khi mới sang Nhật?'));
    await tester.pumpAndSettle();
    expect(find.text('Mở riêng câu này'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilterChip, 'Mua sắm'));
    await tester.enterText(_field('Mô tả chi tiết (không bắt buộc)'), 'Mình ở Arakawa.');
    await tester.tap(find.text('Đăng câu hỏi'));
    await tester.pumpAndSettle();

    final sent = dao.saved.single.question;
    expect(sent.title, 'Mua SIM điện thoại ở đâu?');
    expect(sent.content, 'Mình ở Arakawa.');
    expect(sent.topicIds, [11]);
    expect(find.byType(QuestionDetailScreen), findsOneWidget);
    expect(find.text('Câu hỏi của bạn đã được đăng.'), findsOneWidget);
  });

  testWidgets('sửa câu hỏi: điền sẵn, bỏ ảnh cũ, lưu xong trả về true', (tester) async {
    useTallScreen(tester);
    final dao = FakeQuestionDao();
    await tester.pumpWidget(qaTestApp(home: const _Launcher(2), questions: dao, user: testUser));
    await tester.tap(find.text('Mở form'));
    await tester.pumpAndSettle();

    expect(find.text('Sửa câu hỏi'), findsOneWidget);
    expect(find.text('Gia hạn visa du học cần giấy tờ gì?'), findsOneWidget);
    expect(find.text('Địa điểm liên quan (giữ nguyên): Ga Shinjuku'), findsOneWidget);
    expect(find.byType(MediaImage), findsOneWidget);
    // Sửa câu hỏi không gợi ý FAQ
    await tester.enterText(_field('Câu hỏi *'), 'Gia hạn visa du học cần những giấy tờ gì?');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Có thể đã có câu trả lời'), findsNothing);

    await tester.tap(find.byTooltip('Bỏ ảnh này'));
    await tester.pumpAndSettle();
    expect(find.byType(MediaImage), findsNothing);

    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    final sent = dao.saved.single;
    expect(sent.question.id, 2);
    expect(sent.question.title, 'Gia hạn visa du học cần những giấy tờ gì?');
    expect(sent.question.topicIds, [4, 14]);
    // Ảnh 19 đã bỏ, video 20 (đăng từ web) vẫn giữ
    expect(sent.keepMediaIds, [20]);
    expect(find.text('Kết quả: true'), findsOneWidget);
  });

  testWidgets('đang mở form hiện vòng chờ; không mở được thì hiện câu của server', (tester) async {
    final dao = FakeQuestionDao()
      ..gate = Completer<void>()
      ..failWith = const ApiException('Bạn cần đăng nhập để viết bài.', statusCode: 401);
    await tester.pumpWidget(qaTestApp(home: const QuestionFormScreen(), questions: dao));
    await tester.pump();
    expect(find.byType(LoadingView), findsOneWidget);

    dao.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Bạn cần đăng nhập để viết bài.'), findsOneWidget);
  });

  testWidgets('lỗi theo ô của server hiện dưới ô nhập, nút gửi mở lại', (tester) async {
    useTallScreen(tester);
    final dao = FakeQuestionDao();
    await tester.pumpWidget(qaTestApp(home: const QuestionFormScreen(), questions: dao, user: testUser));
    await tester.pumpAndSettle();

    dao.failOn['create'] = const ApiException(
      'Nội dung chứa từ ngữ không phù hợp.',
      statusCode: 400,
      fields: {'content': 'Nội dung chứa từ ngữ không phù hợp.'},
    );
    await tester.enterText(_field('Câu hỏi *'), 'Hỏi về vay tiền');
    await tester.tap(find.widgetWithText(FilterChip, 'Khác'));
    await tester.tap(find.text('Đăng câu hỏi'));
    await tester.pumpAndSettle();

    expect(find.text('Nội dung chứa từ ngữ không phù hợp.'), findsNWidgets(2));
    expect(find.text('Đăng câu hỏi'), findsOneWidget);
    expect(find.byType(QuestionDetailScreen), findsNothing);
  });

  testWidgets('rời form đang có thay đổi thì hỏi lại', (tester) async {
    useTallScreen(tester);
    await tester.pumpWidget(qaTestApp(home: const _Launcher(null), questions: FakeQuestionDao(), user: testUser));
    await tester.tap(find.text('Mở form'));
    await tester.pumpAndSettle();

    await tester.enterText(_field('Câu hỏi *'), 'Câu hỏi dở dang');
    await tester.pump();
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ thay đổi?'), findsOneWidget);

    await tester.tap(find.text('Ở lại'));
    await tester.pumpAndSettle();
    expect(find.byType(QuestionFormScreen), findsOneWidget);

    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ thay đổi'));
    await tester.pumpAndSettle();
    expect(find.byType(QuestionFormScreen), findsNothing);
    expect(find.text('Kết quả: null'), findsOneWidget);
  });
}
