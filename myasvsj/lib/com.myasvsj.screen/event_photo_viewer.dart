import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/media_image.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

/// Xem ảnh lớn (album từ review, ảnh trong một review): vuốt sang trước / sau, phóng to bằng hai ngón,
/// chú thích "2/5 · Lan Anh · năm 2026".
Future<void> showEventPhotos(
  BuildContext context, {
  required List<({String url, String caption})> photos,
  int initialIndex = 0,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog.fullscreen(
      backgroundColor: SenpaiColors.inkDeep,
      child: EventPhotoViewer(photos: photos, initialIndex: initialIndex),
    ),
  );
}

/// Trình xem ảnh toàn màn hình nền ink-deep: thanh trên có nút Đóng và chú thích, nút "Trước" / "Sau" ở dưới.
class EventPhotoViewer extends StatefulWidget {
  const EventPhotoViewer({super.key, required this.photos, this.initialIndex = 0});

  final List<({String url, String caption})> photos;
  final int initialIndex;

  @override
  State<EventPhotoViewer> createState() => _EventPhotoViewerState();
}

class _EventPhotoViewerState extends State<EventPhotoViewer> {
  late final PageController _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_index];
    final caption = ['${_index + 1}/${widget.photos.length}', if (photo.caption.isNotEmpty) photo.caption].join(' · ');
    final navStyle = TextButton.styleFrom(
      foregroundColor: SenpaiColors.onBrand,
      disabledForegroundColor: SenpaiColors.onBrand.withValues(alpha: 0.35),
    );
    return Scaffold(
      backgroundColor: SenpaiColors.inkDeep,
      appBar: AppBar(
        backgroundColor: SenpaiColors.inkDeep,
        foregroundColor: SenpaiColors.onBrand,
        iconTheme: const IconThemeData(color: SenpaiColors.onBrand),
        titleTextStyle: SenpaiText.titleS.copyWith(color: SenpaiColors.onBrand),
        title: Text(caption, maxLines: 1, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          tooltip: 'Đóng',
          color: SenpaiColors.onBrand,
          icon: const Icon(Symbols.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: widget.photos.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => InteractiveViewer(
                  child: Center(
                    child: MediaImage(url: widget.photos[i].url, fit: BoxFit.contain, radius: 0),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  TextButton.icon(
                    style: navStyle,
                    onPressed: _index == 0 ? null : () => _go(_index - 1),
                    icon: const Icon(Symbols.chevron_left_rounded),
                    label: const Text('Trước'),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    style: navStyle,
                    onPressed: _index == widget.photos.length - 1 ? null : () => _go(_index + 1),
                    icon: const Icon(Symbols.chevron_right_rounded),
                    label: const Text('Sau'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _go(int index) =>
      _pages.animateToPage(index, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
}
