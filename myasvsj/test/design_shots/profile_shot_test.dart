// Ảnh các màn "Tôi" và cài đặt cá nhân (35–43) để so với design/figma-export/ref/35-*.png … 43-*.png.
// Chạy: flutter test test/design_shots/profile_shot_test.dart --dart-define=SHOTS=true
//
// Ảnh tham chiếu có 44 px thanh trạng thái giả ở trên; ảnh Flutter không có nên cao hơn 44 px ít hơn.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/area_stage_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/interest_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/profile_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/saved_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/tag_request_controller.dart';
import 'package:myasvsj/com.myasvsj.model/interest_settings.dart';
import 'package:myasvsj/com.myasvsj.model/interest_topic.dart';
import 'package:myasvsj/com.myasvsj.model/legal_document.dart';
import 'package:myasvsj/com.myasvsj.model/point_line.dart';
import 'package:myasvsj/com.myasvsj.model/profile_rank.dart';
import 'package:myasvsj/com.myasvsj.model/profile_tag.dart';
import 'package:myasvsj/com.myasvsj.model/saved_blog.dart';
import 'package:myasvsj/com.myasvsj.model/saved_guide.dart';
import 'package:myasvsj/com.myasvsj.model/saved_kind.dart';
import 'package:myasvsj/com.myasvsj.model/saved_list.dart';
import 'package:myasvsj/com.myasvsj.model/saved_place.dart';
import 'package:myasvsj/com.myasvsj.model/tag_compose.dart';
import 'package:myasvsj/com.myasvsj.model/tag_option.dart';
import 'package:myasvsj/com.myasvsj.model/tag_proof_type.dart';
import 'package:myasvsj/com.myasvsj.model/topic.dart';
import 'package:myasvsj/com.myasvsj.model/user.dart';
import 'package:myasvsj/com.myasvsj.model/user_profile.dart';
import 'package:myasvsj/com.myasvsj.screen/area_stage_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/change_password_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/delete_account_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/interest_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/legal_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/point_history_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/saved_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/tag_request_screen.dart';

import '../auth_fakes.dart';
import '../profile_fakes.dart';
import '../saved_fakes.dart';
import 'shot_helper.dart';

const _linh = User(
  id: 1,
  email: 'linh.nguyen@gmail.com',
  displayName: 'Linh Nguyễn',
  role: 'USER',
  roleLabel: 'Thành viên',
);

const _ranks = [
  ProfileRank(name: 'Mới', minPoints: 0),
  ProfileRank(name: 'Đồng', minPoints: 200),
  ProfileRank(name: 'Bạc', minPoints: 800),
  ProfileRank(name: 'Vàng', minPoints: 2000),
];

const _linhProfile = UserProfile(
  id: 1,
  email: 'linh.nguyen@gmail.com',
  displayName: 'Linh Nguyễn',
  roleLabel: 'Thành viên',
  points: 1250,
  ranks: _ranks,
  tags: [ProfileTag(name: 'Du học sinh')],
  areaId: 679,
  areaName: 'Arakawa-ku, Tokyo',
  stage: 'ARR',
  accountAgeDays: 120,
  linkedProviders: ['GOOGLE'],
  savedCount: 14,
);

const _interests = InterestSettings(
  topics: [
    InterestTopic(id: 1, name: 'Nhà ở', chosen: true),
    InterestTopic(id: 2, name: 'Việc làm thêm', chosen: true),
    InterestTopic(id: 3, name: 'Ăn uống', chosen: true),
    InterestTopic(id: 4, name: 'Thủ tục giấy tờ'),
    InterestTopic(id: 5, name: 'Visa và cư trú'),
    InterestTopic(id: 6, name: 'Ngân hàng và tiền'),
    InterestTopic(id: 7, name: 'Y tế'),
    InterestTopic(id: 8, name: 'Kinh nghiệm', learnt: true),
    InterestTopic(id: 9, name: 'Học tiếng Nhật'),
    InterestTopic(id: 10, name: 'Đi lại'),
    InterestTopic(id: 11, name: 'Mua sắm'),
    InterestTopic(id: 12, name: 'Cảnh báo lừa đảo'),
    InterestTopic(id: 13, name: 'Khác'),
  ],
);

final _points = [
  PointLine(
    id: 6,
    delta: 5,
    reasonLabel: 'Câu trả lời hay nhất',
    title: 'Gia hạn visa du học cần mang những giấy tờ gì?',
    createdAt: DateTime(2026, 11, 8),
  ),
  PointLine(
    id: 5,
    delta: 15,
    reasonLabel: 'Ghim được duyệt',
    title: 'Chùa Sensō-ji cổng sau',
    createdAt: DateTime(2026, 11, 8),
  ),
  PointLine(id: 4, delta: 10, reasonLabel: 'Review', title: 'Gyomu Super Minami-Senju', createdAt: DateTime(2026, 11, 7)),
  PointLine(id: 3, delta: -20, reasonLabel: 'Bài bị gỡ', createdAt: DateTime(2026, 11, 2)),
  PointLine(id: 2, delta: 10, reasonLabel: 'Review', title: 'Ga Machiya (Chiyoda Line)', createdAt: DateTime(2026, 10, 28)),
  PointLine(id: 1, delta: 10, reasonLabel: 'Review', title: 'Phòng khám Nishi-Nippori', createdAt: DateTime(2026, 10, 15)),
];

SavedList _saved() {
  final now = DateTime.now();
  return SavedList({
    SavedKind.place: const [
      SavedPlace(id: 1, name: 'Ga Nippori', categoryName: 'Ga tàu', icon: 'train', address: 'Higashi-Nippori 6, Arakawa'),
      SavedPlace(id: 2, name: 'Gyomu Super Minami-Senju', categoryName: 'Siêu thị', icon: 'shopping_cart'),
      SavedPlace(id: 3, name: 'Văn phòng quận Arakawa', categoryName: 'Văn phòng quận', icon: 'account_balance', closed: true),
      SavedPlace(id: 4, name: 'Phòng khám Nishi-Nippori', categoryName: 'Bệnh viện và phòng khám', icon: 'local_hospital'),
      SavedPlace(id: 5, name: 'Chùa Sensō-ji', categoryName: 'Đền và chùa', icon: 'temple_buddhist'),
    ],
    SavedKind.post: [
      SavedBlog(
        id: 1,
        title: 'Đi Kawagoe một ngày: tiểu Edo cách Tokyo 30 phút',
        authorName: 'Thảo Vy',
        topics: const [Topic(id: 1, name: 'Du lịch')],
        likeCount: 88,
        commentCount: 21,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      SavedBlog(
        id: 2,
        title: 'Thuê nhà không cần người bảo lãnh ở Tokyo',
        authorName: 'Minh Anh',
        topics: const [Topic(id: 2, name: 'Nhà ở')],
        likeCount: 24,
        commentCount: 8,
        createdAt: now.subtract(const Duration(days: 2, hours: 2)),
      ),
      SavedBlog(
        id: 3,
        title: 'Checklist 2 tuần đầu: SIM, ngân hàng, My Number',
        authorName: 'Tuấn',
        topics: const [Topic(id: 3, name: 'Thủ tục')],
        likeCount: 41,
        commentCount: 12,
        createdAt: now.subtract(const Duration(days: 7, hours: 2)),
      ),
    ],
    SavedKind.question: [
      SavedBlog(
        id: 6,
        type: 'QA',
        title: 'Mua SIM data giá rẻ ở đâu gần Nippori ạ?',
        authorName: 'Trần Minh',
        topics: const [Topic(id: 11, name: 'Mua sắm')],
        likeCount: 3,
        commentCount: 5,
        solved: true,
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ],
    SavedKind.guide: [
      SavedGuide(
        id: 24,
        title: 'Cách phân loại và bỏ rác tại Nhật Bản',
        summary: 'Phân loại và bỏ rác đúng quy định của quận để tránh bị nhắc nhở.',
        stageName: 'Khi mới đến',
        topicName: 'Sinh hoạt',
        savedAt: now.subtract(const Duration(days: 4)),
      ),
    ],
  });
}

const _tags = TagCompose(
  photoMaxMb: 10,
  tags: [
    TagOption(
      id: 1,
      name: 'Du học sinh',
      description: 'Đang học ở trường tiếng, senmon, đại học.',
      proofTypes: [TagProofType(id: 1, name: 'Thẻ sinh viên')],
      owned: true,
    ),
    TagOption(
      id: 2,
      name: 'Đã đi làm',
      description: 'Đang làm việc toàn thời gian ở Nhật.',
      proofTypes: [TagProofType(id: 2, name: 'Thẻ nhân viên / hợp đồng lao động')],
    ),
    TagOption(
      id: 3,
      name: 'Giáo viên',
      description: 'Dạy tiếng Nhật hoặc dạy ở trường tại Nhật.',
      proofTypes: [TagProofType(id: 3, name: 'Giấy xác nhận của trường')],
    ),
  ],
);

const _terms = LegalDocument(
  type: 'TOS',
  version: '2.1',
  content: '1. Phạm vi áp dụng\n'
      'Điều khoản này áp dụng cho mọi người dùng Senpai ơi trên web và ứng dụng di động.\n\n'
      '2. Tài khoản\n'
      'Bạn cần từ 18 tuổi trở lên để đăng ký. Mỗi người chỉ dùng một tài khoản và tự bảo mật mật khẩu của mình.\n\n'
      '3. Nội dung bạn đăng\n'
      'Bài viết, review và ảnh phải đúng sự thật và tuân thủ Quy tắc cộng đồng. Nội dung vi phạm có thể bị ẩn '
      'hoặc gỡ, kèm trừ điểm.\n\n'
      '4. Quyền riêng tư\n'
      'Chúng tôi chỉ lưu khu vực bạn chọn, không lưu vị trí chính xác. Xem chi tiết trong Chính sách bảo mật.',
);

/// App thử có theme thật: AuthController (Linh hoặc khách) và mọi Controller của phần Tôi, dùng DAO giả.
Widget _app(Widget screen, {bool signedIn = true, FakeProfileDao? profileDao, FakeSavedDao? savedDao}) {
  final profiles = profileDao ?? (FakeProfileDao()
    ..profile = _linhProfile
    ..interests = _interests);
  final auth = FakeAuthDao(current: signedIn ? _linh : null)..legal['tos'] = _terms;
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthController(auth)..restoreSession()),
      ChangeNotifierProvider(create: (_) => ProfileController(profiles)),
      ChangeNotifierProvider(create: (_) => AreaStageController(profiles)),
      ChangeNotifierProvider(create: (_) => InterestController(profiles)),
      ChangeNotifierProvider(create: (_) => TagRequestController(profiles)),
      ChangeNotifierProvider(create: (_) => SavedController(savedDao ?? FakeSavedDao(_saved()))),
    ],
    child: shotApp(screen),
  );
}

void main() {
  testWidgets('35 Tôi', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, _app(const ProfileScreen()), height: 1400);
    await saveShot(tester, '35-profile');
  });

  testWidgets('35 Tôi — khách', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, _app(const ProfileScreen(), signedIn: false), height: 800);
    await saveShot(tester, '35-profile-guest');
  });

  testWidgets('36 Lịch sử điểm', skip: shotSkip != null, (tester) async {
    final dao = FakeProfileDao()
      ..pointLines = _points
      ..points = 1250;
    await pumpShot(tester, _app(const PointHistoryScreen(), profileDao: dao), height: 800);
    await saveShot(tester, '36-point-history');
  });

  testWidgets('37 Đã lưu — tab Bài viết', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, _app(const SavedScreen()), height: 800);
    await tester.tap(find.text('Bài viết (3)'));
    await settleShot(tester);
    await saveShot(tester, '37-saved');

    await tester.tap(find.byTooltip('Bỏ lưu').first);
    await settleShot(tester);
    await saveShot(tester, '37-saved-unsave');
  });

  testWidgets('37 Đã lưu — tab Địa điểm', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, _app(const SavedScreen()), height: 800);
    await saveShot(tester, '37-saved-places');
  });

  testWidgets('38 Khu vực và giai đoạn', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, _app(const AreaStageScreen(), profileDao: FakeProfileDao()), height: 902);
    await saveShot(tester, '38-area-stage');
  });

  testWidgets('39 Chủ đề quan tâm', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, _app(const InterestScreen()), height: 800);
    await saveShot(tester, '39-interest');
  });

  testWidgets('40 Xin tag định danh', skip: shotSkip != null, (tester) async {
    final dao = FakeProfileDao()..compose = _tags;
    await pumpShot(tester, _app(const TagRequestScreen(), profileDao: dao), height: 849);
    tester.element(find.byType(TagRequestScreen)).read<TagRequestController>()
      ..selectTag(2)
      ..selectProofType(2)
      ..setConsent(true);
    await settleShot(tester);
    await saveShot(tester, '40-tag-request');
  });

  testWidgets('41 Đổi mật khẩu', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, _app(const ChangePasswordScreen()), height: 800);
    await tester.enterText(find.byType(TextField).at(0), 'abc12345');
    await tester.enterText(find.byType(TextField).at(1), 'matkhau');
    await settleShot(tester);
    await saveShot(tester, '41-change-password');
  });

  testWidgets('42 Xóa tài khoản', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, _app(const DeleteAccountScreen()), height: 800);
    await saveShot(tester, '42-delete-account');

    await tester.tap(find.widgetWithText(FilledButton, 'Xóa tài khoản'));
    await settleShot(tester);
    await saveShot(tester, '42-delete-account-confirm');
  });

  testWidgets('43 Điều khoản sử dụng', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, _app(const LegalScreen(type: 'terms')), height: 800);
    await saveShot(tester, '43-legal');
  });
}
