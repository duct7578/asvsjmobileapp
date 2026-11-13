import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';

/// Ảnh lấy từ server. [url] là đường dẫn như server trả về (`/media/…`) hoặc địa chỉ đầy đủ.
/// Ảnh lỗi hoặc không tải được hiện ô xám có biểu tượng, không làm hỏng màn hình.
class MediaImage extends StatelessWidget {
  const MediaImage({super.key, required this.url, this.width, this.height, this.fit = BoxFit.cover, this.radius = 8});

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: width,
      height: height,
      color: SenpaiColors.surface2,
      child: const Icon(Symbols.hide_image_rounded, color: SenpaiColors.muted),
    );
    if (url.isEmpty) {
      return ClipRRect(borderRadius: BorderRadius.circular(radius), child: placeholder);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        MediaItem.resolve(url),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => placeholder,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : Container(
                width: width,
                height: height,
                color: SenpaiColors.surface2,
                alignment: Alignment.center,
                child: const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
      ),
    );
  }
}
