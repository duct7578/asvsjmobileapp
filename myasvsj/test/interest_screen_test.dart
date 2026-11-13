// Widget test của "Chủ đề quan tâm" (InterestScreen) với DAO giả.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/interest_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_sign_in_prompt.dart';

import 'profile_fakes.dart';
import 'profile_test_app.dart';

FilterChip _chip(WidgetTester tester, String name) => tester.widget<FilterChip>(find.widgetWithText(FilterChip, name));

/// Mở InterestScreen từ một màn hình trước, để kiểm tra kết quả trả về khi đóng.
Widget _launcher(void Function(bool?) onResult) => Builder(
  builder: (context) => Scaffold(
    body: TextButton(
      onPressed: () async =>
          onResult(await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const InterestScreen()))),
      child: const Text('Mở'),
    ),
  ),
);

void main() {
  testWidgets('hiện chủ đề, chủ đề đã chọn, dấu gợi ý', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(profileTestApp(const InterestScreen()));
    await tester.pumpAndSettle();

    expect(find.byType(FilterChip), findsNWidgets(7));
    expect(_chip(tester, 'Kinh nghiệm').selected, isTrue);
    expect(_chip(tester, 'Nhà ở').selected, isFalse);
    expect(
      find.descendant(of: find.widgetWithText(FilterChip, 'Nhà ở'), matching: find.byIcon(Symbols.history_rounded)),
      findsOne,
    );
    expect(find.textContaining('Đã chọn 1/5.'), findsOneWidget);
    expect(find.text('Gợi ý: chủ đề bạn hay đọc, thích hoặc lưu gần đây.'), findsOneWidget);
  });

  testWidgets('chọn đủ 5 thì các chủ đề còn lại bị khóa; bỏ một thì mở lại', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(profileTestApp(const InterestScreen()));
    await tester.pumpAndSettle();

    for (final name in ['Cảnh báo lừa đảo', 'Thủ tục giấy tờ', 'Visa và cư trú', 'Nhà ở']) {
      await tester.tap(find.text(name));
      await tester.pumpAndSettle();
    }
    expect(find.textContaining('Đã chọn 5/5.'), findsOneWidget);
    expect(_chip(tester, 'Ăn uống').onSelected, isNull);
    expect(find.byTooltip('Đã chọn đủ 5 chủ đề'), findsNWidgets(2));

    await tester.tap(find.text('Nhà ở'));
    await tester.pumpAndSettle();
    expect(_chip(tester, 'Ăn uống').onSelected, isNotNull);
  });

  testWidgets('Lưu gửi lựa chọn, đóng màn hình, trả về true, hiện câu của server', (tester) async {
    usePhoneScreen(tester);
    final dao = FakeProfileDao();
    bool? result;
    await tester.pumpWidget(profileTestApp(_launcher((r) => result = r), profileDao: dao));
    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ăn uống'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(dao.savedInterests.single, [1, 7]);
    expect(result, isTrue);
    expect(find.byType(InterestScreen), findsNothing);
    expect(find.text('Đã lưu chủ đề quan tâm.'), findsOneWidget);
  });

  testWidgets('lưu bị từ chối thì ở lại và hiện câu lỗi', (tester) async {
    final dao = FakeProfileDao()
      ..failOn['updateInterests'] = const ApiException(
        'Có chủ đề không còn để chọn. Hãy tải lại trang rồi chọn lại.',
        statusCode: 400,
      );
    await tester.pumpWidget(profileTestApp(const InterestScreen(), profileDao: dao));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(find.byType(InterestScreen), findsOneWidget);
    expect(find.text('Có chủ đề không còn để chọn. Hãy tải lại trang rồi chọn lại.'), findsOneWidget);
  });

  testWidgets('lỗi tải hiện ErrorView và Thử lại; khách thấy lời mời đăng nhập', (tester) async {
    final dao = FakeProfileDao()..failWith = const ApiException('Không kết nối được tới server.');
    await tester.pumpWidget(profileTestApp(const InterestScreen(), profileDao: dao));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    dao.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.byType(FilterChip), findsNWidgets(7));

    await tester.pumpWidget(profileTestApp(const InterestScreen(), signedIn: false));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileSignInPrompt), findsOneWidget);
  });
}
