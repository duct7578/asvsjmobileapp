import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/search_event.dart';
import 'package:myasvsj/com.myasvsj.model/search_faq.dart';
import 'package:myasvsj/com.myasvsj.model/search_guide.dart';
import 'package:myasvsj/com.myasvsj.model/search_phrase.dart';
import 'package:myasvsj/com.myasvsj.model/search_place.dart';
import 'package:myasvsj/com.myasvsj.model/search_post.dart';
import 'package:myasvsj/com.myasvsj.model/search_question.dart';
import 'package:myasvsj/com.myasvsj.model/search_result.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/event_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/event_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/faq_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/for_you_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/guide_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/home_format.dart';
import 'package:myasvsj/com.myasvsj.screen/home_speak_button.dart';
import 'package:myasvsj/com.myasvsj.screen/home_tag_chips.dart';
import 'package:myasvsj/com.myasvsj.screen/map_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/place_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/search_badge.dart';
import 'package:myasvsj/com.myasvsj.screen/search_highlight.dart';
import 'package:myasvsj/com.myasvsj.screen/search_hit_tile.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Kết quả "Tìm kiếm" theo từng phần (thứ tự như web): Địa điểm, Bài viết, Hỏi-Đáp, Cẩm nang, Sự kiện, Mẫu câu và
/// từ vựng, Câu hỏi thường gặp. Mỗi phần là một thẻ trắng bo 20 (5 mục đầu, chỗ khớp được tô); hàng chip cuộn ngang
/// trên cùng ("Tất cả n" rồi từng phần) nhảy tới từng phần.
class SearchResultList extends StatefulWidget {
  const SearchResultList({super.key, required this.result, this.isMember = false});

  final SearchResult result;

  /// Thành viên có thêm "Chỉ tìm trong bài dành cho bạn".
  final bool isMember;

  @override
  State<SearchResultList> createState() => _SearchResultListState();
}

/// Một phần của kết quả: khóa, tên, biểu tượng, số mục.
typedef _Group = ({String key, String title, IconData icon, int total});

class _SearchResultListState extends State<SearchResultList> {
  final Map<String, GlobalKey> _keys = {};
  final _scroll = ScrollController();

  GlobalKey _keyOf(String group) => _keys.putIfAbsent(group, GlobalKey.new);

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _jump(String group) {
    final target = _keys[group]?.currentContext;
    if (target != null) {
      Scrollable.ensureVisible(target, duration: const Duration(milliseconds: 300));
    }
  }

  void _top() {
    if (_scroll.hasClients) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  /// Lề ngang 16 của thân trang (hàng chip cuộn ngang thì tràn tới mép màn hình).
  static Widget _side(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    final q = r.q;
    final List<_Group> groups = [
      (key: 'places', title: 'Địa điểm', icon: Symbols.location_on_rounded, total: r.places.total),
      (key: 'posts', title: 'Bài viết', icon: Symbols.forum_rounded, total: r.posts.total),
      (key: 'questions', title: 'Hỏi-Đáp', icon: Symbols.contact_support_rounded, total: r.questions.total),
      (key: 'guides', title: 'Cẩm nang', icon: Symbols.menu_book_rounded, total: r.guides.total),
      (key: 'events', title: 'Sự kiện', icon: Symbols.celebration_rounded, total: r.events.total),
      (key: 'phrases', title: 'Mẫu câu và từ vựng', icon: Symbols.translate_rounded, total: r.phrases.total),
      (key: 'faqs', title: 'Câu hỏi thường gặp', icon: Symbols.quiz_rounded, total: r.faqs.total),
    ].where((g) => g.total > 0).toList();

    final blocks = <Widget>[
      _side(Text('Tìm thấy ${r.total} kết quả cho “$q”.', style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted))),
      if (groups.length > 1)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            spacing: 8,
            children: [
              ChoiceChip(
                showCheckmark: false,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label: Text('Tất cả ${r.total}'),
                selected: true,
                onSelected: (_) => _top(),
              ),
              for (final g in groups)
                ChoiceChip(
                  showCheckmark: false,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: Text('${g.title} ${g.total}'),
                  selected: false,
                  onSelected: (_) => _jump(g.key),
                ),
            ],
          ),
        ),
      for (final g in groups) _side(_section(context, g, q)),
      if (r.places.isEmpty)
        _side(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(
                'Không thấy địa điểm cần tìm? Bản đồ có cả địa điểm của OpenStreetMap.',
                style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
              ),
              LinkText(
                'Mở Bản đồ',
                icon: Symbols.map_rounded,
                onTap: () => pushScreen<void>(context, const MapScreen()),
              ),
            ],
          ),
        ),
    ];

    return SingleChildScrollView(
      controller: _scroll,
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < blocks.length; i++) ...[if (i > 0) const SizedBox(height: 14), blocks[i]],
        ],
      ),
    );
  }

  /// Thẻ của một phần: đầu thẻ (ô icon 28 bo 8, tên Title/M, badge số mục), các kết quả cách nhau đường kẻ, rồi
  /// các link "Xem tất cả … →".
  Widget _section(BuildContext context, _Group g, String q) {
    final r = widget.result;
    final (List<Widget> items, List<Widget> links) = switch (g.key) {
      'places' => (
        [for (final p in r.places.items) _place(context, p, q)],
        [_link(context, 'Mở Bản đồ (có cả địa điểm OpenStreetMap)', const MapScreen())],
      ),
      'posts' => (
        [for (final p in r.posts.items) _post(context, p, q)],
        [
          if (r.posts.hasMore)
            _link(context, 'Xem tất cả ${r.posts.total} bài viết trong Blog', const BlogListScreen()),
          if (widget.isMember)
            _link(context, 'Chỉ tìm trong bài dành cho bạn', ForYouScreen(initialQuery: q), icon: Symbols.auto_awesome_rounded),
        ],
      ),
      'questions' => (
        [for (final x in r.questions.items) _question(context, x, q)],
        [
          if (r.questions.hasMore)
            _link(context, 'Xem tất cả ${r.questions.total} câu hỏi trong Hỏi-Đáp', QuestionListScreen(initialQuery: q)),
        ],
      ),
      'guides' => (
        [for (final x in r.guides.items) _guide(context, x, q)],
        [if (r.guides.hasMore) _link(context, 'Xem tất cả ${r.guides.total} bài cẩm nang', const GuideListScreen())],
      ),
      'events' => (
        [for (final x in r.events.items) _event(context, x, q)],
        [if (r.events.hasMore) _link(context, 'Xem tất cả ${r.events.total} sự kiện', const EventListScreen())],
      ),
      'phrases' => (
        [for (final x in r.phrases.items) _phrase(context, x, q)],
        [
          if (r.phrases.hasMore)
            _link(context, 'Xem tất cả ${r.phrases.total} mẫu câu và từ vựng trong Nhật ngữ', PhraseScreen(initialQuery: q)),
        ],
      ),
      _ => (
        [for (final x in r.faqs.items) _faq(context, x, q)],
        [
          if (r.faqs.hasMore)
            _link(context, 'Xem tất cả ${r.faqs.total} câu hỏi thường gặp', QuestionListScreen(initialTab: 1, initialQuery: q)),
        ],
      ),
    };
    return SenpaiCard(
      key: _keyOf(g.key),
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 8,
            children: [
              IconTile(g.icon, size: 28, radius: 8),
              Expanded(child: Text(g.title, style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink))),
              SenpaiBadge('${g.total}', tone: SenpaiTone.neutral),
            ],
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            items[i],
          ],
          ...links,
        ],
      ),
    );
  }

  /// Link cuối thẻ: chữ Label/M brand-text + mũi tên 18, p[8,0,10,0].
  Widget _link(BuildContext context, String label, Widget screen, {IconData icon = Symbols.arrow_forward_rounded}) =>
      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: LinkText(label, trailingIcon: icon, onTap: () => pushScreen<void>(context, screen)),
        ),
      );

  Widget _meta(List<Widget> children) =>
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: children),
      );

  Widget _small(String text, {Color color = SenpaiColors.muted}) =>
      Text(text, style: SenpaiText.caption.copyWith(color: color));

  Widget? _excerpt(String text, String q) => text.isEmpty
      ? null
      : SearchHighlight(text: text, query: q, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted), maxLines: 2);

  Widget _place(BuildContext context, SearchPlace p, String q) {
    final where = areaRoman(p.areaName);
    final sub = [?p.otherName, if ((p.address ?? '').isNotEmpty) p.address!].join(' · ');
    return SearchHitTile(
      icon: categoryIcon(p.categoryIcon),
      title: SearchHighlight(text: p.name, query: q, maxLines: 2),
      onTap: () => pushScreen<void>(context, PlaceDetailScreen(placeId: p.id)),
      children: [
        ?_excerpt(sub, q),
        _meta([
          if (p.categoryName.isNotEmpty) SearchBadge(text: p.categoryName, tone: SenpaiTone.ai),
          p.reviewCount > 0
              ? _small('★ ${p.rating ?? ''} · ${p.reviewCount} review', color: SenpaiColors.lanternText)
              : _small('Chưa có review'),
          if (where.isNotEmpty) _small(where),
          if (p.closed) const SearchBadge(text: 'Đã đóng cửa', tone: SenpaiTone.crit),
        ]),
      ],
    );
  }

  Widget _post(BuildContext context, SearchPost b, String q) => SearchHitTile(
    title: SearchHighlight(text: b.title, query: q, maxLines: 2),
    onTap: () => pushScreen<void>(context, BlogDetailScreen(blogId: b.id)),
    children: [
      ?_excerpt(b.excerpt, q),
      _meta([
        if (b.isProcessing) const SearchBadge(text: 'Đang kiểm duyệt', warn: true),
        if (b.topicNames.isNotEmpty) SearchBadge(text: b.topicNames.first, tone: SenpaiTone.brand),
        _small(
          [
            b.authorName,
            if (b.createdAt != null) formatTimeAgo(b.createdAt!),
            '♥ ${b.likeCount}',
            '${b.commentCount} bình luận',
          ].join(' · '),
        ),
        if (b.authorTags.isNotEmpty) HomeTagChips(tags: b.authorTags),
      ]),
    ],
  );

  Widget _question(BuildContext context, SearchQuestion x, String q) => SearchHitTile(
    title: SearchHighlight(text: x.title, query: q, maxLines: 2),
    onTap: () => pushScreen<void>(context, QuestionDetailScreen(questionId: x.id)),
    children: [
      ?_excerpt(x.excerpt, q),
      _meta([
        if (x.isProcessing) const SearchBadge(text: 'Đang kiểm duyệt', warn: true),
        if (x.solved)
          const SearchBadge(text: 'Đã giải quyết', tone: SenpaiTone.ok, icon: Symbols.check_circle_rounded)
        else if (x.unanswered)
          const SearchBadge(text: 'Chưa ai trả lời', warn: true),
        if (x.topicNames.isNotEmpty) SearchBadge(text: x.topicNames.first, tone: SenpaiTone.brand),
        _small([x.authorName, if (x.createdAt != null) formatTimeAgo(x.createdAt!), '${x.answerCount} trả lời'].join(' · ')),
      ]),
    ],
  );

  Widget _guide(BuildContext context, SearchGuide g, String q) {
    // Cẩm nang không có chủ đề riêng thì server trả giai đoạn làm chủ đề: chỉ ghi một lần
    final where = {g.stageName, g.topicName}.whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    return SearchHitTile(
      title: SearchHighlight(text: g.title, query: q, maxLines: 2),
      onTap: () => pushScreen<void>(context, GuideDetailScreen(guideId: g.id)),
      children: [?_excerpt(g.summary, q), if (where.isNotEmpty) _meta([_small(where)])],
    );
  }

  Widget _event(BuildContext context, SearchEvent e, String q) {
    final state = switch (e.state) {
      'NOW' => 'Đang diễn ra',
      'PAST' => 'Đã qua',
      _ => 'Còn ${e.daysUntil} ngày',
    };
    final range = e.startDate == e.endDate
        ? formatDate(e.startDate)
        : '${formatDate(e.startDate)} – ${formatDate(e.endDate)}';
    return SearchHitTile(
      title: SearchHighlight(text: e.title, query: q, maxLines: 2),
      onTap: () => pushScreen<void>(context, EventDetailScreen(eventId: e.id)),
      children: [
        SearchHighlight(
          text: (e.locationName ?? '').isEmpty ? 'Chưa gắn vị trí' : e.locationName!,
          query: q,
          style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
          maxLines: 2,
        ),
        _meta([
          SearchBadge(
            text: state,
            warn: e.state == 'PAST',
            tone: e.state == 'NOW' ? SenpaiTone.ok : SenpaiTone.lantern,
          ),
          _small(range),
        ]),
      ],
    );
  }

  Widget _phrase(BuildContext context, SearchPhrase p, String q) => SearchHitTile(
    title: SearchHighlight(text: p.japanese, query: q),
    onTap: () => pushScreen<void>(context, PhraseScreen(initialQuery: p.japanese)),
    trailing: HomeSpeakButton(text: p.japanese, compact: true),
    children: [
      if (p.romaji.isNotEmpty)
        SearchHighlight(text: p.romaji, query: q, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.lanternText)),
      SearchHighlight(text: p.meaningVi, query: q, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.ink)),
      _meta([
        SearchBadge(text: p.isVocab ? 'Từ vựng' : 'Mẫu câu', tone: SenpaiTone.brand),
        if ((p.categoryName ?? '').isNotEmpty) _small(p.categoryName!),
      ]),
    ],
  );

  Widget _faq(BuildContext context, SearchFaq f, String q) => SearchHitTile(
    title: SearchHighlight(text: f.question, query: q, maxLines: 2),
    onTap: () => pushScreen<void>(context, FaqScreen(faqId: f.id)),
    children: [?_excerpt(f.answer, q), if ((f.topicName ?? '').isNotEmpty) _meta([_small(f.topicName!)])],
  );
}
