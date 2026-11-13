import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/chat_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/profile_controller.dart';
import 'package:myasvsj/com.myasvsj.model/user.dart';
import 'package:myasvsj/com.myasvsj.screen/conversation_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/event_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/faq_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/legal_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/my_guides_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/notification_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/register_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/saved_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/sign_in_gate.dart';

/// Tab "Thêm" (màn 06 của thiết kế): thẻ hồ sơ màu brand, lưới "Khám phá" (Nhật ngữ, Sự kiện, Cẩm nang, FAQ),
/// nhóm "Của tôi" (Tin nhắn, Thông báo, Đã lưu, Cẩm nang của tôi) và nhóm "Pháp lý". Khách thấy thẻ mời đăng
/// nhập / đăng ký thay cho thẻ hồ sơ và nhóm "Của tôi".
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    return Scaffold(
      appBar: const SenpaiLargeAppBar(title: 'Thêm'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (user != null) _ProfileCard(user: user) else const _GuestCard(),
          const SizedBox(height: 14),
          const OverlineLabel('Khám phá'),
          const SizedBox(height: 14),
          const _ExploreGrid(),
          if (user != null) ...[
            const SizedBox(height: 14),
            const OverlineLabel('Của tôi'),
            const SizedBox(height: 14),
            SenpaiGroup(children: [
              _row(context, Symbols.chat_bubble_rounded, 'Tin nhắn', const ConversationListScreen(),
                  count: _chatCount(context), signIn: true),
              _row(context, Symbols.notifications_rounded, 'Thông báo', const NotificationScreen(),
                  count: _notificationCount(context), signIn: true),
              _row(context, Symbols.bookmark_rounded, 'Đã lưu', const SavedScreen(), signIn: true),
              _row(context, Symbols.checklist_rounded, 'Cẩm nang của tôi', const MyGuidesScreen(), signIn: true),
            ]),
          ],
          const SizedBox(height: 14),
          const OverlineLabel('Pháp lý'),
          const SizedBox(height: 14),
          SenpaiGroup(children: [
            _row(context, Symbols.gavel_rounded, 'Điều khoản sử dụng', const LegalScreen(type: 'terms'),
                tone: SenpaiTone.neutral),
            _row(context, Symbols.privacy_tip_rounded, 'Chính sách bảo mật', const LegalScreen(type: 'privacy'),
                tone: SenpaiTone.neutral),
            _row(context, Symbols.groups_rounded, 'Quy tắc cộng đồng', const LegalScreen(type: 'community'),
                tone: SenpaiTone.neutral),
          ]),
          const SizedBox(height: 14),
          Text(
            'Senpai ơi · phiên bản 1.0.0',
            textAlign: TextAlign.center,
            style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
          ),
        ],
      ),
    );
  }

  /// Dòng của nhóm "Của tôi" / "Pháp lý": ô icon 36 bo 10, tên Title/S, số đếm (badge brand) và chevron.
  static Widget _row(
    BuildContext context,
    IconData icon,
    String title,
    Widget screen, {
    SenpaiTone tone = SenpaiTone.brand,
    int count = 0,
    bool signIn = false,
  }) {
    return SenpaiListRow(
      leading: IconTile(icon, tone: tone, size: 36, radius: 10),
      title: title,
      trailing: count > 0
          ? Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                SenpaiBadge(count > 99 ? '99+' : '$count', tone: SenpaiTone.solid),
                const Icon(Symbols.chevron_right_rounded, size: 22, color: SenpaiColors.muted),
              ],
            )
          : null,
      onTap: () => _open(context, screen, signIn: signIn),
    );
  }

  static Future<void> _open(BuildContext context, Widget screen, {bool signIn = false}) async {
    if (signIn && (!await requireSignIn(context) || !context.mounted)) {
      return;
    }
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
  }

  /// Tin chưa đọc + lời mời mới; 0 khi app (hoặc test) không cấp ChatController.
  static int _chatCount(BuildContext context) {
    try {
      final counts = context.watch<ChatController>().counts;
      return counts.unread + counts.requests;
    } on ProviderNotFoundException {
      return 0;
    }
  }

  static int _notificationCount(BuildContext context) {
    try {
      return context.watch<NotificationController>().unreadCount;
    } on ProviderNotFoundException {
      return 0;
    }
  }
}

/// Thẻ hồ sơ màu brand: ảnh đại diện 52 tone lantern, tên Title/M, "điểm · hạng · khu vực" Caption, chevron;
/// logo hoa mờ 15% ở góc phải. Bấm mở trang Tôi.
class _ProfileCard extends StatefulWidget {
  const _ProfileCard({required this.user});

  final User user;

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  @override
  void initState() {
    super.initState();
    // Điểm, hạng, khu vực nằm trong hồ sơ: tải một lần nếu trang Tôi chưa tải
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profiles = _profiles(context, listen: false);
      if (mounted && profiles != null && (profiles.profile == null || profiles.profile!.id != widget.user.id) && !profiles.isLoading) {
        profiles.loadProfile();
      }
    });
  }

  static ProfileController? _profiles(BuildContext context, {bool listen = true}) {
    try {
      return listen ? context.watch<ProfileController>() : context.read<ProfileController>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loaded = _profiles(context)?.profile;
    // Hồ sơ còn lại của người đăng nhập trước thì bỏ qua
    final profile = loaded != null && loaded.id == widget.user.id ? loaded : null;
    final subtitle = profile == null
        ? widget.user.roleLabel
        : [
            '${_points(profile.points)} điểm',
            ?profile.currentRank?.name,
            ?profile.areaName,
          ].join(' · ');
    return SenpaiCard(
      color: SenpaiColors.brand,
      borderColor: null,
      radius: 20,
      padding: EdgeInsets.zero,
      onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ProfileScreen())),
      child: Stack(
        children: [
          const Positioned(right: -42, top: -20, child: Opacity(opacity: 0.15, child: SenpaiLogo(size: 100))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              spacing: 12,
              children: [
                SenpaiAvatar(
                  name: widget.user.displayName,
                  imageUrl: widget.user.avatarUrl ?? '',
                  size: 52,
                  tone: SenpaiTone.lantern,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Text(widget.user.displayName, style: SenpaiText.titleM.copyWith(color: SenpaiColors.onBrand)),
                      Text(subtitle, style: SenpaiText.caption.copyWith(color: SenpaiColors.onBrand)),
                    ],
                  ),
                ),
                const Icon(Symbols.chevron_right_rounded, size: 24, color: SenpaiColors.onBrand),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 1250 → "1.250" như cách viết số của web.
  static String _points(int n) {
    final s = n.abs().toString();
    final out = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        out.write('.');
      }
      out.write(s[i]);
    }
    return out.toString();
  }
}

/// Thẻ mời của khách: cùng kiểu thẻ hồ sơ, hai nút Đăng nhập / Đăng ký.
class _GuestCard extends StatelessWidget {
  const _GuestCard();

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
    return SenpaiCard(
      color: SenpaiColors.brand,
      borderColor: null,
      radius: 20,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          const Positioned(right: -42, top: -20, child: Opacity(opacity: 0.15, child: SenpaiLogo(size: 100))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 12,
              children: [
                Text('Bạn chưa đăng nhập', style: SenpaiText.titleM.copyWith(color: SenpaiColors.onBrand)),
                Text(
                  'Đăng nhập để lưu bài, nhắn tin với senpai và nhận gợi ý theo khu vực của bạn.',
                  style: SenpaiText.bodyS.copyWith(color: SenpaiColors.onBrand),
                ),
                Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: SenpaiButtonStyle.size(SenpaiButtonSize.medium).copyWith(
                          backgroundColor: const WidgetStatePropertyAll(SenpaiColors.surface),
                          foregroundColor: const WidgetStatePropertyAll(SenpaiColors.brandText),
                        ),
                        onPressed: () => open(const LoginScreen()),
                        icon: const Icon(Symbols.login_rounded),
                        label: const Text('Đăng nhập'),
                      ),
                    ),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: SenpaiButtonStyle.size(SenpaiButtonSize.medium).copyWith(
                          backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
                          foregroundColor: const WidgetStatePropertyAll(SenpaiColors.onBrand),
                          side: const WidgetStatePropertyAll(BorderSide(color: SenpaiColors.onBrand, width: 1.5)),
                        ),
                        onPressed: () => open(const RegisterScreen()),
                        icon: const Icon(Symbols.person_add_rounded),
                        label: const Text('Đăng ký'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lưới 2 cột "Khám phá": mỗi ô trắng bo 18 viền line, cao 128, ô icon 40, tên Title/S, mô tả Caption 2 dòng.
class _ExploreGrid extends StatelessWidget {
  const _ExploreGrid();

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, SenpaiTone tone, String title, String description, Widget screen) {
      return SenpaiCard(
        radius: 18,
        onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen)),
        // Cao tối thiểu 100 (ô 128 trong thiết kế); tên dài thì xuống dòng và ô cao theo
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              IconTile(icon, tone: tone),
              Text(title, style: SenpaiText.titleS),
              Text(description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
            ],
          ),
        ),
      );
    }

    final tiles = [
      tile(Symbols.translate_rounded, SenpaiTone.brand, 'Nhật ngữ', 'Mẫu câu, từ vựng, thẻ ghi nhớ', const PhraseScreen()),
      tile(Symbols.festival_rounded, SenpaiTone.lantern, 'Lễ hội và sự kiện', 'Đang và sắp diễn ra',
          const EventListScreen()),
      tile(Symbols.menu_book_rounded, SenpaiTone.ok, 'Cẩm nang', 'Theo từng giai đoạn', const GuideListScreen()),
      tile(Symbols.help_rounded, SenpaiTone.ai, 'Câu hỏi thường gặp', 'Moderator tổng hợp', const FaqScreen()),
    ];
    return Column(
      spacing: 12,
      children: [
        for (var i = 0; i < tiles.length; i += 2)
          // Hai ô cùng hàng cao bằng nhau
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [Expanded(child: tiles[i]), Expanded(child: tiles[i + 1])],
            ),
          ),
      ],
    );
  }
}
