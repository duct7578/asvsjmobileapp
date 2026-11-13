import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

/// Nút "Nghe": đọc câu tiếng Nhật bằng giọng đọc có sẵn của máy (miễn phí, không gọi server).
/// Kiểu thiết kế của thẻ câu tiếng Nhật: viên thuốc brand p[8,16,8,12], icon volume_up 18, chữ Label/M trắng.
/// [compact] là nút chỉ có biểu tượng, cho danh sách kết quả tìm kiếm.
class HomeSpeakButton extends StatefulWidget {
  const HomeSpeakButton({super.key, required this.text, this.compact = false});

  final String text;
  final bool compact;

  @override
  State<HomeSpeakButton> createState() => _HomeSpeakButtonState();
}

class _HomeSpeakButtonState extends State<HomeSpeakButton> {
  /// Chỉ tạo khi bấm lần đầu.
  FlutterTts? _tts;

  @override
  void dispose() {
    _tts?.stop();
    super.dispose();
  }

  Future<void> _speak() async {
    try {
      final tts = _tts ??= FlutterTts();
      await tts.setLanguage('ja-JP');
      await tts.setSpeechRate(0.45);
      await tts.stop();
      await tts.speak(widget.text);
    } catch (_) {
      // Máy không có giọng đọc tiếng Nhật: bỏ qua, câu vẫn hiện trên màn hình
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return IconButton(
        tooltip: 'Nghe ${widget.text}',
        color: SenpaiColors.brandText,
        icon: const Icon(Symbols.volume_up_rounded, size: 22),
        onPressed: _speak,
      );
    }
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: SenpaiColors.brand,
        foregroundColor: SenpaiColors.onBrand,
        minimumSize: const Size(48, 36),
        fixedSize: const Size.fromHeight(36),
        padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
        shape: const StadiumBorder(),
        textStyle: SenpaiText.labelM,
        iconSize: 18,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: _speak,
      icon: const Icon(Symbols.volume_up_rounded),
      label: const Text('Nghe'),
    );
  }
}
