// Test QuestionDao với server giả (FakeServer): DAO gọi đúng phương thức, đường dẫn, tham số, body, và đọc đúng JSON
// thật của web (test/qa_json.dart).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/question.dart';
import 'package:myasvsj/com.myasvsj.model/question_dao.dart';

import 'fake_api.dart';
import 'qa_json.dart';

/// FakeServer giữ thêm body đã mã hóa, để đọc được các phần của form multipart.
class _RecordingServer extends FakeServer {
  _RecordingServer(super.routes);

  final List<String> bodies = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) {
      final bytes = await requestStream.expand((chunk) => chunk).toList();
      bodies.add(utf8.decode(bytes, allowMalformed: true));
    }
    return super.fetch(options, null, cancelFuture);
  }
}

void main() {
  group('đọc', () {
    test('findAll gửi từ khóa, chủ đề, trạng thái, sắp xếp, trang và đọc thẻ câu hỏi', () async {
      final server = FakeServer({'GET /api/questions': (_) => apiOk(questionListJson())});
      final page = await QuestionDao(
        server.api,
      ).findAll(q: '  visa ', topicIds: [4, 14], status: 'UNANSWERED', sort: 'LIKES', page: 1);

      final query = server.last('GET', '/api/questions').uri.queryParameters;
      expect(query, {
        'q': 'visa',
        'topicIds': '4,14',
        'status': 'UNANSWERED',
        'sort': 'LIKES',
        'page': '1',
        'size': '10',
      });
      expect(page.totalItems, 2);
      expect(page.hasMore, isFalse);
      final first = page.items.first;
      expect(first.id, 8);
      expect(first.title, '[TEST QA agent] Hỏi thử về gia hạn visa du học cần giấy tờ gì');
      expect(first.content, 'Câu hỏi thử của agent qa, sẽ xóa ngay.');
      expect(first.unanswered, isTrue);
      expect(first.isSolved, isFalse);
      expect(first.author?.displayName, 'Lan Anh');
      expect(first.author?.tagNames, ['Mentor']);
      expect(first.topics.map((t) => t.name), ['Visa và cư trú', 'Khác']);
      expect(first.topicIds, [4, 14]);
      expect(first.createdAt, DateTime.utc(2026, 11, 7, 18, 52, 32).toLocal());
      expect(page.items.last.likeCount, 3);
    });

    test('findAll không gửi q và topicIds khi không lọc', () async {
      final server = FakeServer({'GET /api/questions': (_) => apiOk(questionListJson())});
      await QuestionDao(server.api).findAll();

      final query = server.last('GET', '/api/questions').uri.queryParameters;
      expect(query.containsKey('q'), isFalse);
      expect(query.containsKey('topicIds'), isFalse);
      expect(query['status'], 'ALL');
      expect(query['sort'], 'NEWEST');
      expect(query['page'], '0');
    });

    test('findOverview đọc thống kê, chủ đề, chủ đề hay hỏi và senpai giải đáp nhiều', () async {
      final server = FakeServer({'GET /api/questions/overview': (_) => apiOk(overviewJson())});
      final overview = await QuestionDao(server.api).findOverview();

      expect(overview.topics, hasLength(14));
      expect(overview.topics.last.name, 'Khác');
      expect([overview.total, overview.unanswered, overview.solved], [1, 1, 0]);
      expect(overview.popularTopics.first.topic.name, 'Mua sắm');
      expect(overview.popularTopics.first.count, 1);
      expect(overview.topAnswerers.single.author.displayName, 'Trần Minh');
      expect(overview.topAnswerers.single.answerCount, 4);
      expect(overview.topAnswerers.single.bestCount, 1);
      expect(overview.topAnswerersDays, 30);
    });

    test('findById đọc câu hỏi, ảnh, quyền người xem và cây câu trả lời', () async {
      final server = FakeServer({'GET /api/questions/8': (_) => apiOk(questionDetailJson())});
      final q = await QuestionDao(server.api).findById(8);

      expect(q.title, startsWith('[TEST QA agent]'));
      expect(q.content, 'Câu hỏi thử của agent qa, sẽ xóa ngay.');
      expect(q.author?.rankName, 'Senpai tin cậy');
      expect(q.images.single.url, '/media/blog/2026/11/e79d08d7-9029-4c43-94ea-b7a039e76bd0.jpg');
      expect(q.images.single.width, 772);
      expect(q.answerCount, 2);
      expect(q.bestAnswerId, 3);
      expect(q.isSolved, isTrue);
      expect([q.signedIn, q.isMine, q.canInteract, q.liked, q.saved], [true, true, true, false, false]);
      expect(q.reportReasons.map((r) => r.label), ['Lừa đảo', 'Sai sự thật', 'Xúc phạm', 'Spam']);

      final best = q.answers.single;
      expect(best.id, 3);
      expect(best.best, isTrue);
      expect(best.liked, isTrue);
      expect(best.likeCount, 1);
      expect(best.isMine, isFalse);
      expect(best.author?.displayName, 'Trần Minh');
      final reply = best.replies.single;
      expect(reply.id, 5);
      expect(reply.parentId, 3);
      expect(reply.isMine, isTrue);
      expect(reply.content, 'Cảm ơn bạn, mình hỏi thêm: có cần giấy xác nhận tài chính không?');
    });

    test('findById của khách: không có quyền, không câu trả lời', () async {
      final server = FakeServer({'GET /api/questions/6': (_) => apiOk(guestDetailJson())});
      final q = await QuestionDao(server.api).findById(6);

      expect(q.signedIn, isFalse);
      expect(q.canInteract, isFalse);
      expect(q.answers, isEmpty);
      expect(q.bestAnswerId, isNull);
      expect(q.isSolved, isFalse);
      expect(q.likeCount, 3);
    });

    test('findById ném ApiException mang câu của server khi không tìm thấy', () async {
      const msg = 'Không tìm thấy nội dung bạn yêu cầu. Bài viết có thể đã bị gỡ hoặc đã bị xóa.';
      final server = FakeServer({'GET /api/questions/99999': (_) => apiError(404, msg)});

      await expectLater(
        QuestionDao(server.api).findById(99999),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message', msg).having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('findCompose đọc chủ đề, giới hạn, hạn mức và quyền chèn link', () async {
      final server = FakeServer({'GET /api/questions/compose': (_) => apiOk(composeJson())});
      final compose = await QuestionDao(server.api).findCompose();

      expect(compose.topics, hasLength(14));
      expect(compose.titleMax, 150);
      expect(compose.contentMax, 5000);
      expect(compose.topicsMax, 3);
      expect(compose.imagesMax, 5);
      expect(compose.imageMaxMb, 20);
      expect(compose.contentRequired, isFalse);
      expect(compose.newAccount, isFalse);
      expect(compose.postsLimit, 3);
      expect(compose.canPostLinks, isTrue);
    });

    test('findCompose của khách nhận 401', () async {
      final server = FakeServer({'GET /api/questions/compose': (_) => apiError(401, 'Bạn cần đăng nhập để viết bài.')});

      await expectLater(
        QuestionDao(server.api).findCompose(),
        throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
      );
    });

    test('findForEdit đọc câu hỏi như đang lưu và lựa chọn của form', () async {
      final server = FakeServer({'GET /api/questions/8/edit': (_) => apiOk(editJson())});
      final data = await QuestionDao(server.api).findForEdit(8);

      expect(data.question.id, 8);
      expect(data.question.topicIds, [4, 14]);
      expect(data.question.media.single.id, 19);
      expect(data.question.status, 'PUBLISHED');
      expect(data.question.isMine, isTrue);
      expect(data.compose.topics.first.name, 'Kinh nghiệm');
    });
  });

  group('ghi câu hỏi', () {
    late Directory dir;
    late String photo;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('qa_dao_test');
      photo = '${dir.path}${Platform.pathSeparator}anh-visa.jpg';
      File(photo).writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xD9]);
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('create gửi multipart: phần JSON "question" và ảnh "images"', () async {
      final server = _RecordingServer({
        'POST /api/questions': (_) => apiOk({
          'id': 8,
          'type': 'QA',
          'status': 'PROCESSING',
        }, message: 'Đã gửi. Ảnh và video đang được quét, trong lúc này chỉ bạn thấy câu hỏi.'),
      });
      const question = Question(title: 'Gia hạn visa cần gì?', content: 'Mình ở Tokyo', topicIds: [4, 14]);
      final saved = await QuestionDao(server.api).create(question, imagePaths: [photo]);

      expect(saved.id, 8);
      expect(saved.status, 'PROCESSING');
      expect(saved.message, startsWith('Đã gửi.'));
      final form = server.last('POST', '/api/questions').data as FormData;
      expect(form.files.map((f) => f.key), ['question', 'images']);
      expect(form.files.first.value.contentType?.mimeType, 'application/json');
      expect(form.files.last.value.filename, 'anh-visa.jpg');
      expect(form.files.last.value.contentType?.mimeType, 'image/jpeg');
      final body = server.bodies.single;
      expect(body, contains('name="question"'));
      expect(
        body,
        contains(
          jsonEncode({
            'title': 'Gia hạn visa cần gì?',
            'content': 'Mình ở Tokyo',
            'topicIds': [4, 14],
            'placeIds': [],
            'externalPlaceIds': [],
          }),
        ),
      );
    });

    test('create không ảnh chỉ gửi phần "question"', () async {
      final server = FakeServer({
        'POST /api/questions': (_) =>
            apiOk({'id': 9, 'type': 'QA', 'status': 'PUBLISHED'}, message: 'Câu hỏi của bạn đã được đăng.'),
      });
      final saved = await QuestionDao(server.api).create(const Question(title: 'Hỏi', topicIds: [14]));

      expect(saved.message, 'Câu hỏi của bạn đã được đăng.');
      final form = server.last('POST', '/api/questions').data as FormData;
      expect(form.files.map((f) => f.key), ['question']);
    });

    test('update gửi PUT kèm keepMediaIds và ảnh mới', () async {
      final server = _RecordingServer({
        'PUT /api/questions/8': (_) =>
            apiOk({'id': 8, 'type': 'QA', 'status': 'PUBLISHED'}, message: 'Đã lưu thay đổi.'),
      });
      const question = Question(id: 8, title: 'Sửa', topicIds: [4], places: [(id: 3, name: 'Shinjuku')]);
      final saved = await QuestionDao(server.api).update(question, keepMediaIds: [19], imagePaths: [photo]);

      expect(saved.message, 'Đã lưu thay đổi.');
      final form = server.last('PUT', '/api/questions/8').data as FormData;
      expect(form.files.map((f) => f.key), ['question', 'images']);
      expect(server.bodies.single, contains('"placeIds":[3]'));
      expect(server.bodies.single, contains('"keepMediaIds":[19]'));
    });

    test('lỗi kiểm tra của server có lỗi theo từng ô', () async {
      final server = FakeServer({
        'POST /api/questions': (_) => apiError(
          400,
          'Hãy nhập câu hỏi.',
          fields: {
            'topicIds': 'Hãy chọn ít nhất 1 chủ đề. Không có chủ đề phù hợp thì chọn “Khác”.',
            'title': 'Hãy nhập câu hỏi.',
          },
        ),
      });

      await expectLater(
        QuestionDao(server.api).create(const Question(title: '')),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Hãy nhập câu hỏi.')
              .having((e) => e.fields['title'], 'fields.title', 'Hãy nhập câu hỏi.'),
        ),
      );
    });

    test('delete, like, unlike, save, unsave, report gọi đúng API', () async {
      final server = FakeServer({
        'DELETE /api/questions/8': (_) => apiOk(null, message: 'Đã xóa câu hỏi.'),
        'POST /api/questions/8/like': (_) => apiOk({'active': true, 'count': 1}),
        'DELETE /api/questions/8/like': (_) => apiOk({'active': false, 'count': 0}),
        'POST /api/questions/8/save': (_) => apiOk({'saved': true}, message: 'Đã lưu câu hỏi.'),
        'DELETE /api/questions/8/save': (_) => apiOk({'saved': false}, message: 'Đã bỏ lưu câu hỏi.'),
        'POST /api/questions/8/report': (_) => apiOk(null, message: 'Cảm ơn bạn. Báo cáo đã được gửi.'),
      });
      final dao = QuestionDao(server.api);

      expect(await dao.delete(8), 'Đã xóa câu hỏi.');
      expect(await dao.like(8), (active: true, count: 1));
      expect(await dao.unlike(8), (active: false, count: 0));
      expect(await dao.save(8), 'Đã lưu câu hỏi.');
      expect(await dao.unsave(8), 'Đã bỏ lưu câu hỏi.');
      expect(await dao.report(8, 4, 'Quảng cáo'), 'Cảm ơn bạn. Báo cáo đã được gửi.');
      expect(server.last('POST', '/api/questions/8/report').data, {'reasonId': 4, 'note': 'Quảng cáo'});
      expect(server.requests.every((r) => r.headers['X-XSRF-TOKEN'] == 'csrf-test'), isTrue);
    });

    test('thích câu hỏi của chính mình: server từ chối bằng câu tiếng Việt', () async {
      final server = FakeServer({
        'POST /api/questions/8/like': (_) => apiError(400, 'Bạn không thể thích bài viết của chính mình.'),
      });

      await expectLater(
        QuestionDao(server.api).like(8),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message', 'Bạn không thể thích bài viết của chính mình.'),
        ),
      );
    });
  });

  group('câu trả lời', () {
    test('answer gửi nội dung (và parentId khi phản hồi), trả về câu hỏi mới', () async {
      final server = FakeServer({
        'POST /api/questions/8/answers': (req) => apiOk(
          questionDetailJson(),
          message: (req.data as Map)['parentId'] == null ? 'Đã đăng câu trả lời.' : 'Đã gửi phản hồi.',
        ),
      });
      final dao = QuestionDao(server.api);

      final answered = await dao.answer(8, 'Cần hộ chiếu');
      expect(server.last('POST', '/api/questions/8/answers').data, {'content': 'Cần hộ chiếu'});
      expect(answered.message, 'Đã đăng câu trả lời.');
      expect(answered.question.answers.single.id, 3);

      final replied = await dao.answer(8, 'Cảm ơn bạn', parentId: 3);
      expect(server.last('POST', '/api/questions/8/answers').data, {'content': 'Cảm ơn bạn', 'parentId': 3});
      expect(replied.message, 'Đã gửi phản hồi.');
    });

    test('answer quá nhanh: 429 với câu báo chờ của server', () async {
      const msg = 'Bạn bình luận hơi nhanh. Vui lòng đợi 7 giây rồi thử lại.';
      final server = FakeServer({'POST /api/questions/8/answers': (_) => apiError(429, msg)});

      await expectLater(
        QuestionDao(server.api).answer(8, 'Lần hai'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 429).having((e) => e.message, 'm', msg)),
      );
    });

    test('chooseBest gửi PUT {answerId}', () async {
      final server = FakeServer({
        'PUT /api/questions/8/best-answer': (_) =>
            apiOk(questionDetailJson(), message: 'Đã chọn câu trả lời hay nhất.'),
      });
      final result = await QuestionDao(server.api).chooseBest(8, 3);

      expect(server.last('PUT', '/api/questions/8/best-answer').data, {'answerId': 3});
      expect(result.message, 'Đã chọn câu trả lời hay nhất.');
      expect(result.question.bestAnswerId, 3);
    });

    test('thích, báo cáo, sửa, xóa câu trả lời qua /api/comments/{id}', () async {
      final server = FakeServer({
        'POST /api/comments/3/like': (_) => apiOk({'active': true, 'count': 2}),
        'DELETE /api/comments/3/like': (_) => apiOk({'active': false, 'count': 1}),
        'POST /api/comments/3/report': (_) => apiOk(questionDetailJson(), message: 'Cảm ơn bạn. Báo cáo đã được gửi.'),
        'PUT /api/comments/3': (_) => apiOk(questionDetailJson(), message: 'Đã lưu bình luận.'),
        'DELETE /api/comments/5': (_) => apiOk(questionDetailJson(), message: 'Đã xóa bình luận.'),
        'DELETE /api/comments/6': (_) => apiOk(null, message: 'Đã xóa bình luận.'),
      });
      final dao = QuestionDao(server.api);

      expect(await dao.likeAnswer(3), (active: true, count: 2));
      expect(await dao.unlikeAnswer(3), (active: false, count: 1));

      final reported = await dao.reportAnswer(3, 2, '');
      expect(server.last('POST', '/api/comments/3/report').data, {'reasonId': 2, 'note': ''});
      expect(reported.message, 'Cảm ơn bạn. Báo cáo đã được gửi.');

      final edited = await dao.updateAnswer(3, 'Đã sửa');
      expect(server.last('PUT', '/api/comments/3').data, {'content': 'Đã sửa'});
      expect(edited.message, 'Đã lưu bình luận.');

      final deleted = await dao.deleteAnswer(5);
      expect(deleted.message, 'Đã xóa bình luận.');
      expect(deleted.question?.id, 8);

      // Câu hỏi không còn hiện được cho người xem: server trả data null, việc xóa vẫn thành công
      final gone = await dao.deleteAnswer(6);
      expect(gone.question, isNull);
    });

    test('nội dung trống: server trả câu báo lỗi', () async {
      final server = FakeServer({
        'POST /api/questions/6/answers': (_) => apiError(400, 'Hãy viết nội dung bình luận.'),
      });

      await expectLater(
        QuestionDao(server.api).answer(6, '  '),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Hãy viết nội dung bình luận.')),
      );
    });
  });

  test('Question.toJson khi sửa có keepMediaIds, khi tạo thì không', () {
    const created = Question(title: 'A', content: 'B', topicIds: [1]);
    expect(created.toJson(), {
      'title': 'A',
      'content': 'B',
      'topicIds': [1],
      'placeIds': [],
      'externalPlaceIds': [],
    });
    const edited = Question(id: 3, title: 'A', topicIds: [1], places: [(id: 7, name: 'Ga')]);
    expect(edited.toJson(keepMediaIds: [19, 20])['keepMediaIds'], [19, 20]);
    expect(edited.toJson()['placeIds'], [7]);
  });
}
