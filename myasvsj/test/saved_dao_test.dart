// Test SavedDao với server giả. JSON mẫu chép từ server thật: kouhai@gmail.com lưu mỗi loại một mục rồi
// gọi GET /api/me/saved (sau đó đã bỏ lưu hết).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/saved_blog.dart';
import 'package:myasvsj/com.myasvsj.model/saved_dao.dart';
import 'package:myasvsj/com.myasvsj.model/saved_guide.dart';
import 'package:myasvsj/com.myasvsj.model/saved_kind.dart';
import 'package:myasvsj/com.myasvsj.model/saved_place.dart';

import 'fake_api.dart';

final savedJson =
    jsonDecode(r'''
{"places":[{"id":1,"name":"Ga Nippori","categoryId":"station","categoryName":"Ga tàu","icon":"train",
  "address":"Higashi-Nippori 6, Arakawa, Tokyo","closed":false,"savedAt":"2026-11-07T18:52:22Z"}],
 "posts":[{"id":1,"type":"POST","title":"Năm điều mình ước biết trước tuần đầu ở Tokyo",
  "author":{"id":6,"displayName":"Lan Anh","avatarUrl":null},
  "topics":[{"id":1,"name":"Kinh nghiệm"},{"id":3,"name":"Thủ tục giấy tờ"},{"id":8,"name":"Đi lại"}],
  "likeCount":24,"commentCount":0,"solved":false,"createdAt":"2026-10-20T18:36:45Z","savedAt":"2026-11-07T18:52:22Z"}],
 "questions":[{"id":6,"type":"QA","title":"Mua SIM data giá rẻ ở đâu gần Nippori ạ?",
  "author":{"id":2,"displayName":"Trần Minh","avatarUrl":null},
  "topics":[{"id":11,"name":"Mua sắm"},{"id":12,"name":"Ngân hàng và tiền"}],
  "likeCount":3,"commentCount":0,"solved":false,"createdAt":"2026-11-06T18:36:45Z","savedAt":"2026-11-07T18:52:22Z"}],
 "guides":[{"id":24,"title":"Cách phân loại và bỏ rác tại Nhật Bản – hướng dẫn chi tiết cho người Việt",
  "summary":"Phân loại và bỏ rác đúng quy định là một trong những điều quan trọng bậc nhất mà người Việt mới sang Nhật cần nắm vững. Không giống ở Việt Nam, tại Nhật Bản mỗ…",
  "stageName":"Khi mới đến (tuần đầu đến 3 tháng)","topicName":"Sinh hoạt","savedAt":"2026-11-07T18:52:21Z"}],
 "counts":{"places":1,"posts":1,"questions":1,"guides":1,"total":4}}
''')
        as Map<String, dynamic>;

void main() {
  test('findAll đọc đủ bốn loại và mọi trường của GET /api/me/saved', () async {
    final server = FakeServer({'GET /api/me/saved': (_) => apiOk(savedJson)});
    final saved = await SavedDao(server.api).findAll();

    expect(saved.total, 4);
    for (final kind in SavedKind.values) {
      expect(saved.countOf(kind), 1, reason: kind.name);
    }

    final place = saved.itemsOf(SavedKind.place).single as SavedPlace;
    expect(place.id, 1);
    expect(place.kind, SavedKind.place);
    expect(place.name, 'Ga Nippori');
    expect(place.categoryId, 'station');
    expect(place.categoryName, 'Ga tàu');
    expect(place.icon, 'train');
    expect(place.address, 'Higashi-Nippori 6, Arakawa, Tokyo');
    expect(place.closed, isFalse);
    expect(place.savedAt, DateTime.utc(2026, 11, 7, 18, 52, 22).toLocal());

    final post = saved.itemsOf(SavedKind.post).single as SavedBlog;
    expect(post.kind, SavedKind.post);
    expect(post.isQuestion, isFalse);
    expect(post.title, 'Năm điều mình ước biết trước tuần đầu ở Tokyo');
    expect(post.authorName, 'Lan Anh');
    expect(post.topics.map((t) => t.name), ['Kinh nghiệm', 'Thủ tục giấy tờ', 'Đi lại']);
    expect(post.likeCount, 24);
    expect(post.commentCount, 0);
    expect(post.createdAt, DateTime.utc(2026, 10, 20, 18, 36, 45).toLocal());

    final question = saved.itemsOf(SavedKind.question).single as SavedBlog;
    expect(question.kind, SavedKind.question);
    expect(question.isQuestion, isTrue);
    expect(question.solved, isFalse);
    expect(question.authorName, 'Trần Minh');

    final guide = saved.itemsOf(SavedKind.guide).single as SavedGuide;
    expect(guide.id, 24);
    expect(guide.kind, SavedKind.guide);
    expect(guide.summary, endsWith('…'));
    expect(guide.stageName, 'Khi mới đến (tuần đầu đến 3 tháng)');
    expect(guide.topicName, 'Sinh hoạt');
  });

  test('findAll khi chưa lưu gì (dữ liệu thật của user@gmail.com)', () async {
    final server = FakeServer({
      'GET /api/me/saved': (_) => apiOk({
        'places': [],
        'posts': [],
        'questions': [],
        'guides': [],
        'counts': {'places': 0, 'posts': 0, 'questions': 0, 'guides': 0, 'total': 0},
      }),
    });
    final saved = await SavedDao(server.api).findAll();
    expect(saved.isEmpty, isTrue);
  });

  test('findAll của khách ném ApiException 401', () async {
    final server = FakeServer({'GET /api/me/saved': (_) => const FakeReply(401, null)});
    await expectLater(
      SavedDao(server.api).findAll(),
      throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
    );
  });

  test('unsave gọi DELETE đúng API lưu của từng loại', () async {
    final server = FakeServer({
      'DELETE /api/map/places/1/save': (_) => apiOk({'saved': false}, message: 'Đã bỏ lưu địa điểm.'),
      'DELETE /api/blogs/1/save': (_) => apiOk({'saved': false}, message: 'Đã bỏ lưu bài viết.'),
      'DELETE /api/questions/6/save': (_) => apiOk({'saved': false}, message: 'Đã bỏ lưu câu hỏi.'),
      'DELETE /api/guides/24/save': (_) => apiOk({'saved': false}, message: 'Đã bỏ lưu cẩm nang.'),
    });
    final dao = SavedDao(server.api);
    expect(await dao.unsave(SavedKind.place, 1), 'Đã bỏ lưu địa điểm.');
    expect(await dao.unsave(SavedKind.post, 1), 'Đã bỏ lưu bài viết.');
    expect(await dao.unsave(SavedKind.question, 6), 'Đã bỏ lưu câu hỏi.');
    expect(await dao.unsave(SavedKind.guide, 24), 'Đã bỏ lưu cẩm nang.');
    expect(server.requests.map((r) => '${r.method} ${r.uri.path}'), [
      'DELETE /api/map/places/1/save',
      'DELETE /api/blogs/1/save',
      'DELETE /api/questions/6/save',
      'DELETE /api/guides/24/save',
    ]);
    expect(server.requests.every((r) => r.headers['X-XSRF-TOKEN'] == 'csrf-test'), isTrue);
  });

  test('save gọi POST đúng API lưu của từng loại', () async {
    final server = FakeServer({
      'POST /api/map/places/1/save': (_) => apiOk({'saved': true}, message: 'Đã lưu địa điểm.'),
      'POST /api/guides/24/save': (_) => apiOk({'saved': true}, message: 'Đã lưu cẩm nang.'),
    });
    final dao = SavedDao(server.api);
    expect(await dao.save(SavedKind.place, 1), 'Đã lưu địa điểm.');
    expect(await dao.save(SavedKind.guide, 24), 'Đã lưu cẩm nang.');
    expect(SavedDao.savePath(SavedKind.post, 3), '/api/blogs/3/save');
    expect(SavedDao.savePath(SavedKind.question, 3), '/api/questions/3/save');
  });

  test('bỏ lưu nội dung đã bị gỡ nhận câu báo lỗi 404 của server', () async {
    final server = FakeServer({
      'DELETE /api/blogs/99999/save': (_) =>
          apiError(404, 'Không tìm thấy nội dung bạn yêu cầu. Bài viết có thể đã bị gỡ hoặc đã bị xóa.'),
    });
    await expectLater(
      SavedDao(server.api).unsave(SavedKind.post, 99999),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.message, 'message', startsWith('Không tìm thấy nội dung')),
      ),
    );
  });
}
