/// Viết số điểm như web: 1250 → "1.250", -20 → "-20".
String formatPoints(int n) {
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
