import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/chat_controller.dart';
import 'package:myasvsj/com.myasvsj.model/chat_keyring.dart';
import 'package:myasvsj/com.myasvsj.model/conversation_item.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/chat_avatar.dart';
import 'package:myasvsj/com.myasvsj.screen/chat_guest_view.dart';
import 'package:myasvsj/com.myasvsj.screen/chat_key_dialog.dart';
import 'package:myasvsj/com.myasvsj.screen/chat_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/conversation_tile.dart';
import 'package:myasvsj/com.myasvsj.screen/empty_view.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Màn hình "Tin nhắn" (trang `/messages` của web, màn 30 của thiết kế): thanh tiêu đề có nút "Người đã chặn", hai tab
/// "Tin nhắn" và "Lời mời" (số lời mời trên badge brand), danh sách ConversationTile, kéo xuống làm mới, tự cập nhật
/// khi có tin mới (luồng tức thì). Nút "Người đã chặn" mở danh sách để bỏ chặn.
class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  int? _loadedFor;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final chat = context.watch<ChatController>();
    final userId = auth.currentUser?.id;
    if (userId != null && userId != _loadedFor) {
      _loadedFor = userId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadBoth());
    }
    if (!auth.isSignedIn) {
      return const Scaffold(
        appBar: SenpaiAppBar(title: 'Tin nhắn'),
        body: ChatGuestView(),
      );
    }
    final requests = chat.counts.requests;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: SenpaiAppBar(
          title: 'Tin nhắn',
          actions: [
            IconButton(tooltip: 'Người đã chặn', icon: const Icon(Symbols.block_rounded), onPressed: _openBlocks),
          ],
          bottom: _FullWidthDivider(
            child: TabBar(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              dividerHeight: 0,
              tabs: [
                const Tab(text: 'Tin nhắn'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 6,
                    children: [
                      const Flexible(child: Text('Lời mời', maxLines: 1, overflow: TextOverflow.ellipsis)),
                      if (requests > 0) SenpaiBadge(requests > 99 ? '99+' : '$requests', tone: SenpaiTone.solid),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?_keyBanner(chat),
            Expanded(
              child: TabBarView(
                children: [
                  _BoxView(box: ChatController.inbox, onOpen: _openConversation),
                  _BoxView(box: ChatController.requests, onOpen: _openConversation),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dải báo về mã hóa đầu cuối trên danh sách, như `chat-key-banner` của web: chưa bật thì "Bật mã hóa", có khóa mà
  /// app chưa mở thì "Nhập mật khẩu khôi phục", lỗi tải khóa thì "Thử lại".
  Widget? _keyBanner(ChatController chat) {
    final (String text, String label, IconData icon, SenpaiTone tone, VoidCallback onPressed) = switch (chat.keyState) {
      ChatKeyState.none => (
        'Bật mã hóa đầu cuối để chỉ bạn và người nhận đọc được tin nhắn.',
        'Bật mã hóa',
        Symbols.lock_rounded,
        SenpaiTone.neutral,
        () => showChatKeyDialog(context, chat, mode: ChatKeyDialogMode.setup),
      ),
      ChatKeyState.locked => (
        'Nhập mật khẩu khôi phục để đọc và gửi tin nhắn đã mã hóa trên app này.',
        'Nhập mật khẩu khôi phục',
        Symbols.key_rounded,
        SenpaiTone.brand,
        () => showChatKeyDialog(context, chat, mode: ChatKeyDialogMode.unlock),
      ),
      ChatKeyState.error => (
        'Chưa tải được khóa mã hóa: ${chat.keyError ?? ''}',
        'Thử lại',
        Symbols.error_rounded,
        SenpaiTone.crit,
        chat.retryKey,
      ),
      _ => ('', '', Symbols.lock_rounded, SenpaiTone.neutral, () {}),
    };
    if (text.isEmpty) {
      return null;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: SenpaiNote(
        text,
        icon: icon,
        tone: tone,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text(text),
            SenpaiButton(
              label: label,
              kind: chat.keyState == ChatKeyState.locked ? SenpaiButtonKind.primary : SenpaiButtonKind.secondary,
              size: SenpaiButtonSize.small,
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }

  void _loadBoth() {
    if (!mounted) {
      return;
    }
    final chat = context.read<ChatController>();
    chat.loadConversations(ChatController.inbox);
    chat.loadConversations(ChatController.requests);
  }

  Future<void> _openConversation(ConversationItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChatScreen(conversationId: item.id, title: item.peer.displayName),
      ),
    );
    // Quay về: số chưa đọc, lời mời đã trả lời, cuộc trò chuyện đã xóa
    _loadBoth();
  }

  void _openBlocks() {
    context.read<ChatController>().loadBlocks();
    showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => const _BlocksSheet());
  }
}

/// Một hộp thư: danh sách (lề [8,8,24,8], các dòng cách 2), trạng thái chờ / lỗi / rỗng, nút Ghost "Xem thêm".
class _BoxView extends StatelessWidget {
  const _BoxView({required this.box, required this.onOpen});

  final String box;
  final ValueChanged<ConversationItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final items = chat.conversationsOf(box);
    final error = chat.errorOf(box);
    if (chat.isLoadingOf(box) && items.isEmpty) {
      return const LoadingView();
    }
    if (error != null && items.isEmpty) {
      return ErrorView(message: error, onRetry: () => chat.loadConversations(box));
    }
    final hasMore = chat.hasMoreOf(box);
    return RefreshIndicator(
      onRefresh: () => chat.loadConversations(box),
      child: items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [EmptyView(text: _emptyText(chat), icon: Symbols.forum_rounded)],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
              itemCount: items.length + (hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const SizedBox(height: 2),
              itemBuilder: (context, i) {
                if (i < items.length) {
                  return ConversationTile(
                    item: items[i],
                    shownLast: chat.previewOf(items[i]),
                    onTap: () => onOpen(items[i]),
                  );
                }
                final loading = chat.isLoadingMoreOf(box);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SenpaiButton(
                      label: loading ? 'Đang tải…' : 'Xem thêm',
                      kind: SenpaiButtonKind.ghost,
                      size: SenpaiButtonSize.small,
                      onPressed: loading ? null : () => _loadMore(context, chat),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _loadMore(BuildContext context, ChatController chat) async {
    await chat.loadMoreConversations(box);
    if (context.mounted) {
      showMessage(context, chat.takeMessage());
    }
  }

  /// Câu "chưa có gì" của trang web.
  String _emptyText(ChatController chat) {
    if (box == ChatController.requests) {
      return 'Không có lời mời nhắn tin nào. Tin nhắn đầu tiên của người chưa từng trò chuyện với bạn sẽ nằm ở đây.';
    }
    final requests = chat.counts.requests;
    return requests > 0
        ? 'Chưa có cuộc trò chuyện nào. Bạn có $requests lời mời nhắn tin đang chờ ở mục “Lời mời”.'
        : 'Chưa có cuộc trò chuyện nào. Muốn hỏi thêm ai đó, bấm “Nhắn tin” cạnh tên họ ở Blog hoặc Hỏi-Đáp.';
  }
}

/// Bottom sheet "Người đã chặn": mỗi dòng ảnh 40, tên Title/S và nút viền cỡ S "Bỏ chặn".
class _BlocksSheet extends StatelessWidget {
  const _BlocksSheet();

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatController>();
    final Widget content;
    if (chat.isLoadingBlocks && chat.blocked.isEmpty) {
      content = const Padding(padding: EdgeInsets.all(24), child: LoadingView());
    } else if (chat.blocksError != null) {
      content = ErrorView(message: chat.blocksError!, onRetry: chat.loadBlocks);
    } else if (chat.blocked.isEmpty) {
      content = const EmptyView(text: 'Bạn chưa chặn ai.', icon: Symbols.block_rounded);
    } else {
      content = ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        itemCount: chat.blocked.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, i) {
          final member = chat.blocked[i];
          return SenpaiListRow(
            leading: ChatAvatar(
              name: member.peer.displayName,
              url: member.peer.avatarUrl,
              tone: ChatAvatar.toneFor(member.peer.id, active: member.peer.active),
            ),
            title: member.peer.displayName,
            trailing: SenpaiButton(
              label: 'Bỏ chặn',
              kind: SenpaiButtonKind.secondary,
              size: SenpaiButtonSize.small,
              onPressed: () async {
                await chat.unblock(member);
                if (context.mounted) {
                  showMessage(context, chat.takeMessage());
                }
              },
            ),
          );
        },
      );
    }
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Người đã chặn', style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink)),
          ),
          Flexible(child: content),
        ],
      ),
    );
  }
}

/// Thanh tab `tabs()` của thiết kế: đường kẻ line 1 px dưới đáy chạy hết bề ngang màn hình (TabBar tự kẻ thì chỉ
/// trong phần lề 16).
class _FullWidthDivider extends StatelessWidget implements PreferredSizeWidget {
  const _FullWidthDivider({required this.child});

  final TabBar child;

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: SenpaiColors.line)),
      ),
      child: child,
    );
  }
}
