// Widget test của ReviewFormScreen: viết mới (kiểm tra nhập, lưu, lỗi server), sửa (điền sẵn, bỏ ảnh cũ), xóa,
// không mở được form, hỏi trước khi bỏ review đang viết.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/review_compose.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/review_form_screen.dart';

import 'place_fakes.dart';
import 'place_samples.dart';

/// Màn hình mở form và ghi lại kết quả form trả về (true khi đã lưu / xóa).
class _Host extends StatelessWidget {
  const _Host({required this.form, required this.results});

  final Widget form;
  final List<bool?> results;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: FilledButton(
        onPressed: () async =>
            results.add(await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => form))),
        child: const Text('Mở form'),
      ),
    ),
  );
}

void main() {
  Future<(MapTestKit, List<bool?>)> open(WidgetTester tester, Widget form, {MapTestKit? kit}) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final k = kit ?? MapTestKit(user: signedInUser);
    final results = <bool?>[];
    await tester.pumpWidget(k.app(_Host(form: form, results: results)));
    await tester.tap(find.text('Mở form'));
    await tester.pumpAndSettle();
    return (k, results);
  }

  const newForm = ReviewFormScreen(placeId: 1, placeName: 'Ga Nippori');

  testWidgets('form viết mới: tên địa điểm, lượt đăng của tài khoản mới, nút Đăng review', (tester) async {
    await open(tester, newForm);
    expect(find.text('Viết review'), findsOneWidget);
    expect(find.text('Ga Nippori'), findsOneWidget);
    expect(find.text('Tài khoản mới (dưới 7 ngày): hôm nay còn 3/3 lượt đăng bài viết hoặc review.'), findsOneWidget);
    expect(find.text('Chọn số sao'), findsOneWidget);
    expect(find.text('Ảnh (không bắt buộc) (0/5)'), findsOneWidget);
    expect(find.text('Đăng review'), findsOneWidget);
  });

  testWidgets('nhập sai thì hiện lỗi dưới từng ô và không gọi server', (tester) async {
    final (kit, _) = await open(tester, newForm);
    await tester.enterText(find.byType(TextField), 'ngắn');
    await tester.tap(find.text('Đăng review'));
    await tester.pumpAndSettle();
    expect(find.text('Hãy chọn số sao.'), findsOneWidget);
    expect(find.text('Nội dung cần ít nhất 10 ký tự.'), findsOneWidget);
    expect(kit.reviews.created, isEmpty);
  });

  testWidgets('chọn sao, nhập nội dung, Đăng review thì gửi và đóng form trả về true', (tester) async {
    final (kit, results) = await open(tester, newForm);
    await tester.tap(find.byTooltip('4 sao'));
    await tester.pump();
    expect(find.text('4/5'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Ga đông giờ cao điểm, nên đi sớm.');
    await tester.tap(find.text('Đăng review'));
    await tester.pumpAndSettle();
    expect(kit.reviews.created.single.review.toJson(), {
      'placeId': 1,
      'rating': 4,
      'content': 'Ga đông giờ cao điểm, nên đi sớm.',
    });
    expect(results, [true]);
    expect(find.byType(ReviewFormScreen), findsNothing);
  });

  testWidgets('lỗi theo ô của server hiện dưới ô nội dung', (tester) async {
    final kit = MapTestKit(user: signedInUser);
    kit.reviews.failOn['create'] = const ApiException(
      'Nội dung chứa từ ngữ không phù hợp.',
      statusCode: 400,
      fields: {'content': 'Nội dung chứa từ ngữ không phù hợp: "abc".'},
    );
    final (_, results) = await open(tester, newForm, kit: kit);
    await tester.tap(find.byTooltip('5 sao'));
    await tester.enterText(find.byType(TextField), 'Nội dung có từ bị cấm abc.');
    await tester.tap(find.text('Đăng review'));
    await tester.pumpAndSettle();
    expect(find.text('Nội dung chứa từ ngữ không phù hợp: "abc".'), findsOneWidget);
    expect(find.text('Nội dung chứa từ ngữ không phù hợp.'), findsOneWidget);
    expect(results, isEmpty);
  });

  testWidgets('form sửa: điền sẵn nội dung, bỏ ảnh cũ rồi Lưu thay đổi', (tester) async {
    final (kit, results) = await open(tester, const ReviewFormScreen(reviewId: 12));
    expect(find.text('Sửa review'), findsOneWidget);
    expect(find.text('Tiệm giặt Coin Laundry Sora'), findsOneWidget);
    expect(find.text('Review thử của agent map, sẽ xóa ngay.'), findsOneWidget);
    expect(find.text('4/5'), findsOneWidget);
    expect(find.text('Ảnh đang có (1)'), findsOneWidget);
    expect(find.text('Ảnh mới (0/4)'), findsOneWidget);

    await tester.tap(find.byTooltip('Bỏ ảnh này'));
    await tester.pump();
    expect(find.text('Ảnh đang có (1)'), findsNothing);
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(kit.reviews.updated.single.review.toJson()['keepMediaIds'], isEmpty);
    expect(results, [true]);
  });

  testWidgets('mở "Viết review" cho nơi đã review thì thành form sửa', (tester) async {
    final kit = MapTestKit(user: signedInUser);
    kit.reviews.compose = ReviewCompose.fromJson({...sampleCompose, 'myReviewId': 12});
    await open(tester, const ReviewFormScreen(placeId: 11), kit: kit);
    expect(find.text('Sửa review'), findsOneWidget);
    expect(find.text('Lưu thay đổi'), findsOneWidget);
  });

  testWidgets('xóa trong form sửa hỏi xác nhận rồi đóng form', (tester) async {
    final (kit, results) = await open(tester, const ReviewFormScreen(reviewId: 12));
    await tester.tap(find.byTooltip('Xóa review'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();
    expect(kit.reviews.deleted, [12]);
    expect(results, [true]);
  });

  testWidgets('không mở được form (chưa đăng nhập) hiện câu của server', (tester) async {
    final kit = MapTestKit()
      ..reviews.failWith = const ApiException('Bạn cần đăng nhập để viết review.', statusCode: 401);
    await open(tester, newForm, kit: kit);
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Bạn cần đăng nhập để viết review.'), findsOneWidget);
  });

  testWidgets('bấm quay lại khi đang viết dở thì hỏi "Bỏ review đang viết?"', (tester) async {
    final (_, results) = await open(tester, newForm);
    await tester.enterText(find.byType(TextField), 'Đang viết dở');
    await tester.pump();
    // Form có nút X (thiết kế màn 10) thay cho nút quay lại
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    expect(find.text('Bỏ review đang viết?'), findsOneWidget);
    await tester.tap(find.text('Viết tiếp'));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewFormScreen), findsOneWidget);

    // Nút Back của hệ thống cũng hỏi trước khi bỏ
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ'));
    await tester.pumpAndSettle();
    expect(find.byType(ReviewFormScreen), findsNothing);
    expect(results, [false]);
  });

  testWidgets('màn hẹp 360 dp không tràn chữ (form sửa có ảnh)', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final kit = MapTestKit(user: signedInUser);
    await tester.pumpWidget(kit.app(const ReviewFormScreen(reviewId: 12)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lưu thay đổi'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
