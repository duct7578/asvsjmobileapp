// Widget test của MapScreen: bản đồ không tải ô từ mạng (showTiles: false), Controller dùng DAO và plugin giả.
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/map_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/place_detail_screen.dart';

import 'place_fakes.dart';

/// Một điểm trống trên bản đồ (góc dưới bên trái của vùng bản đồ: không có ghim, không bị ô tìm kiếm và bộ lọc
/// nổi phía trên che).
Offset emptyMapPoint(WidgetTester tester) {
  final map = tester.getRect(find.byType(FlutterMap));
  return map.bottomLeft + const Offset(40, -40);
}

void main() {
  Future<MapTestKit> open(WidgetTester tester, {bool signedIn = true, int? focus}) async {
    final kit = MapTestKit(user: signedIn ? signedInUser : null);
    await tester.pumpWidget(kit.app(MapScreen(showTiles: false, focusPlaceId: focus)));
    await tester.pumpAndSettle();
    return kit;
  }

  testWidgets('vẽ ghim, chip danh mục kèm số lượng và ghim sự kiện', (tester) async {
    await open(tester);

    expect(find.text('Bản đồ'), findsOneWidget);
    for (final id in [1, 3, 4, 10]) {
      expect(find.byKey(ValueKey('map-pin-$id')), findsOneWidget);
    }
    expect(find.text('Tất cả (4)'), findsOneWidget);
    expect(find.text('Quán ăn (2)'), findsOneWidget);
    expect(find.text('Công viên (0)'), findsNothing);
    expect(find.byKey(const ValueKey('map-event-2')), findsOneWidget);
    expect(find.text('Đang diễn ra'), findsOneWidget);
    expect(find.text('Còn 2 ngày'), findsOneWidget);
    expect(find.text('© OpenStreetMap'), findsOneWidget);
    // Ghim có cảnh báo lừa đảo có dấu "!"
    expect(find.descendant(of: find.byKey(const ValueKey('map-pin-1')), matching: find.text('!')), findsOneWidget);
  });

  testWidgets('bấm ghim mở bảng tóm tắt, "Xem chi tiết" mở chi tiết địa điểm', (tester) async {
    await open(tester);

    await tester.tap(find.byKey(const ValueKey('map-pin-1')));
    await tester.pumpAndSettle();
    expect(find.text('Ga Nippori'), findsOneWidget);
    expect(find.text('4.5 · 2 review'), findsOneWidget);
    expect(find.text('Có cảnh báo lừa đảo'), findsOneWidget);
    expect(find.text('Chỉ đường'), findsOneWidget);

    await tester.tap(find.text('Xem chi tiết'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaceDetailScreen), findsOneWidget);
    expect(find.text('2 review từ người dùng Senpai ơi'), findsOneWidget);
  });

  testWidgets('chọn danh mục chỉ còn ghim của danh mục và mở danh sách', (tester) async {
    await open(tester);

    await tester.tap(find.text('Quán ăn (2)'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-pin-1')), findsNothing);
    expect(find.byKey(const ValueKey('map-pin-4')), findsOneWidget);
    expect(find.text('2 địa điểm'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Quán cơm Hana'), findsOneWidget);

    await tester.tap(find.byTooltip('Đóng danh sách'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-pin-1')), findsOneWidget);
    expect(find.text('2 địa điểm'), findsNothing);
  });

  testWidgets('tìm kiếm hiện kết quả và ghim tạm của địa điểm OpenStreetMap', (tester) async {
    final kit = await open(tester);

    await tester.enterText(find.byType(TextField), 'ga');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(kit.places.calls, contains('search ga'));
    expect(find.text('Kết quả cho “ga”'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Ueno Station'), findsOneWidget);
    expect(find.text('Danh mục · 1 địa điểm'), findsOneWidget);

    await tester.tap(find.widgetWithText(ListTile, 'Ueno Station'));
    await tester.pumpAndSettle();
    expect(find.text('Viết review đầu tiên'), findsOneWidget);
    expect(find.textContaining('chưa có trên Senpai ơi'), findsOneWidget);
  });

  testWidgets('đang gõ thì hiện gợi ý sau 350 ms; bấm gợi ý OpenStreetMap mở bảng tóm tắt', (tester) async {
    final kit = await open(tester);

    await tester.enterText(find.byType(TextField), 'nip');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byType(TextField), 'nippori');
    await tester.pump(const Duration(milliseconds: 200));
    // Chưa ngừng gõ đủ lâu: chưa hỏi server
    expect(kit.places.calls.where((c) => c.startsWith('search')), isEmpty);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    // Chỉ hỏi một lần, cho từ khóa cuối cùng
    expect(kit.places.calls.where((c) => c.startsWith('search')), ['search nippori']);
    expect(find.text('Địa điểm'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Ga Nippori'), findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Ueno Station'), findsOneWidget);
    expect(find.text('Danh mục · 1 địa điểm'), findsOneWidget);
    // Gợi ý không mở bảng kết quả
    expect(find.textContaining('Kết quả cho'), findsNothing);

    await tester.tap(find.widgetWithText(ListTile, 'Ueno Station'));
    await tester.pumpAndSettle();
    expect(find.text('Địa điểm'), findsNothing);
    expect(find.text('Viết review đầu tiên'), findsOneWidget);
  });

  testWidgets('xóa từ khóa đóng gợi ý; bấm tìm trên bàn phím thay gợi ý bằng bảng kết quả', (tester) async {
    await open(tester);

    await tester.enterText(find.byType(TextField), 'ga');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Ga Nippori'), findsOneWidget);
    await tester.tap(find.byTooltip('Xóa từ khóa'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ListTile, 'Ga Nippori'), findsNothing);

    await tester.enterText(find.byType(TextField), 'ga');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Địa điểm'), findsNothing);
    expect(find.text('Kết quả cho “ga”'), findsOneWidget);
  });

  testWidgets('khách bấm "Viết review đầu tiên" thì được đưa sang Đăng nhập', (tester) async {
    await open(tester, signedIn: false);

    await tester.enterText(find.byType(TextField), 'ga');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Ueno Station'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Viết review đầu tiên'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('chip "Tắt" bỏ ghim sự kiện, "15 ngày tới" tải lại', (tester) async {
    final kit = await open(tester);

    await tester.tap(find.text('Tắt'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-event-2')), findsNothing);

    await tester.tap(find.text('15 ngày tới'));
    await tester.pumpAndSettle();
    expect(kit.places.calls.last, 'findEvents 15');
    expect(find.byKey(const ValueKey('map-event-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('map-event-3')), findsNothing);
  });

  testWidgets('bấm ghim sự kiện mở bảng có "Xem sự kiện"', (tester) async {
    await open(tester);

    await tester.tap(find.byKey(const ValueKey('map-event-3')));
    await tester.pumpAndSettle();
    expect(find.text('Lễ hội phố vải Nippori'), findsOneWidget);
    expect(find.text('Xem sự kiện'), findsOneWidget);
  });

  testWidgets('chạm bản đồ khi đã đăng nhập: "Địa điểm quanh đây" hỏi server', (tester) async {
    final kit = await open(tester);

    await tester.tapAt(emptyMapPoint(tester));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
    expect(kit.places.calls.where((c) => c.startsWith('findNearby')), hasLength(1));
    expect(find.text('Địa điểm quanh đây'), findsOneWidget);
  });

  testWidgets('khách chạm bản đồ: danh sách tính trên máy, không gọi server', (tester) async {
    final kit = await open(tester, signedIn: false);

    await tester.tapAt(emptyMapPoint(tester));
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
    expect(kit.places.calls.where((c) => c.startsWith('findNearby')), isEmpty);
    expect(find.text('Địa điểm quanh đây'), findsOneWidget);
    expect(find.textContaining('Đăng nhập để xem thêm địa điểm từ OpenStreetMap.'), findsOneWidget);
  });

  testWidgets('"Vị trí của tôi" hỏi vị trí rồi hiện chấm vị trí', (tester) async {
    final kit = await open(tester);

    await tester.tap(find.byTooltip('Vị trí của tôi'));
    await tester.pumpAndSettle();
    expect(kit.locator.asked, 1);
    expect(find.bySemanticsLabel('Vị trí của bạn'), findsOneWidget);
  });

  testWidgets('từ chối quyền vị trí thì báo nhẹ', (tester) async {
    final kit = MapTestKit(user: signedInUser)..locator.position = null;
    await tester.pumpWidget(kit.app(const MapScreen(showTiles: false)));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Vị trí của tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Không lấy được vị trí. Hãy bật định vị và cho phép ứng dụng dùng vị trí.'), findsOneWidget);
  });

  testWidgets('lỗi server hiện câu thông báo và nút Thử lại', (tester) async {
    final kit = MapTestKit(user: signedInUser)..places.failWith = offline;
    await tester.pumpWidget(kit.app(const MapScreen(showTiles: false)));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text(offline.message), findsOneWidget);

    kit.places.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('map-pin-1')), findsOneWidget);
  });

  testWidgets('focusPlaceId mở bản đồ tại địa điểm và mở bảng tóm tắt', (tester) async {
    await open(tester, focus: 3);
    expect(find.text('Konbini Midori'), findsOneWidget);
    expect(find.text('Xem chi tiết'), findsOneWidget);
  });

  testWidgets('chú thích giải thích các kiểu ghim', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Chú thích'));
    await tester.pumpAndSettle();
    expect(find.text('Ghim cộng đồng (vuông)'), findsOneWidget);
    expect(find.text('Có cảnh báo lừa đảo'), findsOneWidget);
  });

  testWidgets('màn hẹp 360 dp: bảng kết quả và bảng tóm tắt không tràn chữ', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await open(tester);

    await tester.enterText(find.byType(TextField), 'ga');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Ga Nippori'));
    await tester.pumpAndSettle();
    expect(find.text('Xem chi tiết'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
