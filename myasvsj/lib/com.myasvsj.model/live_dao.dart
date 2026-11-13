import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/live_event.dart';
import 'package:myasvsj/com.myasvsj.model/live_event_parser.dart';

/// Luồng cập nhật tức thì của người đang đăng nhập qua REST API của web (mọi vai trò đã đăng nhập; khách nhận 401).
///
/// | Hàm   | API                                          |
/// |-------|----------------------------------------------|
/// | open  | GET /api/me/live (text/event-stream, SSE)    |
class LiveDao {
  LiveDao(this._api);

  final ApiClient _api;

  /// Mở luồng. Sự kiện đầu tiên là [LiveEvent.ready]; sau đó `notification`, `chat` và [LiveEvent.ping].
  ///
  /// Luồng kết thúc khi server đóng (mỗi luồng sống 5 phút) hoặc mất mạng; ném `ApiException` khi không mở được
  /// (401 khi phiên đã hết). Người gọi tự mở lại; hủy lắng nghe thì kết nối được đóng.
  Stream<LiveEvent> open() => _api.openLines('/api/me/live').transform(const LiveEventParser());
}
