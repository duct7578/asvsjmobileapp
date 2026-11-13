// Test BlogDao với server giả (fake_api.dart): JSON mẫu chép từ server thật (curl tới http://localhost:8080),
// kiểm tra DAO gọi đúng phương thức, đường dẫn, tham số, body, đọc đúng mọi trường và ném ApiException khi lỗi.
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/blog.dart';
import 'package:myasvsj/com.myasvsj.model/blog_dao.dart';
import 'package:myasvsj/com.myasvsj.model/blog_place.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.model/topic.dart';

import 'fake_api.dart';

/// Phần `data` của một câu trả lời thật của server.
Map<String, dynamic> data(String body) => (jsonDecode(body) as Map<String, dynamic>)['data'] as Map<String, dynamic>;

// GET /api/blogs?size=2 (khách)
final pageJson = data(r'''
{"success":true,"message":"OK","data":{"items":[{"id":1,"type":"POST","status":"PUBLISHED","pinned":true,"answered":false,"title":"Năm điều mình ước biết trước tuần đầu ở Tokyo","excerpt":"Mua thẻ IC đi tàu ngay ở ga đầu tiên, vì gần như mọi tuyến đều dùng được. Đăng ký cư trú tại văn phòng quận trong 14 ngày kể từ khi có chỗ ở. Mang sẵn tiền mặt: nhiều quán nhỏ…","author":{"id":6,"displayName":"Lan Anh","avatarUrl":null,"tags":[{"name":"Mentor","color":"#C2456E"}]},"topics":[{"id":1,"name":"Kinh nghiệm"},{"id":3,"name":"Thủ tục giấy tờ"},{"id":8,"name":"Đi lại"}],"places":[{"id":1,"name":"Ga Nippori","category":"Ga tàu","address":"Higashi-Nippori 6, Arakawa, Tokyo","lat":35.72892,"lng":139.771364,"osmId":"N772389775"},{"id":6,"name":"Văn phòng quận Arakawa","category":"Văn phòng quận","address":"Arakawa, Tokyo","lat":35.736,"lng":139.7834,"osmId":null}],"likeCount":24,"commentCount":0,"createdAt":"2026-10-20T18:36:45Z"},{"id":3,"type":"POST","status":"PROCESSING","pinned":false,"answered":false,"title":"Hai quán ăn dưới 1.000 yên quanh Nippori","excerpt":"Quán cơm Hana: cơm phần 700 yên, chủ quán hiểu tiếng Việt cơ bản. Ramen Aoba: ramen shoyu khoảng 950 yên, mua vé ở máy trước khi ngồi.","author":{"id":7,"displayName":"Hoàng","avatarUrl":null,"tags":[{"name":"Kouhai","color":"#2E7D5B"}]},"topics":[{"id":7,"name":"Ăn uống"}],"places":[],"likeCount":15,"commentCount":0,"createdAt":"2026-11-03T18:36:45Z"}],"page":0,"size":2,"totalItems":5,"totalPages":3,"filtered":false},"timestamp":"2026-11-07T18:51:35.923110600Z"}
''');

// GET /api/blogs/overview (rút bớt danh sách chủ đề)
final overviewJson = data(r'''
{"success":true,"message":"OK","data":{"featured":{"period":"WEEK","posts":[{"id":3,"type":"POST","status":"PUBLISHED","pinned":false,"answered":false,"title":"Hai quán ăn dưới 1.000 yên quanh Nippori","excerpt":"Quán cơm Hana: cơm phần 700 yên, chủ quán hiểu tiếng Việt cơ bản.","author":{"id":7,"displayName":"Hoàng","avatarUrl":null,"tags":[{"name":"Kouhai","color":"#2E7D5B"}]},"topics":[{"id":7,"name":"Ăn uống"}],"places":[{"id":4,"name":"Quán cơm Hana","category":"Quán ăn","address":"Ghim do cộng đồng thêm","lat":35.7267,"lng":139.7735,"osmId":null}],"likeCount":15,"commentCount":0,"createdAt":"2026-11-03T18:36:45Z"}]},"topics":[{"id":1,"name":"Kinh nghiệm"},{"id":2,"name":"Cảnh báo lừa đảo"},{"id":14,"name":"Khác"}],"popularTopics":[{"id":1,"name":"Kinh nghiệm","postCount":2},{"id":3,"name":"Thủ tục giấy tờ","postCount":2}],"topWriters":[{"author":{"id":7,"displayName":"Hoàng","avatarUrl":null,"tags":[{"name":"Kouhai","color":"#2E7D5B"}]},"postCount":2},{"author":{"id":6,"displayName":"Lan Anh","avatarUrl":null,"tags":[{"name":"Mentor","color":"#C2456E"}]},"postCount":2}],"topWritersDays":30},"timestamp":"2026-11-07T18:51:35.997943300Z"}
''');

// GET /api/blogs/7 (user@gmail.com xem bài của Hoàng: bình luận gốc đã xóa còn câu trả lời)
final detailJson = data(r'''
{"success":true,"message":"OK","data":{"id":7,"type":"POST","status":"PUBLISHED","pinned":false,"edited":true,"title":"[Thử app] Bài thử có ảnh của agent blog (sửa)","content":"Nội dung bài thử để kiểm tra app mobile, sẽ xóa ngay.","author":{"id":7,"displayName":"Hoàng","avatarUrl":null,"tags":[{"name":"Kouhai","color":"#2E7D5B"}],"rankName":"Người chỉ đường"},"topics":[{"id":1,"name":"Kinh nghiệm"},{"id":14,"name":"Khác"}],"places":[{"id":1,"name":"Ga Nippori","category":"Ga tàu","address":"Higashi-Nippori 6, Arakawa, Tokyo","lat":35.72892,"lng":139.771364,"osmId":"N772389775"}],"media":[{"id":17,"type":"IMAGE","url":"/media/blog/2026/11/7fd52c0d-dc6c-4f69-bdb6-dc974a6f5527.jpg","mimeType":"image/jpeg","width":120,"height":80},{"id":21,"type":"IMAGE","url":"/media/blog/2026/11/6d6d1a5e-e043-458b-bf75-cf7b18105e85.jpg","mimeType":"image/jpeg","width":120,"height":80}],"likeCount":0,"commentCount":1,"bestCommentId":null,"createdAt":"2026-11-07T18:52:10Z","viewer":{"signedIn":true,"author":false,"canInteract":true,"liked":false,"saved":true},"comments":[{"id":1,"parentId":null,"author":null,"content":"","edited":false,"removed":true,"best":false,"mine":false,"liked":false,"likeCount":0,"createdAt":"2026-11-07T18:52:24Z","replies":[{"id":4,"parentId":1,"author":{"id":7,"displayName":"Hoàng","avatarUrl":null,"tags":[{"name":"Kouhai","color":"#2E7D5B"}],"rankName":"Người chỉ đường"},"content":"Trả lời thử","edited":true,"removed":false,"best":false,"mine":false,"liked":true,"likeCount":1,"createdAt":"2026-11-07T18:52:54Z","replies":[]}]}],"reportReasons":[{"id":1,"label":"Lừa đảo"},{"id":2,"label":"Sai sự thật"},{"id":3,"label":"Xúc phạm"},{"id":4,"label":"Spam"}]},"timestamp":"2026-11-07T19:06:18.693218600Z"}
''');

// GET /api/blogs/7/edit (kouhai@gmail.com, rút bớt danh sách chủ đề)
final editJson = data(r'''
{"success":true,"message":"OK","data":{"id":7,"type":"POST","status":"PUBLISHED","title":"[Thử app] Bài thử có ảnh của agent blog (sửa)","content":"Nội dung bài thử để kiểm tra app mobile, sẽ xóa ngay.","topicIds":[1,14],"places":[{"id":1,"name":"Ga Nippori","category":"Ga tàu","address":"Higashi-Nippori 6, Arakawa, Tokyo","lat":35.72892,"lng":139.771364,"osmId":"N772389775"}],"media":[{"id":17,"type":"IMAGE","url":"/media/blog/2026/11/7fd52c0d-dc6c-4f69-bdb6-dc974a6f5527.jpg","scanStatus":"PASSED","sortOrder":0},{"id":21,"type":"IMAGE","url":"/media/blog/2026/11/6d6d1a5e-e043-458b-bf75-cf7b18105e85.jpg","scanStatus":"PASSED","sortOrder":1}],"options":{"topics":[{"id":1,"name":"Kinh nghiệm","other":false,"scamWarning":false},{"id":2,"name":"Cảnh báo lừa đảo","other":false,"scamWarning":true},{"id":14,"name":"Khác","other":true,"scamWarning":false}],"limits":{"titleMax":150,"contentMax":5000,"topicsMax":3,"placesMax":5,"imagesMax":5,"imageMaxMb":20,"videosMax":1,"videoMaxSeconds":30,"videoMaxMb":50,"questionContentRequired":false},"quota":{"newAccount":false,"newAccountDays":7,"accountAgeDays":40,"postsUsed":1,"postsLimit":3,"pinsUsed":0,"pinsLimit":2,"videosUsed":0,"videosLimit":1},"canPostLinks":true}},"timestamp":"2026-11-07T18:52:13.621742400Z"}
''');

// GET /api/blogs/compose (rút bớt chủ đề; quota sửa thành tài khoản mới để kiểm tra đọc trường)
final composeJson = data(r'''
{"success":true,"message":"OK","data":{"topics":[{"id":1,"name":"Kinh nghiệm","other":false,"scamWarning":false},{"id":2,"name":"Cảnh báo lừa đảo","other":false,"scamWarning":true},{"id":14,"name":"Khác","other":true,"scamWarning":false}],"limits":{"titleMax":150,"contentMax":5000,"topicsMax":3,"placesMax":5,"imagesMax":5,"imageMaxMb":20,"videosMax":1,"videoMaxSeconds":30,"videoMaxMb":50,"questionContentRequired":false},"quota":{"newAccount":true,"newAccountDays":7,"accountAgeDays":2,"postsUsed":3,"postsLimit":3,"pinsUsed":0,"pinsLimit":2,"videosUsed":0,"videosLimit":1},"canPostLinks":false},"timestamp":"2026-11-07T18:51:51.332479800Z"}
''');

// GET /api/places/search?q=nippori (rút bớt) + một địa điểm OpenStreetMap chưa có trên Senpai ơi
final placesJson = data(r'''
{"success":true,"message":"OK","data":{"items":[{"id":8,"externalId":null,"name":"Bưu điện Nippori","nameJa":"日暮里郵便局","category":"Bưu điện và ngân hàng","address":"Higashi-Nippori 4","source":"TEAM","lat":35.7254,"lng":139.7718},{"id":null,"externalId":"N2000000001","name":"Ga Ueno","nameJa":"上野駅","category":"Ga tàu","address":"Taito, Tokyo","source":"OSM","lat":35.7138,"lng":139.7773}],"external":"ON","externalReason":null},"timestamp":"2026-11-07T18:51:55.548700800Z"}
''');

/// Đọc phần JSON [name] của một request multipart.
Future<Map<String, dynamic>> jsonPart(RequestOptions request, String name) async {
  final form = request.data as FormData;
  final part = form.files.firstWhere((e) => e.key == name).value.clone();
  final bytes = await part.finalize().fold<List<int>>([], (all, chunk) => all..addAll(chunk));
  return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
}

void main() {
  late Directory tmp;
  late String photo;

  setUpAll(() {
    tmp = Directory.systemTemp.createTempSync('blog_dao_test');
    photo = '${tmp.path}${Platform.pathSeparator}anh-1.jpg';
    File(photo).writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xD9]);
  });

  tearDownAll(() => tmp.deleteSync(recursive: true));

  group('đọc', () {
    test('findAll gửi từ khóa, chủ đề, sắp xếp, trang và đọc thẻ bài', () async {
      final server = FakeServer({'GET /api/blogs': (_) => apiOk(pageJson)});
      final page = await BlogDao(server.api).findAll(q: 'nippori', topicIds: [7, 2], sort: 'LIKES', page: 1);

      final query = server.last('GET', '/api/blogs').uri.queryParameters;
      expect(query, {'q': 'nippori', 'topicIds': '7,2', 'sort': 'LIKES', 'page': '1', 'size': '10'});
      expect(page.totalItems, 5);
      expect(page.hasMore, isTrue);
      final first = page.items.first;
      expect(first.id, 1);
      expect(first.title, 'Năm điều mình ước biết trước tuần đầu ở Tokyo');
      expect(first.content, startsWith('Mua thẻ IC đi tàu'));
      expect(first.pinned, isTrue);
      expect(first.author?.displayName, 'Lan Anh');
      expect(first.author?.tagNames, ['Mentor']);
      expect(first.topicNames, ['Kinh nghiệm', 'Thủ tục giấy tờ', 'Đi lại']);
      expect(first.places.first.name, 'Ga Nippori');
      expect(first.places.first.lat, 35.72892);
      expect(first.places.last.externalId, isNull);
      expect(first.likeCount, 24);
      expect(first.createdAt, DateTime.utc(2026, 10, 20, 18, 36, 45).toLocal());
      expect(page.items.last.isProcessing, isTrue);
    });

    test('findAll không gửi từ khóa và chủ đề khi không lọc', () async {
      final server = FakeServer({'GET /api/blogs': (_) => apiOk(pageJson)});
      await BlogDao(server.api).findAll();
      expect(server.requests.single.uri.queryParameters, {'sort': 'NEWEST', 'page': '0', 'size': '10'});
    });

    test('findOverview đọc bài nổi bật, chủ đề, thống kê', () async {
      final server = FakeServer({'GET /api/blogs/overview': (_) => apiOk(overviewJson)});
      final overview = await BlogDao(server.api).findOverview();
      expect(overview.featuredPeriod, 'WEEK');
      expect(overview.featured.single.title, 'Hai quán ăn dưới 1.000 yên quanh Nippori');
      expect(overview.topics.map((t) => t.name), ['Kinh nghiệm', 'Cảnh báo lừa đảo', 'Khác']);
      expect(overview.popularTopics.first.postCount, 2);
      expect(overview.topWriters.first.author.displayName, 'Hoàng');
      expect(overview.topWriters.first.postCount, 2);
      expect(overview.topWritersDays, 30);
    });

    test('findOverview khi chưa có bài nổi bật (period null)', () async {
      final server = FakeServer({
        'GET /api/blogs/overview': (_) => apiOk({
          'featured': {'period': null, 'posts': []},
          'topics': [],
          'popularTopics': [],
          'topWriters': [],
          'topWritersDays': 30,
        }),
      });
      final overview = await BlogDao(server.api).findOverview();
      expect(overview.featuredPeriod, isNull);
      expect(overview.featured, isEmpty);
    });

    test('findById đọc ảnh, cờ người xem, cây bình luận, lý do báo cáo', () async {
      final server = FakeServer({'GET /api/blogs/7': (_) => apiOk(detailJson)});
      final blog = await BlogDao(server.api).findById(7);
      expect(blog.edited, isTrue);
      expect(blog.author?.rankName, 'Người chỉ đường');
      expect(blog.media.map((m) => m.id), [17, 21]);
      expect(blog.images.first.width, 120);
      expect(blog.media.first.url, startsWith('/media/blog/'));
      expect(blog.isSignedIn, isTrue);
      expect(blog.canInteract, isTrue);
      expect(blog.isMine, isFalse);
      expect(blog.isLiked, isFalse);
      expect(blog.isSaved, isTrue);
      final removed = blog.comments.single;
      expect(removed.removed, isTrue);
      expect(removed.author, isNull);
      final reply = removed.replies.single;
      expect(reply.parentId, 1);
      expect(reply.content, 'Trả lời thử');
      expect(reply.author?.displayName, 'Hoàng');
      expect(reply.edited, isTrue);
      expect(reply.liked, isTrue);
      expect(reply.likeCount, 1);
      expect(blog.reportReasons.map((r) => r.label), ['Lừa đảo', 'Sai sự thật', 'Xúc phạm', 'Spam']);
    });

    test('findComposeOptions đọc giới hạn, lượt đăng tài khoản mới, quyền chèn link', () async {
      final server = FakeServer({'GET /api/blogs/compose': (_) => apiOk(composeJson)});
      final options = await BlogDao(server.api).findComposeOptions();
      expect(options.topics.map((t) => t.id), [1, 2, 14]);
      expect(options.scamWarningTopicIds, {2});
      expect(options.titleMax, 150);
      expect(options.placesMax, 5);
      expect(options.imagesMax, 5);
      expect(options.imageMaxMb, 20);
      expect(options.newAccount, isTrue);
      expect(options.quotaFull, isTrue);
      expect(options.canPostLinks, isFalse);
    });

    test('findForEdit đọc bài như đang lưu, tên chủ đề lấy từ options', () async {
      final server = FakeServer({'GET /api/blogs/7/edit': (_) => apiOk(editJson)});
      final blog = await BlogDao(server.api).findForEdit(7);
      expect(blog.id, 7);
      expect(blog.isMine, isTrue);
      expect(blog.topicIds, [1, 14]);
      expect(blog.topicNames, ['Kinh nghiệm', 'Khác']);
      expect(blog.places.single.id, 1);
      expect(blog.media.map((m) => m.id), [17, 21]);
      expect(blog.toJson()['keepMediaIds'], [17, 21]);
    });

    test('searchPlaces gửi q và đọc địa điểm OpenStreetMap chưa có id', () async {
      final server = FakeServer({'GET /api/places/search': (_) => apiOk(placesJson)});
      final places = await BlogDao(server.api).searchPlaces('nippori');
      expect(server.requests.single.uri.queryParameters, {'q': 'nippori'});
      expect(places.first.id, 8);
      expect(places.first.nameJa, '日暮里郵便局');
      expect(places.first.detail, 'Bưu điện và ngân hàng · Higashi-Nippori 4');
      expect(places.last.isNew, isTrue);
      expect(places.last.externalId, 'N2000000001');
      expect(places.last.key, 'mN2000000001');
      expect(places.last.directionsUrl, 'https://www.google.com/maps/dir/?api=1&destination=35.7138%2C139.7773');
    });
  });

  group('ghi', () {
    const draft = Blog(
      title: 'Bài thử',
      content: 'Nội dung',
      topics: [Topic(id: 14, name: 'Khác')],
      places: [
        BlogPlace(id: 1, name: 'Ga Nippori'),
        BlogPlace(externalId: 'N2000000001', name: 'Ga Ueno'),
      ],
    );

    test('create gửi multipart: phần "post" là JSON, ảnh ở phần "images"', () async {
      final server = FakeServer({
        'POST /api/blogs': (_) => apiOk({
          'id': 9,
          'type': 'POST',
          'status': 'PROCESSING',
        }, message: 'Đã gửi. Ảnh và video đang được quét, trong lúc này chỉ bạn thấy bài.'),
      });
      final saved = await BlogDao(server.api).create(draft, imagePaths: [photo]);

      final request = server.last('POST', '/api/blogs');
      final form = request.data as FormData;
      expect(form.files.map((e) => e.key), ['post', 'images']);
      expect(form.files.last.value.filename, 'anh-1.jpg');
      expect(request.headers['X-XSRF-TOKEN'], 'csrf-test');
      expect(await jsonPart(request, 'post'), {
        'title': 'Bài thử',
        'content': 'Nội dung',
        'topicIds': [14],
        'placeIds': [1],
        'externalPlaceIds': ['N2000000001'],
      });
      expect(saved.id, 9);
      expect(saved.status, 'PROCESSING');
      expect(saved.message, startsWith('Đã gửi.'));
    });

    test('update gửi PUT multipart kèm keepMediaIds', () async {
      final server = FakeServer({
        'PUT /api/blogs/7': (_) => apiOk({'id': 7, 'type': 'POST', 'status': 'PUBLISHED'}, message: 'Đã lưu thay đổi.'),
      });
      const edited = Blog(
        id: 7,
        title: 'Bài thử (sửa)',
        content: 'Nội dung',
        topics: [Topic(id: 1, name: 'Kinh nghiệm')],
        media: [MediaItem(id: 17, type: 'IMAGE', url: '/media/a.jpg')],
      );
      final saved = await BlogDao(server.api).update(edited);
      final request = server.last('PUT', '/api/blogs/7');
      expect((request.data as FormData).files.map((e) => e.key), ['post']);
      expect((await jsonPart(request, 'post'))['keepMediaIds'], [17]);
      expect(saved.message, 'Đã lưu thay đổi.');
    });

    test('create lỗi nhập trả lỗi theo ô', () async {
      final server = FakeServer({
        'POST /api/blogs': (_) => apiError(
          400,
          'Hãy nhập tiêu đề và nội dung cho bài viết.',
          fields: {'title': 'Hãy nhập tiêu đề.', 'content': 'Hãy nhập nội dung bài viết.'},
        ),
      });
      await expectLater(
        BlogDao(server.api).create(draft),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Hãy nhập tiêu đề và nội dung cho bài viết.')
              .having((e) => e.fields['title'], 'fields.title', 'Hãy nhập tiêu đề.'),
        ),
      );
    });

    test('delete, like, unlike, save, unsave gọi đúng đường dẫn', () async {
      final server = FakeServer({
        'DELETE /api/blogs/7': (_) => apiOk(null, message: 'Đã xóa bài viết.'),
        'POST /api/blogs/7/like': (_) => apiOk({'active': true, 'count': 1}),
        'DELETE /api/blogs/7/like': (_) => apiOk({'active': false, 'count': 0}),
        'POST /api/blogs/7/save': (_) => apiOk({'saved': true}, message: 'Đã lưu bài viết.'),
        'DELETE /api/blogs/7/save': (_) => apiOk({'saved': false}, message: 'Đã bỏ lưu bài viết.'),
      });
      final dao = BlogDao(server.api);
      expect(await dao.like(7), (active: true, count: 1));
      expect(await dao.unlike(7), (active: false, count: 0));
      expect(await dao.save(7), 'Đã lưu bài viết.');
      expect(await dao.unsave(7), 'Đã bỏ lưu bài viết.');
      expect(await dao.delete(7), 'Đã xóa bài viết.');
      expect(server.requests.map((r) => '${r.method} ${r.uri.path}'), [
        'POST /api/blogs/7/like',
        'DELETE /api/blogs/7/like',
        'POST /api/blogs/7/save',
        'DELETE /api/blogs/7/save',
        'DELETE /api/blogs/7',
      ]);
    });

    test('report gửi reasonId và note (note trống thành null)', () async {
      final server = FakeServer({
        'POST /api/blogs/7/report': (_) => apiOk(null, message: 'Cảm ơn bạn. Báo cáo đã được gửi.'),
      });
      final dao = BlogDao(server.api);
      expect(await dao.report(7, reasonId: 4, note: ' spam '), 'Cảm ơn bạn. Báo cáo đã được gửi.');
      expect(server.requests.last.data, {'reasonId': 4, 'note': 'spam'});
      await dao.report(7, reasonId: 1);
      expect(server.requests.last.data, {'reasonId': 1, 'note': null});
    });

    test('like bài của chính mình: ApiException mang câu của server', () async {
      final server = FakeServer({
        'POST /api/blogs/7/like': (_) => apiError(400, 'Bạn không thể thích bài viết của chính mình.'),
      });
      await expectLater(
        BlogDao(server.api).like(7),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'Bạn không thể thích bài viết của chính mình.')
              .having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });
  });

  group('bình luận', () {
    test('addComment gửi content và parentId, nhận lại cả bài', () async {
      final server = FakeServer({
        'POST /api/blogs/7/comments': (_) => apiOk(detailJson, message: 'Đã đăng bình luận.'),
      });
      final result = await BlogDao(server.api).addComment(7, 'Trả lời thử', parentId: 1);
      expect(server.requests.single.data, {'content': 'Trả lời thử', 'parentId': 1});
      expect(result.message, 'Đã đăng bình luận.');
      expect(result.blog?.comments.single.replies.single.id, 4);
    });

    test('addComment quá nhanh: 429 với câu của server', () async {
      final server = FakeServer({
        'POST /api/blogs/7/comments': (_) => apiError(429, 'Bạn bình luận hơi nhanh. Vui lòng đợi 7 giây rồi thử lại.'),
      });
      await expectLater(
        BlogDao(server.api).addComment(7, 'Nhanh quá'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 429)
              .having((e) => e.message, 'message', 'Bạn bình luận hơi nhanh. Vui lòng đợi 7 giây rồi thử lại.'),
        ),
      );
      expect(server.requests.single.data, {'content': 'Nhanh quá', 'parentId': null});
    });

    test('updateComment, deleteComment, likeComment, unlikeComment, reportComment', () async {
      final server = FakeServer({
        'PUT /api/comments/4': (_) => apiOk(detailJson, message: 'Đã lưu bình luận.'),
        'DELETE /api/comments/4': (_) => apiOk(null, message: 'Đã xóa bình luận.'),
        'POST /api/comments/4/like': (_) => apiOk({'active': true, 'count': 1}),
        'DELETE /api/comments/4/like': (_) => apiOk({'active': false, 'count': 0}),
        'POST /api/comments/4/report': (_) => apiOk(detailJson, message: 'Cảm ơn bạn. Báo cáo đã được gửi.'),
      });
      final dao = BlogDao(server.api);

      final updated = await dao.updateComment(4, 'Đã sửa');
      expect(server.requests.last.data, {'content': 'Đã sửa'});
      expect(updated.message, 'Đã lưu bình luận.');
      expect(updated.blog?.id, 7);

      // Xóa xong mà bài không còn xem được: server trả data null
      final deleted = await dao.deleteComment(4);
      expect(deleted.blog, isNull);
      expect(deleted.message, 'Đã xóa bình luận.');

      expect(await dao.likeComment(4), (active: true, count: 1));
      expect(await dao.unlikeComment(4), (active: false, count: 0));

      final reported = await dao.reportComment(4, reasonId: 4);
      expect(server.requests.last.data, {'reasonId': 4, 'note': null});
      expect(reported.blog?.id, 7);
    });

    test('findById bài không còn: 404 MSG19', () async {
      final server = FakeServer({
        'GET /api/blogs/99': (_) =>
            apiError(404, 'Không tìm thấy nội dung bạn yêu cầu. Bài viết có thể đã bị gỡ hoặc đã bị xóa.'),
      });
      await expectLater(
        BlogDao(server.api).findById(99),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });
}
