// Unit test của FaqController: chạy với DAO giả, không cần server.
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/faq_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';

import 'faq_fakes.dart';

void main() {
  late FakeFaqDao dao;
  late FaqController controller;

  setUp(() {
    dao = FakeFaqDao();
    controller = FaqController(dao, suggestDelay: const Duration(milliseconds: 30));
  });

  tearDown(() => controller.dispose());

  test('loadFaqs lấy chủ đề và trang đầu, tắt trạng thái chờ', () async {
    final future = controller.loadFaqs();
    expect(controller.isLoading, isTrue);
    await future;
    expect(controller.isLoading, isFalse);
    expect(controller.hasLoaded, isTrue);
    expect(controller.entries.map((e) => e.id), [4, 5, 10]);
    expect(controller.totalItems, 3);
    expect(controller.topics.map((t) => t.count), [2, 0, 1]);
    expect(controller.allCount, 3);
    expect(controller.related, isEmpty);
    expect(controller.isFiltered, isFalse);
  });

  test('tìm không ra câu nào khớp nguyên văn: lấy tối đa 5 câu có thể liên quan', () async {
    await controller.search('  điện thoại di động  ');
    expect(dao.lastQuery['q'], 'điện thoại di động');
    expect(controller.entries, isEmpty);
    expect(dao.relatedCalls.single, (q: 'điện thoại di động', limit: 5));
    expect(controller.related.single.id, 4);
    expect(controller.isFiltered, isTrue);
  });

  test('lọc theo chủ đề, rồi Xóa bộ lọc', () async {
    await controller.selectTopic('OTHER');
    expect(dao.lastQuery['topic'], 'OTHER');
    expect(controller.entries.single.id, 10);

    await controller.clearFilters();
    expect(controller.topicCode, '');
    expect(controller.query, '');
    expect(controller.entries, hasLength(3));
  });

  test('chủ đề không còn trong danh sách: quay về mọi chủ đề', () async {
    await controller.selectTopic('KHONG_CO');
    expect(controller.topicCode, '');
    expect(dao.lastQuery['topic'], '');
    expect(controller.entries, hasLength(3));
  });

  test('lỗi danh sách giữ câu báo lỗi; lỗi chủ đề không chặn danh sách', () async {
    dao.failOn['findTopics'] = const ApiException('Lỗi chủ đề');
    await controller.loadFaqs();
    expect(controller.error, isNull);
    expect(controller.entries, hasLength(3));
    expect(controller.topics, isEmpty);

    dao.failOn['findAll'] = const ApiException('Không kết nối được tới server.');
    await controller.loadFaqs();
    expect(controller.error, 'Không kết nối được tới server.');
    expect(controller.entries, isEmpty);
  });

  test('loadMore nối trang sau; lỗi thì giữ danh sách và ghi moreError', () async {
    dao = FakeFaqDao(perPage: 2);
    controller = FaqController(dao);
    await controller.loadFaqs();
    expect(controller.hasMore, isTrue);

    dao.failOn['findAll'] = const ApiException('Mất mạng.');
    await controller.loadMore();
    expect(controller.entries, hasLength(2));
    expect(controller.moreError, 'Mất mạng.');
    expect(controller.hasMore, isTrue);

    dao.failOn.clear();
    await controller.loadMore();
    expect(controller.entries.map((e) => e.id), [4, 5, 10]);
    expect(controller.hasMore, isFalse);
    expect(controller.moreError, isNull);
  });

  test('loadEntry giữ câu theo id; câu không còn thì báo câu dễ hiểu', () async {
    final future = controller.loadEntry(5);
    expect(controller.isLoadingEntry(5), isTrue);
    await future;
    expect(controller.entryOf(5)?.resources.single.targetId, 24);

    await controller.loadEntry(99);
    expect(controller.entryOf(99), isNull);
    expect(controller.entryError(99), 'Câu hỏi thường gặp này không còn hoặc đã được ẩn.');
  });

  test('loadHits: từ khóa ngắn không gọi server; đủ dài lấy tối đa 3 câu; lỗi thì rỗng', () async {
    await controller.loadHits('a');
    expect(dao.relatedCalls, isEmpty);
    expect(controller.hits, isEmpty);

    await controller.loadHits(' SIM ');
    expect(dao.relatedCalls.single, (q: 'SIM', limit: 3));
    expect(controller.hits.single.id, 4);
    expect(controller.hitsQuery, 'SIM');

    dao.failWith = const ApiException('Mất mạng.');
    await controller.loadHits('visa');
    expect(controller.hits, isEmpty);
  });

  test('suggest chờ người dùng ngừng gõ, câu ngắn hơn 8 ký tự bỏ gợi ý', () async {
    controller.suggest('Mua SIM');
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(dao.relatedCalls, isEmpty);

    controller.suggest('Mua SIM ở');
    controller.suggest('Mua SIM ở đâu');
    expect(dao.relatedCalls, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(dao.relatedCalls.single, (q: 'Mua SIM ở đâu', limit: 3));
    expect(controller.suggestions.single.id, 4);

    // Gõ lại đúng câu cũ: không hỏi server lần nữa
    controller.suggest('Mua SIM ở đâu ');
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(dao.relatedCalls, hasLength(1));

    controller.suggest('Mua');
    expect(controller.suggestions, isEmpty);
  });

  test('clearSuggestions hủy lần tìm đang chờ', () async {
    controller.suggest('Gia hạn visa du học');
    controller.clearSuggestions();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(dao.relatedCalls, isEmpty);
    expect(controller.suggestions, isEmpty);
  });
}
