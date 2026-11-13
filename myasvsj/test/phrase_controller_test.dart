// Unit test của PhraseController: chạy với DAO và giọng đọc giả, không cần server.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/phrase_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/phrase.dart';

import 'phrase_fakes.dart';

void main() {
  late FakePhraseDao dao;
  late FakePhraseSpeaker speaker;
  late PhraseController controller;

  PhraseController create({bool member = false}) {
    dao = FakePhraseDao(member: member);
    speaker = FakePhraseSpeaker();
    return controller = PhraseController(dao, speaker: speaker);
  }

  setUp(() => create());

  Phrase byId(List<Phrase> list, int id) => list.firstWhere((p) => p.id == id);

  group('Trang đầu', () {
    test('loadOverview bật trạng thái chờ, rồi có hai phần và lý do báo lỗi', () async {
      final future = controller.loadOverview();
      expect(controller.isLoadingOverview, isTrue);
      await future;
      expect(controller.isLoadingOverview, isFalse);
      expect(controller.overview!.parts.map((p) => p.name), ['Mẫu câu', 'Từ vựng']);
      expect(controller.isMember, isFalse);
      expect(controller.reportReasons.map((r) => r.label), contains('Sai nghĩa'));
      expect(controller.overviewError, isNull);
    });

    test('loadOverview giữ câu báo lỗi của server', () async {
      dao.failWith = const ApiException('Không kết nối được tới server.');
      await controller.loadOverview();
      expect(controller.overviewError, 'Không kết nối được tới server.');
      expect(controller.overview, isNull);
      expect(controller.reportReasons, isEmpty);
    });

    test('thành viên: isMember theo cờ member của server', () async {
      create(member: true);
      await controller.loadOverview();
      expect(controller.isMember, isTrue);
    });
  });

  group('Tìm kiếm', () {
    test('chữ trống xóa kết quả và không gọi server', () async {
      await controller.search('   ');
      expect(dao.finds, isEmpty);
      expect(controller.query, '');
      expect(controller.results, isEmpty);
    });

    test('tìm theo nghĩa, gửi chữ đã cắt khoảng trắng', () async {
      final future = controller.search('  tàu ');
      expect(controller.isSearching, isTrue);
      await future;
      expect(dao.finds.single.q, 'tàu');
      expect(controller.query, 'tàu');
      expect(controller.results.map((p) => p.id), [13, 16]);
      expect(controller.isSearching, isFalse);
    });

    test('câu trả lời cho chữ cũ bị bỏ qua khi đã gõ chữ mới', () async {
      dao.hold = Completer<void>();
      final old = dao.hold!;
      final first = controller.search('túi');
      dao.hold = null;
      await controller.search('thẻ IC');
      expect(controller.results.map((p) => p.id), [14]);
      old.complete();
      await first;
      expect(controller.query, 'thẻ IC');
      expect(controller.results.map((p) => p.id), [14]);
      expect(controller.isSearching, isFalse);
    });

    test('lỗi tìm kiếm giữ câu của server', () async {
      dao.failWith = const ApiException('Server gặp lỗi (500). Hãy thử lại sau.');
      await controller.search('tàu');
      expect(controller.searchError, 'Server gặp lỗi (500). Hãy thử lại sau.');
      expect(controller.results, isEmpty);
    });
  });

  group('Một bộ', () {
    test('mỗi bộ giữ riêng theo khóa, để màn bộ mở chồng không hiện nhầm', () async {
      final topicKey = PhraseController.setKey(topic: 'pay');
      final placeKey = PhraseController.setKey(category: 'station');
      final future = controller.loadSet(topic: 'pay');
      expect(controller.isLoadingSet(topicKey), isTrue);
      await future;
      await controller.loadSet(category: 'station');
      expect(controller.isLoadingSet(topicKey), isFalse);
      expect(controller.phrasesOf(topicKey)!.map((p) => p.id), [1, 6, 14]);
      expect(controller.phrasesOf(placeKey)!.map((p) => p.id), [13, 14, 16]);
      expect(controller.phrasesOf(PhraseController.setKey(mine: 'learning')), isNull);
      expect(dao.finds.first.topic, 'pay');
    });

    test('lỗi của một bộ không làm mất bộ khác', () async {
      await controller.loadSet(topic: 'pay');
      await controller.loadSet(mine: 'learning'); // khách: 401
      expect(controller.setErrorOf('mine=learning'), 'Bạn cần đăng nhập để làm việc này.');
      expect(controller.phrasesOf('mine=learning'), isNull);
      expect(controller.phrasesOf('topic=pay'), hasLength(3));
      expect(controller.setErrorOf('topic=pay'), isNull);
    });

    test('defaultKind: Mẫu câu khi bộ có, ngược lại Từ vựng', () {
      final all = samplePhrases();
      expect(PhraseController.defaultKind(all), Phrase.phraseKind);
      expect(PhraseController.defaultKind(all.where((p) => !p.isPhrase).toList()), Phrase.vocabKind);
      expect(PhraseController.defaultKind(const []), Phrase.phraseKind);
    });

    test('filter lọc từng lớp: danh sách riêng, loại, mức thuộc', () {
      final all = samplePhrases(member: true);
      final phrases = PhraseController.filter(all, kind: Phrase.phraseKind);
      expect(phrases.ofKind.map((p) => p.id), [1, 2, 13, 14]);
      expect(phrases.list, phrases.ofKind);

      final fresh = PhraseController.filter(all, kind: Phrase.phraseKind, status: 'new');
      expect(fresh.list.map((p) => p.id), [2, 13]);

      final learning = PhraseController.filter(all, mine: 'learning');
      expect(learning.inList.map((p) => p.id), [14]);
      expect(PhraseController.filter(all, mine: 'learned', kind: Phrase.vocabKind).list, isEmpty);
    });
  });

  group('Dấu thẻ ghi nhớ', () {
    setUp(() async {
      create(member: true);
      await controller.loadOverview();
      await controller.loadSet(topic: 'pay');
      await controller.loadSet(category: 'konbini');
    });

    test('Bỏ đánh dấu: bỏ ngay ở mọi bộ, trừ số đã thuộc, rồi hiện câu của server', () async {
      final bag = byId(controller.phrasesOf('topic=pay')!, 1);
      final future = controller.clearMark(bag);
      // Lạc quan: chưa có trả lời của server mà dấu đã bỏ ở cả hai bộ
      expect(byId(controller.phrasesOf('topic=pay')!, 1).learned, isFalse);
      expect(byId(controller.phrasesOf('category=konbini')!, 1).learned, isFalse);
      expect(controller.overview!.part(Phrase.phraseKind)!.learned, 0);
      expect(await future, isTrue);
      expect(dao.cleared, [1]);
      expect(controller.takeMessage(), 'Đã bỏ đánh dấu.');
      expect(controller.takeMessage(), isNull);
    });

    test('Bỏ đánh dấu lỗi thì trả lại dấu cũ và số đã thuộc', () async {
      final bag = byId(controller.phrasesOf('topic=pay')!, 1);
      dao.failWith = const ApiException('Bạn không có quyền thực hiện thao tác này.', statusCode: 403);
      expect(await controller.clearMark(bag), isFalse);
      expect(byId(controller.phrasesOf('topic=pay')!, 1).learned, isTrue);
      expect(byId(controller.phrasesOf('category=konbini')!, 1).learned, isTrue);
      final part = controller.overview!.part(Phrase.phraseKind)!;
      expect(part.learned, 1);
      expect(part.topics.firstWhere((t) => t.id == 'pay').learned, 1);
      expect(controller.takeMessage(), 'Bạn không có quyền thực hiện thao tác này.');
    });

    test('Thành viên trả lời thẻ: lưu lên server, đổi dấu ở các bộ, sang thẻ sau', () async {
      controller.startFlash(controller.phrasesOf('category=konbini')!);
      expect(controller.currentCard!.id, 1);
      controller.flip();
      expect(controller.isFlipped, isTrue);

      await controller.answer(learned: false); // mục 1: Đã thuộc → Chưa thuộc
      expect(dao.flashes.single, (id: 1, learned: false));
      expect(byId(controller.phrasesOf('topic=pay')!, 1).learning, isTrue);
      expect(controller.overview!.part(Phrase.phraseKind)!.learned, 0);
      expect(controller.currentCard!.id, 2);
      expect(controller.isFlipped, isFalse);

      await controller.answer(learned: true);
      await controller.answer(learned: true);
      expect(controller.isFlashDone, isTrue);
      expect(controller.learningIds, [1]);
      expect(controller.learnedIds, [2, 6]);
      expect(byId(controller.phrasesOf('topic=pay')!, 6).learned, isTrue);
      expect(controller.overview!.part(Phrase.vocabKind)!.learned, 1);
    });

    test('Trả lời lỗi thì ở lại thẻ đó và giữ câu báo lỗi', () async {
      controller.startFlash(controller.phrasesOf('category=konbini')!);
      dao.failWith = const ApiException('Server gặp lỗi (500). Hãy thử lại sau.');
      await controller.answer(learned: true);
      expect(controller.currentCard!.id, 1);
      expect(controller.learnedIds, isEmpty);
      expect(controller.isAnswering, isFalse);
      expect(controller.takeMessage(), 'Server gặp lỗi (500). Hãy thử lại sau.');
    });

    test('Luyện lại các thẻ chưa thuộc ở cuối lượt', () async {
      controller.startFlash(controller.phrasesOf('category=konbini')!);
      await controller.answer(learned: false);
      await controller.answer(learned: true);
      await controller.answer(learned: false);
      controller.againLearning();
      expect(controller.flashCards.map((p) => p.id), [1, 6]);
      expect(controller.flashIndex, 0);
      expect(controller.learningIds, isEmpty);
      expect(controller.flashCards.every((p) => p.learning), isTrue);
    });
  });

  test('Khách lật và trả lời thẻ: không gọi server, chỉ đếm', () async {
    await controller.loadOverview();
    controller.startFlash(samplePhrases());
    await controller.answer(learned: true);
    await controller.answer(learned: false);
    expect(dao.flashes, isEmpty);
    expect(controller.learnedIds, [1]);
    expect(controller.learningIds, [2]);
    expect(controller.currentCard!.id, 6);
  });

  group('Luyện tập', () {
    test('Tất cả: cả thư viện; đổi loại thì số thẻ đổi theo', () async {
      await controller.loadOverview();
      final future = controller.loadLibrary();
      expect(controller.isLoadingLibrary, isTrue);
      await future;
      expect(controller.practicePool, hasLength(6));
      controller.choosePractice(kind: Phrase.vocabKind);
      expect(controller.practicePool.map((p) => p.id), [6, 16]);
    });

    test('Chủ đề: chọn chủ đề đầu tiên, đếm mục mỗi chủ đề, lọc theo chủ đề', () async {
      await controller.loadOverview();
      await controller.loadLibrary();
      controller.choosePractice(by: 'topic', kind: '');
      final groups = controller.practiceGroups();
      expect({for (final g in groups) g.id: g.count}, {'pay': 3, 'train': 3, 'ask': 1});
      expect(controller.practiceGroup, groups.first.id);

      controller.choosePractice(group: 'ask');
      expect(controller.practicePool.map((p) => p.id), [13]);
      controller.choosePractice(by: 'category');
      expect(controller.practiceGroup, 'konbini');
      expect(controller.practicePool.map((p) => p.id), [1, 2, 6]);
    });

    test('Khách không lọc theo mức thuộc; thành viên lọc được', () async {
      await controller.loadOverview();
      await controller.loadLibrary();
      controller.choosePractice(status: 'learning');
      expect(controller.practiceStatus, '');

      create(member: true);
      await controller.loadOverview();
      await controller.loadLibrary();
      controller.choosePractice(status: 'learning');
      expect(controller.practicePool.map((p) => p.id), [14]);
    });

    test('Bắt đầu có xáo trộn vẫn đủ các thẻ của lựa chọn', () async {
      await controller.loadOverview();
      await controller.loadLibrary();
      controller.choosePractice(shuffle: true);
      controller.startPractice();
      expect(controller.flashCards.map((p) => p.id).toSet(), {1, 2, 6, 13, 14, 16});
      controller.choosePractice(shuffle: false, kind: Phrase.phraseKind);
      controller.startPractice();
      expect(controller.flashCards.map((p) => p.id), [1, 2, 13, 14]);
    });

    test('lỗi tải thư viện giữ câu của server', () async {
      dao.failWith = const ApiException('Không kết nối được tới server.');
      await controller.loadLibrary();
      expect(controller.libraryError, 'Không kết nối được tới server.');
      expect(controller.practicePool, isEmpty);
    });
  });

  group('Báo lỗi, nghe', () {
    test('báo lỗi gửi lý do và ghi chú đã cắt khoảng trắng, giữ câu của server', () async {
      create(member: true);
      expect(await controller.report(14, 6, '  sai nghĩa  '), isTrue);
      expect(dao.reports.single, (id: 14, reasonId: 6, note: 'sai nghĩa'));
      expect(controller.takeMessage(), 'Đã gửi báo cáo cho Biên tập viên nội dung tiếng Nhật.');
    });

    test('báo lỗi lần hai nhận câu từ chối của server', () async {
      create(member: true);
      dao.failWith = const ApiException('Bạn đã báo cáo nội dung này rồi.', statusCode: 409);
      expect(await controller.report(14, 6, ''), isFalse);
      expect(controller.takeMessage(), 'Bạn đã báo cáo nội dung này rồi.');
    });

    test('Nghe đọc chữ Nhật; máy chưa có giọng ja-JP thì báo nhẹ', () async {
      expect(await controller.speak('袋はいりません。'), isTrue);
      expect(speaker.spoken, ['袋はいりません。']);
      expect(controller.takeMessage(), isNull);

      speaker.hasVoice = false;
      expect(await controller.speak('レジ'), isFalse);
      expect(controller.takeMessage(), PhraseController.noVoiceMessage);
      await controller.stopSpeaking();
      expect(speaker.stops, 1);
    });
  });
}
