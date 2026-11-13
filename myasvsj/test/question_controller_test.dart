// Unit test của QuestionController: chạy với DAO giả, không cần server.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/question_controller.dart';
import 'package:myasvsj/com.myasvsj.model/answer.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/question_compose.dart';

import 'question_fakes.dart';

void main() {
  late FakeQuestionDao dao;
  late QuestionController controller;

  setUp(() {
    dao = FakeQuestionDao();
    controller = QuestionController(dao);
  });

  group('danh sách', () {
    test('loadQuestions bật trạng thái chờ, lấy trang đầu rồi tắt chờ', () async {
      final future = controller.loadQuestions();
      expect(controller.isLoading, isTrue);
      await future;
      expect(controller.isLoading, isFalse);
      expect(controller.hasLoaded, isTrue);
      expect(controller.questions.map((q) => q.id), [1, 2, 3]);
      expect(controller.totalItems, 3);
      expect(controller.hasMore, isFalse);
      expect(controller.error, isNull);
    });

    test('loadQuestions giữ câu báo lỗi của server', () async {
      dao.failWith = const ApiException('Không kết nối được tới server.');
      await controller.loadQuestions();
      expect(controller.error, 'Không kết nối được tới server.');
      expect(controller.questions, isEmpty);
      expect(controller.isLoading, isFalse);
    });

    test('tìm, lọc trạng thái, chủ đề, sắp xếp được gửi cho DAO; Xóa bộ lọc trả về như cũ', () async {
      await controller.search('  SIM ');
      expect(dao.lastQuery['q'], 'SIM');
      expect(controller.questions.single.id, 1);
      expect(controller.isFiltered, isTrue);

      await controller.setStatus('UNANSWERED');
      await controller.setSort('LIKES');
      await controller.toggleTopic(14);
      await controller.toggleTopic(4);
      expect(dao.lastQuery, {
        'q': 'SIM',
        'topicIds': [4, 14],
        'status': 'UNANSWERED',
        'sort': 'LIKES',
        'page': 0,
      });

      await controller.toggleTopic(14);
      expect(controller.topicIds, {4});

      await controller.showTopic(11);
      expect(controller.topicIds, {11});

      await controller.clearFilters();
      expect(controller.isFiltered, isFalse);
      expect(dao.lastQuery['q'], '');
      expect(dao.lastQuery['status'], 'ALL');
      expect(controller.sort, 'LIKES');
      expect(controller.questions, hasLength(3));
    });

    test('câu trả lời của lần tìm cũ đến muộn bị bỏ qua', () async {
      dao.slowQuery = 'SIM';
      dao.slowGate = Completer<void>();
      final old = controller.search('SIM');
      await controller.search('visa');
      expect(controller.questions.single.id, 2);

      dao.slowGate!.complete();
      await old;
      expect(controller.questions.single.id, 2);
      expect(controller.query, 'visa');
    });

    test('loadMore nối trang sau, hết trang thì không gọi nữa', () async {
      dao = FakeQuestionDao(perPage: 2);
      controller = QuestionController(dao);
      await controller.loadQuestions();
      expect(controller.questions, hasLength(2));
      expect(controller.hasMore, isTrue);

      final more = controller.loadMore();
      expect(controller.isLoadingMore, isTrue);
      await more;
      expect(controller.questions.map((q) => q.id), [1, 2, 3]);
      expect(dao.lastQuery['page'], 1);
      expect(controller.hasMore, isFalse);

      final calls = dao.calls.length;
      await controller.loadMore();
      expect(dao.calls.length, calls);
    });

    test('loadMore lỗi thì giữ danh sách và báo bằng message', () async {
      dao = FakeQuestionDao(perPage: 2);
      controller = QuestionController(dao);
      await controller.loadQuestions();
      dao.failWith = const ApiException('Mất mạng.');
      await controller.loadMore();
      expect(controller.questions, hasLength(2));
      expect(controller.takeMessage(), 'Mất mạng.');
      expect(controller.isLoadingMore, isFalse);
    });

    test('loadOverview lấy thống kê; lỗi chỉ ghi overviewError', () async {
      await controller.loadOverview();
      expect(controller.overview?.total, 3);
      expect(controller.overview?.topics.map((t) => t.name), contains('Khác'));

      dao.failWith = const ApiException('Server gặp lỗi (500). Hãy thử lại sau.');
      await controller.loadOverview();
      expect(controller.overviewError, 'Server gặp lỗi (500). Hãy thử lại sau.');
    });
  });

  group('chi tiết', () {
    test('loadQuestion giữ chi tiết theo id; nhiều câu cùng lúc không lẫn nhau', () async {
      final future = controller.loadQuestion(1);
      expect(controller.isLoadingQuestion(1), isTrue);
      await future;
      await controller.loadQuestion(2);
      expect(controller.isLoadingQuestion(1), isFalse);
      expect(controller.questionOf(1)?.title, 'Mua SIM data giá rẻ ở đâu gần Nippori ạ?');
      expect(controller.questionOf(2)?.isMine, isTrue);
      expect(controller.questionOf(1)?.answers.first.replies.single.isMine, isTrue);
    });

    test('loadQuestion không tìm thấy: giữ câu báo của server theo id', () async {
      await controller.loadQuestion(99);
      expect(controller.questionOf(99), isNull);
      expect(controller.questionError(99), startsWith('Không tìm thấy nội dung'));
    });

    test('toggleLike cập nhật ngay, rồi lấy số của server; thẻ danh sách cũng đổi', () async {
      await controller.loadQuestions();
      await controller.loadQuestion(1);
      final future = controller.toggleLike(1);
      expect(controller.questionOf(1)?.liked, isTrue);
      expect(controller.questionOf(1)?.likeCount, 4);
      await future;
      expect(dao.calls.last, 'like');
      expect(controller.questionOf(1)?.likeCount, 4);
      expect(controller.questions.first.likeCount, 4);

      await controller.toggleLike(1);
      expect(dao.calls.last, 'unlike');
      expect(controller.questionOf(1)?.liked, isFalse);
      expect(controller.questionOf(1)?.likeCount, 3);
    });

    test('toggleLike lỗi thì trả lại như cũ và giữ câu báo lỗi', () async {
      await controller.loadQuestion(1);
      dao.failOn['like'] = const ApiException('Bạn không thể thích bài viết của chính mình.');
      await controller.toggleLike(1);
      expect(controller.questionOf(1)?.liked, isFalse);
      expect(controller.questionOf(1)?.likeCount, 3);
      expect(controller.takeMessage(), 'Bạn không thể thích bài viết của chính mình.');
    });

    test('toggleSave giữ câu của server; lỗi thì trả lại', () async {
      await controller.loadQuestion(1);
      await controller.toggleSave(1);
      expect(controller.questionOf(1)?.saved, isTrue);
      expect(controller.takeMessage(), 'Đã lưu câu hỏi.');

      dao.failOn['unsave'] = const ApiException('Bạn cần đăng nhập để làm việc này.', statusCode: 401);
      final future = controller.toggleSave(1);
      expect(controller.questionOf(1)?.saved, isFalse);
      await future;
      expect(controller.questionOf(1)?.saved, isTrue);
      expect(controller.takeMessage(), 'Bạn cần đăng nhập để làm việc này.');
    });

    test('reportQuestion gửi lý do và ghi chú đã cắt khoảng trắng', () async {
      expect(await controller.reportQuestion(1, 4, '  quảng cáo  '), isTrue);
      expect(dao.reports.single, (id: 1, reasonId: 4, note: 'quảng cáo'));
      expect(controller.takeMessage(), 'Cảm ơn bạn. Báo cáo đã được gửi.');

      dao.failWith = const ApiException('Bạn đã báo cáo nội dung này rồi.');
      expect(await controller.reportQuestion(1, 4, ''), isFalse);
      expect(controller.takeMessage(), 'Bạn đã báo cáo nội dung này rồi.');
    });

    test('deleteQuestion bỏ câu khỏi danh sách và chi tiết', () async {
      await controller.loadQuestions();
      await controller.loadQuestion(2);
      expect(await controller.deleteQuestion(2), isTrue);
      expect(controller.questions.map((q) => q.id), [1, 3]);
      expect(controller.totalItems, 2);
      expect(controller.questionOf(2), isNull);
      expect(controller.takeMessage(), 'Đã xóa câu hỏi.');
      expect(controller.takeMessage(), isNull);
    });
  });

  group('câu trả lời', () {
    setUp(() => controller.loadQuestion(1));

    test('sendAnswer không gọi server khi nội dung trống hoặc quá 2.000 ký tự', () async {
      expect(await controller.sendAnswer(1, '   '), isFalse);
      expect(controller.answerErrorFor(null), 'Hãy viết nội dung câu trả lời.');
      expect(await controller.sendAnswer(1, 'a' * 2001, parentId: 11), isFalse);
      expect(controller.answerErrorFor(11), 'Câu trả lời tối đa 2.000 ký tự.');
      expect(dao.calls, isNot(contains('answer')));

      controller.clearAnswerError(null);
      expect(controller.answerErrorFor(null), isNull);
    });

    test('sendAnswer đăng câu trả lời, phản hồi lồng vào đúng câu cha', () async {
      await controller.loadQuestions();
      final future = controller.sendAnswer(1, '  Mua ở Yodobashi cũng được.  ');
      expect(controller.isSendingAnswer, isTrue);
      expect(await future, isTrue);
      expect(controller.isSendingAnswer, isFalse);
      final q = controller.questionOf(1)!;
      expect(q.answers.last.content, 'Mua ở Yodobashi cũng được.');
      expect(q.answerCount, 3);
      expect(controller.questions.first.answerCount, 3);
      expect(controller.takeMessage(), 'Đã đăng câu trả lời.');

      expect(await controller.sendAnswer(1, 'Cảm ơn', parentId: 11), isTrue);
      final parent = Answer.find(controller.questionOf(1)!.answers, 11)!;
      expect(parent.replies.last.content, 'Cảm ơn');
      expect(controller.takeMessage(), 'Đã gửi phản hồi.');
    });

    test('sendAnswer quá nhanh: câu báo chờ của server hiện dưới ô trả lời', () async {
      dao.failOn['answer'] = const ApiException(
        'Bạn bình luận hơi nhanh. Vui lòng đợi 7 giây rồi thử lại.',
        statusCode: 429,
      );
      expect(await controller.sendAnswer(1, 'Lần hai', parentId: 11), isFalse);
      expect(controller.answerErrorFor(11), 'Bạn bình luận hơi nhanh. Vui lòng đợi 7 giây rồi thử lại.');
      expect(controller.answerErrorFor(null), isNull);
      expect(controller.isSendingAnswer, isFalse);
    });

    test('updateAnswer: không đổi gì thì không gọi server; đổi thì lưu', () async {
      expect(await controller.updateAnswer(1, 12, 'Cảm ơn chị!'), isTrue);
      expect(dao.calls, isNot(contains('updateAnswer')));

      expect(await controller.updateAnswer(1, 12, 'Cảm ơn chị nhiều!'), isTrue);
      expect(Answer.find(controller.questionOf(1)!.answers, 12)?.content, 'Cảm ơn chị nhiều!');
      expect(Answer.find(controller.questionOf(1)!.answers, 12)?.edited, isTrue);
      expect(controller.takeMessage(), 'Đã lưu bình luận.');

      expect(await controller.updateAnswer(1, 12, ' '), isFalse);
      expect(controller.answerErrors[12], 'Hãy viết nội dung câu trả lời.');
    });

    test('toggleAnswerLike cập nhật lạc quan và hoàn tác khi lỗi', () async {
      final future = controller.toggleAnswerLike(1, 11);
      final optimistic = Answer.find(controller.questionOf(1)!.answers, 11)!;
      expect(optimistic.liked, isTrue);
      expect(optimistic.likeCount, 3);
      await future;
      expect(Answer.find(controller.questionOf(1)!.answers, 11)?.likeCount, 3);

      dao.failOn['unlikeAnswer'] = const ApiException('Mất mạng.');
      await controller.toggleAnswerLike(1, 11);
      final reverted = Answer.find(controller.questionOf(1)!.answers, 11)!;
      expect(reverted.liked, isTrue);
      expect(reverted.likeCount, 3);
      expect(controller.takeMessage(), 'Mất mạng.');
    });

    test('chooseBest: câu được chọn nổi lên đầu, báo +5 điểm', () async {
      await controller.loadQuestion(2);
      expect(await controller.chooseBest(2, 21), isTrue);
      final q = controller.questionOf(2)!;
      expect(q.bestAnswerId, 21);
      expect(q.isSolved, isTrue);
      expect(q.answers.first.best, isTrue);
      expect(controller.takeMessage(), 'Đã chọn câu trả lời hay nhất. Người trả lời được +5 điểm.');
    });

    test('chooseBest lỗi giữ câu của server', () async {
      dao.failWith = const ApiException('Bạn không thể chọn câu trả lời của chính mình.');
      expect(await controller.chooseBest(1, 12), isFalse);
      expect(controller.takeMessage(), 'Bạn không thể chọn câu trả lời của chính mình.');
    });

    test('reportAnswer gửi báo cáo câu trả lời', () async {
      expect(await controller.reportAnswer(1, 11, 1, 'lừa'), isTrue);
      expect(dao.reports.single, (id: 11, reasonId: 1, note: 'lừa'));
      expect(controller.takeMessage(), 'Cảm ơn bạn. Báo cáo đã được gửi.');
    });

    test('deleteAnswer bỏ câu khỏi cây; server không trả câu hỏi thì tải lại', () async {
      expect(await controller.deleteAnswer(1, 12), isTrue);
      expect(Answer.find(controller.questionOf(1)!.answers, 12), isNull);
      expect(controller.takeMessage(), 'Đã xóa bình luận.');

      dao.deleteReturnsNoQuestion = true;
      final before = dao.calls.where((c) => c == 'findById').length;
      expect(await controller.deleteAnswer(1, 11), isTrue);
      expect(dao.calls.where((c) => c == 'findById').length, before + 1);
      expect(controller.questionOf(1)?.answers, isEmpty);
    });
  });

  group('form đặt / sửa câu hỏi', () {
    test('openForm khi đặt mới chỉ lấy chủ đề và luật', () async {
      final future = controller.openForm();
      expect(controller.isLoadingForm, isTrue);
      await future;
      expect(controller.compose?.topics, hasLength(3));
      expect(controller.editing, isNull);
      expect(dao.calls, ['findCompose']);
    });

    test('openForm khi sửa lấy câu hỏi như đang lưu', () async {
      await controller.openForm(questionId: 2);
      expect(controller.editing?.title, 'Gia hạn visa du học cần giấy tờ gì?');
      expect(controller.editing?.places.single.name, 'Ga Shinjuku');
      expect(controller.compose, isNotNull);
    });

    test('openForm của khách: giữ câu báo lỗi', () async {
      dao.failWith = const ApiException('Bạn cần đăng nhập để viết bài.', statusCode: 401);
      await controller.openForm();
      expect(controller.compose, isNull);
      expect(controller.formError, 'Bạn cần đăng nhập để viết bài.');
    });

    test('saveQuestion không gọi server khi thiếu câu hỏi và chủ đề', () async {
      await controller.openForm();
      final saved = await controller.saveQuestion(title: '   ', content: '', topicIds: []);
      expect(saved, isFalse);
      expect(controller.fieldErrors.keys, ['title', 'topicIds']);
      expect(controller.formError, 'Hãy nhập câu hỏi.');
      expect(dao.saved, isEmpty);
    });

    test('validate theo luật của server', () {
      final errors = QuestionController.validate(
        title: 'a' * 151,
        content: 'b' * 5001,
        topicIds: [1, 2, 3, 4],
        imageCount: 6,
      );
      expect(errors, {
        'title': 'Câu hỏi tối đa 150 ký tự.',
        'topicIds': 'Chọn tối đa 3 chủ đề.',
        'content': 'Mô tả chi tiết tối đa 5.000 ký tự.',
        'images': 'Tối đa 5 ảnh, định dạng JPG, PNG hoặc HEIC, mỗi ảnh không quá 20 MB.',
      });
      expect(QuestionController.validate(title: 'Hỏi', content: '', topicIds: [14]), isEmpty);
      expect(
        QuestionController.validate(
          title: 'Hỏi',
          content: ' ',
          topicIds: [14],
          rules: const QuestionCompose(contentRequired: true),
        ),
        {'content': 'Hãy nhập mô tả chi tiết.'},
      );
    });

    test('saveQuestion đặt câu mới: gửi câu đã làm gọn và ảnh, giữ id để mở chi tiết', () async {
      await controller.openForm();
      final saved = await controller.saveQuestion(
        title: '  Gia hạn   visa\n cần gì? ',
        content: ' Mình ở Tokyo ',
        topicIds: [4],
        imagePaths: ['/tmp/a.jpg'],
      );
      expect(saved, isTrue);
      final sent = dao.saved.single;
      expect(sent.question.title, 'Gia hạn visa cần gì?');
      expect(sent.question.content, 'Mình ở Tokyo');
      expect(sent.question.id, isNull);
      expect(sent.imagePaths, ['/tmp/a.jpg']);
      expect(controller.lastSavedId, 100);
      expect(controller.takeMessage(), startsWith('Đã gửi. Ảnh và video đang được quét'));
      expect(controller.isSaving, isFalse);
    });

    test('saveQuestion khi sửa giữ địa điểm, ảnh còn giữ và video đã gắn', () async {
      await controller.loadQuestion(2);
      await controller.openForm(questionId: 2);
      final saved = await controller.saveQuestion(
        title: 'Gia hạn visa du học cần những giấy tờ gì?',
        content: '',
        topicIds: [4],
        keepImageIds: [],
        imagePaths: ['/tmp/b.jpg'],
      );
      expect(saved, isTrue);
      final sent = dao.saved.single;
      expect(sent.question.id, 2);
      expect(sent.question.places.single.id, 3);
      expect(sent.keepMediaIds, [20]);
      expect(sent.imagePaths, ['/tmp/b.jpg']);
      expect(controller.takeMessage(), 'Đã lưu thay đổi.');
      // Chi tiết đang mở được tải lại sau khi lưu
      expect(dao.calls.where((c) => c == 'findById').length, 2);
    });

    test('saveQuestion hiện lỗi theo từng ô mà server trả về', () async {
      await controller.openForm();
      dao.failWith = const ApiException(
        'Nội dung chứa từ ngữ không phù hợp.',
        statusCode: 400,
        fields: {'title': 'Nội dung chứa từ ngữ không phù hợp.'},
      );
      final saved = await controller.saveQuestion(title: 'Vay nóng', content: '', topicIds: [14]);
      expect(saved, isFalse);
      expect(controller.formError, 'Nội dung chứa từ ngữ không phù hợp.');
      expect(controller.fieldErrors['title'], 'Nội dung chứa từ ngữ không phù hợp.');
      expect(controller.isSaving, isFalse);
    });
  });
}
