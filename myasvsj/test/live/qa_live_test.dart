// QuestionDao với server web thật: mọi hàm đọc, và một vòng ghi an toàn (đặt câu hỏi có ảnh → sửa → thích/bỏ thích,
// lưu/bỏ lưu → trả lời, phản hồi, chọn hay nhất, sửa câu trả lời → xóa hết). Dữ liệu thử được xóa ở cuối.
//
// Chạy: flutter test test/live/qa_live_test.dart --dart-define=LIVE_API=http://localhost:8080
//
// Không chạy báo cáo (report) thật: mỗi báo cáo mở một hồ sơ cho Moderator mà app không xóa được.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/answer.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/question.dart';
import 'package:myasvsj/com.myasvsj.model/question_dao.dart';

import 'live_api.dart';

/// Ảnh PNG 1×1 hợp lệ (server đọc JPG và PNG).
const _pixelPng = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

void main() {
  group('đọc (khách)', () {
    test('findAll, có và không có bộ lọc, đọc được thẻ câu hỏi', () async {
      final dao = QuestionDao(liveGuest());
      final page = await dao.findAll();
      expect(page.items, isNotEmpty);
      expect(page.totalItems, greaterThanOrEqualTo(page.items.length));
      final q = page.items.first;
      expect(q.id, isNotNull);
      expect(q.title, isNotEmpty);
      expect(q.author?.displayName, isNotEmpty);
      expect(q.topics, isNotEmpty);
      expect(q.createdAt, isNotNull);

      final filtered = await dao.findAll(
        q: q.title.split(' ').take(3).join(' '),
        topicIds: q.topicIds,
        status: 'ALL',
        sort: 'LIKES',
      );
      expect(filtered.items.map((e) => e.id), contains(q.id));

      for (final status in ['UNANSWERED', 'UNSOLVED', 'SOLVED']) {
        final byStatus = await dao.findAll(status: status, sort: 'ANSWERS');
        expect(byStatus.page, 0);
      }
    }, skip: liveSkip);

    test('findOverview đọc chủ đề và thống kê', () async {
      final overview = await QuestionDao(liveGuest()).findOverview();
      expect(overview.topics, isNotEmpty);
      expect(overview.topics.any((t) => t.name == 'Khác'), isTrue);
      expect(overview.total, greaterThan(0));
      expect(overview.topAnswerersDays, greaterThan(0));
    }, skip: liveSkip);

    test('findById của khách: không có quyền tương tác, có lý do báo cáo', () async {
      final dao = QuestionDao(liveGuest());
      final id = (await dao.findAll()).items.first.id!;
      final q = await dao.findById(id);
      expect(q.title, isNotEmpty);
      expect(q.signedIn, isFalse);
      expect(q.canInteract, isFalse);
      expect(q.reportReasons, isNotEmpty);
    }, skip: liveSkip);

    test('câu hỏi không có: 404 với câu tiếng Việt; khách mở form: 401', () async {
      final dao = QuestionDao(liveGuest());
      await expectLater(
        dao.findById(99999999),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
      await expectLater(
        dao.findCompose(),
        throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
      );
    }, skip: liveSkip);
  });

  test(
    'vòng ghi: đặt câu hỏi có ảnh, sửa, thích, lưu, trả lời, chọn hay nhất, rồi xóa',
    () async {
      final mentor = QuestionDao(await liveSignedIn('mentor@gmail.com'));
      final user = QuestionDao(await liveSignedIn('user@gmail.com'));

      final compose = await mentor.findCompose();
      expect(compose.topics, isNotEmpty);
      expect(compose.imagesMax, 5);
      final other = compose.topics.firstWhere((t) => t.name == 'Khác');

      final dir = Directory.systemTemp.createTempSync('qa_live');
      final photo = '${dir.path}${Platform.pathSeparator}pixel.png';
      File(photo).writeAsBytesSync(base64Decode(_pixelPng));

      int? questionId;
      try {
        // Đặt câu hỏi có ảnh
        final created = await mentor.create(
          Question(
            title: '[TEST app qa] Gia hạn visa du học cần giấy tờ gì?',
            content: 'Câu hỏi thử của test live, sẽ xóa ngay.',
            topicIds: [other.id],
          ),
          imagePaths: [photo],
        );
        questionId = created.id;
        expect(questionId, greaterThan(0));
        expect(created.message, isNotEmpty);

        // Ảnh được quét (ở máy dev luôn qua): chờ câu hỏi được đăng
        var mine = await mentor.findById(questionId);
        for (var i = 0; i < 30 && mine.status != 'PUBLISHED'; i++) {
          await Future<void>.delayed(const Duration(seconds: 1));
          mine = await mentor.findById(questionId);
        }
        expect(mine.status, 'PUBLISHED');
        expect(mine.isMine, isTrue);
        expect(mine.images, hasLength(1));

        // Sửa: giữ ảnh cũ, đổi câu hỏi
        final edit = await mentor.findForEdit(questionId);
        expect(edit.question.topicIds, [other.id]);
        expect(edit.question.media, hasLength(1));
        expect(edit.compose.topics, isNotEmpty);
        final updated = await mentor.update(
          Question(
            id: questionId,
            title: '[TEST app qa] Gia hạn visa du học cần những giấy tờ gì?',
            content: edit.question.content,
            topicIds: edit.question.topicIds,
            places: edit.question.places,
          ),
          keepMediaIds: [edit.question.media.single.id],
        );
        expect(updated.message, 'Đã lưu thay đổi.');
        mine = await mentor.findById(questionId);
        expect(mine.title, endsWith('cần những giấy tờ gì?'));
        expect(mine.edited, isTrue);
        expect(mine.images, hasLength(1));

        // Người khác thích rồi bỏ thích, lưu rồi bỏ lưu
        expect((await user.like(questionId)).active, isTrue);
        expect((await user.unlike(questionId)).active, isFalse);
        expect(await user.save(questionId), 'Đã lưu câu hỏi.');
        expect(await user.unsave(questionId), 'Đã bỏ lưu câu hỏi.');
        await expectLater(mentor.like(questionId), throwsA(isA<ApiException>()));

        // Trả lời, phản hồi, chọn câu trả lời hay nhất
        final answered = await user.answer(
          questionId,
          'Câu trả lời thử: cần hộ chiếu, thẻ cư trú, giấy xác nhận đang học.',
        );
        expect(answered.message, 'Đã đăng câu trả lời.');
        final answer = answered.question.answers.firstWhere((a) => a.isMine);
        expect(answer.parentId, isNull);

        expect((await mentor.likeAnswer(answer.id)).active, isTrue);
        expect((await mentor.unlikeAnswer(answer.id)).active, isFalse);

        final replied = await mentor.answer(
          questionId,
          'Cảm ơn bạn, có cần giấy tài chính không?',
          parentId: answer.id,
        );
        expect(replied.message, 'Đã gửi phản hồi.');
        final reply = Answer.find(replied.question.answers, answer.id)!.replies.single;
        expect(reply.parentId, answer.id);
        expect(reply.isMine, isTrue);

        final best = await mentor.chooseBest(questionId, answer.id);
        expect(best.question.bestAnswerId, answer.id);
        expect(best.question.answers.first.best, isTrue);

        final edited = await user.updateAnswer(answer.id, 'Câu trả lời thử (đã sửa): cần hộ chiếu và thẻ cư trú.');
        expect(Answer.find(edited.question.answers, answer.id)?.edited, isTrue);

        final solvedList = await user.findAll(status: 'SOLVED');
        expect(solvedList.items.map((q) => q.id), contains(questionId));

        // Dọn: xóa phản hồi, câu trả lời (điểm "hay nhất" được thu lại), rồi câu hỏi
        final noReply = await mentor.deleteAnswer(reply.id);
        expect(noReply.message, 'Đã xóa bình luận.');
        final noAnswer = await user.deleteAnswer(answer.id);
        expect(noAnswer.question?.answers ?? const [], isEmpty);
      } finally {
        if (questionId != null && questionId > 0) {
          expect(await mentor.delete(questionId), 'Đã xóa câu hỏi.');
          await expectLater(mentor.findById(questionId), throwsA(isA<ApiException>()));
        }
        dir.deleteSync(recursive: true);
      }
    },
    skip: liveSkip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
