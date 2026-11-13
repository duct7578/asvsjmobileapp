// Widget test của "Đưa cho nhân viên xem" (PhraseStaffScreen): chữ Nhật to, giữ màn hình sáng khi mở, tắt khi rời.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/phrase_controller.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_staff_screen.dart';

import 'phrase_fakes.dart';

void main() {
  testWidgets('hiện chữ Nhật thật to và nghĩa, giữ sáng khi mở, tắt giữ sáng khi đóng', (tester) async {
    useNarrowPhone(tester, height: 800);
    final speaker = FakePhraseSpeaker();
    final awake = <bool>[];
    final phrase = samplePhrases().first;
    await tester.pumpWidget(
      phraseApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PhraseStaffScreen(phrase: phrase, keepScreenOn: (on) async => awake.add(on)),
                ),
              ),
              child: const Text('Mở'),
            ),
          ),
        ),
        phrases: PhraseController(FakePhraseDao(), speaker: speaker),
      ),
    );
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();

    expect(awake, [true]);
    expect(find.text('Đưa màn hình này cho nhân viên'), findsOneWidget);
    expect(find.text('Tôi không cần túi.'), findsOneWidget);
    final japanese = tester.widget<Text>(find.text('袋はいりません。'));
    expect(japanese.style!.fontSize, greaterThanOrEqualTo(40));
    expect(japanese.locale, const Locale('ja'));

    await tester.tap(find.text('Nghe phát âm'));
    await tester.pump();
    expect(speaker.spoken, ['袋はいりません。']);

    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(find.byType(PhraseStaffScreen), findsNothing);
    expect(awake, [true, false]);
    expect(speaker.stops, 1);
  });

  testWidgets('máy chưa có giọng đọc tiếng Nhật thì báo nhẹ', (tester) async {
    useNarrowPhone(tester, height: 800);
    final speaker = FakePhraseSpeaker()..hasVoice = false;
    await tester.pumpWidget(
      phraseApp(
        PhraseStaffScreen(phrase: samplePhrases().first, keepScreenOn: (_) async {}),
        phrases: PhraseController(FakePhraseDao(), speaker: speaker),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nghe phát âm'));
    await tester.pumpAndSettle();
    expect(find.text('Máy chưa có giọng đọc tiếng Nhật.'), findsOneWidget);
  });
}
