import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/notification_page.dart';
import 'package:myasvsj/com.myasvsj.model/notification_summary.dart';

/// Truy cập thông báo của người đang đăng nhập (bảng `notifications`) qua REST API của web.
/// Mọi hàm cần đăng nhập; khách nhận 401.
///
/// | Hàm          | API                                         |
/// |--------------|---------------------------------------------|
/// | findAll      | GET /api/me/notifications?page=             |
/// | findSummary  | GET /api/me/notifications/summary?after=    |
/// | markRead     | POST /api/me/notifications/read {upToId}    |
class NotificationDao {
  NotificationDao(this._api);

  final ApiClient _api;

  /// Số thông báo mỗi trang (NotificationService.PAGE_SIZE của server).
  static const int pageSize = 20;

  /// Một trang thông báo (trang đầu là 0), mới nhất trước, kèm số chưa đọc.
  Future<NotificationPage> findAll({int page = 0}) async =>
      NotificationPage.fromJson(await _api.get('/api/me/notifications', query: {'page': page}) as Map<String, dynamic>);

  /// Số chưa đọc, id mới nhất và (khi có [after]) tối đa 5 thông báo mới hơn id đó.
  Future<NotificationSummary> findSummary({int? after}) async => NotificationSummary.fromJson(
    await _api.get('/api/me/notifications/summary', query: {'after': ?after}) as Map<String, dynamic>,
  );

  /// Đánh dấu đã đọc mọi thông báo có id ≤ [upToId] (null: tất cả). Trả về số chưa đọc còn lại.
  Future<int> markRead({int? upToId}) async {
    final response = await _api.post('/api/me/notifications/read', {'upToId': upToId});
    final data = response.data;
    return data is Map && data['unread'] is int ? data['unread'] as int : 0;
  }
}
