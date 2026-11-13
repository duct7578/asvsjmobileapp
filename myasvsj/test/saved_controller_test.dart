// Unit test của SavedController (Đã lưu) với DAO giả, không cần server.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/saved_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/saved_kind.dart';

import 'saved_fakes.dart';

void main() {
  late FakeSavedDao dao;
  late SavedController controller;

  setUp(() {
    dao = FakeSavedDao();
    controller = SavedController(dao);
  });

  test('load lấy cả bốn loại, tắt trạng thái chờ', () async {
    final future = controller.load();
    expect(controller.isLoading, isTrue);
    expect(controller.isLoaded, isFalse);
    await future;
    expect(controller.isLoading, isFalse);
    expect(controller.isLoaded, isTrue);
    expect(controller.saved.total, 5);
    expect(controller.saved.countOf(SavedKind.place), 2);
  });

  test('load giữ câu báo lỗi của server', () async {
    dao.failWith = const ApiException('Bạn cần đăng nhập để làm việc này.', statusCode: 401);
    await controller.load();
    expect(controller.error, 'Bạn cần đăng nhập để làm việc này.');
    expect(controller.isLoaded, isFalse);
  });

  test('bỏ lưu: mục biến mất ngay (lạc quan), rồi giữ câu của server', () async {
    await controller.load();
    dao.hold = Completer<void>();
    final future = controller.unsave(nippori);
    expect(controller.saved.itemsOf(SavedKind.place).map((p) => p.id), [6], reason: 'gỡ trước khi server trả lời');
    dao.hold!.complete();
    expect(await future, isTrue);
    expect(dao.unsaved.single, (SavedKind.place, 1));
    expect(controller.takeMessage(), 'Đã bỏ lưu địa điểm.');
    expect(controller.canUndo, isTrue);
  });

  test('bỏ lưu lỗi: mục quay lại đúng chỗ cũ, giữ câu lỗi', () async {
    await controller.load();
    dao.failWrites = const ApiException('Không tìm thấy nội dung bạn yêu cầu.', statusCode: 404);
    expect(await controller.unsave(nippori), isFalse);
    expect(controller.saved.itemsOf(SavedKind.place).map((p) => p.id), [1, 6]);
    expect(controller.takeMessage(), 'Không tìm thấy nội dung bạn yêu cầu.');
    expect(controller.canUndo, isFalse);
  });

  test('bỏ lưu hai mục liền nhau, mục sau lỗi thì chỉ mục sau quay lại', () async {
    await controller.load();
    expect(await controller.unsave(nippori), isTrue);
    dao.failWrites = const ApiException('Mất mạng.');
    expect(await controller.unsave(ward), isFalse);
    expect(controller.saved.itemsOf(SavedKind.place).map((p) => p.id), [6]);
  });

  test('Hoàn tác: lưu lại và trả mục về chỗ cũ', () async {
    await controller.load();
    await controller.unsave(nippori);
    controller.takeMessage();
    expect(await controller.undoUnsave(), isTrue);
    expect(dao.resaved.single, (SavedKind.place, 1));
    expect(controller.saved.itemsOf(SavedKind.place).map((p) => p.id), [1, 6]);
    expect(controller.takeMessage(), 'Đã lưu địa điểm.');
    expect(controller.canUndo, isFalse);
    expect(await controller.undoUnsave(), isFalse, reason: 'chỉ hoàn tác một lần');
  });

  test('Hoàn tác lỗi thì mục lại biến mất', () async {
    await controller.load();
    await controller.unsave(tokyoPost);
    dao.failWrites = const ApiException('Mất mạng.');
    expect(await controller.undoUnsave(), isFalse);
    expect(controller.saved.countOf(SavedKind.post), 0);
    expect(controller.takeMessage(), 'Mất mạng.');
  });

  test('bỏ lưu mục không còn trong danh sách thì không gọi server', () async {
    await controller.load();
    await controller.unsave(nippori);
    expect(await controller.unsave(nippori), isFalse);
    expect(dao.unsaved, hasLength(1));
  });

  test('clear xóa danh sách của người vừa đăng xuất', () async {
    await controller.load();
    controller.clear();
    expect(controller.saved.isEmpty, isTrue);
    expect(controller.isLoaded, isFalse);
  });
}
