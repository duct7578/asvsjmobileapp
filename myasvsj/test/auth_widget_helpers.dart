// Hàm dùng chung cho widget test của các màn hình tài khoản.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cuộn danh sách của màn hình đang mở tới khi thấy [finder] rồi bấm (ListView chỉ dựng phần đang hiện).
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 120, scrollable: find.byType(Scrollable).first);
  // Đưa ra giữa màn hình để không nằm dưới SnackBar
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}

/// Form dài hơn màn hình: về đầu danh sách, cuộn xuống tới khi thấy [finder] rồi kiểm tra có đúng một widget khớp.
Future<void> expectVisibleOnce(WidgetTester tester, Finder finder) async {
  final scrollable = find.byType(Scrollable).first;
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pump();
  await tester.scrollUntilVisible(finder, 120, scrollable: scrollable);
  expect(finder, findsOneWidget);
}
