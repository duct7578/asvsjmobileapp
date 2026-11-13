// Widget test của thẻ ghi nhớ (FlashcardScreen): lật thẻ, trả lời, kết quả cuối lượt, khách và thành viên.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/phrase_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/flashcard_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_list_screen.dart';

import 'phrase_fakes.dart';

void main() {
  late FakePhraseDao dao;
  late FakePhraseSpeaker speaker;
  late PhraseController phrases;

  /// Mở FlashcardScreen từ một màn trống (để thử nút Xong quay lại) với 2 thẻ đầu: 袋はいりません。, 温めてください。
  Future<void> open(WidgetTester tester, {bool member = false}) async {
    useNarrowPhone(tester, height: 800);
    dao = FakePhraseDao(member: member);
    speaker = FakePhraseSpeaker();
    phrases = PhraseController(dao, speaker: speaker);
    await phrases.loadOverview();
    phrases.startFlash(dao.stored.take(2).toList());
    await tester.pumpWidget(
      phraseApp(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () =>
                    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const FlashcardScreen())),
                child: const Text('Mở thẻ'),
              ),
            ),
          ),
        ),
        phrases: phrases,
        signedIn: member,
      ),
    );
    await tester.tap(find.text('Mở thẻ'));
    await tester.pumpAndSettle();
  }

  Future<void> flipAndAnswer(WidgetTester tester, String answer) async {
    await tester.tap(find.text('Bấm để lật thẻ'));
    await tester.pumpAndSettle();
    await tester.tap(find.ancestor(of: find.text(answer), matching: find.bySubtype<ButtonStyleButton>()));
    await tester.pumpAndSettle();
  }

  testWidgets('mặt trước chỉ có chữ Nhật; lật thẻ hiện romaji, nghĩa và hai nút trả lời', (tester) async {
    await open(tester);

    expect(find.text('Thẻ ghi nhớ · 1/2'), findsOneWidget);
    expect(find.text('袋はいりません。'), findsOneWidget);
    expect(find.text('Tôi không cần túi.'), findsNothing);
    expect(find.text('Đã thuộc'), findsNothing);

    await tester.tap(find.text('Bấm để lật thẻ'));
    await tester.pumpAndSettle();
    expect(find.text('Fukuro wa irimasen.'), findsOneWidget);
    expect(find.text('Tôi không cần túi.'), findsOneWidget);
    expect(find.text('Chưa thuộc'), findsOneWidget);
    expect(find.text('Đã thuộc'), findsOneWidget);

    await tester.tap(find.text('Nghe'));
    await tester.pump();
    expect(speaker.spoken, ['袋はいりません。']);
  });

  testWidgets('khách: nói rõ không lưu, trả lời không gọi server, cuối lượt mời đăng nhập', (tester) async {
    await open(tester);

    expect(find.text('Bạn đang luyện với tư cách khách: kết quả lật thẻ không được lưu.'), findsOneWidget);
    await flipAndAnswer(tester, 'Đã thuộc');
    expect(find.text('Thẻ ghi nhớ · 2/2'), findsOneWidget);
    expect(find.text('温めてください。'), findsOneWidget);
    await flipAndAnswer(tester, 'Chưa thuộc');

    expect(dao.flashes, isEmpty);
    expect(find.text('Xong 2 thẻ'), findsOneWidget);
    expect(find.text('Đã thuộc: 1 · Chưa thuộc: 1'), findsOneWidget);
    expect(find.text('Đăng nhập để lưu kết quả lần sau.'), findsOneWidget);
    expect(find.text('Xem danh sách Chưa thuộc'), findsNothing);

    await tester.tap(find.text('Luyện lại 1 thẻ chưa thuộc'));
    await tester.pumpAndSettle();
    expect(find.text('Thẻ ghi nhớ · 1/1'), findsOneWidget);
    expect(find.text('温めてください。'), findsOneWidget);
  });

  testWidgets('khách bấm Đăng nhập trên thẻ thì ra màn Đăng nhập', (tester) async {
    await open(tester);

    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('thành viên: mỗi câu trả lời được lưu; cuối lượt mở được danh sách Chưa thuộc', (tester) async {
    await open(tester, member: true);

    expect(find.textContaining('tư cách khách'), findsNothing);
    expect(find.text('Đã thuộc'), findsOneWidget); // dấu cũ của thẻ 1
    await flipAndAnswer(tester, 'Chưa thuộc');
    await flipAndAnswer(tester, 'Đã thuộc');

    expect(dao.flashes, [(id: 1, learned: false), (id: 2, learned: true)]);
    expect(find.text('Đã lưu vào danh sách "Chưa thuộc" và "Đã thuộc" của bạn.'), findsOneWidget);

    await tester.tap(find.text('Xem danh sách Chưa thuộc'));
    await tester.pumpAndSettle();
    expect(find.byType(PhraseListScreen), findsOneWidget);
    expect(find.text('袋はいりません。'), findsOneWidget);
    expect(find.text('チャージしたいです。'), findsOneWidget);
  });

  testWidgets('thành viên: lưu lỗi thì ở lại thẻ và hiện câu báo lỗi', (tester) async {
    await open(tester, member: true);
    dao.failWith = const ApiException('Server gặp lỗi (500). Hãy thử lại sau.');

    await flipAndAnswer(tester, 'Đã thuộc');
    expect(find.text('Server gặp lỗi (500). Hãy thử lại sau.'), findsOneWidget);
    expect(find.text('Thẻ ghi nhớ · 1/2'), findsOneWidget);
  });

  testWidgets('Xong quay lại màn trước', (tester) async {
    await open(tester);
    await flipAndAnswer(tester, 'Đã thuộc');
    await flipAndAnswer(tester, 'Đã thuộc');

    expect(find.text('Luyện lại 0 thẻ chưa thuộc'), findsNothing);
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();
    expect(find.byType(FlashcardScreen), findsNothing);
    expect(find.text('Mở thẻ'), findsOneWidget);
    expect(speaker.stops, greaterThan(0));
  });
}
