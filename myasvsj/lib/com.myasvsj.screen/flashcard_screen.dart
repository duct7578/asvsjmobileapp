import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/phrase_controller.dart';
import 'package:myasvsj/com.myasvsj.model/phrase.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/empty_view.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_icon.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/sign_in_gate.dart';

/// "Thẻ ghi nhớ" (màn 28 của thiết kế): lượt thẻ PhraseController đã bắt đầu (startFlash / startPractice). Thanh
/// tiến độ, thẻ lớn bo 28 (nhãn loại · chủ đề, dấu thuộc, chữ Nhật lớn; lật ra romaji và nghĩa, nút "Nghe"). Bấm thẻ
/// để lật, rồi chọn "Chưa thuộc" hoặc "Đã thuộc". Thành viên được lưu câu trả lời; khách lật được nhưng không lưu
/// (có nút Đăng nhập). Hết lượt: "Xong n thẻ", "Luyện lại N thẻ chưa thuộc", "Xem danh sách Chưa thuộc".
class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key, this.fromLearningList = false});

  /// Mở từ danh sách "Chưa thuộc": cuối lượt không cần nút "Xem danh sách Chưa thuộc".
  final bool fromLearningList;

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  late final PhraseController _phrases;
  int? _userId;

  @override
  void initState() {
    super.initState();
    _phrases = context.read<PhraseController>();
    _userId = context.read<AuthController>().currentUser?.id;
  }

  @override
  void dispose() {
    _phrases.stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Khách vừa đăng nhập ở giữa lượt: đọc lại trang đầu để biết đã là thành viên, các thẻ sau được lưu
    final userId = context.select<AuthController, int?>((a) => a.currentUser?.id);
    if (userId != _userId) {
      _userId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _phrases.loadOverview());
    }
    final phrases = context.watch<PhraseController>();
    final card = phrases.currentCard;
    final total = phrases.flashCards.length;
    return Scaffold(
      appBar: SenpaiAppBar(
        title: card == null ? 'Thẻ ghi nhớ' : 'Thẻ ghi nhớ · ${phrases.flashIndex + 1}/$total',
        close: true,
      ),
      body: total == 0
          ? const EmptyView(text: 'Không có thẻ nào để luyện.', icon: Symbols.style_rounded)
          : card == null
              ? _done(phrases)
              : _card(phrases, card),
    );
  }

  Widget _card(PhraseController phrases, Phrase card) {
    final flipped = phrases.isFlipped;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PhraseProgress(learned: phrases.flashIndex + 1, total: phrases.flashCards.length, height: 6),
            if (!phrases.isMember) ...[const SizedBox(height: 16), _guestNote(context)],
            const SizedBox(height: 16),
            // Thẻ cao tối đa 430 như thiết kế, thấp hơn khi màn hình thấp
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 430),
                child: _bigCard(phrases, card, flipped),
              ),
            ),
            if (flipped) ...[
              const SizedBox(height: 16),
              Text(
                'Bấm vào thẻ để lật lại',
                textAlign: TextAlign.center,
                style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
              ),
              const SizedBox(height: 16),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: SenpaiButton(
                      label: 'Chưa thuộc',
                      kind: SenpaiButtonKind.secondary,
                      icon: Symbols.replay_rounded,
                      expand: true,
                      onPressed: phrases.isAnswering ? null : () => _answer(learned: false),
                    ),
                  ),
                  Expanded(
                    child: SenpaiButton(
                      label: 'Đã thuộc',
                      icon: Symbols.task_alt_rounded,
                      expand: true,
                      onPressed: phrases.isAnswering ? null : () => _answer(learned: true),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Thẻ lớn trắng bo 28 viền line, bóng Card: nhãn trên cùng, chữ Nhật ở giữa (lật ra đường kẻ, romaji Title/M
  /// brand-text, nghĩa Body/M), nút "Nghe" dạng viên thuốc surface-2 ở dưới. Bấm vào thẻ để lật.
  Widget _bigCard(PhraseController phrases, Phrase card, bool flipped) {
    final group = card.topics.isNotEmpty ? card.topics.first.name : card.category.name;
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(28)),
      side: BorderSide(color: SenpaiColors.line),
    );
    return Container(
      decoration: const ShapeDecoration(color: SenpaiColors.surface, shape: shape, shadows: SenpaiColors.shadowCard),
      child: Material(
        type: MaterialType.transparency,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: phrases.flip,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                Row(
                  spacing: 6,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SenpaiBadge(
                          group.isEmpty ? Phrase.kindName(card.kind) : '${Phrase.kindName(card.kind)} · $group',
                        ),
                      ),
                    ),
                    if (card.learned)
                      const SenpaiBadge('Đã thuộc', tone: SenpaiTone.ok, icon: Symbols.check_circle_rounded)
                    else if (card.learning)
                      const SenpaiBadge('Chưa thuộc', tone: SenpaiTone.lantern, icon: Symbols.replay_rounded),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 14,
                        children: [
                          Text(
                            card.japanese,
                            locale: const Locale('ja'),
                            textAlign: TextAlign.center,
                            style: SenpaiText.jpL.copyWith(color: SenpaiColors.ink, fontSize: 34, height: 1.1),
                          ),
                          if (flipped) ...[
                            const Divider(),
                            if (card.romaji.isNotEmpty)
                              Text(
                                card.romaji,
                                textAlign: TextAlign.center,
                                style: SenpaiText.titleM.copyWith(color: SenpaiColors.brandText),
                              ),
                            Text(
                              card.meaningVi,
                              textAlign: TextAlign.center,
                              style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
                            ),
                          ] else
                            Text(
                              'Bấm để lật thẻ',
                              textAlign: TextAlign.center,
                              style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Tooltip(
                    message: 'Nghe',
                    excludeFromSemantics: true,
                    child: FilledButton.icon(
                      style: SenpaiButtonStyle.size(SenpaiButtonSize.small).copyWith(
                        fixedSize: const WidgetStatePropertyAll(Size.fromHeight(36)),
                        backgroundColor: const WidgetStatePropertyAll(SenpaiColors.surface2),
                        foregroundColor: const WidgetStatePropertyAll(SenpaiColors.ink),
                        textStyle: const WidgetStatePropertyAll(SenpaiText.labelM),
                        iconSize: const WidgetStatePropertyAll(20),
                        shape: const WidgetStatePropertyAll(StadiumBorder()),
                      ),
                      onPressed: () => _speak(card),
                      icon: const Icon(Symbols.volume_up_rounded),
                      label: const Text('Nghe'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Khách: lật được nhưng không lưu; nói rõ và mời đăng nhập.
  Widget _guestNote(BuildContext context) {
    final signedIn = context.select<AuthController, bool>((a) => a.isSignedIn);
    return SenpaiNote(
      '',
      icon: Symbols.info_rounded,
      child: Row(
        spacing: 8,
        children: [
          Expanded(
            child: Text(
              signedIn
                  ? 'Kết quả không được lưu với tài khoản này.'
                  : 'Bạn đang luyện với tư cách khách: kết quả lật thẻ không được lưu.',
            ),
          ),
          if (!signedIn)
            TextButton(
              style: SenpaiButtonStyle.ghost(SenpaiButtonSize.small).copyWith(
                foregroundColor: const WidgetStatePropertyAll(SenpaiColors.lanternText),
                padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 8)),
              ),
              onPressed: () => requireSignIn(context),
              child: const Text('Đăng nhập'),
            ),
        ],
      ),
    );
  }

  /// Hết lượt: ô biểu tượng ăn mừng, "Xong n thẻ", số đã thuộc / chưa thuộc, câu về việc lưu, và các nút.
  Widget _done(PhraseController phrases) {
    final learning = phrases.learningIds.length;
    final signedIn = context.select<AuthController, bool>((a) => a.isSignedIn);
    final String note;
    if (phrases.isMember) {
      note = 'Đã lưu vào danh sách "Chưa thuộc" và "Đã thuộc" của bạn.';
    } else if (signedIn) {
      note = 'Kết quả không được lưu với tài khoản này.';
    } else {
      note = 'Đăng nhập để lưu kết quả lần sau.';
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
      children: [
        SenpaiCard(
          radius: 28,
          padding: const EdgeInsets.all(24),
          shadow: SenpaiColors.shadowCard,
          child: Column(
            spacing: 8,
            children: [
              const IconTile(Symbols.celebration_rounded, tone: SenpaiTone.brand, size: 72, radius: 36),
              const SizedBox(height: 4),
              Text(
                'Xong ${phrases.flashCards.length} thẻ',
                textAlign: TextAlign.center,
                style: SenpaiText.displayM.copyWith(color: SenpaiColors.ink),
              ),
              Text(
                'Đã thuộc: ${phrases.learnedIds.length} · Chưa thuộc: $learning',
                textAlign: TextAlign.center,
                style: SenpaiText.titleS.copyWith(color: SenpaiColors.brandText),
              ),
              Text(note, textAlign: TextAlign.center, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
              if (!signedIn)
                TextButton.icon(
                  style: SenpaiButtonStyle.ghost(SenpaiButtonSize.medium),
                  onPressed: () => requireSignIn(context),
                  icon: const Icon(Symbols.login_rounded),
                  label: const Text('Đăng nhập'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (learning > 0) ...[
          SenpaiButton(
            label: 'Luyện lại $learning thẻ chưa thuộc',
            icon: Symbols.replay_rounded,
            expand: true,
            onPressed: phrases.againLearning,
          ),
          const SizedBox(height: 12),
        ],
        if (phrases.isMember && learning > 0 && !widget.fromLearningList) ...[
          SenpaiButton(
            label: 'Xem danh sách Chưa thuộc',
            kind: SenpaiButtonKind.soft,
            icon: Symbols.list_rounded,
            expand: true,
            onPressed: _openLearningList,
          ),
          const SizedBox(height: 12),
        ],
        SenpaiButton(
          label: 'Xong',
          kind: SenpaiButtonKind.secondary,
          expand: true,
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Future<void> _answer({required bool learned}) async {
    await _phrases.answer(learned: learned);
    if (mounted) {
      showMessage(context, _phrases.takeMessage());
    }
  }

  Future<void> _speak(Phrase card) async {
    final spoken = await _phrases.speak(card.japanese);
    if (!spoken && mounted) {
      showMessage(context, _phrases.takeMessage());
    }
  }

  void _openLearningList() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => const PhraseListScreen(mine: 'learning')),
    );
  }
}
