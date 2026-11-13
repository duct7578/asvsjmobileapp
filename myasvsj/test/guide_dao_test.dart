// Test GuideDao với server giả: JSON chép từ server thật (curl http://localhost:8080, dữ liệu mẫu ngày 8/11/2026).
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/guide_dao.dart';
import 'package:myasvsj/com.myasvsj.model/guide_preparation.dart';
import 'package:myasvsj/com.myasvsj.model/guide_progress.dart';
import 'package:myasvsj/com.myasvsj.model/guide_task.dart';

import 'fake_api.dart';

const _browseJson = {
  'items': [
    {
      'id': 24,
      'title': 'Cách phân loại và bỏ rác tại Nhật Bản – hướng dẫn chi tiết cho người Việt',
      'summary': 'Phân loại và bỏ rác đúng quy định là một trong những điều quan trọng bậc nhất.',
      'category': 'ARR',
      'topicName': 'Sinh hoạt',
      'published': true,
      'createdBy': 1,
      'creatorName': 'Dữ liệu mẫu',
      'createdAt': '2026-11-07T18:36:40Z',
      'sections': [],
      'stageName': 'Khi mới đến (tuần đầu đến 3 tháng)',
      'topicCode': 'LIVING',
      'sourceUrl': null,
      'coverImageUrl': '/media/guide/2026/11/289eb8b6-c878-4b29-a610-b1baa0758d7e.jpg',
      'status': 'PUBLISHED',
      'preparationEnabled': false,
      'preparationTasks': [],
    },
    {
      'id': 23,
      'title': 'Hướng dẫn sử dụng tàu điện Nhật Bản cho người mới',
      'summary': '',
      'category': 'ARR',
      'topicName': 'Đi lại',
      'published': true,
      'createdBy': 1,
      'creatorName': 'Dữ liệu mẫu',
      'createdAt': '2026-11-07T18:36:40Z',
      'sections': [],
      'stageName': 'Khi mới đến (tuần đầu đến 3 tháng)',
      'topicCode': 'TRANSPORT',
      'sourceUrl': null,
      'coverImageUrl': null,
      'status': 'PUBLISHED',
      'preparationEnabled': true,
      'preparationTasks': [],
    },
  ],
  'total': 24,
  'page': 0,
  'size': 12,
  'totalPages': 2,
};

const _detailJson = {
  'id': 23,
  'title': 'Hướng dẫn sử dụng tàu điện Nhật Bản cho người mới',
  'summary': '',
  'category': 'ARR',
  'topicName': 'Đi lại',
  'published': true,
  'createdBy': 1,
  'creatorName': 'Dữ liệu mẫu',
  'createdAt': '2026-11-07T18:36:40Z',
  'sections': [
    {
      'heading': '1. Giới thiệu',
      'content': 'Tàu điện là một trong những phương tiện giao thông phổ biến nhất tại Nhật Bản.',
      'imageUrl': null,
      'referenceUrl': null,
      'imageIndex': null,
      'mediaId': null,
    },
    {
      'heading': '3. Cách tìm tuyến tàu',
      'content': 'Các bước thực hiện:\n1. Mở ứng dụng tìm đường.',
      'imageUrl': '/media/guide/2026/11/b3f71461-a2ed-4a11-9927-41fe97acda34.jpg',
      'referenceUrl': 'https://www.jreast.co.jp/',
      'imageIndex': null,
      'mediaId': 12,
    },
  ],
  'stageName': 'Khi mới đến (tuần đầu đến 3 tháng)',
  'topicCode': 'TRANSPORT',
  'sourceUrl': 'https://www.japan-guide.com/e/e2018.html',
  'coverImageUrl': '/media/guide/2026/11/2cce9799-c252-4457-a853-5b444a4dd06c.jpg',
  'status': 'PUBLISHED',
  'preparationEnabled': true,
  'preparationTasks': [
    {
      'id': 10,
      'title': 'Cài đặt ứng dụng tìm đường',
      'notes': 'Ứng dụng tìm đường tại nhật có thời gian và vị trí gần như luôn đúng',
      'completed': false,
    },
    {'id': 11, 'title': 'Tìm tuyến tàu đến trường hoặc nơi thực tập', 'notes': null, 'completed': false},
  ],
};

const _preparationJson = {
  'tasks': [
    {
      'id': 10,
      'title': 'Cài đặt ứng dụng tìm đường',
      'notes': 'Ứng dụng tìm đường tại nhật có thời gian và vị trí gần như luôn đúng',
      'completed': true,
    },
    {
      'id': 11,
      'title': 'Tìm tuyến tàu đến trường hoặc nơi thực tập',
      'notes': 'Hãy tìm chuyến tàu phù hợp để tối ưu chi phí và thời gian',
      'completed': false,
    },
    {
      'id': 12,
      'title': 'Nạp đủ tiền đi lại',
      'notes': 'Nên nạp đủ tiền trong thẻ ic để vừa đi tàu mac cũng có thể thanh toán mua đồ nếu cần',
      'completed': false,
    },
  ],
  'completed': 1,
  'total': 3,
  'percent': 33,
  'signedIn': true,
};

const _myProgressJson = {
  'stage': 'ARR',
  'stages': [
    {'code': 'PRE', 'title': 'Trước khi đi', 'done': 0, 'total': 5, 'current': false},
    {'code': 'ARR', 'title': 'Khi mới đến (tuần đầu đến 3 tháng)', 'done': 1, 'total': 10, 'current': true},
    {'code': 'LEAVE', 'title': 'Trước khi về nước', 'done': 0, 'total': 5, 'current': false},
    {'code': 'HOME', 'title': 'Sau khi về nước', 'done': 0, 'total': 4, 'current': false},
  ],
  'inProgress': [
    {
      'id': 23,
      'title': 'Hướng dẫn sử dụng tàu điện Nhật Bản cho người mới',
      'topicName': 'Đi lại',
      'stageCode': 'ARR',
      'stageTitle': 'Khi mới đến (tuần đầu đến 3 tháng)',
      'checklist': true,
      'tasksDone': 1,
      'tasksTotal': 3,
      'percent': 33,
      'nextTask': 'Tìm tuyến tàu đến trường hoặc nơi thực tập',
      'lastActivityAt': '2026-11-07T18:52:37Z',
    },
  ],
  'recentlyDone': [
    {
      'id': 22,
      'title': 'Hướng dẫn thuê nhà tại Nhật: Tiền cọc, tiền lễ và các chi phí ban đầu',
      'stageCode': 'ARR',
      'stageTitle': 'Khi mới đến (tuần đầu đến 3 tháng)',
      'doneAt': '2026-11-07T18:52:37Z',
    },
  ],
};

void main() {
  test('findStages và findTopics đọc mã và tên từ server', () async {
    final server = FakeServer({
      'GET /api/guides/topics': (_) => apiOk([
        {'code': 'PRE', 'title': 'Trước khi đi'},
        {'code': 'ARR', 'title': 'Khi mới đến (tuần đầu đến 3 tháng)'},
        {'code': 'LEAVE', 'title': 'Trước khi về nước'},
        {'code': 'HOME', 'title': 'Sau khi về nước'},
      ], message: 'Chủ đề cẩm nang'),
      'GET /api/guides/subjects': (_) => apiOk([
        {'code': 'LIVING', 'title': 'Sinh hoạt'},
        {'code': 'HOUSING', 'title': 'Nhà ở'},
      ], message: 'Chủ đề'),
    });
    final dao = GuideDao(server.api);

    final stages = await dao.findStages();
    expect(stages.map((s) => s.code), ['PRE', 'ARR', 'LEAVE', 'HOME']);
    expect(stages[1].title, 'Khi mới đến (tuần đầu đến 3 tháng)');
    final topics = await dao.findTopics();
    expect(topics.map((t) => '${t.code}:${t.title}'), ['LIVING:Sinh hoạt', 'HOUSING:Nhà ở']);
  });

  test('findAll gửi bộ lọc đúng tên tham số của web và đọc trang (tổng số ở trường total)', () async {
    final server = FakeServer({'GET /api/guides/browse': (_) => apiOk(_browseJson)});
    final page = await GuideDao(server.api).findAll(stage: 'ARR', topic: 'LIVING', q: ' rác ', sort: 'TITLE', page: 1);

    final query = server.last('GET', '/api/guides/browse').uri.queryParameters;
    expect(query, {'category': 'ARR', 'topicCode': 'LIVING', 'q': 'rác', 'sort': 'TITLE', 'page': '1', 'size': '12'});
    expect(page.totalItems, 24);
    expect(page.totalPages, 2);
    expect(page.page, 0);
    expect(page.hasMore, isTrue);

    final first = page.items.first;
    expect(first.id, 24);
    expect(first.stageCode, 'ARR');
    expect(first.stageName, 'Khi mới đến (tuần đầu đến 3 tháng)');
    expect(first.topicCode, 'LIVING');
    expect(first.topicName, 'Sinh hoạt');
    expect(first.creatorName, 'Dữ liệu mẫu');
    expect(first.createdAt, DateTime.utc(2026, 11, 7, 18, 36, 40).toLocal());
    expect(first.coverImageUrl, '/media/guide/2026/11/289eb8b6-c878-4b29-a610-b1baa0758d7e.jpg');
    expect(first.sourceUrl, isNull);
    expect(first.preparationEnabled, isFalse);
    expect(page.items.last.preparationEnabled, isTrue);
    expect(page.items.last.coverImageUrl, isNull);
  });

  test('findAll không gửi bộ lọc trống', () async {
    final server = FakeServer({'GET /api/guides/browse': (_) => apiOk(_browseJson)});
    await GuideDao(server.api).findAll();
    expect(server.last('GET', '/api/guides/browse').uri.queryParameters, {'sort': 'NEWEST', 'page': '0', 'size': '12'});
  });

  test('findAll: sắp xếp sai → ApiException 400 mang câu của server', () async {
    final server = FakeServer({'GET /api/guides/browse': (_) => apiError(400, 'Thứ tự sắp xếp không hợp lệ.')});
    await expectLater(
      GuideDao(server.api).findAll(sort: 'X'),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Thứ tự sắp xếp không hợp lệ.')),
    );
  });

  test('findById đọc các mục, ảnh, nguồn tham khảo và checklist', () async {
    final server = FakeServer({'GET /api/guides/23': (_) => apiOk(_detailJson, message: 'Chi tiết cẩm nang')});
    final guide = await GuideDao(server.api).findById(23);

    expect(guide.title, 'Hướng dẫn sử dụng tàu điện Nhật Bản cho người mới');
    expect(guide.summary, '');
    expect(guide.sourceUrl, 'https://www.japan-guide.com/e/e2018.html');
    expect(guide.sections, hasLength(2));
    expect(guide.sections.first.heading, '1. Giới thiệu');
    expect(guide.sections.first.imageUrl, isNull);
    expect(guide.sections.first.referenceUrl, isNull);
    expect(guide.sections.last.imageUrl, '/media/guide/2026/11/b3f71461-a2ed-4a11-9927-41fe97acda34.jpg');
    expect(guide.sections.last.referenceUrl, 'https://www.jreast.co.jp/');
    expect(guide.sections.last.content, contains('\n1. Mở ứng dụng'));
    expect(guide.preparationEnabled, isTrue);
    expect(guide.preparationTasks.map((t) => t.id), [10, 11]);
    expect(guide.preparationTasks.last.notes, '');
  });

  test('findById cẩm nang không còn → 404', () async {
    final server = FakeServer({'GET /api/guides/999': (_) => apiError(404, 'Không tìm thấy cẩm nang.')});
    await expectLater(
      GuideDao(server.api).findById(999),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
    );
  });

  test('findViewer đọc trạng thái khách và thành viên', () async {
    final server = FakeServer({
      'GET /api/guides/23/viewer': (_) => apiOk({
        'signedIn': false,
        'member': false,
        'saved': false,
        'progress': {
          'checklist': true,
          'tasksDone': 0,
          'tasksTotal': 3,
          'percent': 0,
          'done': false,
          'nextTask': 'Cài đặt ứng dụng tìm đường',
        },
      }, message: 'Trạng thái của bạn với cẩm nang'),
      'GET /api/guides/24/viewer': (_) => apiOk({
        'signedIn': true,
        'member': true,
        'saved': true,
        'progress': {
          'checklist': false,
          'tasksDone': 0,
          'tasksTotal': 0,
          'percent': 0,
          'done': false,
          'nextTask': null,
        },
      }),
    });
    final dao = GuideDao(server.api);

    final guest = await dao.findViewer(23);
    expect(guest.signedIn, isFalse);
    expect(guest.member, isFalse);
    expect(guest.progress.checklist, isTrue);
    expect(guest.progress.tasksTotal, 3);
    expect(guest.progress.nextTask, 'Cài đặt ứng dụng tìm đường');

    final member = await dao.findViewer(24);
    expect(member.member, isTrue);
    expect(member.saved, isTrue);
    expect(member.progress.checklist, isFalse);
    expect(member.progress.nextTask, isNull);
  });

  test('findPreparation và checkTask (PUT body {completed}) đọc checklist', () async {
    final server = FakeServer({
      'GET /api/guides/23/preparation': (_) => apiOk(_preparationJson, message: 'Tiến độ chuẩn bị'),
      'PUT /api/guides/23/preparation/10': (_) => apiOk(_preparationJson, message: 'Đã lưu tiến độ'),
    });
    final dao = GuideDao(server.api);

    final preparation = await dao.findPreparation(23);
    expect(preparation.tasks.map((t) => t.completed), [true, false, false]);
    expect(preparation.tasks.first.notes, startsWith('Ứng dụng tìm đường'));
    expect(preparation.completed, 1);
    expect(preparation.total, 3);
    expect(preparation.percent, 33);
    expect(preparation.signedIn, isTrue);

    final after = await dao.checkTask(23, 10, true);
    final request = server.last('PUT', '/api/guides/23/preparation/10');
    expect(request.data, {'completed': true});
    expect(request.headers['X-XSRF-TOKEN'], 'csrf-test');
    expect(after.completed, 1);
  });

  test('findPreparation cẩm nang không có checklist → 404; checkTask khách → 401', () async {
    final server = FakeServer({
      'GET /api/guides/24/preparation': (_) => apiError(404, 'Không tìm thấy danh sách chuẩn bị.'),
      'PUT /api/guides/23/preparation/10': (_) => apiError(401, 'Vui lòng đăng nhập để lưu tiến độ.'),
    });
    final dao = GuideDao(server.api);
    await expectLater(dao.findPreparation(24), throwsA(isA<ApiException>()));
    await expectLater(
      dao.checkTask(23, 10, true),
      throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
    );
  });

  test('save / unsave gọi POST / DELETE và trả câu của server', () async {
    final server = FakeServer({
      'POST /api/guides/22/save': (_) => apiOk({'saved': true}, message: 'Đã lưu cẩm nang.'),
      'DELETE /api/guides/22/save': (_) => apiOk({'saved': false}, message: 'Đã bỏ lưu cẩm nang.'),
    });
    final dao = GuideDao(server.api);
    expect(await dao.save(22), 'Đã lưu cẩm nang.');
    expect(await dao.unsave(22), 'Đã bỏ lưu cẩm nang.');
    expect(server.requests.map((r) => '${r.method} ${r.uri.path}'), [
      'POST /api/guides/22/save',
      'DELETE /api/guides/22/save',
    ]);
  });

  test('markDone / unmarkDone trả câu và tiến độ; cẩm nang có checklist → 400', () async {
    final server = FakeServer({
      'POST /api/guides/22/done': (_) => apiOk({
        'checklist': false,
        'tasksDone': 0,
        'tasksTotal': 0,
        'percent': 100,
        'done': true,
        'nextTask': null,
      }, message: 'Đã đánh dấu xong cẩm nang.'),
      'DELETE /api/guides/22/done': (_) => apiOk({
        'checklist': false,
        'tasksDone': 0,
        'tasksTotal': 0,
        'percent': 0,
        'done': false,
        'nextTask': null,
      }, message: 'Đã bỏ đánh dấu đã xong.'),
      'POST /api/guides/23/done': (_) =>
          apiError(400, 'Cẩm nang này có danh sách chuẩn bị. Hãy đánh dấu từng việc trong tab “Hướng dẫn chuẩn bị”.'),
    });
    final dao = GuideDao(server.api);

    final done = await dao.markDone(22);
    expect(done.message, 'Đã đánh dấu xong cẩm nang.');
    expect(done.progress.done, isTrue);
    expect(done.progress.percent, 100);
    final undone = await dao.unmarkDone(22);
    expect(undone.message, 'Đã bỏ đánh dấu đã xong.');
    expect(undone.progress.done, isFalse);

    await expectLater(
      dao.markDone(23),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('danh sách chuẩn bị'))),
    );
  });

  test('findMyProgress đọc 4 giai đoạn, đang làm dở và đã xong', () async {
    final server = FakeServer({'GET /api/me/guides/progress': (_) => apiOk(_myProgressJson)});
    final my = await GuideDao(server.api).findMyProgress();

    expect(my.stage, 'ARR');
    expect(my.stages.map((s) => s.code), ['PRE', 'ARR', 'LEAVE', 'HOME']);
    expect(my.stages[1].current, isTrue);
    expect(my.stages[1].done, 1);
    expect(my.stages[1].total, 10);
    expect(my.stages[1].ratio, 0.1);
    expect(my.hasActivity, isTrue);

    final started = my.inProgress.single;
    expect(started.id, 23);
    expect(started.topicName, 'Đi lại');
    expect(started.stageTitle, 'Khi mới đến (tuần đầu đến 3 tháng)');
    expect(started.tasksDone, 1);
    expect(started.tasksTotal, 3);
    expect(started.percent, 33);
    expect(started.nextTask, 'Tìm tuyến tàu đến trường hoặc nơi thực tập');
    expect(started.at, DateTime.utc(2026, 11, 7, 18, 52, 37).toLocal());

    final done = my.recentlyDone.single;
    expect(done.id, 22);
    expect(done.at, DateTime.utc(2026, 11, 7, 18, 52, 37).toLocal());
  });

  test('findMyProgress khách → 401', () async {
    final server = FakeServer({'GET /api/me/guides/progress': (_) => const FakeReply(401, null)});
    await expectLater(
      GuideDao(server.api).findMyProgress(),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Bạn cần đăng nhập để làm việc này.')),
    );
  });

  test('GuidePreparation.withTask tính lại số việc và phần trăm như server', () {
    const preparation = GuidePreparation(
      tasks: [
        GuideTask(id: 1, title: 'A'),
        GuideTask(id: 2, title: 'B'),
        GuideTask(id: 3, title: 'C'),
      ],
      total: 3,
    );
    final after = preparation.withTask(2, true);
    expect(after.completed, 1);
    expect(after.percent, 33);
    expect(after.tasks[1].completed, isTrue);

    final progress = GuideProgress.fromPreparation(after);
    expect(progress.checklist, isTrue);
    expect(progress.tasksDone, 1);
    expect(progress.done, isFalse);
    expect(progress.nextTask, 'A');

    final all = after.withTask(1, true).withTask(3, true);
    expect(all.percent, 100);
    expect(GuideProgress.fromPreparation(all).done, isTrue);
    expect(GuideProgress.fromPreparation(all).nextTask, isNull);
  });
}
