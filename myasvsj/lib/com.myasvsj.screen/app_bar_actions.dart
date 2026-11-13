import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/chat_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';
import 'package:myasvsj/com.myasvsj.screen/conversation_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/global_search_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/notification_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/sign_in_gate.dart';

/// Cụm nút "TopActions" trên thanh tiêu đề của 5 tab chính: Tìm kiếm, Tin nhắn (số chưa đọc + lời mời),
/// Thông báo (số chưa đọc), Tôi (ảnh đại diện) / Đăng nhập. Mỗi nút 40 × 40, icon Material Symbols Rounded 24.
///
/// Dùng qua [SenpaiLargeAppBar] / [SenpaiBrandAppBar], hoặc `AppBar(actions: const [AppBarActions()])`.
class AppBarActions extends StatelessWidget {
  const AppBarActions({super.key});

  static final ButtonStyle _style = IconButton.styleFrom(
    foregroundColor: SenpaiColors.ink,
    minimumSize: const Size(40, 40),
    fixedSize: const Size(40, 40),
    padding: EdgeInsets.zero,
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final unread = context.watch<NotificationController>().unreadCount;
    // Tin chưa đọc + lời mời mới, như số trên nút Tin nhắn của web. Test chỉ cấp NotificationController thì bỏ qua.
    final chats = _chatBadge(context);
    final user = auth.currentUser;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Tìm kiếm',
          style: _style,
          icon: const Icon(Symbols.search_rounded),
          onPressed: () => _push(context, const GlobalSearchScreen()),
        ),
        IconButton(
          tooltip: 'Tin nhắn',
          style: _style,
          icon: Badge(
            isLabelVisible: auth.isSignedIn && chats > 0,
            label: Text(chats > 99 ? '99+' : '$chats'),
            child: const Icon(Symbols.chat_bubble_rounded),
          ),
          onPressed: () => _pushSignedIn(context, const ConversationListScreen()),
        ),
        IconButton(
          tooltip: 'Thông báo',
          style: _style,
          icon: Badge(
            isLabelVisible: auth.isSignedIn && unread > 0,
            label: Text(unread > 99 ? '99+' : '$unread'),
            child: const Icon(Symbols.notifications_rounded),
          ),
          onPressed: () => _pushSignedIn(context, const NotificationScreen()),
        ),
        if (auth.isSignedIn)
          IconButton(
            tooltip: 'Tôi',
            style: _style,
            icon: SenpaiAvatar(
              name: user?.displayName ?? '',
              imageUrl: user?.avatarUrl ?? '',
              size: 32,
              tone: SenpaiTone.lantern,
            ),
            onPressed: () => _push(context, const ProfileScreen()),
          )
        else
          IconButton(
            tooltip: 'Đăng nhập',
            style: _style,
            icon: const Icon(Symbols.login_rounded),
            onPressed: () => _push(context, const LoginScreen()),
          ),
      ],
    );
  }

  static int _chatBadge(BuildContext context) {
    try {
      final counts = context.watch<ChatController>().counts;
      return counts.unread + counts.requests;
    } on ProviderNotFoundException {
      return 0;
    }
  }

  static void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
  }

  static Future<void> _pushSignedIn(BuildContext context, Widget screen) async {
    if (!await requireSignIn(context) || !context.mounted) {
      return;
    }
    _push(context, screen);
  }
}
