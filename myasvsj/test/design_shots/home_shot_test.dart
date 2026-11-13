// Ảnh màn 01–05 (Trang chủ khách / thành viên, Tìm kiếm, Dành cho bạn, Thông báo) để so với
// design/figma-export/ref/01-*.png … 05-*.png. Dữ liệu là chữ mẫu của thiết kế (chỉ dùng cho ảnh).
// Chạy: flutter test test/design_shots/home_shot_test.dart --dart-define=SHOTS=true
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';
import 'package:myasvsj/com.myasvsj.model/app_notification.dart';
import 'package:myasvsj/com.myasvsj.model/feed_post.dart';
import 'package:myasvsj/com.myasvsj.model/feed_reason.dart';
import 'package:myasvsj/com.myasvsj.model/home_event.dart';
import 'package:myasvsj/com.myasvsj.model/home_featured.dart';
import 'package:myasvsj/com.myasvsj.model/home_guest.dart';
import 'package:myasvsj/com.myasvsj.model/home_guide_next.dart';
import 'package:myasvsj/com.myasvsj.model/home_guide_progress.dart';
import 'package:myasvsj/com.myasvsj.model/home_member.dart';
import 'package:myasvsj/com.myasvsj.model/home_phrase.dart';
import 'package:myasvsj/com.myasvsj.model/home_quote.dart';
import 'package:myasvsj/com.myasvsj.model/home_review.dart';
import 'package:myasvsj/com.myasvsj.model/home_tag.dart';
import 'package:myasvsj/com.myasvsj.model/search_place.dart';
import 'package:myasvsj/com.myasvsj.model/search_post.dart';
import 'package:myasvsj/com.myasvsj.model/search_question.dart';
import 'package:myasvsj/com.myasvsj.model/search_result.dart';
import 'package:myasvsj/com.myasvsj.model/search_section.dart';
import 'package:myasvsj/com.myasvsj.screen/for_you_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/global_search_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/home_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/notification_screen.dart';

import '../home_fakes.dart';
import '../notification_fakes.dart';
import '../notification_test_app.dart';
import 'shot_helper.dart';

final _now = DateTime.now();
DateTime _ago(Duration d) => _now.subtract(d);

const _arakawa = 'Arakawa-ku, Tokyo · 東京都荒川区';

const _guest = HomeGuest(
  placesWithReviews: 1240,
  reviewCount: 3580,
  phraseCount: 620,
  quotes: [
    HomeQuote(
      text: 'Gyomu Super ở đây rẻ hơn hẳn, thứ Ba có giảm giá rau. Nhân viên kiên nhẫn với người mới.',
      authorName: 'Hà Phương',
      authorTags: [HomeTag(name: 'Du học sinh', color: '#C2456E')],
      placeName: 'Gyomu Super Minami-Senju',
    ),
    HomeQuote(
      text: 'Làm thủ tục chuyển địa chỉ mất 40 phút, nhớ mang thẻ cư trú và hợp đồng nhà.',
      authorName: 'Quang Huy',
      authorTags: [HomeTag(name: 'Đã đi làm', color: '#2F3E6E')],
      placeName: 'Arakawa Ward Office',
    ),
  ],
  phrase: HomePhrase(
    japanese: '袋はいりません。',
    romaji: 'Fukuro wa irimasen.',
    meaningVi: 'Tôi không cần túi ạ.',
    categoryId: 'konbini',
    categoryName: 'Cửa hàng tiện lợi',
    categoryIcon: 'storefront',
  ),
);

List<FeedPost> get _feed => [
  FeedPost(
    id: 11,
    title: 'Thuê nhà không cần người bảo lãnh ở Tokyo: mình đã làm thế nào',
    excerpt: 'Ba công ty nhận hồ sơ du học sinh, phí bảo lãnh khoảng 50% tiền nhà một tháng. Mình kể lại từng bước…',
    authorName: 'Minh Anh',
    topicName: 'Nhà ở',
    likeCount: 24,
    commentCount: 8,
    createdAt: _ago(const Duration(hours: 2)),
    reasons: const [FeedReason(code: 'AREA', label: 'Gần bạn', detail: 'Arakawa')],
  ),
  FeedPost(
    id: 12,
    title: 'Checklist 2 tuần đầu: SIM, ngân hàng, thẻ My Number',
    excerpt: 'Thứ tự làm giấy tờ để không phải chạy đi chạy lại văn phòng quận.',
    authorName: 'Tuấn',
    topicName: 'Nhà ở',
    likeCount: 41,
    commentCount: 12,
    createdAt: _ago(const Duration(days: 1)),
    reasons: const [FeedReason(code: 'STAGE', label: 'Hợp giai đoạn', detail: 'Mới đến')],
  ),
  FeedPost(
    id: 13,
    title: 'Xin baito ở konbini: phỏng vấn hỏi những gì?',
    excerpt: 'Những câu hay gặp và cách trả lời bằng tiếng Nhật đơn giản…',
    authorName: 'Hà Phương',
    topicName: 'Việc làm thêm',
    likeCount: 57,
    commentCount: 20,
    createdAt: _ago(const Duration(days: 3)),
    reasons: const [FeedReason(code: 'INTEREST', label: 'Chủ đề', detail: 'Việc làm thêm')],
  ),
];

HomeMember get _member => HomeMember(
  displayName: 'Nguyễn Linh',
  stage: 'ARR',
  areaId: 679,
  areaName: _arakawa,
  points: 1250,
  rankName: 'Senpai bạc',
  guide: const HomeGuideProgress(
    stageCode: 'ARR',
    stageTitle: 'Mới đến Nhật',
    done: 3,
    total: 8,
    next: HomeGuideNext(
      guideId: 21,
      title: 'Đăng ký địa chỉ tại văn phòng quận',
      dueNote: 'Hạn: trong 14 ngày kể từ khi chuyển đến',
      placeName: 'Arakawa Ward Office',
      placeId: 6,
      checklist: true,
      tasksDone: 2,
      tasksTotal: 5,
      nextTask: 'Mang thẻ cư trú tới quầy 住民登録',
    ),
  ),
  forYou: _feed.take(2).toList(),
  interests: const ['Nhà ở'],
  chosenInterests: const ['Nhà ở'],
  reviews: [
    HomeReview(
      id: 1,
      placeId: 1,
      placeName: 'Gyomu Super Minami-Senju',
      categoryIcon: 'shopping_cart',
      placeArea: 'Arakawa · 荒川区',
      near: 'AREA',
      rating: 4,
      authorName: 'Hà',
      excerpt: 'Rau thứ Ba giảm 20%, có góc đồ châu Á, nước mắm Phú Quốc.',
      createdAt: _ago(const Duration(hours: 3)),
    ),
    HomeReview(
      id: 2,
      placeId: 2,
      placeName: 'Ga Machiya (Chiyoda Line)',
      categoryIcon: 'train',
      placeArea: 'Arakawa · 荒川区',
      near: 'AREA',
      rating: 5,
      authorName: 'Huy',
      excerpt: 'Cửa A2 có thang máy, mua thẻ Suica ở máy màu xanh.',
      createdAt: _ago(const Duration(days: 1)),
    ),
    HomeReview(
      id: 3,
      placeId: 3,
      placeName: 'Phòng khám Nishi-Nippori',
      categoryIcon: 'local_hospital',
      placeArea: 'Arakawa · 荒川区',
      near: 'AREA',
      rating: 4,
      authorName: 'Mai',
      excerpt: 'Bác sĩ nói chậm, có giấy hỏi bệnh tiếng Anh.',
      createdAt: _ago(const Duration(days: 2)),
    ),
  ],
  events: [
    HomeEvent(
      id: 1,
      title: 'Tori-no-ichi — Chợ phiên Gà',
      startDate: DateTime(2026, 11, 15),
      endDate: DateTime(2026, 11, 15),
      locationName: 'Đền Ōtori, Asakusa',
      daysUntil: 7,
    ),
    HomeEvent(
      id: 2,
      title: 'Lễ hội lá phong Rikugien',
      startDate: DateTime(2026, 11, 8),
      endDate: DateTime(2026, 11, 30),
      locationName: 'Komagome',
    ),
  ],
  phrase: const HomePhrase(
    japanese: 'すみません、ゴミの日はいつですか？',
    romaji: 'Sumimasen, gomi no hi wa itsu desu ka?',
    meaningVi: 'Xin lỗi, ngày đổ rác là khi nào ạ?',
    categoryId: 'ward',
    categoryName: 'Văn phòng quận',
    categoryIcon: 'account_balance',
  ),
  featured: const HomeFeatured(
    id: 2,
    title: 'Mùa hanami đầu tiên: 6 công viên ít đông người ở Tokyo',
    excerpt: 'Chọn giờ, mang gì và những phép lịch sự khi ngồi dưới gốc anh đào…',
    authorName: 'Thảo Vy',
    authorTags: [HomeTag(name: 'Đã đi làm', color: '#2F3E6E')],
    readMinutes: 5,
  ),
);

/// DAO tìm kiếm trả kết quả mẫu "nhà ở" của thiết kế.
class _DesignSearchDao extends FakeSearchDao {
  @override
  Future<SearchResult> search(String q) async {
    asked.add(q);
    if (q.trim().isEmpty) {
      return const SearchResult();
    }
    return SearchResult(
      q: q.trim(),
      total: 24,
      places: const SearchSection(
        total: 5,
        items: [
          SearchPlace(
            id: 1,
            name: 'Leopalace21 Arakawa (văn phòng cho thuê nhà ở)',
            nameJa: 'レオパレス21',
            categoryName: 'Bất động sản',
            categoryIcon: 'apartment',
            address: '3-1 Arakawa, Arakawa-ku',
            reviewCount: 12,
            rating: 4.1,
          ),
          SearchPlace(
            id: 2,
            name: 'Sakura House Nippori — nhà ở chung',
            nameJa: 'さくらハウス',
            categoryName: 'Share house',
            categoryIcon: 'home',
            address: 'Nishi-Nippori',
          ),
        ],
      ),
      posts: SearchSection(
        total: 8,
        items: [
          SearchPost(
            id: 1,
            title: 'Kinh nghiệm tìm nhà ở Tokyo khi chưa có người bảo lãnh',
            excerpt: '…ba công ty nhận hồ sơ du học sinh, phí bảo lãnh khoảng 50% tiền nhà…',
            topicNames: const ['Nhà ở'],
            authorName: 'Minh Anh',
            likeCount: 24,
            commentCount: 8,
            createdAt: _ago(const Duration(hours: 2)),
          ),
          SearchPost(
            id: 2,
            title: 'Hợp đồng nhà ở: đọc 重要事項説明 thế nào?',
            topicNames: const ['Nhà ở'],
            authorName: 'Quang Huy',
            createdAt: _ago(const Duration(days: 3)),
          ),
        ],
      ),
      questions: SearchSection(
        total: 6,
        items: [
          SearchQuestion(
            id: 1,
            title: 'Hết hợp đồng nhà ở có được lấy lại tiền đặt cọc không?',
            solved: true,
            authorName: 'Lan',
            answerCount: 5,
            createdAt: _ago(const Duration(days: 7)),
          ),
        ],
      ),
      guides: const SearchSection(total: 3),
    );
  }
}

List<AppNotification> get _notifications => [
  AppNotification(
    id: 7,
    type: 'BEST_ANSWER',
    content: 'Câu trả lời của bạn được chọn là hay nhất trong “Gia hạn visa du học cần giấy tờ gì?” · +5 điểm',
    createdAt: _ago(const Duration(minutes: 12)),
  ),
  AppNotification(
    id: 6,
    type: 'NEW_COMMENT',
    content: 'Minh Anh đã bình luận bài “Thuê nhà không cần người bảo lãnh”',
    createdAt: _ago(const Duration(hours: 1)),
  ),
  AppNotification(
    id: 5,
    type: 'PIN_APPROVED',
    content: 'Ghim “Chùa Sensō-ji cổng sau” của bạn đã được duyệt · +15 điểm',
    createdAt: _ago(const Duration(hours: 3)),
  ),
  AppNotification(
    id: 4,
    type: 'CONTENT_PUBLISHED',
    content: 'Review “Gyomu Super Minami-Senju” đã được đăng.',
    createdAt: _ago(const Duration(days: 1)),
  ),
  AppNotification(
    id: 3,
    type: 'TAG_GRANTED',
    content: 'Bạn đã được cấp tag “Du học sinh”.',
    createdAt: _ago(const Duration(days: 1, hours: 1)),
  ),
  AppNotification(
    id: 2,
    type: 'CONTENT_REJECTED',
    content: 'Ảnh trong bài “Đi Kamakura 1 ngày” vi phạm Quy tắc cộng đồng.',
    read: true,
    createdAt: _ago(const Duration(days: 2)),
  ),
  AppNotification(
    id: 1,
    type: 'WELCOME',
    content: 'Chào mừng bạn đến Senpai ơi! Chọn khu vực để nhận gợi ý gần bạn.',
    read: true,
    createdAt: _ago(const Duration(days: 5)),
  ),
];

void main() {
  testWidgets('01 Trang chủ — khách', skip: shotSkip != null, (tester) async {
    final dao = FakeHomeDao()..guest = _guest;
    await pumpShot(tester, homeTestApp(home: shotTheme(const HomeScreen()), homeDao: dao), height: 1720);
    await saveShot(tester, '01-home-guest');
  });

  testWidgets('02 Trang chủ — thành viên', skip: shotSkip != null, (tester) async {
    final dao = FakeHomeDao()..member = _member;
    await pumpShot(tester, homeTestApp(home: shotTheme(const HomeScreen()), homeDao: dao, signedIn: true), height: 2330);
    await saveShot(tester, '02-home-member');
  });

  testWidgets('02 Trang chủ — thành viên chưa chọn khu vực', skip: shotSkip != null, (tester) async {
    final dao = FakeHomeDao()..member = memberWithoutArea;
    await pumpShot(tester, homeTestApp(home: shotTheme(const HomeScreen()), homeDao: dao, signedIn: true));
    await saveShot(tester, '02-home-member-no-area');
  });

  testWidgets('03 Tìm kiếm — kết quả', skip: shotSkip != null, (tester) async {
    await pumpShot(
      tester,
      homeTestApp(home: const _Pushed(GlobalSearchScreen(initialQuery: 'nhà ở')), searchDao: _DesignSearchDao()),
    );
    await saveShot(tester, '03-search');
  });

  testWidgets('03 Tìm kiếm — ô trống', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, homeTestApp(home: const _Pushed(GlobalSearchScreen()), searchDao: _DesignSearchDao()));
    await saveShot(tester, '03-search-ideas');
  });

  testWidgets('03 Tìm kiếm — không thấy gì', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, homeTestApp(home: const _Pushed(GlobalSearchScreen(initialQuery: 'xyz không có'))));
    await saveShot(tester, '03-search-nothing');
  });

  testWidgets('04 Dành cho bạn', skip: shotSkip != null, (tester) async {
    final dao = FakeHomeDao()
      ..member = _member
      ..feed = _feed;
    await pumpShot(tester, homeTestApp(home: const _Pushed(ForYouScreen()), homeDao: dao, signedIn: true));
    await saveShot(tester, '04-for-you');
  });

  testWidgets('04 Dành cho bạn — khách', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, homeTestApp(home: const _Pushed(ForYouScreen())));
    await saveShot(tester, '04-for-you-guest');
  });

  testWidgets('05 Thông báo', skip: shotSkip != null, (tester) async {
    final auth = await tester.runAsync(signedInAuth);
    await pumpShot(
      tester,
      notifyChatApp(
        home: const _Pushed(NotificationScreen()),
        auth: auth,
        notifications: NotificationController(FakeNotificationDao(stored: _notifications)),
      ),
    );
    await saveShot(tester, '05-notifications');
  });

  testWidgets('05 Thông báo — trống', skip: shotSkip != null, (tester) async {
    final auth = await tester.runAsync(signedInAuth);
    await pumpShot(
      tester,
      notifyChatApp(
        home: const _Pushed(NotificationScreen()),
        auth: auth,
        notifications: NotificationController(FakeNotificationDao(stored: [])),
      ),
    );
    await saveShot(tester, '05-notifications-empty');
  });
}

/// Màn gốc trống, khung hình đầu tiên tự mở [screen] (trong theme của app) để thanh tiêu đề có nút quay lại như
/// khi mở từ trang chủ.
class _Pushed extends StatefulWidget {
  const _Pushed(this.screen);

  final Widget screen;

  @override
  State<_Pushed> createState() => _PushedState();
}

class _PushedState extends State<_Pushed> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => shotTheme(widget.screen)));
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
