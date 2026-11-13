import 'package:flutter_tts/flutter_tts.dart';

/// Đọc to câu tiếng Nhật (giọng ja-JP) bằng bộ đọc văn bản của máy (flutter_tts), cho nút "Nghe" ở phần
/// "Từ vựng và mẫu câu" của địa điểm.
///
/// Bọc plugin trong một lớp riêng để test thay bằng lớp giả (widget test không có plugin). Plugin chỉ được tạo
/// lần đầu người dùng bấm "Nghe".
class PlaceSpeaker {
  FlutterTts? _tts;

  /// Đọc [text]; trả về false khi máy không đọc được tiếng Nhật.
  Future<bool> speak(String text) async {
    try {
      final tts = _tts ??= FlutterTts();
      final available = await tts.isLanguageAvailable('ja-JP');
      if (available == false) {
        return false;
      }
      await tts.setLanguage('ja-JP');
      await tts.setSpeechRate(0.45);
      await tts.stop();
      await tts.speak(text);
      return true;
    } catch (_) {
      // Không có bộ đọc văn bản hoặc plugin lỗi
      return false;
    }
  }

  /// Dừng câu đang đọc (khi rời màn hình).
  Future<void> stop() async {
    try {
      await _tts?.stop();
    } catch (_) {
      // Không có gì để dừng
    }
  }
}
