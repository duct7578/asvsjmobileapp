import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/api_response.dart';
import 'package:myasvsj/com.myasvsj.model/page_result.dart';
import 'package:myasvsj/com.myasvsj.model/question.dart';
import 'package:myasvsj/com.myasvsj.model/question_compose.dart';
import 'package:myasvsj/com.myasvsj.model/question_overview.dart';

/// Truy cập dữ liệu Hỏi-Đáp qua REST API của web. Câu hỏi là dòng `blogs` loại QA, câu trả lời là `comments`.
///
/// | Hàm            | API                                          |
/// |----------------|----------------------------------------------|
/// | findAll        | GET /api/questions                           |
/// | findOverview   | GET /api/questions/overview                  |
/// | findById       | GET /api/questions/{id}                      |
/// | findCompose    | GET /api/questions/compose                   |
/// | findForEdit    | GET /api/questions/{id}/edit                 |
/// | create         | POST /api/questions (multipart "question")   |
/// | update         | PUT /api/questions/{id} (multipart)          |
/// | delete         | DELETE /api/questions/{id}                   |
/// | like / unlike  | POST / DELETE /api/questions/{id}/like       |
/// | save / unsave  | POST / DELETE /api/questions/{id}/save       |
/// | report         | POST /api/questions/{id}/report              |
/// | answer         | POST /api/questions/{id}/answers             |
/// | chooseBest     | PUT /api/questions/{id}/best-answer          |
/// | likeAnswer / unlikeAnswer | POST / DELETE /api/comments/{id}/like |
/// | reportAnswer   | POST /api/comments/{id}/report               |
/// | updateAnswer   | PUT /api/comments/{id}                       |
/// | deleteAnswer   | DELETE /api/comments/{id}                    |
///
/// GET ai cũng gọi được; các hàm còn lại cần User đã đăng nhập (khách nhận 401/403).
class QuestionDao {
  QuestionDao(this._api);

  final ApiClient _api;

  /// Số câu hỏi mỗi trang.
  static const int pageSize = 10;

  /// Một trang câu hỏi (trang đầu là 0).
  ///
  /// [status]: ALL, UNANSWERED ("Chưa ai trả lời"), UNSOLVED ("Chưa giải quyết"), SOLVED ("Đã giải quyết").
  /// [sort]: NEWEST, LIKES, ANSWERS. [topicIds]: câu hỏi có ít nhất một chủ đề trong danh sách.
  Future<PageResult<Question>> findAll({
    String? q,
    List<int> topicIds = const [],
    String status = 'ALL',
    String sort = 'NEWEST',
    int page = 0,
    int size = pageSize,
  }) async {
    final data =
        await _api.get(
              '/api/questions',
              query: {
                if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
                if (topicIds.isNotEmpty) 'topicIds': topicIds.join(','),
                'status': status,
                'sort': sort,
                'page': page,
                'size': size,
              },
            )
            as Map<String, dynamic>;
    return PageResult.fromJson(data, Question.fromJson);
  }

  /// Chủ đề để lọc, thống kê, chủ đề hay được hỏi, senpai giải đáp nhiều.
  Future<QuestionOverview> findOverview() async =>
      QuestionOverview.fromJson(await _api.get('/api/questions/overview') as Map<String, dynamic>);

  /// Chi tiết câu hỏi kèm ảnh, cây câu trả lời và những gì người xem được làm (`viewer`).
  /// Không có hoặc đã bị gỡ: 404 "Không tìm thấy nội dung bạn yêu cầu…" (MSG19).
  Future<Question> findById(int id) async =>
      Question.fromJson(await _api.get('/api/questions/$id') as Map<String, dynamic>);

  /// Chủ đề và luật của form "Đặt câu hỏi". Khách nhận 401 "Bạn cần đăng nhập để viết bài.".
  Future<QuestionCompose> findCompose() async =>
      QuestionCompose.fromJson(await _api.get('/api/questions/compose') as Map<String, dynamic>);

  /// Câu hỏi như đang lưu và lựa chọn của form, để sửa. Chỉ người hỏi gọi được (người khác: 403/404).
  Future<({Question question, QuestionCompose compose})> findForEdit(int id) async {
    final data = await _api.get('/api/questions/$id/edit') as Map<String, dynamic>;
    return (
      question: Question.fromEditJson(data),
      compose: QuestionCompose.fromJson((data['options'] as Map<String, dynamic>?) ?? const {}),
    );
  }

  /// Đặt câu hỏi mới, kèm tối đa 5 ảnh [imagePaths] (đường dẫn file JPEG trên máy).
  /// Trả về id, trạng thái (PUBLISHED, hoặc PROCESSING khi ảnh đang được quét) và câu thông báo của server.
  Future<({int id, String status, String message})> create(Question question, {List<String> imagePaths = const []}) =>
      _write('POST', '/api/questions', question.toJson(), imagePaths);

  /// Lưu câu hỏi đã sửa: giữ ảnh cũ [keepMediaIds] (theo thứ tự) và thêm ảnh mới [imagePaths].
  /// Server trả "Đã lưu thay đổi." (hoặc câu báo ảnh đang được quét).
  Future<({int id, String status, String message})> update(
    Question question, {
    List<int> keepMediaIds = const [],
    List<String> imagePaths = const [],
  }) => _write('PUT', '/api/questions/${question.id}', question.toJson(keepMediaIds: keepMediaIds), imagePaths);

  Future<({int id, String status, String message})> _write(
    String method,
    String path,
    Map<String, dynamic> json,
    List<String> imagePaths,
  ) async {
    final response = await _api.sendMultipart(
      method,
      path,
      jsonPart: 'question',
      json: json,
      files: {if (imagePaths.isNotEmpty) 'images': imagePaths},
    );
    final data = (response.data as Map<String, dynamic>?) ?? const {};
    return (id: (data['id'] ?? 0) as int, status: (data['status'] ?? 'PUBLISHED') as String, message: response.message);
  }

  /// Xóa câu hỏi của mình (các câu trả lời cũng bị xóa); trả về "Đã xóa câu hỏi.".
  Future<String> delete(int id) async => (await _api.delete('/api/questions/$id')).message;

  /// Thích câu hỏi; trả về trạng thái và số lượt thích mới. Không thích được câu hỏi của chính mình (400).
  Future<({bool active, int count})> like(int id) async => _likeState(await _api.post('/api/questions/$id/like'));

  Future<({bool active, int count})> unlike(int id) async => _likeState(await _api.delete('/api/questions/$id/like'));

  /// Lưu câu hỏi (xem lại ở Tôi → Đã lưu); trả về "Đã lưu câu hỏi.".
  Future<String> save(int id) async => (await _api.post('/api/questions/$id/save')).message;

  /// Bỏ lưu; trả về "Đã bỏ lưu câu hỏi.".
  Future<String> unsave(int id) async => (await _api.delete('/api/questions/$id/save')).message;

  /// Báo cáo câu hỏi; trả về "Cảm ơn bạn. Báo cáo đã được gửi." (mỗi người báo cáo một lần).
  Future<String> report(int id, int reasonId, String note) async =>
      (await _api.post('/api/questions/$id/report', {'reasonId': reasonId, 'note': note})).message;

  /// Trả lời câu hỏi [questionId], hoặc phản hồi câu trả lời [parentId]. Server giới hạn 15 giây một lần (429).
  /// Trả về câu hỏi đã cập nhật và câu "Đã đăng câu trả lời." / "Đã gửi phản hồi.".
  Future<({Question question, String message})> answer(int questionId, String content, {int? parentId}) async =>
      _detail(await _api.post('/api/questions/$questionId/answers', {'content': content, 'parentId': ?parentId}));

  /// Người hỏi chọn câu trả lời hay nhất (+5 điểm cho người trả lời); trả về câu hỏi đã cập nhật.
  Future<({Question question, String message})> chooseBest(int questionId, int answerId) async =>
      _detail(await _api.put('/api/questions/$questionId/best-answer', {'answerId': answerId}));

  /// Thích một câu trả lời (không thích được câu của chính mình).
  Future<({bool active, int count})> likeAnswer(int answerId) async =>
      _likeState(await _api.post('/api/comments/$answerId/like'));

  Future<({bool active, int count})> unlikeAnswer(int answerId) async =>
      _likeState(await _api.delete('/api/comments/$answerId/like'));

  /// Báo cáo một câu trả lời; trả về câu hỏi đã cập nhật (câu trả lời có thể đã bị ẩn).
  Future<({Question question, String message})> reportAnswer(int answerId, int reasonId, String note) async =>
      _detail(await _api.post('/api/comments/$answerId/report', {'reasonId': reasonId, 'note': note}));

  /// Sửa câu trả lời của mình; trả về câu hỏi đã cập nhật và "Đã lưu bình luận.".
  Future<({Question question, String message})> updateAnswer(int answerId, String content) async =>
      _detail(await _api.put('/api/comments/$answerId', {'content': content}));

  /// Xóa câu trả lời của mình (câu có phản hồi thành dòng "đã bị xóa"). [question] là null khi câu hỏi không
  /// còn hiện được cho người xem (đã bị ẩn trong lúc đó), dù câu trả lời đã được xóa.
  Future<({Question? question, String message})> deleteAnswer(int answerId) async {
    final response = await _api.delete('/api/comments/$answerId');
    final data = response.data;
    return (question: data is Map<String, dynamic> ? Question.fromJson(data) : null, message: response.message);
  }

  /// LikeState `{active, count}`.
  static ({bool active, int count}) _likeState(ApiResponse response) {
    final data = (response.data as Map<String, dynamic>?) ?? const {};
    return (active: (data['active'] ?? false) as bool, count: (data['count'] ?? 0) as int);
  }

  /// Các thao tác trên câu trả lời trả về cả câu hỏi (BlogDetail) để vẽ lại cây câu trả lời.
  static ({Question question, String message}) _detail(ApiResponse response) {
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Không tải được dữ liệu. Vui lòng thử lại.');
    }
    return (question: Question.fromJson(data), message: response.message);
  }
}
