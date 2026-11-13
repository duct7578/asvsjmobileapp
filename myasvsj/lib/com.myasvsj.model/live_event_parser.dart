import 'dart:async';

import 'package:myasvsj/com.myasvsj.model/live_event.dart';

/// Đọc các dòng chữ của luồng Server-Sent Events thành [LiveEvent], theo chuẩn `text/event-stream`:
///
/// ```text
/// event:chat
/// data:{"kind":"message","conversationId":1,"messageId":5}
///                                           ← dòng trống: hết một sự kiện
/// :ping                                     ← dòng chú thích (giữ kết nối)
/// ```
///
/// - `event:` đặt tên sự kiện (mặc định "message"); `data:` nối thêm dữ liệu (nhiều dòng `data:` nối bằng xuống dòng).
/// - Dòng trống gửi sự kiện đi, khi đã có `data:`. Dòng `id:`, `retry:` app không cần nên bỏ qua.
/// - Dòng bắt đầu bằng `:` là chú thích: trả về [LiveEvent.ping] để biết kết nối vẫn sống.
/// - Sự kiện dở dang khi luồng kết thúc bị bỏ, như trình duyệt.
class LiveEventParser extends StreamTransformerBase<String, LiveEvent> {
  const LiveEventParser();

  @override
  Stream<LiveEvent> bind(Stream<String> stream) async* {
    var type = '';
    final data = StringBuffer();
    var hasData = false;
    await for (final line in stream) {
      if (line.isEmpty) {
        if (hasData) {
          yield LiveEvent.parse(type.isEmpty ? 'message' : type, data.toString());
        }
        type = '';
        data.clear();
        hasData = false;
        continue;
      }
      if (line.startsWith(':')) {
        yield const LiveEvent(LiveEvent.ping);
        continue;
      }
      final colon = line.indexOf(':');
      final field = colon < 0 ? line : line.substring(0, colon);
      var value = colon < 0 ? '' : line.substring(colon + 1);
      if (value.startsWith(' ')) {
        value = value.substring(1);
      }
      switch (field) {
        case 'event':
          type = value;
        case 'data':
          if (hasData) {
            data.write('\n');
          }
          data.write(value);
          hasData = true;
      }
    }
  }
}
