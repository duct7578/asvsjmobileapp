// Unit test của EventController: chạy với DAO giả, không cần server.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/event_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/event.dart';
import 'package:myasvsj/com.myasvsj.model/event_review_form.dart';

import 'event_fakes.dart';

void main() {
  late FakeEventDao dao;
  late EventController controller;

  setUp(() {
    dao = FakeEventDao();
    controller = EventController(dao);
  });

  group('danh sách', () {
    test('loadEvents bật rồi tắt trạng thái chờ và chia nhóm như web', () async {
      final future = controller.loadEvents(q: '');
      expect(controller.isLoading, isTrue);
      await future;
      expect(controller.isLoading, isFalse);
      expect(controller.error, isNull);
      expect(controller.nowEvents.map((e) => e.id), [2]);
      expect(controller.soonEvents.map((e) => e.id), [3]);
      expect(controller.laterEvents.map((e) => e.id), [5]);
      expect(controller.pastEvents.map((e) => e.id), [1]);
    });

    test('nhóm Đã diễn ra: sự kiện vừa kết thúc lên trước', () async {
      dao.events = [
        sampleEvent(7, state: Event.past),
        sampleEvent(8, state: Event.past),
        sampleEvent(9, daysUntil: 30),
        sampleEvent(10, daysUntil: 31),
      ];
      await controller.loadEvents();
      expect(controller.pastEvents.map((e) => e.id), [8, 7]);
      expect(controller.soonEvents.map((e) => e.id), [9]);
      expect(controller.laterEvents.map((e) => e.id), [10]);
    });

    test('loadEvents giữ từ khóa (bỏ khoảng trắng) cho lần tải lại', () async {
      await controller.loadEvents(q: '  obon ');
      expect(controller.query, 'obon');
      expect(controller.events.map((e) => e.id), [1]);
      await controller.loadEvents();
      expect(dao.queries.last, 'obon');
    });

    test('loadEvents giữ câu báo lỗi của server', () async {
      dao.failWith = const ApiException('Không kết nối được tới server.');
      await controller.loadEvents();
      expect(controller.error, 'Không kết nối được tới server.');
      expect(controller.isLoading, isFalse);
    });
  });

  group('chi tiết', () {
    test('loadEvent lưu theo id, hai sự kiện không đè nhau', () async {
      final future = controller.loadEvent(1);
      expect(controller.isLoadingDetail(1), isTrue);
      await future;
      await controller.loadEvent(2);
      expect(controller.isLoadingDetail(1), isFalse);
      expect(controller.detailOf(1)?.event.title, 'Lễ hội Obon');
      expect(controller.detailOf(2)?.event.title, 'Chợ phiên Yanaka Ginza');
    });

    test('loadEvent: sự kiện không còn → lỗi 404 hiện ở màn hình', () async {
      await controller.loadEvent(99);
      expect(controller.detailOf(99), isNull);
      expect(controller.detailErrorOf(99), 'Không tìm thấy sự kiện. Sự kiện có thể đã bị xóa.');
    });

    test('tải lại lỗi mạng mà đã có dữ liệu thì giữ dữ liệu và báo bằng message', () async {
      await controller.loadEvent(1);
      dao.failWith = const ApiException('Server phản hồi quá lâu. Hãy thử lại.');
      await controller.loadEvent(1);
      expect(controller.detailOf(1), isNotNull);
      expect(controller.detailErrorOf(1), isNull);
      expect(controller.takeMessage(), 'Server phản hồi quá lâu. Hãy thử lại.');
    });

    test('toggleLike cập nhật lạc quan ngay, rồi lấy số của server', () async {
      await controller.loadEvent(1);
      dao.likeGate = Completer<void>();
      final future = controller.toggleLike(1, 11);
      var review = controller.detailOf(1)!.reviews.single;
      expect(review.liked, isTrue);
      expect(review.likeCount, 8);
      expect(controller.isLiking(11), isTrue);

      // Bấm lần nữa khi đang chờ: không gửi thêm
      await controller.toggleLike(1, 11);
      dao.likeGate!.complete();
      await future;

      review = controller.detailOf(1)!.reviews.single;
      expect(review.liked, isTrue);
      expect(review.likeCount, 9);
      expect(controller.isLiking(11), isFalse);
      expect(dao.likes, [(reviewId: 11, on: true)]);
    });

    test('toggleLike lỗi thì hoàn tác và giữ câu của server', () async {
      await controller.loadEvent(2);
      dao.writeFailWith = const ApiException('Bạn không thể thích review của chính mình.', statusCode: 400);
      await controller.toggleLike(2, 10);
      final review = controller.detailOf(2)!.reviews.single;
      expect(review.liked, isFalse);
      expect(review.likeCount, 4);
      expect(controller.takeMessage(), 'Bạn không thể thích review của chính mình.');
    });

    test('reportReview gửi lý do và ghi chú, trả câu cảm ơn', () async {
      await controller.loadEvent(1);
      final ok = await controller.reportReview(1, 11, reasonId: 4, note: 'Spam');
      expect(ok, isTrue);
      expect(dao.reports.single, (reviewId: 11, reasonId: 4, note: 'Spam'));
      expect(controller.takeMessage(), 'Cảm ơn bạn. Báo cáo đã được gửi.');
    });

    test('reportReview lỗi (đã báo cáo rồi) trả false với câu của server', () async {
      dao.writeFailWith = const ApiException('Bạn đã báo cáo nội dung này rồi.', statusCode: 409);
      expect(await controller.reportReview(1, 11, reasonId: 1), isFalse);
      expect(controller.takeMessage(), 'Bạn đã báo cáo nội dung này rồi.');
    });

    test('deleteReview xóa rồi tải lại chi tiết và danh sách', () async {
      await controller.loadEvents();
      await controller.loadEvent(2);
      final listCalls = dao.queries.length;
      expect(await controller.deleteReview(2, 10), isTrue);
      expect(dao.deleted, [10]);
      expect(controller.detailOf(2)!.reviews, isEmpty);
      expect(dao.queries.length, listCalls + 1);
      expect(controller.takeMessage(), 'Đã xóa review. Điểm của review này được thu lại.');
    });
  });

  group('form review', () {
    test('openReviewForm lấy form; lỗi 400 của server nằm ở formError', () async {
      final future = controller.openReviewForm(1);
      expect(controller.isLoadingForm, isTrue);
      await future;
      expect(controller.form?.event.id, 1);

      dao.failWith = const ApiException('Viết review được khi sự kiện bắt đầu.', statusCode: 400);
      await controller.openReviewForm(3);
      expect(controller.form, isNull);
      expect(controller.formError, 'Viết review được khi sự kiện bắt đầu.');
    });

    test('validateReview dùng đúng câu chữ của server', () {
      expect(EventController.validateReview(rating: 0, content: '  '), {
        'rating': 'Hãy chọn số sao (1 đến 5).',
        'content': 'Hãy viết vài dòng về sự kiện.',
      });
      expect(
        EventController.validateReview(rating: 5, content: 'a' * 2001)['content'],
        'Nội dung tối đa 2.000 ký tự (hiện có 2001).',
      );
      expect(EventController.validateReview(rating: 3, content: 'ok', imageCount: 6)['images'], 'Tối đa 5 ảnh.');
      expect(EventController.validateReview(rating: 3, content: 'ok', imageCount: 5), isEmpty);
    });

    test('saveReview không gọi server khi nhập sai', () async {
      await controller.openReviewForm(1);
      final saved = await controller.saveReview(rating: 0, content: '');
      expect(saved, isFalse);
      expect(controller.fieldErrors.keys, containsAll(['rating', 'content']));
      expect(dao.created, isEmpty);
    });

    test('saveReview đăng review mới với ảnh, tải lại chi tiết, giữ câu của server', () async {
      await controller.openReviewForm(1);
      final future = controller.saveReview(rating: 4, content: '  Vui lắm  ', imagePaths: ['/tmp/a.jpg']);
      expect(controller.isSaving, isTrue);
      expect(await future, isTrue);
      expect(controller.isSaving, isFalse);
      final sent = dao.created.single;
      expect((sent.eventId, sent.rating, sent.content), (1, 4, 'Vui lắm'));
      expect(sent.images, ['/tmp/a.jpg']);
      expect(controller.detailOf(1), isNotNull);
      expect(controller.takeMessage(), contains('đang được quét'));
    });

    test('saveReview khi sửa: gửi PUT với ảnh giữ lại, đếm cả ảnh cũ vào giới hạn 5 ảnh', () async {
      dao.form = EventReviewForm(event: dao.events.first, review: ownReview());
      await controller.openReviewForm(1);
      final tooMany = await controller.saveReview(
        rating: 4,
        content: 'Sửa',
        keepMediaIds: [50],
        imagePaths: List.filled(5, '/tmp/a.jpg'),
      );
      expect(tooMany, isFalse);
      expect(controller.fieldErrors['images'], 'Tối đa 5 ảnh.');

      final saved = await controller.saveReview(rating: 5, content: 'Sửa', keepMediaIds: [50]);
      expect(saved, isTrue);
      final sent = dao.updated.single;
      expect((sent.reviewId, sent.rating, sent.content), (13, 5, 'Sửa'));
      expect(sent.keep, [50]);
      expect(sent.images, isEmpty);
      expect(dao.created, isEmpty);
      expect(controller.takeMessage(), 'Đã lưu thay đổi.');
    });

    test('saveReview: lỗi của server hiện chung và theo từng ô', () async {
      await controller.openReviewForm(1);
      dao.writeFailWith = const ApiException(
        'Nội dung chứa từ ngữ không phù hợp.',
        statusCode: 400,
        fields: {'content': 'Nội dung chứa từ ngữ không phù hợp.'},
      );
      expect(await controller.saveReview(rating: 3, content: 'abc'), isFalse);
      expect(controller.formError, 'Nội dung chứa từ ngữ không phù hợp.');
      expect(controller.fieldErrors['content'], 'Nội dung chứa từ ngữ không phù hợp.');
      expect(controller.isSaving, isFalse);
    });

    test('takeMessage chỉ trả câu một lần', () async {
      await controller.openReviewForm(1);
      await controller.saveReview(rating: 5, content: 'Hay');
      expect(controller.takeMessage(), 'Đã đăng review. +10 điểm.');
      expect(controller.takeMessage(), isNull);
    });
  });
}
