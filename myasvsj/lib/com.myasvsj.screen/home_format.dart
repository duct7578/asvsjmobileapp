// Cách hiện chữ dùng chung cho Trang chủ, "Dành cho bạn", "Review mới" và "Tìm kiếm" (chép theo lib/ui.js của web).
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';

/// Tên ngắn của giai đoạn (STAGES của web).
const Map<String, String> stageNames = {
  'PRE': 'Sắp sang Nhật',
  'ARR': 'Mới đến',
  'LEAVE': 'Sắp về nước',
  'HOME': 'Đã về nước',
};

/// "ARR" → "Mới đến"; mã lạ giữ nguyên, null → rỗng.
String stageName(String? code) => stageNames[code] ?? (code ?? '');

/// "Arakawa-ku, Tokyo · 東京都荒川区" → "Arakawa-ku, Tokyo".
String areaRoman(String? name) => (name ?? '').split(' · ').first.trim();

/// "Arakawa-ku, Tokyo · 東京都荒川区" → "Arakawa-ku"; "Kita-ku, Osaka-shi, Osaka · …" → "Kita-ku, Osaka-shi".
String areaShort(String? name) {
  final roman = areaRoman(name);
  final comma = roman.lastIndexOf(',');
  return comma < 0 ? roman : roman.substring(0, comma).trim();
}

/// "Arakawa-ku, Tokyo · 東京都荒川区" → "Tokyo".
String prefectureShort(String? name) {
  final roman = areaRoman(name);
  return roman.substring(roman.lastIndexOf(',') + 1).trim();
}

/// 4 sao → "★★★★☆".
String starText(int rating) {
  final full = rating.clamp(0, 5);
  return '${'★' * full}${'☆' * (5 - full)}';
}

/// Sự kiện của trang chủ: "Đang diễn ra" hoặc "Còn n ngày".
String eventWhen(int daysUntil) => daysUntil <= 0 ? 'Đang diễn ra' : 'Còn $daysUntil ngày';

/// Màu tag server gửi ("#C2456E"); null khi không đọc được (dùng màu theme).
Color? tagColor(String hex) {
  final digits = hex.replaceFirst('#', '');
  if (digits.length != 6) {
    return null;
  }
  final value = int.tryParse(digits, radix: 16);
  return value == null ? null : Color(0xFF000000 | value);
}

/// 1250 → "1.250" (cách viết số của web).
String groupDigits(int n) {
  final s = n.abs().toString();
  final out = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) {
      out.write('.');
    }
    out.write(s[i]);
  }
  return out.toString();
}

/// Biểu tượng (Material Symbols Rounded, như thiết kế) ứng với tên biểu tượng Material của web (loại địa điểm,
/// loại mẫu câu); tên lạ → ghim địa điểm.
IconData categoryIcon(String? name) => switch (name) {
  'school' => Symbols.school_rounded,
  'restaurant' => Symbols.restaurant_rounded,
  'train' => Symbols.train_rounded,
  'local_convenience_store' => Symbols.local_convenience_store_rounded,
  'local_post_office' => Symbols.local_post_office_rounded,
  'local_pharmacy' => Symbols.local_pharmacy_rounded,
  'local_hospital' => Symbols.local_hospital_rounded,
  'account_balance' => Symbols.account_balance_rounded,
  'shopping_cart' => Symbols.shopping_cart_rounded,
  'shopping_bag' => Symbols.shopping_bag_rounded,
  'home' => Symbols.home_rounded,
  'apartment' => Symbols.apartment_rounded,
  'park' => Symbols.park_rounded,
  'temple_buddhist' => Symbols.temple_buddhist_rounded,
  'temple_hindu' => Symbols.temple_hindu_rounded,
  'church' => Symbols.church_rounded,
  'local_cafe' => Symbols.local_cafe_rounded,
  'work' => Symbols.work_rounded,
  'translate' => Symbols.translate_rounded,
  'celebration' => Symbols.celebration_rounded,
  'storefront' => Symbols.storefront_rounded,
  _ => Symbols.location_on_rounded,
};

/// Tone của ô biểu tượng loại địa điểm (như thiết kế: siêu thị hồng, ga tàu xanh nhạt, phòng khám xanh lá):
/// đi lại / trường học → ai, y tế → ok, văn phòng / bưu điện / ngân hàng → lantern, còn lại → brand.
SenpaiTone categoryTone(String? name) => switch (name) {
  'train' || 'school' || 'translate' => SenpaiTone.ai,
  'local_hospital' || 'local_pharmacy' || 'park' => SenpaiTone.ok,
  'account_balance' || 'local_post_office' || 'work' || 'temple_buddhist' || 'temple_hindu' || 'church' =>
    SenpaiTone.lantern,
  _ => SenpaiTone.brand,
};

/// Lời chào giống web: chỉ tên gọi (chữ cuối của tên), thêm một câu theo giai đoạn khi đã chọn khu vực và giai đoạn.
String homeGreeting({required String displayName, String? stage, String? areaName}) {
  final parts = displayName.trim().split(RegExp(r'\s+'));
  final name = parts.isEmpty ? '' : parts.last;
  if ((areaName ?? '').isEmpty || (stage ?? '').isEmpty) {
    return 'Chào $name!';
  }
  final area = areaShort(areaName);
  return 'Chào $name, ${switch (stage) {
    'PRE' => 'sắp sang Nhật rồi, chuẩn bị đến đâu rồi?',
    'ARR' => 'dạo này ở $area thế nào rồi?',
    'LEAVE' => 'sắp rời $area rồi, đừng quên các thủ tục nhé.',
    'HOME' => 'về nước rồi, giúp các bạn đi sau nhé!',
    _ => 'hôm nay thế nào rồi?',
  }}';
}

/// Dòng dưới "Dựa trên": chủ đề quan tâm lấy từ đâu và cách tự chọn (interestNote của web).
String interestNote({required int interests, required int chosen}) {
  const learnt = 'những bài bạn đã thích, lưu, bình luận hoặc viết trong 90 ngày qua';
  if (interests == 0) {
    return 'Bấm “Điều chỉnh” để chọn chủ đề bạn quan tâm. Senpai ơi cũng học từ những bài bạn thích, lưu hoặc '
        'bình luận để gợi ý sát hơn.';
  }
  if (chosen == 0) {
    return 'Chủ đề quan tâm được rút ra từ $learnt. Bấm “Điều chỉnh” để tự chọn chủ đề.';
  }
  return 'Bài thuộc chủ đề bạn chọn được ưu tiên trong gợi ý.'
      '${interests > chosen ? ' Các chủ đề còn lại được rút ra từ $learnt.' : ''}';
}

/// Mở [screen] chồng lên màn hình hiện tại.
Future<T?> pushScreen<T>(BuildContext context, Widget screen) =>
    Navigator.push<T>(context, MaterialPageRoute<T>(builder: (_) => screen));
