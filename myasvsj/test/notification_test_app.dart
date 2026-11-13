import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/chat_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';

import 'auth_fakes.dart';
import 'chat_fakes.dart';
import 'notification_fakes.dart';

/// AuthController đã đăng nhập bằng [testUser] (phiên cũ được khôi phục từ DAO giả).
Future<AuthController> signedInAuth() async {
  final auth = AuthController(FakeAuthDao(current: testUser));
  await auth.restoreSession();
  return auth;
}

/// App thử cho màn hình Thông báo / Tin nhắn: cấp AuthController, NotificationController, ChatController (DAO giả).
/// Controller được tạo bằng `create` nên được dispose khi test tháo cây widget (không còn Timer chờ).
Widget notifyChatApp({
  required Widget home,
  AuthController? auth,
  NotificationController? notifications,
  ChatController? chat,
}) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => auth ?? AuthController(FakeAuthDao())),
    ChangeNotifierProvider(create: (_) => notifications ?? NotificationController(FakeNotificationDao())),
    ChangeNotifierProvider(create: (_) => chat ?? ChatController(FakeChatDao())),
  ],
  child: MaterialApp(debugShowCheckedModeBanner: false, home: home),
);
