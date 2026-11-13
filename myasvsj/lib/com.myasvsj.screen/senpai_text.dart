import 'package:flutter/painting.dart';

/// 13 kiểu chữ của Design System (text styles trong Figma). Tên giống Figma: `Display/XL` → [displayXL],
/// `Title/S` → [titleS], `JP/L` → [jpL]…
///
/// Các kiểu không có màu: chữ lấy màu của DefaultTextStyle (ink). Muốn màu khác thì
/// `SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)`.
///
/// Chữ Nhật trong mọi kiểu tự rơi về Zen Maru Gothic ([fontFamilyFallback]), vì Be Vietnam Pro không có chữ Nhật.
abstract final class SenpaiText {
  static const String _vn = 'BeVietnamPro';
  static const String _display = 'BricolageGrotesque';
  static const String _jp = 'ZenMaruGothic';

  /// Font dự phòng cho chữ Nhật.
  static const fontFamilyFallback = [_jp];

  static const _even = TextLeadingDistribution.even;

  /// Bricolage Grotesque ExtraBold 30/36, -0.5. Tiêu đề lớn (hero trang chủ).
  static const displayXL = TextStyle(
    fontFamily: _display,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w800,
    fontVariations: [FontVariation('wght', 800), FontVariation('opsz', 30)],
    fontSize: 30,
    height: 36 / 30,
    letterSpacing: -0.5,
    leadingDistribution: _even,
  );

  /// Bricolage Grotesque Bold 24/30, -0.3. Tiêu đề AppBar lớn của tab gốc, số liệu.
  static const displayL = TextStyle(
    fontFamily: _display,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700), FontVariation('opsz', 24)],
    fontSize: 24,
    height: 30 / 24,
    letterSpacing: -0.3,
    leadingDistribution: _even,
  );

  /// Bricolage Grotesque Bold 20/26, -0.2. Tiêu đề khối, tên địa điểm trong sheet.
  static const displayM = TextStyle(
    fontFamily: _display,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700), FontVariation('opsz', 20)],
    fontSize: 20,
    height: 26 / 20,
    letterSpacing: -0.2,
    leadingDistribution: _even,
  );

  /// Be Vietnam Pro SemiBold 17/24. Tiêu đề thẻ, tiêu đề AppBar thường, sectionHead.
  static const titleM = TextStyle(
    fontFamily: _vn,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w600,
    fontSize: 17,
    height: 24 / 17,
    leadingDistribution: _even,
  );

  /// Be Vietnam Pro SemiBold 15/21. Tên địa điểm, tiêu đề bài, tiêu đề dòng danh sách.
  static const titleS = TextStyle(
    fontFamily: _vn,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 21 / 15,
    leadingDistribution: _even,
  );

  /// Be Vietnam Pro Regular 15/22. Nội dung chính, ô nhập.
  static const bodyM = TextStyle(
    fontFamily: _vn,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w400,
    fontSize: 15,
    height: 22 / 15,
    leadingDistribution: _even,
  );

  /// Be Vietnam Pro Regular 13/19. Trích đoạn, mô tả phụ.
  static const bodyS = TextStyle(
    fontFamily: _vn,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w400,
    fontSize: 13,
    height: 19 / 13,
    leadingDistribution: _even,
  );

  /// Be Vietnam Pro SemiBold 14/20. Nút, chip, tab, link.
  static const labelM = TextStyle(
    fontFamily: _vn,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w600,
    fontSize: 14,
    height: 20 / 14,
    leadingDistribution: _even,
  );

  /// Be Vietnam Pro Medium 12/16. Badge, nhãn nhỏ, nút cỡ S.
  static const labelS = TextStyle(
    fontFamily: _vn,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 16 / 12,
    leadingDistribution: _even,
  );

  /// Be Vietnam Pro Regular 12/16. Thời gian, khu vực, chú thích.
  static const caption = TextStyle(
    fontFamily: _vn,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 16 / 12,
    leadingDistribution: _even,
  );

  /// Be Vietnam Pro Bold 11/14, +0.6. Tiêu đề nhóm viết HOA ("HÔM NAY", "KHÁM PHÁ"), số trên badge.
  static const overline = TextStyle(
    fontFamily: _vn,
    fontFamilyFallback: fontFamilyFallback,
    fontWeight: FontWeight.w700,
    fontSize: 11,
    height: 14 / 11,
    letterSpacing: 0.6,
    leadingDistribution: _even,
  );

  /// Zen Maru Gothic Bold 26/34. Câu tiếng Nhật lớn.
  static const jpL = TextStyle(
    fontFamily: _jp,
    fontWeight: FontWeight.w700,
    fontSize: 26,
    height: 34 / 26,
    leadingDistribution: _even,
  );

  /// Zen Maru Gothic Medium 17/24. Câu tiếng Nhật trong danh sách.
  static const jpM = TextStyle(
    fontFamily: _jp,
    fontWeight: FontWeight.w500,
    fontSize: 17,
    height: 24 / 17,
    leadingDistribution: _even,
  );
}
