import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/profile_controller.dart';
import 'package:myasvsj/com.myasvsj.model/point_line.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/empty_view.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/link_router.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_points.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_sign_in_prompt.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_user_watcher.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// "Lịch sử điểm" (UC-U10, màn 36 của thiết kế): thẻ tổng điểm nền ink, rồi các lần cộng / trừ điểm nhóm theo
/// tháng, mới nhất trước, 20 dòng một trang, cuộn tới cuối để tải thêm. Nội dung còn xem được thì bấm vào để mở.
class PointHistoryScreen extends StatefulWidget {
  const PointHistoryScreen({super.key});

  @override
  State<PointHistoryScreen> createState() => _PointHistoryScreenState();
}

class _PointHistoryScreenState extends State<PointHistoryScreen> with ProfileUserWatcher {
  @override
  void onUserChanged(int? userId) {
    if (userId != null) {
      context.read<ProfileController>().loadPoints();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    watchUser(user?.id);
    return Scaffold(
      appBar: const SenpaiAppBar(title: 'Lịch sử điểm'),
      body: user == null
          ? const ProfileSignInPrompt(text: 'Đăng nhập để xem lịch sử điểm của bạn.')
          : _body(context.watch<ProfileController>()),
    );
  }

  Widget _body(ProfileController profiles) {
    final lines = profiles.pointLines;
    if (profiles.isLoadingPoints && lines.isEmpty) {
      return const LoadingView();
    }
    if (profiles.pointsError != null && lines.isEmpty) {
      return ErrorView(message: profiles.pointsError!, onRetry: profiles.loadPoints);
    }
    final List<Widget> items;
    if (lines.isEmpty) {
      // Điểm có từ trước khi có lịch sử (ví dụ dữ liệu mẫu) không có dòng nào
      items = [
        EmptyView(
          icon: Symbols.history_rounded,
          text: profiles.points > 0
              ? 'Bạn có ${profiles.points} điểm. Chưa có lần cộng hoặc trừ điểm nào được ghi lại.'
              : 'Bạn chưa có điểm nào. Viết review đầu tiên để nhận 10 điểm.',
        ),
      ];
    } else {
      items = [
        _summary(profiles),
        for (final month in _byMonth(lines)) ...[
          OverlineLabel(month.title),
          SenpaiGroup(children: [for (final line in month.lines) _line(line)]),
        ],
        ?_footer(profiles),
      ];
    }
    return RefreshIndicator(
      onRefresh: () => profiles.loadPoints(keepShown: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.extentAfter < 300) {
            profiles.loadMorePoints();
          }
          return false;
        },
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 14),
          itemBuilder: (_, i) => items[i],
        ),
      ),
    );
  }

  /// Thẻ nền ink bo 20: ô huy chương lantern 48, "Bạn có N điểm" Title/M và số lần cộng / trừ Caption.
  Widget _summary(ProfileController profiles) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: SenpaiColors.ink, borderRadius: BorderRadius.circular(20)),
      child: Row(
        spacing: 12,
        children: [
          const IconTile(Symbols.military_tech_rounded, tone: SenpaiTone.lantern, size: 48, radius: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  'Bạn có ${formatPoints(profiles.points)} điểm',
                  style: SenpaiText.titleM.copyWith(color: SenpaiColors.onBrand),
                ),
                Text(
                  '${profiles.pointsTotal} lần cộng / trừ',
                  style: SenpaiText.caption.copyWith(color: SenpaiColors.onBrand),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Gom các dòng liên tiếp cùng tháng ("THÁNG 11/2026"), giữ thứ tự mới nhất trước.
  static List<({String title, List<PointLine> lines})> _byMonth(List<PointLine> lines) {
    final groups = <({String title, List<PointLine> lines})>[];
    for (final line in lines) {
      final at = line.createdAt;
      final title = at == null ? 'Chưa rõ thời gian' : 'Tháng ${at.month}/${at.year}';
      if (groups.isEmpty || groups.last.title != title) {
        groups.add((title: title, lines: [line]));
      } else {
        groups.last.lines.add(line);
      }
    }
    return groups;
  }

  /// `PointRow`: ô số điểm 56 × 40 bo 12 (brand-soft, trừ điểm thì crit-soft), lý do Title/S, tên nội dung Body/S
  /// (còn mở được thì màu link brand-text), ngày Caption.
  Widget _line(PointLine line) {
    final negative = line.delta < 0;
    final link = line.link;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 56,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: negative ? SenpaiColors.critSoft : SenpaiColors.brandSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${negative ? '−' : '+'}${line.delta.abs()}',
              style: SenpaiText.labelM.copyWith(color: negative ? SenpaiColors.crit : SenpaiColors.brandText),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 1,
              children: [
                Text(
                  line.reasonLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink),
                ),
                Text(
                  line.title ?? 'Nội dung không còn',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SenpaiText.bodyS.copyWith(color: link == null ? SenpaiColors.muted : SenpaiColors.brandText),
                ),
                if (line.createdAt != null)
                  Text(formatDate(line.createdAt!), style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
    if (link == null) {
      return row;
    }
    return InkWell(onTap: () => openLink(context, link), borderRadius: BorderRadius.circular(12), child: row);
  }

  /// Cuối danh sách: vòng chờ khi đang tải trang sau, lỗi + Thử lại, hoặc nút "Tải thêm" khi trang đầu vừa
  /// màn hình (không cuộn được để tự tải).
  Widget? _footer(ProfileController profiles) {
    if (profiles.isLoadingMorePoints) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (profiles.morePointsError != null) {
      return Column(
        spacing: 4,
        children: [
          Text(
            profiles.morePointsError!,
            textAlign: TextAlign.center,
            style: SenpaiText.bodyS.copyWith(color: SenpaiColors.crit),
          ),
          TextButton(onPressed: profiles.loadMorePoints, child: const Text('Thử lại')),
        ],
      );
    }
    if (profiles.hasMorePoints) {
      return Center(
        child: SenpaiButton(
          label: 'Tải thêm',
          kind: SenpaiButtonKind.secondary,
          size: SenpaiButtonSize.medium,
          onPressed: profiles.loadMorePoints,
        ),
      );
    }
    return null;
  }
}
