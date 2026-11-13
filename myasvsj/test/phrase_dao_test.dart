// Test PhraseDao với server giả: JSON mẫu chép từ server thật (curl http://localhost:8080/api/phrases…).
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/phrase.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_dao.dart';

import 'fake_api.dart';

// GET /api/phrases/overview của user@gmail.com, rút gọn số chủ đề / địa điểm
final overviewJson = {
  'parts': [
    {
      'kind': 'PHRASE',
      'name': 'Mẫu câu',
      'icon': 'chat',
      'count': 29,
      'learned': 1,
      'topics': [
        {'id': 'ask', 'name': 'Hỏi đường, hỏi đồ', 'icon': 'help', 'count': 9, 'learned': 0},
        {'id': 'pay', 'name': 'Thanh toán', 'icon': 'payments', 'count': 7, 'learned': 1},
      ],
      'categories': [
        {'id': 'konbini', 'name': 'Cửa hàng tiện lợi', 'icon': 'local_convenience_store', 'count': 4, 'learned': 1},
        {'id': 'station', 'name': 'Ga tàu', 'icon': 'train', 'count': 3, 'learned': 0},
      ],
    },
    {
      'kind': 'VOCAB',
      'name': 'Từ vựng',
      'icon': 'abc',
      'count': 19,
      'learned': 0,
      'topics': [
        {'id': 'paper', 'name': 'Giấy tờ, thủ tục', 'icon': 'description', 'count': 5, 'learned': 0},
      ],
      'categories': [
        {'id': 'konbini', 'name': 'Cửa hàng tiện lợi', 'icon': 'local_convenience_store', 'count': 2, 'learned': 0},
      ],
    },
  ],
  'member': true,
  'reportReasons': [
    {'id': 5, 'label': 'Sai tiếng Nhật'},
    {'id': 6, 'label': 'Sai nghĩa'},
    {'id': 7, 'label': 'Xúc phạm'},
    {'id': 8, 'label': 'Spam'},
  ],
};

// Hai mục của GET /api/phrases?topic=pay
final listJson = [
  {
    'id': 14,
    'kind': 'PHRASE',
    'japanese': 'チャージしたいです。',
    'romaji': 'Chāji shitai desu.',
    'meaningVi': 'Tôi muốn nạp tiền vào thẻ IC.',
    'category': {'id': 'station', 'name': 'Ga tàu', 'icon': 'train'},
    'topics': [
      {'id': 'train', 'name': 'Đi tàu'},
      {'id': 'pay', 'name': 'Thanh toán'},
    ],
    'learning': true,
    'learned': false,
  },
  {
    'id': 6,
    'kind': 'VOCAB',
    'japanese': 'レジ',
    'romaji': 'reji',
    'meaningVi': 'Quầy thu ngân.',
    'category': {'id': 'konbini', 'name': 'Cửa hàng tiện lợi', 'icon': 'local_convenience_store'},
    'topics': [
      {'id': 'pay', 'name': 'Thanh toán'},
    ],
    'learning': false,
    'learned': true,
  },
];

void main() {
  test('findOverview đọc hai phần, chủ đề, địa điểm, cờ thành viên và lý do báo lỗi', () async {
    final server = FakeServer({'GET /api/phrases/overview': (_) => apiOk(overviewJson)});
    final overview = await PhraseDao(server.api).findOverview();

    expect(server.requests.single.method, 'GET');
    expect(overview.member, isTrue);
    expect(overview.parts.map((p) => p.kind), ['PHRASE', 'VOCAB']);
    final phrases = overview.part('PHRASE')!;
    expect(phrases.name, 'Mẫu câu');
    expect(phrases.icon, 'chat');
    expect(phrases.count, 29);
    expect(phrases.learned, 1);
    expect(phrases.topics.map((t) => t.id), ['ask', 'pay']);
    final payTopic = phrases.topics[1];
    expect([payTopic.name, payTopic.icon, payTopic.count, payTopic.learned], ['Thanh toán', 'payments', 7, 1]);
    final konbini = phrases.categories.first;
    expect(
      [konbini.id, konbini.name, konbini.icon, konbini.count],
      ['konbini', 'Cửa hàng tiện lợi', 'local_convenience_store', 4],
    );
    expect(overview.part('VOCAB')!.topics.single.name, 'Giấy tờ, thủ tục');
    expect(overview.reportReasons.map((r) => r.label), ['Sai tiếng Nhật', 'Sai nghĩa', 'Xúc phạm', 'Spam']);
    expect(overview.reportReasons.first.id, 5);
  });

  test('findAll gửi topic, category, mine, q và đọc đủ mọi trường của thẻ', () async {
    final server = FakeServer({'GET /api/phrases': (_) => apiOk(listJson)});
    final dao = PhraseDao(server.api);

    final list = await dao.findAll(topic: 'pay');
    expect(server.requests.last.uri.queryParameters, {'topic': 'pay'});
    expect(list.map((p) => p.id), [14, 6]);
    final charge = list.first;
    expect(charge.kind, Phrase.phraseKind);
    expect(charge.isPhrase, isTrue);
    expect(charge.japanese, 'チャージしたいです。');
    expect(charge.romaji, 'Chāji shitai desu.');
    expect(charge.meaningVi, 'Tôi muốn nạp tiền vào thẻ IC.');
    expect([charge.category.id, charge.category.name, charge.category.icon], ['station', 'Ga tàu', 'train']);
    expect(charge.topics.map((t) => t.name), ['Đi tàu', 'Thanh toán']);
    expect([charge.learning, charge.learned], [true, false]);
    expect(list[1].kind, Phrase.vocabKind);
    expect(list[1].learned, isTrue);

    await dao.findAll(category: 'konbini');
    expect(server.requests.last.uri.queryParameters, {'category': 'konbini'});
    await dao.findAll(mine: 'learning');
    expect(server.requests.last.uri.queryParameters, {'mine': 'learning'});
    await dao.findAll(q: '  thẻ IC ');
    expect(server.requests.last.uri.queryParameters, {'q': 'thẻ IC'});
  });

  test('findAll không lọc gì thì không gửi tham số, bỏ qua tham số rỗng', () async {
    final server = FakeServer({'GET /api/phrases': (_) => apiOk(<Object>[])});
    final dao = PhraseDao(server.api);

    expect(await dao.findAll(), isEmpty);
    expect(server.requests.last.uri.queryParameters, isEmpty);
    await dao.findAll(topic: '', category: '', mine: '', q: '   ');
    expect(server.requests.last.uri.queryParameters, isEmpty);
  });

  test(
    'findAll ném ApiException với câu của server khi danh sách không hợp lệ hoặc khách xem danh sách riêng',
    () async {
      final server = FakeServer({
        'GET /api/phrases': (req) => req.uri.queryParameters['mine'] == 'learning'
            ? apiError(401, 'Bạn cần đăng nhập để thực hiện thao tác này.')
            : apiError(400, 'Danh sách không hợp lệ.'),
      });
      final dao = PhraseDao(server.api);

      await expectLater(
        dao.findAll(mine: 'xyz'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Danh sách không hợp lệ.')),
      );
      await expectLater(
        dao.findAll(mine: 'learning'),
        throwsA(isA<ApiException>().having((e) => e.isUnauthorized, '401', isTrue)),
      );
    },
  );

  test('flash gửi POST {learned} và đọc dấu mới kèm câu của server', () async {
    final server = FakeServer({
      'POST /api/phrases/2/flash': (req) => (req.data as Map)['learned'] == true
          ? apiOk({'learning': false, 'learned': true}, message: 'Đã lưu: Đã thuộc.')
          : apiOk({'learning': true, 'learned': false}, message: 'Đã lưu: Chưa thuộc.'),
    });
    final dao = PhraseDao(server.api);

    final learned = await dao.flash(2, learned: true);
    expect(server.last('POST', '/api/phrases/2/flash').data, {'learned': true});
    expect(server.last('POST', '/api/phrases/2/flash').headers['X-XSRF-TOKEN'], 'csrf-test');
    expect([learned.learning, learned.learned, learned.message], [false, true, 'Đã lưu: Đã thuộc.']);

    final learning = await dao.flash(2, learned: false);
    expect(server.requests.last.data, {'learned': false});
    expect([learning.learning, learning.learned, learning.message], [true, false, 'Đã lưu: Chưa thuộc.']);
  });

  test('flash của khách (401 không có body) và mục không có (404) ném ApiException', () async {
    final server = FakeServer({
      'POST /api/phrases/2/flash': (_) => const FakeReply(401, null),
      'POST /api/phrases/99999/flash': (_) => apiError(404, 'Không tìm thấy mẫu câu này.'),
    });
    final dao = PhraseDao(server.api);

    await expectLater(
      dao.flash(2, learned: true),
      throwsA(isA<ApiException>().having((e) => e.isUnauthorized, '401', isTrue)),
    );
    await expectLater(
      dao.flash(99999, learned: true),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Không tìm thấy mẫu câu này.')),
    );
  });

  test('clearFlash gửi DELETE và đọc dấu đã bỏ', () async {
    final server = FakeServer({
      'DELETE /api/phrases/2/flash': (_) => apiOk({'learning': false, 'learned': false}, message: 'Đã bỏ đánh dấu.'),
    });
    final marks = await PhraseDao(server.api).clearFlash(2);

    expect(server.requests.single.method, 'DELETE');
    expect([marks.learning, marks.learned, marks.message], [false, false, 'Đã bỏ đánh dấu.']);
  });

  test('report gửi POST {reasonId, note} và trả câu thông báo của server', () async {
    final server = FakeServer({
      'POST /api/phrases/48/report': (_) =>
          apiOk(null, message: 'Đã gửi báo cáo cho Biên tập viên nội dung tiếng Nhật.'),
    });
    final message = await PhraseDao(server.api).report(48, reasonId: 6, note: 'Nghĩa chưa đúng');

    expect(server.last('POST', '/api/phrases/48/report').data, {'reasonId': 6, 'note': 'Nghĩa chưa đúng'});
    expect(message, 'Đã gửi báo cáo cho Biên tập viên nội dung tiếng Nhật.');
  });

  test('report ném ApiException khi đã báo cáo rồi (409) hoặc lý do sai (400 theo ô)', () async {
    final server = FakeServer({
      'POST /api/phrases/48/report': (_) => apiError(409, 'Bạn đã báo cáo nội dung này rồi.'),
      'POST /api/phrases/2/report': (_) =>
          apiError(400, 'Hãy chọn lý do báo cáo.', fields: {'reasonId': 'Hãy chọn lý do báo cáo.'}),
    });
    final dao = PhraseDao(server.api);

    await expectLater(
      dao.report(48, reasonId: 5),
      throwsA(
        isA<ApiException>()
            .having((e) => e.message, 'message', 'Bạn đã báo cáo nội dung này rồi.')
            .having((e) => e.statusCode, 'statusCode', 409),
      ),
    );
    await expectLater(
      dao.report(2, reasonId: 1),
      throwsA(isA<ApiException>().having((e) => e.fields['reasonId'], 'fields', 'Hãy chọn lý do báo cáo.')),
    );
  });
}
