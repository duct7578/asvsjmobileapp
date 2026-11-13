import 'package:flutter/foundation.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/interest_topic.dart';
import 'package:myasvsj/com.myasvsj.model/point_line.dart';
import 'package:myasvsj/com.myasvsj.model/profile_dao.dart';
import 'package:myasvsj/com.myasvsj.model/user_profile.dart';

/// Controller của trang "Tôi" (ProfileScreen) và "Lịch sử điểm" (PointHistoryScreen).
///
/// Khu vực và giai đoạn, chủ đề quan tâm, xin tag có Controller riêng (AreaStageController, InterestController,
/// TagRequestController); trang Tôi tải lại hồ sơ khi người dùng quay về từ các màn đó.
class ProfileController extends ChangeNotifier {
  ProfileController(this._dao);

  final ProfileDao _dao;

  // ----- Hồ sơ (ProfileScreen)
  UserProfile? profile;

  /// Chủ đề quan tâm đã chọn, hiện dưới mục "Chủ đề quan tâm"; rỗng khi chưa chọn hoặc không tải được.
  List<InterestTopic> chosenInterests = [];
  bool isLoading = false;
  String? error;

  // ----- Lịch sử điểm (PointHistoryScreen)
  List<PointLine> pointLines = [];

  /// Số dòng lịch sử của mọi trang.
  int pointsTotal = 0;

  /// Điểm hiện có.
  int points = 0;
  bool hasMorePoints = false;
  bool isLoadingPoints = false;
  bool isLoadingMorePoints = false;

  /// Lỗi tải trang đầu (cả màn hình hiện lỗi).
  String? pointsError;

  /// Lỗi tải trang sau (danh sách vẫn giữ, cuối danh sách có nút Thử lại).
  String? morePointsError;
  int _pointsPage = 0;

  // ---------------------------------------------------------------- Hồ sơ

  /// Tải hồ sơ và chủ đề quan tâm đã chọn. Đang có hồ sơ thì vẫn giữ để hiện trong lúc tải lại.
  Future<void> loadProfile() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      // Hai lời gọi chạy song song; chủ đề quan tâm lỗi thì chỉ không hiện tên chủ đề
      final interests = _loadChosenInterests();
      profile = await _dao.findProfile();
      chosenInterests = await interests;
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<InterestTopic>> _loadChosenInterests() async {
    try {
      return (await _dao.findInterests()).chosen;
    } on ApiException {
      return [];
    }
  }

  /// Xóa dữ liệu của người vừa đăng xuất, để người đăng nhập sau không thấy nhầm.
  void clear() {
    profile = null;
    chosenInterests = [];
    error = null;
    pointLines = [];
    pointsTotal = 0;
    points = 0;
    hasMorePoints = false;
    pointsError = null;
    morePointsError = null;
    _pointsPage = 0;
    notifyListeners();
  }

  // ---------------------------------------------------------------- Lịch sử điểm

  /// Tải trang đầu của lịch sử điểm. Mở màn hình thì xóa danh sách cũ (có thể của người khác);
  /// kéo xuống làm mới thì [keepShown] để danh sách đang hiện không biến mất.
  Future<void> loadPoints({bool keepShown = false}) async {
    if (!keepShown) {
      pointLines = [];
      pointsTotal = 0;
      hasMorePoints = false;
    }
    isLoadingPoints = true;
    pointsError = null;
    morePointsError = null;
    notifyListeners();
    try {
      final page = await _dao.findPointHistory();
      pointLines = page.items;
      pointsTotal = page.total;
      points = page.points;
      hasMorePoints = page.hasMore;
      _pointsPage = page.page;
    } on ApiException catch (e) {
      pointsError = e.message;
    } finally {
      isLoadingPoints = false;
      notifyListeners();
    }
  }

  /// Tải trang sau và nối vào cuối; bỏ qua khi đang tải hoặc đã hết.
  Future<void> loadMorePoints() async {
    if (!hasMorePoints || isLoadingPoints || isLoadingMorePoints) {
      return;
    }
    isLoadingMorePoints = true;
    morePointsError = null;
    notifyListeners();
    try {
      final page = await _dao.findPointHistory(page: _pointsPage + 1);
      // Điểm mới được cộng giữa hai lần tải đẩy dòng cũ sang trang sau: không hiện một dòng hai lần
      final shown = {for (final line in pointLines) line.id};
      pointLines = [...pointLines, ...page.items.where((line) => !shown.contains(line.id))];
      pointsTotal = page.total;
      points = page.points;
      hasMorePoints = page.hasMore;
      _pointsPage = page.page;
    } on ApiException catch (e) {
      morePointsError = e.message;
    } finally {
      isLoadingMorePoints = false;
      notifyListeners();
    }
  }
}
