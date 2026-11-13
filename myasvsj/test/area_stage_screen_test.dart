// Widget test của "Khu vực và giai đoạn" (AreaStageScreen) với DAO giả và vị trí giả.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/user_profile.dart';
import 'package:myasvsj/com.myasvsj.screen/area_stage_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_sign_in_prompt.dart';

import 'profile_fakes.dart';
import 'profile_test_app.dart';

final _list = find.descendant(of: find.byType(AreaStageScreen), matching: find.byType(Scrollable)).first;

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: _list);
  await tester.pumpAndSettle();
}

ChoiceChip _chip(WidgetTester tester, String label) =>
    tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label));

void main() {
  testWidgets('hiện giai đoạn và khu vực đang lưu, nhãn theo giai đoạn', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(profileTestApp(const AreaStageScreen()));
    await tester.pumpAndSettle();

    expect(_chip(tester, 'Mới đến').selected, isTrue);
    expect(_chip(tester, 'Sắp sang Nhật').selected, isFalse);
    expect(find.text('Khu vực bạn đang sống'), findsWidgets);
    expect(find.text('Arakawa-ku'), findsWidgets, reason: 'ô khu vực đang chọn và ô quận');
    expect(find.text('荒川区 · Tokyo'), findsOneWidget);

    await tester.tap(find.text('Sắp sang Nhật'));
    await tester.pumpAndSettle();
    expect(_chip(tester, 'Sắp sang Nhật').selected, isTrue);
    expect(find.text('Khu vực bạn sắp đến'), findsWidgets);

    // Bấm lại để bỏ chọn
    await tester.tap(find.text('Sắp sang Nhật'));
    await tester.pumpAndSettle();
    expect(_chip(tester, 'Sắp sang Nhật').selected, isFalse);
  });

  testWidgets('tìm nhanh theo tên rồi chọn kết quả', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(profileTestApp(const AreaStageScreen()));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Tìm nhanh: Arakawa, 荒川, Osaka…'), 'kita');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('Kita-ku, Osaka-shi, Osaka'), findsOneWidget);

    // Kết quả hiện ngay dưới ô tìm, có thể nằm dưới thanh "Lưu" trên màn hẹp
    await _scrollTo(tester, find.text('Kita-ku, Osaka-shi, Osaka'));
    await tester.tap(find.text('Kita-ku, Osaka-shi, Osaka'));
    await tester.pumpAndSettle();
    expect(find.text('北区 · Osaka'), findsOneWidget);
    expect(find.text('Osaka'), findsOneWidget, reason: 'ô tỉnh nhảy theo khu vực đã chọn');
  });

  testWidgets('tìm không thấy thì có câu hướng dẫn', (tester) async {
    await tester.pumpWidget(profileTestApp(const AreaStageScreen()));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Tìm nhanh: Arakawa, 荒川, Osaka…'), 'zzz');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy khu vực nào. Thử tên khác hoặc chọn tỉnh ở dưới.'), findsOneWidget);
  });

  testWidgets('Vị trí của tôi gợi ý khu vực gần nhất, Dùng khu vực này chọn nó', (tester) async {
    usePhoneScreen(tester);
    final dao = FakeProfileDao()..profile = const UserProfile(id: 1, email: 'an@example.com', displayName: 'An');
    await tester.pumpWidget(
      profileTestApp(AreaStageScreen(locate: () async => (lat: 35.736, lng: 139.78)), profileDao: dao),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chưa chọn khu vực.'), findsOneWidget);

    await _scrollTo(tester, find.text('Vị trí của tôi'));
    await tester.tap(find.text('Vị trí của tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Khu vực gợi ý: Arakawa-ku, Tokyo · 東京都荒川区'), findsOneWidget);

    await _scrollTo(tester, find.text('Dùng khu vực này'));
    await tester.tap(find.text('Dùng khu vực này'));
    await tester.pumpAndSettle();
    expect(find.text('Khu vực gợi ý: Arakawa-ku, Tokyo · 東京都荒川区'), findsNothing);
    await tester.scrollUntilVisible(find.text('荒川区 · Tokyo'), -200, scrollable: _list);
    expect(find.text('Chưa chọn khu vực.'), findsNothing);
  });

  testWidgets('không lấy được vị trí, hoặc vị trí ngoài Nhật: báo nhẹ', (tester) async {
    await tester.pumpWidget(profileTestApp(AreaStageScreen(locate: () async => null)));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Vị trí của tôi'));
    await tester.tap(find.text('Vị trí của tôi'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không lấy được vị trí'), findsOneWidget);

    await tester.pumpWidget(profileTestApp(AreaStageScreen(locate: () async => (lat: 21.03, lng: 105.85))));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Vị trí của tôi'));
    await tester.tap(find.text('Vị trí của tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Vị trí này không ở Nhật Bản. Hãy chọn một điểm ở Nhật.'), findsOneWidget);
  });

  testWidgets('chọn tỉnh rồi chọn khu vực trong ô chọn', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(profileTestApp(const AreaStageScreen()));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Tokyo'));

    await tester.tap(find.text('Tokyo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Osaka · 大阪府').last);
    await tester.pumpAndSettle();
    expect(find.text('Chưa chọn khu vực.'), findsOneWidget, reason: 'đổi tỉnh thì bỏ khu vực cũ');

    await tester.tap(find.widgetWithText(DropdownButtonFormField<int?>, 'Chưa chọn'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kita-ku, Osaka-shi · 北区').last);
    await tester.pumpAndSettle();
    expect(find.text('北区 · Osaka'), findsOneWidget);
  });

  testWidgets('Bỏ chọn khu vực rồi Lưu: đóng màn hình, trả về true, hiện câu của server', (tester) async {
    usePhoneScreen(tester);
    final dao = FakeProfileDao();
    bool? result;
    await tester.pumpWidget(
      profileTestApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const AreaStageScreen()),
              ),
              child: const Text('Mở'),
            ),
          ),
        ),
        profileDao: dao,
      ),
    );
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Bỏ chọn khu vực'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Lưu'));
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(find.byType(AreaStageScreen), findsNothing);
    expect(find.text('Đã lưu khu vực và giai đoạn.'), findsOneWidget);
    expect(dao.savedAreaStages.single, (areaId: null, stage: 'ARR'));
  });

  testWidgets('lưu bị từ chối thì ở lại và hiện câu lỗi', (tester) async {
    final dao = FakeProfileDao()..failOn['updateAreaStage'] = const ApiException('Khu vực không hợp lệ');
    await tester.pumpWidget(profileTestApp(const AreaStageScreen(), profileDao: dao));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Lưu'));
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Khu vực không hợp lệ'));
    expect(find.byType(AreaStageScreen), findsOneWidget);
  });

  testWidgets('lỗi tải hiện ErrorView; khách thấy lời mời đăng nhập', (tester) async {
    final dao = FakeProfileDao()..failWith = const ApiException('Không kết nối được tới server.');
    await tester.pumpWidget(profileTestApp(const AreaStageScreen(), profileDao: dao));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);

    await tester.pumpWidget(profileTestApp(const AreaStageScreen(), signedIn: false));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileSignInPrompt), findsOneWidget);
  });
}
