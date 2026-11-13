// Công cụ "chụp màn hình" để so giao diện Flutter với ảnh thiết kế Figma (design/figma-export/ref/*.png).
//
// Test trong thư mục này chỉ chạy khi có cờ SHOTS:
//   flutter test test/design_shots --dart-define=SHOTS=true
//   flutter test test/design_shots/more_shot_test.dart --dart-define=SHOTS=true
// Ảnh ra ở design/flutter-shots/<tên>.png, khổ 390 dp × chiều cao chọn (mặc định 844), tỉ lệ 1:1 như ảnh tham chiếu.
// Không có cờ thì test tự bỏ qua, nên `flutter test` thường không chậm đi.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';

/// true khi chạy với `--dart-define=SHOTS=true`.
const bool shotsEnabled = bool.fromEnvironment('SHOTS');

/// Lý do bỏ qua dùng cho tham số `skip:` của testWidgets.
const String? shotSkip = shotsEnabled ? null : 'Chỉ chạy với --dart-define=SHOTS=true';

final _shotKey = GlobalKey(debugLabel: 'shot');
bool _fontsLoaded = false;

/// Nạp font thật của app (Be Vietnam Pro, Bricolage, Zen Maru, Material Icons, Material Symbols Rounded) vào môi
/// trường test; mặc định flutter test vẽ chữ thành ô vuông.
Future<void> loadShotFonts() async {
  if (_fontsLoaded) {
    return;
  }
  final manifest = json.decode(await rootBundle.loadString('FontManifest.json')) as List<dynamic>;
  for (final entry in manifest) {
    final family = (entry as Map<String, dynamic>)['family'] as String;
    // Hai kiểu Symbols không dùng tới (Outlined, Sharp) nặng gần 20 MB: bỏ qua
    if (family.endsWith('MaterialSymbolsOutlined') || family.endsWith('MaterialSymbolsSharp')) {
      continue;
    }
    final loader = FontLoader(family);
    for (final font in entry['fonts'] as List<dynamic>) {
      loader.addFont(rootBundle.load((font as Map<String, dynamic>)['asset'] as String));
    }
    await loader.load();
  }
  _fontsLoaded = true;
}

/// Bọc màn hình [screen] trong theme thật của app để chụp. Dùng khi app thử của test (homeTestApp,
/// profileTestApp…) tạo MaterialApp không có theme: `profileTestApp(shotTheme(const ProfileScreen()))`.
Widget shotTheme(Widget screen) => Theme(data: SenpaiTheme.light(), child: screen);

/// MaterialApp có theme của app, dùng khi tự cấp Provider: `MultiProvider(providers: …, child: shotApp(screen))`.
Widget shotApp(Widget home) =>
    MaterialApp(debugShowCheckedModeBanner: false, theme: SenpaiTheme.light(), home: home);

/// Đặt khổ màn hình 390 × [height] dp (tỉ lệ 1), nạp font, dựng [app], chờ ảnh SVG / font tải xong.
///
/// Màn hình dài hơn 844 thì truyền [height] lớn để chụp trọn nội dung như ảnh thiết kế (Trang chủ ~2474).
Future<void> pumpShot(WidgetTester tester, Widget app, {double height = 844}) async {
  await loadShotFonts();
  tester.view.physicalSize = Size(390, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(RepaintBoundary(key: _shotKey, child: app));
  await settleShot(tester);
}

/// Chờ các việc bất đồng bộ thật (giải mã SVG, ảnh) rồi dựng lại vài khung hình.
Future<void> settleShot(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle(const Duration(milliseconds: 50), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
}

/// Lưu ảnh màn hình hiện tại vào design/flutter-shots/[name].png và trả về đường dẫn file.
Future<String> saveShot(WidgetTester tester, String name) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(_shotKey));
  // flutter test mặc định vẽ BoxShadow không làm mờ: bật bóng thật, vẽ lại, chụp, rồi trả lại như cũ ngay trong
  // thân test (framework kiểm tra biến debug trước khi chạy tearDown)
  await _repaintWithShadows(tester, real: true);
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  await _repaintWithShadows(tester, real: false);
  final file = File('design/flutter-shots/$name.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!);
  // ignore: avoid_print
  print('SHOT ${file.absolute.path}');
  return file.path;
}

Future<void> _repaintWithShadows(WidgetTester tester, {required bool real}) async {
  debugDisableShadows = !real;
  for (final r in tester.allRenderObjects) {
    r.markNeedsPaint();
  }
  await tester.pump();
}
