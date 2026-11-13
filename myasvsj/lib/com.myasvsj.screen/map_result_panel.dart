import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/place_controller.dart';
import 'package:myasvsj/com.myasvsj.model/map_category.dart';
import 'package:myasvsj/com.myasvsj.model/place_option.dart';
import 'package:myasvsj/com.myasvsj.screen/map_distance_text.dart';
import 'package:myasvsj/com.myasvsj.screen/place_category_icon.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Bảng kết quả nằm dưới bản đồ (`ResultPanel` của màn 07): kết quả tìm, "Địa điểm quanh đây", hoặc địa điểm của
/// một danh mục. Nền trắng bo trên 24, bóng Bar, thanh nắm kéo, tiêu đề Title/M + số địa điểm, nút đóng tròn 32;
/// mỗi dòng: ô icon tròn 40, tên Title/S, loại · địa chỉ Caption, bên phải số sao / "OSM" và khoảng cách.
/// Đọc trạng thái từ [PlaceController] (`panelTitle`, `panelItems`…).
class MapResultPanel extends StatelessWidget {
  const MapResultPanel({super.key, required this.onOpen, required this.onCategory});

  /// Bấm một địa điểm.
  final ValueChanged<PlaceOption> onOpen;

  /// Bấm một danh mục khớp từ khóa tìm.
  final ValueChanged<String> onCategory;

  @override
  Widget build(BuildContext context) {
    final places = context.watch<PlaceController>();
    final count = places.panelItems.length;
    return Container(
      decoration: const BoxDecoration(
        color: SenpaiColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: SenpaiColors.shadowBar,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(padding: EdgeInsets.only(top: 8, bottom: 6), child: SheetHandle()),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          places.panelTitle ?? '',
                          style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!places.isPanelLoading && places.panelError == null)
                          Text('$count địa điểm', style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng danh sách',
                    style: IconButton.styleFrom(
                      backgroundColor: SenpaiColors.surface2,
                      foregroundColor: SenpaiColors.muted,
                      fixedSize: const Size(32, 32),
                      minimumSize: const Size(32, 32),
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Symbols.close_rounded),
                    onPressed: places.closePanel,
                  ),
                ],
              ),
            ),
            Flexible(child: _body(context, places)),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, PlaceController places) {
    if (places.isPanelLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (places.panelError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Text(places.panelError!, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.crit)),
      );
    }
    final note = places.panelNote;
    final rows = <Widget>[
      for (final category in places.panelCategories) categoryRow(category, onTap: () => onCategory(category.id)),
      for (final option in places.panelItems) optionRow(places, option, onTap: () => onOpen(option)),
    ];
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      children: [
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text('Không có địa điểm nào khớp.', style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
          ),
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const Divider(),
          rows[i],
        ],
        if (note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(note, style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
          ),
      ],
    );
  }

  /// Dòng một danh mục khớp từ khóa (bảng kết quả và khung gợi ý).
  static Widget categoryRow(MapCategory category, {required VoidCallback onTap}) => _row(
    leading: IconTile(placeCategoryIcon(category.icon), tone: SenpaiTone.brand, radius: 20),
    title: category.name,
    subtitle: 'Danh mục · ${category.count} địa điểm',
    onTap: onTap,
  );

  /// Dòng một địa điểm Senpai ơi hoặc OpenStreetMap (bảng kết quả và khung gợi ý).
  static Widget optionRow(PlaceController places, PlaceOption option, {required VoidCallback onTap}) {
    final known = option.id == null ? null : places.placeById(option.id!);
    final icon = known != null
        ? places.categoryById(known.categoryId)?.icon
        : places.categoryByName(option.category)?.icon;
    final sub = [option.category, option.address].where((s) => s.isNotEmpty).join(' · ');
    final distance = formatMapDistance(places.distanceTo(option.lat, option.lng));
    final Widget meta;
    if (!option.isOnSenpai) {
      meta = const SenpaiBadge('OSM', tone: SenpaiTone.neutral);
    } else if (known != null && known.reviewCount > 0) {
      meta = Text(
        '★ ${known.rating?.toStringAsFixed(1) ?? ''} · ${known.reviewCount} review',
        style: SenpaiText.labelS.copyWith(color: SenpaiColors.lanternText),
      );
    } else {
      meta = Text('Chưa có review', style: SenpaiText.labelS.copyWith(color: SenpaiColors.muted));
    }
    return _row(
      leading: IconTile(
        placeCategoryIcon(icon),
        tone: option.isOnSenpai ? placeCategoryTone(icon) : SenpaiTone.neutral,
        radius: 20,
      ),
      title: option.name,
      subtitle: sub,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 2,
        children: [
          meta,
          if (distance.isNotEmpty) Text(distance, style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
        ],
      ),
      onTap: onTap,
    );
  }

  /// `PlaceRow` của thiết kế: p[10,0], cách 12, tên một dòng, dòng phụ Caption một dòng.
  static Widget _row({
    required Widget leading,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      horizontalTitleGap: 12,
      minVerticalPadding: 10,
      minTileHeight: 60,
      leading: leading,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
