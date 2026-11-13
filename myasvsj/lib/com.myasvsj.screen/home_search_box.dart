import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/global_search_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/home_format.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Ô "Tìm trên Senpai ơi" của trang chủ: gõ rồi bấm "Tìm" (hoặc Enter) để mở màn Tìm kiếm với chữ đã gõ.
/// Ô trống thì không mở, con trỏ ở lại trong ô.
///
/// [hero] true: ô nằm trong thẻ chào của khách (thiết kế 01): viên thuốc trắng không viền p[6,6,6,16], chữ Body/S,
/// nút "Tìm" cỡ S màu brand luôn hiện. false: ô `search()` của trang chủ thành viên (thiết kế 02): viên thuốc cao 48
/// viền line, nút "Tìm" chỉ hiện khi đã gõ chữ.
class HomeSearchBox extends StatefulWidget {
  const HomeSearchBox({super.key, this.hero = false});

  final bool hero;

  @override
  State<HomeSearchBox> createState() => _HomeSearchBoxState();
}

class _HomeSearchBoxState extends State<HomeSearchBox> {
  static const _hint = 'Tìm địa điểm, bài viết, sự kiện…';

  final _text = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _search() {
    final q = _text.text.trim();
    if (q.isEmpty) {
      _focus.requestFocus();
      return;
    }
    _focus.unfocus();
    pushScreen<void>(context, GlobalSearchScreen(initialQuery: q));
  }

  Widget get _button => SenpaiButton(label: 'Tìm', size: SenpaiButtonSize.small, onPressed: _search);

  TextField _field({required InputDecoration decoration, TextStyle? style}) => TextField(
    key: const ValueKey('home-search'),
    controller: _text,
    focusNode: _focus,
    style: style,
    textInputAction: TextInputAction.search,
    inputFormatters: [LengthLimitingTextInputFormatter(100)],
    onChanged: widget.hero ? null : (_) => setState(() {}),
    onSubmitted: (_) => _search(),
    decoration: decoration,
  );

  @override
  Widget build(BuildContext context) {
    if (!widget.hero) {
      return _field(
        decoration: senpaiSearchDecoration(
          _hint,
          suffixIcon: _text.text.trim().isEmpty
              ? null
              : Padding(padding: const EdgeInsets.only(right: 6), child: _button),
        ).copyWith(suffixIconConstraints: const BoxConstraints(minHeight: 48)),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: const ShapeDecoration(color: SenpaiColors.surface, shape: StadiumBorder()),
      child: Row(
        spacing: 8,
        children: [
          const Icon(Symbols.search_rounded, size: 22, color: SenpaiColors.muted),
          Expanded(
            child: _field(
              style: SenpaiText.bodyS.copyWith(color: SenpaiColors.ink),
              decoration: InputDecoration(
                hintText: _hint,
                hintMaxLines: 1,
                hintStyle: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
                filled: false,
                isCollapsed: true,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          _button,
        ],
      ),
    );
  }
}
