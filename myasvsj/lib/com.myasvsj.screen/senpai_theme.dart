import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

/// Theme Material 3 của app theo Design System "Senpai ơi – Mobile App Redesign".
///
/// Widget Material chuẩn tự ra đúng thiết kế khi nằm dưới theme này:
/// FilledButton = nút Primary, FilledButton.tonal = Soft, OutlinedButton = Secondary, TextButton = Ghost (cỡ L,
/// cao 52, bo 14; cỡ M/S dùng [SenpaiButtonStyle]); ChoiceChip / FilterChip = Chip (cao 36, tròn, chọn thì nền
/// brand); TextField = TextField (cao 52, bo 12, viền line, focus brand 2px); Card = card (trắng, bo 16, viền line);
/// NavigationBar = BottomNav; Badge, Switch, Checkbox, Radio, TabBar, Dialog, BottomSheet, SnackBar, FAB.
abstract final class SenpaiTheme {
  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: SenpaiColors.brand,
      onPrimary: SenpaiColors.onBrand,
      primaryContainer: SenpaiColors.brandSoft,
      onPrimaryContainer: SenpaiColors.brandText,
      // secondaryContainer = brand-soft để FilledButton.tonal là nút "Soft" và chỉ báo tab NavigationBar là
      // viên thuốc hồng nhạt như thiết kế.
      secondary: SenpaiColors.ink,
      onSecondary: SenpaiColors.onBrand,
      secondaryContainer: SenpaiColors.brandSoft,
      onSecondaryContainer: SenpaiColors.brandText,
      tertiary: SenpaiColors.lantern,
      onTertiary: SenpaiColors.ink,
      tertiaryContainer: SenpaiColors.lanternSoft,
      onTertiaryContainer: SenpaiColors.lanternText,
      error: SenpaiColors.crit,
      onError: SenpaiColors.onBrand,
      errorContainer: SenpaiColors.critSoft,
      onErrorContainer: SenpaiColors.crit,
      surface: SenpaiColors.surface,
      onSurface: SenpaiColors.ink,
      onSurfaceVariant: SenpaiColors.muted,
      surfaceDim: SenpaiColors.surface2,
      surfaceBright: SenpaiColors.surface,
      surfaceContainerLowest: SenpaiColors.surface,
      surfaceContainerLow: SenpaiColors.bg,
      surfaceContainer: SenpaiColors.surface2,
      surfaceContainerHigh: SenpaiColors.surface2,
      surfaceContainerHighest: SenpaiColors.surface2,
      outline: SenpaiColors.muted,
      outlineVariant: SenpaiColors.line,
      shadow: SenpaiColors.ink,
      scrim: SenpaiColors.inkDeep,
      inverseSurface: SenpaiColors.ink,
      onInverseSurface: SenpaiColors.onBrand,
      inversePrimary: SenpaiColors.brandSoft,
      surfaceTint: Colors.transparent,
    );

    const textTheme = TextTheme(
      displayLarge: SenpaiText.displayXL,
      displayMedium: SenpaiText.displayL,
      displaySmall: SenpaiText.displayM,
      headlineLarge: SenpaiText.displayL,
      headlineMedium: SenpaiText.displayM,
      headlineSmall: SenpaiText.titleM,
      titleLarge: SenpaiText.titleM,
      titleMedium: SenpaiText.titleS,
      titleSmall: SenpaiText.labelM,
      bodyLarge: SenpaiText.bodyM,
      bodyMedium: SenpaiText.bodyM,
      bodySmall: SenpaiText.bodyS,
      labelLarge: SenpaiText.labelM,
      labelMedium: SenpaiText.labelS,
      labelSmall: SenpaiText.overline,
    );
    final colored = textTheme.apply(bodyColor: SenpaiColors.ink, displayColor: SenpaiColors.ink);

    const r12 = BorderRadius.all(Radius.circular(12));
    const r14 = BorderRadius.all(Radius.circular(14));
    const r16 = BorderRadius.all(Radius.circular(16));
    const r24 = BorderRadius.all(Radius.circular(24));

    OutlineInputBorder inputBorder(Color color, double width) =>
        OutlineInputBorder(borderRadius: r12, borderSide: BorderSide(color: color, width: width));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'BeVietnamPro',
      fontFamilyFallback: SenpaiText.fontFamilyFallback,
      textTheme: colored,
      primaryTextTheme: colored,
      scaffoldBackgroundColor: SenpaiColors.bg,
      canvasColor: SenpaiColors.bg,
      dividerColor: SenpaiColors.line,
      visualDensity: VisualDensity.standard,
      // Material Symbols là font biến thiên: thiết kế dùng cỡ quang học 24 (mặc định của Flutter là 48, nét mảnh hơn)
      iconTheme: const IconThemeData(color: SenpaiColors.ink, size: 24, opticalSize: 24),
      appBarTheme: AppBarTheme(
        backgroundColor: SenpaiColors.bg,
        foregroundColor: SenpaiColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 56,
        // Kiểu chữ của theme phải có màu: AppBar dùng nguyên kiểu này, không tự thêm foregroundColor
        titleTextStyle: SenpaiText.titleM.copyWith(color: SenpaiColors.ink),
        iconTheme: const IconThemeData(color: SenpaiColors.ink, size: 24, opticalSize: 24),
        actionsIconTheme: const IconThemeData(color: SenpaiColors.ink, size: 24, opticalSize: 24),
        actionsPadding: const EdgeInsets.only(right: 4),
      ),
      // Nút back / đóng của AppBar dùng icon Material Symbols Rounded như thiết kế.
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const Icon(Symbols.arrow_back_rounded),
        closeButtonIconBuilder: (_) => const Icon(Symbols.close_rounded),
        drawerButtonIconBuilder: (_) => const Icon(Symbols.menu_rounded),
      ),
      filledButtonTheme: FilledButtonThemeData(style: SenpaiButtonStyle._shape(SenpaiButtonSize.large)),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: SenpaiButtonStyle._shape(SenpaiButtonSize.large).copyWith(
          backgroundColor: const WidgetStatePropertyAll(SenpaiColors.surface),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.disabled) ? SenpaiColors.muted : SenpaiColors.ink,
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: SenpaiColors.line, width: 1.5)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: SenpaiButtonStyle._shape(SenpaiButtonSize.large).copyWith(
          backgroundColor: const WidgetStatePropertyAll(SenpaiColors.surface),
          foregroundColor: const WidgetStatePropertyAll(SenpaiColors.ink),
          elevation: const WidgetStatePropertyAll(0),
          side: const WidgetStatePropertyAll(BorderSide(color: SenpaiColors.line, width: 1.5)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SenpaiColors.brandText,
          textStyle: SenpaiText.labelM,
          shape: const RoundedRectangleBorder(borderRadius: r12),
          iconSize: 18,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(foregroundColor: SenpaiColors.ink)),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: SenpaiColors.brand,
        foregroundColor: SenpaiColors.onBrand,
        elevation: 3,
        focusElevation: 3,
        hoverElevation: 4,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
        extendedTextStyle: SenpaiText.labelM,
        extendedPadding: EdgeInsets.only(left: 16, right: 20),
        extendedIconLabelSpacing: 8,
      ),
      chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? SenpaiColors.brand : SenpaiColors.surface,
        ),
        side: WidgetStateBorderSide.resolveWith(
          (s) => s.contains(WidgetState.selected) ? BorderSide.none : const BorderSide(color: SenpaiColors.line),
        ),
        labelStyle: SenpaiText.labelM.copyWith(
          color: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.selected) ? SenpaiColors.onBrand : SenpaiColors.ink,
          ),
        ),
        secondaryLabelStyle: SenpaiText.labelM.copyWith(color: SenpaiColors.onBrand),
        iconTheme: const IconThemeData(color: SenpaiColors.ink, size: 18, opticalSize: 24),
        checkmarkColor: SenpaiColors.onBrand,
        deleteIconColor: SenpaiColors.muted,
        shape: const StadiumBorder(),
        // Chip của thiết kế cao 36: chữ Label/M 20 + lề trên dưới 8
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        showCheckmark: true,
        elevation: 0,
        pressElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SenpaiColors.surface,
        isDense: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        hintStyle: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted),
        labelStyle: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted),
        floatingLabelStyle: SenpaiText.labelM.copyWith(color: SenpaiColors.brandText),
        helperStyle: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
        errorStyle: SenpaiText.caption.copyWith(color: SenpaiColors.crit),
        counterStyle: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
        prefixIconColor: WidgetStateColor.resolveWith(
          (s) => s.contains(WidgetState.error)
              ? SenpaiColors.crit
              : s.contains(WidgetState.focused)
                  ? SenpaiColors.brand
                  : SenpaiColors.muted,
        ),
        suffixIconColor: SenpaiColors.muted,
        border: inputBorder(SenpaiColors.line, 1),
        enabledBorder: inputBorder(SenpaiColors.line, 1),
        disabledBorder: inputBorder(SenpaiColors.line, 1),
        focusedBorder: inputBorder(SenpaiColors.brand, 2),
        errorBorder: inputBorder(SenpaiColors.crit, 1.5),
        focusedErrorBorder: inputBorder(SenpaiColors.crit, 2),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: SenpaiColors.brand,
        selectionColor: SenpaiColors.brandSoft,
        selectionHandleColor: SenpaiColors.brand,
      ),
      cardTheme: const CardThemeData(
        color: SenpaiColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: r16, side: BorderSide(color: SenpaiColors.line)),
      ),
      dividerTheme: const DividerThemeData(color: SenpaiColors.line, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: SenpaiColors.muted,
        textColor: SenpaiColors.ink,
        titleTextStyle: SenpaiText.titleS.copyWith(color: SenpaiColors.ink),
        subtitleTextStyle: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
        leadingAndTrailingTextStyle: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        minVerticalPadding: 10,
      ),
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: SenpaiColors.muted,
        collapsedIconColor: SenpaiColors.muted,
        textColor: SenpaiColors.ink,
        collapsedTextColor: SenpaiColors.ink,
        shape: Border(),
        collapsedShape: Border(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: SenpaiColors.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: SenpaiColors.brandSoft,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelPadding: const EdgeInsets.only(top: 4),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? SenpaiText.labelM.copyWith(color: SenpaiColors.brandText)
              : SenpaiText.labelS.copyWith(color: SenpaiColors.muted, height: 20 / 12),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            opticalSize: 24,
            color: s.contains(WidgetState.selected) ? SenpaiColors.brandText : SenpaiColors.muted,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: SenpaiColors.brandText,
        unselectedLabelColor: SenpaiColors.muted,
        labelStyle: SenpaiText.labelM,
        unselectedLabelStyle: SenpaiText.labelM,
        indicatorColor: SenpaiColors.brand,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: SenpaiColors.brand, width: 3),
          borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
        ),
        dividerColor: SenpaiColors.line,
        dividerHeight: 1,
        overlayColor: const WidgetStatePropertyAll(Color(0x0FC2456E)),
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: SenpaiColors.brand,
        textColor: SenpaiColors.onBrand,
        textStyle: SenpaiText.overline,
        padding: EdgeInsets.symmetric(horizontal: 5),
        largeSize: 18,
        smallSize: 8,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(SenpaiColors.surface),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? SenpaiColors.brand : SenpaiColors.line,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
        thumbIcon: const WidgetStatePropertyAll(null),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? SenpaiColors.brand : SenpaiColors.surface,
        ),
        checkColor: const WidgetStatePropertyAll(SenpaiColors.onBrand),
        side: WidgetStateBorderSide.resolveWith(
          (s) => s.contains(WidgetState.selected) ? BorderSide.none : const BorderSide(color: SenpaiColors.muted, width: 1.5),
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? SenpaiColors.brand : SenpaiColors.muted,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: SenpaiColors.brand,
        linearTrackColor: SenpaiColors.surface2,
        circularTrackColor: Colors.transparent,
        linearMinHeight: 8,
        borderRadius: BorderRadius.all(Radius.circular(99)),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: SenpaiColors.brand,
        inactiveTrackColor: SenpaiColors.surface2,
        thumbColor: SenpaiColors.brand,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? SenpaiColors.surface : SenpaiColors.surface2,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? SenpaiColors.brandText : SenpaiColors.muted,
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: SenpaiColors.line)),
          textStyle: const WidgetStatePropertyAll(SenpaiText.labelM),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: SenpaiColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: r24),
        titleTextStyle: SenpaiText.titleM.copyWith(color: SenpaiColors.ink),
        contentTextStyle: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
        barrierColor: const Color(0x731E2A52),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: SenpaiColors.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: SenpaiColors.surface,
        elevation: 0,
        modalElevation: 0,
        modalBarrierColor: Color(0x731E2A52),
        showDragHandle: true,
        dragHandleColor: SenpaiColors.line,
        dragHandleSize: Size(40, 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        clipBehavior: Clip.antiAlias,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: SenpaiColors.ink,
        contentTextStyle: SenpaiText.bodyS.copyWith(color: SenpaiColors.onBrand),
        actionTextColor: SenpaiColors.lantern,
        shape: const RoundedRectangleBorder(borderRadius: r14),
        elevation: 0,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: SenpaiColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shape: const RoundedRectangleBorder(borderRadius: r14),
        textStyle: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
      ),
      menuTheme: const MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(SenpaiColors.surface),
          surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: r14)),
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(color: SenpaiColors.ink, borderRadius: BorderRadius.all(Radius.circular(8))),
        textStyle: TextStyle(fontFamily: 'BeVietnamPro', fontSize: 12, color: SenpaiColors.onBrand),
      ),
    );
  }
}

/// Cỡ nút của component Button: L cao 52 (mặc định của theme), M cao 44, S cao 34.
enum SenpaiButtonSize { large, medium, small }

/// Kiểu nút của component Button.
enum SenpaiButtonKind { primary, secondary, soft, ghost, danger }

/// ButtonStyle cho cỡ M / S và nút Danger, ghép với nút Material chuẩn:
/// `FilledButton(style: SenpaiButtonStyle.size(SenpaiButtonSize.medium), …)`,
/// `FilledButton(style: SenpaiButtonStyle.danger(), …)`. Thường dùng widget [SenpaiButton] cho gọn.
abstract final class SenpaiButtonStyle {
  /// Hình dáng chung theo cỡ: chiều cao, bo góc, lề ngang, kiểu chữ, cỡ icon (không đổi màu).
  static ButtonStyle size(SenpaiButtonSize size) => _shape(size);

  static ButtonStyle _shape(SenpaiButtonSize size) {
    final (double h, double px, double r, TextStyle text, double icon) = switch (size) {
      SenpaiButtonSize.large => (52, 22, 14, SenpaiText.labelM, 20),
      SenpaiButtonSize.medium => (44, 18, 12, SenpaiText.labelM, 18),
      SenpaiButtonSize.small => (34, 14, 10, SenpaiText.labelS, 16),
    };
    return ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(48, h)),
      fixedSize: WidgetStatePropertyAll(Size.fromHeight(h)),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: px)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(r))),
      textStyle: WidgetStatePropertyAll(text),
      iconSize: WidgetStatePropertyAll(icon),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
    );
  }

  /// Nút Danger (nền đỏ crit, chữ trắng) để xoá.
  static ButtonStyle danger([SenpaiButtonSize size = SenpaiButtonSize.large]) => _shape(size).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? SenpaiColors.critSoft : SenpaiColors.crit,
        ),
        foregroundColor: const WidgetStatePropertyAll(SenpaiColors.onBrand),
      );

  /// Nút Secondary (viền) đúng cỡ.
  static ButtonStyle secondary([SenpaiButtonSize size = SenpaiButtonSize.large]) => _shape(size).copyWith(
        backgroundColor: const WidgetStatePropertyAll(SenpaiColors.surface),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? SenpaiColors.muted : SenpaiColors.ink,
        ),
        side: const WidgetStatePropertyAll(BorderSide(color: SenpaiColors.line, width: 1.5)),
      );

  /// Nút Ghost (chữ brand-text, không nền) đúng cỡ.
  static ButtonStyle ghost([SenpaiButtonSize size = SenpaiButtonSize.large]) => _shape(size).copyWith(
        foregroundColor: const WidgetStatePropertyAll(SenpaiColors.brandText),
      );
}

/// Component "Button" của thiết kế. Bên trong là nút Material chuẩn nên test vẫn tìm được bằng
/// `find.widgetWithText(FilledButton, …)` / `OutlinedButton` / `TextButton`:
/// primary → FilledButton, soft → FilledButton.tonal, secondary → OutlinedButton, ghost → TextButton,
/// danger → FilledButton nền đỏ.
///
/// [expand] true thì nút giãn hết chiều ngang (như `[btn(...), 'w']` trong spec).
class SenpaiButton extends StatelessWidget {
  const SenpaiButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = SenpaiButtonKind.primary,
    this.size = SenpaiButtonSize.large,
    this.icon,
    this.expand = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final SenpaiButtonKind kind;
  final SenpaiButtonSize size;

  /// Icon đứng trước chữ (leading của component).
  final IconData? icon;
  final bool expand;

  /// true: thay icon bằng vòng quay nhỏ và khoá nút.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final callback = loading ? null : onPressed;
    final iconSize = switch (size) {
      SenpaiButtonSize.large => 20.0,
      SenpaiButtonSize.medium => 18.0,
      SenpaiButtonSize.small => 16.0,
    };
    final Widget? lead = loading
        ? SizedBox.square(dimension: iconSize - 2, child: const CircularProgressIndicator(strokeWidth: 2))
        : icon == null
            ? null
            : Icon(icon);
    final text = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    final Widget button = switch (kind) {
      SenpaiButtonKind.primary => lead == null
          ? FilledButton(style: SenpaiButtonStyle._shape(size), onPressed: callback, child: text)
          : FilledButton.icon(style: SenpaiButtonStyle._shape(size), onPressed: callback, icon: lead, label: text),
      SenpaiButtonKind.soft => lead == null
          ? FilledButton.tonal(style: SenpaiButtonStyle._shape(size), onPressed: callback, child: text)
          : FilledButton.tonalIcon(style: SenpaiButtonStyle._shape(size), onPressed: callback, icon: lead, label: text),
      SenpaiButtonKind.danger => lead == null
          ? FilledButton(style: SenpaiButtonStyle.danger(size), onPressed: callback, child: text)
          : FilledButton.icon(style: SenpaiButtonStyle.danger(size), onPressed: callback, icon: lead, label: text),
      SenpaiButtonKind.secondary => lead == null
          ? OutlinedButton(style: SenpaiButtonStyle.secondary(size), onPressed: callback, child: text)
          : OutlinedButton.icon(style: SenpaiButtonStyle.secondary(size), onPressed: callback, icon: lead, label: text),
      SenpaiButtonKind.ghost => lead == null
          ? TextButton(style: SenpaiButtonStyle.ghost(size), onPressed: callback, child: text)
          : TextButton.icon(style: SenpaiButtonStyle.ghost(size), onPressed: callback, icon: lead, label: text),
    };
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
