import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/area_stage_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.model/area_option.dart';
import 'package:myasvsj/com.myasvsj.model/profile_stage.dart';
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

/// Hàm lấy vị trí hiện tại của máy; trả về null khi không lấy được (bị từ chối quyền, tắt GPS…).
typedef AreaLocator = Future<({double lat, double lng})?> Function();

/// "Khu vực và giai đoạn" (màn 38 của thiết kế): chọn giai đoạn (4 ô Sắp sang Nhật / Mới đến / Sắp về nước /
/// Đã về nước) và khu vực sống (tìm nhanh theo tên, "Vị trí của tôi", hoặc tỉnh → quận / thành phố), rồi bấm
/// "Lưu" ở thanh dưới.
///
/// Lưu xong thì đóng và trả về true (Trang chủ, trang Tôi dùng để tải lại).
class AreaStageScreen extends StatefulWidget {
  const AreaStageScreen({super.key, this.locate});

  /// Cách lấy vị trí cho "Vị trí của tôi"; null là dùng GPS của máy. Test truyền hàm giả.
  final AreaLocator? locate;

  @override
  State<AreaStageScreen> createState() => _AreaStageScreenState();
}

class _AreaStageScreenState extends State<AreaStageScreen> with ProfileUserWatcher {
  /// Icon của từng giai đoạn, như thiết kế.
  static const _stageIcons = {
    'PRE': Symbols.flight_takeoff_rounded,
    'ARR': Symbols.flight_land_rounded,
    'LEAVE': Symbols.luggage_rounded,
    'HOME': Symbols.home_rounded,
  };

  final _search = TextEditingController();
  Timer? _searchTimer;

  @override
  void onUserChanged(int? userId) {
    if (userId != null) {
      context.read<AreaStageController>().open();
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    watchUser(user?.id);
    final areas = context.watch<AreaStageController>();
    final ready = user != null && !areas.isLoading && areas.error == null;
    return Scaffold(
      appBar: const SenpaiAppBar(title: 'Khu vực và giai đoạn'),
      body: user == null
          ? const ProfileSignInPrompt(text: 'Đăng nhập để chọn khu vực và giai đoạn của bạn.')
          : _body(areas),
      bottomNavigationBar: ready
          ? ProfileBottomAction(
              error: areas.saveError,
              button: SenpaiButton(
                label: areas.isSaving ? 'Đang lưu…' : 'Lưu',
                onPressed: areas.isSaving ? null : () => _save(areas),
                expand: true,
              ),
            )
          : null,
    );
  }

  Widget _body(AreaStageController areas) {
    if (areas.isLoading) {
      return const LoadingView();
    }
    if (areas.error != null) {
      return ErrorView(message: areas.error!, onRetry: areas.open);
    }
    final blocks = <Widget>[
      const SenpaiNote(
        'Không bắt buộc. Dùng để gợi ý việc cần làm, review và sự kiện gần bạn. '
        'Chỉ lưu khu vực, không lưu địa chỉ; chỉ mình bạn thấy.',
        icon: Symbols.lock_rounded,
        tone: SenpaiTone.ai,
      ),
      _section('Giai đoạn', _stages(areas)),
      _section(areas.areaLabel, _current(areas)),
      _searchBox(areas),
      _location(areas),
      _pickers(areas),
      Text(
        'Danh sách khu vực: Geolonia 住所データ (CC BY 4.0), dựa trên dữ liệu của デジタル庁.',
        style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
      ),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 18),
          blocks[i],
        ],
      ],
    );
  }

  /// Tiêu đề khối Title/S, cách nội dung 10.
  static Widget _section(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [Text(title, style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)), child],
    );
  }

  static Widget _errorText(String text) => Text(text, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.crit));

  // ---------------------------------------------------------------- Giai đoạn

  /// Lưới 2 cột 4 ô giai đoạn; bấm lại ô đang chọn để bỏ chọn.
  Widget _stages(AreaStageController areas) {
    final error = areas.fieldErrors['stage'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        LayoutBuilder(
          builder: (context, box) {
            final width = ((box.maxWidth - 12) / 2).floorToDouble();
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [for (final stage in ProfileStage.all) _stageTile(areas, stage, width)],
            );
          },
        ),
        if (error != null) _errorText(error),
      ],
    );
  }

  /// `stageTile`: ô bo 16 p12, icon 24 trên tên Label/M; đang chọn thì nền brand-soft viền brand 2.
  /// Bên trong là một ChoiceChip (chọn / bỏ chọn, ngữ nghĩa "selected").
  Widget _stageTile(AreaStageController areas, ProfileStage stage, double width) {
    final on = areas.stage == stage.code;
    // Chip cộng bề dày viền vào kích thước: lề trừ đi bề dày viền để ô luôn đúng [width] và p12
    final border = on ? 2.0 : 1.0;
    return ChoiceChip(
      selected: on,
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.all(12 - border),
      labelPadding: EdgeInsets.zero,
      color: WidgetStatePropertyAll(on ? SenpaiColors.brandSoft : SenpaiColors.surface),
      side: BorderSide(color: on ? SenpaiColors.brand : SenpaiColors.line, width: border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (selected) => areas.selectStage(selected ? stage.code : null),
      label: SizedBox(
        width: width - 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Icon(
              _stageIcons[stage.code] ?? Symbols.flag_rounded,
              size: 24,
              color: on ? SenpaiColors.brandText : SenpaiColors.muted,
            ),
            Text(
              stage.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: SenpaiText.labelM.copyWith(color: on ? SenpaiColors.brandText : SenpaiColors.ink),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Khu vực

  /// Khu vực đang chọn: ô trắng bo 14, ghim brand, tên Title/S, "tên Nhật · tỉnh" Caption, nút bỏ chọn.
  Widget _current(AreaStageController areas) {
    final area = areas.area;
    final Widget content;
    if (area == null) {
      content = Row(
        spacing: 10,
        children: [
          const Icon(Symbols.location_on_rounded, size: 22, color: SenpaiColors.muted),
          Expanded(child: Text('Chưa chọn khu vực.', style: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted))),
        ],
      );
    } else {
      final prefecture = areas.prefectureOf(area.prefectureCode)?.nameEn ?? '';
      final title = area.nameEn.isNotEmpty ? area.nameEn : (area.name.isEmpty ? area.label : area.name);
      final caption = area.nameEn.isEmpty ? '' : [area.nameJa, prefecture].where((s) => s.isNotEmpty).join(' · ');
      content = Row(
        spacing: 10,
        children: [
          const Icon(Symbols.location_on_rounded, size: 22, color: SenpaiColors.brand),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
                if (caption.isNotEmpty)
                  Text(caption, style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Bỏ chọn khu vực',
            onPressed: areas.clearArea,
            style: IconButton.styleFrom(
              foregroundColor: SenpaiColors.muted,
              minimumSize: const Size(36, 36),
              fixedSize: const Size(36, 36),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Symbols.close_rounded, size: 20),
          ),
        ],
      );
    }
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: EdgeInsets.fromLTRB(14, 10, area == null ? 14 : 6, 10),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: SenpaiColors.surface,
        border: Border.all(color: SenpaiColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: content,
    );
  }

  /// "Tìm khu vực theo tên": ô nhập có icon tìm kiếm, kết quả hiện trong một nhóm ngay dưới.
  Widget _searchBox(AreaStageController areas) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        SenpaiLabeledField(
          label: 'Tìm khu vực theo tên',
          child: TextField(
            controller: _search,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Tìm nhanh: Arakawa, 荒川, Osaka…',
              prefixIcon: const Icon(Symbols.search_rounded, size: 22),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Xóa',
                      icon: const Icon(Symbols.close_rounded, size: 20),
                      onPressed: () => _clearSearch(areas),
                    ),
            ),
            onChanged: (text) {
              setState(() {}); // hiện / ẩn nút Xóa
              _searchTimer?.cancel();
              _searchTimer = Timer(const Duration(milliseconds: 300), () => areas.searchAreas(text));
            },
            onSubmitted: (text) {
              _searchTimer?.cancel();
              areas.searchAreas(text);
            },
          ),
        ),
        if (areas.isSearching) const LinearProgressIndicator(minHeight: 3),
        if (areas.searchResults.isNotEmpty)
          SenpaiGroup(
            children: [
              for (final option in areas.searchResults)
                SenpaiListRow(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  leading: const Icon(Symbols.location_on_rounded, size: 22, color: SenpaiColors.brand),
                  title: _withPrefecture(areas, option),
                  subtitle: option.nameJa,
                  subtitleLines: 1,
                  showChevron: false,
                  onTap: () => _choose(areas, option),
                ),
            ],
          ),
        if (areas.searchFoundNothing)
          Text(
            'Không tìm thấy khu vực nào. Thử tên khác hoặc chọn tỉnh ở dưới.',
            style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
          ),
        if (areas.searchError != null) _errorText(areas.searchError!),
      ],
    );
  }

  /// "Arakawa-ku, Tokyo" như kết quả tìm của web.
  String _withPrefecture(AreaStageController areas, AreaOption option) {
    final prefecture = areas.prefectureOf(option.prefectureCode);
    return prefecture == null ? option.nameEn : '${option.nameEn}, ${prefecture.nameEn}';
  }

  /// Nút Secondary "Vị trí của tôi" giãn hết chiều ngang, câu giải thích, khu vực gợi ý và câu báo khi không
  /// lấy được vị trí.
  Widget _location(AreaStageController areas) {
    final suggested = areas.suggested;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        SenpaiButton(
          label: 'Vị trí của tôi',
          icon: Symbols.my_location_rounded,
          kind: SenpaiButtonKind.secondary,
          loading: areas.isLocating,
          expand: true,
          onPressed: () => _locate(areas),
        ),
        Text(
          'Vị trí chỉ dùng để gợi ý khu vực, không được lưu.',
          style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
        ),
        if (suggested != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SenpaiCard(
              color: SenpaiColors.brandSoft,
              borderColor: null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [
                      const Icon(Symbols.near_me_rounded, size: 20, color: SenpaiColors.brandText),
                      Expanded(
                        child: Text(
                          'Khu vực gợi ý: ${suggested.name.isEmpty ? suggested.label : suggested.name}',
                          style: SenpaiText.bodyS.copyWith(color: SenpaiColors.ink),
                        ),
                      ),
                    ],
                  ),
                  SenpaiButton(
                    label: 'Dùng khu vực này',
                    size: SenpaiButtonSize.small,
                    onPressed: areas.useSuggested,
                  ),
                ],
              ),
            ),
          ),
        if (areas.locateMessage != null)
          SenpaiNote(areas.locateMessage!, icon: Symbols.location_off_rounded, tone: SenpaiTone.warn),
      ],
    );
  }

  /// Hai ô chọn cạnh nhau: tỉnh, rồi quận / thành phố của tỉnh đó. Ô đóng chỉ hiện tên ngắn (tiếng Anh),
  /// danh sách mở ra hiện cả tên Nhật.
  Widget _pickers(AreaStageController areas) {
    final selectedArea = areas.areas.any((a) => a.id == areas.area?.id) ? areas.area?.id : null;
    final canPickArea = areas.prefectureCode != null && !areas.isLoadingAreas && areas.areasError == null;
    const decoration = InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 13));
    const icon = Icon(Symbols.expand_more_rounded, size: 22, color: SenpaiColors.muted);
    Widget short(String text) => Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Expanded(
              child: _dropdownField(
                'Tỉnh / thành phố',
                DropdownButtonFormField<String?>(
                  // Khóa theo giá trị: ô chọn đổi theo Controller (tìm nhanh, gợi ý vị trí, bỏ chọn)
                  key: ValueKey('prefecture-${areas.prefectureCode}'),
                  initialValue: areas.prefectureCode,
                  isExpanded: true,
                  style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
                  icon: icon,
                  decoration: decoration,
                  selectedItemBuilder: (_) => [
                    short('Chưa chọn'),
                    for (final p in areas.prefectures) short(p.nameEn.isEmpty ? p.label : p.nameEn),
                  ],
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('Chưa chọn')),
                    for (final p in areas.prefectures)
                      DropdownMenuItem<String?>(
                        value: p.code,
                        child: Text(p.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: areas.selectPrefecture,
                ),
              ),
            ),
            Expanded(
              child: _dropdownField(
                'Quận / thành phố',
                DropdownButtonFormField<int?>(
                  key: ValueKey('area-${areas.prefectureCode}-$selectedArea-${areas.areas.length}'),
                  initialValue: selectedArea,
                  isExpanded: true,
                  style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
                  icon: icon,
                  decoration: decoration.copyWith(
                    helperText: areas.prefectureCode == null ? 'Chọn tỉnh trước' : null,
                  ),
                  hint: short(areas.isLoadingAreas ? 'Đang tải…' : 'Chưa chọn'),
                  selectedItemBuilder: (_) => [
                    short('Chưa chọn'),
                    for (final a in areas.areas) short(a.nameEn.isEmpty ? a.label : a.nameEn),
                  ],
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('Chưa chọn')),
                    for (final a in areas.areas)
                      DropdownMenuItem<int?>(
                        value: a.id,
                        child: Text(a.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: canPickArea ? areas.selectArea : null,
                ),
              ),
            ),
          ],
        ),
        if (areas.areasError != null)
          Row(
            children: [
              Expanded(child: _errorText(areas.areasError!)),
              TextButton(onPressed: areas.retryAreas, child: const Text('Thử lại')),
            ],
          ),
      ],
    );
  }

  /// `dropdownField(label, value)`: nhãn Label/S muted phía trên ô chọn cao 48 bo 12.
  static Widget _dropdownField(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [Text(label, style: SenpaiText.labelS.copyWith(color: SenpaiColors.muted)), field],
    );
  }

  void _clearSearch(AreaStageController areas) {
    _searchTimer?.cancel();
    _search.clear();
    areas.searchAreas('');
    setState(() {});
  }

  Future<void> _choose(AreaStageController areas, AreaOption option) async {
    _searchTimer?.cancel();
    _search.clear();
    FocusScope.of(context).unfocus();
    await areas.chooseArea(option);
  }

  /// "Vị trí của tôi": server thử có vị trí cố định thì dùng nó; ngược lại hỏi quyền rồi lấy GPS.
  Future<void> _locate(AreaStageController areas) async {
    final dev = areas.devLocation;
    if (dev != null) {
      await areas.suggestNearest(dev.lat, dev.lng);
      return;
    }
    areas.startLocating();
    final position = await (widget.locate ?? _devicePosition)();
    if (!mounted) {
      return;
    }
    if (position == null) {
      areas.locationUnavailable();
    } else {
      await areas.suggestNearest(position.lat, position.lng);
    }
  }

  /// Vị trí từ GPS của máy; hệ điều hành hỏi người dùng trước. Không lấy được thì trả về null.
  static Future<({double lat, double lng})?> _devicePosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 15)),
      );
      return (lat: position.latitude, lng: position.longitude);
    } catch (_) {
      // Hết thời gian, máy không có GPS, plugin chưa sẵn sàng…
      return null;
    }
  }

  Future<void> _save(AreaStageController areas) async {
    final saved = await areas.save();
    if (saved && mounted) {
      showMessage(context, areas.takeMessage());
      Navigator.pop(context, true);
    }
  }
}
