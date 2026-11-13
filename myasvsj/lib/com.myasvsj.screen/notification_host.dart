import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/chat_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';
import 'package:myasvsj/com.myasvsj.screen/link_router.dart';

/// Bọc màn hình gốc của app (`home: NotificationHost(child: MainScreen())`) để nối "Thông báo" và "Tin nhắn" với
/// cả app, không cần màn hình nào khác biết tới:
///
/// - người đăng nhập đổi → [NotificationController.onSignedInChanged] và [ChatController.onSignedInChanged]
///   (mở / đóng luồng tức thì, xin quyền thông báo);
/// - nối ChatController với luồng tức thì của NotificationController;
/// - app mở lại từ nền → hỏi summary một lần, hỏi bù tin nhắn;
/// - người dùng bấm một thông báo trên máy → mở màn hình của nó ([openLink]).
///
/// Không vẽ gì thêm: trả về [child] nguyên vẹn.
class NotificationHost extends StatefulWidget {
  const NotificationHost({super.key, required this.child});

  final Widget child;

  @override
  State<NotificationHost> createState() => _NotificationHostState();
}

class _NotificationHostState extends State<NotificationHost> {
  late final NotificationController _notifications;
  late final ChatController _chat;
  late final AppLifecycleListener _lifecycle;
  int? _userId;
  bool _synced = false;

  @override
  void initState() {
    super.initState();
    _notifications = context.read<NotificationController>()..addListener(_openPending);
    _chat = context.read<ChatController>()..attachLive(_notifications.liveEvents);
    _lifecycle = AppLifecycleListener(onResume: _onResume);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _notifications.removeListener(_openPending);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.select<AuthController, int?>((auth) => auth.currentUser?.id);
    if (!_synced || userId != _userId) {
      _synced = true;
      _userId = userId;
      // Sau khung hình: hai Controller sẽ notifyListeners()
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncUser());
    }
    return widget.child;
  }

  void _syncUser() {
    if (!mounted) {
      return;
    }
    final user = context.read<AuthController>().currentUser;
    _notifications.onSignedInChanged(user);
    _chat.onSignedInChanged(user);
  }

  void _onResume() {
    _notifications.onAppResumed();
    _chat.onAppResumed();
  }

  /// Thông báo trên máy vừa được bấm: mở màn hình của nó.
  void _openPending() {
    final link = _notifications.takeOpenLink();
    if (link != null && mounted) {
      openLink(context, link);
    }
  }
}
