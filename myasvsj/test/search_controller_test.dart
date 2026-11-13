// Unit test của GlobalSearchController với DAO giả.
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/global_search_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';

import 'home_fakes.dart';

void main() {
  late FakeSearchDao dao;
  late GlobalSearchController controller;

  setUp(() {
    dao = FakeSearchDao();
    controller = GlobalSearchController(dao);
  });

  test('ô trống: không gọi server, hiện gợi ý', () async {
    await controller.search('   ');
    expect(dao.asked, isEmpty);
    expect(controller.asked, '');
    expect(controller.result, isNull);
    expect(controller.isLoading, isFalse);
  });

  test('tìm: có trạng thái chờ, giữ kết quả và từ khóa đã bỏ khoảng trắng', () async {
    final future = controller.search('  Nippori ');
    expect(controller.isLoading, isTrue);
    await future;
    expect(controller.isLoading, isFalse);
    expect(dao.asked, ['Nippori']);
    expect(controller.asked, 'Nippori');
    expect(controller.result?.total, 16);
    expect(controller.result?.places.items.first.name, 'Ga Nippori');
    expect(controller.error, isNull);
  });

  test('chữ không đổi thì không hỏi lại; always (Enter, gợi ý, thử lại) thì hỏi lại', () async {
    await controller.search('Nippori');
    await controller.search('Nippori ');
    expect(dao.asked, hasLength(1));
    await controller.search('Nippori', always: true);
    expect(dao.asked, hasLength(2));
  });

  test('quá 100 ký tự: báo lỗi, không gọi server', () async {
    await controller.search('x' * 101);
    expect(dao.asked, isEmpty);
    expect(controller.error, GlobalSearchController.queryTooLong);
  });

  test('lỗi server: giữ câu báo lỗi; tìm lại được', () async {
    dao.failWith = const ApiException('Không kết nối được tới server.');
    await controller.search('Nippori');
    expect(controller.error, 'Không kết nối được tới server.');
    expect(controller.isLoading, isFalse);
    expect(controller.asked, isNull);

    dao.failWith = null;
    await controller.search('Nippori');
    expect(controller.error, isNull);
    expect(controller.result?.q, 'Nippori');
  });

  test('chỉ giữ câu trả lời của lần tìm mới nhất', () async {
    dao.hold = true;
    final first = controller.search('Nippori');
    final second = controller.search('thẻ cư trú');
    dao.pending[1].complete();
    await second;
    dao.pending[0].complete();
    await first;
    expect(controller.asked, 'thẻ cư trú');
    expect(controller.result?.guides.total, 2);
    expect(controller.isLoading, isFalse);
  });

  test('xóa chữ khi đang tìm: bỏ câu trả lời đang chờ', () async {
    dao.hold = true;
    final pending = controller.search('Nippori');
    await controller.search('');
    dao.pending.single.complete();
    await pending;
    expect(controller.asked, '');
    expect(controller.result, isNull);
  });

  test('reset xóa kết quả cũ cho màn hình mới', () async {
    await controller.search('Nippori');
    controller.reset();
    expect(controller.asked, isNull);
    expect(controller.result, isNull);
    expect(controller.error, isNull);
  });
}
