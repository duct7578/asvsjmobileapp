import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/faq_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/question_controller.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.model/question_compose.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/faq_tile.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/media_image.dart';
import 'package:myasvsj/com.myasvsj.screen/photo_picker.dart';
import 'package:myasvsj/com.myasvsj.screen/question_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Form "Đặt câu hỏi" ([questionId] null) và "Sửa câu hỏi" (`/qa/ask`, `/qa/{id}/edit` của web, màn 17 của thiết
/// kế): câu hỏi, chủ đề, mô tả chi tiết, tối đa 5 ảnh; nút Hủy / Đăng câu hỏi ở thanh dưới. Khi gõ câu hỏi mới
/// (≥ 8 ký tự) hiện hộp "Có thể đã có câu trả lời" với các câu hỏi thường gặp giống điều định hỏi.
///
/// Đặt xong: mở câu hỏi vừa đăng. Sửa xong: đóng form và trả về true để màn chi tiết hiện câu thông báo.
class QuestionFormScreen extends StatefulWidget {
  const QuestionFormScreen({super.key, this.questionId});

  /// null = đặt câu hỏi mới; khác null = sửa câu hỏi này.
  final int? questionId;

  @override
  State<QuestionFormScreen> createState() => _QuestionFormScreenState();
}

class _QuestionFormScreenState extends State<QuestionFormScreen> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _topicIds = <int>{};

  /// Ảnh đã đăng còn giữ (khi sửa) và ảnh mới chọn trên máy.
  List<MediaItem> _kept = [];
  List<String> _newImages = [];

  /// Đã thay đổi gì đó: rời form thì hỏi lại. [_leaving] = đang đóng form sau khi lưu.
  bool _dirty = false;
  bool _leaving = false;

  late final FaqController _faq = context.read<FaqController>();

  bool get _editing => widget.questionId != null;

  @override
  void initState() {
    super.initState();
    _faq.clearSuggestions();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final c = context.read<QuestionController>();
    await c.openForm(questionId: widget.questionId);
    final old = c.editing;
    if (!mounted || old == null) {
      return;
    }
    _title.text = old.title;
    _content.text = old.content;
    setState(() {
      _topicIds
        ..clear()
        ..addAll(old.topicIds);
      _kept = old.images;
      _dirty = false;
    });
  }

  @override
  void dispose() {
    _faq.clearSuggestions();
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  void _changed() {
    if (!_dirty) {
      setState(() => _dirty = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<QuestionController>();
    final ready = !c.isLoadingForm && c.compose != null;
    return PopScope(
      canPop: !_dirty || _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _leaveIfConfirmed();
        }
      },
      child: Scaffold(
        appBar: SenpaiAppBar(title: _editing ? 'Sửa câu hỏi' : 'Đặt câu hỏi', close: true),
        body: _body(c),
        bottomNavigationBar: ready
            ? SenpaiBottomBar(
                children: [
                  SenpaiButton(
                    label: 'Hủy',
                    kind: SenpaiButtonKind.secondary,
                    onPressed: () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: SenpaiButton(
                      label: c.isSaving ? 'Đang gửi…' : (_editing ? 'Lưu thay đổi' : 'Đăng câu hỏi'),
                      icon: Symbols.send_rounded,
                      expand: true,
                      onPressed: c.isSaving ? null : _save,
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _body(QuestionController c) {
    if (c.isLoadingForm) {
      return const LoadingView();
    }
    final compose = c.compose;
    if (compose == null) {
      // Không mở được form: phiên đăng nhập hết, không phải người hỏi, câu hỏi không còn…
      return ErrorView(message: c.formError ?? 'Không tải được dữ liệu. Vui lòng thử lại.', onRetry: _load);
    }
    final errors = c.fieldErrors;
    final status = c.editing?.status;
    final caption = SenpaiText.caption.copyWith(color: SenpaiColors.muted);
    final items = <Widget>[
      Text(
        _editing ? 'Sửa lại câu hỏi để mọi người hiểu đúng điều bạn cần.' : 'Hỏi cộng đồng, các senpai đã trải qua sẽ trả lời bạn.',
        style: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted),
      ),
      if (!_editing && compose.newAccount) _quota(compose),
      if (_editing && (status == 'PROCESSING' || status == 'REJECTED'))
        SenpaiNote(
          status == 'REJECTED'
              ? 'Câu hỏi chưa được đăng vì ảnh vi phạm Quy tắc cộng đồng (đã được gỡ). Sửa xong bấm “Lưu thay đổi” '
                    'để đăng lại.'
              : 'Ảnh đang được quét; trong lúc này chỉ bạn thấy câu hỏi.',
          icon: status == 'REJECTED' ? Symbols.block_rounded : Symbols.hourglass_top_rounded,
          tone: status == 'REJECTED' ? SenpaiTone.crit : SenpaiTone.warn,
        ),
      SenpaiLabeledField(
        label: 'Câu hỏi *',
        child: TextField(
          controller: _title,
          maxLength: compose.titleMax,
          minLines: 1,
          maxLines: 3,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'Ví dụ: Gia hạn visa du học cần mang những giấy tờ gì?',
            errorText: errors['title'],
            errorMaxLines: 2,
          ),
          onChanged: (text) {
            _changed();
            if (!_editing) {
              _faq.suggest(text);
            }
          },
        ),
      ),
      if (!_editing) ?_suggestions(),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text(
            'Chủ đề * (${_topicIds.length}/${compose.topicsMax})',
            style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final topic in compose.topics)
                FilterChip(
                  showCheckmark: false,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text(topic.name),
                  selected: _topicIds.contains(topic.id),
                  onSelected: (on) => setState(() {
                    _dirty = true;
                    if (on) {
                      _topicIds.add(topic.id);
                    } else {
                      _topicIds.remove(topic.id);
                    }
                  }),
                ),
            ],
          ),
          Text(
            errors['topicIds'] ?? 'Chọn từ 1 đến ${compose.topicsMax} chủ đề. Không có chủ đề phù hợp thì chọn “Khác”.',
            style: errors['topicIds'] != null ? caption.copyWith(color: SenpaiColors.crit) : caption,
          ),
        ],
      ),
      SenpaiLabeledField(
        label: compose.contentRequired ? 'Mô tả chi tiết *' : 'Mô tả chi tiết (không bắt buộc)',
        child: TextField(
          controller: _content,
          minLines: 4,
          maxLines: 12,
          maxLength: compose.contentMax,
          decoration: InputDecoration(
            hintText: 'Thêm bối cảnh để mọi người trả lời đúng: bạn đang ở đâu, đã thử những gì',
            hintMaxLines: 3,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            errorText: errors['content'],
            errorMaxLines: 3,
            helperText: compose.canPostLinks
                ? 'Bạn có tag định danh nên được chèn link. Không dùng link rút gọn (bit.ly, tinyurl…).'
                : 'Chỉ tài khoản đã có tag định danh mới được chèn link, ghi số điện thoại hoặc tài khoản Zalo, LINE, '
                      'Telegram, hay đăng ảnh có mã QR.',
            helperMaxLines: 5,
          ),
          onChanged: (_) => _changed(),
        ),
      ),
      if (c.editing?.places.isNotEmpty ?? false)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            const Icon(Symbols.location_on_rounded, size: 18, color: SenpaiColors.brand),
            Expanded(
              child: Text(
                'Địa điểm liên quan (giữ nguyên): ${c.editing!.places.map((p) => p.name).join(', ')}',
                style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
              ),
            ),
          ],
        ),
      _images(compose, errors['images']),
      if (c.formError != null) Text(c.formError!, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.crit)),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          items[i],
        ],
      ],
    );
  }

  /// Hạn mức đăng của tài khoản mới (`note` lantern; hết lượt thì crit).
  Widget _quota(QuestionCompose compose) {
    final full = compose.postsLimit > 0 && compose.postsUsed >= compose.postsLimit;
    return SenpaiNote(
      'Tài khoản mới, hôm nay: ${compose.postsUsed}/${compose.postsLimit} bài viết và review.'
      '${full ? ' Bạn đã dùng hết lượt đăng hôm nay, hãy quay lại vào ngày mai.' : ''}',
      tone: full ? SenpaiTone.crit : SenpaiTone.lantern,
    );
  }

  /// `Suggestions` của thiết kế: hộp ai-soft bo 18 "Có thể đã có câu trả lời" với các câu hỏi thường gặp giống
  /// câu đang gõ (mở rộng tại chỗ). null khi chưa có gợi ý.
  Widget? _suggestions() {
    final suggestions = context.watch<FaqController>().suggestions;
    if (suggestions.isEmpty) {
      return null;
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: SenpaiColors.aiSoft, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            spacing: 8,
            children: [
              const Icon(Symbols.quiz_rounded, size: 20, color: SenpaiColors.ink),
              Expanded(
                child: Text('Có thể đã có câu trả lời', style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
              ),
            ],
          ),
          Text(
            'Những câu hỏi thường gặp này giống điều bạn định hỏi. Nếu chưa đúng ý, bạn cứ đăng câu hỏi.',
            style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
          ),
          for (final entry in suggestions) FaqTile(entry: entry, compact: true),
        ],
      ),
    );
  }

  /// Ảnh đã đăng (khi sửa, bỏ được) và ảnh mới chọn; tổng cộng tối đa imagesMax.
  Widget _images(QuestionCompose compose, String? error) {
    final room = compose.imagesMax - _kept.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        if (_kept.isNotEmpty) ...[
          Text('Ảnh đã đăng', style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink)),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final image in _kept)
                Stack(
                  children: [
                    MediaImage(url: image.url, width: 80, height: 80, radius: 12),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Tooltip(
                        message: 'Bỏ ảnh này',
                        child: Material(
                          color: SenpaiColors.ink,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => setState(() {
                              _dirty = true;
                              _kept = [..._kept]..remove(image);
                            }),
                            child: const SizedBox.square(
                              dimension: 22,
                              child: Icon(Symbols.close_rounded, size: 14, color: SenpaiColors.onBrand),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
        PhotoPicker(
          paths: _newImages,
          max: room < 0 ? 0 : room,
          label: _kept.isEmpty ? 'Ảnh (không bắt buộc)' : 'Ảnh mới',
          onChanged: (paths) => setState(() {
            _dirty = true;
            _newImages = paths;
          }),
        ),
        Text(
          error ?? 'Ảnh JPG, PNG hoặc HEIC, tối đa ${compose.imagesMax} ảnh, mỗi ảnh không quá ${compose.imageMaxMb} MB.',
          style: SenpaiText.caption.copyWith(color: error != null ? SenpaiColors.crit : SenpaiColors.muted),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final c = context.read<QuestionController>();
    final saved = await c.saveQuestion(
      title: _title.text,
      content: _content.text,
      topicIds: _topicIds.toList(),
      keepImageIds: [for (final image in _kept) image.id],
      imagePaths: _newImages,
    );
    if (!saved || !mounted) {
      return;
    }
    setState(() => _leaving = true);
    if (_editing) {
      Navigator.pop(context, true);
      return;
    }
    // Câu hỏi mới: mở luôn câu vừa đăng, như web
    showMessage(context, c.takeMessage());
    final id = c.lastSavedId;
    if (id == null || id == 0) {
      Navigator.pop(context, true);
      return;
    }
    Navigator.pushReplacement(context, MaterialPageRoute<void>(builder: (_) => QuestionDetailScreen(questionId: id)));
  }

  /// Bấm quay lại khi form có thay đổi chưa lưu: hỏi trước khi bỏ.
  Future<void> _leaveIfConfirmed() async {
    if (await _confirmLeave() && mounted) {
      setState(() => _leaving = true);
      Navigator.pop(context);
    }
  }

  Future<bool> _confirmLeave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bỏ thay đổi?'),
        content: const Text('Bạn có thay đổi chưa lưu. Bạn có muốn bỏ các thay đổi này không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Ở lại')),
          FilledButton(
            style: SenpaiButtonStyle.danger(SenpaiButtonSize.medium),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Bỏ thay đổi'),
          ),
        ],
      ),
    );
    return ok == true;
  }
}
