// Ảnh màn 06 "Thêm" (thành viên và khách) để so với design/figma-export/ref/06-*.png.
// Chạy: flutter test test/design_shots/more_shot_test.dart --dart-define=SHOTS=true
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/profile_controller.dart';
import 'package:myasvsj/com.myasvsj.model/profile_daily_usage.dart';
import 'package:myasvsj/com.myasvsj.model/user.dart';
import 'package:myasvsj/com.myasvsj.model/user_profile.dart';
import 'package:myasvsj/com.myasvsj.screen/more_screen.dart';

import '../auth_fakes.dart';
import '../notification_fakes.dart';
import '../profile_fakes.dart';
import 'shot_helper.dart';

void main() {
  const linh = User(id: 1, email: 'linh@example.com', displayName: 'Linh Nguyễn', role: 'USER', roleLabel: 'Người dùng');

  const linhProfile = UserProfile(
    id: 1,
    email: 'linh@example.com',
    displayName: 'Linh Nguyễn',
    roleLabel: 'Người dùng',
    points: 1250,
    ranks: ranks,
    tags: [],
    areaId: 679,
    areaName: 'Arakawa',
    stage: 'ARR',
    accountAgeDays: 30,
    newAccount: false,
    newAccountDays: 7,
    today: ProfileDailyUsage(posts: 0, maxPosts: 3, maxPins: 2, maxVideos: 1),
    savedCount: 4,
  );

  Widget app({required bool signedIn}) => MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthController(FakeAuthDao(current: signedIn ? linh : null))..restoreSession(),
          ),
          ChangeNotifierProvider(
            create: (_) => ProfileController(FakeProfileDao()
              ..profile = linhProfile),
          ),
          ChangeNotifierProvider(create: (_) => NotificationController(FakeNotificationDao())),
        ],
        child: shotApp(const MoreScreen()),
      );

  testWidgets('06 Thêm — thành viên', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(signedIn: true), height: 1000);
    await saveShot(tester, '06-more-member');
  });

  testWidgets('06 Thêm — khách', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(signedIn: false));
    await saveShot(tester, '06-more-guest');
  });
}
