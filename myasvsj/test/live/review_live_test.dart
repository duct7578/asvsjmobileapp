// Review với server thật: viết (multipart có ảnh), đọc lại, sửa (giữ / bỏ ảnh), xóa, bằng ReviewDao và PlaceDao.
//
// Chạy: flutter test test/live/review_live_test.dart --dart-define=LIVE_API=http://localhost:8080
//
// Review thử được viết bằng mentor@gmail.com (tài khoản không còn là tài khoản mới nên không tốn hạn mức 3 bài / ngày
// mà user@gmail.com dùng chung với bài viết của các tính năng khác) cho địa điểm 11, và luôn được xóa ở cuối.
// Không thử "Viết review đầu tiên" cho địa điểm OpenStreetMap: server sẽ thêm địa điểm vào database mà không xóa được.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/place_dao.dart';
import 'package:myasvsj/com.myasvsj.model/review.dart';
import 'package:myasvsj/com.myasvsj.model/review_dao.dart';

import 'live_api.dart';

/// Ảnh PNG 1×1 hợp lệ (server giải mã rồi lưu lại thành JPEG).
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

const _placeId = 11;

void main() {
  test('khách không mở được form review (401)', () async {
    await expectLater(
      ReviewDao(liveGuest()).findCompose(placeId: _placeId),
      throwsA(isA<ApiException>().having((e) => e.isUnauthorized, '401', isTrue)),
    );
  }, skip: liveSkip);

  test('user@gmail.com: form có giới hạn và lượt đăng của tài khoản mới', () async {
    final compose = await ReviewDao(await liveSignedIn('user@gmail.com')).findCompose(placeId: 1);
    expect(compose.contentMin, 10);
    expect(compose.contentMax, 2000);
    expect(compose.imagesMax, 5);
    expect(compose.postsLimit, greaterThan(0));
  }, skip: liveSkip);

  test('mentor@gmail.com: viết review có ảnh, đọc lại, sửa, xóa', () async {
    final api = await liveSignedIn('mentor@gmail.com');
    final reviews = ReviewDao(api);
    final places = PlaceDao(api);
    final dir = await Directory.systemTemp.createTemp('review_live');
    final photo = File('${dir.path}/thu.png')..writeAsBytesSync(_png);
    int? reviewId;
    try {
      final compose = await reviews.findCompose(placeId: _placeId);
      expect(compose.myReviewId, isNull, reason: 'Còn review thử cũ của mentor ở địa điểm $_placeId, hãy xóa trước');

      // Viết mới: multipart "review" + "images"
      final created = await reviews.create(
        const Review(placeId: _placeId, rating: 4, content: 'Review thử của app mobile, sẽ xóa ngay.'),
        imagePaths: [photo.path],
      );
      reviewId = created.id;
      expect(created.placeId, _placeId);
      expect(created.status, anyOf('PROCESSING', 'PUBLISHED'));
      expect(created.message, isNotEmpty);

      // Form lần sau biết mình đã review nơi này
      expect((await reviews.findCompose(placeId: _placeId)).myReviewId, reviewId);
      expect((await places.findById(_placeId)).myReviewId, reviewId);

      // Đọc lại để sửa: ảnh đã lưu
      final edit = await reviews.findForEdit(reviewId);
      expect(edit.review.content, 'Review thử của app mobile, sẽ xóa ngay.');
      expect(edit.review.rating, 4);
      expect(edit.review.placeName, isNotEmpty);
      expect(edit.review.media, hasLength(1));
      expect(edit.review.media.single.url, startsWith('/media/'));

      // Danh sách review của địa điểm có review của mình
      final page = await places.findReviews(_placeId);
      final mine = page.items.firstWhere((r) => r.id == reviewId);
      expect(mine.mine, isTrue);
      expect(mine.author.displayName, isNotEmpty);

      // Không thích được review của chính mình
      await expectLater(places.likeReview(reviewId), throwsA(isA<ApiException>()));

      // Sửa nhưng không đổi gì
      final same = await reviews.update(
        Review(id: reviewId, rating: 4, content: 'Review thử của app mobile, sẽ xóa ngay.', media: edit.review.media),
      );
      expect(same.changed, isFalse);
      expect(same.message, 'Không có thay đổi nào.');

      // Sửa: đổi sao, nội dung, bỏ ảnh
      final changed = await reviews.update(
        Review(id: reviewId, rating: 3, content: 'Review thử của app mobile, đã sửa và bỏ ảnh.'),
      );
      expect(changed.changed, isTrue);
      expect(changed.status, 'PUBLISHED');
      final after = await reviews.findForEdit(reviewId);
      expect(after.review.rating, 3);
      expect(after.review.media, isEmpty);

      // Nội dung quá ngắn: lỗi theo ô
      await expectLater(
        reviews.update(Review(id: reviewId, rating: 3, content: 'ngắn')),
        throwsA(isA<ApiException>().having((e) => e.fields['content'], 'content', 'Nội dung cần ít nhất 10 ký tự.')),
      );
    } finally {
      if (reviewId != null) {
        expect(await reviews.delete(reviewId), 'Đã xóa review. Điểm của review này được thu lại.');
      }
      try {
        await dir.delete(recursive: true);
      } on FileSystemException {
        // thư mục tạm, hệ thống sẽ dọn
      }
    }

    // Đã xóa thật
    await expectLater(reviews.findForEdit(reviewId), throwsA(isA<ApiException>()));
    expect((await reviews.findCompose(placeId: _placeId)).myReviewId, isNull);
  }, skip: liveSkip);

  test('mentor@gmail.com: viết lần hai cho nơi đã review bị từ chối 409', () async {
    // Mentor đã có review mẫu (id 1) ở Ga Nippori
    final reviews = ReviewDao(await liveSignedIn('mentor@gmail.com'));
    final compose = await reviews.findCompose(placeId: 1);
    expect(compose.myReviewId, isNotNull);
    await expectLater(
      reviews.create(const Review(placeId: 1, rating: 5, content: 'Viết lần hai cho cùng địa điểm.')),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)),
    );
  }, skip: liveSkip);
}
