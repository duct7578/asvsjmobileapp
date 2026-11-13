import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/guide_controller.dart';
import 'package:myasvsj/com.myasvsj.model/guide_activity.dart';
import 'package:myasvsj/com.myasvsj.model/guide_my_progress.dart';
import 'package:myasvsj/com.myasvsj.model/guide_stage_progress.dart';
import 'package:myasvsj/com.myasvsj.screen/auth_required_view.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/empty_view.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// "Cẩm nang của tôi" (màn 24 của thiết kế, `GET /api/me/guides/progress`, chỉ thành viên): hộp tiến độ 4 giai
/// đoạn (badge "Giai đoạn của bạn"), thẻ checklist đang làm dở, nhóm cẩm nang vừa xong, nút "Mở Cẩm nang".
/// Bấm một cẩm nang để mở chi tiết; quay về thì tải lại vì tiến độ có thể đã đổi. Khách thấy lời mời đăng nhập.
class MyGuidesScreen extends StatefulWidget {
  const MyGuidesScreen({super.key});

  @override
  State<MyGuidesScreen> createState() => _MyGuidesScreenState();
}

class _MyGuidesScreenState extends State<MyGuidesScreen> {
  /// Người đã tải tiến độ cho; đổi tài khoản thì tải lại.
  int? _loadedFor;

  /// Đang tải lần đầu cho tài khoản này: chưa hiện dữ liệu cũ (của lần mở trước hay của tài khoản khác).
  bool _firstLoad = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final guides = context.watch<GuideController>();
    final userId = auth.currentUser?.id;
    if (userId != null && userId != _loadedFor) {
      _loadedFor = userId;
      _firstLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadFirst(guides));
    }
    return Scaffold(
      appBar: const SenpaiAppBar(title: 'Cẩm nang của tôi'),
      body: userId == null
          ? const AuthRequiredView(text: 'Đăng nhập để theo dõi tiến độ cẩm nang của bạn qua từng giai đoạn.')
          : _body(guides),
    );
  }

  Future<void> _loadFirst(GuideController guides) async {
    if (!mounted) {
      return;
    }
    await guides.loadMyProgress();
    if (mounted) {
      setState(() => _firstLoad = false);
    }
  }

  Widget _body(GuideController guides) {
    final data = guides.myProgress;
    if (_firstLoad || (guides.isLoadingMy && data == null)) {
      return const LoadingView();
    }
    if (guides.myError != null) {
      return ErrorView(message: guides.myError!, onRetry: guides.loadMyProgress);
    }
    if (data == null) {
      return const LoadingView();
    }
    final children = <Widget>[
      Text(
        'Cẩm nang có danh sách chuẩn bị xong khi bạn đánh dấu hết các việc; cẩm nang khác xong khi bạn bấm '
        '“Đánh dấu đã xong”.',
        style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
      ),
      if (data.stages.isNotEmpty) SenpaiGroup(children: [for (final stage in data.stages) _stageRow(stage)]),
      ..._lists(data),
      SenpaiButton(
        label: 'Mở Cẩm nang',
        kind: SenpaiButtonKind.secondary,
        icon: Symbols.menu_book_rounded,
        expand: true,
        onPressed: () => _openList(null),
      ),
    ];
    return RefreshIndicator(
      onRefresh: guides.loadMyProgress,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }

  /// Một giai đoạn: tên Title/S (+ badge "Giai đoạn của bạn"), "đã xong/tổng" Label/S bên phải, thanh tiến độ
  /// (xanh ok khi xong hết). Bấm mở Cẩm nang lọc theo giai đoạn đó.
  Widget _stageRow(GuideStageProgress stage) {
    final complete = stage.total > 0 && stage.done >= stage.total;
    return InkWell(
      onTap: () => _openList(stage.code),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        stage.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink),
                      ),
                      if (stage.current) const SenpaiBadge('Giai đoạn của bạn', icon: Symbols.flag_rounded),
                    ],
                  ),
                ),
                Text(
                  stage.total == 0 ? 'Chưa có' : '${stage.done}/${stage.total}',
                  style: SenpaiText.labelS.copyWith(color: SenpaiColors.muted),
                ),
              ],
            ),
            _Progress(
              value: stage.ratio,
              color: complete ? SenpaiColors.ok : SenpaiColors.brand,
              label: 'Tiến độ ${stage.title}',
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _lists(GuideMyProgress data) {
    if (!data.hasActivity) {
      return const [
        EmptyView(
          text: 'Bạn chưa bắt đầu cẩm nang nào. Mở Cẩm nang để xem việc cần làm ở từng giai đoạn.',
          icon: Symbols.checklist_rounded,
        ),
      ];
    }
    return [
      if (data.inProgress.isNotEmpty) ...[
        const SectionHead('Đang làm dở'),
        for (final g in data.inProgress) _inProgressCard(g),
      ],
      if (data.recentlyDone.isNotEmpty) ...[
        const SectionHead('Đã xong gần đây'),
        SenpaiGroup(
          children: [
            for (final g in data.recentlyDone)
              SenpaiListRow(
                leading: const IconTile(Symbols.check_circle_rounded, tone: SenpaiTone.ok, size: 36, radius: 18),
                title: g.title,
                subtitle: [
                  if (g.stageTitle != null) g.stageTitle!,
                  if (g.at != null) 'Xong ngày ${formatDate(g.at!)}',
                ].join(' · '),
                showChevron: false,
                onTap: () => _openGuide(g),
              ),
          ],
        ),
      ],
    ];
  }

  /// Thẻ checklist đang làm dở bo 18: tên Title/S, giai đoạn Caption, thanh tiến độ, "x/y việc · Tiếp theo: …".
  Widget _inProgressCard(GuideActivity g) {
    return SenpaiCard(
      radius: 18,
      onTap: () => _openGuide(g, checklist: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(
            g.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink),
          ),
          if (g.stageTitle != null)
            Text(
              g.stageTitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
            ),
          _Progress(value: g.percent / 100, color: SenpaiColors.brand, label: 'Tiến độ ${g.title}'),
          Text(
            '${g.tasksDone}/${g.tasksTotal} việc${g.nextTask != null ? ' · Tiếp theo: ${g.nextTask}' : ''}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
          ),
        ],
      ),
    );
  }

  Future<void> _openGuide(GuideActivity guide, {bool checklist = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => GuideDetailScreen(guideId: guide.id, openChecklist: checklist),
      ),
    );
    if (mounted) {
      context.read<GuideController>().loadMyProgress();
    }
  }

  Future<void> _openList(String? stage) async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => GuideListScreen(stage: stage)));
    if (mounted) {
      context.read<GuideController>().loadMyProgress();
    }
  }
}

/// `progress(pct)` của thiết kế: thanh bo tròn cao 8 trên nền surface-2; 0% vẫn hiện chấm tròn đầu thanh như
/// thiết kế. Trình đọc màn hình đọc [label] và phần trăm.
class _Progress extends StatelessWidget {
  const _Progress({required this.value, required this.color, required this.label});

  final double value;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return Semantics(
      label: label,
      value: '${(v * 100).round()}%',
      excludeSemantics: true,
      // Giá trị rất nhỏ: SenpaiProgressBar vẽ thanh tối thiểu bằng chiều cao (chấm tròn)
      child: SenpaiProgressBar(value: v == 0 ? 0.0001 : v, color: color),
    );
  }
}
