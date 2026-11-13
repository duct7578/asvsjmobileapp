// Widget test của một bộ Nhật ngữ (PhraseListScreen) và thẻ mẫu câu (PhraseCard) với DAO và giọng đọc giả.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/phrase_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/phrase.dart';
import 'package:myasvsj/com.myasvsj.screen/flashcard_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_card.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_staff_screen.dart';

import 'phrase_fakes.dart';

void main() {
  late FakePhraseDao dao;
  late FakePhraseSpeaker speaker;

  Future<void> open(WidgetTester tester, Widget screen, {bool member = false}) async {
    useNarrowPhone(tester);
    dao = FakePhraseDao(member: member);
    speaker = FakePhraseSpeaker();
    await tester.pumpWidget(
      phraseApp(
        screen,
        phrases: PhraseController(dao, speaker: speaker),
        signedIn: member,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('chủ đề mở Mẫu câu trước, thẻ có chữ Nhật, romaji, nghĩa; đổi sang Từ vựng', (tester) async {
    await open(tester, const PhraseListScreen(topicId: 'pay'));

    expect(find.widgetWithText(AppBar, 'Thanh toán'), findsOneWidget);
    expect(dao.finds.single.topic, 'pay');
    expect(find.byType(PhraseCard), findsNWidgets(2));
    expect(find.text('袋はいりません。'), findsOneWidget);
    expect(find.text('Fukuro wa irimasen.'), findsOneWidget);
    expect(find.text('Tôi không cần túi.'), findsOneWidget);
    expect(find.text('Đưa cho nhân viên xem'), findsNWidgets(2));
    expect(find.text('2 mục'), findsOneWidget);
    expect(find.text('Luyện thẻ ghi nhớ (2 thẻ)'), findsOneWidget);
    // Khách: không có bộ lọc mức thuộc, không có Bỏ đánh dấu
    expect(find.text('Chưa luyện (0)'), findsNothing);
    expect(find.byTooltip('Bỏ đánh dấu'), findsNothing);

    await tester.tap(find.text('Từ vựng (1)'));
    await tester.pumpAndSettle();
    expect(find.text('レジ'), findsOneWidget);
    expect(find.text('袋はいりません。'), findsNothing);
    // "Đưa cho nhân viên xem" chỉ có ở mẫu câu
    expect(find.text('Đưa cho nhân viên xem'), findsNothing);
  });

  testWidgets('địa điểm mở đúng loại được yêu cầu và ẩn nhãn địa điểm trên thẻ', (tester) async {
    await open(tester, const PhraseListScreen(categoryId: 'station', kind: Phrase.vocabKind));

    expect(find.widgetWithText(AppBar, 'Ga tàu'), findsOneWidget);
    expect(find.text('乗り換え'), findsOneWidget);
    expect(find.text('この電車は上野に止まりますか。'), findsNothing);
    expect(find.text('Ga tàu'), findsOneWidget); // chỉ tiêu đề, thẻ không lặp lại tên địa điểm
  });

  testWidgets('thành viên thấy tiến độ, dấu thuộc và lọc Chưa thuộc / Đã thuộc / Chưa luyện', (tester) async {
    await open(tester, const PhraseListScreen(topicId: 'pay'), member: true);

    expect(find.text('1/2 đã thuộc'), findsOneWidget);
    expect(find.text('Đã thuộc'), findsOneWidget); // nhãn trên thẻ 袋はいりません。
    expect(find.text('Chưa thuộc'), findsOneWidget); // nhãn trên thẻ チャージしたいです。
    expect(find.text('Tất cả (2)'), findsOneWidget);
    expect(find.byTooltip('Bỏ đánh dấu'), findsNWidgets(2));

    await tester.tap(find.text('Chưa thuộc (1)'));
    await tester.pumpAndSettle();
    expect(find.byType(PhraseCard), findsOneWidget);
    expect(find.text('チャージしたいです。'), findsOneWidget);
    expect(find.text('Luyện lại thẻ chưa thuộc (1 thẻ)'), findsOneWidget);

    await tester.tap(find.text('Chưa luyện (0)'));
    await tester.pumpAndSettle();
    expect(find.text('Không có mẫu câu nào chưa luyện ở đây.'), findsOneWidget);
  });

  testWidgets('thành viên Bỏ đánh dấu: dấu mất ngay và hiện câu của server', (tester) async {
    await open(tester, const PhraseListScreen(topicId: 'pay'), member: true);

    await tester.tap(find.byTooltip('Bỏ đánh dấu').first);
    await tester.pumpAndSettle();
    expect(dao.cleared, [1]);
    expect(find.text('Đã bỏ đánh dấu.'), findsOneWidget);
    expect(find.text('0/2 đã thuộc'), findsOneWidget);
    expect(find.byTooltip('Bỏ đánh dấu'), findsOneWidget);
  });

  testWidgets('khách bấm Báo lỗi thì được đưa sang màn Đăng nhập', (tester) async {
    await open(tester, const PhraseListScreen(topicId: 'pay'));

    await tester.tap(find.byTooltip('Báo lỗi').first);
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(dao.reports, isEmpty);
  });

  testWidgets('thành viên báo lỗi: chọn lý do của server, gửi, hiện câu của server', (tester) async {
    await open(tester, const PhraseListScreen(topicId: 'pay'), member: true);

    await tester.tap(find.byTooltip('Báo lỗi').first);
    await tester.pumpAndSettle();
    expect(find.text('Báo lỗi mẫu câu'), findsOneWidget);
    expect(find.text('Sai tiếng Nhật'), findsOneWidget);
    await tester.tap(find.text('Sai nghĩa'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Nghĩa chưa đúng');
    await tester.tap(find.text('Gửi báo cáo'));
    await tester.pumpAndSettle();

    expect(dao.reports.single, (id: 1, reasonId: 6, note: 'Nghĩa chưa đúng'));
    expect(find.text('Đã gửi báo cáo cho Biên tập viên nội dung tiếng Nhật.'), findsOneWidget);
  });

  testWidgets('Nghe đọc chữ Nhật; máy chưa có giọng ja-JP thì báo nhẹ', (tester) async {
    await open(tester, const PhraseListScreen(topicId: 'pay'));

    await tester.tap(find.text('Nghe').first);
    await tester.pumpAndSettle();
    expect(speaker.spoken, ['袋はいりません。']);

    speaker.hasVoice = false;
    await tester.tap(find.text('Nghe').last);
    await tester.pumpAndSettle();
    expect(find.text(PhraseController.noVoiceMessage), findsOneWidget);
  });

  testWidgets('Đưa cho nhân viên xem mở màn chữ to', (tester) async {
    await open(tester, const PhraseListScreen(topicId: 'pay'));

    await tester.tap(find.text('Đưa cho nhân viên xem').first);
    await tester.pumpAndSettle();
    expect(find.byType(PhraseStaffScreen), findsOneWidget);
    expect(find.text('Đưa màn hình này cho nhân viên'), findsOneWidget);
  });

  testWidgets('bấm nhãn chủ đề trên thẻ mở bộ của chủ đề đó chồng lên', (tester) async {
    await open(tester, const PhraseListScreen(topicId: 'pay'));

    await tester.tap(find.text('Đi tàu'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Đi tàu'), findsOneWidget);
    expect(find.text('この電車は上野に止まりますか。'), findsOneWidget);

    // Quay lại: bộ "Thanh toán" vẫn là của nó
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Thanh toán'), findsOneWidget);
    expect(find.text('この電車は上野に止まりますか。'), findsNothing);
  });

  testWidgets('Luyện thẻ ghi nhớ mở thẻ với các mục đang hiện', (tester) async {
    await open(tester, const PhraseListScreen(topicId: 'pay'));

    await tester.tap(find.text('Luyện thẻ ghi nhớ (2 thẻ)'));
    await tester.pumpAndSettle();
    expect(find.byType(FlashcardScreen), findsOneWidget);
    expect(find.text('Thẻ ghi nhớ · 1/2'), findsOneWidget);
  });

  testWidgets('danh sách Chưa thuộc của thành viên; rỗng thì có câu hướng dẫn', (tester) async {
    await open(tester, const PhraseListScreen(mine: 'learning'), member: true);

    expect(dao.finds.single.mine, 'learning');
    expect(find.widgetWithText(AppBar, 'Chưa thuộc'), findsOneWidget);
    expect(find.text('チャージしたいです。'), findsOneWidget);
    expect(find.text('1 mục'), findsOneWidget);

    await tester.tap(find.byTooltip('Bỏ đánh dấu'));
    await tester.pumpAndSettle();
    expect(
      find.text('Không còn thẻ nào chưa thuộc. Lật thẻ ở một chủ đề và chọn "Chưa thuộc" để lưu lại đây.'),
      findsOneWidget,
    );
  });

  testWidgets('lỗi server hiện câu thông báo và Thử lại tải lại', (tester) async {
    useNarrowPhone(tester);
    dao = FakePhraseDao()..failWith = const ApiException('Không kết nối được tới server.');
    await tester.pumpWidget(
      phraseApp(
        const PhraseListScreen(topicId: 'pay'),
        phrases: PhraseController(dao, speaker: FakePhraseSpeaker()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không kết nối được tới server.'), findsOneWidget);

    dao.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byType(PhraseCard), findsNWidgets(2));
  });

  testWidgets('chủ đề không có mục hiện câu rỗng', (tester) async {
    await open(tester, const PhraseListScreen(topicId: 'khong-co'));

    expect(find.text('Chủ đề này chưa có mẫu câu nào.'), findsOneWidget);
    expect(find.textContaining('Luyện thẻ ghi nhớ'), findsNothing);
  });
}
