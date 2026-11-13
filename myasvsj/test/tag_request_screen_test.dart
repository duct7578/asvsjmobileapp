// Widget test của "Xin tag định danh" (TagRequestScreen) với DAO giả.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/tag_request_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/tag_compose.dart';
import 'package:myasvsj/com.myasvsj.model/tag_pending_request.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_sign_in_prompt.dart';
import 'package:myasvsj/com.myasvsj.screen/tag_request_screen.dart';

import 'profile_fakes.dart';
import 'profile_test_app.dart';

final _list = find.descendant(of: find.byType(TagRequestScreen), matching: find.byType(Scrollable)).first;

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200, scrollable: _list);
  await tester.pumpAndSettle();
}

RadioListTile<int> _tile(WidgetTester tester, String name) =>
    tester.widget<RadioListTile<int>>(find.ancestor(of: find.text(name), matching: find.byType(RadioListTile<int>)));

void main() {
  testWidgets('hiện các tag; tag đã có không chọn được', (tester) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(profileTestApp(const TagRequestScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Kouhai'), findsOneWidget);
    expect(find.text('Mentor'), findsOneWidget);
    expect(find.text('Người Nhật'), findsOneWidget);
    expect(find.text('Đã có'), findsOneWidget);
    expect(_tile(tester, 'Kouhai').enabled, isFalse);
    expect(_tile(tester, 'Mentor').enabled, isNot(isFalse));
    expect(find.text('Loại minh chứng'), findsNothing, reason: 'chưa chọn tag thì chưa hiện phần minh chứng');
  });

  testWidgets('gửi khi chưa chọn tag thì báo lỗi, không gọi server', (tester) async {
    usePhoneScreen(tester);
    final dao = FakeProfileDao();
    await tester.pumpWidget(profileTestApp(const TagRequestScreen(), profileDao: dao));
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('Gửi yêu cầu'));
    await tester.tap(find.text('Gửi yêu cầu'));
    await tester.pumpAndSettle();
    expect(find.text('Hãy chọn một tag.'), findsOneWidget);
    expect(dao.submitted, isEmpty);
  });

  testWidgets('chọn tag cần minh chứng: hiện loại minh chứng, ảnh, ô đồng ý; tag chân dung thì không cần loại', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await tester.pumpWidget(profileTestApp(const TagRequestScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mentor'));
    await tester.pumpAndSettle();
    expect(find.text('Loại minh chứng'), findsOneWidget);
    await _scrollTo(tester, find.text('Ảnh minh chứng (0/1)'));
    await _scrollTo(tester, find.textContaining('Tôi đồng ý cho Kiểm duyệt viên xem ảnh này.'));

    await tester.scrollUntilVisible(find.text('Người Nhật'), -200, scrollable: _list);
    await tester.tap(find.text('Người Nhật'));
    await tester.pumpAndSettle();
    expect(find.text('Loại minh chứng'), findsNothing);
    expect(find.text('Tag này chỉ cần một ảnh chân dung của bạn.'), findsOneWidget);
    await _scrollTo(tester, find.text('Ảnh chân dung (0/1)'));
  });

  testWidgets('điền đủ rồi gửi: hiện yêu cầu đang chờ và câu của server', (tester) async {
    usePhoneScreen(tester);
    final dao = FakeProfileDao();
    await tester.pumpWidget(profileTestApp(const TagRequestScreen(), profileDao: dao));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mentor'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thẻ nhân viên (社員証)').last);
    await tester.pumpAndSettle();
    // Ảnh do PhotoPicker (camera / thư viện) trả về: test đặt thẳng vào Controller
    tester.element(find.byType(TagRequestScreen)).read<TagRequestController>().setPhotos(['/tmp/the-nhan-vien.jpg']);
    await tester.pump();
    await _scrollTo(tester, find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Gửi yêu cầu'));
    await tester.tap(find.text('Gửi yêu cầu'));
    await tester.pumpAndSettle();

    final sent = dao.submitted.single;
    expect(sent.toJson(), {'tagId': 2, 'proofTypeId': 8, 'consent': true});
    expect(sent.photoPath, '/tmp/the-nhan-vien.jpg');
    expect(find.text('Đã gửi yêu cầu tag.'), findsOneWidget);
    expect(find.textContaining('Yêu cầu tag Mentor đang chờ duyệt'), findsOneWidget);
    expect(find.text('Gửi yêu cầu'), findsNothing);
  });

  testWidgets('lỗi của server không gắn với ô nào hiện cuối form', (tester) async {
    usePhoneScreen(tester);
    final dao = FakeProfileDao()
      ..failOn['submitTagRequest'] = const ApiException('Bạn đang có một yêu cầu tag chờ duyệt.', statusCode: 409);
    await tester.pumpWidget(profileTestApp(const TagRequestScreen(), profileDao: dao));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Người Nhật'));
    await tester.pumpAndSettle();
    tester.element(find.byType(TagRequestScreen)).read<TagRequestController>()
      ..setPhotos(['/tmp/me.jpg'])
      ..setConsent(true);
    await tester.pump();
    await _scrollTo(tester, find.text('Gửi yêu cầu'));
    await tester.tap(find.text('Gửi yêu cầu'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn đang có một yêu cầu tag chờ duyệt.'), findsOneWidget);
  });

  testWidgets('đang có yêu cầu chờ duyệt thì hiện yêu cầu đó thay cho form', (tester) async {
    final dao = FakeProfileDao()
      ..compose = TagCompose(
        tags: const [mentorTag],
        pending: TagPendingRequest(
          tagName: 'Mentor',
          submittedAt: DateTime(2026, 11, 7),
          expiresAt: DateTime(2026, 11, 21),
        ),
      );
    await tester.pumpWidget(profileTestApp(const TagRequestScreen(), profileDao: dao));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Yêu cầu tag Mentor đang chờ duyệt (gửi ngày 7/11/2026). Ảnh minh chứng tự xóa sau 14 ngày nếu chưa được '
        'duyệt (ngày 21/11/2026). Bạn gửi được yêu cầu mới khi có kết quả.',
      ),
      findsOneWidget,
    );
    expect(find.text('Gửi yêu cầu'), findsNothing);
  });

  testWidgets('lỗi tải hiện ErrorView; khách thấy lời mời đăng nhập', (tester) async {
    final dao = FakeProfileDao()..failWith = const ApiException('Không kết nối được tới server.');
    await tester.pumpWidget(profileTestApp(const TagRequestScreen(), profileDao: dao));
    await tester.pumpAndSettle();
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('Không kết nối được tới server.'), findsOneWidget);

    await tester.pumpWidget(profileTestApp(const TagRequestScreen(), signedIn: false));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileSignInPrompt), findsOneWidget);
  });
}
