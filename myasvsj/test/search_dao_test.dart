// Test SearchDao với server giả: gửi đúng từ khóa, đọc đúng mọi phần của JSON thật của web.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/search_dao.dart';

import 'fake_api.dart';
import 'search_samples.dart';

void main() {
  test('gửi từ khóa đã bỏ khoảng trắng; đọc địa điểm, bài viết, câu hỏi, sự kiện', () async {
    final server = FakeServer({'GET /api/search': (_) => jsonDecode(searchNipporiJson)});
    final result = await SearchDao(server.api).search('  Nippori ');

    final request = server.last('GET', '/api/search');
    expect(request.method, 'GET');
    expect(request.uri.queryParameters, {'q': 'Nippori'});
    expect(result.q, 'Nippori');
    expect(result.tooShort, isFalse);
    expect(result.total, 16);
    expect(result.isEmpty, isFalse);

    expect(result.places.total, 7);
    expect(result.places.items, hasLength(5));
    expect(result.places.hasMore, isTrue);
    final station = result.places.items.first;
    expect(station.id, 1);
    expect(station.name, 'Ga Nippori');
    expect(station.nameJa, '日暮里駅');
    expect(station.nameEn, 'Nippori Station');
    expect(station.otherName, '日暮里駅');
    expect(station.categoryName, 'Ga tàu');
    expect(station.categoryIcon, 'train');
    expect(station.areaName, 'Arakawa-ku, Tokyo · 東京都荒川区');
    expect(station.address, 'Higashi-Nippori 6, Arakawa, Tokyo');
    expect(station.closed, isFalse);
    expect(station.reviewCount, 2);
    expect(station.rating, 4.5);
    // Có review 5.0 (server gửi số thực) và chưa có review (rating null)
    expect(result.places.items[3].rating, 5.0);
    expect(result.places.items[4].reviewCount, 0);
    expect(result.places.items[4].rating, isNull);

    expect(result.posts.total, 5);
    expect(result.posts.hasMore, isFalse);
    final post = result.posts.items.first;
    expect(post.id, 1);
    expect(post.title, 'Năm điều mình ước biết trước tuần đầu ở Tokyo');
    expect(post.excerpt, startsWith('Mua thẻ IC'));
    expect(post.status, 'PUBLISHED');
    expect(post.isProcessing, isFalse);
    expect(post.topicNames, ['Kinh nghiệm', 'Thủ tục giấy tờ', 'Đi lại']);
    expect(post.authorName, 'Lan Anh');
    expect(post.authorTags.single.name, 'Mentor');
    expect(post.likeCount, 24);
    expect(post.commentCount, 0);
    expect(post.createdAt?.toUtc(), DateTime.utc(2026, 10, 20, 18, 36, 45));

    expect(result.questions.total, 1);
    final question = result.questions.items.single;
    expect(question.id, 6);
    expect(question.title, startsWith('Mua SIM data'));
    expect(question.solved, isFalse);
    expect(question.unanswered, isTrue);
    expect(question.topicNames, ['Mua sắm', 'Ngân hàng và tiền']);
    expect(question.authorName, 'Trần Minh');
    expect(question.likeCount, 3);
    expect(question.answerCount, 0);

    expect(result.events.total, 3);
    final event = result.events.items.first;
    expect(event.id, 3);
    expect(event.title, 'Lễ hội phố vải Nippori');
    expect(event.startDate, DateTime(2026, 11, 10));
    expect(event.endDate, DateTime(2026, 11, 11));
    expect(event.locationName, 'Phố vải Nippori, Higashi-Nippori');
    expect(event.state, 'UPCOMING');
    expect(event.daysUntil, 2);
    expect(event.costNote, 'Miễn phí');

    expect(result.guides.isEmpty, isTrue);
    expect(result.phrases.items, isEmpty);
    expect(result.faqs.total, 0);
  });

  test('đọc cẩm nang, mẫu câu, câu hỏi thường gặp', () async {
    final server = FakeServer({'GET /api/search': (_) => jsonDecode(searchResidenceCardJson)});
    final result = await SearchDao(server.api).search('thẻ cư trú');

    expect(server.last('GET', '/api/search').uri.queryParameters['q'], 'thẻ cư trú');
    expect(result.q, 'thẻ cư trú');

    expect(result.guides.total, 2);
    final guide = result.guides.items.first;
    expect(guide.id, 21);
    expect(guide.title, startsWith('Thẻ cư trú 在留カード'));
    expect(guide.summary, '');
    expect(guide.stageName, 'Khi mới đến (tuần đầu đến 3 tháng)');
    expect(guide.topicName, 'Thủ tục');
    expect(guide.coverImageUrl, startsWith('/media/guide/'));
    expect(result.guides.items[1].coverImageUrl, isNull);

    final phrase = result.phrases.items.single;
    expect(phrase.id, 24);
    expect(phrase.kind, 'VOCAB');
    expect(phrase.isVocab, isTrue);
    expect(phrase.japanese, '在留カード');
    expect(phrase.romaji, 'zairyū kādo');
    expect(phrase.meaningVi, 'Thẻ cư trú.');
    expect(phrase.categoryName, 'Văn phòng quận');

    expect(result.faqs.total, 2);
    final faq = result.faqs.items.first;
    expect(faq.id, 8);
    expect(faq.question, 'Nếu làm mất thẻ cư trú tại Nhật thì phải làm gì?');
    expect(faq.answer, startsWith('Khi phát hiện mất thẻ'));
    expect(faq.topicName, 'Thủ tục và giấy tờ');
  });

  test('từ khóa quá ngắn: tooShort, mọi phần rỗng', () async {
    final server = FakeServer({'GET /api/search': (_) => jsonDecode(searchTooShortJson)});
    final result = await SearchDao(server.api).search('a');

    expect(result.tooShort, isTrue);
    expect(result.total, 0);
    expect(result.isEmpty, isTrue);
  });

  test('từ khóa quá 100 ký tự: server trả 400 thành ApiException', () async {
    final server = FakeServer({'GET /api/search': (_) => apiError(400, 'Từ khóa tìm kiếm tối đa 100 ký tự.')});
    await expectLater(
      SearchDao(server.api).search('x' * 101),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.message, 'message', 'Từ khóa tìm kiếm tối đa 100 ký tự.'),
      ),
    );
  });
}
