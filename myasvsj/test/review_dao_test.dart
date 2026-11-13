// Test ReviewDao với server giả: form review, tạo / sửa bằng multipart (phần "review" + "images"), xóa, lỗi.
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.model/review.dart';
import 'package:myasvsj/com.myasvsj.model/review_dao.dart';

import 'fake_api.dart';
import 'place_samples.dart';

/// Đọc phần JSON "review" của một request multipart.
Future<Map<String, dynamic>> reviewPart(FormData form) async {
  final part = form.files.firstWhere((e) => e.key == 'review').value;
  expect(part.contentType.toString(), startsWith('application/json'));
  final bytes = await part.clone().finalize().fold<List<int>>([], (all, chunk) => all..addAll(chunk));
  return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
}

void main() {
  late FakeServer server;
  late ReviewDao dao;
  late Directory temp;

  setUp(() async {
    server = FakeServer({
      'GET /api/reviews/compose': (_) => apiOk(sampleCompose),
      'GET /api/reviews/12/edit': (_) => apiOk(sampleEdit),
      'POST /api/reviews': (_) => apiOk({
        'id': 12,
        'placeId': 11,
        'status': 'PROCESSING',
        'changed': true,
      }, message: 'Đã gửi. Ảnh/video đang được quét, review hiện cho mọi người sau khi đạt.'),
      'PUT /api/reviews/12': (_) =>
          apiOk({'id': 12, 'placeId': 11, 'status': 'PUBLISHED', 'changed': false}, message: 'Không có thay đổi nào.'),
      'DELETE /api/reviews/12': (_) => apiOk(null, message: 'Đã xóa review. Điểm của review này được thu lại.'),
    });
    dao = ReviewDao(server.api);
    temp = await Directory.systemTemp.createTemp('review_dao_test');
  });

  tearDown(() async {
    try {
      await temp.delete(recursive: true);
    } on FileSystemException {
      // Windows còn giữ file ảnh vì server giả không đọc hết luồng gửi lên; thư mục tạm sẽ được hệ thống dọn
    }
  });

  test('findCompose gửi placeId, đọc giới hạn, lượt đăng và myReviewId', () async {
    final compose = await dao.findCompose(placeId: 1);
    expect(server.last('GET', '/api/reviews/compose').uri.queryParameters, {'placeId': '1'});
    expect(compose.contentMin, 10);
    expect(compose.contentMax, 2000);
    expect(compose.imagesMax, 5);
    expect(compose.imageMaxMb, 20);
    expect(compose.newAccount, isTrue);
    expect(compose.newAccountDays, 7);
    expect(compose.postsUsed, 0);
    expect(compose.postsLimit, 3);
    expect(compose.postsLeft, 3);
    expect(compose.myReviewId, isNull);
  });

  test('findCompose không có placeId (địa điểm OpenStreetMap) không gửi tham số', () async {
    server.routes['GET /api/reviews/compose'] = (_) => apiOk({...sampleCompose, 'myReviewId': 7});
    final compose = await dao.findCompose();
    expect(server.last('GET', '/api/reviews/compose').uri.queryParameters, isEmpty);
    expect(compose.myReviewId, 7);
  });

  test('findCompose của khách ném 401', () async {
    server.routes['GET /api/reviews/compose'] = (_) => apiError(401, 'Bạn cần đăng nhập để viết review.');
    await expectLater(
      dao.findCompose(placeId: 1),
      throwsA(isA<ApiException>().having((e) => e.isUnauthorized, '401', isTrue)),
    );
  });

  test('findForEdit đọc review như đang lưu và giới hạn', () async {
    final data = await dao.findForEdit(12);
    final review = data.review;
    expect(review.id, 12);
    expect(review.placeId, 11);
    expect(review.placeName, 'Tiệm giặt Coin Laundry Sora');
    expect(review.rating, 4);
    expect(review.content, 'Review thử của agent map, sẽ xóa ngay.');
    expect(review.status, 'PUBLISHED');
    expect(review.media.single.id, 20);
    expect(review.media.single.isImage, isTrue);
    expect(review.scanningMediaIds, isEmpty);
    expect(data.compose.newAccount, isFalse);
    expect(data.compose.postsUsed, 2);
  });

  test('create gửi multipart: phần JSON "review" {placeId, rating, content} và ảnh trong phần "images"', () async {
    final photo = File('${temp.path}/a.jpg')..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xD9]);
    final saved = await dao.create(
      const Review(placeId: 11, rating: 4, content: 'Máy giặt sạch, có máy sấy.'),
      imagePaths: [photo.path],
    );
    final request = server.last('POST', '/api/reviews');
    final form = request.data as FormData;
    expect(form.files.map((e) => e.key), ['review', 'images']);
    expect(await reviewPart(form), {'placeId': 11, 'rating': 4, 'content': 'Máy giặt sạch, có máy sấy.'});
    final image = form.files.last.value;
    expect(image.filename, 'a.jpg');
    expect(image.contentType.toString(), 'image/jpeg');
    expect(saved.id, 12);
    expect(saved.placeId, 11);
    expect(saved.status, 'PROCESSING');
    expect(saved.changed, isTrue);
    expect(saved.message, 'Đã gửi. Ảnh/video đang được quét, review hiện cho mọi người sau khi đạt.');
  });

  test('create cho địa điểm OpenStreetMap gửi externalPlaceId, không ảnh thì không có phần "images"', () async {
    await dao.create(const Review(externalPlaceId: 'N772389775', rating: 5, content: 'Ga rộng, nhiều lối ra.'));
    final form = server.last('POST', '/api/reviews').data as FormData;
    expect(form.files.map((e) => e.key), ['review']);
    expect(await reviewPart(form), {'externalPlaceId': 'N772389775', 'rating': 5, 'content': 'Ga rộng, nhiều lối ra.'});
  });

  test('update gửi PUT multipart {rating, content, keepMediaIds} và đọc changed', () async {
    const keep = MediaItem(id: 20, type: 'IMAGE', url: '/media/review/x.jpg');
    final saved = await dao.update(const Review(id: 12, rating: 3, content: 'Đã sửa nội dung review.', media: [keep]));
    final form = server.last('PUT', '/api/reviews/12').data as FormData;
    expect(await reviewPart(form), {
      'rating': 3,
      'content': 'Đã sửa nội dung review.',
      'keepMediaIds': [20],
    });
    expect(saved.changed, isFalse);
    expect(saved.message, 'Không có thay đổi nào.');
  });

  test('lỗi theo ô của server (400) nằm trong ApiException.fields; 409 khi đã review', () async {
    server.routes['POST /api/reviews'] = (_) =>
        apiError(400, 'Nội dung cần ít nhất 10 ký tự.', fields: {'content': 'Nội dung cần ít nhất 10 ký tự.'});
    await expectLater(
      dao.create(const Review(placeId: 1, rating: 3, content: 'ngắn')),
      throwsA(isA<ApiException>().having((e) => e.fields['content'], 'content', 'Nội dung cần ít nhất 10 ký tự.')),
    );
    server.routes['POST /api/reviews'] = (_) =>
        apiError(409, 'Bạn đã viết review cho địa điểm này rồi. Hãy sửa review của bạn.');
    await expectLater(
      dao.create(const Review(placeId: 1, rating: 3, content: 'Nội dung đủ dài.')),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 409)),
    );
  });

  test('delete gọi DELETE và trả về câu của server; review đã xóa ném 404', () async {
    expect(await dao.delete(12), 'Đã xóa review. Điểm của review này được thu lại.');
    server.routes['DELETE /api/reviews/12'] = (_) => apiError(404, 'Review này không còn tồn tại.');
    await expectLater(dao.delete(12), throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 404)));
  });
}
