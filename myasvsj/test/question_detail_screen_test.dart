// Widget test của QuestionDetailScreen: câu hỏi, câu trả lời, các thao tác của khách, người xem và người hỏi.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_detail_screen.dart';

import 'auth_fakes.dart';
import 'qa_test_app.dart';
import 'question_fakes.dart';

/// Màn trước có nút mở chi tiết, để thử đóng màn chi tiết (sau khi xóa câu hỏi).
class _Launcher extends StatelessWidget {
  const _Launcher(this.questionId);

  final int questionId;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => QuestionDetailScreen(questionId: questionId)),
        ),
        child: const Text('Mở câu hỏi'),
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester, FakeQuestionDao dao, int id, {bool signedIn = true}) async {
  useTallScreen(tester);
  await tester.pumpWidget(
    qaTestApp(
      home: QuestionDetailScreen(questionId: id),
      questions: dao,
      user: signedIn ? testUser : null,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('hiện câu hỏi, người hỏi, chủ đề và cây câu trả lời', (tester) async {
    await _open(tester, FakeQuestionDao(), 1);

    expect(find.text('Mua SIM data giá rẻ ở đâu gần Nippori ạ?'), findsOneWidget);
    expect(find.text('Em mới sang được 3 ngày, cần SIM data rẻ để dùng bản đồ.'), findsOneWidget);
    expect(find.text('Trần Minh'), findsOneWidget);
    expect(find.text('Mua sắm'), findsOneWidget);
    expect(find.text('Câu trả lời (2)'), findsOneWidget);
    expect(find.text('Ra BicCamera mua SIM của IIJmio nhé.'), findsOneWidget);
    expect(find.text('Cảm ơn chị!'), findsOneWidget);
    expect(find.text('Mentor'), findsOneWidget);
    expect(find.text('Câu hỏi chờ trả lời'), findsOneWidget);
  });

  testWidgets('đang tải hiện vòng chờ; không tìm thấy hiện câu của server và Thử lại', (tester) async {
    final dao = FakeQuestionDao()..gate = Completer<void>();
    useTallScreen(tester);
    await tester.pumpWidget(qaTestApp(home: const QuestionDetailScreen(questionId: 99), questions: dao));
    await tester.pump();
    expect(find.byType(LoadingView), findsOneWidget);

    dao.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.textContaining('Không tìm thấy nội dung bạn yêu cầu'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('khách thấy lời mời đăng nhập; bấm Thích thì sang màn Đăng nhập', (tester) async {
    final dao = FakeQuestionDao();
    dao.details[1] = detailOf(
      1,
      'Mua SIM data giá rẻ ở đâu gần Nippori ạ?',
      signedIn: false,
      canInteract: false,
      likes: 3,
    );
    await _open(tester, dao, 1, signedIn: false);

    expect(find.text('Đăng nhập để trả lời và thích câu hỏi.'), findsOneWidget);
    expect(find.text('Chưa có câu trả lời. Bạn biết câu trả lời thì chia sẻ nhé.'), findsOneWidget);
    await tester.tap(find.text('Thích · 3'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(dao.calls, isNot(contains('like')));
  });

  testWidgets('khách bấm Nhắn tin với người hỏi thì sang màn Đăng nhập', (tester) async {
    await _open(tester, FakeQuestionDao(), 1, signedIn: false);

    await tester.tap(find.text('Nhắn tin').first);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('người xem thích và lưu câu hỏi, thấy câu thông báo của server', (tester) async {
    final dao = FakeQuestionDao();
    await _open(tester, dao, 1);

    await tester.tap(find.text('Thích · 3'));
    await tester.pumpAndSettle();
    expect(find.text('Thích · 4'), findsOneWidget);
    expect(dao.calls, contains('like'));

    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Đã lưu'), findsOneWidget);
    expect(find.text('Đã lưu câu hỏi.'), findsOneWidget);
  });

  testWidgets('gửi câu trả lời: trống thì báo lỗi, có nội dung thì hiện ngay', (tester) async {
    final dao = FakeQuestionDao();
    await _open(tester, dao, 1);

    await tester.tap(find.byTooltip('Gửi'));
    await tester.pumpAndSettle();
    expect(find.text('Hãy viết nội dung câu trả lời.'), findsOneWidget);
    expect(dao.calls, isNot(contains('answer')));

    await tester.enterText(find.widgetWithText(TextField, 'Viết câu trả lời của bạn'), 'Yodobashi cũng có SIM.');
    await tester.tap(find.byTooltip('Gửi'));
    await tester.pumpAndSettle();
    expect(find.text('Yodobashi cũng có SIM.'), findsOneWidget);
    expect(find.text('Đã đăng câu trả lời.'), findsOneWidget);
    expect(find.text('Câu trả lời (3)'), findsOneWidget);
  });

  testWidgets('phản hồi một câu trả lời trong ô trả lời lồng', (tester) async {
    await _open(tester, FakeQuestionDao(), 1);

    await tester.tap(find.widgetWithText(TextButton, 'Trả lời').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Viết câu trả lời cho bình luận này'), 'Cảm ơn nhiều ạ');
    await tester.tap(find.text('Gửi').last);
    await tester.pumpAndSettle();
    expect(find.text('Cảm ơn nhiều ạ'), findsOneWidget);
    expect(find.text('Đã gửi phản hồi.'), findsOneWidget);
    expect(find.text('Viết câu trả lời cho bình luận này'), findsNothing);
  });

  testWidgets('sửa và xóa câu trả lời của mình', (tester) async {
    final dao = FakeQuestionDao();
    await _open(tester, dao, 1);

    // Câu 12 "Cảm ơn chị!" là của người đang xem: có Sửa, Xóa, không có Báo cáo
    await tester.tap(find.widgetWithText(TextButton, 'Sửa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Sửa câu trả lời'), 'Cảm ơn chị nhiều!');
    await tester.tap(find.text('Lưu').last);
    await tester.pumpAndSettle();
    expect(find.text('Cảm ơn chị nhiều!'), findsOneWidget);
    expect(find.text('Đã lưu bình luận.'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Xóa'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn có chắc muốn xóa bình luận này?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();
    expect(find.text('Cảm ơn chị nhiều!'), findsNothing);
    expect(dao.calls, contains('deleteAnswer'));
  });

  testWidgets('báo cáo câu hỏi qua hộp thoại chọn lý do', (tester) async {
    final dao = FakeQuestionDao();
    await _open(tester, dao, 1);

    // Nút Báo cáo của câu hỏi đứng trước nút Báo cáo của các câu trả lời
    await tester.tap(find.text('Báo cáo').first);
    await tester.pumpAndSettle();
    expect(find.text('Báo cáo câu hỏi'), findsOneWidget);
    await tester.tap(find.text('Spam'));
    await tester.pump();
    await tester.tap(find.text('Gửi báo cáo'));
    await tester.pumpAndSettle();
    expect(dao.reports.single, (id: 1, reasonId: 4, note: ''));
    expect(find.text('Cảm ơn bạn. Báo cáo đã được gửi.'), findsOneWidget);
  });

  testWidgets('người hỏi chọn câu trả lời hay nhất sau khi xác nhận', (tester) async {
    final dao = FakeQuestionDao();
    await _open(tester, dao, 2);

    expect(find.byTooltip('Sửa câu hỏi'), findsOneWidget);
    expect(find.byTooltip('Xóa câu hỏi'), findsOneWidget);
    expect(find.text('0 lượt thích'), findsOneWidget);

    await tester.tap(find.text('Chọn là câu trả lời hay nhất'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn câu trả lời hay nhất?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Chọn'));
    await tester.pumpAndSettle();

    expect(dao.calls, contains('chooseBest'));
    expect(find.text('Câu trả lời hay nhất'), findsOneWidget);
    expect(find.text('Đã giải quyết'), findsOneWidget);
    expect(find.text('Chọn là câu trả lời hay nhất'), findsNothing);
    expect(find.text('Đã chọn câu trả lời hay nhất. Người trả lời được +5 điểm.'), findsOneWidget);
  });

  testWidgets('người hỏi xóa câu hỏi: hỏi xác nhận, xóa xong quay về màn trước', (tester) async {
    final dao = FakeQuestionDao();
    useTallScreen(tester);
    await tester.pumpWidget(qaTestApp(home: const _Launcher(2), questions: dao, user: testUser));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mở câu hỏi'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Xóa câu hỏi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Các câu trả lời cũng bị xóa'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();

    expect(dao.calls, contains('delete'));
    expect(find.byType(QuestionDetailScreen), findsNothing);
    expect(find.text('Đã xóa câu hỏi.'), findsOneWidget);
  });

  testWidgets('câu hỏi đang quét ảnh: chỉ người hỏi thấy, chưa nhận câu trả lời', (tester) async {
    final dao = FakeQuestionDao();
    dao.details[2] = detailOf(2, 'Câu đang quét', author: authorAn, mine: true, status: 'PROCESSING');
    await _open(tester, dao, 2);

    expect(find.text('Ảnh của câu hỏi đang được quét. Trong lúc này chỉ bạn thấy câu hỏi.'), findsOneWidget);
    expect(find.text('Câu hỏi chưa được đăng nên chưa nhận câu trả lời.'), findsOneWidget);
    expect(find.byTooltip('Sửa câu hỏi'), findsOneWidget);
  });

  testWidgets('phiên trên server đã hết: mời đăng nhập lại thay vì ô trả lời', (tester) async {
    final dao = FakeQuestionDao();
    dao.details[1] = detailOf(1, 'Mua SIM data giá rẻ ở đâu gần Nippori ạ?', signedIn: false, canInteract: false);
    await _open(tester, dao, 1);

    expect(find.text('Phiên đăng nhập đã hết. Đăng nhập lại để trả lời.'), findsOneWidget);
    expect(find.text('Viết câu trả lời của bạn'), findsNothing);
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('màn hẹp 360 dp không tràn chữ', (tester) async {
    tester.view.physicalSize = const Size(360 * 3, 1600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      qaTestApp(home: const QuestionDetailScreen(questionId: 1), questions: FakeQuestionDao(), user: testUser),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
