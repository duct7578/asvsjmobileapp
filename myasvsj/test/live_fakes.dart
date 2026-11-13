import 'dart:async';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/live_dao.dart';
import 'package:myasvsj/com.myasvsj.model/live_event.dart';

/// Luồng tức thì giả: mỗi lần [open] tạo một luồng mới mà test tự đẩy sự kiện vào ([emit]) hoặc đóng ([closeCurrent]).
class FakeLiveDao implements LiveDao {
  /// Các luồng đã mở, theo thứ tự.
  final List<StreamController<LiveEvent>> streams = [];

  /// Số lần [open] tiếp theo sẽ lỗi (như mất mạng hoặc 401).
  int failNextOpens = 0;

  /// Tổng số lần [open] được gọi (kể cả lần lỗi).
  int opens = 0;

  @override
  Stream<LiveEvent> open() {
    opens++;
    if (failNextOpens > 0) {
      failNextOpens--;
      return Stream.error(const ApiException('Không kết nối được tới server.'));
    }
    final controller = StreamController<LiveEvent>();
    streams.add(controller);
    return controller.stream;
  }

  /// Luồng đang mở (mở sau cùng).
  StreamController<LiveEvent> get current => streams.last;

  /// Có người nghe luồng mới nhất (Controller chưa hủy).
  bool get isListened => streams.isNotEmpty && streams.last.hasListener;

  void emit(LiveEvent event) => current.add(event);

  /// Server đóng luồng (sau 5 phút, hoặc mất mạng).
  Future<void> closeCurrent() => current.close();
}
