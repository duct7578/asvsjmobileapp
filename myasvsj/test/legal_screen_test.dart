// Widget test của LegalScreen: Điều khoản / Chính sách / Quy tắc cộng đồng, trạng thái chờ và lỗi.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/legal_document.dart';
import 'package:myasvsj/com.myasvsj.screen/legal_screen.dart';

import 'auth_fakes.dart';

Widget app(FakeAuthDao dao, String type) => ChangeNotifierProvider(
  create: (_) => AuthController(dao),
  child: MaterialApp(home: LegalScreen(type: type)),
);

void main() {
  testWidgets("type 'terms' hiện Điều khoản sử dụng (server gọi là tos) và phiên bản", (tester) async {
    final dao = FakeAuthDao();
    await tester.pumpWidget(app(dao, 'terms'));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Điều khoản sử dụng'), findsOneWidget);
    expect(find.text('Phiên bản 1.0'), findsOneWidget);
    expect(find.text('Điều khoản sử dụng Senpai ơi (bản nháp 1.0).'), findsOneWidget);
  });

  testWidgets('Chính sách bảo mật và Quy tắc cộng đồng có tiêu đề riêng', (tester) async {
    final dao = FakeAuthDao()
      ..legal['privacy'] = const LegalDocument(type: 'PRIVACY', version: '1.0', content: 'Chúng tôi lưu email.')
      ..legal['community'] = const LegalDocument(type: 'COMMUNITY', version: '2.0', content: 'Tôn trọng người khác.');
    await tester.pumpWidget(app(dao, 'privacy'));
    await tester.pumpAndSettle();
    expect(find.text('Chính sách bảo mật'), findsOneWidget);
    expect(find.text('Chúng tôi lưu email.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(app(dao, 'community'));
    await tester.pumpAndSettle();
    expect(find.text('Quy tắc cộng đồng'), findsOneWidget);
    expect(find.text('Phiên bản 2.0'), findsOneWidget);
  });

  testWidgets('văn bản chưa có (404): ErrorView gọn gàng, Thử lại tải được', (tester) async {
    final dao = FakeAuthDao()..legal.remove('tos');
    await tester.pumpWidget(app(dao, 'terms'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có Điều khoản sử dụng. Hãy quay lại sau.'), findsOneWidget);

    dao.legal['tos'] = const LegalDocument(type: 'TOS', version: '1.1', content: 'Bản mới.');
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Bản mới.'), findsOneWidget);
  });

  testWidgets('mất mạng: hiện câu của ApiClient', (tester) async {
    final dao = FakeAuthDao()..failures['findLegal'] = const ApiException('Không kết nối được tới server.');
    await tester.pumpWidget(app(dao, 'community'));
    await tester.pumpAndSettle();
    expect(find.text('Không kết nối được tới server.'), findsOneWidget);
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('kéo xuống để tải lại', (tester) async {
    final dao = FakeAuthDao();
    await tester.pumpWidget(app(dao, 'terms'));
    await tester.pumpAndSettle();
    await tester.fling(find.text('Phiên bản 1.0'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(dao.calls.where((c) => c == 'findLegal').length, 2);
  });
}
