import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/interest_controller.dart';
import 'package:myasvsj/com.myasvsj.model/interest_topic.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_bottom_action.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_sign_in_prompt.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_user_watcher.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// "Chủ đề quan tâm" (màn 39 của thiết kế): chọn tối đa 5 chủ đề blog để "Dành cho bạn" gợi ý bài của các chủ
/// đề này trước. Mỗi chủ đề là một chip có icon; chủ đề server học được từ những gì người dùng hay đọc mang icon
/// "lịch sử". Bấm "Lưu" ở thanh dưới: lưu xong thì đóng và trả về true.
class InterestScreen extends StatefulWidget {
  const InterestScreen({super.key});

  @override
  State<InterestScreen> createState() => _InterestScreenState();
}

class _InterestScreenState extends State<InterestScreen> with ProfileUserWatcher {
  /// Icon theo tên chủ đề blog (bảng `blog_topics` của web); chủ đề mới chưa có icon riêng thì dùng "sell".
  static const _topicIcons = {
    'Kinh nghiệm': Symbols.lightbulb_rounded,
    'Cảnh báo lừa đảo': Symbols.gpp_maybe_rounded,
    'Thủ tục giấy tờ': Symbols.description_rounded,
    'Visa và cư trú': Symbols.badge_rounded,
    'Nhà ở': Symbols.home_rounded,
    'Việc làm thêm': Symbols.work_rounded,
    'Ăn uống': Symbols.restaurant_rounded,
    'Đi lại': Symbols.train_rounded,
    'Học tiếng Nhật': Symbols.translate_rounded,
    'Y tế': Symbols.local_hospital_rounded,
    'Mua sắm': Symbols.shopping_bag_rounded,
    'Ngân hàng và tiền': Symbols.account_balance_rounded,
    'Sau khi về nước': Symbols.flight_land_rounded,
    'Khác': Symbols.more_horiz_rounded,
  };

  @override
  void onUserChanged(int? userId) {
    if (userId != null) {
      context.read<InterestController>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    watchUser(user?.id);
    final interests = context.watch<InterestController>();
    final ready = user != null && !interests.isLoading && interests.error == null;
    return Scaffold(
      appBar: const SenpaiAppBar(title: 'Chủ đề quan tâm'),
      body: user == null ? const ProfileSignInPrompt(text: 'Đăng nhập để chọn chủ đề bạn quan tâm.') : _body(interests),
      bottomNavigationBar: ready
          ? ProfileBottomAction(
              error: interests.saveError,
              button: SenpaiButton(
                label: interests.isSaving ? 'Đang lưu…' : 'Lưu',
                onPressed: interests.isSaving ? null : () => _save(interests),
                expand: true,
              ),
            )
          : null,
    );
  }

  Widget _body(InterestController interests) {
    if (interests.isLoading) {
      return const LoadingView();
    }
    if (interests.error != null) {
      return ErrorView(message: interests.error!, onRetry: interests.load);
    }
    final blocks = <Widget>[
      Text('Không bắt buộc. Chỉ mình bạn thấy.', style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
      SenpaiNote(
        'Chọn tối đa ${interests.max} chủ đề. Bài thuộc các chủ đề này được gợi ý trước trong “Dành cho bạn”. '
        'Đã chọn ${interests.selectedIds.length}/${interests.max}.',
        icon: Symbols.auto_awesome_rounded,
        tone: SenpaiTone.brand,
      ),
      Wrap(spacing: 8, runSpacing: 8, children: [for (final topic in interests.topics) _chip(interests, topic)]),
      if (interests.hasSuggestions)
        Row(
          spacing: 8,
          children: [
            const Icon(Symbols.history_rounded, size: 18, color: SenpaiColors.muted),
            Expanded(
              child: Text(
                'Gợi ý: chủ đề bạn hay đọc, thích hoặc lưu gần đây.',
                style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
              ),
            ),
          ],
        ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          blocks[i],
        ],
      ],
    );
  }

  /// Chip chủ đề (theme: cao 36, tròn, chọn thì nền brand chữ trắng) có icon 18 phía trước. Chủ đề gợi ý chưa
  /// chọn mang icon "lịch sử", như trên web. Đã chọn đủ thì các chip còn lại mờ đi và bị khóa.
  Widget _chip(InterestController interests, InterestTopic topic) {
    final selected = interests.isSelected(topic.id);
    final blocked = interests.isFull && !selected;
    final icon = topic.learnt && !selected ? Symbols.history_rounded : (_topicIcons[topic.name] ?? Symbols.sell_rounded);
    final chip = FilterChip(
      label: Text(topic.name),
      selected: selected,
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: Icon(icon, size: 18, color: selected ? SenpaiColors.onBrand : SenpaiColors.ink),
      onSelected: blocked || interests.isSaving ? null : (_) => interests.toggle(topic.id),
    );
    return blocked
        ? Tooltip(
            message: 'Đã chọn đủ ${interests.max} chủ đề',
            child: Opacity(opacity: 0.5, child: chip),
          )
        : chip;
  }

  Future<void> _save(InterestController interests) async {
    final saved = await interests.save();
    if (saved && mounted) {
      showMessage(context, interests.takeMessage());
      Navigator.pop(context, true);
    }
  }
}
