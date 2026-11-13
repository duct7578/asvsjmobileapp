import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/home_guide_card.dart';
import 'package:myasvsj/com.myasvsj.model/home_member.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/feed_basis.dart';
import 'package:myasvsj/com.myasvsj.screen/feed_post_card.dart';
import 'package:myasvsj/com.myasvsj.screen/feed_settings_sheet.dart';
import 'package:myasvsj/com.myasvsj.screen/for_you_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/home_format.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Thẻ "Dành cho bạn" của trang chủ thành viên (ForYou của thiết kế 02): đầu thẻ auto_awesome + "Dành cho bạn"
/// + kính lúp + "Xem tất cả ›", mô tả, "Dựa trên" + "Điều chỉnh", lời nhắc chọn khu vực và giai đoạn, 5 bài Senpai ơi
/// chọn (bài đầu có đoạn trích), nút Soft "Xem tất cả bài viết dành cho bạn".
///
/// "Cẩm nang cho giai đoạn …" (không có trong thiết kế) là thẻ riêng ngay dưới: [HomeStageGuidesCard].
class HomeForYouSection extends StatelessWidget {
  const HomeForYouSection({
    super.key,
    required this.home,
    this.notice,
    this.showAreaPrompt = false,
    required this.onHidePrompt,
    required this.onSettingsSaved,
  });

  final HomeMember home;

  /// Câu báo đã lưu (sau "Điều chỉnh"); null khi không có.
  final String? notice;

  /// Hiện lời nhắc chọn khu vực và giai đoạn.
  final bool showAreaPrompt;
  final VoidCallback onHidePrompt;

  /// Màn "Khu vực và giai đoạn" hoặc "Chủ đề quan tâm" đã lưu: trang chủ tải lại.
  final VoidCallback onSettingsSaved;

  Future<void> _adjust(BuildContext context) async {
    if (await showFeedSettings(context)) {
      onSettingsSaved();
    }
  }

  Future<void> _open(BuildContext context, {required bool areaAndStage}) async {
    if (await openFeedSetting(context, areaAndStage: areaAndStage)) {
      onSettingsSaved();
    }
  }

  @override
  Widget build(BuildContext context) {
    final posts = home.forYou;
    return SenpaiCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            spacing: 8,
            children: [
              const Icon(Symbols.auto_awesome_rounded, size: 20, color: SenpaiColors.brand),
              Expanded(child: Text('Dành cho bạn', style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink))),
              if (posts.isNotEmpty) ...[
                IconButton(
                  tooltip: 'Tìm trong bài dành cho bạn',
                  style: IconButton.styleFrom(
                    foregroundColor: SenpaiColors.brandText,
                    minimumSize: const Size(32, 32),
                    fixedSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Symbols.search_rounded, size: 20),
                  onPressed: () => pushScreen<void>(context, const ForYouScreen(autofocusSearch: true)),
                ),
                LinkText(
                  'Xem tất cả',
                  trailingChevron: true,
                  onTap: () => pushScreen<void>(context, const ForYouScreen()),
                ),
              ],
            ],
          ),
          Text(
            'Bài viết và cẩm nang chọn riêng cho bạn, theo khu vực, giai đoạn và chủ đề bạn quan tâm.',
            style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
          ),
          FeedBasis(
            areaName: home.areaName,
            stage: home.stage,
            interests: home.interests,
            chosenInterests: home.chosenInterests,
            onAdjust: () => _adjust(context),
          ),
          if (notice != null)
            Row(
              spacing: 6,
              children: [
                const Icon(Symbols.check_circle_rounded, size: 20, color: SenpaiColors.ok),
                Expanded(child: Text(notice!, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.ok))),
              ],
            ),
          if (showAreaPrompt) _prompt(context),
          if (posts.isEmpty)
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text('Chưa có bài viết phù hợp. Hãy xem thêm ở Blog.',
                    style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
                LinkText('Mở Blog', onTap: () => pushScreen<void>(context, const BlogListScreen())),
              ],
            )
          else ...[
            for (var i = 0; i < posts.length; i++) FeedPostCard(post: posts[i], showExcerpt: i == 0, compact: true),
            SenpaiButton(
              label: 'Xem tất cả bài viết dành cho bạn',
              icon: Symbols.arrow_forward_rounded,
              kind: SenpaiButtonKind.soft,
              size: SenpaiButtonSize.medium,
              expand: true,
              onPressed: () => pushScreen<void>(context, const ForYouScreen()),
            ),
          ],
        ],
      ),
    );
  }

  /// Lời nhắc nhẹ, mở cho tới khi đã chọn đủ khu vực và giai đoạn, hoặc bấm "Để sau": hộp brand-soft bo 16.
  Widget _prompt(BuildContext context) {
    final where = switch (home.stage) {
      'PRE' => 'bạn sắp đến',
      'HOME' => 'bạn từng sống',
      _ => 'bạn đang sinh sống',
    };
    return Container(
      key: const ValueKey('area-prompt'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: SenpaiColors.brandSoft, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              const Icon(Symbols.location_on_rounded, size: 20, color: SenpaiColors.brandText),
              Expanded(
                child: Text('Mong bạn cho Senpai ơi biết khu vực $where',
                    style: SenpaiText.titleS.copyWith(color: SenpaiColors.brandText)),
              ),
            ],
          ),
          Text(
            'Để Senpai ơi gợi ý đúng những gì gần bạn nhất: việc cần làm, review và sự kiện quanh đó. Chỉ lưu khu vực '
            '(quận, thành phố), không lưu địa chỉ hay vị trí; chỉ mình bạn thấy.',
            style: SenpaiText.bodyS.copyWith(color: SenpaiColors.ink),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SenpaiButton(
                label: 'Chọn khu vực và giai đoạn',
                size: SenpaiButtonSize.medium,
                onPressed: () => _open(context, areaAndStage: true),
              ),
              SenpaiButton(
                label: 'Chủ đề quan tâm',
                kind: SenpaiButtonKind.secondary,
                size: SenpaiButtonSize.medium,
                onPressed: () => _open(context, areaAndStage: false),
              ),
              SenpaiButton(
                label: 'Để sau',
                kind: SenpaiButtonKind.ghost,
                size: SenpaiButtonSize.medium,
                onPressed: onHidePrompt,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Cẩm nang cho giai đoạn …": tối đa 3 cẩm nang chưa xong của giai đoạn, đang làm dở trước. Thẻ trắng bo 20 như
/// các khối khác của trang chủ; mỗi cẩm nang là ô surface-2 bo 14.
class HomeStageGuidesCard extends StatelessWidget {
  const HomeStageGuidesCard({super.key, required this.stage, required this.guides});

  /// Mã giai đoạn ("ARR").
  final String stage;
  final List<HomeGuideCard> guides;

  @override
  Widget build(BuildContext context) {
    return SenpaiCard(
      radius: 20,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          SectionHead(
            'Cẩm nang cho giai đoạn ${stageName(stage)}',
            icon: Symbols.menu_book_rounded,
            action: 'Xem tất cả',
            onAction: () => pushScreen<void>(context, GuideListScreen(stage: stage)),
          ),
          for (final guide in guides) _GuideCard(guide: guide),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.guide});

  final HomeGuideCard guide;

  @override
  Widget build(BuildContext context) {
    final caption = SenpaiText.caption.copyWith(color: SenpaiColors.muted);
    return SenpaiCard(
      color: SenpaiColors.surface2,
      borderColor: null,
      radius: 14,
      padding: const EdgeInsets.all(12),
      onTap: () => pushScreen<void>(context, GuideDetailScreen(guideId: guide.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 6,
        children: [
          SenpaiBadge(
            guide.inProgress ? 'Đang làm dở' : 'Hợp giai đoạn của bạn',
            tone: guide.inProgress ? SenpaiTone.lantern : SenpaiTone.brand,
            icon: guide.inProgress ? Symbols.pending_actions_rounded : Symbols.flag_rounded,
          ),
          Text(guide.title,
              maxLines: 2, overflow: TextOverflow.ellipsis, style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
          if ((guide.excerpt ?? '').isNotEmpty)
            Text(guide.excerpt!,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
          Row(
            spacing: 8,
            children: [
              if ((guide.topicName ?? '').isNotEmpty)
                Flexible(child: TopicChip(guide.topicName!)),
              if (guide.checklist) ...[
                Expanded(child: SenpaiProgressBar(value: guide.percent.clamp(0, 100) / 100, height: 6)),
                Text('${guide.tasksDone}/${guide.tasksTotal} việc', style: caption),
              ] else
                Text('Chưa đọc', style: caption),
            ],
          ),
        ],
      ),
    );
  }
}
