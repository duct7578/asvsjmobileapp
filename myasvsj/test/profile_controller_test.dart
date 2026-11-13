// Unit test của ProfileController (trang Tôi, Lịch sử điểm) với DAO giả, không cần server.
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/profile_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/point_line.dart';

import 'profile_fakes.dart';

void main() {
  late FakeProfileDao dao;
  late ProfileController controller;

  setUp(() {
    dao = FakeProfileDao();
    controller = ProfileController(dao);
  });

  group('loadProfile', () {
    test('lấy hồ sơ và chủ đề quan tâm đã chọn, tắt trạng thái chờ', () async {
      final future = controller.loadProfile();
      expect(controller.isLoading, isTrue);
      await future;
      expect(controller.isLoading, isFalse);
      expect(controller.error, isNull);
      expect(controller.profile?.displayName, 'An');
      expect(controller.profile?.currentRank?.name, 'Người chỉ đường');
      expect(controller.chosenInterests.map((t) => t.name), ['Kinh nghiệm']);
    });

    test('giữ câu báo lỗi của server', () async {
      dao.failWith = const ApiException('Không kết nối được tới server.');
      await controller.loadProfile();
      expect(controller.error, 'Không kết nối được tới server.');
      expect(controller.profile, isNull);
      expect(controller.isLoading, isFalse);
    });

    test('chủ đề quan tâm lỗi thì vẫn có hồ sơ, chỉ không có tên chủ đề', () async {
      dao.failOn['findInterests'] = const ApiException('Bạn không có quyền thực hiện thao tác này.', statusCode: 403);
      await controller.loadProfile();
      expect(controller.error, isNull);
      expect(controller.profile, isNotNull);
      expect(controller.chosenInterests, isEmpty);
    });

    test('tải lại lỗi thì vẫn giữ hồ sơ đang hiện', () async {
      await controller.loadProfile();
      dao.failWith = const ApiException('Mất mạng.');
      await controller.loadProfile();
      expect(controller.profile?.id, 1);
      expect(controller.error, 'Mất mạng.');
    });

    test('clear xóa dữ liệu của người vừa đăng xuất', () async {
      await controller.loadProfile();
      await controller.loadPoints();
      controller.clear();
      expect(controller.profile, isNull);
      expect(controller.chosenInterests, isEmpty);
      expect(controller.pointLines, isEmpty);
      expect(controller.points, 0);
    });
  });

  group('Lịch sử điểm', () {
    test('loadPoints lấy trang đầu, còn trang sau', () async {
      final future = controller.loadPoints();
      expect(controller.isLoadingPoints, isTrue);
      await future;
      expect(controller.isLoadingPoints, isFalse);
      expect(controller.pointLines, hasLength(20));
      expect(controller.pointLines.first.title, 'Ga Nippori');
      expect(controller.pointsTotal, 25);
      expect(controller.points, 130);
      expect(controller.hasMorePoints, isTrue);
    });

    test('loadMorePoints nối trang sau rồi hết', () async {
      await controller.loadPoints();
      await controller.loadMorePoints();
      expect(controller.pointLines, hasLength(25));
      expect(controller.pointLines.map((l) => l.id).toSet(), hasLength(25));
      expect(controller.hasMorePoints, isFalse);

      // Đã hết thì không gọi server nữa
      final calls = dao.calls.length;
      await controller.loadMorePoints();
      expect(dao.calls.length, calls);
    });

    test('loadMorePoints không hiện một dòng hai lần khi điểm mới đẩy dòng cũ sang trang sau', () async {
      await controller.loadPoints();
      // Một dòng mới được cộng: dòng cuối trang 0 bị đẩy sang đầu trang 1
      dao.pointLines.insert(0, const PointLine(id: 100, delta: 10, reasonLabel: 'Viết review'));
      await controller.loadMorePoints();
      final ids = controller.pointLines.map((l) => l.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(controller.pointsTotal, 26);
    });

    test('lỗi trang đầu giữ ở pointsError', () async {
      dao.failWith = const ApiException('Server gặp lỗi (500). Hãy thử lại sau.');
      await controller.loadPoints();
      expect(controller.pointsError, 'Server gặp lỗi (500). Hãy thử lại sau.');
      expect(controller.pointLines, isEmpty);
    });

    test('lỗi trang sau giữ danh sách đang có, báo ở morePointsError', () async {
      await controller.loadPoints();
      dao.failWith = const ApiException('Mất mạng.');
      await controller.loadMorePoints();
      expect(controller.pointLines, hasLength(20));
      expect(controller.morePointsError, 'Mất mạng.');
      expect(controller.hasMorePoints, isTrue);
      expect(controller.isLoadingMorePoints, isFalse);

      dao.failWith = null;
      await controller.loadMorePoints();
      expect(controller.morePointsError, isNull);
      expect(controller.pointLines, hasLength(25));
    });

    test('mở màn hình xóa danh sách cũ; kéo làm mới (keepShown) thì giữ trong lúc tải', () async {
      await controller.loadPoints();
      final refresh = controller.loadPoints(keepShown: true);
      expect(controller.pointLines, hasLength(20));
      await refresh;

      final reopen = controller.loadPoints();
      expect(controller.pointLines, isEmpty);
      await reopen;
      expect(controller.pointLines, hasLength(20));
    });
  });
}
