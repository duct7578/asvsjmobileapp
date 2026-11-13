// Unit test của InterestController (Chủ đề quan tâm) với DAO giả, không cần server.
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/interest_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';

import 'profile_fakes.dart';

void main() {
  late FakeProfileDao dao;
  late InterestController controller;

  setUp(() {
    dao = FakeProfileDao();
    controller = InterestController(dao);
  });

  test('load lấy chủ đề, lựa chọn đã lưu và gợi ý', () async {
    final future = controller.load();
    expect(controller.isLoading, isTrue);
    await future;
    expect(controller.isLoading, isFalse);
    expect(controller.topics, hasLength(7));
    expect(controller.max, 5);
    expect(controller.selectedIds, [1]);
    expect(controller.hasChanges, isFalse);
    expect(controller.hasSuggestions, isTrue);
  });

  test('load giữ câu báo lỗi của server', () async {
    dao.failWith = const ApiException('Bạn không có quyền thực hiện thao tác này.', statusCode: 403);
    await controller.load();
    expect(controller.error, 'Bạn không có quyền thực hiện thao tác này.');
    expect(controller.topics, isEmpty);
  });

  test('toggle chọn và bỏ chọn; chọn chủ đề gợi ý thì hết dòng gợi ý', () async {
    await controller.load();
    expect(controller.toggle(5), isTrue);
    expect(controller.selectedIds, [1, 5]);
    expect(controller.hasChanges, isTrue);
    expect(controller.hasSuggestions, isFalse);
    expect(controller.toggle(1), isTrue);
    expect(controller.selectedIds, [5]);
  });

  test('đã đủ 5 chủ đề thì không chọn thêm được', () async {
    await controller.load();
    for (final id in [2, 3, 4, 5]) {
      expect(controller.toggle(id), isTrue);
    }
    expect(controller.isFull, isTrue);
    expect(controller.toggle(6), isFalse);
    expect(controller.selectedIds, hasLength(5));
    // Bỏ một chủ đề thì chọn được chủ đề khác
    expect(controller.toggle(2), isTrue);
    expect(controller.toggle(6), isTrue);
  });

  test('save gửi cả lựa chọn và giữ câu của server', () async {
    await controller.load();
    controller.toggle(3);
    final future = controller.save();
    expect(controller.isSaving, isTrue);
    expect(controller.toggle(4), isFalse, reason: 'không đổi lựa chọn khi đang lưu');
    expect(await future, isTrue);
    expect(dao.savedInterests.single, [1, 3]);
    expect(controller.hasChanges, isFalse);
    expect(controller.takeMessage(), 'Đã lưu chủ đề quan tâm.');
  });

  test('bỏ hết rồi lưu thì gửi danh sách rỗng', () async {
    await controller.load();
    controller.toggle(1);
    expect(await controller.save(), isTrue);
    expect(dao.savedInterests.single, isEmpty);
  });

  test('quá số chủ đề tối đa thì không gọi server', () async {
    await controller.load();
    controller.selectedIds = [1, 2, 3, 4, 5, 6];
    expect(await controller.save(), isFalse);
    expect(controller.saveError, 'Bạn chọn được tối đa 5 chủ đề.');
    expect(dao.calls, isNot(contains('updateInterests')));
    expect(InterestController.validate([1, 1, 2], 2), isNull, reason: 'chủ đề lặp lại chỉ tính một lần');
  });

  test('server từ chối: giữ câu lỗi, giữ lựa chọn chưa lưu', () async {
    await controller.load();
    controller.toggle(2);
    dao.failOn['updateInterests'] = const ApiException(
      'Có chủ đề không còn để chọn. Hãy tải lại trang rồi chọn lại.',
      statusCode: 400,
    );
    expect(await controller.save(), isFalse);
    expect(controller.saveError, startsWith('Có chủ đề không còn để chọn'));
    expect(controller.selectedIds, [1, 2]);
    expect(controller.isSaving, isFalse);
  });
}
