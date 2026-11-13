import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/auth_notice.dart';
import 'package:myasvsj/com.myasvsj.screen/auth_required_view.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// "Xóa tài khoản" (màn 42 của thiết kế) ở trang Tôi: ô cảnh báo đỏ, email, nhóm hậu quả như web, nút Danger
/// "Xóa tài khoản" (hỏi xác nhận rồi xóa) và nút "Hủy". Xóa xong app về trạng thái khách và quay về màn hình gốc.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  /// Hậu quả của việc xóa, chép từ trang Tôi của web.
  static const consequences = [
    'Hồ sơ, điểm và tag bị xóa; yêu cầu tag đang chờ và ảnh minh chứng bị hủy.',
    'Bạn sẽ bị đăng xuất và không thể khôi phục.',
    'Bài viết, câu hỏi, bình luận, câu trả lời và tin nhắn của bạn sẽ bị ẩn với mọi người; '
        'review của bạn được xóa hoặc ẩn danh.',
  ];

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AuthController>().clearForm());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    return Scaffold(
      appBar: const SenpaiAppBar(title: 'Xóa tài khoản'),
      body: user == null
          ? const AuthRequiredView(text: 'Bạn cần đăng nhập để xóa tài khoản.')
          : _body(context, auth, user.email),
    );
  }

  Widget _body(BuildContext context, AuthController auth, String email) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        Column(
          spacing: 8,
          children: [
            const IconTile(Symbols.warning_rounded, tone: SenpaiTone.crit, size: 72, radius: 36),
            Text(
              'Xóa tài khoản?',
              textAlign: TextAlign.center,
              style: SenpaiText.displayL.copyWith(color: SenpaiColors.ink),
            ),
            Text(
              email,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SenpaiGroup(
          children: [
            for (final line in DeleteAccountScreen.consequences)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    const Icon(Symbols.remove_circle_rounded, size: 20, color: SenpaiColors.crit),
                    Expanded(child: Text(line, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.ink))),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        if (auth.bannerError != null) AuthNotice(text: auth.bannerError!),
        SenpaiButton(
          label: auth.isLoading ? 'Đang xóa…' : 'Xóa tài khoản',
          kind: SenpaiButtonKind.danger,
          icon: Symbols.delete_forever_rounded,
          expand: true,
          onPressed: auth.isLoading ? null : () => _confirmAndDelete(context, email),
        ),
        const SizedBox(height: 18),
        SenpaiButton(
          label: 'Hủy',
          kind: SenpaiButtonKind.secondary,
          expand: true,
          onPressed: auth.isLoading ? null : () => Navigator.pop(context),
        ),
      ],
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, String email) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Center(child: IconTile(Symbols.warning_rounded, tone: SenpaiTone.crit, size: 48, radius: 24)),
        title: const Text('Xóa tài khoản?'),
        content: Text(
          'Tài khoản $email sẽ bị xóa và không thể khôi phục.',
          style: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Hủy')),
          FilledButton(
            style: SenpaiButtonStyle.danger(SenpaiButtonSize.medium),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa tài khoản'),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) {
      return;
    }
    final auth = context.read<AuthController>();
    final deleted = await auth.deleteAccount();
    if (deleted && context.mounted) {
      // "Đã xóa tài khoản."
      showMessage(context, auth.takeMessage());
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }
}
