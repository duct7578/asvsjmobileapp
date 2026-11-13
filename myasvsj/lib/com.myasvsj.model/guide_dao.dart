import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/api_response.dart';
import 'package:myasvsj/com.myasvsj.model/guide.dart';
import 'package:myasvsj/com.myasvsj.model/guide_my_progress.dart';
import 'package:myasvsj/com.myasvsj.model/guide_option.dart';
import 'package:myasvsj/com.myasvsj.model/guide_preparation.dart';
import 'package:myasvsj/com.myasvsj.model/guide_progress.dart';
import 'package:myasvsj/com.myasvsj.model/guide_viewer.dart';
import 'package:myasvsj/com.myasvsj.model/page_result.dart';

/// Truy cập dữ liệu "Cẩm nang" qua REST API của web: bảng `guide_items`, `guide_sections`, checklist
/// `guide_preparation_tasks` / `guide_preparation_progress`, `saved_guides` và `user_guide_progress`.
///
/// | Hàm              | API                                          |
/// |------------------|----------------------------------------------|
/// | findStages       | GET /api/guides/topics                       |
/// | findTopics       | GET /api/guides/subjects                     |
/// | findAll          | GET /api/guides/browse                       |
/// | findById         | GET /api/guides/{id}                         |
/// | findViewer       | GET /api/guides/{id}/viewer                  |
/// | findPreparation  | GET /api/guides/{id}/preparation             |
/// | checkTask        | PUT /api/guides/{id}/preparation/{taskId}    |
/// | save / unsave    | POST / DELETE /api/guides/{id}/save          |
/// | markDone / unmarkDone | POST / DELETE /api/guides/{id}/done     |
/// | findMyProgress   | GET /api/me/guides/progress                  |
class GuideDao {
  GuideDao(this._api);

  final ApiClient _api;

  /// Số cẩm nang mỗi trang (như trang /guides của web).
  static const int pageSize = 12;

  /// Cách sắp xếp server nhận: mới nhất, cũ nhất, tiêu đề A–Z.
  static const List<String> sorts = ['NEWEST', 'OLDEST', 'TITLE'];

  /// Bốn giai đoạn theo thứ tự (PRE, ARR, LEAVE, HOME). Ai cũng xem được.
  Future<List<GuideOption>> findStages() async => _options(await _api.get('/api/guides/topics'));

  /// Các chủ đề (LIVING, PROCEDURES…). Ai cũng xem được.
  Future<List<GuideOption>> findTopics() async => _options(await _api.get('/api/guides/subjects'));

  /// Một trang cẩm nang đã đăng (trang đầu là 0), lọc theo mã giai đoạn [stage], mã chủ đề [topic] và từ khóa [q]
  /// (tìm trong tiêu đề, tóm tắt, tên chủ đề và nội dung), sắp xếp theo [sort] (một trong [sorts]).
  Future<PageResult<Guide>> findAll({
    String? stage,
    String? topic,
    String? q,
    String sort = 'NEWEST',
    int page = 0,
  }) async {
    final data =
        await _api.get(
              '/api/guides/browse',
              query: {
                if (stage != null && stage.isNotEmpty) 'category': stage,
                if (topic != null && topic.isNotEmpty) 'topicCode': topic,
                if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
                'sort': sort,
                'page': page,
                'size': pageSize,
              },
            )
            as Map<String, dynamic>;
    // BrowsePage của web gọi tổng số là `total` (không phải `totalItems` như các danh sách khác)
    return PageResult(
      items: [for (final item in (data['items'] as List?) ?? const []) Guide.fromJson(item as Map<String, dynamic>)],
      page: (data['page'] ?? 0) as int,
      size: (data['size'] ?? pageSize) as int,
      totalItems: (data['total'] ?? 0) as int,
      totalPages: (data['totalPages'] ?? 0) as int,
    );
  }

  /// Chi tiết một cẩm nang đã đăng: các mục, nguồn, checklist. Cẩm nang nháp hoặc đã xóa → 404.
  Future<Guide> findById(int id) async => Guide.fromJson(await _api.get('/api/guides/$id') as Map<String, dynamic>);

  /// Người xem với cẩm nang: đã lưu chưa, tiến độ, việc tiếp theo. Khách cũng gọi được.
  Future<GuideViewer> findViewer(int id) async =>
      GuideViewer.fromJson(await _api.get('/api/guides/$id/viewer') as Map<String, dynamic>);

  /// Checklist "Hướng dẫn chuẩn bị" với dấu tick của người xem (khách: chưa tick việc nào).
  /// Cẩm nang không có checklist → 404 "Không tìm thấy danh sách chuẩn bị.".
  Future<GuidePreparation> findPreparation(int id) async =>
      GuidePreparation.fromJson(await _api.get('/api/guides/$id/preparation') as Map<String, dynamic>);

  /// Tick hoặc bỏ tick một việc; trả về checklist mới. Cần đăng nhập (khách → 401).
  Future<GuidePreparation> checkTask(int guideId, int taskId, bool completed) async {
    final response = await _api.put('/api/guides/$guideId/preparation/$taskId', {'completed': completed});
    return GuidePreparation.fromJson(response.data as Map<String, dynamic>);
  }

  /// Lưu cẩm nang vào "Đã lưu"; trả về "Đã lưu cẩm nang.". Chỉ thành viên (khách 401, staff 403).
  Future<String> save(int id) async => (await _api.post('/api/guides/$id/save')).message;

  /// Bỏ lưu; trả về "Đã bỏ lưu cẩm nang.".
  Future<String> unsave(int id) async => (await _api.delete('/api/guides/$id/save')).message;

  /// "Đánh dấu đã xong" một cẩm nang không có checklist; trả về câu của server và tiến độ mới.
  /// Cẩm nang có checklist → 400.
  Future<({String message, GuideProgress progress})> markDone(int id) async =>
      _doneAnswer(await _api.post('/api/guides/$id/done'));

  /// Bỏ đánh dấu đã xong.
  Future<({String message, GuideProgress progress})> unmarkDone(int id) async =>
      _doneAnswer(await _api.delete('/api/guides/$id/done'));

  /// "Cẩm nang của tôi": tiến độ 4 giai đoạn, checklist đang làm, cẩm nang vừa xong. Chỉ thành viên.
  Future<GuideMyProgress> findMyProgress() async =>
      GuideMyProgress.fromJson(await _api.get('/api/me/guides/progress') as Map<String, dynamic>);

  static List<GuideOption> _options(Object? data) => [
    for (final item in (data as List?) ?? const []) GuideOption.fromJson(item as Map<String, dynamic>),
  ];

  static ({String message, GuideProgress progress}) _doneAnswer(ApiResponse response) =>
      (message: response.message, progress: GuideProgress.fromJson(response.data as Map<String, dynamic>));
}
