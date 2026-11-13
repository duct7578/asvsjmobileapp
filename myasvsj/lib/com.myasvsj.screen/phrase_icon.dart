import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Biểu tượng của một chủ đề học hoặc loại địa điểm Nhật ngữ. Server gửi tên Material Symbols của web
/// ("payments", "local_convenience_store"…), vẽ bằng Material Symbols Rounded viền như thiết kế; tên lạ hiện nhãn
/// chung.
class PhraseIcon extends StatelessWidget {
  const PhraseIcon(this.name, {super.key, this.size, this.color});

  final String name;
  final double? size;
  final Color? color;

  /// Tên của web → biểu tượng Material Symbols Rounded: biểu tượng chủ đề (AcademicService.ICONS), loại địa điểm
  /// (place_categories) và hai phần Mẫu câu / Từ vựng.
  static const Map<String, IconData> icons = {
    'label': Symbols.label_rounded,
    'payments': Symbols.payments_rounded,
    'help': Symbols.help_rounded,
    'restaurant_menu': Symbols.restaurant_menu_rounded,
    'train': Symbols.train_rounded,
    'medical_services': Symbols.medical_services_rounded,
    'description': Symbols.description_rounded,
    'waving_hand': Symbols.waving_hand_rounded,
    'home': Symbols.home_rounded,
    'bed': Symbols.bed_rounded,
    'work': Symbols.work_rounded,
    'school': Symbols.school_rounded,
    'shopping_cart': Symbols.shopping_cart_rounded,
    'local_post_office': Symbols.local_post_office_rounded,
    'smartphone': Symbols.smartphone_rounded,
    'directions_bus': Symbols.directions_bus_rounded,
    'local_laundry_service': Symbols.local_laundry_service_rounded,
    'emergency': Symbols.emergency_rounded,
    'celebration': Symbols.celebration_rounded,
    'account_balance': Symbols.account_balance_rounded,
    'translate': Symbols.translate_rounded,
    'forum': Symbols.forum_rounded,
    'local_convenience_store': Symbols.local_convenience_store_rounded,
    'restaurant': Symbols.restaurant_rounded,
    'local_hospital': Symbols.local_hospital_rounded,
    'local_pharmacy': Symbols.local_pharmacy_rounded,
    'park': Symbols.park_rounded,
    'temple_buddhist': Symbols.temple_buddhist_rounded,
    'home_work': Symbols.home_work_rounded,
    'place': Symbols.place_rounded,
    'storefront': Symbols.storefront_rounded,
    'directions': Symbols.directions_rounded,
    'chat': Symbols.chat_rounded,
    'abc': Symbols.abc_rounded,
  };

  /// Biểu tượng của tên [name] của web; tên lạ là nhãn chung.
  static IconData of(String name) => icons[name] ?? Symbols.label_rounded;

  /// Màu ô biểu tượng của nhóm thứ [index] trong lưới (thiết kế: Thanh toán hồng, Hỏi đường xanh nhạt, Khám bệnh
  /// xanh lá, Mua sắm vàng), lặp lại theo vòng.
  static SenpaiTone toneAt(int index) => _tones[index % _tones.length];

  static const _tones = [SenpaiTone.brand, SenpaiTone.ai, SenpaiTone.ok, SenpaiTone.lantern];

  @override
  Widget build(BuildContext context) => Icon(of(name), size: size, color: color);
}

/// Ô vuông bo góc chứa biểu tượng của chủ đề / loại địa điểm (`iconTile(icon, tone, size, r)` của thiết kế).
class PhraseIconTile extends StatelessWidget {
  const PhraseIconTile(this.name, {super.key, this.tone = SenpaiTone.brand, this.size = 40, this.radius = 12});

  final String name;
  final SenpaiTone tone;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => IconTile(PhraseIcon.of(name), tone: tone, size: size, radius: radius);
}

/// Thanh tiến độ "đã thuộc" bo tròn (`progress()` của thiết kế). Là LinearProgressIndicator của Material nên test
/// vẫn tìm được; theme đã cho màu brand, nền surface-2, cao 8, bo tròn hai đầu.
class PhraseProgress extends StatelessWidget {
  const PhraseProgress({super.key, required this.learned, required this.total, this.height = 8, this.color, this.trackColor});

  final int learned;
  final int total;
  final double height;
  final Color? color;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: total <= 0 ? 0 : (learned / total).clamp(0.0, 1.0),
      minHeight: height,
      color: color,
      backgroundColor: trackColor,
      borderRadius: BorderRadius.circular(99),
    );
  }
}
