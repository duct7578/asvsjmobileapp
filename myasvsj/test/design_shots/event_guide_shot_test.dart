// Ảnh các màn 19–24 "Sự kiện & Cẩm nang" để so với design/figma-export/ref/19-*.png … 24-*.png.
// Chạy: flutter test test/design_shots/event_guide_shot_test.dart --dart-define=SHOTS=true
//
// Ảnh tham chiếu cao hơn 44 px vì có thanh trạng thái giả; ảnh Flutter không có, nên chiều cao = cao ảnh mẫu − 44.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/event_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/guide_controller.dart';
import 'package:myasvsj/com.myasvsj.model/author.dart';
import 'package:myasvsj/com.myasvsj.model/event.dart';
import 'package:myasvsj/com.myasvsj.model/event_detail.dart';
import 'package:myasvsj/com.myasvsj.model/event_photo.dart';
import 'package:myasvsj/com.myasvsj.model/event_review.dart';
import 'package:myasvsj/com.myasvsj.model/event_review_form.dart';
import 'package:myasvsj/com.myasvsj.model/guide.dart';
import 'package:myasvsj/com.myasvsj.model/guide_activity.dart';
import 'package:myasvsj/com.myasvsj.model/guide_my_progress.dart';
import 'package:myasvsj/com.myasvsj.model/guide_option.dart';
import 'package:myasvsj/com.myasvsj.model/guide_section.dart';
import 'package:myasvsj/com.myasvsj.model/guide_stage_progress.dart';
import 'package:myasvsj/com.myasvsj.model/guide_task.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.model/page_result.dart';
import 'package:myasvsj/com.myasvsj.screen/event_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/event_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/event_review_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/my_guides_screen.dart';

import '../auth_fakes.dart';
import '../event_fakes.dart';
import '../guide_fakes.dart';
import 'shot_helper.dart';

// ---------------------------------------------------------------- Dữ liệu mẫu (chữ mẫu của thiết kế)

/// Id 6 → cảnh Festival, id 7 → cảnh Torii (như ảnh mẫu).
final rikugien = Event(
  id: 6,
  title: 'Lễ hội lá phong Rikugien — chiếu sáng đêm',
  startDate: DateTime(2026, 11, 1),
  endDate: DateTime(2026, 12, 7),
  locationName: 'Vườn Rikugien, Komagome',
  lat: 35.733,
  lng: 139.746,
  costNote: '300 yên',
  state: Event.now,
  reviewYear: 2026,
  canReview: true,
  avgRating: 4.5,
  reviewCount: 32,
);

final toriNoIchi = Event(
  id: 7,
  title: 'Tori-no-ichi — Chợ phiên Gà',
  startDate: DateTime(2026, 11, 15),
  endDate: DateTime(2026, 11, 27),
  locationName: 'Đền Ōtori, Asakusa',
  costNote: 'Miễn phí',
  daysUntil: 7,
  reviewYear: 2026,
);

FakeEventDao eventDao() {
  final dao = FakeEventDao()..events = [rikugien, toriNoIchi];
  dao.details[6] = EventDetail(
    event: rikugien.copyWithLocation('Vườn Rikugien, 6-16-3 Hon-Komagome, Bunkyō', '300 yên (sinh viên 150 yên)'),
    tip: 'Đi sau 19h để xem chiếu sáng, xếp hàng ở cổng Somei ít đông hơn cổng chính.',
    album: const [
      EventPhoto(url: '/media/review/1.jpg', authorName: 'Ngọc', year: 2025),
      EventPhoto(url: '/media/review/2.jpg', authorName: 'Ngọc', year: 2025),
      EventPhoto(url: '/media/review/3.jpg', authorName: 'Lan', year: 2025),
    ],
    albumCount: 24,
    reviews: [
      EventReview(
        id: 30,
        author: const Author(id: 4, displayName: 'Ngọc', tagNames: ['Du học sinh']),
        rating: 5,
        content: 'Ánh đèn chiếu lên hồ đẹp lắm, nên đi ngày thường. Có quầy trà matcha 600 yên ngay cạnh hồ.',
        year: 2025,
        createdAt: DateTime(2025, 11, 2),
        likeCount: 7,
        media: const [
          MediaItem(id: 1, type: 'IMAGE', url: '/media/review/1.jpg'),
          MediaItem(id: 2, type: 'IMAGE', url: '/media/review/2.jpg'),
        ],
      ),
    ],
    signedIn: true,
    member: true,
    reportReasons: reportReasons,
  );
  dao.form = EventReviewForm(
    event: rikugien,
    imagesMax: 6,
    newAccount: true,
    postsUsed: 1,
    postsLimit: 3,
    pinsLimit: 1,
    videosLimit: 1,
  );
  return dao;
}

extension on Event {
  Event copyWithLocation(String location, String cost) => Event(
    id: id,
    title: title,
    startDate: startDate,
    endDate: endDate,
    locationName: location,
    lat: lat,
    lng: lng,
    costNote: cost,
    state: state,
    reviewYear: reviewYear,
    canReview: canReview,
    avgRating: avgRating,
    reviewCount: reviewCount,
  );
}

const shotStages = [
  GuideOption(code: 'PRE', title: 'Sắp sang Nhật'),
  GuideOption(code: 'ARR', title: 'Mới đến'),
  GuideOption(code: 'LEAVE', title: 'Sắp về nước'),
  GuideOption(code: 'HOME', title: 'Đã về nước'),
];

const shotTopics = [
  GuideOption(code: 'PAPERS', title: 'Giấy tờ'),
  GuideOption(code: 'HOUSING', title: 'Nhà ở'),
  GuideOption(code: 'MONEY', title: 'Tài chính'),
  GuideOption(code: 'HEALTH', title: 'Y tế'),
];

/// Id 3 → cảnh City, 7 → Study, 5 → Park (như ảnh mẫu).
final shotGuides = [
  Guide(
    id: 3,
    title: 'Đăng ký địa chỉ tại văn phòng quận',
    summary: 'Làm trong 14 ngày sau khi chuyển đến: mang thẻ cư trú, hộ chiếu và hợp đồng nhà.',
    stageCode: 'ARR',
    stageName: 'Mới đến',
    topicCode: 'PAPERS',
    topicName: 'Giấy tờ',
    creatorName: 'Nhóm Senpai ơi',
    createdAt: DateTime(2026, 9, 12),
    sections: const [
      GuideSection(heading: 'Cần mang gì', content: '- Thẻ cư trú\n- Hộ chiếu\n- Hợp đồng nhà'),
    ],
    preparationEnabled: true,
    preparationTasks: const [
      GuideTask(id: 1, title: 'Nhận thẻ cư trú ở sân bay', notes: 'Thẻ ghi “住居地未定” nếu chưa có địa chỉ.'),
      GuideTask(id: 2, title: 'Ký hợp đồng nhà, lấy địa chỉ chính xác'),
      GuideTask(id: 3, title: 'Mang thẻ cư trú và hộ chiếu tới quầy 住民登録', notes: 'Văn phòng quận nơi bạn sống, trong 14 ngày.'),
      GuideTask(id: 4, title: 'Đăng ký bảo hiểm y tế quốc dân', notes: 'Làm cùng lúc ở quầy 国民健康保険.'),
      GuideTask(id: 5, title: 'Nhận thẻ thông báo My Number', notes: 'Gửi qua bưu điện sau 2–3 tuần.'),
    ],
  ),
  Guide(
    id: 7,
    title: 'Mở tài khoản ngân hàng khi mới sang',
    summary: 'Yuucho, ngân hàng lớn hay ngân hàng online: chọn sao cho dễ.',
    stageCode: 'ARR',
    stageName: 'Mới đến',
    topicCode: 'MONEY',
    topicName: 'Tài chính',
    createdAt: DateTime(2026, 9, 3),
  ),
  Guide(
    id: 5,
    title: 'Bảo hiểm y tế quốc dân 国民健康保険',
    summary: 'Đóng bao nhiêu, cách xin giảm phí cho du học sinh…',
    stageCode: 'ARR',
    stageName: 'Mới đến',
    topicCode: 'HEALTH',
    topicName: 'Y tế',
    createdAt: DateTime(2026, 8, 28),
  ),
];

/// DAO giả với giai đoạn / chủ đề / cẩm nang như ảnh mẫu, "18 cẩm nang phù hợp".
class ShotGuideDao extends FakeGuideDao {
  ShotGuideDao({super.signedIn}) {
    guides = shotGuides;
    savedIds.add(3);
    ticked[3] = {1, 2};
    myProgress = GuideMyProgress(
      stage: 'ARR',
      stages: const [
        GuideStageProgress(code: 'PRE', title: 'Sắp sang Nhật', done: 6, total: 6),
        GuideStageProgress(code: 'ARR', title: 'Mới đến', done: 3, total: 8, current: true),
        GuideStageProgress(code: 'LEAVE', title: 'Sắp về nước'),
        GuideStageProgress(code: 'HOME', title: 'Đã về nước', total: 4),
      ],
      inProgress: const [
        GuideActivity(
          id: 3,
          title: 'Đăng ký địa chỉ tại văn phòng quận',
          stageTitle: 'Mới đến',
          tasksDone: 2,
          tasksTotal: 5,
          percent: 40,
          nextTask: 'Mang thẻ cư trú và hộ chiếu tới quầy 住民登録',
        ),
      ],
      recentlyDone: [
        GuideActivity(id: 8, title: 'Mua SIM và đăng ký điện thoại', stageTitle: 'Mới đến', at: DateTime(2026, 9, 2)),
        GuideActivity(
          id: 9,
          title: 'Chuẩn bị hành lý và giấy tờ',
          stageTitle: 'Sắp sang Nhật',
          at: DateTime(2026, 8, 20),
        ),
      ],
    );
  }

  @override
  Future<List<GuideOption>> findStages() async => shotStages;

  @override
  Future<List<GuideOption>> findTopics() async => shotTopics;

  @override
  Future<PageResult<Guide>> findAll({String? stage, String? topic, String? q, String sort = 'NEWEST', int page = 0}) async {
    return PageResult(items: guides, page: 0, size: 3, totalItems: 18, totalPages: 6);
  }
}

// ---------------------------------------------------------------- Dựng app

/// Mở [screen] chồng lên một trang trống để AppBar có nút quay lại / đóng như thiết kế.
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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Navigator.of(context).push(
        PageRouteBuilder<void>(pageBuilder: (_, _, _) => widget.screen, transitionDuration: Duration.zero),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}

Widget app(Widget screen, {bool signedIn = true, FakeEventDao? events, FakeGuideDao? guides}) => MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) =>
          AuthController(FakeAuthDao(current: signedIn ? testUser : null))..currentUser = signedIn ? testUser : null,
    ),
    ChangeNotifierProvider(create: (_) => EventController(events ?? eventDao())),
    ChangeNotifierProvider(create: (_) => GuideController(guides ?? ShotGuideDao(signedIn: signedIn))),
  ],
  child: shotApp(_Pushed(screen)),
);

void main() {
  testWidgets('19 Lễ hội và sự kiện', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const EventListScreen()), height: 800);
    await saveShot(tester, '19-event-list');
  });

  testWidgets('20 Chi tiết sự kiện', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const EventDetailScreen(eventId: 6)), height: 1389);
    await saveShot(tester, '20-event-detail');
  });

  testWidgets('20 Chi tiết sự kiện — sắp diễn ra, chưa gắn vị trí, khách', skip: shotSkip != null, (tester) async {
    final dao = eventDao();
    dao.details[7] = EventDetail(event: toriNoIchi);
    await pumpShot(tester, app(const EventDetailScreen(eventId: 7), signedIn: false, events: dao));
    await saveShot(tester, '20-event-detail-upcoming');
  });

  testWidgets('21 Viết review sự kiện', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const EventReviewFormScreen(eventId: 6)), height: 800);
    await tester.tap(find.byTooltip('5 sao'));
    await tester.tap(find.byType(TextField));
    await settleShot(tester);
    await saveShot(tester, '21-event-review-form');
  });

  testWidgets('22 Cẩm nang', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const GuideListScreen(stage: 'ARR')), height: 800);
    await saveShot(tester, '22-guide-list');
  });

  testWidgets('23 Chi tiết cẩm nang — tab Hướng dẫn chuẩn bị', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const GuideDetailScreen(guideId: 3, openChecklist: true)), height: 852);
    await saveShot(tester, '23-guide-detail-checklist');
  });

  testWidgets('23 Chi tiết cẩm nang — tab Xem chi tiết', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const GuideDetailScreen(guideId: 3)), height: 852);
    await saveShot(tester, '23-guide-detail-info');
  });

  testWidgets('23 Chi tiết cẩm nang — khách', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const GuideDetailScreen(guideId: 3, openChecklist: true), signedIn: false), height: 1000);
    await saveShot(tester, '23-guide-detail-guest');
  });

  testWidgets('24 Cẩm nang của tôi', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const MyGuidesScreen()), height: 800);
    await saveShot(tester, '24-my-guides');
  });

  testWidgets('24 Cẩm nang của tôi — khách', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, app(const MyGuidesScreen(), signedIn: false), height: 800);
    await saveShot(tester, '24-my-guides-guest');
  });
}
