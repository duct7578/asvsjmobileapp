// Widget test của trang đầu Nhật ngữ (PhraseScreen) với DAO giả.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/phrase_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_card.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_practice_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_screen.dart';

import 'phrase_fakes.dart';

void main() {
  Future<FakePhraseDao> open(WidgetTester tester, {bool member = false, Widget home = const PhraseScreen()}) async {
    useNarrowPhone(tester);
    final dao = FakePhraseDao(member: member);
    await tester.pumpWidget(
      phraseApp(
        home,
        phrases: PhraseController(dao, speaker: FakePhraseSpeaker()),
        signedIn: member,
      ),
    );
    await tester.pumpAndSettle();
    return dao;
  }

  testWidgets('khách thấy Luyện tập, lời mời đăng nhập, Từ vựng rồi Mẫu câu theo Chủ đề', (tester) async {
    await open(tester);

    expect(find.text('Luyện tập'), findsOneWidget);
    expect(find.text('Đăng nhập để lưu kết quả lật thẻ (Chưa thuộc / Đã thuộc).'), findsOneWidget);
    expect(find.text('Chủ đề (3)'), findsOneWidget);
    expect(find.text('Địa điểm (2)'), findsOneWidget);
    expect(find.text('Chưa thuộc'), findsNothing);
    // Từ vựng (2 mục) trước Mẫu câu (4 mục), không có tiến độ cho khách
    final vocab = tester.getTopLeft(find.text('Từ vựng'));
    final phrase = tester.getTopLeft(find.text('Mẫu câu'));
    expect(vocab.dy, lessThan(phrase.dy));
    expect(find.text('2 mục'), findsWidgets);
    expect(find.text('4 mục'), findsOneWidget);
    expect(find.textContaining('đã thuộc'), findsNothing);
    expect(find.text('Thanh toán'), findsNWidgets(2));
    expect(find.text('Hỏi đường, hỏi đồ'), findsOneWidget);
    expect(find.text('Cửa hàng tiện lợi'), findsNothing);
  });

  testWidgets('chuyển sang Địa điểm hiện các loại địa điểm', (tester) async {
    await open(tester);

    await tester.tap(find.text('Địa điểm (2)'));
    await tester.pumpAndSettle();
    expect(find.text('Cửa hàng tiện lợi'), findsNWidgets(2));
    expect(find.text('Ga tàu'), findsNWidgets(2));
    expect(find.text('Hỏi đường, hỏi đồ'), findsNothing);
  });

  testWidgets('thành viên thấy tiến độ đã thuộc và lối vào Chưa thuộc / Đã thuộc', (tester) async {
    await open(tester, member: true);

    expect(find.text('Đăng nhập để lưu kết quả lật thẻ (Chưa thuộc / Đã thuộc).'), findsNothing);
    expect(find.text('4 mục · 1/4 đã thuộc'), findsOneWidget);
    expect(find.text('2 mục · 0/2 đã thuộc'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsWidgets);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Chưa thuộc'));
    await tester.pumpAndSettle();
    expect(find.byType(PhraseListScreen), findsOneWidget);
    expect(find.text('チャージしたいです。'), findsOneWidget);
  });

  testWidgets('trạng thái chờ rồi hiện trang đầu', (tester) async {
    useNarrowPhone(tester);
    final dao = FakePhraseDao()..hold = Completer<void>();
    await tester.pumpWidget(
      phraseApp(const PhraseScreen(), phrases: PhraseController(dao, speaker: FakePhraseSpeaker())),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    dao.hold!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Luyện tập'), findsOneWidget);
  });

  testWidgets('lỗi server hiện câu thông báo và Thử lại tải lại', (tester) async {
    useNarrowPhone(tester);
    final dao = FakePhraseDao()..failWith = const ApiException('Không kết nối được tới server.');
    await tester.pumpWidget(
      phraseApp(const PhraseScreen(), phrases: PhraseController(dao, speaker: FakePhraseSpeaker())),
    );
    await tester.pumpAndSettle();
    expect(find.text('Không kết nối được tới server.'), findsOneWidget);

    dao.failWith = null;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Luyện tập'), findsOneWidget);
  });

  testWidgets('tìm kiếm hiện kết quả chia Từ vựng / Mẫu câu và ẩn phần duyệt', (tester) async {
    final dao = await open(tester);

    await tester.enterText(find.byType(TextField), 'tàu');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(dao.finds.last.q, 'tàu');
    expect(find.text('2 kết quả'), findsOneWidget);
    expect(find.text('Từ vựng (1)'), findsOneWidget);
    expect(find.text('Mẫu câu (1)'), findsOneWidget);
    expect(find.byType(PhraseCard), findsNWidgets(2));
    expect(find.text('Luyện tập'), findsNothing);

    await tester.enterText(find.byType(TextField), 'không có');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy mẫu câu hay từ vựng nào.'), findsOneWidget);

    await tester.tap(find.byTooltip('Xóa'));
    await tester.pumpAndSettle();
    expect(find.text('Luyện tập'), findsOneWidget);
    expect(find.byType(PhraseCard), findsNothing);
  });

  testWidgets('bấm một chủ đề mở bộ của loại đó', (tester) async {
    await open(tester);

    await tester.tap(find.text('Đi tàu').last); // phần Mẫu câu
    await tester.pumpAndSettle();
    expect(find.byType(PhraseListScreen), findsOneWidget);
    expect(find.text('この電車は上野に止まりますか。'), findsOneWidget);
    expect(find.text('乗り換え'), findsNothing);
  });

  testWidgets('mở với topicId thì bộ đó hiện trên trang đầu, quay lại là trang đầu', (tester) async {
    await open(tester, home: const PhraseScreen(topicId: 'train'));

    expect(find.byType(PhraseListScreen), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Đi tàu'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Luyện tập'), findsOneWidget);
  });

  testWidgets('mở với initialQuery thì tìm ngay', (tester) async {
    final dao = await open(tester, home: const PhraseScreen(initialQuery: 'レジ'));

    expect(dao.finds.single.q, 'レジ');
    expect(find.text('1 kết quả'), findsOneWidget);
  });

  testWidgets('Luyện tập mở màn chọn thẻ; khách bấm Đăng nhập ra màn Đăng nhập', (tester) async {
    await open(tester);

    await tester.tap(find.text('Luyện tập'));
    await tester.pumpAndSettle();
    expect(find.byType(PhrasePracticeScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
