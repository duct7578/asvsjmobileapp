// FaqDao với server web thật: gọi mọi hàm đọc, kiểm tra đọc được JSON và có dữ liệu mẫu.
//
// Chạy: flutter test test/live/faq_live_test.dart --dart-define=LIVE_API=http://localhost:8080
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/faq_dao.dart';

import 'live_api.dart';

void main() {
  test('findTopics đọc mã, tên và số câu', () async {
    final dao = FaqDao(liveGuest());
    final topics = await dao.findTopics();
    expect(topics, isNotEmpty);
    expect(topics.every((t) => t.code.isNotEmpty && t.title.isNotEmpty), isTrue);
    expect(topics.fold<int>(0, (sum, t) => sum + t.count), greaterThan(0));

    final searched = await dao.findTopics(q: 'SIM');
    expect(searched.map((t) => t.code), topics.map((t) => t.code));
  }, skip: liveSkip);

  test('findAll: trang đầu, lọc chủ đề, tìm, trang sau', () async {
    final dao = FaqDao(liveGuest());
    final page = await dao.findAll();
    expect(page.items, isNotEmpty);
    expect(page.totalItems, greaterThanOrEqualTo(page.items.length));
    final first = page.items.first;
    expect(first.question, isNotEmpty);
    expect(first.answer, isNotEmpty);
    expect(first.topicName, isNotEmpty);
    expect(first.updatedAt, isNotNull);

    final topics = await dao.findTopics();
    final topic = topics.firstWhere((t) => t.count > 0);
    final byTopic = await dao.findAll(topic: topic.code);
    expect(byTopic.totalItems, topic.count);
    expect(byTopic.items.every((e) => e.topicCode == topic.code), isTrue);

    final word = first.question.split(' ').firstWhere((w) => w.length >= 3);
    final searched = await dao.findAll(q: word);
    expect(searched.items, isNotEmpty);

    final small = await dao.findAll(size: 2);
    if (small.hasMore) {
      final next = await dao.findAll(size: 2, page: 1);
      expect(next.page, 1);
      expect(next.items.map((e) => e.id), isNot(contains(small.items.first.id)));
    }
  }, skip: liveSkip);

  test('findById đọc một câu kèm liên kết "Xem thêm"; câu không có: 404', () async {
    final dao = FaqDao(liveGuest());
    final all = await dao.findAll(size: 50);
    final withLinks = all.items.where((e) => e.resources.isNotEmpty);
    final entry = await dao.findById((withLinks.isEmpty ? all.items.first : withLinks.first).id);
    expect(entry.question, isNotEmpty);
    if (withLinks.isNotEmpty) {
      expect(entry.resources.first.kind, isNotEmpty);
      expect(entry.resources.first.label, isNotEmpty);
    }

    await expectLater(
      dao.findById(99999999),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.message, 'message', 'FAQ không tồn tại hoặc đã bị ẩn.'),
      ),
    );
  }, skip: liveSkip);

  test('findRelated: câu giống, tối đa limit; câu toàn từ để hỏi thì rỗng', () async {
    final dao = FaqDao(liveGuest());
    final related = await dao.findRelated('Mua SIM điện thoại ở đâu khi mới sang Nhật?', limit: 3);
    expect(related, isNotEmpty);
    expect(related.length, lessThanOrEqualTo(3));
    expect(related.first.question, isNotEmpty);

    expect(await dao.findRelated('a'), isEmpty);
  }, skip: liveSkip);
}
