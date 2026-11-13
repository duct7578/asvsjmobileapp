import 'package:flutter/material.dart';

/// Bảng màu của Design System "Senpai ơi – Mobile App Redesign" (biến "Senpai Color" trong Figma, lấy từ
/// tokens.css của web). Tên hằng giống tên biến trong Figma, viết camelCase: `brand-soft` → [brandSoft].
///
/// Màn hình dùng các hằng này (hoặc Theme của [SenpaiTheme]) thay cho Colors.xxx hay mã màu tự đặt.
abstract final class SenpaiColors {
  /// Nền màn hình.
  static const bg = Color(0xFFFBF4F3);

  /// Nền thẻ, ô nhập, thanh dưới.
  static const surface = Color(0xFFFFFFFF);

  /// Nền phụ: thẻ lồng trong thẻ, ô tìm kiếm phụ, chip trung tính.
  static const surface2 = Color(0xFFF8EEF0);

  /// Chữ chính, thẻ tối (thẻ câu tiếng Nhật).
  static const ink = Color(0xFF2F3E6E);

  /// Chữ phụ, icon phụ.
  static const muted = Color(0xFF676E8A);

  /// Viền, đường kẻ.
  static const line = Color(0xFFEBDCE0);

  /// Màu chủ đạo: nút chính, tab đang chọn.
  static const brand = Color(0xFFC2456E);

  /// Brand khi nhấn.
  static const brandStrong = Color(0xFFA8365C);

  /// Nền hồng nhạt: chỉ báo tab, nút Soft, badge brand.
  static const brandSoft = Color(0xFFFCE9EF);

  /// Chữ trên nền hồng nhạt, link.
  static const brandText = Color(0xFF8E2B4E);

  /// Chữ / icon trên nền brand hoặc ink.
  static const onBrand = Color(0xFFFFFFFF);

  /// Nền xanh nhạt của gợi ý "Dành cho bạn", tag định danh.
  static const aiSoft = Color(0xFFE6E9F4);

  /// Điểm nhấn đèn lồng: sao đánh giá, sự kiện.
  static const lantern = Color(0xFFE8A33C);
  static const lanternSoft = Color(0xFFFDF0D8);
  static const lanternText = Color(0xFF7A4E00);

  /// Thành công / đã giải quyết.
  static const ok = Color(0xFF2E7D5B);
  static const okSoft = Color(0xFFE1F2E9);

  /// Cảnh báo.
  static const warn = Color(0xFF8A5800);
  static const warnSoft = Color(0xFFFCEFD2);

  /// Lỗi, xoá, lừa đảo.
  static const crit = Color(0xFFB3261E);
  static const critSoft = Color(0xFFFBE1DF);

  /// Màu lớp phủ (scrim 45%) phía sau hộp thoại / bottom sheet.
  static const inkDeep = Color(0xFF1E2A52);

  /// Màu bản đồ minh hoạ.
  static const mapLand = Color(0xFFF3EEE6);
  static const mapPark = Color(0xFFDDEBD3);
  static const mapWater = Color(0xFFCFE3F2);
  static const mapRoad = Color(0xFFFFFFFF);

  /// Đổ bóng "Shadow/Card": thẻ nổi, ô tìm kiếm trên bản đồ, đoạn đang chọn của segmented.
  static const shadowCard = [BoxShadow(color: Color(0x142F3E6E), offset: Offset(0, 4), blurRadius: 16)];

  /// Đổ bóng "Shadow/Float": nút FAB, ghim bản đồ.
  static const shadowFloat = [BoxShadow(color: Color(0x47C2456E), offset: Offset(0, 8), blurRadius: 20)];

  /// Đổ bóng "Shadow/Bar": thanh tab dưới, thanh hành động dưới, bottom sheet.
  static const shadowBar = [BoxShadow(color: Color(0x0F2F3E6E), offset: Offset(0, -2), blurRadius: 12)];
}

/// Cặp màu (nền, chữ) theo "tone" của thiết kế, dùng cho badge, avatar, iconTile, note (TONES trong spec):
/// `brand` hồng, `lantern` vàng, `ok` xanh lá, `warn` cam, `crit` đỏ, `ai` xanh nhạt, `neutral` xám hồng,
/// `solid` nền brand chữ trắng, `ink` nền xanh đậm chữ trắng.
enum SenpaiTone {
  brand(SenpaiColors.brandSoft, SenpaiColors.brandText),
  lantern(SenpaiColors.lanternSoft, SenpaiColors.lanternText),
  ok(SenpaiColors.okSoft, SenpaiColors.ok),
  warn(SenpaiColors.warnSoft, SenpaiColors.warn),
  crit(SenpaiColors.critSoft, SenpaiColors.crit),
  ai(SenpaiColors.aiSoft, SenpaiColors.ink),
  neutral(SenpaiColors.surface2, SenpaiColors.muted),
  solid(SenpaiColors.brand, SenpaiColors.onBrand),
  ink(SenpaiColors.ink, SenpaiColors.onBrand);

  const SenpaiTone(this.background, this.foreground);

  /// Màu nền.
  final Color background;

  /// Màu chữ / icon trên nền đó.
  final Color foreground;
}
