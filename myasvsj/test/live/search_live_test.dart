// SearchDao với server thật (khách và thành viên). Chỉ kiểm tra cấu trúc và parse, không khẳng định số lượng cố định.
//   flutter test test/live/search_live_test.dart --dart-define=LIVE_API=http://localhost:8080
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/search_dao.dart';
import 'package:myasvsj/com.myasvsj.model/search_result.dart';

import 'live_api.dart';

/// Tổng của mọi phần bằng `total`, mỗi phần tối đa 5 mục.
void expectConsistent(SearchResult r) {
  final sections = [r.places, r.posts, r.questions, r.guides, r.events, r.phrases, r.faqs];
  expect(sections.fold<int>(0, (sum, s) => sum + s.total), r.total);
  for (final s in sections) {
    expect(s.items.length, lessThanOrEqualTo(5));
    expect(s.items.length, lessThanOrEqualTo(s.total));
  }
}

void main() {
  test('khách tìm "Nippori": địa điểm, bài viết, sự kiện', () async {
    final result = await SearchDao(liveGuest()).search('Nippori');
    expect(result.q, 'Nippori');
    expect(result.tooShort, isFalse);
    expectConsistent(result);
    expect(result.places.items, isNotEmpty);
    for (final p in result.places.items) {
      expect(p.name, isNotEmpty);
      expect(p.reviewCount == 0 ? p.rating == null : p.rating != null, isTrue);
    }
    expect(result.posts.items, isNotEmpty);
    for (final b in result.posts.items) {
      expect(b.title, isNotEmpty);
      expect(b.authorName, isNotEmpty);
    }
    for (final q in result.questions.items) {
      expect(q.title, isNotEmpty);
    }
    for (final e in result.events.items) {
      expect(['NOW', 'UPCOMING', 'PAST'], contains(e.state));
    }
  }, skip: liveSkip);

  test('khách tìm "thẻ cư trú": cẩm nang, mẫu câu, câu hỏi thường gặp', () async {
    final result = await SearchDao(liveGuest()).search('thẻ cư trú');
    expect(result.q, 'thẻ cư trú');
    expectConsistent(result);
    expect(result.guides.items, isNotEmpty);
    expect(result.guides.items.first.title, isNotEmpty);
    expect(result.phrases.items, isNotEmpty);
    expect(result.phrases.items.first.japanese, isNotEmpty);
    expect(result.faqs.items, isNotEmpty);
    expect(result.faqs.items.first.question, isNotEmpty);
  }, skip: liveSkip);

  test('chữ Nhật một ký tự vẫn tìm; một chữ cái thì quá ngắn; ô trống không tìm gì', () async {
    final dao = SearchDao(liveGuest());
    final japanese = await dao.search('駅');
    expect(japanese.tooShort, isFalse);
    expectConsistent(japanese);

    final short = await dao.search('a');
    expect(short.tooShort, isTrue);
    expect(short.isEmpty, isTrue);

    final empty = await dao.search('');
    expect(empty.q, '');
    expect(empty.total, 0);
  }, skip: liveSkip);

  test('quá 100 ký tự: ApiException 400 với câu của server', () async {
    await expectLater(
      SearchDao(liveGuest()).search('x' * 101),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.message, 'message', 'Từ khóa tìm kiếm tối đa 100 ký tự.'),
      ),
    );
  }, skip: liveSkip);

  test('thành viên user@gmail.com tìm cũng đọc được kết quả', () async {
    final result = await SearchDao(await liveSignedIn('user@gmail.com')).search('Nippori');
    expectConsistent(result);
    expect(result.posts.items, isNotEmpty);
  }, skip: liveSkip);
}
