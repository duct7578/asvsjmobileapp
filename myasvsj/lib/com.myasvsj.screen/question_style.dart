import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';

// Vài quy ước giao diện dùng chung của Hỏi-Đáp và Câu hỏi thường gặp (màn 15–18 của thiết kế).

/// Tone của ảnh đại diện chữ cái khi người viết chưa có ảnh: cố định theo id để cùng một người luôn cùng màu,
/// xoay vòng các tone của thiết kế (brand, lantern, ok, ai).
SenpaiTone questionAvatarTone(int? authorId) {
  const tones = [SenpaiTone.brand, SenpaiTone.lantern, SenpaiTone.ok, SenpaiTone.ai];
  return tones[(authorId ?? 0).abs() % tones.length];
}

/// Số viết theo kiểu Việt Nam như thiết kế và web: 1204 → "1.204".
String formatQaCount(int n) {
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
