# Agent guide — Flutter redesign "Senpai ơi – Mobile App Redesign"

You are one of several agents restyling the Flutter app in `C:\Users\A\myasvsj` so every screen matches the Figma
redesign. The lead already built the shared foundation (theme, tokens, shared widgets, screenshot tool) and one fully
worked screen. Read this whole guide before touching code.

## 1. The project in 60 seconds

- Flutter app (Android) of the web app "Senpai ơi" for Vietnamese students in Japan. UI text is Vietnamese.
- Strict MVC with three folders: `lib/com.myasvsj.screen` (View: screens + widgets), `lib/com.myasvsj.controller`
  (ChangeNotifier via `provider`), `lib/com.myasvsj.model` (entities + XxxDao calling the REST API).
- Your job is **View only**. Do not change controllers, models, DAOs, `main.dart`, `pubspec.yaml`.
- Tests: `test/` (~1000 widget/unit tests with fake DAOs), `test/live` (skipped without server),
  `integration_test/` (real app on emulator). Flutter on PATH is **3.41.9 / Dart 3.11** — use it.
- Code comments and doc comments are written in **Vietnamese**, like the existing code. Identifiers stay English.

## 2. Sources of truth for the design

1. **Spec code** (exact values) — the JavaScript that drew the Figma file:
   - `design/spec/design-system.figma.js` — colour variables, 13 text styles, effects, helper library (part 2) and
     components (StatusBar, Button, Chip, TextField, Cover, Logo, BottomNav, TopActions).
   - `design/spec/screens-01-08.figma.js` — screens 01–08.
   - `design/spec/screens-09-43.figma.js` — screens 09–43 (helpers at the top, lines 1–362, then one block per screen;
     find yours with `grep -n "NN ·" design/spec/screens-09-43.figma.js`).
2. **Reference images** — `design/figma-export/ref/NN-<slug>.png` (390 px wide, 1:1) rendered from the spec, plus the
   HTML they were rendered from (`NN-<slug>.html`, handy to read exact paddings), and `design/figma-export/ref/index.md`.
   The first 44 px of every reference are a fake phone status bar: ignore it (Flutter shots have none).
3. Sample texts in the design ("Linh", "Gyomu Super", numbers…) are **mock data**. Real screens show real data from the
   controllers. Copy the *structure, spacing, colours, typography, icons and static labels*, not the sample values.

### Reading the spec DSL → Flutter

| Spec | Flutter |
| --- | --- |
| `F('V', {p, gap, align, just}, kids)` | `Padding` + `Column(spacing: gap, crossAxisAlignment: …, mainAxisSize: MainAxisSize.min)` |
| `F('H', …)` | `Row(spacing: gap, …)` |
| `p: 16` / `[8,16]` / `[t,r,b,l]` | `EdgeInsets.all(16)` / `symmetric(vertical: 8, horizontal: 16)` / `fromLTRB(l,t,r,b)` |
| child flag `'w'` in a Column | stretch (`crossAxisAlignment: stretch` or `SizedBox(width: double.infinity)`) |
| child flag `'g'` (or `'w'` in a Row) | `Expanded` |
| `align: 'c'` / `just: 'sb'` | `CrossAxisAlignment.center` / `MainAxisAlignment.spaceBetween` |
| `fill`, `r`, `stroke`, `sw` | `BoxDecoration(color: SenpaiColors.x, borderRadius: BorderRadius.circular(r), border: Border.all(color: …, width: sw))` |
| `shadow: true` / `'Shadow/Float'` / `'Shadow/Bar'` | `boxShadow: SenpaiColors.shadowCard` / `shadowFloat` / `shadowBar` |
| `wrap: true, rowGap` | `Wrap(spacing: gap, runSpacing: rowGap)` |
| `abs(parent, n, x, y)` | `Stack` + `Positioned(left: x, top: y)` |
| `op` / `opacity` | colour `.withValues(alpha: op)` / `Opacity` |
| `T(text, 'Title/S', 'muted', {lines: 2})` | `Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: SenpaiText.titleS.copyWith(color: SenpaiColors.muted))` |
| `I('search', 22, 'muted')` (outline icon) | `Icon(Symbols.search_rounded, size: 22, color: SenpaiColors.muted)` |
| `I('star', 16, 'lantern', true)` (filled icon) | `Icon(Icons.star_rounded, size: 16, color: SenpaiColors.lantern)` |
| `sp(h, w)` | `SizedBox(height: h, width: w)` |
| `divider()` | `Divider()` (theme: line, 1 px) |
| `screen()` + `body(s, {p:[8,16,24,16], gap:16})` | `Scaffold(body: ListView(padding: EdgeInsets.fromLTRB(16, 8, 16, 24), children: […with SizedBox gaps…]))` |
| `fitH(s, b)` | the screen is taller than 844: it is the whole scroll content |
| `nav(s, …)` | nothing — `MainScreen` already draws the bottom nav |
| `StatusBar` | nothing — system status bar |

Colour names map 1:1: `'brand-soft'` → `SenpaiColors.brandSoft`, `'surface-2'` → `SenpaiColors.surface2`,
`'ink-deep'` → `SenpaiColors.inkDeep`… Text style names map 1:1: `'Display/XL'` → `SenpaiText.displayXL`,
`'Label/S'` → `SenpaiText.labelS`, `'Caption'` → `SenpaiText.caption`, `'Overline'` → `SenpaiText.overline`,
`'JP/L'` → `SenpaiText.jpL`. Tones (`'brand'`, `'lantern'`, `'ok'`, `'warn'`, `'crit'`, `'ai'`, `'neutral'`, `'solid'`,
`'ink'`) → `SenpaiTone.brand` … (`tone.background` / `tone.foreground`).

## 3. The foundation you must use (do not edit these files)

All in `lib/com.myasvsj.screen/`. Read them once — they are short and documented.

- `senpai_colors.dart` — `SenpaiColors.*` tokens, shadows, `SenpaiTone`.
- `senpai_text.dart` — `SenpaiText.*` 13 text styles (no colour inside; add with `copyWith(color: …)`).
- `senpai_theme.dart` — `SenpaiTheme.light()` (already set in `main.dart`), `SenpaiButton`, `SenpaiButtonKind`,
  `SenpaiButtonSize`, `SenpaiButtonStyle.size()/secondary()/ghost()/danger()`.
- `senpai_ui.dart` — building blocks, one per spec helper:

| Spec helper | Widget |
| --- | --- |
| `btn(label, kind, {size, icon})` | `SenpaiButton(label:, onPressed:, kind:, size:, icon:, expand:)` (inside it is FilledButton / FilledButton.tonal / OutlinedButton / TextButton) |
| `chip(label, on, icon)` / `chips()` | `FilterChip` / `ChoiceChip` — the theme makes them the design chip (36 high, pill, selected = brand) |
| `badge(text, tone, icon)` | `SenpaiBadge(text, tone:, icon:)` |
| `outlineBadge()` | `SenpaiOutlineBadge(text, color:, icon:)` |
| `avatar(initials, size, tone)` | `SenpaiAvatar(name:, size:, tone:, imageUrl:)` |
| `iconTile(icon, tone, size, r)` | `IconTile(icon, tone:, size:, radius:)` |
| `card(o, kids)` | `SenpaiCard(child:, padding:, radius:, color:, borderColor:, shadow:, onTap:)` |
| `sectionHead(title, action, icon)` | `SectionHead(title, icon:, action:, onAction:)` |
| `linkText(t, icon)` | `LinkText(text, onTap:, icon:, trailingChevron:, trailingIcon:)` |
| `T(..., 'Overline', 'muted')` group titles | `OverlineLabel('Hôm nay')` (upper-cases for you) |
| `listRow(icon, title, sub, o)` | `SenpaiListRow(leading:, title:, subtitle:, trailing:, onTap:)` |
| `group(rows)` | `SenpaiGroup(children: […rows…])` |
| `note(icon, text, tone)` | `SenpaiNote(text, icon:, tone:)` |
| `stars(n, size)` | `StarRow(rating, size:)` |
| `progress(pct, total)` | `SenpaiProgressBar(value: 0..1)` |
| `search(ph)` (tap to open search) | `SenpaiSearchBox(hint:, onTap:, trailing:)` |
| real search input | `TextField(decoration: senpaiSearchDecoration('Tìm…', suffixIcon: …))` |
| `field(label, value)` / `textarea()` | `SenpaiLabeledField(label:, help:, child: TextField(…))` — the theme gives the 52-high, r12 input |
| `seg(items, active)` | `SenpaiSegmented(segments: [SenpaiSegment(value:, label:, icon:)], selected:, onChanged:)` |
| `tabs()` / `tabsScroll()` | `TabBar` (themed: brand indicator 3 px, Label/M) |
| `stepper(steps, cur)` | `SenpaiStepper(steps:, current:)` |
| `iconStat(ic, n)` | `IconStat(icon, text)` |
| `placeChip(name)` / `topicChip(name)` | `PlaceChip(name, onTap:)` / `TopicChip(name)` |
| `toggle(on)` / `checkbox()` / `radio()` | `Switch` / `Checkbox` (or `CheckboxListTile`) / `Radio` — themed |
| `cover(kind, w, h, r)` | `CoverArt(scene: CoverScene.forSeed(item.id), imageUrl: realUrl, width:, height:, radius:)` |
| Logo | `SenpaiLogo(size:)` |
| `appBar(title, {sub, actions, close})` | `SenpaiAppBar(title:, subtitle:, actions:, close:, bottom:)` (a real `AppBar` inside) |
| `appBar(title, {large: true, top})` (root tabs) | `SenpaiLargeAppBar(title:, overline:, actions:)` — includes `AppBarActions` |
| Home brand header | `SenpaiBrandAppBar()` |
| `fab(s, icon, label)` | `FloatingActionButton` / `FloatingActionButton.extended` (themed: brand, r18) |
| `bottomBar(s, kids)` | `Scaffold(bottomNavigationBar: SenpaiBottomBar(children: […]))` |
| `sheet()` / `overlay({sheet})` | `showModalBottomSheet` (themed: r24 top, drag handle) / `showDialog` + `AlertDialog` (themed r24) |
| sheet handle in a panel | `SheetHandle()` |
| `dot(size, color)` | `SenpaiDot(size:, color:)` |
| empty / error / loading / needs login | `EmptyView`, `ErrorView`, `LoadingView`, `AuthRequiredView` (already restyled) |

Theme notes:
- `FilledButton` = Primary (brand), `FilledButton.tonal` = Soft (brand-soft / brand-text), `OutlinedButton` = Secondary
  (**white background**, line border 1.5 — on a coloured background override `backgroundColor` to transparent),
  `TextButton` = Ghost (brand-text). All buttons of the theme are size L (52 high); for M/S use
  `style: SenpaiButtonStyle.size(SenpaiButtonSize.medium)` or `SenpaiButton(size: …)`.
- `Card` is white, r16, line border, no elevation, margin 0. `ListTile` titles are Title/S, subtitles Body/S muted.
- Scaffold background is `bg` (#FBF4F3). AppBars sit on `bg` with no elevation.
- Default `Text` style is Body/M ink. Japanese text falls back to Zen Maru Gothic automatically.

### Look at the worked example first

`lib/com.myasvsj.screen/more_screen.dart` (screen 06) and its screenshot test
`test/design_shots/more_shot_test.dart` show exactly the expected quality and style: tokens only, spec helpers mapped
to foundation widgets, guest + member variants, providers read defensively, Vietnamese doc comments.

## 4. Hard rules

1. **Only edit the files assigned to you** (and your own tests / new files). Other agents edit the other files at the
   same time. Shared files — every `senpai_*.dart`, `app_bar_actions.dart`, `main_screen.dart`, `more_screen.dart`,
   `empty_view.dart`, `error_view.dart`, `loading_view.dart`, `auth_required_view.dart`, `sign_in_gate.dart`,
   `app_message.dart`, `media_image.dart`, `date_text.dart`, `link_router.dart`, `notification_host.dart`,
   `profile_user_watcher.dart`, and shared test files `test/auth_fakes.dart`, `test/fake_api.dart` — are the lead's.
   If you need something changed there, say so in your report; meanwhile build a private widget in your own file.
   New widget files go in `lib/com.myasvsj.screen/` with your feature prefix (e.g. `blog_cover.dart`).
2. **Keep every behaviour.** All actions, navigation, dialogs, loading / error / empty / guest / signed-in states,
   pagination, pull-to-refresh, validation, snackbars, tooltips, Keys, semantics must still work exactly as before.
   Restyle and restructure the layout; do not remove features. Elements that exist in the app but not in the design:
   keep them, styled in the same design language.
3. **No new data.** Do not add controller/DAO calls or model fields. If the design shows something the model does not
   have, leave it out or use the closest real data. **Never show fake numbers or placeholder text as if real.**
   Static design labels (titles, hints, section names, button labels) should follow the design wording.
4. **Tests must stay green.** Keep public class names and constructor parameters (tests build these widgets), keep
   tooltips, keys and the Material widget *types* tests find (`FilledButton`, `OutlinedButton`, `TextButton`,
   `FilterChip`, `ChoiceChip`, `TextField`, `AppBar`, `ListTile`, `CheckboxListTile`, `BackButton`, `NavigationBar`…).
   Before changing a widget type or a visible text, grep your tests (`grep -n "widgetWithText\|byType\|text('" test/<your>_test.dart`)
   and `integration_test/app_flow_test.dart`. If the design really changes wording/structure, update the test finders
   accordingly — **never delete or weaken a behavioural assertion**, and never touch tests of other areas.
   `integration_test/app_flow_test.dart` finders (e.g. `find.widgetWithText(TextField, 'Email')`,
   `find.widgetWithText(FilledButton, 'Đăng nhập')`, `find.textContaining('Chào Minh')`) must keep matching.
5. **Tokens only.** Colours from `SenpaiColors` / `SenpaiTone`, text from `SenpaiText`. No `Colors.indigo`, no hex
   literals, no ad-hoc font sizes. (`Colors.transparent` is fine.) Avoid `Theme.of(context).colorScheme.*` in new code.
6. **Icons:** outline = `Symbols.<name>_rounded` (`import 'package:material_symbols_icons/symbols.dart';`),
   filled (the spec's 4th arg `true`) = `Icons.<name>_rounded`. Use the icon names from the spec.
7. **Images:** if the model has an image URL, show it (`MediaImage` / `CoverArt(imageUrl: …)`) in the design's size and
   radius; otherwise show the design's illustration `CoverArt(scene: CoverScene.forSeed(<id>))`.
8. **Robust layout.** Real data is longer than mock data. Nothing may overflow at 360 dp width or with long names /
   long Vietnamese text: use `Expanded` / `Flexible`, `maxLines` + `TextOverflow.ellipsis`, `Wrap`. Scrollable screens
   use `ListView` / `CustomScrollView`. Keep `RefreshIndicator`s.
9. Do not run `flutter clean`, `flutter pub get/upgrade/add`, or delete `build/` / `.dart_tool/` — other agents are
   running Flutter at the same time. If a command waits on a lock or fails with a transient file error, wait a few
   seconds and retry. No git here (folder is not a repo).
10. Dart 3.11 features are allowed (`Row/Column(spacing:)`, null-aware list elements `?x`, records, switch expressions).

## 5. Workflow for each screen

1. Read the spec block of the screen and list every element top to bottom (with sizes, paddings, colours, styles).
2. Open the reference PNG (`Read` the file) — and the HTML if you need exact numbers.
3. Read the current screen file(s), the controller API it uses, and its tests.
4. Rewrite the build methods to match the design using the foundation widgets.
5. **Screenshot it.** Add `test/design_shots/<area>_shot_test.dart` (pattern: `more_shot_test.dart`): build the screen
   with the existing fakes of your area (fake DAO + controller), signed-in member and realistic data (you may reuse
   the design's sample texts as *test* data here), wrapped with `shotApp(...)` or `shotTheme(...)` from
   `test/design_shots/shot_helper.dart`. Use `pumpShot(tester, app, height: <ref height>)` then
   `saveShot(tester, 'NN-name')`. Run:
   `flutter test test/design_shots/<area>_shot_test.dart --dart-define=SHOTS=true`
   then `Read` `design/flutter-shots/NN-name.png` and compare side by side with the reference PNG. Iterate until
   layout, spacing, colours, type, icons and radii match. Also shoot the important other states (guest, empty).
   Shot tests are skipped in a normal `flutter test` run (they need the SHOTS flag), so they never slow the suite.
6. `flutter analyze lib test` → zero issues in your files. `flutter test test/<your tests>.dart` → all pass.
   Finally run all tests of your area together.

## 6. Report back (short)

- Screens done (number + file) and what you changed; anything from the design you could not do and why.
- Shot files produced (paths) and your honest verdict per screen (matches / differs in …).
- Test results (command + pass/fail counts) and analyzer result.
- Any change you need in a lead-owned shared file.
