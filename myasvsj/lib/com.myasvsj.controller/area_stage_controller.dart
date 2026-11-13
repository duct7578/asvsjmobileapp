import 'package:flutter/foundation.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/area_dev_location.dart';
import 'package:myasvsj/com.myasvsj.model/area_option.dart';
import 'package:myasvsj/com.myasvsj.model/area_prefecture.dart';
import 'package:myasvsj/com.myasvsj.model/profile_dao.dart';
import 'package:myasvsj/com.myasvsj.model/profile_stage.dart';

/// Controller của màn "Khu vực và giai đoạn" (AreaStageScreen): chọn tỉnh → khu vực, tìm nhanh theo tên,
/// gợi ý theo vị trí, chọn giai đoạn, rồi lưu bằng `PUT /api/me/profile`.
///
/// Chỉ id khu vực được lưu; vị trí GPS chỉ dùng để hỏi khu vực gần nhất, không gửi đi đâu khác.
class AreaStageController extends ChangeNotifier {
  AreaStageController(this._dao);

  final ProfileDao _dao;

  // ----- Dữ liệu mở màn hình
  List<AreaPrefecture> prefectures = [];

  /// Vị trí cố định "Vị trí của tôi" dùng ở server thử; null ở server thật (dùng GPS).
  AreaDevLocation? devLocation;
  bool isLoading = false;
  String? error;

  // ----- Lựa chọn hiện tại
  /// PRE, ARR, LEAVE, HOME hoặc null (chưa chọn).
  String? stage;
  String? prefectureCode;

  /// Khu vực đang chọn; null khi chưa chọn.
  AreaOption? area;

  /// Khu vực của tỉnh đang chọn.
  List<AreaOption> areas = [];
  bool isLoadingAreas = false;
  String? areasError;
  final Map<String, List<AreaOption>> _areasByPrefecture = {};
  int _areasSeq = 0;

  // ----- Tìm nhanh
  String searchQuery = '';
  List<AreaOption> searchResults = [];
  bool isSearching = false;
  String? searchError;
  String _searchedQuery = '';
  int _searchSeq = 0;

  // ----- "Vị trí của tôi"
  AreaOption? suggested;
  bool isLocating = false;

  /// Câu báo nhẹ khi không lấy được vị trí hoặc vị trí không ở Nhật.
  String? locateMessage;

  // ----- Lưu
  bool isSaving = false;
  String? saveError;
  Map<String, String> fieldErrors = {};

  /// Câu của server sau khi lưu ("Đã lưu khu vực và giai đoạn."); màn hình lấy một lần bằng [takeMessage].
  String? message;

  /// Nhãn ô khu vực theo giai đoạn đang chọn.
  String get areaLabel => ProfileStage.areaLabel(stage);

  /// Đã tìm xong mà không có kết quả nào.
  bool get searchFoundNothing =>
      searchQuery.isNotEmpty &&
      !isSearching &&
      searchError == null &&
      _searchedQuery == searchQuery &&
      searchResults.isEmpty;

  AreaPrefecture? prefectureOf(String? code) {
    for (final p in prefectures) {
      if (p.code == code) {
        return p;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------- Mở màn hình

  /// Lấy danh sách tỉnh và hồ sơ (khu vực, giai đoạn đang lưu); có khu vực thì mở sẵn tỉnh của nó.
  Future<void> open() async {
    prefectures = [];
    devLocation = null;
    stage = null;
    prefectureCode = null;
    area = null;
    areas = [];
    areasError = null;
    searchQuery = '';
    searchResults = [];
    searchError = null;
    suggested = null;
    locateMessage = null;
    saveError = null;
    fieldErrors = {};
    error = null;
    isLoading = true;
    notifyListeners();
    try {
      final data = await _dao.findAreaPicker();
      final profile = await _dao.findProfile();
      prefectures = data.prefectures;
      devLocation = data.devLocation;
      stage = profile.stage;
      if (profile.areaId != null) {
        final current = await _findArea(profile.areaId!);
        if (current != null) {
          prefectureCode = current.prefectureCode;
          area = current;
          await _loadAreas(current.prefectureCode);
        }
      }
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Khu vực đang lưu đã bị tắt hay không còn: coi như chưa chọn, giống web.
  Future<AreaOption?> _findArea(int id) async {
    try {
      return await _dao.findArea(id);
    } on ApiException {
      return null;
    }
  }

  // ---------------------------------------------------------------- Chọn

  void selectStage(String? code) {
    stage = code;
    fieldErrors.remove('stage');
    notifyListeners();
  }

  /// Chọn tỉnh: bỏ khu vực đang chọn và tải danh sách khu vực của tỉnh đó.
  Future<void> selectPrefecture(String? code) async {
    if (code == prefectureCode) {
      return;
    }
    prefectureCode = code;
    area = null;
    areas = [];
    areasError = null;
    if (code == null) {
      notifyListeners();
      return;
    }
    await _loadAreas(code);
  }

  void selectArea(int? id) {
    area = null;
    for (final a in areas) {
      if (a.id == id) {
        area = a;
      }
    }
    notifyListeners();
  }

  /// Chọn một khu vực tìm được hoặc được gợi ý: mở tỉnh của nó và chọn sẵn.
  Future<void> chooseArea(AreaOption option) async {
    searchQuery = '';
    searchResults = [];
    suggested = null;
    locateMessage = null;
    prefectureCode = option.prefectureCode;
    area = option;
    areas = _areasByPrefecture[option.prefectureCode] ?? [];
    areasError = null;
    await _loadAreas(option.prefectureCode);
  }

  /// Bỏ chọn khu vực (lưu xong thì hồ sơ không còn khu vực).
  void clearArea() {
    prefectureCode = null;
    area = null;
    areas = [];
    areasError = null;
    notifyListeners();
  }

  /// Thử tải lại danh sách khu vực của tỉnh đang chọn sau khi lỗi.
  Future<void> retryAreas() async {
    final code = prefectureCode;
    if (code != null) {
      await _loadAreas(code);
    }
  }

  Future<void> _loadAreas(String code) async {
    final seq = ++_areasSeq;
    isLoadingAreas = true;
    areasError = null;
    notifyListeners();
    try {
      final list = _areasByPrefecture[code] ?? await _dao.findAreasInPrefecture(code);
      _areasByPrefecture[code] = list;
      if (seq == _areasSeq) {
        areas = list;
        // Dùng đúng phần tử của danh sách để ô chọn nhận ra khu vực đang chọn
        final chosen = area;
        if (chosen != null) {
          area = list.firstWhere((a) => a.id == chosen.id, orElse: () => chosen);
        }
      }
    } on ApiException catch (e) {
      if (seq == _areasSeq) {
        areasError = e.message;
      }
    } finally {
      if (seq == _areasSeq) {
        isLoadingAreas = false;
        notifyListeners();
      }
    }
  }

  // ---------------------------------------------------------------- Tìm nhanh

  /// Tìm khu vực theo tên (romaji, kanji, kana). Câu trả lời của lần tìm cũ đến muộn bị bỏ qua.
  Future<void> searchAreas(String text) async {
    final q = text.trim();
    final seq = ++_searchSeq;
    searchQuery = q;
    searchError = null;
    if (q.isEmpty) {
      searchResults = [];
      isSearching = false;
      notifyListeners();
      return;
    }
    isSearching = true;
    notifyListeners();
    try {
      final found = await _dao.searchAreas(q);
      if (seq == _searchSeq) {
        searchResults = found;
        _searchedQuery = q;
      }
    } on ApiException catch (e) {
      if (seq == _searchSeq) {
        searchResults = [];
        searchError = e.message;
      }
    } finally {
      if (seq == _searchSeq) {
        isSearching = false;
        notifyListeners();
      }
    }
  }

  // ---------------------------------------------------------------- "Vị trí của tôi"

  /// Màn hình bắt đầu lấy vị trí (đang chờ người dùng cho phép, hoặc chờ GPS).
  void startLocating() {
    isLocating = true;
    suggested = null;
    locateMessage = null;
    notifyListeners();
  }

  /// Không lấy được vị trí: báo nhẹ, vẫn chọn trong danh sách được.
  void locationUnavailable([String? text]) {
    isLocating = false;
    suggested = null;
    locateMessage =
        text ??
        'Không lấy được vị trí (bạn chưa cho phép hoặc thiết bị không hỗ trợ). '
            'Hãy chọn trong danh sách hoặc tìm theo tên.';
    notifyListeners();
  }

  /// Hỏi server khu vực gần vị trí nhất để người dùng xác nhận bằng [useSuggested].
  Future<void> suggestNearest(double lat, double lng) async {
    isLocating = true;
    suggested = null;
    locateMessage = null;
    notifyListeners();
    try {
      suggested = await _dao.findNearestArea(lat, lng);
    } on ApiException catch (e) {
      locateMessage = e.message;
    } finally {
      isLocating = false;
      notifyListeners();
    }
  }

  Future<void> useSuggested() async {
    final option = suggested;
    if (option != null) {
      await chooseArea(option);
    }
  }

  // ---------------------------------------------------------------- Lưu

  /// Kiểm tra trước khi gửi (server kiểm tra lại): giai đoạn phải là một trong bốn mã.
  static Map<String, String> validate({String? stage}) => {
    if (stage != null && ProfileStage.labelOf(stage) == null) 'stage': 'Giai đoạn không hợp lệ',
  };

  /// Lưu khu vực và giai đoạn (cả hai không bắt buộc). Trả về true khi server đã lưu.
  Future<bool> save() async {
    saveError = null;
    fieldErrors = validate(stage: stage);
    if (fieldErrors.isNotEmpty) {
      notifyListeners();
      return false;
    }
    isSaving = true;
    notifyListeners();
    try {
      final result = await _dao.updateAreaStage(areaId: area?.id, stage: stage);
      message = result.message;
      stage = result.profile.stage;
      return true;
    } on ApiException catch (e) {
      saveError = e.message;
      fieldErrors = e.fields;
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Lấy câu thông báo để hiện SnackBar, rồi xóa để không hiện lại.
  String? takeMessage() {
    final text = message;
    message = null;
    return text;
  }
}
