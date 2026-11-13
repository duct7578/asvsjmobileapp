import 'package:flutter/foundation.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/map_category.dart';
import 'package:myasvsj/com.myasvsj.model/map_center.dart';
import 'package:myasvsj/com.myasvsj.model/map_directions.dart';
import 'package:myasvsj/com.myasvsj.model/map_festival.dart';
import 'package:myasvsj/com.myasvsj.model/map_overview.dart';
import 'package:myasvsj/com.myasvsj.model/map_place.dart';
import 'package:myasvsj/com.myasvsj.model/map_search_result.dart';
import 'package:myasvsj/com.myasvsj.model/page_result.dart';
import 'package:myasvsj/com.myasvsj.model/place_dao.dart';
import 'package:myasvsj/com.myasvsj.model/place_detail.dart';
import 'package:myasvsj/com.myasvsj.model/place_locator.dart';
import 'package:myasvsj/com.myasvsj.model/place_option.dart';
import 'package:myasvsj/com.myasvsj.model/place_phrase.dart';
import 'package:myasvsj/com.myasvsj.model/place_review.dart';
import 'package:myasvsj/com.myasvsj.model/place_speaker.dart';

/// Controller của Bản đồ (MapScreen) và chi tiết địa điểm (PlaceDetailScreen).
///
/// - Bản đồ: ghim, danh mục (lọc), sự kiện, tìm kiếm, "Địa điểm quanh đây", "Vị trí của tôi".
/// - Chi tiết: lưu theo id địa điểm, vì màn chi tiết có thể mở chồng nhau (địa điểm A → bài cảnh báo → địa điểm B).
/// - Thao tác: lưu / bỏ lưu, báo đã đóng cửa, thích / báo cáo review, nghe câu tiếng Nhật.
class PlaceController extends ChangeNotifier {
  PlaceController(this._dao, {PlaceSpeaker? speaker, PlaceLocator? locator})
    : _speaker = speaker ?? PlaceSpeaker(),
      _locator = locator ?? PlaceLocator();

  final PlaceDao _dao;
  final PlaceSpeaker _speaker;
  final PlaceLocator _locator;

  /// Chạm bản đồ ở mức phóng to này trở lên thì tìm "Địa điểm quanh đây" (giống NEARBY_ZOOM của web).
  static const double nearbyZoom = 15;

  /// Tiêu đề bảng "Địa điểm quanh đây".
  static const String nearbyTitle = 'Địa điểm quanh đây';

  /// Khách: "Địa điểm quanh đây" là địa điểm Senpai ơi trong bán kính này (mét), tính trên máy.
  static const double nearbyRadius = 150;

  /// Lựa chọn lớp sự kiện: 0 (Tắt), 15 hoặc 30 ngày tới.
  static const List<int> eventDayChoices = [0, 15, 30];

  // ----- Bản đồ (MapScreen)
  MapOverview? overview;
  bool isLoadingMap = false;
  String? mapError;

  /// Danh mục đang lọc; null = tất cả.
  String? categoryId;

  /// Lớp sự kiện: 0 (Tắt), 15 hoặc 30 ngày tới (mặc định 30 như web).
  int eventDays = 30;
  List<MapFestival> events = [];

  /// Vị trí của tôi (chỉ dùng trên máy).
  ({double lat, double lng})? myLocation;
  bool isLocating = false;

  // ----- Bảng kết quả trên bản đồ: tìm kiếm, "Địa điểm quanh đây", hoặc danh sách một danh mục
  /// Tiêu đề bảng; null khi bảng đóng.
  String? panelTitle;
  List<PlaceOption> panelItems = [];
  List<MapCategory> panelCategories = [];

  /// Ghi chú dưới kết quả (ví dụ "Đăng nhập để tìm thêm trên OpenStreetMap.").
  String panelNote = '';
  bool isPanelLoading = false;
  String? panelError;

  // ----- Gợi ý khi đang gõ ô tìm kiếm (khung `#suggest` của web), trước khi bấm tìm
  /// Từ khóa đang gợi ý; null khi khung gợi ý đóng.
  String? suggestQuery;

  /// Kết quả gợi ý gần nhất; giữ nguyên trong lúc chờ kết quả cho từ khóa mới, như web.
  MapSearchResult? suggestions;
  bool isSuggesting = false;
  String? suggestError;

  /// Tăng mỗi lần gợi ý / đóng gợi ý / tìm: kết quả về muộn của lần gõ cũ bị bỏ (giống `suggestTicket` của web).
  int _suggestTicket = 0;

  // ----- Chi tiết địa điểm (PlaceDetailScreen), theo id địa điểm được mở
  final Map<int, PlaceDetail> _details = {};
  final Map<int, String> _detailErrors = {};
  final Set<int> _loadingDetails = {};
  final Map<int, List<PlaceReview>> _reviews = {};
  final Map<int, PageResult<PlaceReview>> _reviewPages = {};
  final Set<int> _loadingReviews = {};
  final Map<int, String> _reviewErrors = {};
  final Map<int, List<PlacePhrase>> _phrases = {};
  final Set<int> _loadingPhrases = {};

  /// Câu thông báo sau một thao tác (thành công hay lỗi); màn hình hiện một lần bằng [takeMessage].
  String? message;

  // ---------------------------------------------------------------- Bản đồ

  List<MapCategory> get categories => overview?.categories ?? const [];

  /// Danh mục có ít nhất một địa điểm (chip lọc).
  List<MapCategory> get activeCategories => [
    for (final c in categories)
      if (c.count > 0) c,
  ];

  /// Tổng số địa điểm của mọi danh mục ("Tất cả danh mục").
  int get totalCount => activeCategories.fold(0, (sum, c) => sum + c.count);

  MapCenter get center => overview?.center ?? MapCenter.tokyo;

  /// Ghim đang hiện (theo danh mục đang lọc).
  List<MapPlace> get places => [
    for (final p in overview?.places ?? const <MapPlace>[])
      if (categoryId == null || p.categoryId == categoryId) p,
  ];

  MapPlace? placeById(int id) {
    for (final p in overview?.places ?? const <MapPlace>[]) {
      if (p.id == id) {
        return p;
      }
    }
    return null;
  }

  MapCategory? categoryById(String? id) {
    for (final c in categories) {
      if (c.id == id) {
        return c;
      }
    }
    return null;
  }

  MapCategory? categoryByName(String? name) {
    for (final c in categories) {
      if (c.name == name) {
        return c;
      }
    }
    return null;
  }

  /// Bảng kết quả đang mở.
  bool get isPanelOpen => panelTitle != null;

  /// Tải ghim, danh mục và lớp sự kiện.
  Future<void> loadMap() async {
    isLoadingMap = true;
    mapError = null;
    notifyListeners();
    try {
      overview = await _dao.findMap();
    } on ApiException catch (e) {
      mapError = e.message;
    } finally {
      isLoadingMap = false;
      notifyListeners();
    }
    if (mapError == null) {
      await _loadEvents();
    }
  }

  /// Tải lại ghim sau khi review đổi số liệu (số review, số sao, địa điểm OpenStreetMap mới được thêm).
  /// Lỗi thì giữ ghim cũ: ghim sẽ đúng ở lần mở sau.
  Future<void> refreshMap() async {
    try {
      overview = await _dao.findMap();
      notifyListeners();
    } on ApiException {
      // giữ ghim cũ
    }
  }

  /// Đổi lớp sự kiện: 0 (Tắt), 15 hoặc 30 ngày tới.
  Future<void> setEventDays(int days) async {
    eventDays = days;
    notifyListeners();
    await _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (eventDays <= 0) {
      events = [];
      notifyListeners();
      return;
    }
    final days = eventDays;
    try {
      final loaded = await _dao.findEvents(days);
      if (days == eventDays) {
        events = loaded;
      }
    } on ApiException {
      // Sự kiện chỉ là lớp phụ trên bản đồ: lỗi thì không vẽ
      events = [];
    }
    notifyListeners();
  }

  /// Lọc theo danh mục; chọn một danh mục thì mở bảng danh sách địa điểm của danh mục đó. null = tất cả.
  void setCategory(String? id) {
    categoryId = id;
    final category = categoryById(id);
    if (category == null) {
      _closePanel();
    } else {
      _showPanel(category.name, [for (final p in _sorted(places)) _option(p, category.name)]);
    }
    notifyListeners();
  }

  /// Khung gợi ý đang mở.
  bool get isSuggestOpen => suggestQuery != null;

  /// Gợi ý danh mục và địa điểm cho từ khóa đang gõ (màn hình gọi sau khi ngừng gõ một lúc). Từ khóa trống thì
  /// đóng khung gợi ý.
  Future<void> suggest(String text) async {
    final q = text.trim();
    if (q.isEmpty) {
      hideSuggestions();
      return;
    }
    final ticket = ++_suggestTicket;
    suggestQuery = q;
    isSuggesting = true;
    notifyListeners();
    try {
      final found = await _dao.search(q);
      if (ticket != _suggestTicket) {
        return;
      }
      suggestions = found;
      suggestError = null;
    } on ApiException catch (e) {
      if (ticket != _suggestTicket) {
        return;
      }
      suggestError = e.message;
    }
    isSuggesting = false;
    notifyListeners();
  }

  /// Đóng khung gợi ý và bỏ kết quả gợi ý còn đang chờ.
  void hideSuggestions() {
    if (!isSuggestOpen && !isSuggesting) {
      return;
    }
    _clearSuggestions();
    notifyListeners();
  }

  void _clearSuggestions() {
    _suggestTicket++;
    suggestQuery = null;
    suggestions = null;
    isSuggesting = false;
    suggestError = null;
  }

  /// Tìm danh mục và địa điểm; kết quả hiện trong bảng.
  Future<void> search(String text) async {
    final q = text.trim();
    _clearSuggestions();
    if (q.isEmpty) {
      notifyListeners();
      return;
    }
    categoryId = null;
    _showPanel('Kết quả cho “$q”', []);
    isPanelLoading = true;
    notifyListeners();
    try {
      final found = await _dao.search(q);
      panelItems = found.places;
      panelCategories = found.categories;
      panelNote = found.externalNote;
    } on ApiException catch (e) {
      panelError = e.message;
    } finally {
      isPanelLoading = false;
      notifyListeners();
    }
  }

  /// "Địa điểm quanh đây" quanh điểm [lat], [lng] vừa chạm (màn hình chỉ gọi khi đã phóng to tới [nearbyZoom]).
  /// Người đã đăng nhập hỏi server (Senpai ơi + OpenStreetMap); khách xem địa điểm Senpai ơi trong 150 m.
  Future<void> loadNearby(double lat, double lng, {required bool signedIn}) async {
    categoryId = null;
    _showPanel(nearbyTitle, []);
    if (!signedIn) {
      final near = [
        for (final p in overview?.places ?? const <MapPlace>[])
          if (p.status == 'ACTIVE' && mapDistanceMeters(lat, lng, p.lat, p.lng) <= nearbyRadius) p,
      ]..sort((a, b) => mapDistanceMeters(lat, lng, a.lat, a.lng).compareTo(mapDistanceMeters(lat, lng, b.lat, b.lng)));
      panelItems = [for (final p in near) _option(p, categoryById(p.categoryId)?.name ?? '')];
      panelNote = near.isEmpty
          ? 'Không có địa điểm Senpai ơi nào trong khoảng 150 m. Đăng nhập để xem thêm địa điểm từ OpenStreetMap.'
          : 'Đăng nhập để xem thêm địa điểm từ OpenStreetMap.';
      notifyListeners();
      return;
    }
    isPanelLoading = true;
    notifyListeners();
    try {
      final found = await _dao.findNearby(lat, lng);
      panelItems = found.places;
      panelNote = [
        found.externalNote,
        if (found.places.isEmpty)
          'Không có địa điểm có tên nào trong khoảng 150 m. Hãy chạm gần cửa hàng, nhà ga hoặc công viên hơn.',
      ].where((s) => s.isNotEmpty).join(' ');
    } on ApiException catch (e) {
      panelError = e.message;
    } finally {
      isPanelLoading = false;
      notifyListeners();
    }
  }

  /// Đóng bảng kết quả và bỏ lọc danh mục.
  void closePanel() {
    categoryId = null;
    _closePanel();
    notifyListeners();
  }

  void _showPanel(String title, List<PlaceOption> items) {
    panelTitle = title;
    panelItems = items;
    panelCategories = [];
    panelNote = '';
    panelError = null;
  }

  void _closePanel() {
    panelTitle = null;
    panelItems = [];
    panelCategories = [];
    panelNote = '';
    panelError = null;
    isPanelLoading = false;
  }

  /// Gần tôi nhất trước khi biết vị trí; không thì nhiều review nhất trước (giống danh sách của web).
  List<MapPlace> _sorted(List<MapPlace> list) {
    final me = myLocation;
    final sorted = [
      for (final p in list)
        if (p.status == 'ACTIVE') p,
    ];
    if (me != null) {
      sorted.sort((a, b) => distanceTo(a.lat, a.lng)!.compareTo(distanceTo(b.lat, b.lng)!));
    } else {
      sorted.sort((a, b) {
        final byCount = b.reviewCount.compareTo(a.reviewCount);
        return byCount != 0 ? byCount : (b.rating ?? 0).compareTo(a.rating ?? 0);
      });
    }
    return sorted;
  }

  static PlaceOption _option(MapPlace p, String categoryName) => PlaceOption(
    id: p.id,
    externalId: p.osmId,
    name: p.name,
    nameJa: p.nameJa,
    category: categoryName,
    source: p.source,
    lat: p.lat,
    lng: p.lng,
  );

  /// Khoảng cách (mét) từ vị trí của tôi; null khi chưa biết vị trí.
  double? distanceTo(double? lat, double? lng) {
    final me = myLocation;
    if (me == null || lat == null || lng == null) {
      return null;
    }
    return mapDistanceMeters(me.lat, me.lng, lat, lng);
  }

  /// "Vị trí của tôi". Môi trường thử nghiệm ngoài Nhật dùng vị trí giả lập của server (`devLocation`).
  /// Trả về câu cần báo cho người dùng (vị trí giả lập, hoặc không lấy được vị trí); null khi lấy được bình thường.
  Future<String?> locateMe() async {
    final dev = overview?.devLocation;
    if (dev != null) {
      myLocation = (lat: dev.lat, lng: dev.lng);
      notifyListeners();
      return 'Vị trí giả lập cho môi trường thử nghiệm: ${dev.label}';
    }
    isLocating = true;
    notifyListeners();
    final found = await _locator.current();
    isLocating = false;
    if (found != null) {
      myLocation = found;
    }
    notifyListeners();
    return found == null ? 'Không lấy được vị trí. Hãy bật định vị và cho phép ứng dụng dùng vị trí.' : null;
  }

  // ---------------------------------------------------------------- Chi tiết địa điểm

  PlaceDetail? detailOf(int placeId) => _details[placeId];
  String? detailErrorOf(int placeId) => _detailErrors[placeId];
  bool isLoadingDetail(int placeId) => _loadingDetails.contains(placeId);

  List<PlaceReview> reviewsOf(int placeId) => _reviews[placeId] ?? const [];
  bool isLoadingReviews(int placeId) => _loadingReviews.contains(placeId);
  bool hasMoreReviews(int placeId) => _reviewPages[placeId]?.hasMore ?? false;

  /// Lỗi khi tải review (hiện kèm nút Thử lại); null khi không lỗi.
  String? reviewErrorOf(int placeId) => _reviewErrors[placeId];

  /// null khi chưa tải.
  List<PlacePhrase>? phrasesOf(int placeId) => _phrases[placeId];
  bool isLoadingPhrases(int placeId) => _loadingPhrases.contains(placeId);

  /// Tải chi tiết và trang review đầu. Gọi lại để làm mới (sau khi viết / sửa / xóa review, sau khi đăng nhập).
  Future<void> loadPlace(int placeId) async {
    _loadingDetails.add(placeId);
    _detailErrors.remove(placeId);
    notifyListeners();
    try {
      _details[placeId] = await _dao.findById(placeId);
    } on ApiException catch (e) {
      _details.remove(placeId);
      _detailErrors[placeId] = e.message;
    } finally {
      _loadingDetails.remove(placeId);
      notifyListeners();
    }
    if (_details.containsKey(placeId)) {
      await loadReviews(placeId);
    }
  }

  /// Tải trang review đầu, hoặc trang sau khi [more] ("Xem thêm review").
  Future<void> loadReviews(int placeId, {bool more = false}) async {
    if (_loadingReviews.contains(placeId)) {
      return;
    }
    final page = more ? (_reviewPages[placeId]?.page ?? -1) + 1 : 0;
    _loadingReviews.add(placeId);
    _reviewErrors.remove(placeId);
    notifyListeners();
    try {
      final result = await _dao.findReviews(placeId, page: page);
      _reviewPages[placeId] = result;
      _reviews[placeId] = more ? [...reviewsOf(placeId), ...result.items] : result.items;
    } on ApiException catch (e) {
      _reviewErrors[placeId] = e.message;
    } finally {
      _loadingReviews.remove(placeId);
      notifyListeners();
    }
  }

  /// Từ vựng và mẫu câu theo danh mục (tải lần đầu mở phần này).
  Future<void> loadPhrases(int placeId) async {
    _loadingPhrases.add(placeId);
    notifyListeners();
    try {
      _phrases[placeId] = await _dao.findPhrases(placeId);
    } on ApiException catch (e) {
      _phrases[placeId] = [];
      message = e.message;
    } finally {
      _loadingPhrases.remove(placeId);
      notifyListeners();
    }
  }

  /// Lưu / Bỏ lưu: đổi ngay trên màn hình, server từ chối thì trả lại như cũ. Trả về true khi server đã ghi.
  Future<bool> toggleSave(int placeId) async {
    final old = _details[placeId];
    if (old == null) {
      return false;
    }
    final on = !old.saved;
    _details[placeId] = old.copyWith(saved: on);
    notifyListeners();
    try {
      message = on ? await _dao.save(old.id) : await _dao.unsave(old.id);
      return true;
    } on ApiException catch (e) {
      _details[placeId] = old;
      message = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// "Báo đã đóng cửa" (màn hình hỏi xác nhận trước). Trả về true khi server đã ghi nhận.
  Future<bool> reportClosed(int placeId) async {
    final old = _details[placeId];
    if (old == null) {
      return false;
    }
    try {
      final state = await _dao.reportClosed(old.id);
      _details[placeId] = (_details[placeId] ?? old).copyWith(closedReports: state.count, reportedClosed: true);
      message = state.message;
      return true;
    } on ApiException catch (e) {
      message = e.message;
      if (e.statusCode == 409) {
        // Đã báo từ trước (ví dụ trên web): hiện đúng trạng thái
        _details[placeId] = old.copyWith(reportedClosed: true);
      }
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Thích / bỏ thích review: đổi ngay, rồi lấy số lượt thích server đếm lại; lỗi thì trả lại như cũ.
  Future<void> toggleLike(int placeId, int reviewId) async {
    final list = _reviews[placeId];
    final index = list?.indexWhere((r) => r.id == reviewId) ?? -1;
    if (list == null || index < 0) {
      return;
    }
    final old = list[index];
    final on = !old.liked;
    _replaceReview(placeId, old.copyWith(liked: on, likeCount: old.likeCount + (on ? 1 : -1)));
    notifyListeners();
    try {
      final state = on ? await _dao.likeReview(reviewId) : await _dao.unlikeReview(reviewId);
      _replaceReview(placeId, old.copyWith(liked: state.active, likeCount: state.count));
    } on ApiException catch (e) {
      _replaceReview(placeId, old);
      message = e.message;
    } finally {
      notifyListeners();
    }
  }

  void _replaceReview(int placeId, PlaceReview review) {
    _reviews[placeId] = [for (final r in reviewsOf(placeId)) r.id == review.id ? review : r];
  }

  /// Báo cáo review (màn hình đã hỏi lý do). Thành công thì tải lại review: review có thể đã bị ẩn.
  Future<bool> reportReview(int placeId, int reviewId, int reasonId, String note) async {
    try {
      message = await _dao.reportReview(reviewId, reasonId, note);
    } on ApiException catch (e) {
      message = e.message;
      notifyListeners();
      return false;
    }
    notifyListeners();
    await loadReviews(placeId);
    return true;
  }

  /// "Nghe" câu tiếng Nhật; máy không đọc được thì để câu báo ở [message].
  Future<void> speak(String text) async {
    if (!await _speaker.speak(text)) {
      message = 'Thiết bị này không hỗ trợ đọc tiếng Nhật.';
      notifyListeners();
    }
  }

  /// Dừng đọc (khi rời màn chi tiết).
  Future<void> stopSpeaking() => _speaker.stop();

  /// Lấy câu thông báo để hiện SnackBar, rồi xóa để không hiện lại lần nữa.
  String? takeMessage() {
    final text = message;
    message = null;
    return text;
  }
}
