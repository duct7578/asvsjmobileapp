import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.screen/media_image.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

/// Xem ảnh của bài cỡ lớn: vuốt ngang để chuyển ảnh, chụm hai ngón để phóng to.
class BlogPhotoViewer extends StatefulWidget {
  const BlogPhotoViewer({super.key, required this.urls, this.initialIndex = 0});

  /// Đường dẫn ảnh như server trả về.
  final List<String> urls;
  final int initialIndex;

  @override
  State<BlogPhotoViewer> createState() => _BlogPhotoViewerState();
}

class _BlogPhotoViewerState extends State<BlogPhotoViewer> {
  late final PageController _pages = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Nền tối ink-deep (màu lớp phủ của thiết kế) để ảnh nổi rõ, như trình xem ảnh thường gặp
    return Scaffold(
      backgroundColor: SenpaiColors.inkDeep,
      appBar: AppBar(
        backgroundColor: SenpaiColors.inkDeep,
        foregroundColor: SenpaiColors.onBrand,
        iconTheme: const IconThemeData(color: SenpaiColors.onBrand),
        titleTextStyle: SenpaiText.titleM.copyWith(color: SenpaiColors.onBrand),
        title: Text('Ảnh ${_index + 1}/${widget.urls.length}'),
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: widget.urls.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) => InteractiveViewer(
          maxScale: 4,
          child: Center(
            child: MediaImage(url: widget.urls[i], fit: BoxFit.contain, radius: 0),
          ),
        ),
      ),
    );
  }
}
