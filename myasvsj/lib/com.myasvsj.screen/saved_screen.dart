import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/saved_controller.dart';
import 'package:myasvsj/com.myasvsj.model/saved_blog.dart';
import 'package:myasvsj/com.myasvsj.model/saved_guide.dart';
import 'package:myasvsj/com.myasvsj.model/saved_item.dart';
import 'package:myasvsj/com.myasvsj.model/saved_kind.dart';
import 'package:myasvsj/com.myasvsj.model/saved_place.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/empty_view.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/place_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_sign_in_prompt.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_user_watcher.dart';
import 'package:myasvsj/com.myasvsj.screen/question_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// "Đã lưu" (màn 37 của thiết kế): địa điểm, bài viết, câu hỏi và cẩm nang đã lưu, mỗi loại một tab có số mục,
/// mới lưu trước. Mỗi mục là một thẻ trắng bo 18; bấm để mở. Nút tròn "Bỏ lưu" gỡ mục ngay (lỗi thì mục quay lại)
/// và SnackBar cho "Hoàn tác".
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> with ProfileUserWatcher {
  /// Tên tab, biểu tượng và câu "chưa có" của từng loại, như trang web.
  static const _titles = {
    SavedKind.place: 'Địa điểm',
    SavedKind.post: 'Bài viết',
    SavedKind.question: 'Câu hỏi',
    SavedKind.guide: 'Cẩm nang',
  };
  static const _icons = {
    SavedKind.place: Symbols.location_on_rounded,
    SavedKind.post: Symbols.article_rounded,
    SavedKind.question: Symbols.contact_support_rounded,
    SavedKind.guide: Symbols.menu_book_rounded,
  };
  static const _empty = {
    SavedKind.place: 'Chưa lưu địa điểm nào.',
    SavedKind.post: 'Chưa lưu bài nào.',
    SavedKind.question: 'Chưa lưu câu hỏi nào.',
    SavedKind.guide: 'Chưa lưu cẩm nang nào.',
  };

  /// Biểu tượng loại địa điểm (tên Material Symbols trong bảng `place_categories`).
  static const _placeIcons = {
    'local_convenience_store': Symbols.local_convenience_store_rounded,
    'restaurant': Symbols.restaurant_rounded,
    'train': Symbols.train_rounded,
    'shopping_cart': Symbols.shopping_cart_rounded,
    'account_balance': Symbols.account_balance_rounded,
    'local_hospital': Symbols.local_hospital_rounded,
    'local_post_office': Symbols.local_post_office_rounded,
    'local_pharmacy': Symbols.local_pharmacy_rounded,
    'school': Symbols.school_rounded,
    'local_laundry_service': Symbols.local_laundry_service_rounded,
    'park': Symbols.park_rounded,
    'temple_buddhist': Symbols.temple_buddhist_rounded,
    'smartphone': Symbols.smartphone_rounded,
    'home_work': Symbols.home_work_rounded,
  };

  @override
  void onUserChanged(int? userId) {
    final saved = context.read<SavedController>();
    // Bỏ danh sách cũ (có thể của người khác) rồi tải của người đang đăng nhập
    saved.clear();
    if (userId != null) {
      saved.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    watchUser(user?.id);
    final saved = context.watch<SavedController>();
    return DefaultTabController(
      length: SavedKind.values.length,
      child: Scaffold(
        appBar: SenpaiAppBar(
          title: 'Đã lưu',
          bottom: user == null
              ? null
              : TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  // tabsScroll(): chữ cách nhau 22, hàng tab lùi 16 như lề màn hình
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 11),
                  tabs: [
                    for (final kind in SavedKind.values)
                      Tab(
                        // + chỉ báo 3 = 44 như thiết kế
                        height: 41,
                        text: saved.saved.countOf(kind) == 0
                            ? _titles[kind]
                            : '${_titles[kind]} (${saved.saved.countOf(kind)})',
                      ),
                  ],
                ),
        ),
        body: user == null
            ? const ProfileSignInPrompt(text: 'Đăng nhập để xem địa điểm, bài viết, câu hỏi và cẩm nang bạn đã lưu.')
            : _body(saved),
      ),
    );
  }

  Widget _body(SavedController saved) {
    if (!saved.isLoaded) {
      if (saved.error != null && !saved.isLoading) {
        return ErrorView(message: saved.error!, onRetry: saved.load);
      }
      return const LoadingView();
    }
    return TabBarView(
      children: [
        for (final kind in SavedKind.values)
          RefreshIndicator(
            onRefresh: saved.load,
            child: saved.saved.countOf(kind) == 0
                ? ListView(
                    children: [EmptyView(text: _empty[kind]!, icon: _icons[kind]!)],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: saved.saved.countOf(kind),
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _item(saved.saved.itemsOf(kind)[i]),
                  ),
          ),
      ],
    );
  }

  Widget _item(SavedItem item) => switch (item) {
    SavedPlace place => _placeCard(place),
    SavedBlog blog => _blogCard(blog),
    SavedGuide guide => _guideCard(guide),
    _ => const SizedBox.shrink(),
  };

  /// Nút tròn 32 nền brand-soft, icon bookmark_remove brand-text.
  Widget _unsaveButton(SavedItem item) => IconButton(
    tooltip: 'Bỏ lưu',
    onPressed: () => _unsave(item),
    style: IconButton.styleFrom(
      backgroundColor: SenpaiColors.brandSoft,
      foregroundColor: SenpaiColors.brandText,
      fixedSize: const Size(32, 32),
      minimumSize: const Size(32, 32),
      padding: EdgeInsets.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    icon: const Icon(Symbols.bookmark_remove_rounded, size: 18),
  );

  /// Thẻ địa điểm: ô icon loại địa điểm, tên Title/S, "loại · địa chỉ" Body/S, badge "Đã đóng cửa", nút Bỏ lưu.
  Widget _placeCard(SavedPlace place) {
    final address = place.address;
    return SenpaiCard(
      radius: 18,
      onTap: () => _open(PlaceDetailScreen(placeId: place.id)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          IconTile(_placeIcons[place.icon] ?? Symbols.location_on_rounded, tone: SenpaiTone.brand),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  place.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink),
                ),
                Text(
                  [place.categoryName, if (address != null && address.isNotEmpty) address].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
                ),
                if (place.closed) const SenpaiBadge('Đã đóng cửa', tone: SenpaiTone.warn),
              ],
            ),
          ),
          _unsaveButton(place),
        ],
      ),
    );
  }

  /// `SavedPost`: badge chủ đề + thời gian bên phải, tiêu đề Title/S, tác giả Label/S, lượt thích, bình luận,
  /// nút Bỏ lưu. Câu hỏi đã giải quyết có thêm badge xanh.
  Widget _blogCard(SavedBlog blog) {
    final created = blog.createdAt;
    return SenpaiCard(
      radius: 18,
      onTap: () => _open(blog.isQuestion ? QuestionDetailScreen(questionId: blog.id) : BlogDetailScreen(blogId: blog.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Row(
            spacing: 6,
            children: [
              // Badge giữ độ rộng tự nhiên (tối đa 160), thời gian chiếm phần còn lại và căn phải
              if (blog.topics.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: SenpaiBadge(blog.topics.first.name),
                ),
              if (blog.isQuestion && blog.solved)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: const SenpaiBadge('Đã giải quyết', tone: SenpaiTone.ok, icon: Symbols.check_rounded),
                ),
              Expanded(
                child: Text(
                  created == null ? '' : formatTimeAgo(created),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
                ),
              ),
            ],
          ),
          Text(
            blog.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink),
          ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text(
                  blog.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SenpaiText.labelS.copyWith(color: SenpaiColors.muted),
                ),
              ),
              Semantics(label: 'Lượt thích', child: IconStat(Symbols.favorite_rounded, '${blog.likeCount}')),
              Semantics(
                label: blog.isQuestion ? 'Trả lời' : 'Bình luận',
                child: IconStat(Symbols.chat_bubble_rounded, '${blog.commentCount}'),
              ),
              _unsaveButton(blog),
            ],
          ),
        ],
      ),
    );
  }

  /// Thẻ cẩm nang: badge giai đoạn / chủ đề, tiêu đề Title/S, tóm tắt Body/S, "Đã lưu: …" Caption, nút Bỏ lưu.
  Widget _guideCard(SavedGuide guide) {
    final saved = guide.savedAt;
    final summary = guide.summary;
    return SenpaiCard(
      radius: 18,
      onTap: () => _open(GuideDetailScreen(guideId: guide.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          if (guide.stageName.isNotEmpty || guide.topicName.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (guide.stageName.isNotEmpty) SenpaiBadge(guide.stageName, tone: SenpaiTone.ok),
                if (guide.topicName.isNotEmpty && guide.topicName != guide.stageName) SenpaiBadge(guide.topicName),
              ],
            ),
          Text(
            guide.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink),
          ),
          if (summary != null && summary.isNotEmpty)
            Text(
              summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
            ),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text(
                  saved == null ? '' : 'Đã lưu: ${formatTimeAgo(saved)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
                ),
              ),
              _unsaveButton(guide),
            ],
          ),
        ],
      ),
    );
  }

  /// Mở màn chi tiết; quay về thì tải lại, vì người dùng có thể đã bỏ lưu ở đó.
  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted && context.read<AuthController>().isSignedIn) {
      await context.read<SavedController>().load();
    }
  }

  Future<void> _unsave(SavedItem item) async {
    final saved = context.read<SavedController>();
    final messenger = ScaffoldMessenger.of(context);
    final removed = await saved.unsave(item);
    final text = saved.takeMessage();
    if (text == null) {
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          // Có nút thì SnackBar mặc định không tự tắt; ở đây vẫn cho tự tắt sau vài giây
          persist: false,
          action: removed ? SnackBarAction(label: 'Hoàn tác', onPressed: () => _undo(saved, messenger)) : null,
        ),
      );
  }

  /// Gọi được cả khi màn hình đã đóng, nên chỉ dùng Controller và ScaffoldMessenger đã lấy sẵn.
  static Future<void> _undo(SavedController saved, ScaffoldMessengerState messenger) async {
    await saved.undoUnsave();
    final text = saved.takeMessage();
    if (text != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
    }
  }
}
