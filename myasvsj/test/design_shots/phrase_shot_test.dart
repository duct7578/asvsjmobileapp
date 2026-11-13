// Ảnh màn 25–29 "Nhật ngữ" để so với design/figma-export/ref/25-*.png … 29-*.png.
// Chạy: flutter test test/design_shots/phrase_shot_test.dart --dart-define=SHOTS=true
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/phrase_controller.dart';
import 'package:myasvsj/com.myasvsj.model/phrase.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_group.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_marks.dart';
import 'package:myasvsj/com.myasvsj.screen/flashcard_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_practice_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_staff_screen.dart';

import '../auth_fakes.dart';
import '../phrase_fakes.dart';
import 'shot_helper.dart';

// Dữ liệu thử giống thiết kế: 4 chủ đề Thanh toán, Hỏi đường, Khám bệnh, Mua sắm.
const _konbini = PhraseGroup(id: 'konbini', name: 'Cửa hàng tiện lợi', icon: 'local_convenience_store');
const _super = PhraseGroup(id: 'super', name: 'Siêu thị', icon: 'shopping_cart');
const _restaurant = PhraseGroup(id: 'restaurant', name: 'Nhà hàng', icon: 'restaurant');
const _station = PhraseGroup(id: 'station', name: 'Ga tàu', icon: 'train');
const _clinic = PhraseGroup(id: 'clinic', name: 'Phòng khám', icon: 'local_hospital');
const _pay = PhraseGroup(id: 'pay', name: 'Thanh toán', icon: 'payments');
const _ask = PhraseGroup(id: 'ask', name: 'Hỏi đường', icon: 'directions');
const _doctor = PhraseGroup(id: 'doctor', name: 'Khám bệnh', icon: 'local_hospital');
const _shop = PhraseGroup(id: 'shop', name: 'Mua sắm', icon: 'storefront');

Phrase _p(int id, String jp, String romaji, String vi, PhraseGroup cat, List<PhraseGroup> topics,
        {String kind = Phrase.phraseKind, bool learned = false, bool learning = false}) =>
    Phrase(
      id: id,
      kind: kind,
      japanese: jp,
      romaji: romaji,
      meaningVi: vi,
      category: cat,
      topics: topics,
      learned: learned,
      learning: learning,
    );

final _phrases = [
  _p(1, 'カードで払えますか？', 'Kādo de haraemasu ka?', 'Tôi trả bằng thẻ được không?', _konbini, [_pay], learned: true),
  _p(2, '袋はいりません。', 'Fukuro wa irimasen.', 'Tôi không cần túi ạ.', _super, [_pay], learning: true),
  _p(3, 'お会計をお願いします。', 'Okaikei o onegai shimasu.', 'Cho tôi thanh toán.', _restaurant, [_pay], learning: true),
  _p(4, '領収書をください。', 'Ryōshūsho o kudasai.', 'Cho tôi xin hóa đơn.', _restaurant, [_pay]),
  _p(5, '駅はどこですか？', 'Eki wa doko desu ka?', 'Nhà ga ở đâu?', _station, [_ask], learned: true),
  _p(6, 'トイレはどこですか？', 'Toire wa doko desu ka?', 'Nhà vệ sinh ở đâu?', _station, [_ask]),
  _p(7, '熱があります。', 'Netsu ga arimasu.', 'Tôi bị sốt.', _clinic, [_doctor]),
  _p(8, '保険証があります。', 'Hokenshō ga arimasu.', 'Tôi có thẻ bảo hiểm.', _clinic, [_doctor]),
  _p(9, 'これはいくらですか？', 'Kore wa ikura desu ka?', 'Cái này bao nhiêu tiền?', _super, [_shop], learned: true),
  _p(10, '試着してもいいですか？', 'Shichaku shite mo ii desu ka?', 'Tôi thử đồ được không?', _super, [_shop]),
  _p(11, 'レジ', 'reji', 'Quầy thu ngân.', _konbini, [_pay], kind: Phrase.vocabKind, learned: true),
  _p(12, '現金', 'genkin', 'Tiền mặt.', _konbini, [_pay], kind: Phrase.vocabKind),
  _p(13, '地図', 'chizu', 'Bản đồ.', _station, [_ask], kind: Phrase.vocabKind),
  _p(14, '薬', 'kusuri', 'Thuốc.', _clinic, [_doctor], kind: Phrase.vocabKind),
];

void main() {
  late PhraseController phrases;

  Widget app({bool member = true}) {
    final dao = FakePhraseDao(member: member)
      ..stored = [for (final p in _phrases) member ? p : p.withMarks(const PhraseMarks())];
    phrases = PhraseController(dao, speaker: FakePhraseSpeaker());
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(FakeAuthDao(current: member ? testUser : null))
            ..currentUser = member ? testUser : null,
        ),
        ChangeNotifierProvider.value(value: phrases),
      ],
      child: shotApp(const Scaffold()),
    );
  }

  /// Dựng app rồi mở [screen] chồng lên một màn trống (như khi mở từ tab Thêm), để AppBar có nút quay lại / X.
  /// [before] chạy trước khi mở (ví dụ bắt đầu lượt thẻ).
  Future<void> open(
    WidgetTester tester,
    Widget screen, {
    bool member = true,
    double height = 844,
    bool dialog = false,
    Future<void> Function()? before,
  }) async {
    await pumpShot(tester, app(member: member), height: height);
    await before?.call();
    tester.state<NavigatorState>(find.byType(Navigator)).push(
          MaterialPageRoute<void>(fullscreenDialog: dialog, builder: (_) => screen),
        );
    await settleShot(tester);
  }

  testWidgets('25 Nhật ngữ — thành viên', skip: shotSkip != null, (tester) async {
    await open(tester, const PhraseScreen(), height: 1180);
    await saveShot(tester, '25-phrase-member');
  });

  testWidgets('25 Nhật ngữ — khách', skip: shotSkip != null, (tester) async {
    await open(tester, const PhraseScreen(), member: false);
    await saveShot(tester, '25-phrase-guest');
  });

  testWidgets('25 Nhật ngữ — tìm kiếm', skip: shotSkip != null, (tester) async {
    await open(tester, const PhraseScreen(initialQuery: 'thẻ'));
    await saveShot(tester, '25-phrase-search');
  });

  testWidgets('26 Danh sách mẫu câu — thành viên', skip: shotSkip != null, (tester) async {
    await open(tester, const PhraseListScreen(topicId: 'pay'), height: 1300);
    await saveShot(tester, '26-phrase-list-member');
  });

  testWidgets('26 Danh sách mẫu câu — khách', skip: shotSkip != null, (tester) async {
    await open(tester, const PhraseListScreen(topicId: 'pay'), member: false);
    await saveShot(tester, '26-phrase-list-guest');
  });

  testWidgets('26 Danh sách Chưa thuộc — thành viên', skip: shotSkip != null, (tester) async {
    await open(tester, const PhraseListScreen(mine: 'learning'));
    await saveShot(tester, '26-phrase-list-learning');
  });

  testWidgets('27 Luyện tập — thành viên', skip: shotSkip != null, (tester) async {
    await open(tester, const PhrasePracticeScreen());
    phrases.choosePractice(by: 'topic', status: 'learning');
    await settleShot(tester);
    await saveShot(tester, '27-phrase-practice');
  });

  testWidgets('28 Thẻ ghi nhớ — đã lật', skip: shotSkip != null, (tester) async {
    await open(tester, const FlashcardScreen(), before: () async {
      await phrases.loadOverview();
      phrases.startFlash([
        _phrases[8],
        _phrases[4],
        _phrases[0].withMarks(const PhraseMarks(learning: true)),
        _phrases[2],
        _phrases[3],
      ]);
      await phrases.answer(learned: true);
      await phrases.answer(learned: true);
      phrases.flip();
    });
    await saveShot(tester, '28-flashcard');
  });

  testWidgets('28 Thẻ ghi nhớ — mặt trước, khách', skip: shotSkip != null, (tester) async {
    await open(tester, const FlashcardScreen(), member: false, before: () async {
      await phrases.loadOverview();
      phrases.startFlash([for (final p in _phrases.take(2)) p.withMarks(const PhraseMarks())]);
    });
    await saveShot(tester, '28-flashcard-guest-front');
  });

  testWidgets('28 Thẻ ghi nhớ — hết lượt', skip: shotSkip != null, (tester) async {
    await open(tester, const FlashcardScreen(), before: () async {
      await phrases.loadOverview();
      phrases.startFlash([_phrases[0], _phrases[1], _phrases[2]]);
      await phrases.answer(learned: true);
      await phrases.answer(learned: false);
      await phrases.answer(learned: true);
    });
    await saveShot(tester, '28-flashcard-done');
  });

  testWidgets('29 Đưa cho nhân viên xem', skip: shotSkip != null, (tester) async {
    await open(tester, PhraseStaffScreen(phrase: _phrases[0], keepScreenOn: (_) async {}), dialog: true);
    await saveShot(tester, '29-phrase-staff');
  });
}
