// GuideDao với server thật: đọc bộ lọc, danh sách, chi tiết, checklist, trạng thái người xem, "Cẩm nang của tôi";
// lưu / đánh dấu xong / tick rồi trả lại đúng trạng thái cũ.
//
//   flutter test test/live/guide_live_test.dart --dart-define=LIVE_API=http://localhost:8080
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/guide.dart';
import 'package:myasvsj/com.myasvsj.model/guide_dao.dart';

import 'live_api.dart';

/// Mọi cẩm nang đã đăng (đi hết các trang).
Future<List<Guide>> _allGuides(GuideDao dao) async {
  final all = <Guide>[];
  var page = 0;
  while (true) {
    final result = await dao.findAll(page: page);
    all.addAll(result.items);
    if (!result.hasMore) {
      return all;
    }
    page++;
  }
}

void main() {
  test('khách: giai đoạn, chủ đề, danh sách có bộ lọc / phân trang, chi tiết, checklist, trạng thái', () async {
    final dao = GuideDao(liveGuest());

    final stages = await dao.findStages();
    expect(stages.map((s) => s.code), ['PRE', 'ARR', 'LEAVE', 'HOME']);
    expect(stages.every((s) => s.title.isNotEmpty), isTrue);
    final topics = await dao.findTopics();
    expect(topics, isNotEmpty);

    final first = await dao.findAll();
    expect(first.items, isNotEmpty);
    expect(first.totalItems, greaterThan(0));
    expect(first.items.length, lessThanOrEqualTo(GuideDao.pageSize));
    final all = await _allGuides(dao);
    expect(all.length, first.totalItems);
    expect(all.map((g) => g.id).toSet().length, all.length);

    final arr = await dao.findAll(stage: 'ARR');
    expect(arr.items, isNotEmpty);
    expect(arr.items.every((g) => g.stageCode == 'ARR'), isTrue);
    final topic = all.firstWhere((g) => g.topicCode != null).topicCode!;
    expect((await dao.findAll(topic: topic)).items.every((g) => g.topicCode == topic), isTrue);
    final byTitle = await dao.findAll(sort: 'TITLE');
    expect(byTitle.items, isNotEmpty);
    expect((await dao.findAll(sort: 'OLDEST')).items, isNotEmpty);
    expect((await dao.findAll(q: 'tàu')).items, isNotEmpty);
    expect((await dao.findAll(q: 'khongcocamnangnaynhe')).items, isEmpty);

    for (final g in first.items) {
      final guide = await dao.findById(g.id);
      expect(guide.title, g.title);
      expect(guide.createdAt, isNotNull);
      final viewer = await dao.findViewer(g.id);
      expect(viewer.signedIn, isFalse);
      expect(viewer.member, isFalse);
      expect(viewer.saved, isFalse);
      expect(viewer.progress.checklist, guide.preparationEnabled && guide.preparationTasks.isNotEmpty);
    }

    final checklist = all.firstWhere((g) => g.preparationEnabled);
    final detail = await dao.findById(checklist.id);
    expect(detail.sections, isNotEmpty);
    expect(detail.preparationTasks, isNotEmpty);
    final preparation = await dao.findPreparation(checklist.id);
    expect(preparation.signedIn, isFalse);
    expect(preparation.total, detail.preparationTasks.length);
    expect(preparation.completed, 0);

    final plain = all.firstWhere((g) => !g.preparationEnabled);
    await expectLater(dao.findPreparation(plain.id), throwsA(isA<ApiException>()));
    await expectLater(
      dao.findById(99999999),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
    );
    // Khách không lưu, không tick, không xem "Cẩm nang của tôi" được
    await expectLater(dao.checkTask(checklist.id, preparation.tasks.first.id, true), throwsA(isA<ApiException>()));
    await expectLater(dao.save(plain.id), throwsA(isA<ApiException>()));
    await expectLater(dao.findMyProgress(), throwsA(isA<ApiException>()));
  }, skip: liveSkip);

  test('kouhai: Cẩm nang của tôi, lưu / bỏ lưu, đánh dấu xong, tick — trả lại trạng thái cũ', () async {
    final dao = GuideDao(await liveSignedIn('kouhai@gmail.com'));

    final my = await dao.findMyProgress();
    expect(my.stages.map((s) => s.code), ['PRE', 'ARR', 'LEAVE', 'HOME']);
    expect(my.stages.where((s) => s.current).length, lessThanOrEqualTo(1));
    for (final s in my.stages) {
      expect(s.done, lessThanOrEqualTo(s.total));
    }

    final all = await _allGuides(dao);
    // Dùng cẩm nang cuối danh sách (cũ nhất) để ít đụng dữ liệu agent khác đang thử
    final plain = all.lastWhere((g) => !g.preparationEnabled);
    final checklist = all.lastWhere((g) => g.preparationEnabled);

    // Lưu / Bỏ lưu
    final before = await dao.findViewer(plain.id);
    expect(before.signedIn, isTrue);
    expect(before.member, isTrue);
    if (before.saved) {
      expect(await dao.unsave(plain.id), 'Đã bỏ lưu cẩm nang.');
      expect((await dao.findViewer(plain.id)).saved, isFalse);
      expect(await dao.save(plain.id), 'Đã lưu cẩm nang.');
    } else {
      expect(await dao.save(plain.id), 'Đã lưu cẩm nang.');
      expect((await dao.findViewer(plain.id)).saved, isTrue);
      expect(await dao.unsave(plain.id), 'Đã bỏ lưu cẩm nang.');
    }
    expect((await dao.findViewer(plain.id)).saved, before.saved);

    // Đánh dấu đã xong
    if (before.progress.done) {
      final off = await dao.unmarkDone(plain.id);
      expect(off.progress.done, isFalse);
      final on = await dao.markDone(plain.id);
      expect(on.progress.done, isTrue);
    } else {
      final on = await dao.markDone(plain.id);
      expect(on.message, 'Đã đánh dấu xong cẩm nang.');
      expect(on.progress.done, isTrue);
      expect(on.progress.percent, 100);
      final off = await dao.unmarkDone(plain.id);
      expect(off.message, 'Đã bỏ đánh dấu đã xong.');
      expect(off.progress.done, isFalse);
    }
    expect((await dao.findViewer(plain.id)).progress.done, before.progress.done);

    // Cẩm nang có checklist: không đánh dấu tay được
    await expectLater(
      dao.markDone(checklist.id),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400)),
    );

    // Tick một việc rồi trả lại
    final preparation = await dao.findPreparation(checklist.id);
    expect(preparation.signedIn, isTrue);
    final task = preparation.tasks.first;
    final flipped = await dao.checkTask(checklist.id, task.id, !task.completed);
    expect(flipped.tasks.first.completed, !task.completed);
    expect(flipped.completed, preparation.completed + (task.completed ? -1 : 1));
    final viewer = await dao.findViewer(checklist.id);
    expect(viewer.progress.checklist, isTrue);
    expect(viewer.progress.tasksDone, flipped.completed);
    final restored = await dao.checkTask(checklist.id, task.id, task.completed);
    expect(restored.completed, preparation.completed);
    expect(restored.percent, preparation.percent);
  }, skip: liveSkip);
}
