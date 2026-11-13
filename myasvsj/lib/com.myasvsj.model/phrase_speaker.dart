import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Đọc tiếng Nhật bằng giọng ja-JP có sẵn trong máy (TextToSpeech của Android, AVSpeechSynthesizer của iOS), như nút
/// "Nghe" của web (speechSynthesis, ja-JP, tốc độ 0.85). Miễn phí, không gọi server.
///
/// Chỉ tạo FlutterTts ở lần đọc đầu, nên tạo lớp này (trong PhraseController) không đụng tới plugin.
class PhraseSpeaker {
  static const String language = 'ja-JP';

  /// flutter_tts lấy 0.5 làm tốc độ thường; web đọc bằng 0.85 lần tốc độ thường.
  static const double speechRate = 0.5 * 0.85;

  FlutterTts? _tts;
  bool _ready = false;

  /// Đọc [text]. Trả về false khi máy chưa có giọng đọc tiếng Nhật hoặc không đọc được.
  Future<bool> speak(String text) async {
    try {
      final tts = _tts ??= FlutterTts();
      if (!_ready) {
        // setLanguage trả về 1 khi máy có giọng ja-JP, 0 khi chưa có (Android, iOS)
        final result = await tts.setLanguage(language);
        if (result != 1 && result != true) {
          return false;
        }
        await tts.setSpeechRate(speechRate);
        _ready = true;
      }
      await tts.stop();
      await tts.speak(text);
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Dừng câu đang đọc (khi rời màn hình).
  Future<void> stop() async {
    try {
      await _tts?.stop();
    } on PlatformException {
      // Không đọc gì thì không có gì để dừng
    } on MissingPluginException {
      // Như trên
    }
  }
}
