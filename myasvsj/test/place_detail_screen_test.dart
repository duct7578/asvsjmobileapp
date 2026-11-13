// Widget test của PlaceDetailScreen: vẽ dữ liệu, chờ / lỗi / rỗng, khách bị đưa sang Đăng nhập, người đã đăng nhập
// dùng được Lưu, Thích, Báo cáo, Báo đã đóng cửa, Nghe, Sửa / Xóa review của mình.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/place_detail.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/place_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/place_review_card.dart';
import 'package:myasvsj/com.myasvsj.screen/review_form_screen.dart';

import 'place_fakes.dart';
import 'place_samples.dart';

void main() {
  /// Màn hình cao để mọi phần của chi tiết đều được dựng (ListView không dựng phần ngoài khung).
  void tallScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<MapTestKit> open(WidgetTester tester, {bool signedIn = true, int placeId = 1, MapTestKit? kit}) async {
    tallScreen(tester);
    final k = kit ?? MapTestKit(user: signedIn ? signedInUser : null);
    await tester.pumpWidget(k.app(PlaceDetailScreen(placeId: placeId)));
    await tester.pumpAndSettle();
    return k;
  }

  testWidgets('đang tải hiện vòng quay', (tester) async {
    tallScreen(tester);
    final kit = MapTestKit(user: signedInUser);
    await tester.pumpWidget(kit.app(const PlaceDetailScreen(placeId: 1)));
    expect(find.byType(LoadingView), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(LoadingView), findsNothing);
  });

  testWidgets('vẽ thông tin địa điểm, cảnh báo lừa đảo và review', (tester) async {
    await open(tester);

    expect(find.text('Ga Nippori'), findsNWidgets(2)); // tiêu đề AppBar và tên
    expect(find.text('Ga tàu'), findsOneWidget);
    expect(find.text('OpenStreetMap'), findsOneWidget);
    expect(find.text('日暮里駅 · Nippori Station · Higashi-Nippori 6, Arakawa, Tokyo'), findsOneWidget);
    expect(find.text('Cảnh báo lừa đảo'), findsOneWidget);
    expect(find.text('Tin nhắn tuyển việc làm thêm lương cao quanh ga'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('2 review từ người dùng Senpai ơi'), findsOneWidget);
    expect(find.text('Viết review'), findsOneWidget);
    expect(find.text('Lưu'), findsOneWidget);
    expect(find.text('Chỉ đường'), findsOneWidget);
    expect(find.text('Báo đã đóng cửa (0/5)'), findsOneWidget);
    expect(find.byType(PlaceReviewCard), findsNWidgets(2));
    expect(find.text('Thích (14)'), findsOneWidget);
    expect(find.text('Hữu ích'), findsOneWidget);
    expect(find.text('Mentor · Senpai tin cậy'), findsNWidgets(2));
    // Review của mình: Sửa / Xóa thay cho Thích / Báo cáo
    expect(find.text('Sửa'), findsOneWidget);
    expect(find.text('Xóa'), findsOneWidget);
    expect(find.text('Báo cáo'), findsOneWidget);
  });

  testWidgets('địa điểm không còn: câu của server và nút Thử lại', (tester) async {
    await open(tester, placeId: 9999);
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Địa điểm này không còn trên Senpai ơi.'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('chưa có review thì mời viết review đầu tiên', (tester) async {
    final kit = MapTestKit(user: signedInUser);
    kit.places.details[5] = PlaceDetail.fromJson({
      ...sampleDetail,
      'id': 5,
      'name': 'Siêu thị Sakura',
      'reviewCount': 0,
      'rating': null,
      'scamWarnings': [],
    });
    await open(tester, placeId: 5, kit: kit);
    expect(find.text('Chưa có review. Hãy là người đầu tiên.'), findsOneWidget);
    expect(find.text('Chưa ai viết review về địa điểm này.'), findsOneWidget);
    expect(find.text('Cảnh báo lừa đảo'), findsNothing);
  });

  testWidgets('khách bấm Lưu thì được đưa sang Đăng nhập', (tester) async {
    final kit = await open(tester, signedIn: false);
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(kit.places.calls.where((c) => c.startsWith('save')), isEmpty);
  });

  testWidgets('khách bấm Thích review thì được đưa sang Đăng nhập', (tester) async {
    await open(tester, signedIn: false);
    await tester.tap(find.text('Thích (14)'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('đã đăng nhập: Lưu đổi thành "Đã lưu" và hiện câu của server', (tester) async {
    final kit = await open(tester);
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(kit.places.calls, contains('save 1'));
    expect(find.text('Đã lưu'), findsOneWidget);
    expect(find.text('Đã lưu địa điểm.'), findsOneWidget);
  });

  testWidgets('Thích review tăng số lượt thích', (tester) async {
    final kit = await open(tester);
    await tester.tap(find.text('Thích (14)'));
    await tester.pumpAndSettle();
    expect(kit.places.calls, contains('likeReview 1'));
    expect(find.text('Thích (15)'), findsOneWidget);
  });

  testWidgets('Báo cáo review: chọn lý do rồi gửi', (tester) async {
    final kit = await open(tester);
    await tester.tap(find.text('Báo cáo'));
    await tester.pumpAndSettle();
    expect(find.text('Báo cáo review'), findsOneWidget);
    await tester.tap(find.text('Spam'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi báo cáo'));
    await tester.pumpAndSettle();
    expect(kit.places.calls, contains('reportReview 1 r4'));
    expect(find.text('Đã gửi báo cáo cho Moderator.'), findsOneWidget);
  });

  testWidgets('Báo đã đóng cửa hỏi xác nhận rồi cập nhật số báo', (tester) async {
    final kit = await open(tester);
    await tester.tap(find.text('Báo đã đóng cửa (0/5)'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bạn chắc “Ga Nippori” đã đóng cửa?'), findsOneWidget);

    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(kit.places.calls.where((c) => c.startsWith('reportClosed')), isEmpty);

    await tester.tap(find.text('Báo đã đóng cửa (0/5)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gửi báo cáo'));
    await tester.pumpAndSettle();
    expect(kit.places.calls, contains('reportClosed 1'));
    expect(find.text('Bạn đã báo đóng cửa (1/5)'), findsOneWidget);
    expect(find.text('Đã ghi nhận báo cáo.'), findsOneWidget);
  });

  testWidgets('Từ vựng và mẫu câu: bấm "Nghe" đọc câu tiếng Nhật', (tester) async {
    final kit = await open(tester);
    await tester.tap(find.text('Từ vựng và mẫu câu'));
    await tester.pumpAndSettle();
    expect(find.text('この電車は上野に止まりますか。'), findsOneWidget);
    expect(find.text('Tàu này có dừng ở Ueno không?'), findsOneWidget);
    expect(find.text('Từ vựng'), findsOneWidget);

    await tester.tap(find.byTooltip('Nghe').first);
    await tester.pumpAndSettle();
    expect(kit.speaker.spoken, ['この電車は上野に止まりますか。']);
  });

  testWidgets('máy không đọc được tiếng Nhật thì báo', (tester) async {
    final kit = MapTestKit(user: signedInUser)..speaker.works = false;
    await open(tester, kit: kit);
    await tester.tap(find.text('Từ vựng và mẫu câu'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Nghe').first);
    await tester.pumpAndSettle();
    expect(find.text('Thiết bị này không hỗ trợ đọc tiếng Nhật.'), findsOneWidget);
  });

  testWidgets('Xóa review của mình hỏi xác nhận rồi tải lại địa điểm', (tester) async {
    final kit = await open(tester);
    kit.places.calls.clear();
    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    expect(find.text('Xóa review này? Điểm của review này sẽ được thu lại.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();
    expect(kit.reviews.deleted, [12]);
    expect(kit.places.calls, containsAllInOrder(['findById 1', 'findReviews 1 p0', 'findMap']));
    expect(find.text('Đã xóa review. Điểm của review này được thu lại.'), findsOneWidget);
  });

  testWidgets('Viết review mở form review cho địa điểm', (tester) async {
    final kit = await open(tester);
    await tester.tap(find.text('Viết review'));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewFormScreen), findsOneWidget);
    expect(kit.reviews.composeAsked, [1]);
  });

  testWidgets('Xem thêm review tải trang sau', (tester) async {
    final kit = MapTestKit(user: signedInUser);
    kit.places.reviews[1] = manyReviews();
    await open(tester, kit: kit);
    expect(find.byType(PlaceReviewCard), findsNWidgets(10));
    await tester.scrollUntilVisible(find.text('Xem thêm review'), 300);
    await tester.tap(find.text('Xem thêm review'));
    await tester.pumpAndSettle();
    expect(kit.places.calls.last, 'findReviews 1 p1');
    expect(find.text('Xem thêm review'), findsNothing);
  });

  testWidgets('màn hẹp 360 dp không tràn chữ', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final kit = MapTestKit(user: signedInUser);
    await tester.pumpWidget(kit.app(const PlaceDetailScreen(placeId: 1)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Thích (14)'), 300);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
