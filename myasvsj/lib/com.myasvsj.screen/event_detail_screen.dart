import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/event_controller.dart';
import 'package:myasvsj/com.myasvsj.model/event_detail.dart';
import 'package:myasvsj/com.myasvsj.model/event_review.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/event_cover.dart';
import 'package:myasvsj/com.myasvsj.screen/event_info_line.dart';
import 'package:myasvsj/com.myasvsj.screen/event_photo_viewer.dart';
import 'package:myasvsj/com.myasvsj.screen/event_review_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/event_review_tile.dart';
import 'package:myasvsj/com.myasvsj.screen/event_stars.dart';
import 'package:myasvsj/com.myasvsj.screen/event_text.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/media_image.dart';
import 'package:myasvsj/com.myasvsj.screen/report_dialog.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/sign_in_gate.dart';

/// Chi tiết một sự kiện (màn 20 của thiết kế, `GET /api/events/{id}`): ảnh bìa tràn ngang, nhãn trạng thái, tên
/// Display/L, thẻ thông tin (thời gian, nơi tổ chức, chi phí), nút "Chỉ đường" (Google Maps), album ảnh từ review,
/// mẹo từ Moderator, thẻ điểm trung bình, nút viết / sửa review và các review với Thích / Báo cáo / Sửa / Xóa.
class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final int eventId;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  /// Người đang đăng nhập lúc tải; đổi (vừa đăng nhập / đăng xuất) thì tải lại vì quyền và dấu "Thích" đổi theo.
  int? _userId;

  @override
  void initState() {
    super.initState();
    _userId = context.read<AuthController>().currentUser?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final events = context.read<EventController>();
    await events.loadEvent(widget.eventId);
    if (mounted) {
      showMessage(context, events.takeMessage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventController>();
    final userId = context.watch<AuthController>().currentUser?.id;
    if (userId != _userId) {
      _userId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _load();
        }
      });
    }
    final detail = events.detailOf(widget.eventId);
    return Scaffold(
      appBar: SenpaiAppBar(title: detail?.event.title ?? 'Sự kiện'),
      body: _body(events, detail),
    );
  }

  Widget _body(EventController events, EventDetail? detail) {
    if (detail == null) {
      final error = events.detailErrorOf(widget.eventId);
      if (error != null) {
        return ErrorView(message: error, onRetry: _load);
      }
      return const LoadingView();
    }
    final event = detail.event;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          EventCover(event: event, height: 210, showState: false),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 16,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: SenpaiBadge(event.stateLabel, tone: eventStateTone(event), icon: eventStateIcon(event)),
                ),
                Text(event.title, style: SenpaiText.displayL.copyWith(color: SenpaiColors.ink)),
                _infoCard(detail),
                if (detail.event.directionsUri case final uri?)
                  SenpaiButton(
                    label: 'Chỉ đường',
                    kind: SenpaiButtonKind.secondary,
                    icon: Symbols.directions_rounded,
                    expand: true,
                    onPressed: () => _openUri(uri),
                  ),
                if (detail.albumCount > 0 && detail.album.isNotEmpty) ..._album(detail),
                if (detail.tip != null) _tip(detail.tip!),
                _ratingCard(detail),
                ?_writeButton(detail),
                SectionHead('Review (${detail.publishedCount})'),
                if (detail.reviews.isEmpty)
                  Text(
                    'Chưa ai viết review về sự kiện này.',
                    style: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted),
                  ),
                for (final review in detail.reviews)
                  EventReviewTile(
                    review: review,
                    // Thành viên thích / báo cáo review đã đăng của người khác; khách thấy nút, bấm thì đăng nhập
                    canAct: review.isPublished && !review.mine && (detail.member || !detail.signedIn),
                    canEdit: review.status != EventReview.hidden && review.year == event.reviewYear,
                    liking: events.isLiking(review.id),
                    onLike: () => _like(review),
                    onReport: () => _report(detail, review),
                    onEdit: _openForm,
                    onDelete: () => _delete(review),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Thẻ thông tin r16: thời gian, nơi tổ chức (tối đa 3 dòng), chi phí; thêm dòng phụ khi chưa gắn vị trí.
  Widget _infoCard(EventDetail detail) {
    final event = detail.event;
    return SenpaiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          EventInfoLine(icon: Symbols.event_rounded, text: eventDateRange(event), maxLines: 2),
          EventInfoLine(icon: Symbols.location_on_rounded, text: event.locationName, maxLines: 3),
          EventInfoLine(
            icon: Symbols.payments_rounded,
            text: event.costNote.isEmpty ? 'Chưa rõ' : event.costNote,
            maxLines: 2,
          ),
          if (event.directionsUri == null)
            const EventInfoLine(
              icon: Symbols.location_off_rounded,
              text: 'Sự kiện chưa gắn vị trí trên bản đồ.',
              maxLines: 2,
              color: SenpaiColors.muted,
            ),
        ],
      ),
    );
  }

  /// "Album từ review (n ảnh)" + "Xem tất cả", rồi tối đa 3 ảnh vuông 110 bo 14; ảnh thứ ba có nhãn "+k" khi
  /// album còn nhiều ảnh hơn.
  List<Widget> _album(EventDetail detail) {
    final photos = [for (final p in detail.album) (url: p.url, caption: '${p.authorName} · năm ${p.year}')];
    final shown = math.min(3, detail.album.length);
    final more = detail.albumCount - shown;
    return [
      _AlbumHead(
        title: 'Album từ review (${detail.albumCount} ảnh)',
        onAll: () => showEventPhotos(context, photos: photos),
      ),
      LayoutBuilder(
        builder: (context, box) {
          final side = math.min(110.0, (box.maxWidth - 16) / 3);
          return Row(
            spacing: 8,
            children: [
              for (var i = 0; i < shown; i++)
                _AlbumThumb(
                  url: detail.album[i].url,
                  side: side,
                  more: i == shown - 1 && more > 0 ? more : 0,
                  onTap: () => showEventPhotos(context, photos: photos, initialIndex: i),
                ),
            ],
          );
        },
      ),
    ];
  }

  /// Hộp "Mẹo từ Moderator": nền lantern-soft bo 16, icon tips_and_updates, chữ Body/S lantern-text (đầu câu đậm).
  Widget _tip(String tip) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: SenpaiColors.lanternSoft, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          const Icon(Symbols.tips_and_updates_rounded, size: 22, color: SenpaiColors.lanternText),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Mẹo từ Moderator', style: TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: ': $tip'),
                ],
              ),
              style: SenpaiText.bodyS.copyWith(color: SenpaiColors.lanternText),
            ),
          ),
        ],
      ),
    );
  }

  /// Thẻ điểm r18: số trung bình Display/XL, 5 sao 18 và "n review, gồm cả các năm trước".
  Widget _ratingCard(EventDetail detail) {
    final event = detail.event;
    final avg = event.avgRating;
    final rated = event.reviewCount > 0 && avg != null;
    return SenpaiCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Row(
        spacing: 14,
        children: [
          if (rated) Text(avg.toStringAsFixed(1), style: SenpaiText.displayXL.copyWith(color: SenpaiColors.ink)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                EventStars(rating: rated ? avg : 0, size: 18),
                Text(
                  rated ? '${event.reviewCount} review, gồm cả các năm trước' : 'Chưa có review.',
                  style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "Viết review năm 2026" / "Sửa review năm 2026", hoặc lý do chưa viết được; tài khoản staff: không có gì.
  Widget? _writeButton(EventDetail detail) {
    final event = detail.event;
    if (!event.canReview) {
      return const SenpaiNote(
        'Viết review được khi sự kiện bắt đầu.',
        icon: Symbols.schedule_rounded,
        tone: SenpaiTone.neutral,
      );
    }
    if (detail.signedIn && !detail.member) {
      return null; // tài khoản staff không viết review
    }
    final editing = detail.myReviewId != null;
    return SenpaiButton(
      label: editing ? 'Sửa review năm ${event.reviewYear}' : 'Viết review năm ${event.reviewYear}',
      icon: editing ? Symbols.edit_rounded : Symbols.rate_review_rounded,
      expand: true,
      onPressed: _openForm,
    );
  }

  // ---------------------------------------------------------------- Thao tác

  Future<void> _openForm() async {
    if (!await requireSignIn(context) || !mounted) {
      return;
    }
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EventReviewFormScreen(eventId: widget.eventId)),
    );
    if (saved == true && mounted) {
      showMessage(context, context.read<EventController>().takeMessage());
    }
  }

  /// Khách được đưa sang đăng nhập; đăng nhập xong trang tự tải lại dấu "Thích" thật của tài khoản, người dùng
  /// bấm lại nếu vẫn muốn thích (không đảo dấu thích theo dữ liệu cũ của khách).
  Future<void> _like(EventReview review) async {
    if (!context.read<AuthController>().isSignedIn) {
      await requireSignIn(context);
      return;
    }
    final events = context.read<EventController>();
    await events.toggleLike(widget.eventId, review.id);
    if (mounted) {
      showMessage(context, events.takeMessage());
    }
  }

  Future<void> _report(EventDetail detail, EventReview review) async {
    if (!await requireSignIn(context) || !mounted) {
      return;
    }
    final choice = await showReportDialog(context, reasons: detail.reportReasons, title: 'Báo cáo review');
    if (choice == null || !mounted) {
      return;
    }
    final events = context.read<EventController>();
    await events.reportReview(widget.eventId, review.id, reasonId: choice.reasonId, note: choice.note);
    if (mounted) {
      showMessage(context, events.takeMessage());
    }
  }

  Future<void> _delete(EventReview review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa review?'),
        content: Text(
          'Ảnh, video và điểm của review cũng bị xóa. Không thể hoàn tác.',
          style: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted),
        ),
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
    final events = context.read<EventController>();
    await events.deleteReview(widget.eventId, review.id);
    if (mounted) {
      showMessage(context, events.takeMessage());
    }
  }

  Future<void> _openUri(Uri uri) async {
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Máy không có trình duyệt / Google Maps: báo bên dưới
    }
    if (!opened && mounted) {
      showMessage(context, 'Không mở được Google Maps.');
    }
  }
}

/// `sectionHead('Album từ review (n ảnh)', 'Xem tất cả', 'photo_library')`: như [SectionHead] nhưng link không có
/// lề trong, để tiêu đề dài vẫn vừa một dòng như thiết kế; vùng bấm của link vẫn cao 32.
class _AlbumHead extends StatelessWidget {
  const _AlbumHead({required this.title, required this.onAll});

  final String title;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        const Icon(Symbols.photo_library_rounded, size: 20, color: SenpaiColors.brand),
        Expanded(child: Text(title, style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink))),
        Semantics(
          button: true,
          child: InkWell(
            onTap: onAll,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 32),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: [
                  Text('Xem tất cả', style: SenpaiText.labelM.copyWith(color: SenpaiColors.brandText)),
                  const Icon(Symbols.chevron_right_rounded, size: 18, color: SenpaiColors.brandText),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Một ảnh vuông của album, bo 14; [more] > 0 thì phủ nhãn "+more" (nền ink 75%) ở góc dưới phải.
class _AlbumThumb extends StatelessWidget {
  const _AlbumThumb({required this.url, required this.side, required this.more, required this.onTap});

  final String url;
  final double side;
  final int more;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: more > 0 ? 'Xem thêm $more ảnh' : 'Xem ảnh',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox.square(
          dimension: side,
          child: Stack(
            fit: StackFit.expand,
            children: [
              MediaImage(url: url, width: side, height: side, radius: 14),
              if (more > 0)
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: ShapeDecoration(
                      color: SenpaiColors.ink.withValues(alpha: 0.75),
                      shape: const StadiumBorder(),
                    ),
                    child: Text('+$more', style: SenpaiText.labelS.copyWith(color: SenpaiColors.onBrand)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
