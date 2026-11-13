import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/blog_place.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Ô "Địa điểm liên quan" của form viết bài: tìm địa điểm (Senpai ơi và OpenStreetMap), bấm kết quả để gắn,
/// tối đa [max] địa điểm.
///
/// Thiết kế (màn 14): nhãn "Địa điểm liên quan (n/max)" Label/M; địa điểm đã gắn là chip `inputChip` nền brand-soft
/// (icon location_on, hoặc travel_explore với địa điểm OpenStreetMap mới) có nút bỏ; ô tìm cao 52 có icon search
/// phía trước (bấm icon để tìm, hoặc nút tìm trên bàn phím). Kết quả hiện trong hộp trắng bên dưới.
class BlogPlacePicker extends StatefulWidget {
  const BlogPlacePicker({
    super.key,
    required this.selected,
    required this.results,
    required this.onSearch,
    required this.onAdd,
    required this.onRemove,
    this.max = 5,
    this.isSearching = false,
    this.message,
    this.errorText,
  });

  final List<BlogPlace> selected;
  final List<BlogPlace> results;
  final ValueChanged<String> onSearch;
  final ValueChanged<BlogPlace> onAdd;
  final ValueChanged<BlogPlace> onRemove;
  final int max;
  final bool isSearching;

  /// Câu dưới ô tìm, ví dụ "Không tìm thấy địa điểm nào." hoặc lỗi của server.
  final String? message;

  /// Lỗi theo ô từ server (`placeIds`).
  final String? errorText;

  @override
  State<BlogPlacePicker> createState() => _BlogPlacePickerState();
}

class _BlogPlacePickerState extends State<BlogPlacePicker> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  static IconData _iconOf(BlogPlace place) =>
      place.isNew ? Symbols.travel_explore_rounded : Symbols.location_on_rounded;

  @override
  Widget build(BuildContext context) {
    final full = widget.selected.length >= widget.max;
    final chosen = {for (final p in widget.selected) p.key};
    final results = [
      for (final p in widget.results)
        if (!chosen.contains(p.key)) p,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Text(
          'Địa điểm liên quan (${widget.selected.length}/${widget.max})',
          style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink),
        ),
        if (widget.selected.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final place in widget.selected) _chip(place)],
          ),
        TextField(
          controller: _query,
          enabled: !full,
          maxLength: 100,
          textInputAction: TextInputAction.search,
          onSubmitted: widget.onSearch,
          style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
          decoration: InputDecoration(
            hintText: full ? 'Đã chọn đủ ${widget.max} địa điểm' : 'Tìm địa điểm (không bắt buộc)',
            counterText: '',
            errorText: widget.errorText,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: IconButton(
                tooltip: 'Tìm địa điểm',
                icon: const Icon(Symbols.search_rounded, size: 22),
                onPressed: full ? null : () => widget.onSearch(_query.text),
              ),
            ),
          ),
        ),
        if (widget.isSearching) const _SearchingBar(),
        if (widget.message != null && !widget.isSearching)
          Text(widget.message!, style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
        if (!full && results.isNotEmpty)
          SenpaiGroup(
            children: [
              for (final place in results)
                SenpaiListRow(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  leading: IconTile(_iconOf(place), size: 36, radius: 10),
                  title: place.name,
                  titleStyle: SenpaiText.titleS.copyWith(color: SenpaiColors.ink),
                  subtitle: [if (place.isNew) 'OpenStreetMap', place.detail].where((s) => s.isNotEmpty).join(' · '),
                  subtitleLines: 1,
                  trailing: const Icon(Symbols.add_circle_rounded, size: 22, color: SenpaiColors.brand),
                  onTap: () {
                    _query.clear();
                    widget.onAdd(place);
                  },
                ),
            ],
          ),
      ],
    );
  }

  /// `inputChip(name, icon)`: viên thuốc brand-soft, icon 16, chữ Label/S brand-text, nút x 16.
  Widget _chip(BlogPlace place) {
    return InputChip(
      avatar: Icon(_iconOf(place), size: 16, color: SenpaiColors.brandText),
      label: Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      labelStyle: SenpaiText.labelS.copyWith(color: SenpaiColors.brandText),
      color: const WidgetStatePropertyAll(SenpaiColors.brandSoft),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.fromLTRB(6, 2, 4, 2),
      labelPadding: const EdgeInsets.symmetric(horizontal: 2),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      deleteIcon: const Icon(Symbols.close_rounded, size: 16),
      deleteIconColor: SenpaiColors.brandText,
      deleteButtonTooltipMessage: 'Bỏ địa điểm ${place.name}',
      onDeleted: () => widget.onRemove(place),
    );
  }
}

/// Vạch chạy ngang báo đang tìm: cao 4, bo tròn, màu brand trên nền surface-2.
class _SearchingBar extends StatelessWidget {
  const _SearchingBar();

  @override
  Widget build(BuildContext context) {
    return const ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(99)),
      child: LinearProgressIndicator(minHeight: 4),
    );
  }
}
