// EventDao với server thật: đọc danh sách, chi tiết, form; viết → sửa → xóa review thử; thích rồi trả lại như cũ.
//
//   flutter test test/live/event_live_test.dart --dart-define=LIVE_API=http://localhost:8080
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/event_dao.dart';
import 'package:myasvsj/com.myasvsj.model/event_detail.dart';
import 'package:myasvsj/com.myasvsj.model/event_review.dart';

import 'live_api.dart';

/// Ảnh PNG 1×1 hợp lệ để thử gửi ảnh kèm review.
const _pngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';

void main() {
  test('khách: danh sách, tìm, chi tiết mọi sự kiện, sự kiện không có → 404, form → 401', () async {
    final dao = EventDao(liveGuest());

    final events = await dao.findAll();
    expect(events, isNotEmpty);
    for (final e in events) {
      expect(e.title, isNotEmpty);
      expect(e.state, isIn(['NOW', 'UPCOMING', 'PAST']));
      expect(e.reviewYear, e.startDate.year);
      expect(e.endDate.isBefore(e.startDate), isFalse);
      final detail = await dao.findById(e.id);
      expect(detail.event.id, e.id);
      expect(detail.signedIn, isFalse);
      expect(detail.member, isFalse);
      expect(detail.reportReasons, isNotEmpty);
      expect(detail.album.length, lessThanOrEqualTo(detail.albumCount));
      for (final r in detail.reviews) {
        expect(r.author?.displayName, isNotEmpty);
        expect(r.rating, inInclusiveRange(1, 5));
        expect(r.createdAt, isNotNull);
        expect(r.mine, isFalse);
      }
    }
    expect(events.any((e) => e.reviewCount > 0 && e.avgRating != null), isTrue);
    expect(events.any((e) => e.hasLocation), isTrue);

    // Không phân biệt dấu và hoa thường
    final found = await dao.findAll(q: 'yanaka');
    expect(found, isNotEmpty);
    expect(await dao.findAll(q: 'khongcosukiennaynhe'), isEmpty);

    await expectLater(
      dao.findById(99999999),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
    );
    await expectLater(dao.findReviewForm(events.first.id), throwsA(isA<ApiException>()));
  }, skip: liveSkip);

  // Review có ảnh đi qua bước quét ảnh, nên mỗi lần chạy kouhai nhận một thông báo "đã được đăng" (link null vì
  // review đã bị xóa) và lượt đăng hôm nay tăng 1; điểm được thu lại khi xóa. Thông báo không xóa được qua API.
  test('kouhai: form review, viết → sửa → xóa review thử (có ảnh)', () async {
    final dao = EventDao(await liveSignedIn('kouhai@gmail.com'));
    final events = await dao.findAll();

    // Sự kiện đã bắt đầu mà kouhai chưa viết review năm nay
    EventDetail? target;
    for (final e in events.where((e) => e.canReview)) {
      final detail = await dao.findById(e.id);
      expect(detail.member, isTrue);
      if (detail.myReviewId == null) {
        target = detail;
        break;
      }
    }
    if (target == null) {
      markTestSkipped('kouhai đã review mọi sự kiện đã bắt đầu');
      return;
    }
    final eventId = target.event.id;

    final form = await dao.findReviewForm(eventId);
    expect(form.event.id, eventId);
    expect(form.contentMax, 2000);
    expect(form.imagesMax, 5);
    expect(form.isEditing, isFalse);

    // Sự kiện chưa bắt đầu: server từ chối form
    final upcoming = events.where((e) => !e.canReview);
    if (upcoming.isNotEmpty) {
      await expectLater(
        dao.findReviewForm(upcoming.first.id),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Viết review được khi sự kiện bắt đầu.')),
      );
    }

    final dir = Directory.systemTemp.createTempSync('event_live');
    final png = File('${dir.path}/thu.png')..writeAsBytesSync(base64Decode(_pngBase64));
    int? reviewId;
    try {
      final created = await dao.createReview(
        eventId,
        rating: 4,
        content: 'Review thử từ app mobile (test tự động, sẽ xóa ngay).',
        imagePaths: [png.path],
      );
      expect(created, isNotEmpty);

      final editForm = await dao.findReviewForm(eventId);
      expect(editForm.isEditing, isTrue);
      reviewId = editForm.review!.id;
      expect(editForm.review!.rating, 4);
      expect(editForm.review!.media, hasLength(1));

      // Đã có review năm nay: viết lần nữa bị từ chối
      await expectLater(
        dao.createReview(eventId, rating: 5, content: 'Lần hai'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409)),
      );

      // Lỗi theo ô: thiếu sao và nội dung
      await expectLater(
        dao.updateReview(reviewId, rating: 0, content: ''),
        throwsA(isA<ApiException>().having((e) => e.fields.keys, 'fields', containsAll(['rating', 'content']))),
      );

      final updated = await dao.updateReview(
        reviewId,
        rating: 5,
        content: 'Review thử đã sửa (test tự động).',
        keepMediaIds: [editForm.review!.media.single.id],
      );
      expect(updated, startsWith('Đã lưu thay đổi'));

      final detail = await dao.findById(eventId);
      expect(detail.myReviewId, reviewId);
      final mine = detail.reviews.firstWhere((r) => r.id == reviewId);
      expect(mine.mine, isTrue);
      expect(mine.rating, 5);
      expect(mine.content, 'Review thử đã sửa (test tự động).');
      expect(mine.status, isIn([EventReview.published, EventReview.processing]));
      expect(mine.images, hasLength(1));

      // Không thích được review của chính mình
      await expectLater(dao.likeReview(reviewId), throwsA(isA<ApiException>()));
    } finally {
      if (reviewId != null) {
        expect(await dao.deleteReview(reviewId), 'Đã xóa review. Điểm của review này được thu lại.');
      }
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows còn giữ file một lúc; thư mục tạm tự dọn sau
      }
    }
    final after = await dao.findById(eventId);
    expect(after.myReviewId, isNull);
    expect(after.reviews.where((r) => r.id == reviewId), isEmpty);
  }, skip: liveSkip);

  test('kouhai: thích rồi trả lại như cũ; báo cáo review không có → 404', () async {
    final dao = EventDao(await liveSignedIn('kouhai@gmail.com'));

    EventReview? other;
    for (final e in await dao.findAll()) {
      final detail = await dao.findById(e.id);
      for (final r in detail.reviews) {
        if (!r.mine && r.isPublished) {
          other = r;
          break;
        }
      }
      if (other != null) {
        break;
      }
    }
    expect(other, isNotNull, reason: 'cần một review đã đăng của người khác');
    final review = other!;

    if (review.liked) {
      final off = await dao.unlikeReview(review.id);
      expect(off.liked, isFalse);
      final on = await dao.likeReview(review.id);
      expect(on.liked, isTrue);
      expect(on.likeCount, review.likeCount);
    } else {
      final on = await dao.likeReview(review.id);
      expect(on.liked, isTrue);
      expect(on.likeCount, review.likeCount + 1);
      final off = await dao.unlikeReview(review.id);
      expect(off.liked, isFalse);
      expect(off.likeCount, review.likeCount);
    }

    await expectLater(
      dao.reportReview(99999999, reasonId: 4, note: 'test'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
    );
  }, skip: liveSkip);
}
