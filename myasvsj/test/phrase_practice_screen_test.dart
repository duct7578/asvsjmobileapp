// Widget test của "Luyện tập" (PhrasePracticeScreen): chọn thẻ theo nhóm, loại, mức thuộc rồi bắt đầu.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/phrase_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/flashcard_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_practice_screen.dart';

import 'phrase_fakes.dart';

void main() {
  late FakePhraseDao dao;
  late PhraseController phrases;

  Future<void> open(WidgetTester tester, {bool member = false}) async {
    useNarrowPhone(tester, height: 1200);
    dao = FakePhraseDao(member: member);
    phrases = PhraseController(dao, speaker: FakePhraseSpeaker());
    await tester.pumpWidget(phraseApp(const PhrasePracticeScreen(), phrases: phrases, signedIn: member));
    await tester.pumpAndSettle();
  }

  testWidgets('khách: cả thư viện, đếm theo loại, không có lọc mức thuộc', (tester) async {
    await open(tester);

    expect(dao.finds.single, (topic: null, category: null, mine: null, q: null));
    expect(find.text('Cả hai (6)'), findsOneWidget);
    expect(find.text('Từ vựng (2)'), findsOneWidget);
    expect(find.text('Mẫu câu (4)'), findsOneWidget);
    expect(find.text('Thẻ'), findsNothing);
    expect(find.text('Bắt đầu (6 thẻ)'), findsOneWidget);

    await tester.tap(find.text('Từ vựng (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Bắt đầu (2 thẻ)'), findsOneWidget);
  });

  testWidgets('Luyện theo Chủ đề: chọn sẵn chủ đề đầu, đổi chủ đề thì số thẻ đổi theo', (tester) async {
    await open(tester);

    await tester.tap(find.text('Chủ đề'));
    await tester.pumpAndSettle();
    expect(find.text('Thanh toán (3)'), findsOneWidget);
    expect(find.text('Cả hai (3)'), findsOneWidget);

    await tester.tap(find.text('Thanh toán (3)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hỏi đường, hỏi đồ (1)').last);
    await tester.pumpAndSettle();
    expect(phrases.practiceGroup, 'ask');
    expect(find.text('Bắt đầu (1 thẻ)'), findsOneWidget);

    await tester.tap(find.text('Địa điểm'));
    await tester.pumpAndSettle();
    expect(find.text('Cửa hàng tiện lợi (3)'), findsOneWidget);
  });

  testWidgets('thành viên lọc theo mức thuộc rồi bắt đầu lượt thẻ', (tester) async {
    await open(tester, member: true);

    expect(find.text('Thẻ'), findsOneWidget);
    expect(find.text('Chưa thuộc (1)'), findsOneWidget);
    expect(find.text('Đã thuộc (1)'), findsOneWidget);
    expect(find.text('Chưa luyện (4)'), findsOneWidget);

    await tester.tap(find.text('Chưa thuộc (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bắt đầu (1 thẻ)'));
    await tester.pumpAndSettle();
    expect(find.byType(FlashcardScreen), findsOneWidget);
    expect(find.byType(PhrasePracticeScreen), findsNothing);
    expect(find.text('Thẻ ghi nhớ · 1/1'), findsOneWidget);
    expect(find.text('チャージしたいです。'), findsOneWidget);
  });

  testWidgets('tắt Xáo trộn thì thẻ theo thứ tự thư viện', (tester) async {
    await open(tester);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(phrases.practiceShuffle, isFalse);
    await tester.tap(find.text('Bắt đầu (6 thẻ)'));
    await tester.pumpAndSettle();
    expect(phrases.flashCards.map((p) => p.id), [1, 2, 6, 13, 14, 16]);
  });

  testWidgets('lỗi tải thư viện hiện câu thông báo và Thử lại', (tester) async {
    useNarrowPhone(tester, height: 1200);
    dao = FakePhraseDao()..failWith = const ApiException('Không kết nối được tới server.');
    await tester.pumpWidget(
      phraseApp(const PhrasePracticeScreen(), phrases: PhraseController(dao, speaker: FakePhraseSpeaker())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không kết nối được tới server.'), findsOneWidget);

    dao.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Bắt đầu (6 thẻ)'), findsOneWidget);
  });
}
