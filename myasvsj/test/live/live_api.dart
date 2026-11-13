// Test với server web thật (Spring Boot chạy ở máy dev, dữ liệu mẫu của profile local).
//
// Bỏ qua khi chạy `flutter test` bình thường. Chạy riêng:
//   flutter test test/live --dart-define=LIVE_API=http://localhost:8080
//
// Tài khoản mẫu (mật khẩu 123456): user@gmail.com, mentor@gmail.com, kouhai@gmail.com (USER),
// moderator@gmail.com, academic@gmail.com, admin@gmail.com (staff).
import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/auth_dao.dart';

/// Địa chỉ server khi chạy test live; rỗng = không chạy.
const liveBaseUrl = String.fromEnvironment('LIVE_API');

/// Đưa vào tham số `skip:` của `test` / `group`: bỏ qua khi không có server.
const String? liveSkip = liveBaseUrl == '' ? 'Cần --dart-define=LIVE_API=http://localhost:8080' : null;

/// ApiClient của khách (chưa đăng nhập).
ApiClient liveGuest() => ApiClient.inMemory(liveBaseUrl);

/// ApiClient đã đăng nhập bằng tài khoản mẫu [email].
Future<ApiClient> liveSignedIn(String email, {String password = '123456'}) async {
  final api = ApiClient.inMemory(liveBaseUrl);
  await AuthDao(api).login(email, password);
  return api;
}
