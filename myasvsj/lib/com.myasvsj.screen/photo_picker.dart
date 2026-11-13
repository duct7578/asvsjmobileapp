import 'dart:io';
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

/// Ô chọn ảnh cho form (bài viết, câu hỏi, review, ảnh minh chứng tag): chụp bằng camera hoặc chọn
/// trong thư viện, tối đa [max] ảnh, hiện ảnh nhỏ có nút xóa.
///
/// Giao diện theo `photoPicker(label, n, max)` của thiết kế: nhãn "label (n/max)" Label/M, rồi các ảnh nhỏ 80 × 80
/// bo 12 có nút "x" tròn màu ink ở góc, và hai ô viền đứt màu brand nền brand-soft "Chụp ảnh" / "Chọn ảnh".
///
/// Mỗi ảnh được thu nhỏ còn cạnh dài ≤ 1600 px và đổi sang JPEG trước khi đưa ra ngoài, vì server chỉ đọc
/// JPEG và PNG (ảnh iPhone mặc định là HEIC). [onChanged] nhận danh sách đường dẫn file trên máy; Controller
/// chuyển nguyên danh sách này cho DAO, DAO gửi bằng `ApiClient.sendMultipart`.
class PhotoPicker extends StatefulWidget {
  const PhotoPicker({super.key, required this.paths, required this.onChanged, this.max = 5, this.label = 'Ảnh'});

  /// Ảnh đang chọn (đường dẫn trên máy).
  final List<String> paths;
  final ValueChanged<List<String>> onChanged;
  final int max;
  final String label;

  @override
  State<PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends State<PhotoPicker> {
  static const double _side = 1600;
  final _picker = ImagePicker();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final full = widget.paths.length >= widget.max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Text(
          '${widget.label} (${widget.paths.length}/${widget.max})',
          style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final path in widget.paths)
              PhotoThumb(
                image: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const ColoredBox(
                    color: SenpaiColors.surface2,
                    child: Center(child: Icon(Symbols.broken_image_rounded, color: SenpaiColors.muted)),
                  ),
                ),
                onRemove: () => widget.onChanged([...widget.paths]..remove(path)),
              ),
            if (!full) ...[
              _AddTile(
                icon: Symbols.photo_camera_rounded,
                label: 'Chụp ảnh',
                onTap: _busy ? null : () => _pick(ImageSource.camera),
              ),
              _AddTile(
                icon: Symbols.photo_library_rounded,
                label: 'Chọn ảnh',
                onTap: _busy ? null : () => _pick(ImageSource.gallery),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Future<void> _pick(ImageSource source) async {
    setState(() => _busy = true);
    try {
      final room = widget.max - widget.paths.length;
      final List<XFile> picked;
      if (source == ImageSource.camera) {
        final one = await _picker.pickImage(source: source, maxWidth: _side, maxHeight: _side, imageQuality: 85);
        picked = one == null ? const [] : [one];
      } else {
        picked = await _picker.pickMultiImage(maxWidth: _side, maxHeight: _side, imageQuality: 85, limit: room);
      }
      final added = <String>[];
      for (final file in picked.take(room)) {
        added.add(await _toJpeg(file.path));
      }
      if (added.isNotEmpty) {
        widget.onChanged([...widget.paths, ...added]);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Không mở được camera hoặc thư viện ảnh.')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Đổi sang JPEG (ảnh HEIC của iPhone, ảnh WebP…). Lỗi thì giữ file gốc.
  Future<String> _toJpeg(String path) async {
    if (path.toLowerCase().endsWith('.jpg') || path.toLowerCase().endsWith('.jpeg')) {
      return path;
    }
    try {
      final target = '${Directory.systemTemp.path}/senpai_${DateTime.now().microsecondsSinceEpoch}.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(path, target,
          quality: 85, minWidth: _side.toInt(), minHeight: _side.toInt(), format: CompressFormat.jpeg);
      return result?.path ?? path;
    } catch (_) {
      return path;
    }
  }
}

/// Ảnh nhỏ 80 × 80 bo 12 có nút "x" tròn 22 màu ink ở góc trên phải (thumbnail trong `photoPicker` của thiết kế).
///
/// Dùng cho ảnh mới chọn trong [PhotoPicker] và cho ảnh / video đã đăng còn giữ lại trong form sửa:
/// `PhotoThumb(image: MediaImage(url: m.url, radius: 0), onRemove: …)`. [removeTooltip] là chữ gợi ý của nút bỏ.
class PhotoThumb extends StatelessWidget {
  const PhotoThumb({
    super.key,
    required this.image,
    required this.onRemove,
    this.removeTooltip = 'Bỏ ảnh này',
    this.size = 80,
  });

  /// Nội dung ô (Image.file, MediaImage…), được cắt bo 12 và phủ kín ô.
  final Widget image;
  final VoidCallback? onRemove;
  final String removeTooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: image)),
          if (onRemove != null)
            Positioned(
              right: 2,
              top: 2,
              child: Tooltip(
                message: removeTooltip,
                child: Semantics(
                  button: true,
                  child: InkResponse(
                    onTap: onRemove,
                    radius: 18,
                    // Vùng bấm 26 quanh nút 22
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(color: SenpaiColors.ink, shape: BoxShape.circle),
                        child: const Icon(Symbols.close_rounded, size: 14, color: SenpaiColors.onBrand),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ô "Chụp ảnh" / "Chọn ảnh": 80 × 80, viền đứt brand 1.5 (nét 6, cách 4), nền brand-soft, bo 12,
/// icon 24 và chữ Label/S màu brand-text.
class _AddTile extends StatelessWidget {
  const _AddTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = onTap == null ? SenpaiColors.muted : SenpaiColors.brandText;
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: SizedBox(
        width: 80,
        height: 80,
        child: CustomPaint(
          foregroundPainter: _DashedBorderPainter(color: onTap == null ? SenpaiColors.line : SenpaiColors.brand),
          child: Material(
            color: SenpaiColors.brandSoft,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 4,
                children: [
                  Icon(icon, size: 24, color: color),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SenpaiText.labelS.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vẽ viền đứt nét bo 12 (`dash: [6, 4]`, `sw: 1.5` trong spec), nằm trong mép ô.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  static const double _width = 1.5;
  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_width / 2);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12 - _width / 2)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _width;
    for (final PathMetric metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => oldDelegate.color != color;
}
