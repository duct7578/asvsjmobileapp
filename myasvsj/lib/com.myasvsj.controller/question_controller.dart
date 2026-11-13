import 'package:flutter/foundation.dart';

import 'package:myasvsj/com.myasvsj.model/answer.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/question.dart';
import 'package:myasvsj/com.myasvsj.model/question_compose.dart';
import 'package:myasvsj/com.myasvsj.model/question_dao.dart';
import 'package:myasvsj/com.myasvsj.model/question_overview.dart';

/// Controller của Hỏi-Đáp: danh sách câu hỏi (lọc, tìm, sắp xếp, tải thêm), chi tiết một câu hỏi với các câu trả
/// lời, và form đặt / sửa câu hỏi.
///
/// Chi tiết được giữ theo id, vì màn chi tiết có thể mở chồng nhau (từ thông báo, từ liên kết của FAQ…).
class QuestionController extends ChangeNotifier {
  QuestionController(this._dao);

  final QuestionDao _dao;

  /// Luật nhập liệu, giống BlogWriteRules và BlogActionService của server (server vẫn kiểm tra lại).
  static const int titleMax = 150;
  static const int contentMax = 5000;
  static const int topicsMax = 3;
  static const int imagesMax = 5;
  static const int answerMax = 2000;

  /// Bộ lọc trạng thái và cách sắp xếp mà server nhận.
  static const List<String> statuses = ['ALL', 'UNANSWERED', 'UNSOLVED', 'SOLVED'];
  static const List<String> sorts = ['NEWEST', 'LIKES', 'ANSWERS'];

  /// Trạng thái người hỏi còn mở form sửa được (câu bị ẩn vì báo cáo thì không).
  static const Set<String> editableStatuses = {'PUBLISHED', 'PROCESSING', 'REJECTED'};

  // ----- Danh sách (QuestionListScreen)
  List<Question> questions = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String? error;
  int totalItems = 0;
  bool hasMore = false;

  /// Đã tải danh sách ít nhất một lần (để màn hình không tải lại mỗi lần dựng).
  bool hasLoaded = false;
  int _page = 0;
  int _listRequest = 0;

  String query = '';
  String status = 'ALL';
  String sort = 'NEWEST';
  Set<int> topicIds = {};

  /// Đang lọc theo từ khóa, chủ đề hoặc trạng thái (sắp xếp không tính).
  bool get isFiltered => query.trim().isNotEmpty || topicIds.isNotEmpty || status != 'ALL';

  QuestionOverview? overview;
  String? overviewError;

  // ----- Chi tiết (QuestionDetailScreen), theo id câu hỏi
  final Map<int, Question> _questions = {};
  final Set<int> _loadingIds = {};
  final Map<int, String> _errors = {};

  /// Đang gửi câu trả lời hoặc lưu câu trả lời đã sửa.
  bool isSendingAnswer = false;

  /// Lỗi của ô trả lời: khóa là id câu trả lời cha (0 = ô trả lời câu hỏi), hoặc id câu đang sửa.
  Map<int, String> answerErrors = {};

  // ----- Form đặt / sửa câu hỏi (QuestionFormScreen)
  QuestionCompose? compose;

  /// Câu hỏi đang sửa; null khi đặt câu hỏi mới.
  Question? editing;
  bool isLoadingForm = false;
  bool isSaving = false;
  String? formError;
  Map<String, String> fieldErrors = {};

  /// Id câu hỏi vừa đặt hoặc sửa xong, để mở màn chi tiết.
  int? lastSavedId;

  /// Câu thông báo của server sau một thao tác; màn hình hiện một lần bằng [takeMessage].
  String? message;

  // ---------------------------------------------------------------- Danh sách

  /// Tải lại trang đầu theo bộ lọc hiện tại. Câu trả lời của lần tải cũ hơn (đang gõ tìm kiếm) bị bỏ qua.
  Future<void> loadQuestions() async {
    final request = ++_listRequest;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _dao.findAll(q: query, topicIds: topicIds.toList()..sort(), status: status, sort: sort);
      if (request != _listRequest) {
        return;
      }
      questions = result.items;
      totalItems = result.totalItems;
      hasMore = result.hasMore;
      _page = result.page;
      hasLoaded = true;
    } on ApiException catch (e) {
      if (request != _listRequest) {
        return;
      }
      error = e.message;
      questions = [];
      hasMore = false;
    } finally {
      if (request == _listRequest) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Tải trang sau và nối vào cuối danh sách. Lỗi thì giữ danh sách cũ và báo bằng [message].
  Future<void> loadMore() async {
    if (!hasMore || isLoading || isLoadingMore) {
      return;
    }
    final request = _listRequest;
    isLoadingMore = true;
    notifyListeners();
    try {
      final result = await _dao.findAll(
        q: query,
        topicIds: topicIds.toList()..sort(),
        status: status,
        sort: sort,
        page: _page + 1,
      );
      if (request != _listRequest) {
        return;
      }
      final seen = {for (final q in questions) q.id};
      questions = [...questions, ...result.items.where((q) => !seen.contains(q.id))];
      totalItems = result.totalItems;
      hasMore = result.hasMore;
      _page = result.page;
    } on ApiException catch (e) {
      message = e.message;
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Tìm theo nội dung hoặc địa điểm (server: tối đa 100 ký tự).
  Future<void> search(String text) {
    query = text.trim();
    return loadQuestions();
  }

  Future<void> setStatus(String value) {
    status = value;
    return loadQuestions();
  }

  Future<void> setSort(String value) {
    sort = value;
    return loadQuestions();
  }

  /// Bấm một chủ đề trong bộ lọc: thêm nếu chưa chọn, bỏ nếu đã chọn.
  Future<void> toggleTopic(int id) {
    topicIds = {...topicIds};
    if (!topicIds.remove(id)) {
      topicIds.add(id);
    }
    return loadQuestions();
  }

  /// Chỉ lọc theo đúng một chủ đề (bấm chủ đề trên thẻ câu hỏi hay "Chủ đề hay được hỏi").
  Future<void> showTopic(int id) {
    topicIds = {id};
    return loadQuestions();
  }

  /// "Xóa bộ lọc": bỏ từ khóa, chủ đề và trạng thái.
  Future<void> clearFilters() {
    query = '';
    topicIds = {};
    status = 'ALL';
    return loadQuestions();
  }

  /// Chủ đề để lọc và thống kê. Lỗi không chặn danh sách, chỉ ẩn phần thống kê.
  Future<void> loadOverview() async {
    try {
      overview = await _dao.findOverview();
      overviewError = null;
    } on ApiException catch (e) {
      overviewError = e.message;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------- Chi tiết

  Question? questionOf(int id) => _questions[id];

  bool isLoadingQuestion(int id) => _loadingIds.contains(id);

  String? questionError(int id) => _errors[id];

  /// Tải (hoặc tải lại) chi tiết câu hỏi [id]. Khi tải lại, dữ liệu cũ vẫn hiện trong lúc chờ.
  Future<void> loadQuestion(int id) async {
    _loadingIds.add(id);
    _errors.remove(id);
    notifyListeners();
    try {
      _store(await _dao.findById(id));
    } on ApiException catch (e) {
      _errors[id] = e.message;
      _questions.remove(id);
    } finally {
      _loadingIds.remove(id);
      notifyListeners();
    }
  }

  /// Giữ chi tiết mới và cập nhật số thích / số trả lời trên thẻ danh sách.
  void _store(Question question) {
    final id = question.id!;
    _questions[id] = question;
    questions = [for (final q in questions) q.id == id ? q.withCountsOf(question) : q];
  }

  /// Thích / bỏ thích câu hỏi. Cập nhật ngay trên màn hình rồi gửi server; lỗi thì trả lại như cũ.
  Future<void> toggleLike(int id) async {
    final old = _questions[id];
    if (old == null) {
      return;
    }
    final liked = !old.liked;
    _store(old.copyWith(liked: liked, likeCount: old.likeCount + (liked ? 1 : -1)));
    notifyListeners();
    try {
      final state = liked ? await _dao.like(id) : await _dao.unlike(id);
      final now = _questions[id];
      if (now != null) {
        _store(now.copyWith(liked: state.active, likeCount: state.count));
      }
    } on ApiException catch (e) {
      final now = _questions[id];
      if (now != null) {
        _store(now.copyWith(liked: old.liked, likeCount: old.likeCount));
      }
      message = e.message;
    } finally {
      notifyListeners();
    }
  }

  /// Lưu / bỏ lưu câu hỏi, cập nhật lạc quan như [toggleLike]. Câu thông báo của server nằm ở [message].
  Future<void> toggleSave(int id) async {
    final old = _questions[id];
    if (old == null) {
      return;
    }
    final saved = !old.saved;
    _questions[id] = old.copyWith(saved: saved);
    notifyListeners();
    try {
      message = saved ? await _dao.save(id) : await _dao.unsave(id);
    } on ApiException catch (e) {
      final now = _questions[id];
      if (now != null) {
        _questions[id] = now.copyWith(saved: old.saved);
      }
      message = e.message;
    } finally {
      notifyListeners();
    }
  }

  /// Báo cáo câu hỏi; trả về true khi server đã nhận. Câu thông báo (thành công hay lỗi) ở [message].
  Future<bool> reportQuestion(int id, int reasonId, String note) async {
    try {
      message = await _dao.report(id, reasonId, note.trim());
      return true;
    } on ApiException catch (e) {
      message = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Xóa câu hỏi của mình; trả về true khi server đã xóa.
  Future<bool> deleteQuestion(int id) async {
    try {
      message = await _dao.delete(id);
      final before = questions.length;
      questions = questions.where((q) => q.id != id).toList();
      totalItems -= before - questions.length;
      _questions.remove(id);
      return true;
    } on ApiException catch (e) {
      message = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- Câu trả lời

  /// Lỗi của ô trả lời câu hỏi ([parentId] null) hoặc ô phản hồi câu trả lời [parentId].
  String? answerErrorFor(int? parentId) => answerErrors[parentId ?? 0];

  /// Bỏ lỗi đang hiện dưới một ô trả lời (khi người dùng gõ lại).
  void clearAnswerError(int? key) {
    if (answerErrors.remove(key ?? 0) != null) {
      notifyListeners();
    }
  }

  /// Kiểm tra nội dung câu trả lời như server; null khi hợp lệ.
  static String? validateAnswer(String content) {
    final text = content.trim();
    if (text.isEmpty) {
      return 'Hãy viết nội dung câu trả lời.';
    }
    if (text.length > answerMax) {
      return 'Câu trả lời tối đa 2.000 ký tự.';
    }
    return null;
  }

  /// Trả lời câu hỏi, hoặc phản hồi câu trả lời [parentId]. Trả về true khi đã đăng.
  /// Server cho mỗi người gửi một lần mỗi 15 giây; câu báo chờ của server hiện dưới ô trả lời.
  Future<bool> sendAnswer(int questionId, String content, {int? parentId}) async {
    final key = parentId ?? 0;
    final invalid = validateAnswer(content);
    if (invalid != null) {
      answerErrors = {...answerErrors, key: invalid};
      notifyListeners();
      return false;
    }
    if (isSendingAnswer) {
      return false;
    }
    answerErrors = {...answerErrors}..remove(key);
    isSendingAnswer = true;
    notifyListeners();
    try {
      final result = await _dao.answer(questionId, content.trim(), parentId: parentId);
      _store(result.question);
      message = result.message;
      return true;
    } on ApiException catch (e) {
      answerErrors = {...answerErrors, key: e.message};
      return false;
    } finally {
      isSendingAnswer = false;
      notifyListeners();
    }
  }

  /// Lưu câu trả lời [answerId] đã sửa. Trả về true khi đã lưu (hoặc không đổi gì).
  Future<bool> updateAnswer(int questionId, int answerId, String content) async {
    final invalid = validateAnswer(content);
    if (invalid != null) {
      answerErrors = {...answerErrors, answerId: invalid};
      notifyListeners();
      return false;
    }
    final old = Answer.find(_questions[questionId]?.answers ?? const [], answerId);
    if (old != null && old.content == content.trim()) {
      return true;
    }
    if (isSendingAnswer) {
      return false;
    }
    answerErrors = {...answerErrors}..remove(answerId);
    isSendingAnswer = true;
    notifyListeners();
    try {
      final result = await _dao.updateAnswer(answerId, content.trim());
      _store(result.question);
      final edited = Answer.find(result.question.answers, answerId);
      message = edited != null && edited.parentId == null ? 'Đã lưu câu trả lời.' : result.message;
      return true;
    } on ApiException catch (e) {
      answerErrors = {...answerErrors, answerId: e.message};
      return false;
    } finally {
      isSendingAnswer = false;
      notifyListeners();
    }
  }

  /// Thích / bỏ thích một câu trả lời, cập nhật lạc quan; lỗi thì trả lại như cũ.
  Future<void> toggleAnswerLike(int questionId, int answerId) async {
    final question = _questions[questionId];
    final old = question == null ? null : Answer.find(question.answers, answerId);
    if (question == null || old == null) {
      return;
    }
    final liked = !old.liked;
    _setAnswer(questionId, answerId, liked, old.likeCount + (liked ? 1 : -1));
    notifyListeners();
    try {
      final state = liked ? await _dao.likeAnswer(answerId) : await _dao.unlikeAnswer(answerId);
      _setAnswer(questionId, answerId, state.active, state.count);
    } on ApiException catch (e) {
      _setAnswer(questionId, answerId, old.liked, old.likeCount);
      message = e.message;
    } finally {
      notifyListeners();
    }
  }

  void _setAnswer(int questionId, int answerId, bool liked, int likeCount) {
    final question = _questions[questionId];
    if (question == null) {
      return;
    }
    _questions[questionId] = question.copyWith(
      answers: Answer.replace(question.answers, answerId, (a) => a.copyWith(liked: liked, likeCount: likeCount)),
    );
  }

  /// Người hỏi chọn câu trả lời hay nhất (+5 điểm cho người trả lời). Trả về true khi đã chọn.
  Future<bool> chooseBest(int questionId, int answerId) async {
    try {
      final result = await _dao.chooseBest(questionId, answerId);
      _store(result.question);
      message = '${result.message} Người trả lời được +5 điểm.';
      return true;
    } on ApiException catch (e) {
      message = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Báo cáo một câu trả lời; trả về true khi server đã nhận.
  Future<bool> reportAnswer(int questionId, int answerId, int reasonId, String note) async {
    try {
      final result = await _dao.reportAnswer(answerId, reasonId, note.trim());
      _store(result.question);
      message = result.message;
      return true;
    } on ApiException catch (e) {
      message = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Xóa câu trả lời của mình; trả về true khi server đã xóa.
  Future<bool> deleteAnswer(int questionId, int answerId) async {
    try {
      final result = await _dao.deleteAnswer(answerId);
      message = result.message;
      if (result.question != null) {
        _store(result.question!);
        notifyListeners();
      } else {
        // Câu hỏi vừa bị ẩn hoặc đang được quét: tải lại để hiện đúng tình trạng
        await loadQuestion(questionId);
      }
      return true;
    } on ApiException catch (e) {
      message = e.message;
      notifyListeners();
      return false;
    }
  }

  // ---------------------------------------------------------------- Form đặt / sửa câu hỏi

  /// Mở form: lấy chủ đề và luật; khi sửa ([questionId] khác null) lấy thêm câu hỏi như đang lưu.
  Future<void> openForm({int? questionId}) async {
    compose = null;
    editing = null;
    formError = null;
    fieldErrors = {};
    isLoadingForm = true;
    notifyListeners();
    try {
      if (questionId == null) {
        compose = await _dao.findCompose();
      } else {
        final data = await _dao.findForEdit(questionId);
        editing = data.question;
        compose = data.compose;
      }
    } on ApiException catch (e) {
      formError = e.message;
    } finally {
      isLoadingForm = false;
      notifyListeners();
    }
  }

  /// Gửi form: đặt câu hỏi mới khi [editing] là null, ngược lại lưu câu đang sửa.
  /// [keepImageIds] là ảnh cũ còn giữ (khi sửa), [imagePaths] là ảnh mới chọn trên máy. Video đã gắn (đăng từ web)
  /// luôn được giữ, vì app không sửa video.
  /// Trả về true khi server đã lưu; id ở [lastSavedId], câu thông báo ở [message].
  Future<bool> saveQuestion({
    required String title,
    required String content,
    required List<int> topicIds,
    List<int> keepImageIds = const [],
    List<String> imagePaths = const [],
  }) async {
    if (isSaving) {
      return false;
    }
    formError = null;
    fieldErrors = validate(
      title: title,
      content: content,
      topicIds: topicIds,
      imageCount: keepImageIds.length + imagePaths.length,
      rules: compose,
    );
    if (fieldErrors.isNotEmpty) {
      formError = fieldErrors.values.first;
      notifyListeners();
      return false;
    }
    final old = editing;
    final question = Question(
      id: old?.id,
      title: title.replaceAll(RegExp(r'\s+'), ' ').trim(),
      content: content.trim(),
      topicIds: topicIds,
      // App chưa sửa được địa điểm: giữ nguyên địa điểm đã gắn
      places: old?.places ?? const [],
    );
    final keepMediaIds = <int>[
      ...keepImageIds,
      if (old != null)
        for (final m in old.media)
          if (!m.isImage) m.id,
    ];
    isSaving = true;
    notifyListeners();
    try {
      final saved = old == null
          ? await _dao.create(question, imagePaths: imagePaths)
          : await _dao.update(question, keepMediaIds: keepMediaIds, imagePaths: imagePaths);
      lastSavedId = saved.id;
      message = saved.message;
      if (old != null && _questions.containsKey(old.id)) {
        await loadQuestion(old.id!);
      }
      // Danh sách và thống kê đổi theo câu hỏi vừa lưu
      loadQuestions();
      loadOverview();
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

  /// Kiểm tra form trước khi gửi, theo thứ tự các ô trên màn hình; rỗng khi hợp lệ.
  static Map<String, String> validate({
    required String title,
    required String content,
    required List<int> topicIds,
    int imageCount = 0,
    QuestionCompose? rules,
  }) {
    final titleLimit = rules?.titleMax ?? titleMax;
    final contentLimit = rules?.contentMax ?? contentMax;
    final topicLimit = rules?.topicsMax ?? topicsMax;
    final imageLimit = rules?.imagesMax ?? imagesMax;
    final errors = <String, String>{};
    final cleanTitle = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (cleanTitle.isEmpty) {
      errors['title'] = 'Hãy nhập câu hỏi.';
    } else if (cleanTitle.length > titleLimit) {
      errors['title'] = 'Câu hỏi tối đa $titleLimit ký tự.';
    }
    if (topicIds.isEmpty) {
      errors['topicIds'] = 'Hãy chọn ít nhất 1 chủ đề. Không có chủ đề phù hợp thì chọn “Khác”.';
    } else if (topicIds.length > topicLimit) {
      errors['topicIds'] = 'Chọn tối đa $topicLimit chủ đề.';
    }
    final cleanContent = content.trim();
    if (cleanContent.isEmpty && (rules?.contentRequired ?? false)) {
      errors['content'] = 'Hãy nhập mô tả chi tiết.';
    } else if (cleanContent.length > contentLimit) {
      errors['content'] = 'Mô tả chi tiết tối đa 5.000 ký tự.';
    }
    if (imageCount > imageLimit) {
      errors['images'] = 'Tối đa $imageLimit ảnh, định dạng JPG, PNG hoặc HEIC, mỗi ảnh không quá 20 MB.';
    }
    return errors;
  }

  /// Lấy câu thông báo để hiện SnackBar, rồi xóa để không hiện lại lần nữa.
  String? takeMessage() {
    final text = message;
    message = null;
    return text;
  }
}
