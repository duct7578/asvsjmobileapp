import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';

/// Nút "Chỉ đường": mở chỉ đường Google Maps tới địa điểm (app Google Maps nếu có, không thì trình duyệt).
/// [url] lấy từ thực thể (`directionsUrl` của MapPlace, PlaceOption, PlaceDetail).
///
/// Mặc định là nút Secondary (viền) có icon directions như `btn('Chỉ đường', 'Secondary', {icon: 'directions'})`
/// của thiết kế; [filled] true là nút Soft. Màn khác (ô thao tác của chi tiết địa điểm) gọi thẳng [open].
class PlaceDirectionsButton extends StatelessWidget {
  const PlaceDirectionsButton({
    super.key,
    required this.url,
    this.filled = false,
    this.size = SenpaiButtonSize.large,
    this.expand = false,
  });

  final String url;

  /// Nút nổi bật (FilledButton.tonal) thay vì nút viền.
  final bool filled;
  final SenpaiButtonSize size;

  /// true: giãn hết chiều ngang.
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return SenpaiButton(
      label: 'Chỉ đường',
      icon: Symbols.directions_rounded,
      kind: filled ? SenpaiButtonKind.soft : SenpaiButtonKind.secondary,
      size: size,
      expand: expand,
      onPressed: () => open(context, url),
    );
  }

  /// Mở chỉ đường tới [url]; báo nhẹ khi máy không mở được.
  static Future<void> open(BuildContext context, String url) async {
    var opened = false;
    try {
      opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      showMessage(context, 'Không mở được Google Maps trên máy này.');
    }
  }
}
