import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/guide_controller.dart';
import 'package:myasvsj/com.myasvsj.model/guide.dart';
import 'package:myasvsj/com.myasvsj.model/guide_preparation.dart';
import 'package:myasvsj/com.myasvsj.model/guide_task.dart';
import 'package:myasvsj/com.myasvsj.model/guide_viewer.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_content.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/media_image.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/sign_in_gate.dart';

/// Chi tiết một cẩm nang (màn 23 của thiết kế, `GET /api/guides/{id}`).
///
/// Đầu trang (cả hai tab): chủ đề Overline brand, tiêu đề Display/L, "Ngày tạo · người tạo", hàng nút của người xem
/// (`…/viewer`): Lưu / Đã lưu và Đánh dấu đã xong, hoặc "Tiến độ: x/y việc" với cẩm nang có checklist.
/// Tab "Xem chi tiết": các mục có ảnh, nguồn tham khảo. Tab "Hướng dẫn chuẩn bị" (checklist `…/preparation`, khi
/// cẩm nang có checklist): thẻ tiến độ màu brand, danh sách việc có ô tick, "Việc tiếp theo". Khách tick được
/// checklist nhưng không lưu (màn hình nói rõ).
class GuideDetailScreen extends StatefulWidget {
  const GuideDetailScreen({super.key, required this.guideId, this.openChecklist = false});

  final int guideId;

  /// Mở sẵn tab "Hướng dẫn chuẩn bị" (như `?tab=preparation` của web), ví dụ từ "Cẩm nang của tôi".
  final bool openChecklist;

  @override
  State<GuideDetailScreen> createState() => _GuideDetailScreenState();
}

class _GuideDetailScreenState extends State<GuideDetailScreen> {
  /// Người đang đăng nhập lúc tải; đổi (vừa đăng nhập / đăng xuất) thì tải lại trạng thái và dấu tick.
  int? _userId;

  static final RegExp _numbered = RegExp(r'^\d+[.)]\s');

  @override
  void initState() {
    super.initState();
    _userId = context.read<AuthController>().currentUser?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final guides = context.read<GuideController>();
    await guides.loadGuide(widget.guideId);
    if (mounted) {
      showMessage(context, guides.takeMessage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final guides = context.watch<GuideController>();
    final userId = context.watch<AuthController>().currentUser?.id;
    if (userId != _userId) {
      _userId = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _load();
        }
      });
    }
    final guide = guides.guideOf(widget.guideId);
    if (guide == null) {
      final error = guides.guideErrorOf(widget.guideId);
      return Scaffold(
        appBar: const SenpaiAppBar(title: 'Cẩm nang'),
        body: error != null ? ErrorView(message: error, onRetry: _load) : const LoadingView(),
      );
    }
    final viewer = guides.viewerOf(widget.guideId);
    if (!guide.preparationEnabled) {
      return Scaffold(
        appBar: const SenpaiAppBar(title: 'Cẩm nang'),
        body: _page([..._header(guides, guide, viewer, showNext: true), ..._details(guide)]),
      );
    }
    return DefaultTabController(
      length: 2,
      initialIndex: widget.openChecklist ? 1 : 0,
      child: Scaffold(
        appBar: const SenpaiAppBar(
          title: 'Cẩm nang',
          bottom: TabBar(
            tabs: [
              Tab(text: 'Xem chi tiết'),
              Tab(text: 'Hướng dẫn chuẩn bị'),
            ],
          ),
        ),
        // Tiêu đề và hàng nút ở đầu cả hai tab, nên "Lưu" và "Tiến độ" luôn thấy (như web)
        body: TabBarView(
          children: [
            _page([..._header(guides, guide, viewer, showNext: true), ..._details(guide)]),
            _page([..._header(guides, guide, viewer, showNext: false), ..._checklist(guides, guide, viewer)]),
          ],
        ),
      ),
    );
  }

  /// Một tab: danh sách cuộn, lề [16,16,24,16], các khối cách nhau 16, kéo xuống để tải lại.
  Widget _page(List<Widget> blocks) => RefreshIndicator(
    onRefresh: _load,
    child: ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: blocks.length,
      separatorBuilder: (_, _) => const SizedBox(height: 16),
      itemBuilder: (_, i) => blocks[i],
    ),
  );

  // ---------------------------------------------------------------- Đầu trang và hàng nút

  /// Tiêu đề + hàng nút; [showNext] thêm hộp "Việc tiếp theo" ngay dưới hàng nút (tab checklist đặt hộp này ở
  /// cuối danh sách việc).
  List<Widget> _header(GuideController guides, Guide guide, GuideViewer? viewer, {required bool showNext}) {
    final created = guide.createdAt;
    final meta = [
      if (created != null) 'Ngày tạo: ${formatDate(created)}',
      if (guide.creatorName != null && guide.creatorName!.isNotEmpty) guide.creatorName!,
    ].join(' · ');
    final next = _nextTask(viewer);
    return [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          if (guide.topicName != null)
            Text(guide.topicName!.toUpperCase(), style: SenpaiText.overline.copyWith(color: SenpaiColors.brand)),
          Text(guide.title, style: SenpaiText.displayL.copyWith(color: SenpaiColors.ink)),
          if (meta.isNotEmpty) Text(meta, style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
        ],
      ),
      if (viewer != null && !(viewer.signedIn && !viewer.member)) _memberActions(guides, guide, viewer),
      if (showNext && next != null) _nextNote(next),
    ];
  }

  /// Việc tiếp theo của checklist (thành viên, chưa xong); null khi không có.
  String? _nextTask(GuideViewer? viewer) {
    final progress = viewer?.progress;
    if (viewer == null || !viewer.signedIn || progress == null || !progress.checklist || progress.done) {
      return null;
    }
    return progress.nextTask;
  }

  Widget _nextNote(String task) =>
      SenpaiNote('Việc tiếp theo: $task', icon: Symbols.arrow_forward_rounded, tone: SenpaiTone.brand);

  /// Khách: lời mời đăng nhập và các nút (bấm thì đăng nhập). Thành viên: "Lưu" (Soft khi đã lưu) và "Đánh dấu đã
  /// xong", hoặc "Tiến độ" với cẩm nang có checklist (bấm mở tab checklist). Tài khoản staff: không gọi tới đây.
  Widget _memberActions(GuideController guides, Guide guide, GuideViewer viewer) {
    final progress = viewer.progress;
    final busy = guides.isBusy(guide.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        if (!viewer.signedIn)
          Text(
            'Đăng nhập để lưu cẩm nang và theo dõi tiến độ.',
            style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
          ),
        Row(
          spacing: 10,
          children: [
            SenpaiButton(
              label: viewer.saved ? 'Đã lưu' : 'Lưu',
              icon: viewer.saved ? Icons.bookmark_rounded : Symbols.bookmark_rounded,
              kind: viewer.saved ? SenpaiButtonKind.soft : SenpaiButtonKind.secondary,
              size: SenpaiButtonSize.medium,
              onPressed: busy ? null : () => _memberAction(guides.toggleSave),
            ),
            Expanded(
              child: progress.checklist
                  ? Builder(
                      builder: (tabContext) => SenpaiButton(
                        label: progress.done
                            ? 'Đã xong · ${progress.tasksTotal}/${progress.tasksTotal} việc'
                            : 'Tiến độ: ${progress.tasksDone}/${progress.tasksTotal} việc',
                        icon: Symbols.checklist_rounded,
                        kind: progress.done ? SenpaiButtonKind.soft : SenpaiButtonKind.secondary,
                        size: SenpaiButtonSize.medium,
                        expand: true,
                        onPressed: () => DefaultTabController.maybeOf(tabContext)?.animateTo(1),
                      ),
                    )
                  : SenpaiButton(
                      label: progress.done ? 'Đã xong' : 'Đánh dấu đã xong',
                      icon: Symbols.task_alt_rounded,
                      kind: progress.done ? SenpaiButtonKind.soft : SenpaiButtonKind.secondary,
                      size: SenpaiButtonSize.medium,
                      expand: true,
                      onPressed: busy ? null : () => _memberAction(guides.toggleDone),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  /// "Lưu" / "Đánh dấu đã xong" cần tài khoản: khách được đưa sang đăng nhập; đăng nhập xong trang tự tải lại
  /// trạng thái thật của tài khoản, người dùng bấm lại nếu vẫn muốn.
  Future<void> _memberAction(Future<void> Function(int id) action) async {
    if (!context.read<AuthController>().isSignedIn) {
      await requireSignIn(context);
      return;
    }
    final guides = context.read<GuideController>();
    await action(widget.guideId);
    if (mounted) {
      showMessage(context, guides.takeMessage());
    }
  }

  // ---------------------------------------------------------------- Tab "Xem chi tiết"

  List<Widget> _details(Guide guide) {
    final cover = guide.coverImageUrl;
    final source = guide.sourceUrl;
    final body = SenpaiText.bodyM.copyWith(color: SenpaiColors.ink);
    return [
      if (guide.summary.isNotEmpty) Text(guide.summary, style: body),
      if (cover != null && cover.isNotEmpty) MediaImage(url: cover, height: 180, width: double.infinity, radius: 16),
      if (guide.stageName != null || source != null)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            if (guide.stageName != null)
              Row(
                spacing: 8,
                children: [
                  const Icon(Symbols.flag_rounded, size: 18, color: SenpaiColors.muted),
                  Expanded(
                    child: Text(
                      'Giai đoạn: ${guide.stageName}',
                      style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
                    ),
                  ),
                ],
              ),
            if (source != null) _link('Đường dẫn gốc', source),
          ],
        ),
      for (var i = 0; i < guide.sections.length; i++)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            Text(
              _numbered.hasMatch(guide.sections[i].heading)
                  ? guide.sections[i].heading
                  : '${i + 1}. ${guide.sections[i].heading}',
              style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink),
            ),
            GuideContent(text: guide.sections[i].content, onOpenLink: _openUrl),
            if (guide.sections[i].imageUrl != null)
              MediaImage(url: guide.sections[i].imageUrl!, width: double.infinity, fit: BoxFit.fitWidth, radius: 12),
            if (guide.sections[i].referenceUrl != null)
              Align(
                alignment: Alignment.centerLeft,
                child: _link('Tài liệu tham khảo', guide.sections[i].referenceUrl!),
              ),
          ],
        ),
      if (guide.sections.isEmpty)
        Text('Nội dung hướng dẫn đang được cập nhật.', style: body.copyWith(color: SenpaiColors.muted)),
    ];
  }

  Widget _link(String label, String url) =>
      LinkText(label, icon: Symbols.open_in_new_rounded, onTap: () => _openUrl(url));

  // ---------------------------------------------------------------- Tab "Hướng dẫn chuẩn bị"

  List<Widget> _checklist(GuideController guides, Guide guide, GuideViewer? viewer) {
    final preparation = guides.preparationOf(guide.id);
    final error = guides.preparationErrorOf(guide.id);
    if (preparation == null) {
      return [
        if (error != null)
          ErrorView(message: error, onRetry: () => guides.loadPreparation(guide.id))
        else
          const SizedBox(height: 120, child: LoadingView()),
      ];
    }
    final ticking = guides.isTicking(guide.id);
    final next = _nextTask(viewer);
    return [
      _ProgressCard(preparation: preparation),
      if (!preparation.signedIn) _guestNote(),
      if (preparation.tasks.isEmpty)
        Text(
          'Chưa có công việc trong danh sách chuẩn bị.',
          style: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted),
        )
      else
        SenpaiGroup(
          children: [
            for (final task in preparation.tasks)
              _TaskTile(task: task, onChanged: ticking ? null : (value) => _tick(guides, task.id, value)),
          ],
        ),
      if (next != null) _nextNote(next),
    ];
  }

  /// Hộp lantern cho khách: dấu tick không được lưu, nút "Đăng nhập".
  Widget _guestNote() {
    return SenpaiNote(
      '',
      icon: Symbols.info_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bạn chưa đăng nhập: dấu tick chỉ để tự theo dõi và sẽ mất khi rời trang, không được lưu. '
            'Đăng nhập để tick công việc và lưu tiến độ riêng của bạn.',
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: SenpaiColors.lanternText,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => requireSignIn(context),
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }

  Future<void> _tick(GuideController guides, int taskId, bool completed) async {
    await guides.toggleTask(widget.guideId, taskId, completed);
    if (mounted) {
      showMessage(context, guides.takeMessage());
    }
  }

  /// Mở link http / https bằng trình duyệt; link khác bị bỏ qua.
  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'http' || uri.scheme == 'https') || uri.host.isEmpty) {
      showMessage(context, 'Link không hợp lệ.');
      return;
    }
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Máy không có trình duyệt: báo bên dưới
    }
    if (!opened && mounted) {
      showMessage(context, 'Không mở được link.');
    }
  }
}

/// Thẻ tiến độ màu brand bo 20: "HƯỚNG DẪN CHUẨN BỊ", "x/y công việc đã hoàn thành" Title/M + "%" Display/M, thanh
/// tiến độ trắng trên nền brand-strong cao 10; logo hoa mờ 15% ở góc phải.
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.preparation});

  final GuidePreparation preparation;

  @override
  Widget build(BuildContext context) {
    const onBrand = SenpaiColors.onBrand;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: SenpaiColors.brand, borderRadius: BorderRadius.circular(20)),
      child: Stack(
        children: [
          const Positioned(right: -20, top: -30, child: Opacity(opacity: 0.15, child: SenpaiLogo(size: 88))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                Text('HƯỚNG DẪN CHUẨN BỊ', style: SenpaiText.overline.copyWith(color: onBrand)),
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Text(
                        '${preparation.completed}/${preparation.total} công việc đã hoàn thành',
                        style: SenpaiText.titleM.copyWith(color: onBrand),
                      ),
                    ),
                    Text('${preparation.percent}%', style: SenpaiText.displayM.copyWith(color: onBrand)),
                  ],
                ),
                Semantics(
                  label: 'Tiến độ chuẩn bị',
                  value: '${preparation.percent}%',
                  child: SenpaiProgressBar(
                    value: preparation.percent / 100,
                    height: 10,
                    color: SenpaiColors.surface,
                    trackColor: SenpaiColors.brandStrong,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// `taskRow` của thiết kế: ô tick 22 bo 6 ở đầu, tên việc Title/S (đã xong: muted gạch ngang), ghi chú Body/S muted.
/// Vẫn là [CheckboxListTile] nên bấm cả dòng để tick.
class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task, required this.onChanged});

  final GuideTask task;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = task.completed;
    // Ô tick gọn 24 × 24 (thay vì vùng 40) để thẳng lề trái như thiết kế; cả dòng vẫn bấm được
    return Theme(
      data: theme.copyWith(
        checkboxTheme: theme.checkboxTheme.copyWith(visualDensity: const VisualDensity(horizontal: -4, vertical: -4)),
      ),
      child: CheckboxListTile(
        value: done,
        onChanged: onChanged == null ? null : (value) => onChanged!(value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        checkboxScaleFactor: 22 / 18,
        minVerticalPadding: 12,
        minTileHeight: 0,
        minLeadingWidth: 22,
        horizontalTitleGap: 12,
        titleAlignment: ListTileTitleAlignment.top,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          task.title,
          style: SenpaiText.titleS.copyWith(
            color: done ? SenpaiColors.muted : SenpaiColors.ink,
            decoration: done ? TextDecoration.lineThrough : null,
            decorationColor: SenpaiColors.muted,
          ),
        ),
        subtitle: task.notes.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(task.notes, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
              ),
      ),
    );
  }
}
