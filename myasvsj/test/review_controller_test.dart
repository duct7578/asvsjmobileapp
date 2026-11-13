// Unit test của ReviewController: mở form, kiểm tra nhập, viết / sửa / xóa review với DAO giả.
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/review_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/review.dart';
import 'package:myasvsj/com.myasvsj.model/review_compose.dart';

import 'place_fakes.dart';
import 'place_samples.dart';

void main() {
  late FakeReviewDao dao;
  late ReviewController controller;

  setUp(() {
    dao = FakeReviewDao();
    controller = ReviewController(dao);
  });

  test('openForm viết mới: lấy giới hạn và lượt đăng, chưa có review đang sửa', () async {
    final future = controller.openForm(placeId: 1);
    expect(controller.isLoadingForm, isTrue);
    await future;
    expect(controller.isLoadingForm, isFalse);
    expect(dao.composeAsked, [1]);
    expect(controller.compose?.contentMin, 10);
    expect(controller.compose?.newAccount, isTrue);
    expect(controller.editing, isNull);
    expect(controller.formError, isNull);
  });

  test('openForm cho nơi đã review thì chuyển sang sửa review đó', () async {
    dao.compose = ReviewCompose.fromJson({...sampleCompose, 'myReviewId': 12});
    await controller.openForm(placeId: 11);
    expect(controller.editing?.id, 12);
    expect(controller.editing?.content, 'Review thử của agent map, sẽ xóa ngay.');
    expect(controller.compose?.newAccount, isFalse);
  });

  test('openForm sửa theo reviewId không hỏi compose', () async {
    await controller.openForm(reviewId: 12);
    expect(dao.composeAsked, isEmpty);
    expect(controller.editing?.placeName, 'Tiệm giặt Coin Laundry Sora');
  });

  test('openForm của khách giữ câu báo lỗi và không có form', () async {
    dao.failWith = const ApiException('Bạn cần đăng nhập để viết review.', statusCode: 401);
    await controller.openForm(placeId: 1);
    expect(controller.compose, isNull);
    expect(controller.formError, 'Bạn cần đăng nhập để viết review.');
  });

  test('validate giống luật server: số sao, độ dài nội dung, số ảnh', () {
    expect(ReviewController.validate(rating: 0, content: 'ngắn'), {
      'rating': 'Hãy chọn số sao.',
      'content': 'Nội dung cần ít nhất 10 ký tự.',
    });
    expect(ReviewController.validate(rating: 6, content: 'x' * 10).keys, ['rating']);
    expect(ReviewController.validate(rating: 5, content: 'x' * 2001), {'content': 'Nội dung tối đa 2.000 ký tự.'});
    expect(ReviewController.validate(rating: 5, content: '  ${'x' * 9}  ').keys, ['content']);
    expect(ReviewController.validate(rating: 1, content: 'x' * 10, imageCount: 6), {'images': 'Tối đa 5 ảnh.'});
    expect(ReviewController.validate(rating: 5, content: 'Nhân viên thân thiện.', imageCount: 5), isEmpty);
  });

  test('saveReview không gọi server khi nhập sai', () async {
    await controller.openForm(placeId: 1);
    final saved = await controller.saveReview(placeId: 1, rating: 0, content: 'ngắn');
    expect(saved, isFalse);
    expect(controller.fieldErrors.keys, containsAll(['rating', 'content']));
    expect(dao.created, isEmpty);
  });

  test('saveReview viết mới gửi review đã cắt khoảng trắng và ảnh mới', () async {
    await controller.openForm(placeId: 1);
    final future = controller.saveReview(
      placeId: 1,
      rating: 5,
      content: '  Ga sạch, có thang máy.  ',
      imagePaths: ['/tmp/a.jpg'],
    );
    expect(controller.isSaving, isTrue);
    expect(await future, isTrue);
    expect(controller.isSaving, isFalse);
    final sent = dao.created.single;
    expect(sent.review.toJson(), {'placeId': 1, 'rating': 5, 'content': 'Ga sạch, có thang máy.'});
    expect(sent.images, ['/tmp/a.jpg']);
    expect(controller.savedPlaceId, 1);
    expect(controller.takeMessage(), 'Đã gửi. Ảnh/video đang được quét, review hiện cho mọi người sau khi đạt.');
    expect(controller.takeMessage(), isNull);
  });

  test('saveReview cho địa điểm OpenStreetMap gửi externalPlaceId và nhận id địa điểm mới', () async {
    await controller.openForm(externalPlaceId: 'DEV-ueno-station');
    expect(dao.composeAsked, [null]);
    expect(
      await controller.saveReview(externalPlaceId: 'DEV-ueno-station', rating: 4, content: 'Ga rất đông.'),
      isTrue,
    );
    expect(dao.created.single.review.toJson(), {
      'externalPlaceId': 'DEV-ueno-station',
      'rating': 4,
      'content': 'Ga rất đông.',
    });
    expect(controller.savedPlaceId, 77);
  });

  test('saveReview viết mới mà không có địa điểm thì báo lỗi, không gọi server', () async {
    await controller.openForm();
    expect(await controller.saveReview(rating: 4, content: 'Nội dung đủ dài.'), isFalse);
    expect(controller.fieldErrors['place'], 'Hãy chọn địa điểm.');
    expect(dao.created, isEmpty);
  });

  test('saveReview khi sửa gửi keepMediaIds của ảnh còn giữ', () async {
    await controller.openForm(reviewId: 12);
    final keep = controller.editing!.media;
    expect(
      await controller.saveReview(rating: 3, content: 'Đã sửa nội dung.', keep: keep, imagePaths: ['/tmp/b.jpg']),
      isTrue,
    );
    final sent = dao.updated.single;
    expect(sent.review.id, 12);
    expect(sent.review.toJson(), {
      'rating': 3,
      'content': 'Đã sửa nội dung.',
      'keepMediaIds': [20],
    });
    expect(sent.images, ['/tmp/b.jpg']);
    expect(controller.takeMessage(), 'Đã lưu thay đổi.');
  });

  test('saveReview khi sửa giữ nguyên video đã đăng từ web (app chỉ sửa ảnh)', () async {
    dao.edits[13] = (
      review: Review.fromEditJson({
        ...sampleEdit,
        'id': 13,
        'media': [
          {'id': 20, 'type': 'IMAGE', 'url': '/media/review/a.jpg', 'scanStatus': 'PASSED'},
          {'id': 21, 'type': 'VIDEO', 'url': '/media/review/b.mp4', 'scanStatus': 'PROCESSING'},
        ],
      }),
      compose: ReviewCompose.fromJson(sampleEdit),
    );
    await controller.openForm(reviewId: 13);
    expect(controller.editing?.scanningMediaIds, [21]);
    // Người dùng bỏ ảnh 20; video 21 không hiện trên app
    expect(await controller.saveReview(rating: 4, content: 'Bỏ ảnh, giữ video.', keep: const []), isTrue);
    expect(dao.updated.single.review.toJson()['keepMediaIds'], [21]);
  });

  test('saveReview khi sửa: ảnh giữ lại + ảnh mới quá 5 thì báo lỗi', () async {
    await controller.openForm(reviewId: 12);
    final saved = await controller.saveReview(
      rating: 3,
      content: 'Đã sửa nội dung.',
      keep: controller.editing!.media,
      imagePaths: List.filled(5, '/tmp/c.jpg'),
    );
    expect(saved, isFalse);
    expect(controller.fieldErrors['images'], 'Tối đa 5 ảnh.');
    expect(dao.updated, isEmpty);
  });

  test('saveReview hiện lỗi theo ô và lỗi chung của server', () async {
    await controller.openForm(placeId: 1);
    dao.failOn['create'] = const ApiException(
      'Nội dung chứa từ ngữ không phù hợp.',
      statusCode: 400,
      fields: {'content': 'Nội dung chứa từ ngữ không phù hợp.'},
    );
    expect(await controller.saveReview(placeId: 1, rating: 4, content: 'Nội dung đủ dài.'), isFalse);
    expect(controller.formError, 'Nội dung chứa từ ngữ không phù hợp.');
    expect(controller.fieldErrors['content'], 'Nội dung chứa từ ngữ không phù hợp.');
    expect(controller.isSaving, isFalse);
  });

  test('deleteReview giữ câu của server; lỗi trả về false', () async {
    await controller.openForm(reviewId: 12);
    expect(await controller.deleteReview(12), isTrue);
    expect(dao.deleted, [12]);
    expect(controller.editing, isNull);
    expect(controller.takeMessage(), 'Đã xóa review. Điểm của review này được thu lại.');
    dao.failOn['delete'] = const ApiException('Review này không còn tồn tại.', statusCode: 404);
    expect(await controller.deleteReview(12), isFalse);
    expect(controller.takeMessage(), 'Review này không còn tồn tại.');
  });
}
