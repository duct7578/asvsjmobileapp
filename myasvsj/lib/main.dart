import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/area_stage_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/blog_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/chat_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/event_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/faq_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/global_search_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/guide_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/home_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/interest_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/phrase_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/place_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/profile_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/question_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/review_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/saved_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/tag_request_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/auth_dao.dart';
import 'package:myasvsj/com.myasvsj.model/blog_dao.dart';
import 'package:myasvsj/com.myasvsj.model/chat_dao.dart';
import 'package:myasvsj/com.myasvsj.model/chat_device_key_dao.dart';
import 'package:myasvsj/com.myasvsj.model/chat_key_dao.dart';
import 'package:myasvsj/com.myasvsj.model/event_dao.dart';
import 'package:myasvsj/com.myasvsj.model/faq_dao.dart';
import 'package:myasvsj/com.myasvsj.model/guide_dao.dart';
import 'package:myasvsj/com.myasvsj.model/home_dao.dart';
import 'package:myasvsj/com.myasvsj.model/live_dao.dart';
import 'package:myasvsj/com.myasvsj.model/notification_dao.dart';
import 'package:myasvsj/com.myasvsj.model/notification_device.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_dao.dart';
import 'package:myasvsj/com.myasvsj.model/place_dao.dart';
import 'package:myasvsj/com.myasvsj.model/profile_dao.dart';
import 'package:myasvsj/com.myasvsj.model/question_dao.dart';
import 'package:myasvsj/com.myasvsj.model/review_dao.dart';
import 'package:myasvsj/com.myasvsj.model/saved_dao.dart';
import 'package:myasvsj/com.myasvsj.model/search_dao.dart';
import 'package:myasvsj/com.myasvsj.screen/main_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/notification_host.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';

/// Điểm khởi động: tạo ApiClient một lần, nối DAO vào Controller, rồi cấp Controller cho mọi màn hình
/// bằng Provider. Ngoài thư mục Model, đây là nơi duy nhất biết tới DAO và ApiClient.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = await ApiClient.create();
  runApp(SenpaiApp(api: api));
}

class SenpaiApp extends StatelessWidget {
  const SenpaiApp({super.key, required this.api});

  final ApiClient api;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController(AuthDao(api))..restoreSession()),
        ChangeNotifierProvider(create: (_) => BlogController(BlogDao(api))..loadBlogs()),
        ChangeNotifierProvider(create: (_) => HomeController(HomeDao(api))),
        ChangeNotifierProvider(create: (_) => GlobalSearchController(SearchDao(api))),
        ChangeNotifierProvider(create: (_) => ProfileController(ProfileDao(api))),
        ChangeNotifierProvider(create: (_) => SavedController(SavedDao(api))),
        ChangeNotifierProvider(create: (_) => AreaStageController(ProfileDao(api))),
        ChangeNotifierProvider(create: (_) => InterestController(ProfileDao(api))),
        ChangeNotifierProvider(create: (_) => TagRequestController(ProfileDao(api))),
        ChangeNotifierProvider(create: (_) => QuestionController(QuestionDao(api))),
        ChangeNotifierProvider(create: (_) => FaqController(FaqDao(api))),
        ChangeNotifierProvider(create: (_) => EventController(EventDao(api))),
        ChangeNotifierProvider(create: (_) => GuideController(GuideDao(api))),
        ChangeNotifierProvider(create: (_) => PlaceController(PlaceDao(api))),
        ChangeNotifierProvider(create: (_) => ReviewController(ReviewDao(api))),
        ChangeNotifierProvider(create: (_) => PhraseController(PhraseDao(api))),
        // Luồng tức thì /api/me/live và thông báo trên máy chạy khi đã đăng nhập; NotificationHost nối chúng
        // với đăng nhập / đăng xuất, app mở lại từ nền, và bấm thông báo trên máy.
        ChangeNotifierProvider(
          create: (_) => NotificationController(NotificationDao(api), live: LiveDao(api), device: NotificationDevice()),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatController(
            ChatDao(api),
            keyDao: ChatKeyDao(api),
            deviceKeys: ChatDeviceKeyDao(),
            device: NotificationDevice(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Senpai ơi',
        debugShowCheckedModeBanner: false,
        theme: SenpaiTheme.light(),
        home: const NotificationHost(child: MainScreen()),
      ),
    );
  }
}
