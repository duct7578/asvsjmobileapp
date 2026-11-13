// Khung cho widget test của Hỏi-Đáp: cấp các Controller dùng DAO giả bằng Provider, như main.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/faq_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/question_controller.dart';
import 'package:myasvsj/com.myasvsj.model/notification_dao.dart';
import 'package:myasvsj/com.myasvsj.model/user.dart';

import 'auth_fakes.dart';
import 'faq_fakes.dart';
import 'question_fakes.dart';

/// DAO thông báo giả cho thanh tiêu đề (AppBarActions chỉ đọc `unreadCount`).
class QaFakeNotificationDao implements NotificationDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// App thử: [home] là màn hình cần test; [user] khác null = đã đăng nhập.
Widget qaTestApp({required Widget home, required FakeQuestionDao questions, FakeFaqDao? faqs, User? user}) =>
    MultiProvider(
      providers: [
        // Như main.dart: hỏi "phiên cũ" lúc mở app; FakeAuthDao trả về [user]
        ChangeNotifierProvider(create: (_) => AuthController(FakeAuthDao(current: user))..restoreSession()),
        ChangeNotifierProvider(create: (_) => NotificationController(QaFakeNotificationDao())),
        ChangeNotifierProvider(create: (_) => QuestionController(questions)),
        ChangeNotifierProvider(
          create: (_) => FaqController(faqs ?? FakeFaqDao(), suggestDelay: const Duration(milliseconds: 50)),
        ),
      ],
      child: MaterialApp(home: home),
    );

/// Màn thử cao hơn mặc định (800 × 600) để danh sách dài dựng đủ các thẻ.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}
