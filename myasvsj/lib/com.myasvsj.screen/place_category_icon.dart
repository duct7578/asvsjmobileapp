import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';

/// Biểu tượng của danh mục địa điểm. Server gửi tên Material Symbols của web (`icon` của danh mục, ví dụ
/// "restaurant", "train"); tên lạ hiện biểu tượng địa điểm chung.
///
/// Mặc định là icon viền (Material Symbols Rounded) như chip, ô icon, dòng kết quả của thiết kế; [filled] true
/// cho icon đặc (Material Icons Round) trên ghim bản đồ đã có review.
IconData placeCategoryIcon(String? name, {bool filled = false}) {
  final pair = switch (name) {
    'local_convenience_store' => (Symbols.local_convenience_store_rounded, Icons.local_convenience_store_rounded),
    'restaurant' => (Symbols.restaurant_rounded, Icons.restaurant_rounded),
    'ramen_dining' => (Symbols.ramen_dining_rounded, Icons.ramen_dining_rounded),
    'local_cafe' => (Symbols.local_cafe_rounded, Icons.local_cafe_rounded),
    'train' => (Symbols.train_rounded, Icons.train_rounded),
    'shopping_cart' => (Symbols.shopping_cart_rounded, Icons.shopping_cart_rounded),
    'shopping_bag' => (Symbols.shopping_bag_rounded, Icons.shopping_bag_rounded),
    'account_balance' => (Symbols.account_balance_rounded, Icons.account_balance_rounded),
    'local_hospital' => (Symbols.local_hospital_rounded, Icons.local_hospital_rounded),
    'local_post_office' => (Symbols.local_post_office_rounded, Icons.local_post_office_rounded),
    'local_pharmacy' => (Symbols.local_pharmacy_rounded, Icons.local_pharmacy_rounded),
    'school' => (Symbols.school_rounded, Icons.school_rounded),
    'local_laundry_service' => (Symbols.local_laundry_service_rounded, Icons.local_laundry_service_rounded),
    'park' => (Symbols.park_rounded, Icons.park_rounded),
    'temple_buddhist' => (Symbols.temple_buddhist_rounded, Icons.temple_buddhist_rounded),
    'temple_hindu' => (Symbols.temple_hindu_rounded, Icons.temple_hindu_rounded),
    'church' => (Symbols.church_rounded, Icons.church_rounded),
    'smartphone' => (Symbols.smartphone_rounded, Icons.smartphone_rounded),
    'home_work' => (Symbols.home_work_rounded, Icons.home_work_rounded),
    'home' => (Symbols.home_rounded, Icons.home_rounded),
    'apartment' => (Symbols.apartment_rounded, Icons.apartment_rounded),
    'work' => (Symbols.work_rounded, Icons.work_rounded),
    'translate' => (Symbols.translate_rounded, Icons.translate_rounded),
    'celebration' => (Symbols.celebration_rounded, Icons.celebration_rounded),
    _ => (Symbols.location_on_rounded, Icons.location_on_rounded),
  };
  return filled ? pair.$2 : pair.$1;
}

/// Tone của ô icon danh mục (dòng kết quả trên bản đồ, thẻ địa điểm trong form review, "Review mới"), giống bảng
/// màu của thiết kế: siêu thị / cửa hàng hồng, quán ăn vàng đèn lồng, ga tàu / giặt là xanh nhạt, công viên / chùa
/// xanh lá, phòng khám / nhà thuốc đỏ nhạt.
SenpaiTone placeCategoryTone(String? name) => switch (name) {
  'restaurant' || 'ramen_dining' || 'local_cafe' || 'celebration' => SenpaiTone.lantern,
  'train' || 'local_laundry_service' || 'school' || 'translate' => SenpaiTone.ai,
  'park' || 'temple_buddhist' || 'temple_hindu' || 'church' => SenpaiTone.ok,
  'local_hospital' || 'local_pharmacy' => SenpaiTone.crit,
  'account_balance' || 'local_post_office' || 'home_work' || 'home' || 'apartment' || 'work' => SenpaiTone.neutral,
  _ => SenpaiTone.brand,
};
