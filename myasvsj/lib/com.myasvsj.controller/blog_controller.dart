import 'package:flutter/foundation.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/blog.dart';
import 'package:myasvsj/com.myasvsj.model/blog_comment.dart';
import 'package:myasvsj/com.myasvsj.model/blog_compose_options.dart';
import 'package:myasvsj/com.myasvsj.model/blog_dao.dart';
import 'package:myasvsj/com.myasvsj.model/blog_overview.dart';
import 'package:myasvsj/com.myasvsj.model/blog_place.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.model/topic.dart';

/// Controller của Blog: danh sách (tìm, lọc, sắp xếp, tải thêm), chi tiết bài (thích, lưu, báo cáo, bình luận)
/// và form viết / sửa bài.
///
/// Giữ trạng thái của từng màn hình, kiểm tra dữ liệu nhập, gọi [BlogDao],
/// rồi `notifyListeners()` để các màn hình đang nghe tự vẽ lại.
class BlogController extends ChangeNotifier {
  BlogController(this._dao);

  final BlogDao _dao;

  /// Luật nhập liệu, giống BlogWriteRules của server (server vẫn kiểm tra lại).
  static const int titleMax = 150;
  static const int contentMax = 5000;
  static const int topicsMax = 3;
  static const int placesMax = 5;
  static const int imagesMax = 5;
  static const int commentMax = 2000;

  /// Cách sắp xếp danh sách của web.
  static const sorts = ['NEWEST', 'LIKES', 'COMMENTS'];

  /// Câu thông báo của server sau một thao tác; màn hình hiện một lần bằng [takeMessage].
  String? message;

  // ================================================================ Danh sách (BlogListScreen)

  List<Blog> blogs = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String? error;
  String? loadMoreError;
  int totalItems = 0;
  bool hasMore = false;

  /// Bộ lọc đang dùng.
  String query = '';
  Set<int> filterTopicIds = {};
  String sort = 'NEWEST';

  /// Bài nổi bật, chủ đề, thống kê.
  BlogOverview? overview;
  bool isLoadingOverview = false;

  int _page = 0;
  bool _listLoaded = false;

  /// Mỗi lần tải lại trang đầu tăng số này; câu trả lời của lần tải cũ (bộ lọc cũ) bị bỏ qua.
  int _listTicket = 0;

  bool get isFiltered => query.isNotEmpty || filterTopicIds.isNotEmpty;

  /// Đã tải xong danh sách ít nhất một lần (trước đó màn hình hiện vòng quay, không hiện "Chưa có bài").
  bool get isListLoaded => _listLoaded;

  /// Mở tab Blog: tải những gì chưa có.
  Future<void> openList() => Future.wait([
    if (overview == null && !isLoadingOverview) loadOverview(),
    if (!_listLoaded && !isLoading) loadBlogs(),
  ]);

  /// Kéo xuống làm mới: tải lại cả bài nổi bật và trang đầu.
  Future<void> refresh() => Future.wait([loadOverview(), loadBlogs()]);

  /// Tải trang đầu theo bộ lọc đang dùng.
  Future<void> loadBlogs() async {
    final ticket = ++_listTicket;
    isLoading = true;
    error = null;
    loadMoreError = null;
    notifyListeners();
    try {
      final page = await _dao.findAll(q: query, topicIds: filterTopicIds.toList(), sort: sort);
      if (ticket == _listTicket) {
        blogs = page.items;
        _page = page.page;
        hasMore = page.hasMore;
        totalItems = page.totalItems;
        _listLoaded = true;
      }
    } on ApiException catch (e) {
      if (ticket == _listTicket) {
        error = e.message;
        blogs = [];
        hasMore = false;
        totalItems = 0;
      }
    } finally {
      if (ticket == _listTicket) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Tải trang sau (cuộn tới cuối hoặc bấm "Tải thêm").
  Future<void> loadMore() async {
    if (!hasMore || isLoading || isLoadingMore) {
      return;
    }
    final ticket = _listTicket;
    isLoadingMore = true;
    loadMoreError = null;
    notifyListeners();
    try {
      final page = await _dao.findAll(q: query, topicIds: filterTopicIds.toList(), sort: sort, page: _page + 1);
      if (ticket == _listTicket) {
        // Server trả trang cuối khi trang xin vượt quá: bỏ bài đã có
        final known = {for (final b in blogs) b.id};
        blogs = [...blogs, ...page.items.where((b) => !known.contains(b.id))];
        _page = page.page;
        hasMore = page.hasMore;
        totalItems = page.totalItems;
      }
    } on ApiException catch (e) {
      if (ticket == _listTicket) {
        loadMoreError = e.message;
      }
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> loadOverview() async {
    isLoadingOverview = true;
    try {
      overview = await _dao.findOverview();
    } on ApiException {
      // Bài nổi bật chỉ là phần phụ: lỗi thì vẫn hiện danh sách (danh sách tự báo lỗi nếu mất mạng)
    } finally {
      isLoadingOverview = false;
      notifyListeners();
    }
  }

  /// Tìm theo tiêu đề, nội dung hoặc địa điểm.
  Future<void> search(String text) async {
    final q = text.trim();
    if (q == query) {
      return;
    }
    query = q;
    await loadBlogs();
  }

  /// Bật / tắt một chủ đề trong bộ lọc (bài khớp khi có ít nhất một chủ đề đã chọn).
  Future<void> toggleTopic(int topicId) async {
    filterTopicIds = {...filterTopicIds};
    if (!filterTopicIds.remove(topicId)) {
      filterTopicIds.add(topicId);
    }
    await loadBlogs();
  }

  /// Chỉ lọc theo một chủ đề (bấm chủ đề trên thẻ bài hoặc ở "Chủ đề phổ biến").
  Future<void> filterByTopic(int topicId) async {
    filterTopicIds = {topicId};
    await loadBlogs();
  }

  Future<void> setSort(String value) async {
    if (value == sort || !sorts.contains(value)) {
      return;
    }
    sort = value;
    await loadBlogs();
  }

  Future<void> clearFilters() async {
    query = '';
    filterTopicIds = {};
    await loadBlogs();
  }

  // ================================================================ Chi tiết (BlogDetailScreen)

  /// Bài đã mở, theo id: màn chi tiết có thể mở chồng nhau (bài A → địa điểm → bài B).
  final Map<int, Blog> _details = {};
  final Set<int> _loadingDetails = {};
  final Map<int, String> _detailErrors = {};

  Blog? blogById(int id) => _details[id];

  bool isLoadingBlog(int id) => _loadingDetails.contains(id);

  String? blogError(int id) => _detailErrors[id];

  /// Bình luận đang gửi và lỗi của ô bình luận (ví dụ "Bạn bình luận hơi nhanh…").
  bool isSendingComment = false;
  String? commentError;

  /// Tải bài. [quiet]: giữ bài cũ trên màn hình trong lúc tải lại (kéo làm mới, vừa đăng nhập).
  Future<void> loadBlog(int id, {bool quiet = false}) async {
    if (!quiet) {
      _details.remove(id);
    }
    _loadingDetails.add(id);
    _detailErrors.remove(id);
    notifyListeners();
    try {
      _putDetail(await _dao.findById(id));
    } on ApiException catch (e) {
      _detailErrors[id] = e.message;
      _details.remove(id);
    } finally {
      _loadingDetails.remove(id);
      notifyListeners();
    }
  }

  /// Thích / bỏ thích bài: đổi ngay trên màn hình, server từ chối thì trả lại như cũ.
  Future<void> toggleLike(int id) async {
    final before = _details[id];
    if (before == null) {
      return;
    }
    final on = !before.isLiked;
    _putDetail(before.copyWith(isLiked: on, likeCount: before.likeCount + (on ? 1 : -1)));
    notifyListeners();
    try {
      final state = on ? await _dao.like(id) : await _dao.unlike(id);
      _putDetail((_details[id] ?? before).copyWith(isLiked: state.active, likeCount: state.count));
    } on ApiException catch (e) {
      _putDetail((_details[id] ?? before).copyWith(isLiked: before.isLiked, likeCount: before.likeCount));
      message = e.message;
    } finally {
      notifyListeners();
    }
  }

  /// Lưu / bỏ lưu bài (xem lại ở Tôi → Đã lưu).
  Future<void> toggleSave(int id) async {
    final before = _details[id];
    if (before == null) {
      return;
    }
    final on = !before.isSaved;
    _putDetail(before.copyWith(isSaved: on));
    notifyListeners();
    try {
      message = on ? await _dao.save(id) : await _dao.unsave(id);
    } on ApiException catch (e) {
      _putDetail((_details[id] ?? before).copyWith(isSaved: before.isSaved));
      message = e.message;
    } finally {
      notifyListeners();
    }
  }

  /// Báo cáo bài; trả về true khi server đã nhận. Câu thông báo (thành công hay lỗi) nằm ở [message].
  Future<bool> reportBlog(int id, {required int reasonId, String note = ''}) async {
    try {
      message = await _dao.report(id, reasonId: reasonId, note: note);
      return true;
    } on ApiException catch (e) {
      message = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Gửi bình luận ([parentId] null) hoặc câu trả lời. Trả về true khi đã đăng; lỗi nằm ở [commentError].
  Future<bool> addComment(int blogId, String content, {int? parentId}) async {
    final text = content.trim();
    commentError = validateComment(text);
    if (commentError != null) {
      notifyListeners();
      return false;
    }
    isSendingComment = true;
    notifyListeners();
    try {
      final result = await _dao.addComment(blogId, text, parentId: parentId);
      _putDetail(result.blog);
      message = result.message;
      return true;
    } on ApiException catch (e) {
      commentError = e.message;
      return false;
    } finally {
      isSendingComment = false;
      notifyListeners();
    }
  }

  /// Sửa bình luận của mình. Trả về true khi đã lưu; câu thông báo ở [message].
  Future<bool> updateComment(int blogId, int commentId, String content) async {
    final text = content.trim();
    final invalid = validateComment(text);
    if (invalid != null) {
      message = invalid;
      notifyListeners();
      return false;
    }
    return _commentAction(blogId, () => _dao.updateComment(commentId, text));
  }

  Future<bool> deleteComment(int blogId, int commentId) => _commentAction(blogId, () => _dao.deleteComment(commentId));

  Future<bool> reportComment(int blogId, int commentId, {required int reasonId, String note = ''}) =>
      _commentAction(blogId, () => _dao.reportComment(commentId, reasonId: reasonId, note: note));

  /// Thích / bỏ thích một bình luận, đổi ngay trong cây bình luận.
  Future<void> toggleCommentLike(int blogId, int commentId) async {
    final comment = _findComment(_details[blogId]?.comments ?? const [], commentId);
    if (comment == null) {
      return;
    }
    final on = !comment.liked;
    _updateComment(blogId, commentId, (c) => c.copyWith(liked: on, likeCount: c.likeCount + (on ? 1 : -1)));
    notifyListeners();
    try {
      final state = on ? await _dao.likeComment(commentId) : await _dao.unlikeComment(commentId);
      _updateComment(blogId, commentId, (c) => c.copyWith(liked: state.active, likeCount: state.count));
    } on ApiException catch (e) {
      _updateComment(blogId, commentId, (c) => c.copyWith(liked: comment.liked, likeCount: comment.likeCount));
      message = e.message;
    } finally {
      notifyListeners();
    }
  }

  /// Kiểm tra nội dung bình luận; null khi hợp lệ.
  static String? validateComment(String text) {
    if (text.trim().isEmpty) {
      return 'Hãy viết nội dung bình luận.';
    }
    if (text.trim().length > commentMax) {
      return 'Bình luận tối đa 2.000 ký tự.';
    }
    return null;
  }

  void clearCommentError() {
    if (commentError != null) {
      commentError = null;
      notifyListeners();
    }
  }

  Future<bool> _commentAction(int blogId, Future<BlogCommentResult> Function() call) async {
    try {
      final result = await call();
      message = result.message;
      if (result.blog != null) {
        _putDetail(result.blog);
      } else {
        // Đã xóa, nhưng bài không còn xem được (vừa bị ẩn hoặc đang quét): tải lại để thấy trạng thái mới
        await loadBlog(blogId, quiet: true);
      }
      return true;
    } on ApiException catch (e) {
      message = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Giữ bài chi tiết và cập nhật số thích / bình luận của bài đó trong danh sách.
  void _putDetail(Blog? blog) {
    final id = blog?.id;
    if (blog == null || id == null) {
      return;
    }
    _details[id] = blog;
    final index = blogs.indexWhere((b) => b.id == id);
    if (index >= 0) {
      blogs = [...blogs]..[index] = blogs[index].copyWith(likeCount: blog.likeCount, commentCount: blog.commentCount);
    }
  }

  void _updateComment(int blogId, int commentId, BlogComment Function(BlogComment) change) {
    final blog = _details[blogId];
    if (blog != null) {
      _details[blogId] = blog.copyWith(comments: _mapComment(blog.comments, commentId, change));
    }
  }

  static List<BlogComment> _mapComment(List<BlogComment> nodes, int id, BlogComment Function(BlogComment) change) => [
    for (final c in nodes) c.id == id ? change(c) : c.copyWith(replies: _mapComment(c.replies, id, change)),
  ];

  static BlogComment? _findComment(List<BlogComment> nodes, int id) {
    for (final c in nodes) {
      final found = c.id == id ? c : _findComment(c.replies, id);
      if (found != null) {
        return found;
      }
    }
    return null;
  }

  // ================================================================ Form tạo / sửa (BlogFormScreen)

  BlogComposeOptions? composeOptions;

  /// Bài đang sửa; null khi form tạo bài mới.
  Blog? editing;
  bool isLoadingForm = false;
  bool isSaving = false;
  String? formError;
  Map<String, String> fieldErrors = {};

  /// Kết quả tìm địa điểm cho ô "Địa điểm liên quan".
  List<BlogPlace> placeResults = [];
  bool isSearchingPlaces = false;
  String? placeError;
  int _placeTicket = 0;

  /// Chủ đề cho form.
  List<Topic> get topics => composeOptions?.topics ?? const [];

  /// Mở form: lấy chủ đề và giới hạn; khi sửa ([blogId] khác null) lấy thêm bài như đang lưu.
  Future<void> openForm({int? blogId}) async {
    editing = null;
    composeOptions = null;
    formError = null;
    fieldErrors = {};
    placeResults = [];
    placeError = null;
    isLoadingForm = true;
    notifyListeners();
    try {
      composeOptions = await _dao.findComposeOptions();
      if (blogId != null) {
        editing = await _dao.findForEdit(blogId);
      }
    } on ApiException catch (e) {
      // Không mở được form: chưa đăng nhập, tài khoản staff (MSG18) hoặc không phải tác giả
      composeOptions = null;
      formError = e.message;
    } finally {
      isLoadingForm = false;
      notifyListeners();
    }
  }

  /// Lưu form: tạo bài mới khi [editing] là null, ngược lại lưu bài đang sửa.
  /// [keptMedia]: ảnh / video cũ còn giữ khi sửa; [imagePaths]: ảnh mới chọn trên máy.
  /// Trả về true khi server đã lưu; câu thông báo của server ở [message].
  Future<bool> saveBlog({
    required String title,
    required String content,
    required List<int> topicIds,
    List<BlogPlace> places = const [],
    List<MediaItem> keptMedia = const [],
    List<String> imagePaths = const [],
  }) async {
    final cleanTitle = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    final cleanContent = content.trim();
    formError = null;
    fieldErrors = validate(
      title: cleanTitle,
      content: cleanContent,
      topicIds: topicIds,
      placeCount: places.length,
      imageCount: keptMedia.where((m) => m.isImage).length + imagePaths.length,
    );
    if (fieldErrors.isNotEmpty) {
      formError = summaryOf(fieldErrors);
      notifyListeners();
      return false;
    }
    final old = editing;
    final names = {for (final t in topics) t.id: t.name};
    final blog = Blog(
      id: old?.id,
      title: cleanTitle,
      content: cleanContent,
      topics: [for (final id in topicIds) Topic(id: id, name: names[id] ?? '')],
      places: places,
      // Ảnh trước, video sau, như bài hiện ra
      media: [...keptMedia.where((m) => m.isImage), ...keptMedia.where((m) => !m.isImage)],
    );
    isSaving = true;
    notifyListeners();
    try {
      final saved = old == null
          ? await _dao.create(blog, imagePaths: imagePaths)
          : await _dao.update(blog, imagePaths: imagePaths);
      message = saved.message;
      // Lấy lại từ server để thấy đúng thứ tự, trạng thái và nội dung đã lưu
      await loadBlogs();
      if (_details.containsKey(saved.id)) {
        await loadBlog(saved.id, quiet: true);
      }
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

  /// Kiểm tra trước khi gửi (bước 1 của BlogWriteRules); trả về lỗi theo từng ô, rỗng khi hợp lệ.
  /// Link, số điện thoại, mã QR trong ảnh và từ khóa cấm do server kiểm tra.
  static Map<String, String> validate({
    required String title,
    required String content,
    required List<int> topicIds,
    int placeCount = 0,
    int imageCount = 0,
  }) {
    final errors = <String, String>{};
    final cleanTitle = title.trim();
    final cleanContent = content.trim();
    if (cleanTitle.isEmpty) {
      errors['title'] = 'Hãy nhập tiêu đề.';
    } else if (cleanTitle.length > titleMax) {
      errors['title'] = 'Tiêu đề tối đa $titleMax ký tự.';
    }
    if (topicIds.isEmpty) {
      errors['topicIds'] = 'Hãy chọn ít nhất 1 chủ đề. Không có chủ đề phù hợp thì chọn “Khác”.';
    } else if (topicIds.length > topicsMax) {
      errors['topicIds'] = 'Chọn tối đa $topicsMax chủ đề.';
    }
    if (placeCount > placesMax) {
      errors['placeIds'] = 'Chọn tối đa $placesMax địa điểm.';
    }
    if (cleanContent.isEmpty) {
      errors['content'] = 'Hãy nhập nội dung bài viết.';
    } else if (cleanContent.length > contentMax) {
      errors['content'] = 'Nội dung tối đa 5.000 ký tự.';
    }
    if (imageCount > imagesMax) {
      errors['images'] = 'Tối đa $imagesMax ảnh, định dạng JPG, PNG hoặc HEIC, mỗi ảnh không quá 20 MB.';
    }
    return errors;
  }

  /// Dòng trên cùng của form: MSG37 khi thiếu tiêu đề hoặc nội dung, ngược lại là lỗi đầu tiên.
  static String summaryOf(Map<String, String> errors) {
    if (errors['title'] == 'Hãy nhập tiêu đề.' || errors['content'] == 'Hãy nhập nội dung bài viết.') {
      return 'Hãy nhập tiêu đề và nội dung cho bài viết.';
    }
    return errors.values.first;
  }

  /// Tìm địa điểm để gắn vào bài. Câu trả lời cũ về muộn (người dùng đã gõ tìm cái khác) bị bỏ qua.
  Future<void> searchPlaces(String text) async {
    final q = text.trim();
    final ticket = ++_placeTicket;
    if (q.isEmpty) {
      clearPlaceResults();
      return;
    }
    isSearchingPlaces = true;
    placeError = null;
    notifyListeners();
    try {
      final found = await _dao.searchPlaces(q);
      if (ticket == _placeTicket) {
        placeResults = found;
        if (found.isEmpty) {
          placeError = 'Không tìm thấy địa điểm nào.';
        }
      }
    } on ApiException catch (e) {
      if (ticket == _placeTicket) {
        placeResults = [];
        placeError = e.message;
      }
    } finally {
      if (ticket == _placeTicket) {
        isSearchingPlaces = false;
        notifyListeners();
      }
    }
  }

  void clearPlaceResults() {
    _placeTicket++;
    placeResults = [];
    placeError = null;
    isSearchingPlaces = false;
    notifyListeners();
  }

  // ================================================================ Xóa bài

  /// Xóa bài; trả về true khi server đã xóa. Câu thông báo (thành công hay lỗi) nằm ở [message].
  Future<bool> deleteBlog(int id) async {
    try {
      message = await _dao.delete(id);
      final before = blogs.length;
      blogs = blogs.where((b) => b.id != id).toList();
      totalItems -= before - blogs.length;
      _details.remove(id);
      return true;
    } on ApiException catch (e) {
      message = e.message;
      return false;
    } finally {
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
