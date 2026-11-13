import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';
import 'package:myasvsj/com.myasvsj.model/app_notification.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/auth_required_view.dart';
import 'package:myasvsj/com.myasvsj.screen/empty_view.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/link_router.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/notification_tile.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Màn hình "Thông báo" (màn 05 của thiết kế, trang `/notifications` của web): hộp tóm tắt số chưa đọc + "Đọc hết",
/// thông báo mới nhất trước, nhóm theo ngày ("HÔM NAY", "HÔM QUA", "TRƯỚC ĐÓ"), 20 một trang, "Xem thêm".
/// Bấm một thông báo: đánh dấu đã đọc rồi mở trang của nó (bài viết, câu hỏi, địa điểm, sự kiện; tag → "Tôi").
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, this.linkOpener = openLink});

  /// Mở màn hình của một đường dẫn web; mặc định [openLink] (test thay để không phải dựng màn hình khác).
  final Future<bool> Function(BuildContext context, String? link) linkOpener;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  int? _loadedFor;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final notifications = context.watch<NotificationController>();
    final userId = auth.currentUser?.id;
    if (userId != null && userId != _loadedFor) {
      _loadedFor = userId;
      // Gọi sau khung hình: notifyListeners() không được chạy giữa lúc đang dựng giao diện
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<NotificationController>().loadNotifications();
        }
      });
    }
    final hasUnread = _hasUnread(notifications);
    return Scaffold(
      appBar: SenpaiAppBar(
        title: 'Thông báo',
        actions: [
          if (auth.isSignedIn)
            IconButton(
              tooltip: 'Đánh dấu tất cả đã đọc',
              icon: const Icon(Symbols.done_all_rounded),
              onPressed: hasUnread ? _markAllRead : null,
            ),
        ],
      ),
      body: auth.isSignedIn
          ? _body(notifications)
          : const AuthRequiredView(text: 'Đăng nhập để xem thông báo của bạn.'),
    );
  }

  static bool _hasUnread(NotificationController n) => n.unreadCount > 0 || n.items.any((item) => !item.read);

  Widget _body(NotificationController n) {
    if (n.isLoading && n.items.isEmpty) {
      return const LoadingView();
    }
    if (n.error != null && n.items.isEmpty) {
      return ErrorView(message: n.error!, onRetry: n.loadNotifications);
    }
    final children = <Widget>[
      // Chưa có thông báo thì chỉ hiện EmptyView, không lặp câu đó trong thanh tóm tắt
      if (n.items.isNotEmpty)
        _Summary(
          text: n.unreadCount > 0 ? '${n.unreadCount} thông báo chưa đọc.' : 'Bạn đã xem hết thông báo.',
          unread: n.unreadCount > 0,
          onReadAll: _hasUnread(n) ? _markAllRead : null,
        ),
    ];
    if (n.items.isEmpty) {
      children.add(const EmptyView(text: 'Chưa có thông báo.', icon: Symbols.notifications_rounded));
    }
    String? group;
    for (final item in n.items) {
      final label = _dayGroup(item.createdAt);
      if (label != group) {
        group = label;
        children.add(OverlineLabel(label));
      }
      children.add(NotificationTile(notification: item, onTap: () => _open(item)));
    }
    if (n.hasMore) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: SenpaiButton(
              label: n.isLoadingMore ? 'Đang tải…' : 'Xem thêm',
              kind: SenpaiButtonKind.ghost,
              size: SenpaiButtonSize.small,
              loading: n.isLoadingMore,
              onPressed: () => _loadMore(n),
            ),
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: n.loadNotifications,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }

  /// Nhóm theo ngày của thông báo (giờ máy): "Hôm nay", "Hôm qua", còn lại / không rõ ngày: "Trước đó".
  static String _dayGroup(DateTime? at) {
    if (at == null) {
      return 'Trước đó';
    }
    final now = DateTime.now();
    final local = at.toLocal();
    final days = DateTime(now.year, now.month, now.day).difference(DateTime(local.year, local.month, local.day)).inDays;
    return switch (days) {
      <= 0 => 'Hôm nay',
      1 => 'Hôm qua',
      _ => 'Trước đó',
    };
  }

  Future<void> _loadMore(NotificationController n) async {
    await n.loadMore();
    if (mounted) {
      showMessage(context, n.takeMessage());
    }
  }

  /// Đánh dấu đã đọc (ngay trên màn hình, server lưu sau) rồi mở trang của thông báo.
  Future<void> _open(AppNotification item) async {
    final notifications = context.read<NotificationController>();
    final marking = notifications.markRead(item);
    final target = item.target;
    if (target != null) {
      unawaited(widget.linkOpener(context, target));
    }
    await marking;
    if (mounted) {
      showMessage(context, notifications.takeMessage());
    }
  }

  Future<void> _markAllRead() async {
    final notifications = context.read<NotificationController>();
    await notifications.markAllRead();
    if (mounted) {
      showMessage(context, notifications.takeMessage());
    }
  }
}

/// Hộp tóm tắt: bo 14 p[10,14], icon + câu Label/M; còn thông báo chưa đọc thì nền brand-soft và link "Đọc hết"
/// gạch chân (đánh dấu tất cả đã đọc), không thì nền surface-2 chữ muted.
class _Summary extends StatelessWidget {
  const _Summary({required this.text, required this.unread, required this.onReadAll});

  final String text;
  final bool unread;
  final VoidCallback? onReadAll;

  @override
  Widget build(BuildContext context) {
    final color = unread ? SenpaiColors.brandText : SenpaiColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: unread ? SenpaiColors.brandSoft : SenpaiColors.surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        spacing: 8,
        children: [
          Icon(unread ? Symbols.notifications_active_rounded : Symbols.notifications_rounded, size: 20, color: color),
          Expanded(
            child: Text(text, style: SenpaiText.labelM.copyWith(color: color)),
          ),
          if (unread && onReadAll != null)
            InkWell(
              onTap: onReadAll,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                child: Text(
                  'Đọc hết',
                  style: SenpaiText.labelS.copyWith(
                    color: color,
                    decoration: TextDecoration.underline,
                    decorationColor: color,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
