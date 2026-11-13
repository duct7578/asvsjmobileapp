import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/media_image.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

// Các khối dựng giao diện dùng chung của Design System "Senpai ơi – Mobile App Redesign".
// Mỗi widget ứng với một helper trong spec Figma (design/spec/*.figma.js), ghi ở đầu mô tả: badge(), avatar(),
// iconTile(), card(), sectionHead(), listRow(), group(), note(), stars(), progress(), search(), seg(), stepper()…
//
// Icon: icon viền dùng `Symbols.<tên>_rounded` (Material Symbols Rounded), icon đặc dùng `Icons.<tên>_rounded`
// (Material Icons Round), đúng hai font icon của thiết kế.

/// `badge(text, tone, icon)`: viên thuốc nhỏ p[3,8], icon 14, chữ Label/S, màu theo [tone].
class SenpaiBadge extends StatelessWidget {
  const SenpaiBadge(this.text, {super.key, this.tone = SenpaiTone.brand, this.icon});

  final String text;
  final SenpaiTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(color: tone.background, shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            if (icon != null) Icon(icon, size: 14, color: tone.foreground),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SenpaiText.labelS.copyWith(color: tone.foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `outlineBadge(text, color, icon)`: viên thuốc chỉ có viền, p[2,8].
class SenpaiOutlineBadge extends StatelessWidget {
  const SenpaiOutlineBadge(this.text, {super.key, this.color = SenpaiColors.muted, this.borderColor, this.icon});

  final String text;

  /// Màu chữ và icon.
  final Color color;

  /// Màu viền; mặc định line khi chữ là muted, còn lại cùng màu chữ.
  final Color? borderColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? (color == SenpaiColors.muted ? SenpaiColors.line : color);
    return DecoratedBox(
      decoration: ShapeDecoration(shape: StadiumBorder(side: BorderSide(color: border))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            if (icon != null) Icon(icon, size: 14, color: color),
            Flexible(
              child: Text(text,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: SenpaiText.labelS.copyWith(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

/// `avatar(initials, size, tone)`: ảnh đại diện tròn. Có [imageUrl] thì hiện ảnh thật, không thì chữ cái đầu của
/// [name] trên nền tone (chữ Display/M khi ≥ 56, Label/M khi ≥ 36, Label/S khi nhỏ hơn).
class SenpaiAvatar extends StatelessWidget {
  const SenpaiAvatar({super.key, required this.name, this.size = 40, this.tone = SenpaiTone.brand, this.imageUrl = ''});

  final String name;
  final double size;
  final SenpaiTone tone;

  /// Đường dẫn ảnh của server; rỗng khi chưa có.
  final String imageUrl;

  /// Chữ cái đầu viết hoa của [name], '?' khi rỗng.
  static String initialOf(String name) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return MediaImage(url: imageUrl, width: size, height: size, radius: size / 2);
    }
    final style = size >= 56
        ? SenpaiText.displayM
        : size >= 36
            ? SenpaiText.labelM
            : SenpaiText.labelS;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tone.background, shape: BoxShape.circle),
      child: Text(initialOf(name), style: style.copyWith(color: tone.foreground)),
    );
  }
}

/// `iconTile(icon, tone, size, r)`: ô vuông bo góc chứa icon (icon = 55% cạnh).
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.tone = SenpaiTone.brand, this.size = 40, this.radius = 12});

  final IconData icon;
  final SenpaiTone tone;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tone.background, borderRadius: BorderRadius.circular(radius)),
      child: Icon(icon, size: (size * 0.55).roundToDouble(), color: tone.foreground),
    );
  }
}

/// `card(o, kids)`: thẻ trắng bo 16, viền line, lề 14. Bấm được khi có [onTap] (gợn sóng trong viền thẻ).
///
/// Con xếp dọc thì truyền `child: Column(spacing: 10, crossAxisAlignment: CrossAxisAlignment.start, …)`.
class SenpaiCard extends StatelessWidget {
  const SenpaiCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 16,
    this.color = SenpaiColors.surface,
    this.borderColor = SenpaiColors.line,
    this.borderWidth = 1,
    this.shadow,
    this.onTap,
    this.clip = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;

  /// null: không viền.
  final Color? borderColor;
  final double borderWidth;

  /// Ví dụ [SenpaiColors.shadowCard].
  final List<BoxShadow>? shadow;
  final VoidCallback? onTap;

  /// Cắt con theo góc bo (ảnh bìa trên đầu thẻ).
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: borderColor == null ? BorderSide.none : BorderSide(color: borderColor!, width: borderWidth),
    );
    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = InkWell(onTap: onTap, customBorder: shape, child: content);
    }
    return Container(
      decoration: ShapeDecoration(color: color, shape: shape, shadows: shadow),
      // Material chỉ để cắt góc và gợn sóng: hình không có viền, nếu không viền bị vẽ hai lần ở góc bo
      child: Material(
        type: MaterialType.transparency,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        child: content,
      ),
    );
  }
}

/// `sectionHead(title, action, icon)`: tiêu đề khối Title/M, icon brand 20 phía trước, link "Xem thêm ›" bên phải.
class SectionHead extends StatelessWidget {
  const SectionHead(this.title, {super.key, this.icon, this.action, this.onAction});

  final String title;
  final IconData? icon;

  /// Chữ của link bên phải ("Xem tất cả"); cần [onAction] mới hiện.
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        if (icon != null) Icon(icon, size: 20, color: SenpaiColors.brand),
        Expanded(child: Text(title, style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink))),
        if (action != null && onAction != null) LinkText(action!, onTap: onAction, trailingChevron: true),
      ],
    );
  }
}

/// `linkText(t, icon)` / link "Xem thêm ›": chữ Label/M brand-text, bấm được.
class LinkText extends StatelessWidget {
  const LinkText(this.text, {super.key, this.onTap, this.icon, this.trailingChevron = false, this.trailingIcon});

  final String text;
  final VoidCallback? onTap;

  /// Icon 18 trước chữ.
  final IconData? icon;

  /// true: thêm chevron_right 18 sau chữ (link "Xem tất cả ›").
  final bool trailingChevron;

  /// Icon 18 sau chữ (ví dụ arrow_forward).
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final after = trailingIcon ?? (trailingChevron ? Symbols.chevron_right_rounded : null);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: trailingChevron ? 2 : 4,
      children: [
        if (icon != null) Icon(icon, size: 18, color: SenpaiColors.brandText),
        Flexible(child: Text(text, style: SenpaiText.labelM.copyWith(color: SenpaiColors.brandText))),
        if (after != null) Icon(after, size: 18, color: SenpaiColors.brandText),
      ],
    );
    if (onTap == null) {
      return row;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2), child: row),
    );
  }
}

/// Tiêu đề nhóm viết HOA kiểu Overline, màu muted ("HÔM NAY", "KHÁM PHÁ").
class OverlineLabel extends StatelessWidget {
  const OverlineLabel(this.text, {super.key, this.color = SenpaiColors.muted});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: SenpaiText.overline.copyWith(color: color));
}

/// `listRow(icon, title, sub, o)`: dòng danh sách: [leading] (thường [IconTile]), tiêu đề Title/S, dòng phụ
/// Body/S muted tối đa [subtitleLines] dòng, [trailing] (mặc định chevron_right muted 22). p[12,0], cách 12.
class SenpaiListRow extends StatelessWidget {
  const SenpaiListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.showChevron = true,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
    this.titleStyle,
    this.subtitleLines = 2,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;

  /// Thay cho chevron mặc định.
  final Widget? trailing;

  /// false: không có chevron khi [trailing] null.
  final bool showChevron;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final TextStyle? titleStyle;
  final int subtitleLines;

  @override
  Widget build(BuildContext context) {
    final trail = trailing ?? (showChevron ? const Icon(Symbols.chevron_right_rounded, size: 22, color: SenpaiColors.muted) : null);
    final row = Padding(
      padding: padding,
      child: Row(
        spacing: 12,
        children: [
          ?leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 2,
              children: [
                Text(title, style: titleStyle ?? SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    maxLines: subtitleLines,
                    overflow: TextOverflow.ellipsis,
                    style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
                  ),
              ],
            ),
          ),
          ?trail,
        ],
      ),
    );
    if (onTap == null) {
      return row;
    }
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: row);
  }
}

/// `group(rows)`: hộp trắng bo 16 viền line, lề [4,14], đường kẻ line giữa các dòng.
class SenpaiGroup extends StatelessWidget {
  const SenpaiGroup({super.key, required this.children, this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 4)});

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SenpaiCard(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, thickness: 1, color: SenpaiColors.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// `note(icon, text, tone)`: hộp ghi chú bo 14, p[10,12], icon 20 + chữ Body/S cùng màu tone (mặc định lantern).
class SenpaiNote extends StatelessWidget {
  const SenpaiNote(this.text, {super.key, this.icon = Symbols.info_rounded, this.tone = SenpaiTone.lantern, this.child});

  final String text;
  final IconData icon;
  final SenpaiTone tone;

  /// Thay cho [text] khi cần chữ nhiều kiểu (RichText…).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: tone.background, borderRadius: BorderRadius.circular(14)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Icon(icon, size: 20, color: tone.foreground),
          Expanded(
            child: DefaultTextStyle.merge(
              style: SenpaiText.bodyS.copyWith(color: tone.foreground),
              child: child ?? Text(text),
            ),
          ),
        ],
      ),
    );
  }
}

/// `stars(n, size, color)`: 5 ngôi sao đặc (Material Icons Round: star / star_half / star_border), cách 1.
class StarRow extends StatelessWidget {
  const StarRow(this.rating, {super.key, this.size = 16, this.color = SenpaiColors.lantern});

  /// Từ 0 đến 5, làm tròn tới nửa sao.
  final double rating;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 1,
      children: [
        for (var k = 1; k <= 5; k++)
          Icon(
            rating >= k
                ? Icons.star_rounded
                : rating >= k - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_border_rounded,
            size: size,
            color: color,
          ),
      ],
    );
  }
}

/// `progress(pct, total, color, track, h)`: thanh tiến độ bo tròn cao 8, nền surface-2, thanh brand.
class SenpaiProgressBar extends StatelessWidget {
  const SenpaiProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color = SenpaiColors.brand,
    this.trackColor = SenpaiColors.surface2,
  });

  /// Từ 0 đến 1.
  final double value;
  final double height;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth.isFinite ? box.maxWidth : 200.0;
        return Container(
          height: height,
          width: w,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(color: trackColor, borderRadius: BorderRadius.circular(99)),
          child: v == 0
              ? null
              : Container(
                  height: height,
                  width: (w * v).clamp(height, w),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99)),
                ),
        );
      },
    );
  }
}

/// `search(ph, o)`: ô tìm kiếm dạng viên thuốc cao 48, nền trắng viền line, icon search muted.
/// Đây là ô "giả" để bấm mở màn tìm kiếm. Ô gõ được thì dùng TextField với [senpaiSearchDecoration].
class SenpaiSearchBox extends StatelessWidget {
  const SenpaiSearchBox({
    super.key,
    required this.hint,
    this.onTap,
    this.trailing,
    this.color = SenpaiColors.surface,
    this.border = true,
    this.height = 48,
    this.shadow,
  });

  final String hint;
  final VoidCallback? onTap;

  /// Widget cuối ô (nút lọc, nút "Tìm").
  final Widget? trailing;
  final Color color;
  final bool border;
  final double height;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    final shape = StadiumBorder(side: border ? const BorderSide(color: SenpaiColors.line) : BorderSide.none);
    return Container(
      height: height,
      decoration: ShapeDecoration(color: color, shape: shape, shadows: shadow),
      child: Material(
        type: MaterialType.transparency,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.only(left: 16, right: trailing == null ? 16 : 6),
            child: Row(
              spacing: 10,
              children: [
                const Icon(Symbols.search_rounded, size: 22, color: SenpaiColors.muted),
                Expanded(
                  child: Text(hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted)),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// InputDecoration cho ô tìm kiếm gõ được: viên thuốc cao 48, icon search, viền line (focus brand 2).
InputDecoration senpaiSearchDecoration(String hint, {Widget? suffixIcon, Color fill = SenpaiColors.surface}) {
  const pill = BorderRadius.all(Radius.circular(999));
  return InputDecoration(
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    prefixIcon: const Padding(
      padding: EdgeInsets.only(left: 16, right: 10),
      child: Icon(Symbols.search_rounded, size: 22),
    ),
    prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    suffixIcon: suffixIcon,
    border: const OutlineInputBorder(borderRadius: pill, borderSide: BorderSide(color: SenpaiColors.line)),
    enabledBorder: const OutlineInputBorder(borderRadius: pill, borderSide: BorderSide(color: SenpaiColors.line)),
    focusedBorder: const OutlineInputBorder(borderRadius: pill, borderSide: BorderSide(color: SenpaiColors.brand, width: 2)),
  );
}

/// `field(label, value, o)` / `textarea(...)`: nhãn Label/M phía trên ô nhập, [help] Caption phía dưới.
/// [child] thường là TextField / TextFormField / DropdownButtonFormField dùng InputDecoration của theme.
class SenpaiLabeledField extends StatelessWidget {
  const SenpaiLabeledField({super.key, required this.label, required this.child, this.help, this.required = false});

  final String label;
  final Widget child;
  final String? help;

  /// true: thêm dấu * sau nhãn.
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Text(required ? '$label *' : label, style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink)),
        child,
        if (help != null) Text(help!, style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
      ],
    );
  }
}

/// Một lựa chọn của [SenpaiSegmented].
class SenpaiSegment<T> {
  const SenpaiSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// `seg(items, active)`: thanh chọn dạng viên thuốc nền surface-2, đoạn đang chọn nền trắng có bóng Card,
/// chữ Label/M brand-text (chưa chọn: muted).
class SenpaiSegmented<T> extends StatelessWidget {
  const SenpaiSegmented({super.key, required this.segments, required this.selected, required this.onChanged});

  final List<SenpaiSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const ShapeDecoration(color: SenpaiColors.surface2, shape: StadiumBorder()),
      child: Row(
        spacing: 4,
        children: [
          for (final s in segments)
            Expanded(
              child: _SegmentButton(
                label: s.label,
                icon: s.icon,
                selected: s.value == selected,
                onTap: () => onChanged(s.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({required this.label, required this.icon, required this.selected, required this.onTap});

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? SenpaiColors.brandText : SenpaiColors.muted;
    return Semantics(
      selected: selected,
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: ShapeDecoration(
          color: selected ? SenpaiColors.surface : null,
          shape: const StadiumBorder(),
          shadows: selected ? SenpaiColors.shadowCard : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 6,
                children: [
                  if (icon != null) Icon(icon, size: 18, color: color),
                  // Nhãn dài ("Từ vựng và mẫu câu") thu nhỏ chữ cho vừa thay vì bị cắt "…"
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(label,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: SenpaiText.labelM.copyWith(color: color)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `stepper(steps, current)`: các bước 1-2-3: bước đã xong tròn brand có dấu tích, bước hiện tại nền brand-soft
/// viền brand, bước sau nền surface-2; đường nối brand / line.
class SenpaiStepper extends StatelessWidget {
  const SenpaiStepper({super.key, required this.steps, required this.current});

  final List<String> steps;

  /// Chỉ số bước đang làm (0 là bước đầu).
  final int current;

  @override
  Widget build(BuildContext context) {
    final kids = <Widget>[];
    for (var i = 0; i < steps.length; i++) {
      final done = i < current;
      final cur = i == current;
      if (i > 0) {
        kids.add(Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Container(height: 2, color: i <= current ? SenpaiColors.brand : SenpaiColors.line),
          ),
        ));
      }
      kids.add(SizedBox(
        width: 76,
        child: Column(
          spacing: 6,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? SenpaiColors.brand
                    : cur
                        ? SenpaiColors.brandSoft
                        : SenpaiColors.surface2,
                border: cur ? Border.all(color: SenpaiColors.brand, width: 2) : null,
              ),
              child: done
                  ? const Icon(Symbols.check_rounded, size: 18, color: SenpaiColors.onBrand)
                  : Text('${i + 1}',
                      style: SenpaiText.labelM.copyWith(color: cur ? SenpaiColors.brandText : SenpaiColors.muted)),
            ),
            Text(
              steps[i],
              textAlign: TextAlign.center,
              style: SenpaiText.labelS.copyWith(color: done || cur ? SenpaiColors.brandText : SenpaiColors.muted),
            ),
          ],
        ),
      ));
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: kids);
  }
}

/// `iconStat(ic, n, color, filled)`: icon 18 + số Label/S (lượt thích, bình luận, lượt xem).
class IconStat extends StatelessWidget {
  const IconStat(this.icon, this.text, {super.key, this.color = SenpaiColors.muted, this.size = 18});

  final IconData icon;
  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [
        Icon(icon, size: size, color: color),
        Text(text, style: SenpaiText.labelS.copyWith(color: color)),
      ],
    );
  }
}

/// `placeChip(name)`: chip địa điểm viền line, icon location_on brand 16, chữ Label/S.
class PlaceChip extends StatelessWidget {
  const PlaceChip(this.name, {super.key, this.onTap, this.icon = Symbols.location_on_rounded});

  final String name;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    const shape = StadiumBorder(side: BorderSide(color: SenpaiColors.line));
    return Material(
      color: SenpaiColors.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Icon(icon, size: 16, color: SenpaiColors.brand),
              Flexible(
                child: Text(name,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: SenpaiText.labelS.copyWith(color: SenpaiColors.ink)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `topicChip(name)`: chip chủ đề nền surface-2, icon sell 14, chữ Label/S muted.
class TopicChip extends StatelessWidget {
  const TopicChip(this.name, {super.key, this.icon = Symbols.sell_rounded});

  final String name;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
      decoration: const ShapeDecoration(color: SenpaiColors.surface2, shape: StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Icon(icon, size: 14, color: SenpaiColors.muted),
          Flexible(
            child: Text(name,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: SenpaiText.labelS.copyWith(color: SenpaiColors.muted)),
          ),
        ],
      ),
    );
  }
}

/// Thanh nắm kéo của bottom sheet / bảng kết quả: 40 × 4, màu line.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(color: SenpaiColors.line, borderRadius: BorderRadius.circular(99)),
      ),
    );
  }
}

/// `bottomBar(s, kids)`: thanh hành động dính đáy màn hình: nền trắng, bóng Bar, lề [12,16,12+đáy máy,16].
/// Dùng làm `Scaffold.bottomNavigationBar`.
class SenpaiBottomBar extends StatelessWidget {
  const SenpaiBottomBar({super.key, required this.children, this.spacing = 12});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: SenpaiColors.surface, boxShadow: SenpaiColors.shadowBar),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(spacing: spacing, children: children),
        ),
      ),
    );
  }
}

/// Chấm tròn (dấu chưa đọc…).
class SenpaiDot extends StatelessWidget {
  const SenpaiDot({super.key, this.size = 10, this.color = SenpaiColors.brand});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

/// 8 cảnh minh hoạ "Cover" của Design System (assets/images/cover_*.svg), dùng thay ảnh thật khi bài / sự kiện /
/// địa điểm chưa có ảnh.
enum CoverScene {
  fuji('cover_fuji'),
  torii('cover_torii'),
  sakura('cover_sakura'),
  city('cover_city'),
  food('cover_food'),
  park('cover_park'),
  festival('cover_festival'),
  study('cover_study');

  const CoverScene(this.file);

  final String file;

  String get asset => 'assets/images/$file.svg';

  /// Chọn cảnh cố định theo một giá trị (id, tiêu đề…): cùng giá trị luôn ra cùng cảnh.
  static CoverScene forSeed(Object? seed) {
    final text = '${seed ?? ''}';
    var h = 0;
    for (final c in text.codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return values[h % values.length];
  }
}

/// `cover(kind, w, h, r)`: ảnh bìa. Có [imageUrl] thì hiện ảnh thật của server, không thì cảnh minh hoạ [scene]
/// (phủ kín khung, căn giữa, như Cover trong Figma).
class CoverArt extends StatelessWidget {
  const CoverArt({super.key, this.scene = CoverScene.sakura, this.imageUrl = '', this.width, this.height, this.radius = 0});

  final CoverScene scene;
  final String imageUrl;
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return MediaImage(url: imageUrl, width: width, height: height, radius: radius);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: SvgPicture.asset(
          scene.asset,
          fit: BoxFit.cover,
          width: width,
          height: height,
          placeholderBuilder: (_) => const ColoredBox(color: SenpaiColors.brandSoft),
        ),
      ),
    );
  }
}

/// Logo hoa anh đào (component "Logo", 40 × 40).
class SenpaiLogo extends StatelessWidget {
  const SenpaiLogo({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/logo.svg',
      width: size,
      height: size,
      placeholderBuilder: (_) => SizedBox.square(dimension: size),
    );
  }
}
