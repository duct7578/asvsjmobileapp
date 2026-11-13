import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thông báo trên máy (khay thông báo của Android / iOS) qua thư viện `flutter_local_notifications`.
///
/// Chỉ dùng khi app đang mở: app nghe luồng tức thì của server rồi tự hiện thông báo trên máy. Không có thông báo khi
/// app đã đóng (cần push/FCM, ngoài phạm vi).
///
/// Bọc plugin trong một lớp để Controller không phụ thuộc plugin: test thay bằng lớp giả `implements NotificationDevice`.
/// Hàm tạo không gọi plugin; plugin được khởi động ở lần dùng đầu tiên. Trên nền tảng không hỗ trợ (test, máy tính)
/// mọi hàm lặng lẽ không làm gì.
class NotificationDevice {
  NotificationDevice();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  /// Plugin chỉ nhận một hàm xử lý khi bấm, nên mọi đối tượng dùng chung một luồng.
  static final StreamController<String> _taps = StreamController<String>.broadcast();
  static Future<bool>? _ready;
  static String? _launchLink;

  /// Kênh thông báo trên Android (người dùng thấy tên kênh trong Cài đặt của máy).
  static const String channelId = 'senpai_notifications';
  static const String channelName = 'Thông báo và tin nhắn';

  /// Đường dẫn web (`/blog/12`, `/messages/3`…) của thông báo người dùng vừa bấm, khi app đang chạy.
  Stream<String> get taps => _taps.stream;

  /// Đường dẫn của thông báo đã mở app (app đã bị đóng sau khi hiện thông báo); trả về một lần rồi xóa.
  Future<String?> takeLaunchLink() async {
    await _init();
    final link = _launchLink;
    _launchLink = null;
    return link;
  }

  /// Lần xin quyền đang chờ người dùng trả lời: Android từ chối yêu cầu thứ hai khi hộp thoại đầu còn mở
  /// ("permissionRequestInProgress"), nên các lần gọi trùng nhau dùng chung một lần xin.
  static Future<bool>? _asking;

  /// Xin quyền hiện thông báo: POST_NOTIFICATIONS trên Android 13+, hộp thoại xin quyền trên iOS.
  /// Trả về true khi được phép (Android cũ luôn được phép).
  Future<bool> requestPermission() => _asking ??= _askPermission().whenComplete(() => _asking = null);

  Future<bool> _askPermission() async {
    if (!await _init()) {
      return false;
    }
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(alert: true, badge: true, sound: true) ?? false;
      }
    } on Exception catch (e) {
      debugPrint('NotificationDevice.requestPermission: $e');
    }
    return false;
  }

  /// Hiện một thông báo. [id] trùng thì thông báo cũ được thay (một thông báo cho mỗi cuộc trò chuyện);
  /// bấm vào thì [link] được đưa ra [taps].
  Future<void> show({required int id, required String title, required String body, String? link}) async {
    if (!await _init()) {
      return;
    }
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        payload: link,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: 'Thông báo mới và tin nhắn mới khi app đang mở',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } on Exception catch (e) {
      debugPrint('NotificationDevice.show: $e');
    }
  }

  static Future<bool> _init() => _ready ??= _initialize();

  static Future<bool> _initialize() async {
    try {
      final ok = await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Không xin quyền ngay khi khởi động: requestPermission() xin sau khi đăng nhập
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final link = response.payload;
          if (link != null && link.isNotEmpty) {
            _taps.add(link);
          }
        },
      );
      final launch = await _plugin.getNotificationAppLaunchDetails();
      final link = launch?.notificationResponse?.payload;
      if ((launch?.didNotificationLaunchApp ?? false) && link != null && link.isNotEmpty) {
        _launchLink = link;
      }
      return ok ?? false;
    } on Object catch (e) {
      // Nền tảng chưa có plugin (test, Windows chưa cấu hình): không hiện thông báo trên máy
      debugPrint('NotificationDevice: $e');
      return false;
    }
  }
}
