import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:myasvsj/com.myasvsj.controller/phrase_controller.dart';
import 'package:myasvsj/com.myasvsj.model/phrase.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// "Đưa cho nhân viên xem" (màn 29 của thiết kế): nền trắng, nhãn vàng "Đưa màn hình này cho nhân viên", khối hồng
/// nhạt bo 32 chứa mẫu câu tiếng Nhật thật to (JP/L cỡ 40) và nghĩa, hai nút "Nghe phát âm" / "Đóng", và lời nhắc
/// màn hình luôn sáng. Màn hình được giữ sáng trong lúc mở và tắt giữ sáng khi rời màn.
class PhraseStaffScreen extends StatefulWidget {
  const PhraseStaffScreen({super.key, required this.phrase, this.keepScreenOn = _keepScreenOn});

  final Phrase phrase;

  /// Bật (true) / tắt (false) giữ màn hình sáng. Mặc định dùng wakelock_plus; test truyền hàm giả.
  final Future<void> Function(bool on) keepScreenOn;

  @override
  State<PhraseStaffScreen> createState() => _PhraseStaffScreenState();
}

Future<void> _keepScreenOn(bool on) async {
  try {
    await WakelockPlus.toggle(enable: on);
  } on Exception {
    // Máy không hỗ trợ giữ sáng: vẫn hiện mẫu câu như thường
  }
}

class _PhraseStaffScreenState extends State<PhraseStaffScreen> {
  late final PhraseController _phrases;

  @override
  void initState() {
    super.initState();
    _phrases = context.read<PhraseController>();
    widget.keepScreenOn(true);
  }

  @override
  void dispose() {
    widget.keepScreenOn(false);
    _phrases.stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final phrase = widget.phrase;
    return Scaffold(
      backgroundColor: SenpaiColors.surface,
      appBar: const SenpaiAppBar(title: 'Đưa cho nhân viên xem', close: true, backgroundColor: SenpaiColors.surface),
      body: SafeArea(
        child: LayoutBuilder(
          // Nội dung căn giữa màn hình; câu dài (hoặc xoay ngang) thì cuộn được
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: (box.maxHeight - 64).clamp(0, double.infinity)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 24,
                children: [
                  const SenpaiBadge(
                    'Đưa màn hình này cho nhân viên',
                    tone: SenpaiTone.lantern,
                    icon: Symbols.front_hand_rounded,
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                    decoration: BoxDecoration(color: SenpaiColors.brandSoft, borderRadius: BorderRadius.circular(32)),
                    child: Column(
                      spacing: 20,
                      children: [
                        Text(
                          phrase.japanese,
                          locale: const Locale('ja'),
                          textAlign: TextAlign.center,
                          style: SenpaiText.jpL.copyWith(color: SenpaiColors.ink, fontSize: 40, height: 1.1),
                        ),
                        Text(
                          phrase.meaningVi,
                          textAlign: TextAlign.center,
                          style: SenpaiText.bodyM.copyWith(color: SenpaiColors.brandText),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: Tooltip(
                          message: 'Nghe',
                          excludeFromSemantics: true,
                          child: OutlinedButton.icon(
                            // Lề ngang 16 thay vì 22 để "Nghe phát âm" vừa một dòng trên màn 360
                            style: SenpaiButtonStyle.secondary().copyWith(
                              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
                            ),
                            onPressed: _speak,
                            icon: const Icon(Symbols.volume_up_rounded),
                            label: const Text('Nghe phát âm', maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SenpaiButton(label: 'Đóng', expand: true, onPressed: () => Navigator.pop(context)),
                      ),
                    ],
                  ),
                  Text(
                    'Màn hình luôn sáng khi đang mở.',
                    textAlign: TextAlign.center,
                    style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _speak() async {
    final spoken = await _phrases.speak(widget.phrase.japanese);
    if (!spoken && mounted) {
      showMessage(context, _phrases.takeMessage());
    }
  }
}
