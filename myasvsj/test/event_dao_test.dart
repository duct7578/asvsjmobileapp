// Test EventDao với server giả: JSON chép từ server thật (curl http://localhost:8080, dữ liệu mẫu ngày 8/11/2026).
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/event.dart';
import 'package:myasvsj/com.myasvsj.model/event_dao.dart';
import 'package:myasvsj/com.myasvsj.model/event_review.dart';

import 'fake_api.dart';

const _eventsJson = [
  {
    'id': 1,
    'title': 'Lễ hội Obon công viên Yanaka',
    'startDate': '2026-09-08',
    'endDate': '2026-09-10',
    'locationName': 'Công viên Yanaka',
    'lat': 35.725800,
    'lng': 139.766000,
    'costNote': 'Miễn phí',
    'coverUrl': null,
    'state': 'PAST',
    'daysUntil': 0,
    'reviewYear': 2026,
    'canReview': true,
    'avgRating': 4.0,
    'reviewCount': 1,
  },
  {
    'id': 5,
    'title': 'Ngắm hoa anh đào ở công viên Ueno',
    'startDate': '2027-04-16',
    'endDate': '2027-04-27',
    'locationName': 'Công viên Ueno, cách Nippori hai ga',
    'lat': null,
    'lng': null,
    'costNote': 'Miễn phí',
    'coverUrl': '/media/event/2026/11/ueno.jpg',
    'state': 'UPCOMING',
    'daysUntil': 159,
    'reviewYear': 2027,
    'canReview': false,
    'avgRating': null,
    'reviewCount': 0,
  },
];

const _detailJson = {
  'event': {
    'id': 2,
    'title': 'Chợ phiên cuối tuần phố Yanaka Ginza',
    'startDate': '2026-11-06',
    'endDate': '2026-11-08',
    'locationName': 'Phố Yanaka Ginza',
    'lat': 35.727400,
    'lng': 139.765800,
    'costNote': 'Miễn phí vào cửa',
    'coverUrl': null,
    'state': 'NOW',
    'daysUntil': 0,
    'reviewYear': 2026,
    'canReview': true,
    'avgRating': 5.0,
    'reviewCount': 1,
  },
  'tip': 'Nhiều món ăn vặt 100 đến 300 yên, nên mang tiền lẻ.',
  'album': [
    {'url': '/media/review/2026/11/a.jpg', 'authorName': 'Hoàng', 'year': 2026, 'width': 1600, 'height': 1200},
  ],
  'albumCount': 1,
  'reviews': [
    {
      'id': 10,
      'author': {
        'id': 7,
        'displayName': 'Hoàng',
        'avatarUrl': null,
        'tags': [
          {'name': 'Kouhai', 'color': '#2E7D5B'},
        ],
        'rankName': 'Người chỉ đường',
      },
      'rating': 5,
      'content': 'Chiều thứ bảy đông nhưng vui. Croquette 100 yên ở đầu phố rất ngon.',
      'year': 2026,
      'status': 'PUBLISHED',
      'edited': false,
      'createdAt': '2026-11-06T18:36:45Z',
      'likeCount': 4,
      'media': [
        {
          'id': 31,
          'type': 'IMAGE',
          'url': '/media/review/2026/11/a.jpg',
          'width': 1600,
          'height': 1200,
          'scanStatus': 'PASSED',
        },
      ],
      'mine': true,
      'liked': false,
    },
  ],
  'viewer': {'signedIn': true, 'member': true, 'myReviewId': 10},
  'reportReasons': [
    {'id': 1, 'label': 'Lừa đảo'},
    {'id': 2, 'label': 'Sai sự thật'},
    {'id': 3, 'label': 'Xúc phạm'},
    {'id': 4, 'label': 'Spam'},
  ],
};

const _formJson = {
  'event': {
    'id': 2,
    'title': 'Chợ phiên cuối tuần phố Yanaka Ginza',
    'startDate': '2026-11-06',
    'endDate': '2026-11-08',
    'locationName': 'Phố Yanaka Ginza',
    'lat': 35.727400,
    'lng': 139.765800,
    'costNote': 'Miễn phí vào cửa',
    'coverUrl': null,
    'state': 'NOW',
    'daysUntil': 0,
    'reviewYear': 2026,
    'canReview': true,
    'avgRating': null,
    'reviewCount': 0,
  },
  'limits': {
    'contentMax': 2000,
    'imagesMax': 5,
    'imageMaxMb': 20,
    'videosMax': 1,
    'videoMaxSeconds': 30,
    'videoMaxMb': 50,
  },
  'quota': {
    'newAccount': true,
    'newAccountDays': 7,
    'postsUsed': 1,
    'postsLimit': 3,
    'pinsUsed': 0,
    'pinsLimit': 2,
    'videosUsed': 0,
    'videosLimit': 1,
  },
  'canPostLinks': false,
  'review': {
    'id': 10,
    'rating': 5,
    'content': 'Chiều thứ bảy đông nhưng vui.',
    'status': 'PUBLISHED',
    'media': [
      {'id': 31, 'type': 'IMAGE', 'url': '/media/review/a.jpg', 'width': 10, 'height': 10, 'scanStatus': 'PASSED'},
      {'id': 32, 'type': 'IMAGE', 'url': '/media/review/b.jpg', 'width': 10, 'height': 10, 'scanStatus': 'REJECTED'},
    ],
  },
};

/// Đọc lại phần JSON "review" mà DAO đã gửi trong multipart.
Future<Map<String, dynamic>> _jsonPart(RequestOptions request, String name) async {
  final part = (request.data as FormData).files.firstWhere((e) => e.key == name).value;
  expect(part.contentType.toString(), startsWith('application/json'));
  return jsonDecode(await utf8.decodeStream(part.clone().finalize())) as Map<String, dynamic>;
}

void main() {
  test('findAll gọi GET /api/events với từ khóa và đọc đủ trường', () async {
    final server = FakeServer({'GET /api/events': (_) => apiOk(_eventsJson)});
    final events = await EventDao(server.api).findAll(q: '  hanabi ');

    expect(server.last('GET', '/api/events').uri.queryParameters['q'], 'hanabi');
    final obon = events.first;
    expect(obon.id, 1);
    expect(obon.title, 'Lễ hội Obon công viên Yanaka');
    expect(obon.startDate, DateTime(2026, 9, 8));
    expect(obon.endDate, DateTime(2026, 9, 10));
    expect(obon.lat, closeTo(35.7258, 1e-9));
    expect(obon.lng, closeTo(139.766, 1e-9));
    expect(obon.costNote, 'Miễn phí');
    expect(obon.isPast, isTrue);
    expect(obon.stateLabel, 'Đã qua');
    expect(obon.canReview, isTrue);
    expect(obon.avgRating, 4.0);
    expect(obon.reviewCount, 1);
    expect(obon.directionsUri.toString(), 'https://www.google.com/maps/dir/?api=1&destination=35.7258,139.766');

    final ueno = events.last;
    expect(ueno.hasLocation, isFalse);
    expect(ueno.directionsUri, isNull);
    expect(ueno.coverUrl, '/media/event/2026/11/ueno.jpg');
    expect(ueno.stateLabel, 'Còn 159 ngày');
    expect(ueno.reviewYear, 2027);
    expect(ueno.avgRating, isNull);
  });

  test('findAll không gửi q khi từ khóa rỗng', () async {
    final server = FakeServer({'GET /api/events': (_) => apiOk(<Object>[])});
    expect(await EventDao(server.api).findAll(q: '  '), isEmpty);
    expect(server.last('GET', '/api/events').uri.queryParameters.containsKey('q'), isFalse);
  });

  test('findById đọc album, mẹo, review, người xem và lý do báo cáo', () async {
    final server = FakeServer({'GET /api/events/2': (_) => apiOk(_detailJson)});
    final detail = await EventDao(server.api).findById(2);

    expect(detail.event.isNow, isTrue);
    expect(detail.event.stateLabel, 'Đang diễn ra');
    expect(detail.tip, 'Nhiều món ăn vặt 100 đến 300 yên, nên mang tiền lẻ.');
    expect(detail.albumCount, 1);
    expect(detail.album.single.authorName, 'Hoàng');
    expect(detail.album.single.year, 2026);
    expect(detail.album.single.width, 1600);
    expect(detail.signedIn, isTrue);
    expect(detail.member, isTrue);
    expect(detail.myReviewId, 10);
    expect(detail.reportReasons.map((r) => r.label), ['Lừa đảo', 'Sai sự thật', 'Xúc phạm', 'Spam']);

    final review = detail.reviews.single;
    expect(review.id, 10);
    expect(review.author?.displayName, 'Hoàng');
    expect(review.author?.tagNames, ['Kouhai']);
    expect(review.author?.rankName, 'Người chỉ đường');
    expect(review.rating, 5);
    expect(review.year, 2026);
    expect(review.isPublished, isTrue);
    expect(review.statusNote, isNull);
    expect(review.createdAt, DateTime.utc(2026, 11, 6, 18, 36, 45).toLocal());
    expect(review.likeCount, 4);
    expect(review.images.single.url, '/media/review/2026/11/a.jpg');
    expect(review.mine, isTrue);
    expect(review.liked, isFalse);
    expect(detail.publishedCount, 1);
  });

  test('findById ném ApiException mang câu của server khi sự kiện đã xóa', () async {
    final server = FakeServer({
      'GET /api/events/999': (_) => apiError(404, 'Không tìm thấy sự kiện. Sự kiện có thể đã bị xóa.'),
    });
    await expectLater(
      EventDao(server.api).findById(999),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.message, 'message', 'Không tìm thấy sự kiện. Sự kiện có thể đã bị xóa.'),
      ),
    );
  });

  test('findReviewForm đọc giới hạn, hạn mức và review đang sửa (bỏ ảnh bị từ chối)', () async {
    final server = FakeServer({'GET /api/events/2/review-form': (_) => apiOk(_formJson)});
    final form = await EventDao(server.api).findReviewForm(2);

    expect(form.event.id, 2);
    expect(form.contentMax, 2000);
    expect(form.imagesMax, 5);
    expect(form.imageMaxMb, 20);
    expect(form.newAccount, isTrue);
    expect(form.postsUsed, 1);
    expect(form.postsLimit, 3);
    expect(form.pinsLimit, 2);
    expect(form.videosLimit, 1);
    expect(form.quotaFull, isFalse);
    expect(form.canPostLinks, isFalse);
    expect(form.isEditing, isTrue);
    expect(form.review!.id, 10);
    expect(form.review!.rating, 5);
    expect(form.review!.year, 2026);
    expect(form.review!.media.map((m) => m.id), [31]);
  });

  test('findReviewForm: sự kiện chưa bắt đầu → ApiException 400', () async {
    final server = FakeServer({
      'GET /api/events/3/review-form': (_) => apiError(400, 'Viết review được khi sự kiện bắt đầu.'),
    });
    await expectLater(
      EventDao(server.api).findReviewForm(3),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Viết review được khi sự kiện bắt đầu.')),
    );
  });

  test('createReview gửi multipart: phần "review" là JSON, ảnh ở phần "images"', () async {
    final dir = Directory.systemTemp.createTempSync('event_dao_test');
    addTearDown(() {
      try {
        dir.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows: server giả không đọc hết luồng file nên file còn bị giữ; thư mục tạm tự dọn sau
      }
    });
    final photo = File('${dir.path}/anh.jpg')..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xD9]);
    final server = FakeServer({
      'POST /api/events/2/reviews': (_) => apiOk({
        'id': 13,
        'eventId': 2,
        'status': 'PROCESSING',
      }, message: 'Đã gửi. Ảnh và video đang được quét, trong lúc này chỉ bạn thấy review.'),
    });

    final message = await EventDao(server.api).createReview(2, rating: 4, content: 'Vui', imagePaths: [photo.path]);

    expect(message, 'Đã gửi. Ảnh và video đang được quét, trong lúc này chỉ bạn thấy review.');
    final request = server.last('POST', '/api/events/2/reviews');
    expect(request.headers['X-XSRF-TOKEN'], 'csrf-test');
    expect(await _jsonPart(request, 'review'), {'rating': 4, 'content': 'Vui'});
    final images = (request.data as FormData).files.where((e) => e.key == 'images').toList();
    expect(images.single.value.filename, 'anh.jpg');
    expect(images.single.value.contentType.toString(), 'image/jpeg');
  });

  test('createReview không ảnh chỉ gửi phần "review"; 409 khi đã viết review năm nay', () async {
    final server = FakeServer({
      'POST /api/events/1/reviews': (_) =>
          apiError(409, 'Bạn đã viết review cho lần tổ chức năm 2026. Hãy sửa review đó.'),
    });
    await expectLater(
      EventDao(server.api).createReview(1, rating: 5, content: 'Hay'),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409)),
    );
    final form = server.last('POST', '/api/events/1/reviews').data as FormData;
    expect(form.files.map((e) => e.key), ['review']);
  });

  test('updateReview gửi PUT multipart với keepMediaIds; lỗi theo ô nằm ở fields', () async {
    final server = FakeServer({
      'PUT /api/event-reviews/13': (_) =>
          apiOk({'id': 13, 'eventId': 1, 'status': 'PUBLISHED'}, message: 'Đã lưu thay đổi.'),
      'PUT /api/event-reviews/14': (_) => apiError(
        400,
        'Hãy chọn số sao (1 đến 5).',
        fields: {'content': 'Hãy viết vài dòng về sự kiện.', 'rating': 'Hãy chọn số sao (1 đến 5).'},
      ),
    });
    final dao = EventDao(server.api);

    expect(await dao.updateReview(13, rating: 5, content: 'Đã sửa', keepMediaIds: [31]), 'Đã lưu thay đổi.');
    expect(await _jsonPart(server.last('PUT', '/api/event-reviews/13'), 'review'), {
      'rating': 5,
      'content': 'Đã sửa',
      'keepMediaIds': [31],
    });

    await expectLater(
      dao.updateReview(14, rating: 9, content: ''),
      throwsA(isA<ApiException>().having((e) => e.fields['content'], 'fields', 'Hãy viết vài dòng về sự kiện.')),
    );
  });

  test('deleteReview, likeReview, unlikeReview, reportReview gọi đúng phương thức và đường dẫn', () async {
    final server = FakeServer({
      'DELETE /api/event-reviews/13': (_) => apiOk(null, message: 'Đã xóa review. Điểm của review này được thu lại.'),
      'POST /api/event-reviews/11/like': (_) => apiOk({'liked': true, 'likeCount': 8}),
      'DELETE /api/event-reviews/11/like': (_) => apiOk({'liked': false, 'likeCount': 7}),
      'POST /api/event-reviews/11/report': (_) => apiOk(null, message: 'Cảm ơn bạn. Báo cáo đã được gửi.'),
    });
    final dao = EventDao(server.api);

    expect(await dao.deleteReview(13), 'Đã xóa review. Điểm của review này được thu lại.');
    final liked = await dao.likeReview(11);
    expect(liked.liked, isTrue);
    expect(liked.likeCount, 8);
    final unliked = await dao.unlikeReview(11);
    expect(unliked.liked, isFalse);
    expect(unliked.likeCount, 7);

    expect(await dao.reportReview(11, reasonId: 4, note: '  quảng cáo  '), 'Cảm ơn bạn. Báo cáo đã được gửi.');
    expect(server.last('POST', '/api/event-reviews/11/report').data, {'reasonId': 4, 'note': 'quảng cáo'});
    await dao.reportReview(11, reasonId: 1);
    expect(server.last('POST', '/api/event-reviews/11/report').data, {'reasonId': 1, 'note': null});
  });

  test('likeReview review của chính mình → câu báo lỗi của server', () async {
    final server = FakeServer({
      'POST /api/event-reviews/10/like': (_) => apiError(400, 'Bạn không thể thích review của chính mình.'),
    });
    await expectLater(
      EventDao(server.api).likeReview(10),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Bạn không thể thích review của chính mình.')),
    );
  });

  test('EventReview.statusNote cho tác giả khi review chưa hiện với người khác', () {
    const review = EventReview(id: 1, rating: 3, status: EventReview.processing);
    expect(review.statusNote, contains('đang được quét'));
    expect(const EventReview(id: 1, rating: 3, status: EventReview.hidden).statusNote, contains('bị ẩn'));
    expect(const EventReview(id: 1, rating: 3, status: EventReview.rejected).statusNote, contains('chưa được đăng'));
  });

  test('Event một ngày và nhãn còn N ngày', () {
    final oneDay = Event(
      id: 1,
      title: 'A',
      startDate: DateTime(2026, 11, 10),
      endDate: DateTime(2026, 11, 10),
      daysUntil: 2,
    );
    expect(oneDay.isOneDay, isTrue);
    expect(oneDay.stateLabel, 'Còn 2 ngày');
  });
}
