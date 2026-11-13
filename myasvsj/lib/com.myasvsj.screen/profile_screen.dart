import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/profile_controller.dart';
import 'package:myasvsj/com.myasvsj.model/profile_rank.dart';
import 'package:myasvsj/com.myasvsj.model/profile_stage.dart';
import 'package:myasvsj/com.myasvsj.model/user_profile.dart';
import 'package:myasvsj/com.myasvsj.screen/area_stage_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/change_password_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/delete_account_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/interest_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/my_guides_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/point_history_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_points.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_sign_in_prompt.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_tag_chip.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_user_watcher.dart';
import 'package:myasvsj/com.myasvsj.screen/saved_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/tag_request_screen.dart';

/// Trang "Tôi" (màn 35 của thiết kế): thẻ hồ sơ (ảnh, tên, tag, cách đăng nhập), thẻ điểm màu brand (cấp hiện
/// tại, tiến độ lên cấp, cách tính điểm, Lịch sử điểm), các ô cấp bậc và quyền lợi, hạn mức tài khoản mới, nhóm
/// mục cá nhân (tag, khu vực và giai đoạn, chủ đề quan tâm, Cẩm nang của tôi, Đã lưu) và nhóm tài khoản (đổi
/// mật khẩu, đăng xuất, xóa tài khoản). Khách thấy lời mời đăng nhập.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with ProfileUserWatcher {
  /// Cách đăng nhập theo nhà cung cấp đã liên kết, như trang web.
  static const _providerNames = {'GOOGLE': 'Google', 'FACEBOOK': 'Facebook'};

  @override
  void onUserChanged(int? userId) {
    final profiles = context.read<ProfileController>();
    if (userId == null) {
      profiles.clear();
    } else {
      profiles.loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    watchUser(user?.id);
    final profiles = context.watch<ProfileController>();
    return Scaffold(
      appBar: const SenpaiAppBar(title: 'Tôi'),
      body: user == null
          ? const ProfileSignInPrompt(text: 'Đăng nhập để xem điểm, khu vực, mục đã lưu và quản lý tài khoản.')
          : _body(profiles, user.id),
    );
  }

  Widget _body(ProfileController profiles, int userId) {
    final profile = profiles.profile;
    // Hồ sơ của người khác (vừa đổi tài khoản) không bao giờ được hiện
    if (profile == null || profile.id != userId) {
      if (profiles.error != null && !profiles.isLoading) {
        return ErrorView(message: profiles.error!, onRetry: profiles.loadProfile);
      }
      return const LoadingView();
    }
    final blocks = <Widget>[
      if (profiles.error != null) SenpaiNote(profiles.error!, icon: Symbols.error_rounded, tone: SenpaiTone.crit),
      _header(profile),
      _pointsCard(profile),
      if (profile.ranks.isNotEmpty) _rankTiles(profile),
      if (profile.ranks.any((r) => r.perks.isNotEmpty)) _perksCard(profile),
      if (profile.newAccount) _newAccountCard(profile),
      _personalGroup(profiles, profile),
      _accountGroup(profile),
    ];
    return RefreshIndicator(
      onRefresh: profiles.loadProfile,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (var i = 0; i < blocks.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            blocks[i],
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Ảnh, tên, tag, cách đăng nhập

  /// Thẻ hồ sơ trắng bo 24: ảnh đại diện 64 tone lantern, tên Display/M, tag định danh và vai trò, rồi email ·
  /// cách đăng nhập (Caption muted).
  Widget _header(UserProfile profile) {
    final methods = [
      if (profile.hasPassword) 'Email và mật khẩu',
      for (final p in profile.linkedProviders) _providerNames[p] ?? p,
    ];
    return SenpaiCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            spacing: 14,
            children: [
              SenpaiAvatar(
                name: profile.displayName,
                imageUrl: profile.avatarUrl ?? '',
                size: 64,
                tone: SenpaiTone.lantern,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Text(
                      profile.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: SenpaiText.displayM.copyWith(color: SenpaiColors.ink),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final tag in profile.tags)
                          ProfileTagChip(name: tag.name, color: tag.color, icon: Symbols.verified_rounded),
                        if (profile.tags.isEmpty)
                          Text('Chưa có tag định danh', style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
                        if (profile.roleLabel.isNotEmpty) SenpaiBadge(profile.roleLabel, tone: SenpaiTone.neutral),
                        if (profile.reportMutedUntil != null)
                          SenpaiBadge(
                            'Bị khóa báo cáo đến ${formatDate(profile.reportMutedUntil!)}',
                            tone: SenpaiTone.crit,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Text(
            '${profile.email}${methods.isEmpty ? '' : ' · Đăng nhập bằng: ${methods.join(', ')}'}',
            style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Điểm và cấp bậc

  /// Thẻ điểm nền brand bo 24: "ĐIỂM CỦA BẠN", số điểm Display/XL, viên thuốc trắng tên cấp hiện tại, thanh tiến độ
  /// lantern trên nền brand-strong, số điểm còn thiếu, cách tính điểm và dòng "Lịch sử điểm"; logo hoa mờ ở góc.
  Widget _pointsCard(UserProfile profile) {
    final current = profile.currentRank;
    final next = profile.nextRank;
    const onBrand = SenpaiColors.onBrand;
    return SenpaiCard(
      color: SenpaiColors.brand,
      borderColor: null,
      radius: 24,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          const Positioned(right: -32, top: -34, child: Opacity(opacity: 0.14, child: SenpaiLogo(size: 120))),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ĐIỂM CỦA BẠN', style: SenpaiText.overline.copyWith(color: onBrand)),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${formatPoints(profile.points)} điểm',
                              style: SenpaiText.displayXL.copyWith(color: onBrand),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (current != null)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 170),
                        child: _rankPill(current.name),
                      ),
                  ],
                ),
                Semantics(
                  label: 'Tiến độ lên cấp',
                  value: '${(profile.rankProgress * 100).round()}%',
                  child: SenpaiProgressBar(
                    value: profile.rankProgress,
                    height: 10,
                    color: SenpaiColors.lantern,
                    trackColor: SenpaiColors.brandStrong,
                  ),
                ),
                Text(
                  next == null ? 'Hạng cao nhất' : 'Còn ${profile.pointsToNextRank} điểm nữa lên ${next.name}',
                  style: SenpaiText.bodyS.copyWith(color: onBrand),
                ),
                Text(
                  'Review +10 · Ghim được duyệt +15 · Câu trả lời hay nhất +5 · Bài bị gỡ −20 · '
                  'Tự xóa bài thì điểm của bài đó được thu lại',
                  style: SenpaiText.caption.copyWith(color: onBrand),
                ),
                Material(
                  color: SenpaiColors.surface.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _open(const PointHistoryScreen(), reload: false),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                        spacing: 6,
                        children: [
                          const Icon(Symbols.history_rounded, size: 18, color: onBrand),
                          Expanded(child: Text('Lịch sử điểm', style: SenpaiText.labelM.copyWith(color: onBrand))),
                          const Icon(Symbols.chevron_right_rounded, size: 20, color: onBrand),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Viên thuốc trắng: icon huy chương lantern-text + tên cấp Label/M brand-text.
  static Widget _rankPill(String name) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const ShapeDecoration(color: SenpaiColors.surface, shape: StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          const Icon(Symbols.military_tech_rounded, size: 18, color: SenpaiColors.lanternText),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SenpaiText.labelM.copyWith(color: SenpaiColors.brandText),
            ),
          ),
        ],
      ),
    );
  }

  /// Hàng ô cấp bậc: cấp đã đạt nền lantern-soft "Đã đạt" (ok), cấp chưa đạt nền trắng "từ N" (muted).
  /// Tối đa 4 ô chia đều chiều ngang; nhiều hơn thì cuộn ngang.
  Widget _rankTiles(UserProfile profile) {
    final ranks = profile.ranks;
    Widget tile(int i) {
      final rank = ranks[i];
      final reached = i <= profile.rankIndex;
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: reached ? SenpaiColors.lanternSoft : SenpaiColors.surface,
          border: Border.all(color: SenpaiColors.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            Icon(Symbols.military_tech_rounded, size: 20, color: reached ? SenpaiColors.lanternText : SenpaiColors.muted),
            Text(
              rank.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SenpaiText.labelS.copyWith(color: SenpaiColors.ink),
            ),
            Text(
              reached ? 'Đã đạt' : 'từ ${formatPoints(rank.minPoints)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: SenpaiText.caption.copyWith(color: reached ? SenpaiColors.ok : SenpaiColors.muted),
            ),
          ],
        ),
      );
    }

    if (ranks.length <= 4) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [for (var i = 0; i < ranks.length; i++) Expanded(child: tile(i))],
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [for (var i = 0; i < ranks.length; i++) SizedBox(width: 96, child: tile(i))],
        ),
      ),
    );
  }

  /// Quyền lợi của từng cấp (như trang Tôi của web): tên cấp, ngưỡng điểm, các quyền lợi.
  Widget _perksCard(UserProfile profile) {
    return SenpaiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Text('Quyền lợi theo cấp', style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
          for (var i = 0; i < profile.ranks.length; i++)
            if (profile.ranks[i].perks.isNotEmpty) _perks(profile.ranks[i], reached: i <= profile.rankIndex),
        ],
      ),
    );
  }

  static Widget _perks(ProfileRank rank, {required bool reached}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: [
        Row(
          spacing: 6,
          children: [
            Icon(Symbols.military_tech_rounded, size: 16, color: reached ? SenpaiColors.lanternText : SenpaiColors.muted),
            Flexible(child: Text(rank.name, style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink))),
            Text('từ ${formatPoints(rank.minPoints)} điểm', style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
          ],
        ),
        for (final perk in rank.perks) Text('• $perk', style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
      ],
    );
  }

  // ---------------------------------------------------------------- Tài khoản mới

  /// Hạn mức của tài khoản mới: số bài, ghim, video được đăng mỗi ngày và đã dùng hôm nay.
  Widget _newAccountCard(UserProfile profile) {
    final today = profile.today;
    final age = profile.accountAgeDays == 0 ? 'hôm nay' : '${profile.accountAgeDays} ngày trước';
    return SenpaiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            spacing: 10,
            children: [
              const IconTile(Symbols.new_releases_rounded, tone: SenpaiTone.lantern, size: 36, radius: 10),
              Expanded(child: Text('Tài khoản mới', style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink))),
              Flexible(child: SenpaiBadge('Tạo $age', tone: SenpaiTone.lantern)),
            ],
          ),
          Text(
            'Trong ${profile.newAccountDays} ngày đầu, mỗi ngày bạn đăng được tối đa ${today.maxPosts} bài viết '
            'hoặc review, ${today.maxPins} ghim mới và ${today.maxVideos} video. Giới hạn này giúp chống spam.',
            style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
          ),
          Text(
            'Hôm nay: ${today.posts}/${today.maxPosts} bài viết và review · ${today.pins}/${today.maxPins} ghim · '
            '${today.videos}/${today.maxVideos} video',
            style: SenpaiText.labelS.copyWith(color: SenpaiColors.ink),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- Các mục

  /// Nhóm mục cá nhân: tag định danh (hoặc yêu cầu đang chờ), khu vực và giai đoạn, chủ đề quan tâm,
  /// Cẩm nang của tôi, Đã lưu.
  Widget _personalGroup(ProfileController profiles, UserProfile profile) {
    final stage = ProfileStage.labelOf(profile.stage);
    final interests = profiles.chosenInterests.map((t) => t.name).join(', ');
    return SenpaiGroup(
      children: [
        if (profile.pendingTag != null)
          _row(
            Symbols.hourglass_top_rounded,
            'Yêu cầu tag ${profile.pendingTag} đang chờ duyệt',
            subtitle: 'Ảnh minh chứng tự xóa sau 14 ngày nếu chưa được duyệt.',
            tone: SenpaiTone.lantern,
            onTap: () => _open(const TagRequestScreen()),
          )
        else
          _row(
            Symbols.verified_rounded,
            'Xin tag định danh',
            subtitle: 'Thêm tag để mọi người biết bạn là ai',
            onTap: () => _open(const TagRequestScreen()),
          ),
        _row(
          Symbols.person_pin_circle_rounded,
          'Khu vực và giai đoạn',
          subtitle: '${stage ?? 'Chưa chọn giai đoạn'} · ${profile.areaName ?? 'Chưa chọn khu vực'}',
          onTap: () => _open(const AreaStageScreen()),
        ),
        if (profile.isMember) ...[
          _row(
            Symbols.interests_rounded,
            'Chủ đề quan tâm',
            subtitle: interests.isEmpty ? 'Chưa chọn' : interests,
            onTap: () => _open(const InterestScreen()),
          ),
          _row(Symbols.menu_book_rounded, 'Cẩm nang của tôi', onTap: () => _open(const MyGuidesScreen())),
        ],
        _row(Symbols.bookmarks_rounded, 'Đã lưu (${profile.savedCount})', onTap: () => _open(const SavedScreen())),
      ],
    );
  }

  /// Nhóm tài khoản: đổi (hoặc tạo) mật khẩu, đăng xuất, xóa tài khoản (chữ crit).
  Widget _accountGroup(UserProfile profile) {
    return SenpaiGroup(
      children: [
        _row(
          Symbols.password_rounded,
          profile.hasPassword ? 'Đổi mật khẩu' : 'Tạo mật khẩu',
          tone: SenpaiTone.neutral,
          onTap: () => _open(const ChangePasswordScreen()),
        ),
        _row(Symbols.logout_rounded, 'Đăng xuất', tone: SenpaiTone.neutral, onTap: _logout),
        _row(
          Symbols.delete_rounded,
          'Xóa tài khoản',
          tone: SenpaiTone.crit,
          titleColor: SenpaiColors.crit,
          onTap: () => _open(const DeleteAccountScreen()),
        ),
      ],
    );
  }

  /// `listRow(iconTile(icon, tone, 36, 10), title, sub)`: ô icon 36 bo 10, tiêu đề Title/S, dòng phụ Body/S, chevron.
  static Widget _row(
    IconData icon,
    String title, {
    String? subtitle,
    SenpaiTone tone = SenpaiTone.brand,
    Color titleColor = SenpaiColors.ink,
    required VoidCallback onTap,
  }) {
    return SenpaiListRow(
      leading: IconTile(icon, tone: tone, size: 36, radius: 10),
      title: title,
      subtitle: subtitle,
      titleStyle: SenpaiText.titleS.copyWith(color: titleColor),
      onTap: onTap,
    );
  }

  /// Mở một màn hình; quay về thì tải lại hồ sơ (điểm, khu vực, tag, số mục đã lưu có thể đã đổi).
  Future<void> _open(Widget screen, {bool reload = true}) async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
    if (reload && mounted && context.read<AuthController>().isSignedIn) {
      await context.read<ProfileController>().loadProfile();
    }
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    final auth = context.read<AuthController>();
    context.read<ProfileController>().clear();
    await auth.logout();
    navigator.popUntil((route) => route.isFirst);
  }
}
