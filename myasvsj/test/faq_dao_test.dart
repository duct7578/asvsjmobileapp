// Test FaqDao với server giả (FakeServer) và JSON thật của web (test/qa_json.dart).
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/faq_dao.dart';

import 'fake_api.dart';
import 'qa_json.dart';

void main() {
  test('findAll gửi từ khóa, chủ đề, trang và đọc trang có "total"', () async {
    final server = FakeServer({'GET /api/faqs': (_) => apiOk(faqPageJson())});
    final page = await FaqDao(server.api).findAll(q: ' hộ chiếu ', topic: 'OTHER', page: 0);

    final query = server.last('GET', '/api/faqs').uri.queryParameters;
    expect(query, {'q': 'hộ chiếu', 'topic': 'OTHER', 'page': '0', 'size': '10'});
    expect(page.totalItems, 10);
    expect(page.totalPages, 5);
    expect(page.hasMore, isTrue);
    final first = page.items.first;
    expect(first.id, 10);
    expect(first.question, 'Nếu bị mất hộ chiếu tại Nhật phải làm gì?');
    expect(first.answer, contains('\n\nNên chuẩn bị bản sao hộ chiếu'));
    expect(first.topicCode, 'OTHER');
    expect(first.topicName, 'Khác');
    expect(first.updatedAt, DateTime.utc(2026, 11, 7, 18, 36, 40).toLocal());
    expect(first.resources, isEmpty);
  });

  test('findAll không gửi q và topic khi trống; trang rỗng', () async {
    final server = FakeServer({'GET /api/faqs': (_) => apiOk(faqEmptyPageJson())});
    final page = await FaqDao(server.api).findAll(q: '  ', topic: '');

    final query = server.last('GET', '/api/faqs').uri.queryParameters;
    expect(query.keys, unorderedEquals(['page', 'size']));
    expect(page.items, isEmpty);
    expect(page.totalItems, 0);
    expect(page.hasMore, isFalse);
  });

  test('findTopics đọc mã, tên và số câu; gửi q khi đang tìm', () async {
    final server = FakeServer({'GET /api/faqs/topics': (_) => apiOk(faqTopicsJson(), message: 'Chủ đề FAQ')});
    final topics = await FaqDao(server.api).findTopics(q: 'SIM');

    expect(server.last('GET', '/api/faqs/topics').uri.queryParameters, {'q': 'SIM'});
    expect(topics.map((t) => t.code), ['PREPARATION', 'LIVING', 'STUDY_WORK', 'PROCEDURES', 'LANGUAGE', 'OTHER']);
    expect(topics.first.title, 'Chuẩn bị trước khi sang Nhật');
    expect(topics.first.count, 3);
  });

  test('findById đọc liên kết "Xem thêm"', () async {
    final server = FakeServer({'GET /api/faqs/5': (_) => apiOk(faqEntryJson())});
    final entry = await FaqDao(server.api).findById(5);

    expect(entry.question, 'Phân loại và đổ rác tại Nhật như thế nào?');
    final link = entry.resources.single;
    expect(link.kind, 'GUIDE');
    expect(link.targetId, 24);
    expect(link.url, isNull);
    expect(link.isExternal, isFalse);
    expect(link.label, 'Xem chi tiết về phân loại rác tại Nhật');
  });

  test('findById ném ApiException khi câu không còn', () async {
    final server = FakeServer({'GET /api/faqs/99999': (_) => apiError(404, 'FAQ không tồn tại hoặc đã bị ẩn.')});

    await expectLater(
      FaqDao(server.api).findById(99999),
      throwsA(
        isA<ApiException>()
            .having((e) => e.message, 'message', 'FAQ không tồn tại hoặc đã bị ẩn.')
            .having((e) => e.statusCode, 'statusCode', 404),
      ),
    );
  });

  test('findRelated gửi q và limit, đọc danh sách', () async {
    final server = FakeServer({'GET /api/faqs/related': (_) => apiOk(faqRelatedJson(), message: 'FAQ liên quan')});
    final related = await FaqDao(server.api).findRelated(' mua SIM data ', limit: 5);

    expect(server.last('GET', '/api/faqs/related').uri.queryParameters, {'q': 'mua SIM data', 'limit': '5'});
    expect(related.single.id, 4);
    expect(related.single.topicName, 'Sinh hoạt và đời sống');
  });

  test('lỗi mạng của server (500) thành ApiException', () async {
    final server = FakeServer({'GET /api/faqs/related': (_) => const FakeReply(500, null)});

    await expectLater(FaqDao(server.api).findRelated('visa'), throwsA(isA<ApiException>()));
  });
}
