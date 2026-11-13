import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/home_controller.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/home_guest_view.dart';
import 'package:myasvsj/com.myasvsj.screen/home_member_view.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';

/// Tab "Trang chủ" (màn 01 / 02 của thiết kế), thanh tiêu đề thương hiệu: logo + "Senpai ơi" + cụm nút.
/// Khách thấy lời mời, số liệu, review "Hữu ích" và câu tiếng Nhật hôm nay (`GET /api/home`);
/// thành viên thấy "Việc tiếp theo", "Dành cho bạn", review quanh khu vực, sự kiện, mẫu câu, bài nổi bật
/// (`GET /api/me/home`). Đăng nhập hoặc đăng xuất (đổi người dùng) thì tự tải lại đúng loại trang chủ.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _started = false;

  /// Người dùng của lần tải gần nhất (null là khách).
  int? _userId;

  Future<void> _reload({String? notice}) =>
      context.read<HomeController>().loadHome(signedIn: context.read<AuthController>().isSignedIn, notice: notice);

  @override
  Widget build(BuildContext context) {
    final userId = context.select<AuthController, int?>((auth) => auth.currentUser?.id);
    if (!_started || userId != _userId) {
      _started = true;
      _userId = userId;
      // Gọi sau khung hình đầu: notifyListeners() không được chạy giữa lúc đang dựng giao diện
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _reload();
        }
      });
    }
    final home = context.watch<HomeController>();
    return Scaffold(
      appBar: const SenpaiBrandAppBar(),
      body: _body(home, signedIn: userId != null),
    );
  }

  Widget _body(HomeController home, {required bool signedIn}) {
    final member = signedIn ? home.member : null;
    final guest = signedIn ? null : home.guest;
    if (member == null && guest == null) {
      if (home.homeError != null && !home.isLoadingHome) {
        return ErrorView(message: home.homeError!, onRetry: _reload);
      }
      return const LoadingView();
    }
    // Đã có trang chủ mà tải lại bị lỗi: giữ trang cũ, báo lỗi ở đầu
    final banner = home.homeError == null ? null : _ErrorBanner(message: home.homeError!, onRetry: _reload);
    return RefreshIndicator(
      onRefresh: _reload,
      child: member != null
          ? HomeMemberView(
              home: member,
              banner: banner,
              notice: home.homeNotice,
              showAreaPrompt: home.showAreaPrompt,
              onHidePrompt: home.hideAreaPrompt,
              onSettingsSaved: () => _reload(notice: HomeController.savedNotice),
            )
          : HomeGuestView(home: guest!, banner: banner),
    );
  }
}

/// Báo lỗi tải lại ở đầu trang: hộp crit-soft bo 14, icon, câu lỗi Body/S và nút "Thử lại".
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(color: SenpaiColors.critSoft, borderRadius: BorderRadius.circular(14)),
      child: Row(
        spacing: 10,
        children: [
          const Icon(Symbols.error_rounded, size: 20, color: SenpaiColors.crit),
          Expanded(child: Text(message, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.crit))),
          TextButton(
            style: SenpaiButtonStyle.ghost(SenpaiButtonSize.small)
                .copyWith(foregroundColor: const WidgetStatePropertyAll(SenpaiColors.crit)),
            onPressed: onRetry,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
