import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.screen/app_bar_actions.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// `appBar(title, {sub, actions, close})` của thiết kế: thanh tiêu đề cao 56 trên nền bg, nút quay lại tròn 40
/// (tự hiện khi màn hình có thể quay lại), tiêu đề Title/M một dòng, dòng phụ Caption muted.
///
/// Bên trong là một [AppBar] thật nên `find.widgetWithText(AppBar, …)` và `find.byType(BackButton)` trong test
/// vẫn chạy.
class SenpaiAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SenpaiAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.actions,
    this.leading,
    this.close = false,
    this.automaticallyImplyLeading = true,
    this.bottom,
    this.backgroundColor,
  });

  final String? title;

  /// Thay cho [title] khi tiêu đề không phải chữ thường.
  final Widget? titleWidget;
  final String? subtitle;

  /// Các nút bên phải (IconButton 24 màu ink; nút xoá dùng màu crit).
  final List<Widget>? actions;
  final Widget? leading;

  /// true: nút trái là dấu X (màn hình mở dạng hộp thoại / form).
  final bool close;
  final bool automaticallyImplyLeading;

  /// Thanh tab dưới tiêu đề.
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;

  @override
  Size get preferredSize => Size.fromHeight(56 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final implied = automaticallyImplyLeading && (ModalRoute.of(context)?.impliesAppBarDismissal ?? false);
    final lead = leading ?? (close && implied ? const CloseButton() : null);
    final hasLeading = lead != null || implied;
    final Widget? heading = titleWidget ??
        (title == null
            ? null
            : subtitle == null
                ? Text(title!, maxLines: 1, overflow: TextOverflow.ellipsis, style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink)),
                      Text(subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
                    ],
                  ));
    return AppBar(
      leading: lead,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leadingWidth: 48,
      titleSpacing: hasLeading ? 0 : 16,
      title: heading,
      actions: actions,
      actionsPadding: const EdgeInsets.only(right: 4),
      bottom: bottom,
      backgroundColor: backgroundColor,
    );
  }
}

/// `appBar(title, {large: true, top})` của 4 tab gốc (Bản đồ, Blog, Hỏi-Đáp, Thêm): tiêu đề lớn Display/L,
/// có thể có dòng [overline] nhỏ màu brand phía trên, bên phải là cụm [AppBarActions] (Tìm kiếm, Tin nhắn,
/// Thông báo, Tôi / Đăng nhập).
class SenpaiLargeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SenpaiLargeAppBar({
    super.key,
    required this.title,
    this.overline,
    this.actions = const [],
    this.showTopActions = true,
    this.bottom,
  });

  final String title;
  final String? overline;

  /// Nút thêm, đứng trước cụm [AppBarActions].
  final List<Widget> actions;
  final bool showTopActions;
  final PreferredSizeWidget? bottom;

  double get _toolbar => overline == null ? 56 : 64;

  @override
  Size get preferredSize => Size.fromHeight(_toolbar + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: _toolbar,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (overline != null) Text(overline!, style: SenpaiText.overline.copyWith(color: SenpaiColors.brand)),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: SenpaiText.displayL.copyWith(color: SenpaiColors.ink)),
        ],
      ),
      actions: [...actions, if (showTopActions) const AppBarActions()],
      actionsPadding: const EdgeInsets.only(right: 8),
      bottom: bottom,
    );
  }
}

/// `AppBar/Brand` của Trang chủ: logo hoa anh đào + chữ "Senpai ơi" Display/M màu brand-text, bên phải
/// [AppBarActions].
class SenpaiBrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SenpaiBrandAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 52,
      titleSpacing: 16,
      title: Row(
        spacing: 8,
        children: [
          const SenpaiLogo(size: 34),
          Flexible(
            child: Text('Senpai ơi',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SenpaiText.displayM.copyWith(color: SenpaiColors.brandText)),
          ),
        ],
      ),
      actions: const [AppBarActions()],
      actionsPadding: const EdgeInsets.only(right: 8),
    );
  }
}
