import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/event_controller.dart';
import 'package:myasvsj/com.myasvsj.model/event_review_form.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/event_text.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/media_image.dart';
import 'package:myasvsj/com.myasvsj.screen/photo_picker.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Form "Viết review" của một sự kiện (màn 21 của thiết kế, `GET /api/events/{id}/review-form`): viết review năm
/// nay, hoặc sửa review năm nay khi đã viết. Tên sự kiện, hạn mức tài khoản mới, chọn 1–5 sao (sao 40), nội dung
/// có bộ đếm ký tự, tối đa 5 ảnh (app không gửi video), nút "Đăng review" dính đáy màn hình.
///
/// Lưu xong thì đóng và trả về true để màn trước hiện câu thông báo của server ([EventController.takeMessage]).
class EventReviewFormScreen extends StatefulWidget {
  const EventReviewFormScreen({super.key, required this.eventId});

  final int eventId;

  @override
  State<EventReviewFormScreen> createState() => _EventReviewFormScreenState();
}

class _EventReviewFormScreenState extends State<EventReviewFormScreen> {
  /// Lời tả số sao bên cạnh "n/5".
  static const List<String> _ratingLabels = ['Rất tệ', 'Chưa tốt', 'Tạm được', 'Tốt', 'Tuyệt vời'];

  final _content = TextEditingController();
  int _rating = 0;

  /// Ảnh / video đã đăng của review đang sửa, còn giữ lại.
  List<MediaItem> _kept = [];

  /// Ảnh mới chọn trên máy.
  List<String> _photos = [];

  /// Đã bắt đầu tải form: trước đó Controller có thể còn giữ form / lỗi của lần mở trước.
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final events = context.read<EventController>();
    _opened = true;
    await events.openReviewForm(widget.eventId);
    final own = events.form?.review;
    if (!mounted || own == null) {
      return;
    }
    setState(() {
      _rating = own.rating;
      _content.text = own.content;
      _kept = List.of(own.media);
    });
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventController>();
    final form = _opened ? events.form : null;
    final editing = form?.isEditing ?? false;
    final ready = _opened && !events.isLoadingForm && form != null;
    return Scaffold(
      appBar: SenpaiAppBar(title: editing ? 'Sửa review' : 'Viết review', close: true),
      body: _body(events, form),
      bottomNavigationBar: ready
          ? SenpaiBottomBar(
              children: [
                Expanded(
                  child: SenpaiButton(
                    label: events.isSaving ? 'Đang gửi…' : (editing ? 'Lưu thay đổi' : 'Đăng review'),
                    icon: Symbols.send_rounded,
                    expand: true,
                    loading: events.isSaving,
                    onPressed: () => _save(events),
                  ),
                ),
              ],
            )
          : null,
    );
  }

  Widget _body(EventController events, EventReviewForm? form) {
    if (!_opened || events.isLoadingForm) {
      return const LoadingView();
    }
    if (form == null) {
      // Không mở được form: sự kiện chưa bắt đầu, đã bị xóa, chưa đăng nhập…
      return ErrorView(message: events.formError ?? 'Không tải được sự kiện.', onRetry: _load);
    }
    final errors = events.fieldErrors;
    final event = form.event;
    final keptImages = _kept.where((m) => m.isImage).length;
    final room = form.imagesMax - keptImages;
    final children = <Widget>[
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 2,
        children: [
          Text(event.title, style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink)),
          Text(
            'Review cho lần tổ chức năm ${event.reviewYear} · ${eventDateRange(event)}',
            style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
          ),
        ],
      ),
      if (form.newAccount && !form.isEditing) _quota(form),
      if (events.formError != null) SenpaiNote(events.formError!, icon: Symbols.error_rounded, tone: SenpaiTone.crit),
      _ratingPicker(events, errors['rating']),
      SenpaiLabeledField(
        label: 'Nội dung *',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            TextField(
              controller: _content,
              minLines: 4,
              maxLines: 12,
              maxLength: form.contentMax,
              enabled: !events.isSaving,
              style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
              // Bộ đếm ký tự vẽ ở hàng dưới cùng câu gợi ý, thẳng mép ô như thiết kế
              buildCounter: (_, {required currentLength, required isFocused, required maxLength}) => null,
              decoration: InputDecoration(
                hintText: 'Không khí, chi phí, nên đi giờ nào',
                errorText: errors['content'],
                errorMaxLines: 3,
              ),
            ),
            _ContentHelp(
              controller: _content,
              max: form.contentMax,
              help: form.canPostLinks ? null : 'Chỉ tài khoản có tag định danh mới chèn được link.',
            ),
          ],
        ),
      ),
      if (_kept.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text('Ảnh đã đăng', style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink)),
            Wrap(spacing: 10, runSpacing: 10, children: [for (final m in _kept) _keptTile(m)]),
          ],
        ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          PhotoPicker(
            paths: _photos,
            max: room < 0 ? 0 : room,
            label: _kept.isEmpty ? 'Ảnh' : 'Ảnh mới',
            onChanged: (paths) => setState(() => _photos = paths),
          ),
          Text(
            'Tối đa ${form.imagesMax} ảnh, mỗi ảnh không quá ${form.imageMaxMb} MB.',
            style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
          ),
          if (errors['images'] != null)
            Text(errors['images']!, style: SenpaiText.caption.copyWith(color: SenpaiColors.crit)),
        ],
      ),
      Text(
        'Chữ được lọc từ khóa ngay. Ảnh được quét sau khi đăng; trong lúc đó review ở trạng thái '
        '“đang xử lý” và chỉ bạn thấy.',
        style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
      ),
    ];
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, i) => children[i],
    );
  }

  /// `ratingPicker`: "Đánh giá *", 5 sao 40 (chọn: lantern, chưa: muted) và "n/5" + lời tả.
  Widget _ratingPicker(EventController events, String? error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text('Đánh giá *', style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink)),
        Row(
          children: [
            for (var n = 1; n <= 5; n++)
              IconButton(
                tooltip: '$n sao',
                isSelected: n <= _rating,
                style: IconButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  fixedSize: const Size(44, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: Icon(
                  n <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 40,
                  color: n <= _rating ? SenpaiColors.lantern : SenpaiColors.muted,
                ),
                onPressed: events.isSaving ? null : () => setState(() => _rating = n),
              ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _rating > 0 ? '$_rating/5' : 'Chưa chọn',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SenpaiText.titleM.copyWith(color: _rating > 0 ? SenpaiColors.ink : SenpaiColors.muted),
                  ),
                  if (_rating > 0)
                    Text(
                      _ratingLabels[_rating - 1],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (error != null) Text(error, style: SenpaiText.caption.copyWith(color: SenpaiColors.crit)),
      ],
    );
  }

  /// "Tài khoản mới, hôm nay: 1/3 bài viết và review · 0/2 ghim · 0/1 video." (BR-07), chỉ khi viết mới.
  Widget _quota(EventReviewForm form) {
    final full = form.quotaFull;
    return SenpaiNote(
      'Tài khoản mới, hôm nay: ${form.postsUsed}/${form.postsLimit} bài viết và review · '
      '${form.pinsUsed}/${form.pinsLimit} ghim · ${form.videosUsed}/${form.videosLimit} video.'
      '${full ? ' Bạn đã dùng hết lượt đăng hôm nay, hãy quay lại vào ngày mai.' : ''}',
      icon: Symbols.info_rounded,
      tone: full ? SenpaiTone.crit : SenpaiTone.lantern,
    );
  }

  /// Ảnh / video đã đăng 80 × 80 bo 12, nút tròn ink "×" ở góc để bỏ.
  Widget _keptTile(MediaItem media) {
    return SizedBox.square(
      dimension: 80,
      child: Stack(
        children: [
          if (media.isImage)
            MediaImage(url: media.url, width: 80, height: 80, radius: 12)
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: SenpaiColors.surface2, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Symbols.videocam_rounded, color: SenpaiColors.muted),
            ),
          Positioned(
            right: 4,
            top: 4,
            child: Tooltip(
              message: media.isImage ? 'Bỏ ảnh' : 'Bỏ video',
              child: Material(
                color: SenpaiColors.ink,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => setState(() => _kept = [..._kept]..remove(media)),
                  child: const SizedBox.square(
                    dimension: 24,
                    child: Icon(Symbols.close_rounded, size: 14, color: SenpaiColors.onBrand),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save(EventController events) async {
    final saved = await events.saveReview(
      rating: _rating,
      content: _content.text,
      keepMediaIds: [for (final m in _kept) m.id],
      imagePaths: _photos,
    );
    if (saved && mounted) {
      Navigator.pop(context, true);
    }
  }
}

/// Hàng dưới ô nội dung: câu gợi ý Caption muted bên trái, bộ đếm "n/2000" bên phải (đổi theo chữ đang gõ).
class _ContentHelp extends StatelessWidget {
  const _ContentHelp({required this.controller, required this.max, this.help});

  final TextEditingController controller;
  final int max;
  final String? help;

  @override
  Widget build(BuildContext context) {
    final style = SenpaiText.caption.copyWith(color: SenpaiColors.muted);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (_, value, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Expanded(child: Text(help ?? '', style: style)),
          Text('${value.text.characters.length}/$max', style: style),
        ],
      ),
    );
  }
}
