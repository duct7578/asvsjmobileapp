import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/api_response.dart';
import 'package:myasvsj/com.myasvsj.model/blog.dart';
import 'package:myasvsj/com.myasvsj.model/blog_compose_options.dart';
import 'package:myasvsj/com.myasvsj.model/blog_overview.dart';
import 'package:myasvsj/com.myasvsj.model/blog_place.dart';
import 'package:myasvsj/com.myasvsj.model/page_result.dart';

/// Trạng thái thích sau khi bấm (LikeState của web): đang thích hay không, và số lượt thích mới.
typedef BlogLikeState = ({bool active, int count});

/// Kết quả đăng hoặc sửa bài (Created của web) kèm câu thông báo của server.
/// [status] là PUBLISHED, hoặc PROCESSING khi ảnh đang được quét.
typedef BlogSaveResult = ({int id, String status, String message});

/// Bài sau một thao tác với bình luận (server trả lại cả bài để vẽ lại) kèm câu thông báo.
/// [blog] null khi bình luận đã xóa nhưng người xem không còn xem được bài.
typedef BlogCommentResult = ({Blog? blog, String message});

/// Truy cập dữ liệu Blog qua REST API của web: bài viết (bảng `blogs`), bình luận (bảng `comments`),
/// lượt thích, lưu, báo cáo.
///
/// | Hàm                | API                                   |
/// |--------------------|---------------------------------------|
/// | findAll            | GET /api/blogs                        |
/// | findOverview       | GET /api/blogs/overview               |
/// | findById           | GET /api/blogs/{id}                   |
/// | findComposeOptions | GET /api/blogs/compose                |
/// | findForEdit        | GET /api/blogs/{id}/edit              |
/// | searchPlaces       | GET /api/places/search                |
/// | create             | POST /api/blogs (multipart)           |
/// | update             | PUT /api/blogs/{id} (multipart)       |
/// | delete             | DELETE /api/blogs/{id}                |
/// | like, unlike       | POST, DELETE /api/blogs/{id}/like     |
/// | save, unsave       | POST, DELETE /api/blogs/{id}/save     |
/// | report             | POST /api/blogs/{id}/report           |
/// | addComment         | POST /api/blogs/{id}/comments         |
/// | updateComment      | PUT /api/comments/{id}                |
/// | deleteComment      | DELETE /api/comments/{id}             |
/// | likeComment, …     | POST, DELETE /api/comments/{id}/like  |
/// | reportComment      | POST /api/comments/{id}/report        |
class BlogDao {
  BlogDao(this._api);

  final ApiClient _api;

  /// Số bài mỗi trang.
  static const int pageSize = 10;

  // ---------------------------------------------------------------- Đọc

  /// Một trang bài (trang đầu là 0), lọc theo từ khóa [q] và chủ đề [topicIds], sắp xếp theo [sort]
  /// (NEWEST, LIKES, COMMENTS). Ai cũng xem được; tác giả đã đăng nhập thấy thêm bài PROCESSING của mình.
  Future<PageResult<Blog>> findAll({
    String q = '',
    List<int> topicIds = const [],
    String sort = 'NEWEST',
    int page = 0,
  }) async {
    final data =
        await _api.get(
              '/api/blogs',
              query: {
                if (q.isNotEmpty) 'q': q,
                if (topicIds.isNotEmpty) 'topicIds': topicIds.join(','),
                'sort': sort,
                'page': page,
                'size': pageSize,
              },
            )
            as Map<String, dynamic>;
    return PageResult.fromJson(data, Blog.fromJson);
  }

  /// Bài nổi bật, chủ đề để lọc và thống kê bên cạnh danh sách. Ai cũng xem được.
  Future<BlogOverview> findOverview() async =>
      BlogOverview.fromJson(await _api.get('/api/blogs/overview') as Map<String, dynamic>);

  /// Chi tiết một bài: media, bình luận, cờ của người xem, lý do báo cáo. Ai cũng xem được.
  Future<Blog> findById(int id) async => Blog.fromJson(await _api.get('/api/blogs/$id') as Map<String, dynamic>);

  /// Chủ đề, giới hạn nhập và lượt đăng hôm nay cho form. Chỉ User đã đăng nhập gọi được.
  Future<BlogComposeOptions> findComposeOptions() async =>
      BlogComposeOptions.fromJson(await _api.get('/api/blogs/compose') as Map<String, dynamic>);

  /// Bài như đang lưu để sửa. Chỉ tác giả gọi được; người khác nhận 403 MSG18 hoặc 404 MSG19.
  Future<Blog> findForEdit(int id) async =>
      Blog.fromEditJson(await _api.get('/api/blogs/$id/edit') as Map<String, dynamic>);

  /// Tìm địa điểm để gắn vào bài: địa điểm của Senpai ơi trước, rồi địa điểm OpenStreetMap chưa có.
  /// Chỉ người đã đăng nhập gọi được.
  Future<List<BlogPlace>> searchPlaces(String q) async {
    final data = await _api.get('/api/places/search', query: {'q': q}) as Map<String, dynamic>;
    return [for (final p in (data['items'] as List?) ?? const []) BlogPlace.fromJson(p as Map<String, dynamic>)];
  }

  // ---------------------------------------------------------------- Tạo, sửa, xóa bài

  /// Đăng bài mới: phần JSON "post" và tối đa 5 ảnh "images" ([imagePaths] là file trên máy).
  /// Câu thông báo: "Bài viết của bạn đã được đăng." hoặc "Đã gửi. Ảnh và video đang được quét…".
  Future<BlogSaveResult> create(Blog blog, {List<String> imagePaths = const []}) async => _saved(
    await _api.sendMultipart(
      'POST',
      '/api/blogs',
      jsonPart: 'post',
      json: blog.toJson(),
      files: {if (imagePaths.isNotEmpty) 'images': imagePaths},
    ),
  );

  /// Lưu bài đã sửa: giữ các media trong `keepMediaIds`, thêm ảnh mới [imagePaths]. Trả về "Đã lưu thay đổi.".
  Future<BlogSaveResult> update(Blog blog, {List<String> imagePaths = const []}) async => _saved(
    await _api.sendMultipart(
      'PUT',
      '/api/blogs/${blog.id}',
      jsonPart: 'post',
      json: blog.toJson(),
      files: {if (imagePaths.isNotEmpty) 'images': imagePaths},
    ),
  );

  /// Xóa bài của mình; trả về "Đã xóa bài viết.".
  Future<String> delete(int id) async => (await _api.delete('/api/blogs/$id')).message;

  // ---------------------------------------------------------------- Thích, lưu, báo cáo bài

  /// Thích bài (không thích được bài của chính mình).
  Future<BlogLikeState> like(int id) async => _like(await _api.post('/api/blogs/$id/like'));

  Future<BlogLikeState> unlike(int id) async => _like(await _api.delete('/api/blogs/$id/like'));

  /// Lưu bài; trả về "Đã lưu bài viết.".
  Future<String> save(int id) async => (await _api.post('/api/blogs/$id/save')).message;

  /// Bỏ lưu; trả về "Đã bỏ lưu bài viết.".
  Future<String> unsave(int id) async => (await _api.delete('/api/blogs/$id/save')).message;

  /// Báo cáo bài; trả về "Cảm ơn bạn. Báo cáo đã được gửi.". Mỗi người báo cáo một bài một lần.
  Future<String> report(int id, {required int reasonId, String note = ''}) async =>
      (await _api.post('/api/blogs/$id/report', _reportBody(reasonId, note))).message;

  // ---------------------------------------------------------------- Bình luận

  /// Bình luận ([parentId] null) hoặc trả lời một bình luận. Server giới hạn 15 giây một lần và số bình luận
  /// mỗi ngày của tài khoản mới; lỗi mang câu của server, ví dụ "Bạn bình luận hơi nhanh…".
  Future<BlogCommentResult> addComment(int blogId, String content, {int? parentId}) async =>
      _comment(await _api.post('/api/blogs/$blogId/comments', {'content': content, 'parentId': parentId}));

  /// Sửa bình luận của mình; trả về bài mới và "Đã lưu bình luận.".
  Future<BlogCommentResult> updateComment(int commentId, String content) async =>
      _comment(await _api.put('/api/comments/$commentId', {'content': content}));

  /// Xóa bình luận của mình (còn câu trả lời thì thành dòng "đã bị xóa"); trả về "Đã xóa bình luận.".
  Future<BlogCommentResult> deleteComment(int commentId) async =>
      _comment(await _api.delete('/api/comments/$commentId'));

  Future<BlogLikeState> likeComment(int commentId) async => _like(await _api.post('/api/comments/$commentId/like'));

  Future<BlogLikeState> unlikeComment(int commentId) async => _like(await _api.delete('/api/comments/$commentId/like'));

  /// Báo cáo bình luận; trả về bài mới và "Cảm ơn bạn. Báo cáo đã được gửi.".
  Future<BlogCommentResult> reportComment(int commentId, {required int reasonId, String note = ''}) async =>
      _comment(await _api.post('/api/comments/$commentId/report', _reportBody(reasonId, note)));

  // ---------------------------------------------------------------- Đọc phần data

  static BlogSaveResult _saved(ApiResponse response) {
    final data = response.data as Map<String, dynamic>;
    return (id: data['id'] as int, status: (data['status'] ?? 'PUBLISHED') as String, message: response.message);
  }

  static BlogLikeState _like(ApiResponse response) {
    final data = response.data as Map<String, dynamic>;
    return (active: data['active'] as bool, count: (data['count'] ?? 0) as int);
  }

  static BlogCommentResult _comment(ApiResponse response) {
    final data = response.data;
    return (blog: data is Map<String, dynamic> ? Blog.fromJson(data) : null, message: response.message);
  }

  static Map<String, dynamic> _reportBody(int reasonId, String note) => {
    'reasonId': reasonId,
    'note': note.trim().isEmpty ? null : note.trim(),
  };
}
