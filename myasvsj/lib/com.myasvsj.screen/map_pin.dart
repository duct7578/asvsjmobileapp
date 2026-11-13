import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.model/map_place.dart';
import 'package:myasvsj/com.myasvsj.screen/place_category_icon.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

/// Ghim một địa điểm trên bản đồ, theo các ghim của thiết kế (màn 07) và chú thích của web:
/// - sáng (`pin/review`): tròn brand 44 viền trắng 3, icon đặc, bóng Float, số review trên viên thuốc lantern ở góc
///   phải; đang chọn thì to 52;
/// - mờ (`pin/none`): tròn trắng 34 viền line 2, icon viền muted: chưa có review;
/// - lừa đảo (`pin/scam`): tròn trắng 40 viền crit 2, icon crit, dấu "!" đỏ ở góc (ghim sáng có cảnh báo thì dấu
///   "!" nằm ở góc trái);
/// - vuông: ghim cộng đồng; viền lantern và nhạt màu: ghim của mình chờ duyệt; nền xám: đã đóng cửa.
class MapPin extends StatelessWidget {
  const MapPin({super.key, required this.place, required this.icon, this.selected = false, this.onTap});

  /// Kích thước khung của ghim sáng và ghim mờ (Marker của bản đồ dùng cỡ này).
  static const double litSize = 44;
  static const double dimSize = 34;

  /// Ghim sáng đang chọn và ghim mờ có cảnh báo lừa đảo.
  static const double selectedSize = 52;
  static const double scamSize = 40;

  final MapPlace place;

  /// Tên biểu tượng của danh mục (Material Symbols).
  final String icon;
  final bool selected;
  final VoidCallback? onTap;

  /// Cạnh khung Marker cần cho ghim của [place].
  static double sizeFor(MapPlace place, {bool selected = false}) {
    if (place.isLit) {
      return selected ? selectedSize : litSize;
    }
    return place.scam ? scamSize : dimSize;
  }

  /// Câu đọc cho trình đọc màn hình, giống `pinLabel` của web.
  String get label => [
    place.name,
    if (place.reviewCount > 0) '${place.reviewCount} review' else 'chưa có review',
    if (place.closed) 'đã đóng cửa',
    if (place.scam) 'có cảnh báo lừa đảo',
    if (place.isPending) 'chờ Moderator duyệt',
  ].join(', ');

  @override
  Widget build(BuildContext context) {
    final lit = place.isLit;
    final size = sizeFor(place, selected: selected);
    final scamDim = place.scam && !lit;
    final Color background;
    final Color foreground;
    final Color border;
    final double borderWidth;
    if (place.closed) {
      background = SenpaiColors.muted;
      foreground = SenpaiColors.onBrand;
      border = SenpaiColors.surface;
      borderWidth = 2;
    } else if (lit) {
      background = SenpaiColors.brand;
      foreground = SenpaiColors.onBrand;
      border = SenpaiColors.surface;
      borderWidth = 3;
    } else if (scamDim) {
      background = SenpaiColors.surface;
      foreground = SenpaiColors.crit;
      border = SenpaiColors.crit;
      borderWidth = 2;
    } else {
      background = SenpaiColors.surface;
      foreground = SenpaiColors.muted;
      border = selected ? SenpaiColors.brand : SenpaiColors.line;
      borderWidth = selected ? 3 : 2;
    }
    final radius = place.isCommunity ? BorderRadius.circular(size * 0.3) : BorderRadius.circular(size / 2);
    final iconSize = lit ? (selected ? 26.0 : 22.0) : (scamDim ? 20.0 : 18.0);
    final body = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: place.isPending ? background.withValues(alpha: 0.6) : background,
        borderRadius: radius,
        border: Border.all(color: place.isPending ? SenpaiColors.lantern : border, width: borderWidth),
        boxShadow: lit ? SenpaiColors.shadowFloat : null,
      ),
      child: Icon(placeCategoryIcon(icon, filled: lit), size: iconSize, color: foreground),
    );
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              body,
              if (lit)
                Positioned(
                  left: size - 18,
                  top: -6,
                  child: _CountBadge(text: '${place.reviewCount}'),
                ),
              if (place.scam)
                Positioned(
                  left: lit ? -6 : size - 14,
                  top: -4,
                  child: const _ScamBadge(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Số review trên ghim sáng: viên thuốc lantern viền trắng 1.5, chữ Overline ink.
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: SenpaiColors.lantern,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: SenpaiColors.surface, width: 1.5),
      ),
      child: Text(text, style: SenpaiText.overline.copyWith(color: SenpaiColors.ink)),
    );
  }
}

/// Dấu "!" của ghim có cảnh báo lừa đảo: tròn crit 18, chữ Label/S trắng.
class _ScamBadge extends StatelessWidget {
  const _ScamBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: SenpaiColors.crit, shape: BoxShape.circle),
      child: Text('!', style: SenpaiText.labelS.copyWith(color: SenpaiColors.onBrand)),
    );
  }
}
