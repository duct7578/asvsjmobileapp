import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_photo_viewer.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Ảnh của bài ở màn chi tiết (màn 13 của thiết kế): lưới 2 cột, mỗi ô 175 × 130 bo 14, cách 8. Bấm ảnh để xem lớn.
///
/// [skip]: số ảnh đầu đã hiện ở chỗ khác (ảnh bìa [BlogHeroImage] trên cùng bài), lưới chỉ hiện các ảnh sau;
/// số thứ tự "Xem ảnh n" và trình xem ảnh vẫn tính trên toàn bộ ảnh của bài.
/// App chưa phát video: video (đăng từ web) hiện một ô ghi chú.
class BlogMediaGrid extends StatelessWidget {
  const BlogMediaGrid({super.key, required this.media, this.skip = 0});

  final List<MediaItem> media;
  final int skip;

  @override
  Widget build(BuildContext context) {
    final images = imagesOf(media);
    final videoCount = media.length - images.length;
    final shown = [for (var i = skip; i < images.length; i++) i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        if (shown.length == 1 && skip == 0)
          _photo(context, images, shown.first, aspect: _aspect(images[shown.first]), radius: 14)
        else if (shown.isNotEmpty)
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 175 / 130,
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            children: [for (final i in shown) _photo(context, images, i, radius: 14)],
          ),
        if (videoCount > 0)
          const SenpaiNote(
            'Bài có video. App chưa phát được video, hãy xem trên trang web.',
            icon: Symbols.videocam_rounded,
            tone: SenpaiTone.neutral,
          ),
      ],
    );
  }

  /// Các ảnh (bỏ video) của bài, đúng thứ tự.
  static List<MediaItem> imagesOf(List<MediaItem> media) => [
    for (final m in media)
      if (m.isImage) m,
  ];

  static double _aspect(MediaItem image) {
    final w = image.width;
    final h = image.height;
    if (w == null || h == null || w <= 0 || h <= 0) {
      return 4 / 3;
    }
    // Ảnh quá dài hoặc quá dẹt bị cắt bớt cho vừa màn hình
    return (w / h).clamp(0.75, 2.0);
  }

  static Widget _photo(BuildContext context, List<MediaItem> images, int index, {double aspect = 1, double radius = 14}) {
    return _Tappable(
      images: images,
      index: index,
      child: AspectRatio(
        aspectRatio: aspect,
        child: CoverArt(imageUrl: images[index].url, radius: radius),
      ),
    );
  }
}

/// Ảnh bìa trên cùng bài (`cover(…, 358, 200, 20)` của thiết kế): ảnh đầu tiên của bài, bấm để xem lớn; bài không
/// có ảnh thì là cảnh minh hoạ cố định theo [seed] (id bài).
class BlogHeroImage extends StatelessWidget {
  const BlogHeroImage({super.key, required this.media, required this.seed, this.height = 200});

  final List<MediaItem> media;
  final Object? seed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final images = BlogMediaGrid.imagesOf(media);
    final cover = CoverArt(
      scene: CoverScene.forSeed(seed),
      imageUrl: images.isEmpty ? '' : images.first.url,
      width: double.infinity,
      height: height,
      radius: 20,
    );
    if (images.isEmpty) {
      return ExcludeSemantics(child: cover);
    }
    return _Tappable(images: images, index: 0, child: cover);
  }
}

/// Bấm ảnh thứ [index] mở trình xem ảnh cỡ lớn; nhãn trợ năng "Xem ảnh n".
class _Tappable extends StatelessWidget {
  const _Tappable({required this.images, required this.index, required this.child});

  final List<MediaItem> images;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Xem ảnh ${index + 1}',
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => BlogPhotoViewer(urls: [for (final m in images) m.url], initialIndex: index),
          ),
        ),
        child: child,
      ),
    );
  }
}
