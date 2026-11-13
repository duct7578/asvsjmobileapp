import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/home_guest.dart';
import 'package:myasvsj/com.myasvsj.model/home_quote.dart';
import 'package:myasvsj/com.myasvsj.screen/event_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/home_format.dart';
import 'package:myasvsj/com.myasvsj.screen/home_phrase_card.dart';
import 'package:myasvsj/com.myasvsj.screen/home_search_box.dart';
import 'package:myasvsj/com.myasvsj.screen/home_tag_chips.dart';
import 'package:myasvsj/com.myasvsj.screen/legal_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/map_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/phrase_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/recent_reviews_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/register_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Trang chủ của khách (màn 01 của thiết kế, câu chữ theo home.js của web): thẻ chào màu brand có ô tìm kiếm,
/// "Xem bản đồ", "Đăng ký miễn phí"; 3 ô số liệu; "Senpai nói gì" (thẻ trích dẫn cuộn ngang); lưới 2×2 "Senpai ơi
/// giúp gì cho bạn"; câu tiếng Nhật hôm nay và liên kết điều khoản.
class HomeGuestView extends StatelessWidget {
  const HomeGuestView({super.key, required this.home, this.banner});

  final HomeGuest home;

  /// Báo lỗi khi tải lại (giữ trang cũ); null khi không có.
  final Widget? banner;

  /// Lề ngang 16 của thân trang (hàng trích dẫn cuộn ngang thì tràn tới mép màn hình).
  static Widget _side(Widget child) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 20);
    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      children: [
        if (banner != null) ...[_side(banner!), const SizedBox(height: 12)],
        _side(const _Hero()),
        gap,
        _side(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                Expanded(
                  child: _Stat(value: home.placesWithReviews, label: 'địa điểm đã có review'),
                ),
                Expanded(
                  child: _Stat(value: home.reviewCount, label: 'review của người Việt'),
                ),
                Expanded(
                  child: _Stat(value: home.phraseCount, label: 'mẫu câu theo địa điểm'),
                ),
              ],
            ),
          ),
        ),
        if (home.quotes.isNotEmpty) ...[
          gap,
          _side(
            SectionHead(
              'Senpai nói gì',
              action: 'Xem thêm',
              onAction: () => pushScreen<void>(context, const RecentReviewsScreen()),
            ),
          ),
          gap,
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  for (var i = 0; i < home.quotes.length; i++)
                    _QuoteCard(quote: home.quotes[i], tone: i.isEven ? SenpaiTone.brand : SenpaiTone.ai),
                ],
              ),
            ),
          ),
        ],
        gap,
        _side(const SectionHead('Senpai ơi giúp gì cho bạn')),
        gap,
        _side(const _FeatureGrid()),
        if (home.phrase != null) ...[gap, _side(HomePhraseCard(phrase: home.phrase!))],
        gap,
        _side(const _LegalLinks()),
      ],
    );
  }
}

/// Thẻ chào "Hero": nền brand bo 24, logo hoa mờ 16% ở góc phải trên, nhãn "Cho du học sinh…", tiêu đề
/// Display/XL, đoạn giới thiệu, ô tìm kiếm, "Xem bản đồ" (Secondary), "Đăng ký miễn phí" (viền trắng), ghi chú.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final onBrand = SenpaiColors.onBrand;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: SenpaiColors.brand, borderRadius: BorderRadius.circular(24)),
      child: Stack(
        children: [
          const Positioned(
            top: -36,
            right: -24,
            child: ExcludeSemantics(child: Opacity(opacity: 0.16, child: SenpaiLogo(size: 168))),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 14,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: ShapeDecoration(
                      color: SenpaiColors.surface.withValues(alpha: 0.18),
                      shape: const StadiumBorder(),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [
                        Icon(Symbols.local_florist_rounded, size: 16, color: onBrand),
                        Flexible(
                          child: Text(
                            'Cho du học sinh Việt mới đến Nhật',
                            style: SenpaiText.labelS.copyWith(color: onBrand),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Text('Ở Nhật, bạn không đi một mình.', style: SenpaiText.displayXL.copyWith(color: onBrand)),
                Text(
                  'Các senpai đã đánh dấu sẵn chỗ ăn rẻ, ga tàu, văn phòng quận. Mở bản đồ là thấy nơi nào đã có người '
                  'Việt review, kèm câu tiếng Nhật để dùng ngay tại đó.',
                  style: SenpaiText.bodyM.copyWith(color: onBrand.withValues(alpha: 0.92)),
                ),
                const HomeSearchBox(hero: true),
                SenpaiButton(
                  label: 'Xem bản đồ',
                  icon: Symbols.map_rounded,
                  kind: SenpaiButtonKind.secondary,
                  expand: true,
                  onPressed: () => pushScreen<void>(context, const MapScreen()),
                ),
                OutlinedButton.icon(
                  style: SenpaiButtonStyle.size(SenpaiButtonSize.large).copyWith(
                    backgroundColor: const WidgetStatePropertyAll(Colors.transparent),
                    foregroundColor: WidgetStatePropertyAll(onBrand),
                    side: WidgetStatePropertyAll(BorderSide(color: onBrand, width: 1.5)),
                  ),
                  onPressed: () => pushScreen<void>(context, const RegisterScreen()),
                  icon: const Icon(Symbols.person_add_rounded),
                  label: const Text('Đăng ký miễn phí'),
                ),
                Text(
                  'Xem bản đồ, review và từ vựng không cần tài khoản.',
                  style: SenpaiText.caption.copyWith(color: onBrand.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ô số liệu: thẻ trắng bo 16 viền line p12, số Display/L màu brand, nhãn Caption muted.
class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SenpaiCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(groupDigits(value), style: SenpaiText.displayL.copyWith(color: SenpaiColors.brand)),
          ),
          Text(
            label,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
          ),
        ],
      ),
    );
  }
}

/// Thẻ trích dẫn "Senpai nói gì": trắng bo 20 viền line p16, rộng 280; dấu ngoặc kép brand, câu review Body/M,
/// ảnh đại diện chữ cái 28 + tên + tag định danh, "về (địa điểm)".
class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote, required this.tone});

  final HomeQuote quote;
  final SenpaiTone tone;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: SenpaiCard(
        radius: 20,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            const Icon(Icons.format_quote_rounded, size: 28, color: SenpaiColors.brand),
            Expanded(
              child: Text(quote.text, style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink)),
            ),
            if (quote.authorName.isNotEmpty)
              Row(
                spacing: 8,
                children: [
                  SenpaiAvatar(name: quote.authorName, size: 28, tone: tone),
                  Flexible(
                    child: Text(
                      quote.authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink),
                    ),
                  ),
                  if (quote.authorTags.isNotEmpty) Flexible(child: HomeTagChips(tags: quote.authorTags)),
                ],
              ),
            if (quote.placeName.isNotEmpty)
              Text(
                'về ${quote.placeName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lưới 2×2 "Senpai ơi giúp gì cho bạn": ô trắng bo 18 viền line p14, ô icon 40, tên Title/S, mô tả Body/S.
/// Bấm mở Bản đồ, Nhật ngữ, Hỏi-Đáp, Sự kiện.
class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, SenpaiTone tone, String title, String text, Widget screen) => SenpaiCard(
      radius: 18,
      onTap: () => pushScreen<void>(context, screen),
      // Cả 4 ô cao bằng nhau như thiết kế (200 gồm lề 14): cao tối thiểu 172, chữ dài hơn thì ô cao theo
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 172),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            IconTile(icon, tone: tone),
            Text(title, style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
            Text(text, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
          ],
        ),
      ),
    );

    final tiles = [
      tile(
        Symbols.location_on_rounded,
        SenpaiTone.brand,
        'Bản đồ có review',
        'Nơi nào đã có review sẽ nở hoa trên bản đồ.',
        const MapScreen(),
      ),
      tile(
        Symbols.school_rounded,
        SenpaiTone.ai,
        'Học tiếng Nhật theo chủ đề',
        'Thanh toán, hỏi đường, khám bệnh… học đúng câu mình sắp dùng.',
        const PhraseScreen(),
      ),
      tile(
        Symbols.contact_support_rounded,
        SenpaiTone.lantern,
        'Hỏi senpai',
        'Đặt câu hỏi, Mentor trả lời, bạn chọn câu hay nhất.',
        const QuestionListScreen(),
      ),
      tile(
        Symbols.celebration_rounded,
        SenpaiTone.ok,
        'Lễ hội gần bạn',
        'Sự kiện đang và sắp diễn ra hiện ngay trên bản đồ.',
        const EventListScreen(),
      ),
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
              children: [
                Expanded(child: tiles[i]),
                Expanded(child: tiles[i + 1]),
              ],
            ),
          ),
      ],
    );
  }
}

/// Chân trang: "Điều khoản sử dụng · Chính sách bảo mật · Quy tắc cộng đồng" Caption muted, bấm mở trang pháp lý.
class _LegalLinks extends StatelessWidget {
  const _LegalLinks();

  @override
  Widget build(BuildContext context) {
    final style = SenpaiText.caption.copyWith(color: SenpaiColors.muted);
    Widget link(String text, String type) => InkWell(
      onTap: () => pushScreen<void>(context, LegalScreen(type: type)),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(text, style: style),
      ),
    );
    final dot = Text('·', style: style);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        link('Điều khoản sử dụng', 'terms'),
        dot,
        link('Chính sách bảo mật', 'privacy'),
        dot,
        link('Quy tắc cộng đồng', 'community'),
      ],
    );
  }
}
