// PhraseDao với server thật: mọi hàm đọc (khách và thành viên), thẻ ghi nhớ ghi rồi trả lại dấu cũ, báo lỗi.
//
// Chạy: flutter test test/live/phrase_live_test.dart --dart-define=LIVE_API=http://localhost:8080
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/phrase.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_dao.dart';

import 'live_api.dart';

void main() {
  group('khách', () {
    final dao = PhraseDao(liveGuest());

    test('findOverview: hai phần có chủ đề, địa điểm, 4 lý do báo lỗi, không phải thành viên', () async {
      final overview = await dao.findOverview();
      expect(overview.member, isFalse);
      expect(overview.parts.map((p) => p.kind), containsAll([Phrase.phraseKind, Phrase.vocabKind]));
      for (final part in overview.parts) {
        expect(part.name, isNotEmpty);
        expect(part.count, greaterThan(0));
        expect(part.learned, 0);
        expect(part.topics, isNotEmpty);
        expect(part.categories, isNotEmpty);
        for (final g in [...part.topics, ...part.categories]) {
          expect(g.id, isNotEmpty);
          expect(g.name, isNotEmpty);
          expect(g.icon, isNotEmpty);
          expect(g.count, greaterThan(0));
        }
      }
      expect(overview.reportReasons.map((r) => r.label), ['Sai tiếng Nhật', 'Sai nghĩa', 'Xúc phạm', 'Spam']);
    }, skip: liveSkip);

    test('findAll: cả thư viện, theo chủ đề, theo địa điểm, tìm kiếm', () async {
      final all = await dao.findAll();
      expect(all, isNotEmpty);
      for (final p in all) {
        expect(p.id, greaterThan(0));
        expect([Phrase.phraseKind, Phrase.vocabKind], contains(p.kind));
        expect(p.japanese, isNotEmpty);
        expect(p.meaningVi, isNotEmpty);
        expect(p.category.id, isNotEmpty);
        expect(p.category.name, isNotEmpty);
        expect(p.isNew, isTrue); // khách không có dấu
      }
      expect(all.any((p) => p.topics.isNotEmpty), isTrue);
      expect(all.any((p) => p.romaji.isNotEmpty), isTrue);

      final overview = await dao.findOverview();
      final topic = overview.part(Phrase.phraseKind)!.topics.first;
      final byTopic = await dao.findAll(topic: topic.id);
      expect(byTopic, isNotEmpty);
      expect(byTopic.every((p) => p.inGroup('topic', topic.id)), isTrue);

      final byPlace = await dao.findAll(category: 'konbini');
      expect(byPlace, isNotEmpty);
      expect(byPlace.every((p) => p.category.id == 'konbini'), isTrue);

      // Tìm bỏ dấu và hoa thường: "tau" thấy "tàu"
      final found = await dao.findAll(q: 'tau');
      expect(found, isNotEmpty);
    }, skip: liveSkip);

    test('khách xem danh sách riêng nhận 401; danh sách lạ nhận 400', () async {
      await expectLater(
        dao.findAll(mine: 'learning'),
        throwsA(isA<ApiException>().having((e) => e.isUnauthorized, '401', isTrue)),
      );
      await expectLater(
        dao.findAll(mine: 'xyz'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Danh sách không hợp lệ.')),
      );
    }, skip: liveSkip);

    test('khách lưu thẻ ghi nhớ nhận 401', () async {
      await expectLater(
        dao.flash(2, learned: true),
        throwsA(isA<ApiException>().having((e) => e.isUnauthorized, '401', isTrue)),
      );
    }, skip: liveSkip);
  });

  group('thành viên user@gmail.com', () {
    late PhraseDao dao;

    setUpAll(() async {
      if (liveSkip == null) {
        dao = PhraseDao(await liveSignedIn('user@gmail.com'));
      }
    });

    test('findOverview là thành viên; đọc được danh sách Chưa thuộc / Đã thuộc', () async {
      final overview = await dao.findOverview();
      expect(overview.member, isTrue);
      final learning = await dao.findAll(mine: 'learning');
      final learned = await dao.findAll(mine: 'learned');
      expect(learning.every((p) => p.learning && !p.learned), isTrue);
      expect(learned.every((p) => p.learned && !p.learning), isTrue);
    }, skip: liveSkip);

    test('thẻ ghi nhớ: Chưa thuộc → Đã thuộc → Bỏ đánh dấu, rồi trả lại dấu cũ', () async {
      final before = (await dao.findAll(category: 'konbini')).firstWhere((p) => p.id == 2);
      try {
        final learning = await dao.flash(2, learned: false);
        expect([learning.learning, learning.learned, learning.message], [true, false, 'Đã lưu: Chưa thuộc.']);
        expect((await dao.findAll(mine: 'learning')).map((p) => p.id), contains(2));

        final overviewBefore = await dao.findOverview();
        final learned = await dao.flash(2, learned: true);
        expect([learned.learning, learned.learned, learned.message], [false, true, 'Đã lưu: Đã thuộc.']);
        final overviewAfter = await dao.findOverview();
        expect(overviewAfter.part(Phrase.phraseKind)!.learned, overviewBefore.part(Phrase.phraseKind)!.learned + 1);
        expect((await dao.findAll(mine: 'learned')).map((p) => p.id), contains(2));

        final cleared = await dao.clearFlash(2);
        expect([cleared.learning, cleared.learned, cleared.message], [false, false, 'Đã bỏ đánh dấu.']);
        expect((await dao.findAll(mine: 'learned')).map((p) => p.id), isNot(contains(2)));
      } finally {
        // Trả lại đúng dấu của tài khoản mẫu trước khi thử
        if (before.learned || before.learning) {
          await dao.flash(2, learned: before.learned);
        } else {
          await dao.clearFlash(2);
        }
      }
      final after = (await dao.findAll(category: 'konbini')).firstWhere((p) => p.id == 2);
      expect([after.learning, after.learned], [before.learning, before.learned]);
    }, skip: liveSkip);

    test('mẫu câu không có nhận 404; lý do không thuộc nhóm báo lỗi mẫu câu nhận 400', () async {
      await expectLater(
        dao.flash(99999, learned: true),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Không tìm thấy mẫu câu này.')),
      );
      await expectLater(
        dao.report(2, reasonId: 1),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Hãy chọn lý do báo cáo.')),
      );
    }, skip: liveSkip);

    // Báo lỗi thật đúng một lần trên mục 48 (敷金礼金); các lần chạy sau server trả 409 "đã báo cáo rồi"
    test('báo lỗi mục 48: lần đầu được nhận, lần sau nhận 409', () async {
      try {
        final message = await dao.report(48, reasonId: 6, note: 'Báo lỗi thử từ app mobile (test tự động).');
        expect(message, 'Đã gửi báo cáo cho Biên tập viên nội dung tiếng Nhật.');
      } on ApiException catch (e) {
        expect(e.statusCode, 409);
        expect(e.message, 'Bạn đã báo cáo nội dung này rồi.');
      }
    }, skip: liveSkip);
  });
}
