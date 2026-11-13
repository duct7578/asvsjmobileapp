// SavedDao với server thật: đọc bằng user@gmail.com; lưu rồi bỏ lưu bằng kouhai@gmail.com (mục nào đã lưu từ
// trước thì lưu lại khi xong).
//
// Chạy: flutter test test/live/saved_live_test.dart --dart-define=LIVE_API=http://localhost:8080
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/saved_blog.dart';
import 'package:myasvsj/com.myasvsj.model/saved_dao.dart';
import 'package:myasvsj/com.myasvsj.model/saved_guide.dart';
import 'package:myasvsj/com.myasvsj.model/saved_kind.dart';
import 'package:myasvsj/com.myasvsj.model/saved_place.dart';

import 'live_api.dart';

/// Id của mục đầu tiên một danh sách công khai trả về (bài viết, câu hỏi: `{items}`; cẩm nang: danh sách).
Future<int> _firstId(ApiClient api, String path) async {
  final data = await api.get(path, query: {'size': 1});
  final items = data is Map<String, dynamic> ? data['items'] as List : data as List;
  return (items.first as Map<String, dynamic>)['id'] as int;
}

void main() {
  test('findAll (user@gmail.com)', () async {
    final saved = await SavedDao(await liveSignedIn('user@gmail.com')).findAll();
    expect(saved.total, greaterThanOrEqualTo(0));
    for (final kind in SavedKind.values) {
      for (final item in saved.itemsOf(kind)) {
        expect(item.kind, kind);
        expect(item.savedAt, isNotNull);
      }
    }
  }, skip: liveSkip);

  test('lưu rồi bỏ lưu mỗi loại một mục, đọc đủ trường (kouhai@gmail.com)', () async {
    final api = await liveSignedIn('kouhai@gmail.com');
    final dao = SavedDao(api);
    final targets = {
      SavedKind.place: 1, // Ga Nippori trong dữ liệu mẫu
      SavedKind.post: await _firstId(api, '/api/blogs'),
      SavedKind.question: await _firstId(api, '/api/questions'),
      SavedKind.guide: await _firstId(api, '/api/guides'),
    };
    final before = await dao.findAll();
    bool wasSaved(SavedKind kind, int id) => before.itemsOf(kind).any((x) => x.id == id);
    addTearDown(() async {
      for (final entry in targets.entries) {
        if (wasSaved(entry.key, entry.value)) {
          await dao.save(entry.key, entry.value);
        }
      }
    });

    for (final entry in targets.entries) {
      expect(await dao.save(entry.key, entry.value), startsWith('Đã lưu'));
    }
    final saved = await dao.findAll();
    for (final entry in targets.entries) {
      expect(saved.itemsOf(entry.key).map((x) => x.id), contains(entry.value), reason: entry.key.name);
    }
    final place = saved.itemsOf(SavedKind.place).firstWhere((x) => x.id == 1) as SavedPlace;
    expect(place.name, isNotEmpty);
    expect(place.categoryName, isNotEmpty);
    final post = saved.itemsOf(SavedKind.post).firstWhere((x) => x.id == targets[SavedKind.post]) as SavedBlog;
    expect(post.title, isNotEmpty);
    expect(post.authorName, isNotEmpty);
    expect(post.createdAt, isNotNull);
    final question =
        saved.itemsOf(SavedKind.question).firstWhere((x) => x.id == targets[SavedKind.question]) as SavedBlog;
    expect(question.isQuestion, isTrue);
    final guide = saved.itemsOf(SavedKind.guide).firstWhere((x) => x.id == targets[SavedKind.guide]) as SavedGuide;
    expect(guide.title, isNotEmpty);
    expect(guide.stageName, isNotEmpty);

    for (final entry in targets.entries) {
      expect(await dao.unsave(entry.key, entry.value), startsWith('Đã bỏ lưu'));
    }
    final after = await dao.findAll();
    for (final entry in targets.entries) {
      expect(after.itemsOf(entry.key).map((x) => x.id), isNot(contains(entry.value)), reason: entry.key.name);
    }
  }, skip: liveSkip);

  test('bỏ lưu bài không có thì nhận 404', () async {
    final dao = SavedDao(await liveSignedIn('kouhai@gmail.com'));
    await expectLater(
      dao.unsave(SavedKind.post, 999999),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
    );
  }, skip: liveSkip);

  test('khách đọc Đã lưu thì nhận 401', () async {
    await expectLater(
      SavedDao(liveGuest()).findAll(),
      throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
    );
  }, skip: liveSkip);
}
