import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:myasvsj/com.myasvsj.model/blog_place.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/place_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// "Địa điểm liên quan" của bài (khối RelatedPlaces của thiết kế): thẻ trắng bo 18, sectionHead có icon map, mỗi
/// địa điểm một dòng (ô icon tròn 40, tên Title/S, loại · địa chỉ Caption, link "Chỉ đường"), kẻ line giữa các dòng.
/// Bấm tên mở trang địa điểm, "Chỉ đường" mở Google Maps.
class BlogPlaceList extends StatelessWidget {
  const BlogPlaceList({super.key, required this.places});

  final List<BlogPlace> places;

  @override
  Widget build(BuildContext context) {
    return SenpaiCard(
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          const SectionHead('Địa điểm liên quan', icon: Symbols.map_rounded),
          for (var i = 0; i < places.length; i++) ...[
            if (i > 0) const Divider(),
            _row(context, places[i]),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, BlogPlace place) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: place.id == null
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => PlaceDetailScreen(placeId: place.id!)),
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          spacing: 10,
          children: [
            IconTile(place.isNew ? Symbols.travel_explore_rounded : Symbols.location_on_rounded, radius: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    place.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink),
                  ),
                  if (place.detail.isNotEmpty)
                    Text(
                      place.detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
                    ),
                ],
              ),
            ),
            LinkText('Chỉ đường', icon: Symbols.directions_rounded, onTap: () => _directions(context, place)),
          ],
        ),
      ),
    );
  }

  static Future<void> _directions(BuildContext context, BlogPlace place) async {
    var opened = false;
    try {
      opened = await launchUrl(Uri.parse(place.directionsUrl), mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      showMessage(context, 'Không mở được Google Maps.');
    }
  }
}
