import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/place_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/review_controller.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.model/place_detail.dart';
import 'package:myasvsj/com.myasvsj.model/review_compose.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/media_image.dart';
import 'package:myasvsj/com.myasvsj.screen/photo_picker.dart';
import 'package:myasvsj/com.myasvsj.screen/place_category_icon.dart';
import 'package:myasvsj/com.myasvsj.screen/review_star_picker.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Form viết review (UC-U16, khi không có [reviewId]) và sửa review (UC-U17), xóa review (UC-U18) ở thanh tiêu đề
/// khi sửa. Màn 10 của thiết kế: nút X, thẻ địa điểm, ghi chú lượt đăng của tài khoản mới, chọn 1–5 sao, ô nội dung
/// 10–2.000 ký tự có bộ đếm, tối đa 5 ảnh, nút "Đăng review" ở thanh dưới. Khi lưu hoặc xóa xong, màn hình đóng và
/// trả về true để màn trước hiện câu thông báo của server (`ReviewController.takeMessage`).
class ReviewFormScreen extends StatefulWidget {
  const ReviewFormScreen({super.key, this.placeId, this.reviewId, this.externalPlaceId, this.placeName = ''});

  /// Viết review cho địa điểm [placeId], hoặc sửa review [reviewId].
  final int? placeId;
  final int? reviewId;

  /// Địa điểm OpenStreetMap chưa có trên Senpai ơi ("Viết review đầu tiên"): server thêm địa điểm khi lưu.
  final String? externalPlaceId;

  /// Tên địa điểm để hiện trên form.
  final String placeName;

  @override
  State<ReviewFormScreen> createState() => _ReviewFormScreenState();
}

class _ReviewFormScreenState extends State<ReviewFormScreen> {
  final _content = TextEditingController();
  int _rating = 0;

  /// Ảnh cũ giữ lại (khi sửa) và ảnh mới chọn trên máy.
  List<MediaItem> _keep = [];
  List<String> _newPaths = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final reviews = context.read<ReviewController>();
    await reviews.openForm(placeId: widget.placeId, externalPlaceId: widget.externalPlaceId, reviewId: widget.reviewId);
    final old = reviews.editing;
    if (!mounted || old == null) {
      return;
    }
    _content.text = old.content;
    setState(() {
      _rating = old.rating;
      _keep = [
        for (final m in old.media)
          if (m.isImage) m,
      ];
    });
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  /// Có thay đổi chưa lưu: hỏi trước khi bỏ (giống "Bỏ review đang viết?" của web).
  bool _dirty(ReviewController reviews) {
    if (_newPaths.isNotEmpty) {
      return true;
    }
    return reviews.editing == null && (_rating > 0 || _content.text.trim().isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ReviewController>();
    final editing = reviews.editing;
    final ready = !reviews.isLoadingForm && reviews.compose != null;
    return PopScope(
      canPop: reviews.isSaving || !_dirty(reviews),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmLeave();
        }
      },
      child: Scaffold(
        appBar: SenpaiAppBar(
          title: editing == null && widget.reviewId == null ? 'Viết review' : 'Sửa review',
          close: true,
          actions: [
            if (editing != null)
              IconButton(
                tooltip: 'Xóa review',
                color: SenpaiColors.crit,
                icon: const Icon(Symbols.delete_rounded),
                onPressed: reviews.isSaving ? null : () => _delete(reviews, editing.id!),
              ),
          ],
        ),
        body: _body(reviews),
        bottomNavigationBar: ready
            ? SenpaiBottomBar(
                children: [
                  Expanded(
                    child: SenpaiButton(
                      label: reviews.isSaving ? 'Đang gửi…' : (editing == null ? 'Đăng review' : 'Lưu thay đổi'),
                      icon: Symbols.send_rounded,
                      loading: reviews.isSaving,
                      expand: true,
                      onPressed: () => _save(reviews),
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _body(ReviewController reviews) {
    if (reviews.isLoadingForm) {
      return const LoadingView();
    }
    final compose = reviews.compose;
    if (compose == null) {
      // Không mở được form: chưa đăng nhập, tài khoản staff, review không phải của mình hoặc đã bị xóa
      return ErrorView(message: reviews.formError ?? 'Không mở được form review.', onRetry: _load);
    }
    final editing = reviews.editing;
    final errors = reviews.fieldErrors;
    final placeName = editing?.placeName.isNotEmpty == true ? editing!.placeName : widget.placeName;
    final room = compose.imagesMax - _keep.length;
    final sections = <Widget>[
      if (placeName.isNotEmpty) _placeCard(placeName, _knownPlace(editing?.placeId ?? widget.placeId)),
      if (editing != null && editing.isRejected)
        const SenpaiNote(
          'Review chưa được đăng vì ảnh hoặc video vi phạm Quy tắc cộng đồng. Hãy sửa rồi lưu lại.',
          icon: Symbols.report_rounded,
          tone: SenpaiTone.crit,
        ),
      if (editing == null && compose.newAccount) SenpaiNote(_quotaText(compose), tone: SenpaiTone.lantern),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Text('Đánh giá *', style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink)),
          ReviewStarPicker(value: _rating, errorText: errors['rating'], onChanged: (n) => setState(() => _rating = n)),
        ],
      ),
      SenpaiLabeledField(
        label: 'Nội dung *',
        child: TextField(
          controller: _content,
          minLines: 4,
          maxLines: 12,
          maxLength: compose.contentMax,
          onChanged: (_) => setState(() {}),
          style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
          decoration: InputDecoration(
            hintText: 'Bạn thấy nơi này thế nào? Có mẹo gì cho người mới không?',
            helperText: 'Ít nhất ${compose.contentMin} ký tự',
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            errorText: errors['content'],
          ),
        ),
      ),
      if (_keep.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text('Ảnh đang có (${_keep.length})', style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink)),
            Wrap(spacing: 10, runSpacing: 10, children: [for (final m in _keep) _keptThumb(m, editing?.scanningMediaIds)]),
          ],
        ),
      if (editing != null && editing.media.any((m) => !m.isImage))
        Text('Video đã gắn (đăng từ web) được giữ nguyên.', style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
      if (room > 0 || _newPaths.isNotEmpty)
        PhotoPicker(
          paths: _newPaths,
          max: room < _newPaths.length ? _newPaths.length : room,
          label: _keep.isEmpty ? 'Ảnh (không bắt buộc)' : 'Ảnh mới',
          onChanged: (paths) => setState(() => _newPaths = paths),
        ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          Text(
            'Tối đa ${compose.imagesMax} ảnh. Ảnh được quét tự động trước khi hiện cho mọi người.',
            style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
          ),
          for (final key in const ['images', 'place'])
            if (errors[key] != null) Text(errors[key]!, style: SenpaiText.caption.copyWith(color: SenpaiColors.crit)),
        ],
      ),
      if (reviews.formError != null)
        SenpaiNote(reviews.formError!, icon: Symbols.error_rounded, tone: SenpaiTone.crit),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          sections[i],
        ],
      ],
    );
  }

  /// Chi tiết địa điểm đã tải sẵn (form mở từ chi tiết địa điểm), để thẻ địa điểm có danh mục và địa chỉ.
  PlaceDetail? _knownPlace(int? placeId) {
    if (placeId == null) {
      return null;
    }
    try {
      return context.read<PlaceController>().detailOf(placeId);
    } on ProviderNotFoundException {
      return null;
    }
  }

  /// Thẻ địa điểm: ô icon tròn 44 của danh mục, tên Title/S, danh mục · địa chỉ Caption.
  Widget _placeCard(String name, PlaceDetail? place) {
    final sub = [place?.categoryName ?? '', place?.address ?? ''].where((s) => s.isNotEmpty).join(' · ');
    return SenpaiCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        spacing: 12,
        children: [
          IconTile(
            placeCategoryIcon(place?.categoryIcon),
            tone: place == null ? SenpaiTone.brand : placeCategoryTone(place.categoryIcon),
            size: 44,
            radius: 22,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
                if (sub.isNotEmpty)
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _quotaText(ReviewCompose c) =>
      'Tài khoản mới (dưới ${c.newAccountDays} ngày): hôm nay còn ${c.postsLeft}/${c.postsLimit} lượt đăng bài viết '
      'hoặc review.';

  /// Ảnh cũ 80 bo 12, nút bỏ ảnh tròn ink 22 ở góc, nhãn "Đang quét" khi ảnh còn đang được quét.
  Widget _keptThumb(MediaItem media, List<int>? scanning) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        children: [
          MediaImage(url: media.url, width: 80, height: 80, radius: 12),
          if (scanning?.contains(media.id) == true)
            const Positioned(left: 4, bottom: 4, child: SenpaiBadge('Đang quét', tone: SenpaiTone.neutral)),
          Positioned(
            right: 4,
            top: 4,
            child: Tooltip(
              message: 'Bỏ ảnh này',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => setState(
                  () => _keep = [
                    for (final m in _keep)
                      if (m.id != media.id) m,
                  ],
                ),
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
        ],
      ),
    );
  }

  Future<void> _save(ReviewController reviews) async {
    FocusScope.of(context).unfocus();
    final saved = await reviews.saveReview(
      placeId: widget.placeId,
      externalPlaceId: widget.externalPlaceId,
      rating: _rating,
      content: _content.text,
      keep: _keep,
      imagePaths: _newPaths,
    );
    if (saved && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _delete(ReviewController reviews, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa review?'),
        content: const Text('Xóa review này? Điểm của review này sẽ được thu lại.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
          FilledButton(
            style: SenpaiButtonStyle.danger(SenpaiButtonSize.medium),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    if (await reviews.deleteReview(id) && mounted) {
      Navigator.pop(context, true);
    } else if (mounted) {
      showMessage(context, reviews.takeMessage());
    }
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Bỏ review đang viết?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Viết tiếp')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Bỏ')),
        ],
      ),
    );
    if (leave == true && mounted) {
      Navigator.pop(context, false);
    }
  }
}
