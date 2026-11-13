import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/place_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/review_controller.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.model/place_detail.dart';
import 'package:myasvsj/com.myasvsj.model/place_review.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/empty_view.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/map_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/media_image.dart';
import 'package:myasvsj/com.myasvsj.screen/place_category_icon.dart';
import 'package:myasvsj/com.myasvsj.screen/place_directions_button.dart';
import 'package:myasvsj/com.myasvsj.screen/place_phrase_tile.dart';
import 'package:myasvsj/com.myasvsj.screen/place_rating_stars.dart';
import 'package:myasvsj/com.myasvsj.screen/place_review_card.dart';
import 'package:myasvsj/com.myasvsj.screen/place_summary_sheet.dart';
import 'package:myasvsj/com.myasvsj.screen/report_dialog.dart';
import 'package:myasvsj/com.myasvsj.screen/review_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/sign_in_gate.dart';

/// Chi tiết địa điểm (UC-U15, màn 09 của thiết kế): ảnh (ảnh trong các review, không có thì tranh minh hoạ),
/// badge danh mục và nguồn, tên Display/L, tên Nhật / Anh / địa chỉ, thẻ điểm (điểm lớn, sao, phân bố số sao khi đã
/// có đủ review), cảnh báo lừa đảo, nút "Viết review", ba ô thao tác Lưu / Chỉ đường / "Báo đã đóng cửa", thanh chọn
/// Review | Từ vựng và mẫu câu; review (Thích / Báo cáo, hoặc Sửa / Xóa review của mình) và từ vựng, mẫu câu tiếng
/// Nhật có nút "Nghe". Khách bấm thao tác cần tài khoản thì được đưa sang Đăng nhập.
class PlaceDetailScreen extends StatefulWidget {
  const PlaceDetailScreen({super.key, required this.placeId});

  final int placeId;

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  /// 0: Review, 1: Từ vựng và mẫu câu.
  int _tab = 0;
  late final PlaceController _places;

  /// Người đang đăng nhập lúc dựng lần trước: đổi thì tải lại (đã lưu, review của mình, quyền thao tác).
  int? _userId;
  bool _userSeen = false;

  int get _id => widget.placeId;

  @override
  void initState() {
    super.initState();
    _places = context.read<PlaceController>();
    // Gọi sau khung hình đầu: notifyListeners() không được chạy giữa lúc đang dựng giao diện
    WidgetsBinding.instance.addPostFrameCallback((_) => _places.loadPlace(_id));
  }

  @override
  void dispose() {
    _places.stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final places = context.watch<PlaceController>();
    _watchUser(context.watch<AuthController>().currentUser?.id);
    final detail = places.detailOf(_id);
    return Scaffold(
      appBar: SenpaiAppBar(
        title: detail?.name ?? 'Địa điểm',
        actions: [
          if (detail?.lat != null)
            IconButton(
              tooltip: 'Xem trên bản đồ',
              icon: const Icon(Symbols.map_rounded),
              onPressed: () =>
                  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => MapScreen(focusPlaceId: detail!.id))),
            ),
        ],
      ),
      body: _body(places, detail),
    );
  }

  void _watchUser(int? userId) {
    if (_userSeen && userId == _userId) {
      return;
    }
    final changed = _userSeen;
    _userSeen = true;
    _userId = userId;
    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _places.loadPlace(_id);
        }
      });
    }
  }

  Widget _body(PlaceController places, PlaceDetail? detail) {
    if (detail == null) {
      final error = places.detailErrorOf(_id);
      if (error != null && !places.isLoadingDetail(_id)) {
        return ErrorView(message: error, onRetry: () => places.loadPlace(_id));
      }
      return const LoadingView();
    }
    final reviews = places.reviewsOf(_id);
    final sections = <Widget>[
      _PhotoHeader(images: [for (final r in reviews) ...r.images], seed: detail.id),
      ..._header(detail),
      _ratingCard(places, detail, reviews),
      _writeButton(detail),
      _actionTiles(detail),
      SenpaiSegmented<int>(
        segments: const [
          SenpaiSegment(value: 0, label: 'Review', icon: Symbols.rate_review_rounded),
          SenpaiSegment(value: 1, label: 'Từ vựng và mẫu câu', icon: Symbols.translate_rounded),
        ],
        selected: _tab,
        onChanged: (value) => _selectTab(places, value),
      ),
      ...(_tab == 0 ? _reviews(places, detail) : _phrases(places)),
    ];
    return RefreshIndicator(
      onRefresh: () => places.loadPlace(_id),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            sections[i],
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- thông tin

  List<Widget> _header(PlaceDetail d) {
    final names = [d.nameJa, d.nameEn, d.address].where((s) => s.isNotEmpty).join(' · ');
    return [
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          SenpaiBadge(d.categoryName, icon: placeCategoryIcon(d.categoryIcon)),
          placeSourceBadge(d.source),
          if (d.isPending) const SenpaiBadge('Chờ Moderator duyệt', tone: SenpaiTone.warn, icon: Symbols.schedule_rounded),
          if (d.closed)
            const SenpaiBadge('Đã đóng cửa (Moderator xác nhận)', tone: SenpaiTone.crit, icon: Symbols.block_rounded),
        ],
      ),
      if (d.closedWaiting && !d.closed)
        const SenpaiNote(
          'Nhiều người báo đã đóng cửa, đang chờ xác minh',
          icon: Symbols.storefront_rounded,
          tone: SenpaiTone.warn,
        ),
      if (d.mergedFrom != null)
        const SenpaiNote('Địa điểm bạn mở đã được gộp vào địa điểm này.', icon: Symbols.merge_rounded, tone: SenpaiTone.ai),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(d.name, style: SenpaiText.displayL.copyWith(color: SenpaiColors.ink)),
          if (names.isNotEmpty) Text(names, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
        ],
      ),
      if (d.scamWarnings.isNotEmpty) _scamBox(d),
    ];
  }

  /// Hộp cảnh báo lừa đảo (nền crit-soft): mỗi bài cảnh báo là một dòng bấm được mở bài viết.
  Widget _scamBox(PlaceDetail d) {
    return SenpaiCard(
      color: SenpaiColors.critSoft,
      borderColor: null,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 8,
            children: [
              const Icon(Symbols.warning_rounded, size: 20, color: SenpaiColors.crit),
              Text('Cảnh báo lừa đảo', style: SenpaiText.titleS.copyWith(color: SenpaiColors.crit)),
            ],
          ),
          for (final warning in d.scamWarnings)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: SenpaiColors.crit,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(vertical: 6),
                textStyle: SenpaiText.bodyS,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => BlogDetailScreen(blogId: warning.blogId)),
              ),
              child: Row(
                spacing: 6,
                children: [
                  Expanded(child: Text(warning.title, maxLines: 2, overflow: TextOverflow.ellipsis)),
                  const Icon(Symbols.chevron_right_rounded, size: 18),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Thẻ điểm (`Rating` bo 20): điểm Display/XL, sao, số review; bên phải phân bố 5→1 sao (chỉ khi đã tải đủ mọi
  /// review của địa điểm, để con số đúng thật); dòng "n review từ người dùng Senpai ơi".
  Widget _ratingCard(PlaceController places, PlaceDetail d, List<PlaceReview> reviews) {
    if (d.reviewCount == 0 || d.rating == null) {
      return SenpaiCard(
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Row(
          spacing: 12,
          children: [
            const IconTile(Symbols.star_rounded, tone: SenpaiTone.lantern),
            Expanded(
              child: Text(
                'Chưa có review. Hãy là người đầu tiên.',
                style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
              ),
            ),
          ],
        ),
      );
    }
    final published = [
      for (final r in reviews)
        if (r.isPublished) r,
    ];
    final complete = !places.hasMoreReviews(_id) && published.length == d.reviewCount;
    final summary = Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        Text(d.rating!.toStringAsFixed(1), style: SenpaiText.displayXL.copyWith(color: SenpaiColors.ink)),
        PlaceRatingStars(rating: d.rating!),
        Text('${d.reviewCount} review', style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
      ],
    );
    return SenpaiCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Row(
            spacing: 20,
            children: [
              if (complete) ...[
                summary,
                Expanded(
                  child: Column(
                    spacing: 4,
                    children: [
                      for (var star = 5; star >= 1; star--)
                        _distributionRow(star, published.where((r) => r.rating == star).length, published.length),
                    ],
                  ),
                ),
              ] else
                Expanded(child: Align(alignment: Alignment.centerLeft, child: summary)),
            ],
          ),
          Text(
            '${d.reviewCount} review từ người dùng Senpai ơi',
            style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
          ),
        ],
      ),
    );
  }

  static Widget _distributionRow(int star, int count, int total) {
    final caption = SenpaiText.caption.copyWith(color: SenpaiColors.muted);
    return Row(
      spacing: 8,
      children: [
        SizedBox(width: 8, child: Text('$star', style: caption)),
        Expanded(
          child: SenpaiProgressBar(value: total == 0 ? 0 : count / total, color: SenpaiColors.lantern),
        ),
        SizedBox(width: 20, child: Text('$count', style: caption, textAlign: TextAlign.right)),
      ],
    );
  }

  Widget _writeButton(PlaceDetail d) {
    final signedIn = context.read<AuthController>().isSignedIn;
    // Tài khoản staff chỉ xem: khóa nút. Khách vẫn bấm được để sang Đăng nhập.
    final staff = signedIn && !d.canAct;
    if (d.myReviewId != null) {
      return SenpaiButton(
        label: 'Sửa review của bạn',
        icon: Symbols.edit_rounded,
        expand: true,
        onPressed: () => _openForm(reviewId: d.myReviewId),
      );
    }
    return SenpaiButton(
      label: 'Viết review',
      icon: Symbols.rate_review_rounded,
      expand: true,
      onPressed: staff || !d.isActive ? null : () => _openForm(),
    );
  }

  /// Ba ô thao tác (`actionTile`): Lưu, Chỉ đường, Báo đã đóng cửa (n/ngưỡng).
  Widget _actionTiles(PlaceDetail d) {
    final signedIn = context.read<AuthController>().isSignedIn;
    final staff = signedIn && !d.canAct;
    final tiles = [
      _ActionTile(
        icon: d.saved ? Icons.bookmark_rounded : Symbols.bookmark_rounded,
        label: d.saved ? 'Đã lưu' : 'Lưu',
        active: d.saved,
        onTap: staff ? null : _toggleSave,
      ),
      _ActionTile(
        icon: Symbols.directions_rounded,
        label: 'Chỉ đường',
        onTap: () => PlaceDirectionsButton.open(context, d.directionsUrl),
      ),
      if (!d.closed && d.isActive)
        _ActionTile(
          icon: Symbols.block_rounded,
          label: d.reportedClosed ? 'Bạn đã báo đóng cửa (${d.closedProgress})' : 'Báo đã đóng cửa (${d.closedProgress})',
          active: d.reportedClosed,
          onTap: staff || d.reportedClosed ? null : () => _reportClosed(d),
        ),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [for (final t in tiles) Expanded(child: t)],
      ),
    );
  }

  // ---------------------------------------------------------------- review, từ vựng

  List<Widget> _reviews(PlaceController places, PlaceDetail d) {
    final reviews = places.reviewsOf(_id);
    final loading = places.isLoadingReviews(_id);
    final error = places.reviewErrorOf(_id);
    final staff = context.read<AuthController>().isSignedIn && !d.canAct;
    return [
      if (reviews.isEmpty && loading)
        const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (reviews.isEmpty && error != null)
        ErrorView(message: error, onRetry: () => places.loadReviews(_id))
      else if (reviews.isEmpty)
        const EmptyView(text: 'Chưa ai viết review về địa điểm này.', icon: Symbols.rate_review_rounded),
      for (final review in reviews)
        PlaceReviewCard(
          key: ValueKey('review-${review.id}'),
          review: review,
          canAct: !staff,
          onLike: () => _toggleLike(review),
          onReport: () => _report(d, review),
          onEdit: () => _openForm(reviewId: review.id),
          onDelete: () => _deleteReview(review),
        ),
      if (reviews.isNotEmpty && error != null)
        Text(error, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.crit)),
      if (places.hasMoreReviews(_id))
        Center(
          child: SenpaiButton(
            label: loading ? 'Đang tải…' : 'Xem thêm review',
            kind: SenpaiButtonKind.ghost,
            size: SenpaiButtonSize.small,
            onPressed: loading ? null : () => places.loadReviews(_id, more: true),
          ),
        ),
    ];
  }

  List<Widget> _phrases(PlaceController places) {
    final phrases = places.phrasesOf(_id);
    if (phrases == null) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (phrases.isEmpty) {
      return const [EmptyView(text: 'Danh mục này chưa có từ vựng và mẫu câu.', icon: Symbols.translate_rounded)];
    }
    return [for (final phrase in phrases) PlacePhraseTile(phrase: phrase, onSpeak: () => _speak(phrase.japanese))];
  }

  void _selectTab(PlaceController places, int tab) {
    setState(() => _tab = tab);
    if (tab == 1 && places.phrasesOf(_id) == null && !places.isLoadingPhrases(_id)) {
      places.loadPhrases(_id);
    }
  }

  // ---------------------------------------------------------------- thao tác

  /// Khách được đưa sang Đăng nhập; đăng nhập xong thì tải lại địa điểm để có trạng thái của người dùng.
  Future<bool> _signedIn() async {
    if (context.read<AuthController>().isSignedIn) {
      return true;
    }
    if (!await requireSignIn(context) || !mounted) {
      return false;
    }
    await _places.loadPlace(_id);
    return mounted;
  }

  void _showControllerMessage() {
    if (mounted) {
      showMessage(context, _places.takeMessage());
    }
  }

  Future<void> _toggleSave() async {
    if (!await _signedIn()) {
      return;
    }
    await _places.toggleSave(_id);
    _showControllerMessage();
  }

  Future<void> _reportClosed(PlaceDetail d) async {
    if (!await _signedIn() || !mounted) {
      return;
    }
    final current = _places.detailOf(_id) ?? d;
    if (current.reportedClosed) {
      showMessage(context, 'Bạn đã báo địa điểm này rồi.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Báo đã đóng cửa?'),
        content: Text(
          'Bạn chắc “${current.name}” đã đóng cửa? Khi đủ ${current.closedThreshold} người báo, '
          'Moderator sẽ kiểm tra rồi mới gắn nhãn.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Gửi báo cáo')),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await _places.reportClosed(_id);
    _showControllerMessage();
  }

  Future<void> _toggleLike(PlaceReview review) async {
    if (!await _signedIn()) {
      return;
    }
    // Sau khi đăng nhập, review có thể là của chính mình (server không cho tự thích)
    final fresh = _places.reviewsOf(_id).where((r) => r.id == review.id).firstOrNull;
    if (fresh == null || fresh.mine) {
      return;
    }
    await _places.toggleLike(_id, review.id);
    _showControllerMessage();
  }

  Future<void> _report(PlaceDetail d, PlaceReview review) async {
    if (!await _signedIn() || !mounted) {
      return;
    }
    final reasons = (_places.detailOf(_id) ?? d).reportReasons;
    final choice = await showReportDialog(context, reasons: reasons, title: 'Báo cáo review');
    if (choice == null) {
      return;
    }
    await _places.reportReview(_id, review.id, choice.reasonId, choice.note);
    _showControllerMessage();
  }

  Future<void> _speak(String text) async {
    await _places.speak(text);
    _showControllerMessage();
  }

  /// Viết review mới ([reviewId] null) hoặc sửa review của mình.
  Future<void> _openForm({int? reviewId}) async {
    if (!await _signedIn() || !mounted) {
      return;
    }
    final d = _places.detailOf(_id);
    if (d == null) {
      return;
    }
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewFormScreen(
          placeId: reviewId == null ? d.id : null,
          reviewId: reviewId ?? d.myReviewId,
          placeName: d.name,
        ),
      ),
    );
    if (saved == true && mounted) {
      showMessage(context, context.read<ReviewController>().takeMessage());
      await _afterReviewChanged();
    }
  }

  Future<void> _deleteReview(PlaceReview review) async {
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
    final reviews = context.read<ReviewController>();
    final deleted = await reviews.deleteReview(review.id);
    if (!mounted) {
      return;
    }
    showMessage(context, reviews.takeMessage());
    if (deleted) {
      await _afterReviewChanged();
    }
  }

  /// Số review, số sao, review của mình đã đổi: tải lại địa điểm và ghim trên bản đồ.
  Future<void> _afterReviewChanged() async {
    await _places.loadPlace(_id);
    await _places.refreshMap();
  }
}

/// `actionTile` của thiết kế: ô trắng viền line bo 14, p[10,6], icon 22 trên, nhãn Label/S căn giữa. [active] tô
/// brand (đã lưu, đã báo); [onTap] null thì mờ.
class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap, this.active = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = active ? SenpaiColors.brandText : (enabled ? SenpaiColors.ink : SenpaiColors.muted);
    return Semantics(
      button: true,
      enabled: enabled,
      child: SenpaiCard(
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        color: active ? SenpaiColors.brandSoft : SenpaiColors.surface,
        borderColor: active ? SenpaiColors.brandSoft : SenpaiColors.line,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 4,
          children: [
            Icon(icon, size: 22, color: active ? SenpaiColors.brand : color),
            Text(label, textAlign: TextAlign.center, style: SenpaiText.labelS.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

/// Ảnh đầu trang: một ảnh lớn 160 bo 18 và hai ảnh nhỏ 110 × 76 bo 14 (ảnh cuối có "+n" khi còn ảnh). Ảnh lấy từ
/// các review đã tải; chưa có ảnh nào thì là tranh minh hoạ Cover theo [seed].
class _PhotoHeader extends StatelessWidget {
  const _PhotoHeader({required this.images, required this.seed});

  final List<MediaItem> images;
  final Object seed;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return CoverArt(scene: CoverScene.forSeed(seed), width: double.infinity, height: 160, radius: 18);
    }
    Widget photo(MediaItem image, double height, double radius) => GestureDetector(
      onTap: () => showPlacePhoto(context, image),
      child: MediaImage(url: image.url, width: double.infinity, height: height, radius: radius),
    );
    if (images.length == 1) {
      return photo(images.first, 160, 18);
    }
    if (images.length == 2) {
      return Row(
        spacing: 8,
        children: [Expanded(child: photo(images[0], 160, 18)), Expanded(child: photo(images[1], 160, 14))],
      );
    }
    final more = images.length - 3;
    return Row(
      spacing: 8,
      children: [
        Expanded(child: photo(images[0], 160, 18)),
        SizedBox(
          width: 110,
          child: Column(
            spacing: 8,
            children: [
              photo(images[1], 76, 14),
              Stack(
                children: [
                  photo(images[2], 76, 14),
                  if (more > 0)
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: IgnorePointer(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: SenpaiColors.ink.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text('+$more', style: SenpaiText.labelS.copyWith(color: SenpaiColors.onBrand)),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
