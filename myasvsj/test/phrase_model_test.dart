// Unit test của thực thể Nhật ngữ: lọc theo mức thuộc / nhóm và số "đã thuộc" ở trang đầu khi dấu đổi.
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/phrase.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_marks.dart';

import 'phrase_fakes.dart';

void main() {
  final phrases = samplePhrases(member: true);
  final bag = phrases.firstWhere((p) => p.id == 1); // Đã thuộc, konbini, chủ đề pay
  final charge = phrases.firstWhere((p) => p.id == 14); // Chưa thuộc, station, chủ đề train + pay
  final warm = phrases.firstWhere((p) => p.id == 2); // Chưa luyện

  test('hasStatus lọc Chưa thuộc / Đã thuộc / Chưa luyện; "" là tất cả', () {
    expect(bag.hasStatus('learned'), isTrue);
    expect(bag.hasStatus('learning'), isFalse);
    expect(charge.hasStatus('learning'), isTrue);
    expect(warm.isNew, isTrue);
    expect(warm.hasStatus('new'), isTrue);
    expect(bag.hasStatus('new'), isFalse);
    expect(phrases.every((p) => p.hasStatus('')), isTrue);
  });

  test('inGroup theo chủ đề hoặc loại địa điểm', () {
    expect(charge.inGroup('topic', 'pay'), isTrue);
    expect(charge.inGroup('topic', 'ask'), isFalse);
    expect(charge.inGroup('category', 'station'), isTrue);
    expect(charge.inGroup('category', 'konbini'), isFalse);
  });

  test('withMarks giữ nguyên nội dung, chỉ đổi dấu', () {
    final updated = charge.withMarks(const PhraseMarks(learned: true));
    expect(
      [updated.id, updated.japanese, updated.category.id, updated.topics.length],
      [14, 'チャージしたいです。', 'station', 2],
    );
    expect([updated.learning, updated.learned], [false, true]);
  });

  test('Overview: hai phần hiện Từ vựng trước, nhóm không trùng, tìm được nhóm theo mã', () {
    final overview = overviewOf(phrases, member: true);
    expect(overview.shownParts.map((p) => p.kind), [Phrase.vocabKind, Phrase.phraseKind]);
    expect(overview.groupsOf('category').map((g) => g.id), ['konbini', 'station']);
    expect(overview.groupsOf('topic').map((g) => g.id).toSet(), {'pay', 'train', 'ask'});
    expect(overview.groupsOf('topic').length, 3);
    expect(overview.findGroup(topicId: 'train')?.name, 'Đi tàu');
    expect(overview.findGroup(categoryId: 'konbini')?.icon, 'local_convenience_store');
    expect(overview.findGroup(topicId: 'khong-co'), isNull);
  });

  test('Overview.withMarks cộng 1 "đã thuộc" ở phần, chủ đề và địa điểm của mục', () {
    final overview = overviewOf(phrases, member: true);
    final part = overview.part(Phrase.phraseKind)!;
    expect(part.learned, 1);

    final after = overview.withMarks(charge, const PhraseMarks(learned: true));
    final newPart = after.part(Phrase.phraseKind)!;
    expect(newPart.learned, 2);
    expect(newPart.topics.firstWhere((t) => t.id == 'pay').learned, 2);
    expect(newPart.topics.firstWhere((t) => t.id == 'train').learned, 1);
    expect(newPart.topics.firstWhere((t) => t.id == 'ask').learned, 0);
    expect(newPart.categories.firstWhere((c) => c.id == 'station').learned, 1);
    expect(newPart.categories.firstWhere((c) => c.id == 'konbini').learned, 1);
    // Phần Từ vựng không đổi
    expect(identical(after.part(Phrase.vocabKind), overview.part(Phrase.vocabKind)), isTrue);
  });

  test('Overview.withMarks trừ 1 khi bỏ "Đã thuộc", giữ nguyên khi "đã thuộc" không đổi', () {
    final overview = overviewOf(phrases, member: true);
    final after = overview.withMarks(bag, const PhraseMarks(learning: true));
    expect(after.part(Phrase.phraseKind)!.learned, 0);
    expect(after.part(Phrase.phraseKind)!.categories.firstWhere((c) => c.id == 'konbini').learned, 0);

    expect(identical(overview.withMarks(warm, const PhraseMarks(learning: true)), overview), isTrue);
  });
}
