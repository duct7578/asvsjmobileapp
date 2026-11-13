// Test ProfileDao với server giả: đúng phương thức, đường dẫn, tham số, body; đọc đúng JSON của web.
// JSON mẫu chép từ server thật (curl http://localhost:8080, tài khoản kouhai@gmail.com / user@gmail.com).
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/profile_dao.dart';
import 'package:myasvsj/com.myasvsj.model/tag_request.dart';

import 'fake_api.dart';

Map<String, dynamic> _json(String text) => jsonDecode(text) as Map<String, dynamic>;
List<dynamic> _list(String text) => jsonDecode(text) as List<dynamic>;

/// `GET /api/me/profile` của kouhai@gmail.com.
final profileJson = _json(r'''
{"id":7,"email":"kouhai@gmail.com","displayName":"Hoàng","avatarUrl":null,"role":"USER","roleLabel":"Người dùng",
 "points":130,"ranks":[{"name":"Người mới","minPoints":0,"featuredBonus":0},
 {"name":"Người chỉ đường","minPoints":100,"featuredBonus":5},{"name":"Senpai tin cậy","minPoints":300,"featuredBonus":10}],
 "tags":[{"name":"Kouhai","color":"#2E7D5B"}],"pendingTag":null,"areaId":679,
 "areaName":"Arakawa-ku, Tokyo · 東京都荒川区","stage":"ARR","createdAt":"2026-09-28T18:36:45Z","accountAgeDays":40,
 "newAccount":false,"newAccountDays":7,"today":{"posts":0,"maxPosts":3,"pins":0,"maxPins":2,"videos":0,"maxVideos":1},
 "reportMutedUntil":null,"hasPassword":true,"linkedProviders":[],"savedCount":4}
''');

/// `GET /api/areas/prefectures/13` (2 dòng đầu).
final tokyoAreasJson = _list(r'''
[{"id":662,"prefectureCode":"13","nameJa":"千代田区","nameEn":"Chiyoda-ku","name":"Chiyoda-ku, Tokyo · 東京都千代田区",
  "lat":35.694003,"lng":139.753634},
 {"id":663,"prefectureCode":"13","nameJa":"中央区","nameEn":"Chuo-ku","name":"Chuo-ku, Tokyo · 東京都中央区",
  "lat":35.670587,"lng":139.772003}]
''');

final arakawaJson = _json(r'''
{"id":679,"prefectureCode":"13","nameJa":"荒川区","nameEn":"Arakawa-ku","name":"Arakawa-ku, Tokyo · 東京都荒川区",
 "lat":35.736083,"lng":139.783372}
''');

/// `GET /api/me/interests` của user@gmail.com (rút gọn).
final interestsJson = _json(r'''
{"max":5,"topics":[{"id":1,"name":"Kinh nghiệm","chosen":false,"learnt":false},
 {"id":2,"name":"Cảnh báo lừa đảo","chosen":true,"learnt":false},
 {"id":11,"name":"Mua sắm","chosen":false,"learnt":true},
 {"id":12,"name":"Ngân hàng và tiền","chosen":false,"learnt":true}]}
''');

/// `GET /api/me/tag-requests/compose` của kouhai@gmail.com (rút gọn), thêm một yêu cầu đang chờ.
final composeJson = _json(r'''
{"tags":[{"id":1,"name":"Kouhai","description":"Đang học tại Nhật hoặc mới đến Nhật","color":"#2E7D5B",
  "selfieOnly":false,"proofTypes":[{"id":5,"name":"Thẻ sinh viên (学生証)"},
  {"id":6,"name":"Giấy chứng nhận đang học (在学証明書)"}],"owned":true},
 {"id":5,"name":"Người Nhật","description":"Người Nhật dùng Senpai ơi, chủ yếu là người quen của nhóm",
  "color":"#E8A33C","selfieOnly":true,"proofTypes":[{"id":10,"name":"Ảnh chân dung (selfie)"}],"owned":false}],
 "pending":{"tagName":"Mentor","submittedAt":"2026-11-07T18:52:22Z","expiresAt":"2026-11-21T18:52:22Z"},
 "keepDays":14,"photoMaxMb":20}
''');

void main() {
  group('Hồ sơ', () {
    test('findProfile đọc đủ trường của GET /api/me/profile', () async {
      final server = FakeServer({'GET /api/me/profile': (_) => apiOk(profileJson)});
      final profile = await ProfileDao(server.api).findProfile();

      expect(server.requests.single.method, 'GET');
      expect(profile.id, 7);
      expect(profile.email, 'kouhai@gmail.com');
      expect(profile.displayName, 'Hoàng');
      expect(profile.avatarUrl, isNull);
      expect(profile.isMember, isTrue);
      expect(profile.roleLabel, 'Người dùng');
      expect(profile.points, 130);
      expect(profile.ranks.map((r) => r.name), ['Người mới', 'Người chỉ đường', 'Senpai tin cậy']);
      expect(profile.ranks[1].featuredBonus, 5);
      expect(profile.currentRank?.name, 'Người chỉ đường');
      expect(profile.nextRank?.name, 'Senpai tin cậy');
      expect(profile.pointsToNextRank, 170);
      expect(profile.rankProgress, closeTo(0.15, 0.001));
      expect(profile.tags.single.name, 'Kouhai');
      expect(profile.tags.single.colorValue, 0xFF2E7D5B);
      expect(profile.pendingTag, isNull);
      expect(profile.areaId, 679);
      expect(profile.areaName, 'Arakawa-ku, Tokyo · 東京都荒川区');
      expect(profile.stage, 'ARR');
      expect(profile.createdAt, DateTime.utc(2026, 9, 28, 18, 36, 45).toLocal());
      expect(profile.accountAgeDays, 40);
      expect(profile.newAccount, isFalse);
      expect(profile.newAccountDays, 7);
      expect(profile.today.maxPosts, 3);
      expect(profile.today.maxPins, 2);
      expect(profile.today.maxVideos, 1);
      expect(profile.reportMutedUntil, isNull);
      expect(profile.hasPassword, isTrue);
      expect(profile.linkedProviders, isEmpty);
      expect(profile.savedCount, 4);
    });

    test('findProfile của khách ném ApiException 401', () async {
      final server = FakeServer({'GET /api/me/profile': (_) => const FakeReply(401, null)});
      await expectLater(
        ProfileDao(server.api).findProfile(),
        throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
      );
    });

    test('updateAreaStage gửi PUT {areaId, stage} và trả câu thông báo + hồ sơ mới', () async {
      final server = FakeServer({
        'PUT /api/me/profile': (_) =>
            apiOk({...profileJson, 'areaId': 662, 'stage': 'PRE'}, message: 'Đã lưu khu vực và giai đoạn.'),
      });
      final result = await ProfileDao(server.api).updateAreaStage(areaId: 662, stage: 'PRE');

      final request = server.last('PUT', '/api/me/profile');
      expect(request.data, {'areaId': 662, 'stage': 'PRE'});
      expect(request.headers['X-XSRF-TOKEN'], 'csrf-test');
      expect(result.message, 'Đã lưu khu vực và giai đoạn.');
      expect(result.profile.areaId, 662);
      expect(result.profile.stage, 'PRE');
    });

    test('updateAreaStage gửi null để bỏ chọn', () async {
      final server = FakeServer({'PUT /api/me/profile': (_) => apiOk(profileJson, message: 'OK')});
      await ProfileDao(server.api).updateAreaStage();
      expect(server.last('PUT', '/api/me/profile').data, {'areaId': null, 'stage': null});
    });

    test('updateAreaStage giữ lỗi theo ô của server', () async {
      final server = FakeServer({
        'PUT /api/me/profile': (_) =>
            apiError(400, 'Giai đoạn không hợp lệ', fields: {'stage': 'Giai đoạn không hợp lệ'}),
      });
      await expectLater(
        ProfileDao(server.api).updateAreaStage(stage: 'XX'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.fields['stage'], 'fields.stage', 'Giai đoạn không hợp lệ'),
        ),
      );
    });
  });

  group('Lịch sử điểm', () {
    test('findPointHistory gửi page và đọc {items, page, size, total, points}', () async {
      final server = FakeServer({
        'GET /api/me/points': (_) => apiOk({
          'items': [
            {
              'id': 31,
              'delta': 10,
              'reason': 'REVIEW_CREATED',
              'reasonLabel': 'Viết review',
              'title': 'Ga Nippori',
              'link': '/map?place=1',
              'createdAt': '2026-11-07T18:52:22Z',
            },
            {
              'id': 30,
              'delta': -20,
              'reason': 'CONTENT_REMOVED',
              'reasonLabel': 'Nội dung bị Moderator gỡ',
              'title': null,
              'link': null,
              'createdAt': '2026-11-06T10:00:00Z',
            },
          ],
          'page': 1,
          'size': 20,
          'total': 42,
          'points': 130,
        }),
      });
      final page = await ProfileDao(server.api).findPointHistory(page: 1);

      expect(server.last('GET', '/api/me/points').uri.queryParameters['page'], '1');
      expect(page.page, 1);
      expect(page.total, 42);
      expect(page.points, 130);
      expect(page.hasMore, isTrue);
      expect(page.items.first.delta, 10);
      expect(page.items.first.isPlus, isTrue);
      expect(page.items.first.reasonLabel, 'Viết review');
      expect(page.items.first.title, 'Ga Nippori');
      expect(page.items.first.link, '/map?place=1');
      expect(page.items.first.createdAt, DateTime.utc(2026, 11, 7, 18, 52, 22).toLocal());
      expect(page.items.last.delta, -20);
      expect(page.items.last.title, isNull);
      expect(page.items.last.link, isNull);
    });

    test('lịch sử rỗng (dữ liệu thật của user@gmail.com) không còn trang sau', () async {
      final server = FakeServer({
        'GET /api/me/points': (_) => apiOk({'items': [], 'page': 0, 'size': 20, 'total': 0, 'points': 40}),
      });
      final page = await ProfileDao(server.api).findPointHistory();
      expect(server.requests.single.uri.queryParameters['page'], '0');
      expect(page.items, isEmpty);
      expect(page.points, 40);
      expect(page.hasMore, isFalse);
    });
  });

  group('Khu vực', () {
    test('findAreaPicker đọc 47 tỉnh và vị trí thử (null ở server thật)', () async {
      final server = FakeServer({
        'GET /api/areas': (_) => apiOk(
          _json(r'''
          {"prefectures":[{"code":"01","nameJa":"北海道","nameEn":"Hokkaido","lat":43.063941,"lng":141.347907},
           {"code":"13","nameJa":"東京都","nameEn":"Tokyo","lat":35.689501,"lng":139.691722}],"devLocation":null}'''),
        ),
      });
      final picker = await ProfileDao(server.api).findAreaPicker();
      expect(picker.prefectures.map((p) => p.code), ['01', '13']);
      expect(picker.prefectures.last.label, 'Tokyo · 東京都');
      expect(picker.prefectures.first.lat, closeTo(43.06, 0.01));
      expect(picker.devLocation, isNull);
    });

    test('findAreaPicker đọc vị trí thử khi server có app.map.dev-location', () async {
      final server = FakeServer({
        'GET /api/areas': (_) => apiOk({
          'prefectures': [],
          'devLocation': {'lat': 35.7, 'lng': 139, 'label': 'Nippori'},
        }),
      });
      final picker = await ProfileDao(server.api).findAreaPicker();
      expect(picker.devLocation?.lat, 35.7);
      expect(picker.devLocation?.lng, 139.0);
      expect(picker.devLocation?.label, 'Nippori');
    });

    test('findAreasInPrefecture gọi /api/areas/prefectures/{code}', () async {
      final server = FakeServer({'GET /api/areas/prefectures/13': (_) => apiOk(tokyoAreasJson)});
      final areas = await ProfileDao(server.api).findAreasInPrefecture('13');
      expect(areas.map((a) => a.id), [662, 663]);
      expect(areas.first.prefectureCode, '13');
      expect(areas.first.nameEn, 'Chiyoda-ku');
      expect(areas.first.nameJa, '千代田区');
      expect(areas.first.name, 'Chiyoda-ku, Tokyo · 東京都千代田区');
      expect(areas.first.label, 'Chiyoda-ku · 千代田区');
      expect(areas.first.lat, closeTo(35.694, 0.001));
    });

    test('searchAreas gửi q và đọc danh sách', () async {
      final server = FakeServer({
        'GET /api/areas/search': (_) => apiOk([arakawaJson]),
      });
      final found = await ProfileDao(server.api).searchAreas('arakawa');
      expect(server.last('GET', '/api/areas/search').uri.queryParameters['q'], 'arakawa');
      expect(found.single.id, 679);
    });

    test('findNearestArea gửi lat, lng; vị trí ngoài Nhật nhận câu báo lỗi của server', () async {
      final server = FakeServer({
        'GET /api/areas/nearest': (request) => request.uri.queryParameters['lat'] == '35.736'
            ? apiOk(arakawaJson)
            : apiError(400, 'Vị trí này không ở Nhật Bản. Hãy chọn một điểm ở Nhật.'),
      });
      final dao = ProfileDao(server.api);
      final area = await dao.findNearestArea(35.736, 139.7834);
      expect(server.requests.first.uri.queryParameters['lng'], '139.7834');
      expect(area.nameEn, 'Arakawa-ku');

      await expectLater(
        dao.findNearestArea(21.03, 105.85),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('không ở Nhật Bản'))),
      );
    });

    test('findArea đọc một khu vực, không có thì 404', () async {
      final server = FakeServer({
        'GET /api/areas/679': (_) => apiOk(arakawaJson),
        'GET /api/areas/999999': (_) => apiError(404, 'Không tìm thấy khu vực này.'),
      });
      final dao = ProfileDao(server.api);
      expect((await dao.findArea(679)).name, 'Arakawa-ku, Tokyo · 東京都荒川区');
      await expectLater(
        dao.findArea(999999),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });

  group('Chủ đề quan tâm', () {
    test('findInterests đọc max, chosen, learnt', () async {
      final server = FakeServer({'GET /api/me/interests': (_) => apiOk(interestsJson)});
      final settings = await ProfileDao(server.api).findInterests();
      expect(settings.max, 5);
      expect(settings.topics, hasLength(4));
      expect(settings.chosen.map((t) => t.name), ['Cảnh báo lừa đảo']);
      expect(settings.topics.where((t) => t.learnt).map((t) => t.id), [11, 12]);
    });

    test('updateInterests gửi PUT {topicIds} và đọc danh sách mới', () async {
      final server = FakeServer({
        'PUT /api/me/interests': (_) => apiOk(interestsJson, message: 'Đã lưu chủ đề quan tâm.'),
      });
      final result = await ProfileDao(server.api).updateInterests([2, 5]);
      expect(server.last('PUT', '/api/me/interests').data, {
        'topicIds': [2, 5],
      });
      expect(result.message, 'Đã lưu chủ đề quan tâm.');
      expect(result.settings.chosen.single.id, 2);
    });

    test('updateInterests quá 5 chủ đề nhận câu báo lỗi của server', () async {
      final server = FakeServer({'PUT /api/me/interests': (_) => apiError(400, 'Bạn chọn được tối đa 5 chủ đề.')});
      await expectLater(
        ProfileDao(server.api).updateInterests([1, 2, 3, 4, 5, 6]),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Bạn chọn được tối đa 5 chủ đề.')),
      );
    });
  });

  group('Tag định danh', () {
    test('findTagCompose đọc tag, loại minh chứng, yêu cầu đang chờ', () async {
      final server = FakeServer({'GET /api/me/tag-requests/compose': (_) => apiOk(composeJson)});
      final compose = await ProfileDao(server.api).findTagCompose();
      expect(compose.tags.map((t) => t.name), ['Kouhai', 'Người Nhật']);
      expect(compose.tags.first.owned, isTrue);
      expect(compose.tags.first.color, '#2E7D5B');
      expect(compose.tags.first.proofTypes.map((p) => p.id), [5, 6]);
      expect(compose.tags.last.selfieOnly, isTrue);
      expect(compose.pending?.tagName, 'Mentor');
      expect(compose.pending?.submittedAt, DateTime.utc(2026, 11, 7, 18, 52, 22).toLocal());
      expect(compose.pending?.expiresAt, DateTime.utc(2026, 11, 21, 18, 52, 22).toLocal());
      expect(compose.keepDays, 14);
      expect(compose.photoMaxMb, 20);
    });

    test('compose không có yêu cầu chờ thì pending là null', () async {
      final server = FakeServer({
        'GET /api/me/tag-requests/compose': (_) => apiOk({...composeJson, 'pending': null}),
      });
      expect((await ProfileDao(server.api).findTagCompose()).pending, isNull);
    });

    test('submitTagRequest gửi multipart: phần JSON "request" và ảnh "photo"', () async {
      final dir = Directory.systemTemp.createTempSync('profile_dao_test');
      final photo = File('${dir.path}/profile_dao_test_proof.jpg')..writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xD9]);
      addTearDown(() {
        // Server giả không đọc luồng file nên Windows có thể còn giữ file: bỏ qua nếu chưa xóa được
        try {
          dir.deleteSync(recursive: true);
        } on FileSystemException {
          // thư mục tạm của hệ điều hành sẽ tự dọn
        }
      });
      final server = FakeServer({
        'POST /api/me/tag-requests': (_) => apiOk({
          'message': 'Đã gửi yêu cầu tag.',
          'pending': {'tagName': 'Mentor', 'submittedAt': '2026-11-08T01:00:00Z', 'expiresAt': '2026-11-22T01:00:00Z'},
        }, message: 'Đã gửi yêu cầu tag.'),
      });
      final result = await ProfileDao(
        server.api,
      ).submitTagRequest(TagRequest(tagId: 2, proofTypeId: 7, consent: true, photoPath: photo.path));

      final request = server.last('POST', '/api/me/tag-requests');
      final form = request.data as FormData;
      expect(form.files.map((e) => e.key), ['request', 'photo']);
      final json = form.files.firstWhere((e) => e.key == 'request').value;
      expect(json.contentType?.mimeType, 'application/json');
      final bytes = await json.clone().finalize().expand((chunk) => chunk).toList();
      expect(jsonDecode(utf8.decode(bytes)), {'tagId': 2, 'proofTypeId': 7, 'consent': true});
      final file = form.files.firstWhere((e) => e.key == 'photo').value;
      expect(file.filename, 'profile_dao_test_proof.jpg');
      expect(file.contentType?.mimeType, 'image/jpeg');

      expect(result.message, 'Đã gửi yêu cầu tag.');
      expect(result.pending?.tagName, 'Mentor');
    });

    test('submitTagRequest không ảnh thì không có phần "photo"; lỗi theo ô của server', () async {
      final server = FakeServer({
        'POST /api/me/tag-requests': (_) => apiError(
          400,
          'Hãy chọn ảnh minh chứng.',
          fields: {'photo': 'Hãy chọn ảnh minh chứng.', 'consent': 'Bạn cần đồng ý cho Kiểm duyệt viên xem ảnh.'},
        ),
      });
      await expectLater(
        ProfileDao(server.api).submitTagRequest(const TagRequest(tagId: 2, proofTypeId: 7)),
        throwsA(
          isA<ApiException>()
              .having((e) => e.fields.keys, 'fields', containsAll(['photo', 'consent']))
              .having((e) => e.message, 'message', 'Hãy chọn ảnh minh chứng.'),
        ),
      );
      final form = server.last('POST', '/api/me/tag-requests').data as FormData;
      expect(form.files.map((e) => e.key), ['request']);
    });

    test('đang có yêu cầu chờ duyệt thì server trả 409', () async {
      final server = FakeServer({
        'POST /api/me/tag-requests': (_) => apiError(409, 'Bạn đang có một yêu cầu tag chờ duyệt.'),
      });
      await expectLater(
        ProfileDao(server.api).submitTagRequest(const TagRequest(tagId: 2, proofTypeId: 7, consent: true)),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409)),
      );
    });
  });
}
