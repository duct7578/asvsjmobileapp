import 'package:flutter/foundation.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/event.dart';
import 'package:myasvsj/com.myasvsj.model/event_dao.dart';
import 'package:myasvsj/com.myasvsj.model/event_detail.dart';
import 'package:myasvsj/com.myasvsj.model/event_review.dart';
import 'package:myasvsj/com.myasvsj.model/event_review_form.dart';

/// Controller của "Lễ hội và sự kiện": danh sách, chi tiết, form viết / sửa review và các thao tác trên review
/// (thích, báo cáo, xóa).
///
/// Chi tiết lưu theo id sự kiện, vì màn chi tiết có thể mở chồng nhau (từ thông báo, từ tìm kiếm…).
class EventController extends ChangeNotifier {
  EventController(this._dao);

  final EventDao _dao;

  /// Sự kiện bắt đầu trong chừng này ngày thuộc nhóm "Trong 30 ngày tới" (như web).
  static const int soonDays = 30;

  // ----- Danh sách (EventListScreen)
  List<Event> events = [];
  bool isLoading = false;
  String? error;

  /// Từ khóa đang tìm.
  String query = '';

  /// Số thứ tự lần tải danh sách: kết quả của lần tìm cũ về muộn thì bỏ qua.
  int _listTicket = 0;

  // ----- Chi tiết (EventDetailScreen), theo id sự kiện
  final Map<int, EventDetail> _details = {};
  final Set<int> _loadingDetails = {};
  final Map<int, String> _detailErrors = {};

  /// Review đang chờ server trả lời lượt thích (khóa nút để không bấm hai lần).
  final Set<int> _liking = {};

  // ----- Form viết / sửa review (EventReviewFormScreen)
  EventReviewForm? form;
  bool isLoadingForm = false;
  bool isSaving = false;
  String? formError;
  Map<String, String> fieldErrors = {};

  /// Câu thông báo của server sau một thao tác; màn hình hiện một lần bằng [takeMessage].
  String? message;

  // ---------------------------------------------------------------- Danh sách

  /// Nhóm "Đang diễn ra".
  List<Event> get nowEvents => [
    for (final e in events)
      if (e.isNow) e,
  ];

  /// Nhóm "Trong 30 ngày tới".
  List<Event> get soonEvents => [
    for (final e in events)
      if (e.isUpcoming && e.daysUntil <= soonDays) e,
  ];

  /// Nhóm "Sau này".
  List<Event> get laterEvents => [
    for (final e in events)
      if (e.isUpcoming && e.daysUntil > soonDays) e,
  ];

  /// Nhóm "Đã diễn ra", vừa kết thúc trước: đó là sự kiện người ta muốn review nhất.
  List<Event> get pastEvents => [
    for (final e in events.reversed)
      if (e.isPast) e,
  ];

  /// Tải danh sách; [q] khác null là tìm từ khóa mới, null là tải lại với từ khóa đang có.
  Future<void> loadEvents({String? q}) async {
    if (q != null) {
      query = q.trim();
    }
    final ticket = ++_listTicket;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _dao.findAll(q: query);
      if (ticket == _listTicket) {
        events = result;
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

  // ---------------------------------------------------------------- Chi tiết

  EventDetail? detailOf(int eventId) => _details[eventId];

  bool isLoadingDetail(int eventId) => _loadingDetails.contains(eventId);

  /// Lỗi khi chưa tải được lần nào (màn hình hiện ErrorView); null khi không lỗi.
  String? detailErrorOf(int eventId) => _detailErrors[eventId];

  bool isLiking(int reviewId) => _liking.contains(reviewId);

  /// Tải (hoặc tải lại) chi tiết. Tải lại lỗi mà đã có dữ liệu thì giữ dữ liệu cũ và báo bằng [message].
  Future<void> loadEvent(int eventId) async {
    _loadingDetails.add(eventId);
    _detailErrors.remove(eventId);
    notifyListeners();
    try {
      _details[eventId] = await _dao.findById(eventId);
    } on ApiException catch (e) {
      if (_details.containsKey(eventId) && e.statusCode != 404) {
        message = e.message;
      } else {
        _details.remove(eventId);
        _detailErrors[eventId] = e.message;
      }
    } finally {
      _loadingDetails.remove(eventId);
      notifyListeners();
    }
  }

  /// Thích / bỏ thích review của người khác. Cập nhật ngay trên màn hình (lạc quan), rồi lấy số của server;
  /// server từ chối thì hoàn tác và giữ câu báo lỗi ở [message].
  Future<void> toggleLike(int eventId, int reviewId) async {
    final review = _findReview(eventId, reviewId);
    if (review == null || _liking.contains(reviewId)) {
      return;
    }
    final on = !review.liked;
    final guess = review.likeCount + (on ? 1 : -1);
    _liking.add(reviewId);
    _replaceReview(eventId, review.copyWith(liked: on, likeCount: guess < 0 ? 0 : guess));
    notifyListeners();
    try {
      final state = on ? await _dao.likeReview(reviewId) : await _dao.unlikeReview(reviewId);
      _replaceReview(eventId, review.copyWith(liked: state.liked, likeCount: state.likeCount));
    } on ApiException catch (e) {
      _replaceReview(eventId, review);
      message = e.message;
    } finally {
      _liking.remove(reviewId);
      notifyListeners();
    }
  }

  /// Báo cáo review; trả về true khi server đã nhận. Câu thông báo (thành công hay lỗi) nằm ở [message].
  Future<bool> reportReview(int eventId, int reviewId, {required int reasonId, String note = ''}) async {
    try {
      message = await _dao.reportReview(reviewId, reasonId: reasonId, note: note);
      // Review có thể vừa bị ẩn vì quá nhiều báo cáo
      await _reloadQuietly(eventId);
      return true;
    } on ApiException catch (e) {
      message = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Xóa review của chính mình; trả về true khi server đã xóa.
  Future<bool> deleteReview(int eventId, int reviewId) async {
    try {
      message = await _dao.deleteReview(reviewId);
      await _reloadQuietly(eventId);
      await _reloadListQuietly();
      return true;
    } on ApiException catch (e) {
      message = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- Form viết / sửa review

  /// Mở form: sự kiện, giới hạn, hạn mức hôm nay và review năm nay của người xem (khi có thì là form sửa).
  Future<void> openReviewForm(int eventId) async {
    form = null;
    formError = null;
    fieldErrors = {};
    isLoadingForm = true;
    notifyListeners();
    try {
      form = await _dao.findReviewForm(eventId);
    } on ApiException catch (e) {
      formError = e.message;
    } finally {
      isLoadingForm = false;
      notifyListeners();
    }
  }

  /// Gửi form: đăng review mới, hoặc lưu review đang sửa với [keepMediaIds] (ảnh / video cũ giữ lại).
  /// [imagePaths] là ảnh mới trên máy. Trả về true khi server đã lưu; câu của server nằm ở [message].
  Future<bool> saveReview({
    required int rating,
    required String content,
    List<int> keepMediaIds = const [],
    List<String> imagePaths = const [],
  }) async {
    final current = form;
    if (current == null || isSaving) {
      return false;
    }
    final own = current.review;
    final keptImages = own == null ? 0 : own.images.where((m) => keepMediaIds.contains(m.id)).length;
    formError = null;
    fieldErrors = validateReview(
      rating: rating,
      content: content,
      imageCount: keptImages + imagePaths.length,
      contentMax: current.contentMax,
      imagesMax: current.imagesMax,
    );
    if (fieldErrors.isNotEmpty) {
      notifyListeners();
      return false;
    }
    isSaving = true;
    notifyListeners();
    try {
      final text = content.trim();
      message = own == null
          ? await _dao.createReview(current.event.id, rating: rating, content: text, imagePaths: imagePaths)
          : await _dao.updateReview(
              own.id,
              rating: rating,
              content: text,
              keepMediaIds: keepMediaIds,
              imagePaths: imagePaths,
            );
      await _reloadQuietly(current.event.id);
      await _reloadListQuietly();
      return true;
    } on ApiException catch (e) {
      formError = e.message;
      fieldErrors = e.fields;
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  /// Kiểm tra trước khi gửi, cùng luật và câu chữ với server (EventRules.checkReview); rỗng khi hợp lệ.
  static Map<String, String> validateReview({
    required int rating,
    required String content,
    int imageCount = 0,
    int contentMax = 2000,
    int imagesMax = 5,
  }) {
    final errors = <String, String>{};
    if (rating < 1 || rating > 5) {
      errors['rating'] = 'Hãy chọn số sao (1 đến 5).';
    }
    final text = content.trim();
    if (text.isEmpty) {
      errors['content'] = 'Hãy viết vài dòng về sự kiện.';
    } else if (text.length > contentMax) {
      errors['content'] = 'Nội dung tối đa ${_thousands(contentMax)} ký tự (hiện có ${text.length}).';
    }
    if (imageCount > imagesMax) {
      errors['images'] = 'Tối đa $imagesMax ảnh.';
    }
    return errors;
  }

  /// Lấy câu thông báo để hiện SnackBar, rồi xóa để không hiện lại lần nữa.
  String? takeMessage() {
    final text = message;
    message = null;
    return text;
  }

  // ---------------------------------------------------------------- Phụ trợ

  EventReview? _findReview(int eventId, int reviewId) {
    for (final review in _details[eventId]?.reviews ?? const <EventReview>[]) {
      if (review.id == reviewId) {
        return review;
      }
    }
    return null;
  }

  void _replaceReview(int eventId, EventReview review) {
    final detail = _details[eventId];
    if (detail == null) {
      return;
    }
    _details[eventId] = detail.copyWith(reviews: [for (final r in detail.reviews) r.id == review.id ? review : r]);
  }

  /// Tải lại chi tiết sau một thao tác ghi; lỗi tải lại không che câu thông báo của thao tác.
  Future<void> _reloadQuietly(int eventId) async {
    try {
      _details[eventId] = await _dao.findById(eventId);
    } on ApiException {
      // Giữ dữ liệu cũ; người dùng kéo xuống để tải lại
    }
  }

  /// Điểm trung bình và số review trên thẻ danh sách cũng đổi khi review được đăng hay xóa.
  Future<void> _reloadListQuietly() async {
    if (events.isEmpty) {
      return;
    }
    try {
      events = await _dao.findAll(q: query);
    } on ApiException {
      // Danh sách cũ vẫn dùng được
    }
  }

  /// 2000 → "2.000", kiểu số Việt Nam như câu của server.
  static String _thousands(int value) => value.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
}
