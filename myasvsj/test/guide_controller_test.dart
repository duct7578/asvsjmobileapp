// Unit test của GuideController: chạy với DAO giả, không cần server.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/guide_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';

import 'guide_fakes.dart';

void main() {
  late FakeGuideDao dao;
  late GuideController controller;

  setUp(() {
    dao = FakeGuideDao();
    controller = GuideController(dao);
  });

  group('danh sách', () {
    test('openList tải giai đoạn, chủ đề và trang đầu; bật rồi tắt trạng thái chờ', () async {
      final future = controller.openList();
      expect(controller.isLoading, isTrue);
      await future;
      expect(controller.isLoading, isFalse);
      expect(controller.stages.map((s) => s.code), ['PRE', 'ARR', 'LEAVE', 'HOME']);
      expect(controller.topics.map((t) => t.code), ['LIVING', 'TRANSPORT']);
      expect(controller.guides.map((g) => g.id), [24, 23]);
      expect(controller.totalItems, 3);
      expect(controller.hasMore, isTrue);
    });

    test('openList(stage) chọn sẵn giai đoạn và bỏ bộ lọc cũ', () async {
      await controller.openList();
      await controller.selectTopic('LIVING');
      await controller.search('rác');
      await controller.openList(stage: 'PRE');
      expect(controller.stage, 'PRE');
      expect(controller.topic, isNull);
      expect(controller.query, '');
      expect(dao.listCalls.last, (stage: 'PRE', topic: null, q: '', sort: 'NEWEST', page: 0));
      expect(controller.guides.map((g) => g.id), [5]);
    });

    test('loadMore nối trang sau, hết trang thì không gọi nữa', () async {
      await controller.openList();
      await controller.loadMore();
      expect(controller.guides.map((g) => g.id), [24, 23, 5]);
      expect(controller.hasMore, isFalse);
      final calls = dao.listCalls.length;
      await controller.loadMore();
      expect(dao.listCalls.length, calls);
    });

    test('loadMore lỗi giữ danh sách đang có và báo bằng message', () async {
      await controller.openList();
      dao.failWith = const ApiException('Không kết nối được tới server.');
      await controller.loadMore();
      expect(controller.guides, hasLength(2));
      expect(controller.isLoadingMore, isFalse);
      expect(controller.takeMessage(), 'Không kết nối được tới server.');
    });

    test('lọc giai đoạn, chủ đề, tìm, sắp xếp gửi đúng bộ lọc cho DAO', () async {
      await controller.openList();
      await controller.selectStage('ARR');
      await controller.selectTopic('TRANSPORT');
      expect(controller.guides.map((g) => g.id), [23]);
      await controller.search('  tàu  ');
      await controller.selectSort('TITLE');
      expect(dao.listCalls.last, (stage: 'ARR', topic: 'TRANSPORT', q: 'tàu', sort: 'TITLE', page: 0));
      await controller.selectSort('LẠ');
      expect(controller.sort, 'NEWEST');
    });

    test('search cắt từ khóa còn 200 ký tự như server', () async {
      await controller.search('a' * 250);
      expect(controller.query.length, 200);
    });

    test('lỗi tải danh sách nằm ở error; lựa chọn lọc lỗi vẫn xem được danh sách', () async {
      dao.failWith = const ApiException('Server gặp lỗi (500). Hãy thử lại sau.');
      await controller.openList();
      expect(controller.error, 'Server gặp lỗi (500). Hãy thử lại sau.');
      expect(controller.stages, isEmpty);

      dao.failWith = null;
      await controller.loadGuides();
      expect(controller.error, isNull);
      expect(controller.stages, hasLength(4));
      expect(controller.guides, isNotEmpty);
    });
  });

  group('chi tiết', () {
    test('loadGuide tải cẩm nang, trạng thái người xem và checklist theo id', () async {
      final future = controller.loadGuide(23);
      expect(controller.isLoadingGuide(23), isTrue);
      await future;
      await controller.loadGuide(24);
      expect(controller.guideOf(23)?.title, 'Hướng dẫn sử dụng tàu điện Nhật Bản');
      expect(controller.guideOf(24)?.title, 'Cách phân loại và bỏ rác tại Nhật Bản');
      expect(controller.viewerOf(23)?.member, isTrue);
      expect(controller.preparationOf(23)?.total, 3);
      expect(controller.preparationOf(24), isNull);
      expect(controller.isLoadingGuide(23), isFalse);
    });

    test('loadGuide: cẩm nang không còn → lỗi 404', () async {
      await controller.loadGuide(999);
      expect(controller.guideOf(999), isNull);
      expect(controller.guideErrorOf(999), 'Không tìm thấy cẩm nang.');
    });

    test('thành viên tick: hiện ngay, lưu lên server, tiến độ trên nút đi theo', () async {
      await controller.loadGuide(23);
      dao.writeGate = Completer<void>();
      final future = controller.toggleTask(23, 10, true);
      expect(controller.preparationOf(23)!.completed, 1);
      expect(controller.preparationOf(23)!.percent, 33);
      expect(controller.viewerOf(23)!.progress.tasksDone, 1);
      expect(controller.viewerOf(23)!.progress.nextTask, 'Tìm tuyến tàu đến trường');
      expect(controller.isTicking(23), isTrue);
      dao.writeGate!.complete();
      await future;
      expect(dao.checks.single, (guideId: 23, taskId: 10, completed: true));
      expect(controller.isTicking(23), isFalse);
      expect(controller.preparationOf(23)!.tasks.first.completed, isTrue);
    });

    test('tick lỗi thì hoàn tác và báo câu của server', () async {
      await controller.loadGuide(23);
      dao.writeFailWith = const ApiException('Công việc không thuộc cẩm nang này hoặc đã bị xóa.', statusCode: 404);
      await controller.toggleTask(23, 10, true);
      expect(controller.preparationOf(23)!.completed, 0);
      expect(controller.viewerOf(23)!.progress.tasksDone, 0);
      expect(
        controller.takeMessage(),
        'Công việc không thuộc cẩm nang này hoặc đã bị xóa. Tiến độ chưa được thay đổi.',
      );
    });

    test('khách tick: chỉ tính trên máy, không gọi server', () async {
      dao.signedIn = false;
      await controller.loadGuide(23);
      expect(controller.preparationOf(23)!.signedIn, isFalse);
      await controller.toggleTask(23, 11, true);
      await controller.toggleTask(23, 12, true);
      expect(controller.preparationOf(23)!.completed, 2);
      expect(controller.preparationOf(23)!.percent, 66);
      expect(dao.checks, isEmpty);
    });

    test('toggleSave lạc quan: đổi nút ngay, giữ câu của server', () async {
      await controller.loadGuide(24);
      dao.writeGate = Completer<void>();
      final future = controller.toggleSave(24);
      expect(controller.viewerOf(24)!.saved, isTrue);
      expect(controller.isBusy(24), isTrue);
      dao.writeGate!.complete();
      await future;
      expect(dao.actions, ['save 24']);
      expect(controller.takeMessage(), 'Đã lưu cẩm nang.');

      await controller.toggleSave(24);
      expect(controller.viewerOf(24)!.saved, isFalse);
      expect(dao.actions.last, 'unsave 24');
    });

    test('toggleSave lỗi thì hoàn tác', () async {
      await controller.loadGuide(24);
      dao.writeFailWith = const ApiException('Bạn cần đăng nhập để thực hiện thao tác này.', statusCode: 401);
      await controller.toggleSave(24);
      expect(controller.viewerOf(24)!.saved, isFalse);
      expect(controller.takeMessage(), 'Bạn cần đăng nhập để thực hiện thao tác này.');
    });

    test('toggleDone lấy tiến độ của server; cẩm nang có checklist thì không gọi', () async {
      await controller.loadGuide(24);
      await controller.toggleDone(24);
      expect(controller.viewerOf(24)!.progress.done, isTrue);
      expect(controller.takeMessage(), 'Đã đánh dấu xong cẩm nang.');
      await controller.toggleDone(24);
      expect(controller.viewerOf(24)!.progress.done, isFalse);
      expect(dao.actions, ['done 24', 'undone 24']);

      await controller.loadGuide(23);
      await controller.toggleDone(23);
      expect(dao.actions, hasLength(2));
    });

    test('toggleDone lỗi thì hoàn tác', () async {
      await controller.loadGuide(24);
      dao.writeFailWith = const ApiException('Bạn không có quyền thực hiện thao tác này.', statusCode: 403);
      await controller.toggleDone(24);
      expect(controller.viewerOf(24)!.progress.done, isFalse);
      expect(controller.takeMessage(), 'Bạn không có quyền thực hiện thao tác này.');
    });
  });

  group('cẩm nang của tôi', () {
    test('loadMyProgress lấy tiến độ; lỗi nằm ở myError', () async {
      final future = controller.loadMyProgress();
      expect(controller.isLoadingMy, isTrue);
      await future;
      expect(controller.myProgress?.stages, hasLength(4));
      expect(controller.myError, isNull);

      dao.failWith = const ApiException('Bạn không có quyền thực hiện thao tác này.', statusCode: 403);
      await controller.loadMyProgress();
      expect(controller.myError, 'Bạn không có quyền thực hiện thao tác này.');
      expect(controller.isLoadingMy, isFalse);
    });
  });
}
