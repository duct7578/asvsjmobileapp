import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/place_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/review_controller.dart';
import 'package:myasvsj/com.myasvsj.model/map_festival.dart';
import 'package:myasvsj/com.myasvsj.model/map_place.dart';
import 'package:myasvsj/com.myasvsj.model/place_option.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/event_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/map_distance_text.dart';
import 'package:myasvsj/com.myasvsj.screen/map_pin.dart';
import 'package:myasvsj/com.myasvsj.screen/map_result_panel.dart';
import 'package:myasvsj/com.myasvsj.screen/place_category_icon.dart';
import 'package:myasvsj/com.myasvsj.screen/place_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/place_summary_sheet.dart';
import 'package:myasvsj/com.myasvsj.screen/review_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/sign_in_gate.dart';

/// Tab Bản đồ (UC-U14, màn 07 của thiết kế): bản đồ OpenStreetMap phủ kín thân màn hình, nổi trên đó là ô tìm
/// địa điểm (viên thuốc có bóng, nút bộ lọc), hàng chip danh mục kèm số lượng, viên thuốc "Sự kiện: Tắt / 15 / 30
/// ngày tới", hai nút vuông "Vị trí của tôi" và "Chú thích"; ghim địa điểm theo danh mục, ghim sự kiện đèn lồng,
/// chấm vị trí của tôi. "Địa điểm quanh đây" (chạm bản đồ khi đã phóng to) và kết quả tìm hiện ở bảng bo tròn
/// phía dưới. Bấm ghim → bảng tóm tắt (màn 08) → chi tiết địa điểm.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.focusPlaceId, this.showTiles = true});

  /// Mở bản đồ tại địa điểm này; null = khu vực của tôi hoặc mặc định.
  final int? focusPlaceId;

  /// false trong widget test: không tải ô bản đồ từ mạng (test không có mạng).
  final bool showTiles;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const _focusZoom = 16.0;

  /// Đỉnh của cột nút nổi khi hàng bộ lọc đang hiện / đang ẩn (theo bố cục màn 07).
  static const _fabTopWithFilters = 166.0;
  static const _fabTopNoFilters = 72.0;

  /// Ngừng gõ bấy lâu thì hiện gợi ý (SEARCH_DELAY của web).
  static const _suggestDelay = Duration(milliseconds: 350);

  /// Đỉnh khung gợi ý: ngay dưới ô tìm kiếm (đỉnh 12 + cao 48 + cách 6).
  static const _suggestTop = 66.0;

  final _map = MapController();
  final _search = TextEditingController();
  Timer? _suggestTimer;
  bool _mapReady = false;
  bool _focusDone = false;
  int? _selectedId;
  LatLng? _tapPoint;

  /// Hàng chip danh mục và viên thuốc sự kiện đang hiện (nút bộ lọc trong ô tìm kiếm ẩn / hiện để rộng bản đồ).
  bool _filtersOpen = true;

  /// Người đang đăng nhập lúc dựng lần trước: đổi thì tải lại ghim (ghim chờ duyệt của mình, khu vực của tôi).
  int? _userId;
  bool _userSeen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<PlaceController>().loadMap());
  }

  @override
  void dispose() {
    _suggestTimer?.cancel();
    _search.dispose();
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final places = context.watch<PlaceController>();
    _watchUser(context.watch<AuthController>().currentUser?.id);
    final loaded = places.overview != null;
    return Scaffold(
      appBar: const SenpaiLargeAppBar(title: 'Bản đồ'),
      body: Stack(
        children: [
          Positioned.fill(child: _mapArea(places)),
          if (places.isLoadingMap)
            const Positioned(top: 0, left: 0, right: 0, child: LinearProgressIndicator(minHeight: 3)),
          Positioned(top: 12, left: 0, right: 0, child: _tools(places)),
          if (loaded)
            Positioned(top: _filtersOpen ? _fabTopWithFilters : _fabTopNoFilters, right: 16, child: _fabs(places)),
          Positioned(left: 0, right: 0, bottom: 0, child: _bottom(places, loaded: loaded)),
          // Khung gợi ý nằm trên cùng, phủ lên bộ lọc, nút nổi và bảng kết quả
          if (places.isSuggestOpen)
            Positioned(
              top: _suggestTop,
              left: 16,
              right: 16,
              bottom: 8,
              child: Align(alignment: Alignment.topCenter, child: _suggestBox(places)),
            ),
        ],
      ),
    );
  }

  void _watchUser(int? userId) {
    if (_userSeen && userId == _userId) {
      return;
    }
    final changed = _userSeen;
    _userSeen = true;
    _userId = userId;
    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<PlaceController>().refreshMap();
        }
      });
    }
  }

  // ---------------------------------------------------------------- công cụ nổi trên bản đồ

  Widget _tools(PlaceController places) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: _searchBox(places)),
        if (_filtersOpen) ...[
          const SizedBox(height: 10),
          _categoryChips(places),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            clipBehavior: Clip.none,
            child: _eventRow(places),
          ),
        ],
      ],
    );
  }

  /// Ô tìm địa điểm: viên thuốc trắng cao 48, bóng Card, icon search muted; cuối ô là nút bộ lọc (tune, nền
  /// brand-soft) hoặc nút xoá từ khoá khi đã gõ.
  Widget _searchBox(PlaceController places) {
    const pill = BorderRadius.all(Radius.circular(999));
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: SenpaiColors.surface,
        shape: StadiumBorder(),
        shadows: SenpaiColors.shadowCard,
      ),
      child: TextField(
        controller: _search,
        textInputAction: TextInputAction.search,
        inputFormatters: [LengthLimitingTextInputFormatter(100)],
        onChanged: (text) {
          setState(() {});
          _suggestTimer?.cancel();
          if (text.trim().isEmpty) {
            places.hideSuggestions();
          } else {
            _suggestTimer = Timer(_suggestDelay, () => places.suggest(text));
          }
        },
        onSubmitted: (text) => _runSearch(places, text),
        style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
        decoration: InputDecoration(
          hintText: 'Tìm địa điểm',
          isDense: true,
          filled: true,
          fillColor: SenpaiColors.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 10),
            child: Icon(Symbols.search_rounded, size: 22),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          // Align: ô nhập ép biểu tượng cuối cao bằng ô, giữ nút tròn 32 ở giữa thay vì kéo dài thành viên thuốc
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Align(widthFactor: 1, heightFactor: 1, child: _searchTrailing(places)),
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 48),
          border: const OutlineInputBorder(borderRadius: pill, borderSide: BorderSide.none),
          enabledBorder: const OutlineInputBorder(borderRadius: pill, borderSide: BorderSide.none),
          focusedBorder: const OutlineInputBorder(
            borderRadius: pill,
            borderSide: BorderSide(color: SenpaiColors.brand, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _searchTrailing(PlaceController places) {
    ButtonStyle round(Color background, Color foreground) => IconButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      fixedSize: const Size(32, 32),
      minimumSize: const Size(32, 32),
      padding: EdgeInsets.zero,
      iconSize: 18,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    if (_search.text.isNotEmpty) {
      return IconButton(
        tooltip: 'Xóa từ khóa',
        style: round(SenpaiColors.surface2, SenpaiColors.muted),
        icon: const Icon(Symbols.close_rounded),
        onPressed: () {
          _search.clear();
          _suggestTimer?.cancel();
          places.hideSuggestions();
          places.closePanel();
          setState(() {});
        },
      );
    }
    return IconButton(
      tooltip: _filtersOpen ? 'Ẩn bộ lọc' : 'Hiện bộ lọc',
      style: _filtersOpen
          ? round(SenpaiColors.brandSoft, SenpaiColors.brandText)
          : round(SenpaiColors.brand, SenpaiColors.onBrand),
      icon: const Icon(Symbols.tune_rounded),
      onPressed: () => setState(() => _filtersOpen = !_filtersOpen),
    );
  }

  /// Hàng chip danh mục cuộn ngang: "Tất cả (n)" (icon apps) và mỗi danh mục có địa điểm, chip đang chọn nền brand.
  Widget _categoryChips(PlaceController places) {
    Widget chip(String label, IconData icon, bool selected, ValueChanged<bool> onSelected) => ChoiceChip(
      avatar: Icon(icon, size: 18, color: selected ? SenpaiColors.onBrand : SenpaiColors.ink),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: onSelected,
    );
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          chip(
            'Tất cả (${places.totalCount})',
            Symbols.apps_rounded,
            places.categoryId == null,
            (_) => places.setCategory(null),
          ),
          for (final category in places.activeCategories) ...[
            const SizedBox(width: 8),
            chip(
              '${category.name} (${category.count})',
              placeCategoryIcon(category.icon),
              places.categoryId == category.id,
              (on) => _pickCategory(on ? category.id : null),
            ),
          ],
        ],
      ),
    );
  }

  /// `eventRow` của thiết kế: viên thuốc trắng có bóng, icon đèn lồng, "Sự kiện:" và ba lựa chọn (đang chọn nền ink).
  Widget _eventRow(PlaceController places) {
    const labels = {0: 'Tắt', 15: '15 ngày tới', 30: '30 ngày tới'};
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: const ShapeDecoration(
        color: SenpaiColors.surface,
        shape: StadiumBorder(),
        shadows: SenpaiColors.shadowCard,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          const Icon(Symbols.celebration_rounded, size: 18, color: SenpaiColors.lanternText),
          Text('Sự kiện:', style: SenpaiText.labelS.copyWith(color: SenpaiColors.ink)),
          for (final days in PlaceController.eventDayChoices)
            _EventChoice(
              label: labels[days]!,
              selected: places.eventDays == days,
              onTap: () => places.setEventDays(days),
            ),
        ],
      ),
    );
  }

  /// Hai nút vuông trắng 44 bo 14 có bóng Card: "Vị trí của tôi" và "Chú thích".
  Widget _fabs(PlaceController places) {
    return Column(
      spacing: 8,
      children: [
        _MapFab(
          tooltip: 'Vị trí của tôi',
          onPressed: places.isLocating ? null : () => _locate(places),
          child: places.isLocating
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(places.myLocation == null ? Symbols.location_searching_rounded : Symbols.my_location_rounded),
        ),
        _MapFab(tooltip: 'Chú thích', onPressed: _showLegend, child: const Icon(Symbols.info_rounded)),
      ],
    );
  }

  /// Phần đáy: ghi nguồn OpenStreetMap (bắt buộc với ô bản đồ OSM, bấm mở trang bản quyền) nằm ngay trên bảng
  /// kết quả khi bảng mở.
  Widget _bottom(PlaceController places, {required bool loaded}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (loaded)
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: GestureDetector(
              onTap: () =>
                  launchUrl(Uri.parse('https://www.openstreetmap.org/copyright'), mode: LaunchMode.externalApplication),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: SenpaiColors.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('© OpenStreetMap', style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
              ),
            ),
          ),
        if (places.isPanelOpen)
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.4),
            child: SizedBox(
              width: double.infinity,
              child: MapResultPanel(onOpen: _openOption, onCategory: _pickCategory),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------- bản đồ

  Widget _mapArea(PlaceController places) {
    final overview = places.overview;
    if (overview == null) {
      // Chừa chỗ cho ô tìm kiếm và bộ lọc phía trên
      return Padding(
        padding: const EdgeInsets.only(top: 150),
        child: places.mapError != null
            ? ErrorView(message: places.mapError!, onRetry: places.loadMap)
            : const LoadingView(),
      );
    }
    final start = _focusPlace(places);
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: start == null ? LatLng(places.center.lat, places.center.lng) : LatLng(start.lat, start.lng),
        initialZoom: start == null ? places.center.zoom : _focusZoom,
        minZoom: 3,
        maxZoom: 19,
        backgroundColor: SenpaiColors.mapLand,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        onMapReady: _onMapReady,
        onTap: (_, point) => _onMapTap(places, point),
      ),
      children: [
        if (widget.showTiles)
          TileLayer(urlTemplate: _tileUrl, userAgentPackageName: 'com.example.myasvsj', maxNativeZoom: 19),
        MarkerLayer(markers: _markers(places)),
      ],
    );
  }

  /// Địa điểm cần mở khi vào màn hình ([MapScreen.focusPlaceId]), nếu có ghim.
  MapPlace? _focusPlace(PlaceController places) {
    final id = widget.focusPlaceId;
    return id == null || _focusDone ? null : places.placeById(id);
  }

  List<Marker> _markers(PlaceController places) {
    return [
      for (final event in places.events)
        Marker(
          point: LatLng(event.lat, event.lng),
          width: 120,
          height: 72,
          child: _EventPin(key: ValueKey('map-event-${event.id}'), event: event, onTap: () => _showEvent(event)),
        ),
      for (final option in places.panelItems)
        if (!option.isOnSenpai && option.lat != null && option.lng != null)
          Marker(
            point: LatLng(option.lat!, option.lng!),
            width: MapPin.dimSize,
            height: MapPin.dimSize,
            child: _OsmPin(
              key: ValueKey('map-osm-${option.externalId}'),
              icon: places.categoryByName(option.category)?.icon,
              label: '${option.name}, OpenStreetMap, chưa có trên Senpai ơi',
              onTap: () => _showOption(option),
            ),
          ),
      for (final place in places.places)
        Marker(
          point: LatLng(place.lat, place.lng),
          width: MapPin.sizeFor(place, selected: _selectedId == place.id),
          height: MapPin.sizeFor(place, selected: _selectedId == place.id),
          child: MapPin(
            key: ValueKey('map-pin-${place.id}'),
            place: place,
            icon: places.categoryById(place.categoryId)?.icon ?? 'place',
            selected: _selectedId == place.id,
            onTap: () => _showPlace(place),
          ),
        ),
      if (_tapPoint != null && places.panelTitle == PlaceController.nearbyTitle)
        Marker(
          point: _tapPoint!,
          width: 18,
          height: 18,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SenpaiColors.lantern.withValues(alpha: 0.5),
              border: Border.all(color: SenpaiColors.lantern, width: 2),
            ),
          ),
        ),
      if (places.myLocation != null)
        Marker(
          point: LatLng(places.myLocation!.lat, places.myLocation!.lng),
          width: 44,
          height: 44,
          child: Semantics(label: 'Vị trí của bạn', child: const _MeDot()),
        ),
    ];
  }

  void _onMapReady() {
    _mapReady = true;
    final id = widget.focusPlaceId;
    if (id != null && !_focusDone) {
      _focusOn(id);
    }
  }

  /// Mở bản đồ tại địa điểm [id]: có ghim thì mở bảng tóm tắt; không có (ví dụ ghim vừa thêm) thì hỏi chi tiết.
  Future<void> _focusOn(int id) async {
    final places = context.read<PlaceController>();
    final pin = places.placeById(id);
    _focusDone = true;
    if (pin != null) {
      _showPlace(pin);
      return;
    }
    await places.loadPlace(id);
    if (!mounted) {
      return;
    }
    final detail = places.detailOf(id);
    if (detail == null || detail.lat == null || detail.lng == null) {
      showMessage(context, places.detailErrorOf(id) ?? 'Địa điểm này chưa có vị trí trên bản đồ.');
      return;
    }
    _moveTo(detail.lat!, detail.lng!);
    _openDetail(id);
  }

  void _moveTo(double lat, double lng, {double? zoom}) {
    if (!_mapReady) {
      return;
    }
    final current = _map.camera.zoom;
    _map.move(LatLng(lat, lng), zoom ?? (current < _focusZoom ? _focusZoom : current));
  }

  /// Chạm bản đồ khi đã phóng to: "Địa điểm quanh đây".
  void _onMapTap(PlaceController places, LatLng point) {
    // Đang xem gợi ý: chạm bản đồ chỉ đóng khung gợi ý (như bấm ra ngoài trên web)
    if (places.isSuggestOpen) {
      _suggestTimer?.cancel();
      places.hideSuggestions();
      FocusScope.of(context).unfocus();
      return;
    }
    if (_map.camera.zoom < PlaceController.nearbyZoom) {
      showMessage(context, 'Phóng to bản đồ rồi chạm vào chỗ bạn muốn để xem các địa điểm quanh đó.');
      return;
    }
    setState(() => _tapPoint = point);
    _search.clear();
    places.loadNearby(point.latitude, point.longitude, signedIn: context.read<AuthController>().isSignedIn);
  }

  Future<void> _runSearch(PlaceController places, String text) async {
    if (text.trim().isEmpty) {
      return;
    }
    _suggestTimer?.cancel();
    FocusScope.of(context).unfocus();
    await places.search(text);
    if (!mounted || !_mapReady) {
      return;
    }
    final points = [
      for (final o in places.panelItems)
        if (o.lat != null && o.lng != null) LatLng(o.lat!, o.lng!),
    ];
    if (points.isNotEmpty) {
      _map.fitCamera(CameraFit.coordinates(coordinates: points, padding: const EdgeInsets.all(48), maxZoom: 16));
    }
  }

  void _pickCategory(String? id) {
    _search.clear();
    _suggestTimer?.cancel();
    context.read<PlaceController>()
      ..hideSuggestions()
      ..setCategory(id);
  }

  /// Khung gợi ý dưới ô tìm kiếm (khung `#suggest` của web): danh mục và địa điểm khớp từ khóa đang gõ, ghi chú
  /// OpenStreetMap; bấm một dòng thì mở luôn, bấm "tìm" trên bàn phím thì ra bảng kết quả đầy đủ.
  Widget _suggestBox(PlaceController places) {
    final found = places.suggestions;
    final note = found?.externalNote ?? '';
    final rows = <Widget>[
      if (found != null && found.categories.isNotEmpty) ...[
        _suggestHeading('Danh mục'),
        for (final c in found.categories)
          MapResultPanel.categoryRow(
            c,
            onTap: () {
              FocusScope.of(context).unfocus();
              _pickCategory(c.id);
            },
          ),
      ],
      if (found != null && found.places.isNotEmpty) ...[
        _suggestHeading('Địa điểm'),
        for (final o in found.places)
          MapResultPanel.optionRow(
            places,
            o,
            onTap: () {
              _suggestTimer?.cancel();
              places.hideSuggestions();
              FocusScope.of(context).unfocus();
              _openOption(o);
            },
          ),
      ],
    ];
    Widget line(String text, {Color color = SenpaiColors.muted}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(text, style: SenpaiText.bodyS.copyWith(color: color)),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SenpaiColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: SenpaiColors.shadowCard,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (places.isSuggesting) const LinearProgressIndicator(minHeight: 2),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  children: [
                    if (places.suggestError != null)
                      line(places.suggestError!, color: SenpaiColors.crit)
                    else if (found == null)
                      line('Đang tìm…')
                    else if (rows.isEmpty)
                      line('Không có địa điểm nào khớp.'),
                    ...rows,
                    if (note.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(note, style: SenpaiText.caption.copyWith(color: SenpaiColors.muted)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _suggestHeading(String text) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 2),
    child: Text(text, style: SenpaiText.labelS.copyWith(color: SenpaiColors.muted)),
  );

  Future<void> _locate(PlaceController places) async {
    final note = await places.locateMe();
    if (!mounted) {
      return;
    }
    showMessage(context, note);
    final me = places.myLocation;
    if (me != null) {
      _moveTo(me.lat, me.lng, zoom: _focusZoom);
    }
  }

  // ---------------------------------------------------------------- bảng dưới

  /// Bảng dưới của bản đồ: bảng tự vẽ thanh nắm kéo, không phủ tối bản đồ (như màn 08).
  Future<void> _sheet(WidgetBuilder builder) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: false,
      isScrollControlled: true,
      barrierColor: Colors.transparent,
      builder: builder,
    );
  }

  /// Bấm một kết quả trong bảng: địa điểm có ghim → bảng tóm tắt; địa điểm OpenStreetMap → bảng "chưa có".
  void _openOption(PlaceOption option) {
    final places = context.read<PlaceController>();
    final pin = option.id == null ? null : places.placeById(option.id!);
    if (pin != null) {
      _moveTo(pin.lat, pin.lng);
      _showPlace(pin);
    } else if (option.id != null) {
      _openDetail(option.id!);
    } else {
      if (option.lat != null && option.lng != null) {
        _moveTo(option.lat!, option.lng!);
      }
      _showOption(option);
    }
  }

  void _showPlace(MapPlace place) {
    final places = context.read<PlaceController>();
    final category = places.categoryById(place.categoryId);
    setState(() => _selectedId = place.id);
    _sheet(
      (sheetContext) => PlaceSummarySheet.place(
        place,
        categoryName: category?.name ?? '',
        categoryIcon: category?.icon ?? 'place',
        distanceText: formatMapDistance(places.distanceTo(place.lat, place.lng)),
        onOpenDetail: () {
          Navigator.pop(sheetContext);
          _openDetail(place.id);
        },
      ),
    ).whenComplete(() {
      if (mounted) {
        setState(() => _selectedId = null);
      }
    });
  }

  void _showOption(PlaceOption option) {
    final places = context.read<PlaceController>();
    _sheet(
      (sheetContext) => PlaceSummarySheet.option(
        option,
        categoryIcon: places.categoryByName(option.category)?.icon ?? 'place',
        distanceText: formatMapDistance(places.distanceTo(option.lat, option.lng)),
        onOpenDetail: option.id == null
            ? null
            : () {
                Navigator.pop(sheetContext);
                _openDetail(option.id!);
              },
        onWriteFirst: option.id != null || option.externalId == null
            ? null
            : () {
                Navigator.pop(sheetContext);
                _writeFirst(option);
              },
      ),
    );
  }

  /// Bảng của ghim sự kiện: badge "Còn n ngày", tên sự kiện, nơi tổ chức · ngày, nút "Xem sự kiện".
  void _showEvent(MapFestival event) {
    final dates = [
      if (event.startDate != null) formatDate(event.startDate!),
      if (event.endDate != null && event.endDate != event.startDate) formatDate(event.endDate!),
    ].join(' – ');
    final where = [event.locationName, dates].where((s) => s.isNotEmpty).join(' · ');
    _sheet(
      (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              const SheetHandle(),
              Align(
                alignment: Alignment.centerLeft,
                child: SenpaiBadge(event.whenLabel, tone: SenpaiTone.lantern, icon: Symbols.celebration_rounded),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    event.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: SenpaiText.displayM.copyWith(color: SenpaiColors.ink),
                  ),
                  if (where.isNotEmpty) Text(where, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
                ],
              ),
              SenpaiButton(
                label: 'Xem sự kiện',
                icon: Symbols.arrow_forward_rounded,
                size: SenpaiButtonSize.medium,
                expand: true,
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => EventDetailScreen(eventId: event.id)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Chú thích các kiểu ghim, mỗi dòng có một ghim thu nhỏ đúng kiểu trên bản đồ.
  void _showLegend() {
    Widget row(Widget mark, String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        spacing: 12,
        children: [
          SizedBox(width: 32, child: Center(child: mark)),
          Expanded(
            child: Text(text, style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink)),
          ),
        ],
      ),
    );
    Widget mark({
      required Color color,
      double size = 24,
      double? radius,
      Color? border,
      double borderWidth = 2,
      Widget? child,
    }) => Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius ?? size / 2),
        border: border == null ? null : Border.all(color: border, width: borderWidth),
      ),
      child: child,
    );
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chú thích'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              row(
                mark(
                  color: SenpaiColors.brand,
                  size: 28,
                  child: const Icon(Icons.location_on_rounded, size: 16, color: SenpaiColors.onBrand),
                ),
                'Đã có review (tròn to, có số review)',
              ),
              row(mark(color: SenpaiColors.brand, radius: 7), 'Ghim cộng đồng (vuông)'),
              row(mark(color: SenpaiColors.surface, size: 22, border: SenpaiColors.line), 'Chưa có review (tròn, nhỏ)'),
              row(
                mark(
                  color: SenpaiColors.lantern,
                  size: 28,
                  child: const Icon(Icons.celebration_rounded, size: 16, color: SenpaiColors.ink),
                ),
                'Sự kiện (đèn lồng)',
              ),
              row(
                mark(
                  color: SenpaiColors.crit,
                  size: 20,
                  child: Text('!', style: SenpaiText.labelS.copyWith(color: SenpaiColors.onBrand)),
                ),
                'Có cảnh báo lừa đảo',
              ),
              row(mark(color: SenpaiColors.muted, size: 22), 'Đã đóng cửa'),
              const SizedBox(height: 8),
              Text(
                'Phóng to rồi chạm vào bất kỳ chỗ nào trên bản đồ để xem và review các địa điểm quanh đó.',
                style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
              ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Đóng'))],
      ),
    );
  }

  // ---------------------------------------------------------------- mở màn hình khác

  Future<void> _openDetail(int placeId) async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PlaceDetailScreen(placeId: placeId)));
    if (mounted) {
      // Review vừa viết / sửa / xóa đổi số review và màu ghim
      context.read<PlaceController>().refreshMap();
    }
  }

  /// "Viết review đầu tiên" cho địa điểm OpenStreetMap: server thêm địa điểm khi lưu review.
  Future<void> _writeFirst(PlaceOption option) async {
    if (!await requireSignIn(context) || !mounted) {
      return;
    }
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewFormScreen(externalPlaceId: option.externalId, placeName: option.name),
      ),
    );
    if (saved != true || !mounted) {
      return;
    }
    final reviews = context.read<ReviewController>();
    final places = context.read<PlaceController>();
    showMessage(context, reviews.takeMessage());
    places.closePanel();
    await places.refreshMap();
    final placeId = reviews.savedPlaceId;
    if (placeId != null && mounted) {
      await _openDetail(placeId);
    }
  }
}

/// Một lựa chọn của viên thuốc "Sự kiện:": p[4,10] bo tròn, đang chọn nền ink chữ trắng, còn lại nền surface-2.
class _EventChoice extends StatelessWidget {
  const _EventChoice({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Material(
        color: selected ? SenpaiColors.ink : SenpaiColors.surface2,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              label,
              style: SenpaiText.labelS.copyWith(color: selected ? SenpaiColors.onBrand : SenpaiColors.muted),
            ),
          ),
        ),
      ),
    );
  }
}

/// `mapFab` của thiết kế: nút vuông trắng 44 bo 14, bóng Card, icon 22 ink.
class _MapFab extends StatelessWidget {
  const _MapFab({required this.tooltip, required this.onPressed, required this.child});

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;

  static const _shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14)));

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(color: SenpaiColors.surface, shape: _shape, shadows: SenpaiColors.shadowCard),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        style: IconButton.styleFrom(
          foregroundColor: SenpaiColors.ink,
          disabledForegroundColor: SenpaiColors.muted,
          fixedSize: const Size(44, 44),
          minimumSize: const Size(44, 44),
          padding: EdgeInsets.zero,
          iconSize: 22,
          shape: _shape,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: child,
      ),
    );
  }
}

/// Ghim sự kiện (`pin/event`): đèn lồng tròn 44 viền trắng 3 bóng Card, nhãn "Còn N ngày" / "Đang diễn ra" trên
/// viên thuốc ink bên dưới.
class _EventPin extends StatelessWidget {
  const _EventPin({super.key, required this.event, required this.onTap});

  final MapFestival event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Sự kiện: ${event.title}, ${event.whenLabel}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SenpaiColors.lantern,
                shape: BoxShape.circle,
                border: Border.all(color: SenpaiColors.surface, width: 3),
                boxShadow: SenpaiColors.shadowCard,
              ),
              child: const Icon(Icons.celebration_rounded, size: 22, color: SenpaiColors.ink),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: SenpaiColors.ink, borderRadius: BorderRadius.circular(99)),
              child: Text(
                event.whenLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: SenpaiText.labelS.copyWith(color: SenpaiColors.onBrand),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ghim tạm (nền ink) của địa điểm OpenStreetMap trong kết quả tìm, chưa có trên Senpai ơi.
class _OsmPin extends StatelessWidget {
  const _OsmPin({super.key, required this.icon, required this.label, required this.onTap});

  final String? icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: SenpaiColors.ink,
            shape: BoxShape.circle,
            border: Border.all(color: SenpaiColors.surface, width: 2),
            boxShadow: SenpaiColors.shadowCard,
          ),
          child: Icon(placeCategoryIcon(icon), size: 18, color: SenpaiColors.onBrand),
        ),
      ),
    );
  }
}

/// Chấm vị trí của tôi (`me`): quầng ink 15% cỡ 44, chấm ink 16 viền trắng 3 ở giữa.
class _MeDot extends StatelessWidget {
  const _MeDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(color: SenpaiColors.ink.withValues(alpha: 0.15), shape: BoxShape.circle),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: SenpaiColors.ink,
          shape: BoxShape.circle,
          border: Border.all(color: SenpaiColors.surface, width: 3),
        ),
      ),
    );
  }
}
