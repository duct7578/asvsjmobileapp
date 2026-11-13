import 'package:flutter/foundation.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/guide.dart';
import 'package:myasvsj/com.myasvsj.model/guide_dao.dart';
import 'package:myasvsj/com.myasvsj.model/guide_my_progress.dart';
import 'package:myasvsj/com.myasvsj.model/guide_option.dart';
import 'package:myasvsj/com.myasvsj.model/guide_preparation.dart';
import 'package:myasvsj/com.myasvsj.model/guide_progress.dart';
import 'package:myasvsj/com.myasvsj.model/guide_viewer.dart';

/// Controller của "Cẩm nang": danh sách có bộ lọc (giai đoạn, chủ đề, từ khóa, sắp xếp, phân trang), trang chi tiết
/// (trạng thái người xem, checklist "Hướng dẫn chuẩn bị", Lưu, Đánh dấu đã xong) và "Cẩm nang của tôi".
///
/// Chi tiết lưu theo id cẩm nang, vì màn chi tiết có thể mở chồng nhau.
class GuideController extends ChangeNotifier {
  GuideController(this._dao);

  final GuideDao _dao;

  // ----- Danh sách (GuideListScreen)
  /// Bốn giai đoạn và các chủ đề để lọc, lấy từ server.
  List<GuideOption> stages = [];
  List<GuideOption> topics = [];

  /// Bộ lọc đang chọn: mã giai đoạn, mã chủ đề (null = tất cả), từ khóa, cách sắp xếp.
  String? stage;
  String? topic;
  String query = '';
  String sort = 'NEWEST';

  List<Guide> guides = [];
  int totalItems = 0;
  bool hasMore = false;
  bool isLoading = false;
  bool isLoadingMore = false;
  String? error;
  int _page = 0;

  /// Số thứ tự lần tải trang đầu: kết quả của bộ lọc cũ về muộn thì bỏ qua.
  int _listTicket = 0;

  // ----- Chi tiết (GuideDetailScreen), theo id cẩm nang
  final Map<int, Guide> _guides = {};
  final Map<int, GuideViewer> _viewers = {};
  final Map<int, GuidePreparation> _preparations = {};
  final Set<int> _loadingGuides = {};
  final Map<int, String> _guideErrors = {};
  final Map<int, String> _preparationErrors = {};

  /// Cẩm nang đang chờ server trả lời "Lưu" / "Đánh dấu đã xong".
  final Set<int> _busy = {};

  /// Cẩm nang đang chờ server lưu một dấu tick.
  final Set<int> _ticking = {};

  // ----- Cẩm nang của tôi (MyGuidesScreen)
  GuideMyProgress? myProgress;
  bool isLoadingMy = false;
  String? myError;

  /// Câu thông báo của server sau một thao tác; màn hình hiện một lần bằng [takeMessage].
  String? message;

  // ---------------------------------------------------------------- Danh sách

  /// Mở danh sách: bỏ bộ lọc cũ, chọn sẵn giai đoạn [stage] (mã của server, null = tất cả), tải lựa chọn lọc
  /// (một lần) và trang đầu.
  Future<void> openList({String? stage}) {
    this.stage = stage;
    topic = null;
    query = '';
    sort = 'NEWEST';
    return loadGuides();
  }

  /// Tải trang đầu với bộ lọc đang chọn (kéo xuống làm mới, Thử lại). Lựa chọn lọc chưa có (lần đầu, hoặc lần
  /// trước lỗi mạng) thì lấy cùng lúc.
  Future<void> loadGuides() async {
    final ticket = ++_listTicket;
    isLoading = true;
    isLoadingMore = false;
    error = null;
    notifyListeners();
    try {
      final options = stages.isEmpty || topics.isEmpty ? _loadOptions() : Future<void>.value();
      final result = await _dao.findAll(stage: stage, topic: topic, q: query, sort: sort);
      await options;
      if (ticket == _listTicket) {
        guides = result.items;
        totalItems = result.totalItems;
        hasMore = result.hasMore;
        _page = result.page;
      }
    } on ApiException catch (e) {
      if (ticket == _listTicket) {
        error = e.message;
      }
    } finally {
      if (ticket == _listTicket) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Tải trang sau (cuộn tới cuối / "Tải thêm"). Lỗi thì giữ danh sách đang có và báo bằng [message].
  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasMore) {
      return;
    }
    final ticket = _listTicket;
    isLoadingMore = true;
    notifyListeners();
    try {
      final result = await _dao.findAll(stage: stage, topic: topic, q: query, sort: sort, page: _page + 1);
      if (ticket == _listTicket) {
        guides = [...guides, ...result.items];
        totalItems = result.totalItems;
        hasMore = result.hasMore;
        _page = result.page;
      }
    } on ApiException catch (e) {
      if (ticket == _listTicket) {
        message = e.message;
      }
    } finally {
      if (ticket == _listTicket) {
        isLoadingMore = false;
      }
      notifyListeners();
    }
  }

  /// Lọc theo giai đoạn (null = tất cả giai đoạn).
  Future<void> selectStage(String? code) {
    stage = code;
    return loadGuides();
  }

  /// Lọc theo chủ đề (null = tất cả).
  Future<void> selectTopic(String? code) {
    topic = code;
    return loadGuides();
  }

  /// Sắp xếp: NEWEST, OLDEST hoặc TITLE (xem [GuideDao.sorts]).
  Future<void> selectSort(String value) {
    sort = GuideDao.sorts.contains(value) ? value : 'NEWEST';
    return loadGuides();
  }

  /// Tìm theo tiêu đề, chủ đề hoặc từ khóa trong nội dung. Server nhận tối đa 200 ký tự.
  Future<void> search(String text) {
    final q = text.trim();
    query = q.length > 200 ? q.substring(0, 200) : q;
    return loadGuides();
  }

  Future<void> _loadOptions() async {
    try {
      final results = await Future.wait([_dao.findStages(), _dao.findTopics()]);
      stages = results[0];
      topics = results[1];
      notifyListeners();
    } on ApiException {
      // Không có lựa chọn lọc thì vẫn xem được danh sách; lần tải sau sẽ thử lại
    }
  }

  // ---------------------------------------------------------------- Chi tiết

  Guide? guideOf(int id) => _guides[id];

  /// Trạng thái người xem; null khi chưa tải được (màn hình bỏ hàng nút, vẫn hiện cẩm nang như web).
  GuideViewer? viewerOf(int id) => _viewers[id];

  GuidePreparation? preparationOf(int id) => _preparations[id];

  bool isLoadingGuide(int id) => _loadingGuides.contains(id);

  String? guideErrorOf(int id) => _guideErrors[id];

  String? preparationErrorOf(int id) => _preparationErrors[id];

  bool isBusy(int id) => _busy.contains(id);

  bool isTicking(int id) => _ticking.contains(id);

  /// Tải cẩm nang, trạng thái người xem và checklist (khi có). Tải lại lỗi mà đã có dữ liệu thì giữ dữ liệu cũ.
  Future<void> loadGuide(int id) async {
    _loadingGuides.add(id);
    _guideErrors.remove(id);
    notifyListeners();
    try {
      final guide = await _dao.findById(id);
      _guides[id] = guide;
      await Future.wait([_loadViewer(id), if (guide.preparationEnabled) _loadPreparation(id)]);
      _syncProgress(id);
    } on ApiException catch (e) {
      if (_guides.containsKey(id) && e.statusCode != 404) {
        message = e.message;
      } else {
        _guides.remove(id);
        _guideErrors[id] = e.message;
      }
    } finally {
      _loadingGuides.remove(id);
      notifyListeners();
    }
  }

  /// Tải lại riêng checklist ("Tải lại danh sách").
  Future<void> loadPreparation(int id) async {
    await _loadPreparation(id);
    _syncProgress(id);
    notifyListeners();
  }

  /// Tick / bỏ tick một việc. Thành viên: hiện ngay rồi lưu lên server, lỗi thì hoàn tác.
  /// Khách: chỉ tick trên máy để tự theo dõi, không lưu (màn hình nói rõ điều này).
  Future<void> toggleTask(int guideId, int taskId, bool completed) async {
    final before = _preparations[guideId];
    if (before == null || _ticking.contains(guideId)) {
      return;
    }
    _preparations[guideId] = before.withTask(taskId, completed);
    _syncProgress(guideId);
    if (!before.signedIn) {
      notifyListeners();
      return;
    }
    _ticking.add(guideId);
    notifyListeners();
    try {
      _preparations[guideId] = await _dao.checkTask(guideId, taskId, completed);
    } on ApiException catch (e) {
      _preparations[guideId] = before;
      message = '${e.message} Tiến độ chưa được thay đổi.';
    } finally {
      _syncProgress(guideId);
      _ticking.remove(guideId);
      notifyListeners();
    }
  }

  /// "Lưu" / "Bỏ lưu" (thành viên). Đổi nút ngay, lỗi thì hoàn tác; câu của server ở [message].
  Future<void> toggleSave(int id) async {
    final viewer = _viewers[id];
    if (viewer == null || _busy.contains(id)) {
      return;
    }
    final on = !viewer.saved;
    _busy.add(id);
    _viewers[id] = viewer.copyWith(saved: on);
    notifyListeners();
    try {
      message = on ? await _dao.save(id) : await _dao.unsave(id);
    } on ApiException catch (e) {
      _viewers[id] = (_viewers[id] ?? viewer).copyWith(saved: viewer.saved);
      message = e.message;
    } finally {
      _busy.remove(id);
      notifyListeners();
    }
  }

  /// "Đánh dấu đã xong" / bỏ đánh dấu, chỉ cho cẩm nang không có checklist. Đổi nút ngay, lấy tiến độ của server,
  /// lỗi thì hoàn tác.
  Future<void> toggleDone(int id) async {
    final viewer = _viewers[id];
    if (viewer == null || viewer.progress.checklist || _busy.contains(id)) {
      return;
    }
    final on = !viewer.progress.done;
    _busy.add(id);
    _viewers[id] = viewer.copyWith(
      progress: GuideProgress(done: on, percent: on ? 100 : 0),
    );
    notifyListeners();
    try {
      final answer = on ? await _dao.markDone(id) : await _dao.unmarkDone(id);
      _viewers[id] = (_viewers[id] ?? viewer).copyWith(progress: answer.progress);
      message = answer.message;
    } on ApiException catch (e) {
      _viewers[id] = (_viewers[id] ?? viewer).copyWith(progress: viewer.progress);
      message = e.message;
    } finally {
      _busy.remove(id);
      notifyListeners();
    }
  }

  Future<void> _loadViewer(int id) async {
    try {
      _viewers[id] = await _dao.findViewer(id);
    } on ApiException {
      _viewers.remove(id);
    }
  }

  Future<void> _loadPreparation(int id) async {
    _preparationErrors.remove(id);
    try {
      _preparations[id] = await _dao.findPreparation(id);
    } on ApiException catch (e) {
      _preparationErrors[id] = e.message;
    }
  }

  /// Checklist mới hơn tiến độ trong trạng thái người xem: số việc trên nút "Tiến độ" đi theo dấu tick.
  void _syncProgress(int id) {
    final viewer = _viewers[id];
    final preparation = _preparations[id];
    if (viewer != null && preparation != null && preparation.total > 0) {
      _viewers[id] = viewer.copyWith(progress: GuideProgress.fromPreparation(preparation));
    }
  }

  // ---------------------------------------------------------------- Cẩm nang của tôi

  /// Tiến độ 4 giai đoạn, checklist đang làm, cẩm nang vừa xong. Chỉ thành viên gọi được.
  Future<void> loadMyProgress() async {
    isLoadingMy = true;
    myError = null;
    notifyListeners();
    try {
      myProgress = await _dao.findMyProgress();
    } on ApiException catch (e) {
      myError = e.message;
    } finally {
      isLoadingMy = false;
      notifyListeners();
    }
  }

  /// Lấy câu thông báo để hiện SnackBar, rồi xóa để không hiện lại lần nữa.
  String? takeMessage() {
    final text = message;
    message = null;
    return text;
  }
}
