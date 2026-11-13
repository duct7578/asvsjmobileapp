import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/faq_dao.dart';
import 'package:myasvsj/com.myasvsj.model/faq_entry.dart';
import 'package:myasvsj/com.myasvsj.model/faq_topic.dart';

/// Controller của "Câu hỏi thường gặp": danh sách theo chủ đề và từ khóa (tab FAQ của Hỏi-Đáp và màn FaqScreen
/// dùng chung), một câu mở riêng theo id, các câu liên quan hiện trên kết quả tìm câu hỏi, và gợi ý khi đang gõ
/// câu hỏi mới.
class FaqController extends ChangeNotifier {
  FaqController(this._dao, {this.suggestDelay = const Duration(milliseconds: 400)});

  final FaqDao _dao;

  /// Chờ người dùng ngừng gõ bao lâu rồi mới tìm gợi ý (web: 500 ms).
  final Duration suggestDelay;

  /// Tìm câu liên quan trên kết quả tìm câu hỏi khi từ khóa có ít nhất [hitsMinLength] ký tự; hiện tối đa [hitsMax].
  static const int hitsMinLength = 2;
  static const int hitsMax = 3;

  /// Gợi ý khi câu hỏi đang gõ có ít nhất [suggestMinLength] ký tự; tối đa [suggestMax] câu.
  static const int suggestMinLength = 8;
  static const int suggestMax = 3;

  /// Từ khóa không khớp nguyên văn câu nào: hiện tối đa [relatedMax] câu có thể liên quan.
  static const int relatedMax = 5;

  // ----- Danh sách (tab "Câu hỏi thường gặp", FaqScreen)
  List<FaqTopic> topics = [];
  List<FaqEntry> entries = [];

  /// Những câu có thể liên quan khi tìm [query] không ra câu nào.
  List<FaqEntry> related = [];
  String query = '';

  /// Mã chủ đề đang lọc; rỗng = tất cả.
  String topicCode = '';
  bool isLoading = false;
  bool isLoadingMore = false;
  String? error;

  /// Lỗi của lần tải thêm gần nhất (danh sách đang có vẫn giữ).
  String? moreError;
  int totalItems = 0;
  bool hasMore = false;
  bool hasLoaded = false;
  int _page = 0;
  int _request = 0;

  bool get isFiltered => query.trim().isNotEmpty || topicCode.isNotEmpty;

  /// Tổng số câu của mọi chủ đề (nút "Tất cả").
  int get allCount => topics.fold(0, (sum, t) => sum + t.count);

  // ----- Một câu mở riêng (FaqScreen(faqId: …)), theo id
  final Map<int, FaqEntry> _entries = {};
  final Set<int> _loadingIds = {};
  final Map<int, String> _errors = {};

  // ----- "Câu hỏi thường gặp liên quan" trên kết quả tìm câu hỏi
  List<FaqEntry> hits = [];
  String hitsQuery = '';
  int _hitsRequest = 0;

  // ----- "Có thể đã có câu trả lời" khi đặt câu hỏi
  List<FaqEntry> suggestions = [];
  Timer? _suggestTimer;
  String _suggested = '';
  int _suggestRequest = 0;

  // ---------------------------------------------------------------- Danh sách

  /// Tải chủ đề (kèm số câu khớp từ khóa) và trang đầu theo bộ lọc hiện tại.
  Future<void> loadFaqs() async {
    final request = ++_request;
    isLoading = true;
    error = null;
    notifyListeners();
    final q = query.trim();
    // Hai yêu cầu chạy song song; chủ đề lỗi thì vẫn hiện danh sách với chủ đề cũ
    final topicsFuture = _topicsOrNull(q);
    try {
      final page = await _dao.findAll(q: q, topic: topicCode);
      final newTopics = await topicsFuture;
      if (request != _request) {
        return;
      }
      if (newTopics != null) {
        topics = newTopics;
        // Chủ đề đang lọc không còn: hiện mọi chủ đề
        if (topicCode.isNotEmpty && !topics.any((t) => t.code == topicCode)) {
          topicCode = '';
          await loadFaqs();
          return;
        }
      }
      entries = page.items;
      totalItems = page.totalItems;
      hasMore = page.hasMore;
      _page = page.page;
      moreError = null;
      related = entries.isEmpty && q.isNotEmpty ? await _relatedOrEmpty(q, relatedMax) : [];
      if (request != _request) {
        return;
      }
      hasLoaded = true;
    } on ApiException catch (e) {
      if (request != _request) {
        return;
      }
      error = e.message;
      entries = [];
      related = [];
      hasMore = false;
    } finally {
      if (request == _request) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Trang sau, nối vào cuối danh sách. Lỗi thì giữ danh sách cũ.
  Future<void> loadMore() async {
    if (!hasMore || isLoading || isLoadingMore) {
      return;
    }
    final request = _request;
    isLoadingMore = true;
    moreError = null;
    notifyListeners();
    try {
      final page = await _dao.findAll(q: query.trim(), topic: topicCode, page: _page + 1);
      if (request != _request) {
        return;
      }
      final seen = {for (final e in entries) e.id};
      entries = [...entries, ...page.items.where((e) => !seen.contains(e.id))];
      totalItems = page.totalItems;
      hasMore = page.hasMore;
      _page = page.page;
    } on ApiException catch (e) {
      // Giữ danh sách đang có; nút "Tải thêm" vẫn còn để thử lại
      moreError = e.message;
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> search(String text) {
    query = text.trim();
    return loadFaqs();
  }

  Future<void> selectTopic(String code) {
    topicCode = code;
    return loadFaqs();
  }

  /// "Xóa bộ lọc" / "Xem tất cả": bỏ từ khóa và chủ đề.
  Future<void> clearFilters() {
    query = '';
    topicCode = '';
    return loadFaqs();
  }

  // ---------------------------------------------------------------- Một câu

  FaqEntry? entryOf(int id) => _entries[id];

  bool isLoadingEntry(int id) => _loadingIds.contains(id);

  String? entryError(int id) => _errors[id];

  /// Tải một câu theo id (mở từ kết quả tìm kiếm của app, hoặc từ gợi ý).
  Future<void> loadEntry(int id) async {
    _loadingIds.add(id);
    _errors.remove(id);
    notifyListeners();
    try {
      _entries[id] = await _dao.findById(id);
    } on ApiException catch (e) {
      _entries.remove(id);
      _errors[id] = e.statusCode == 404 ? 'Câu hỏi thường gặp này không còn hoặc đã được ẩn.' : e.message;
    } finally {
      _loadingIds.remove(id);
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------- Liên quan và gợi ý

  /// Câu liên quan tới từ khóa tìm câu hỏi [text] (chỉ trang đầu). Lỗi không làm hỏng danh sách câu hỏi: rỗng.
  Future<void> loadHits(String text) async {
    final q = text.trim();
    final request = ++_hitsRequest;
    hitsQuery = q;
    if (q.length < hitsMinLength) {
      if (hits.isNotEmpty) {
        hits = [];
        notifyListeners();
      }
      return;
    }
    final found = await _relatedOrEmpty(q, hitsMax);
    if (request != _hitsRequest) {
      return;
    }
    hits = found;
    notifyListeners();
  }

  /// Người dùng đang gõ câu hỏi [title]: chờ [suggestDelay] sau lần gõ cuối rồi tìm câu giống.
  /// Ngắn hơn [suggestMinLength] ký tự thì bỏ gợi ý ngay.
  void suggest(String title) {
    _suggestTimer?.cancel();
    final text = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.length < suggestMinLength) {
      _suggested = '';
      _suggestRequest++;
      if (suggestions.isNotEmpty) {
        suggestions = [];
        notifyListeners();
      }
      return;
    }
    if (text == _suggested) {
      return;
    }
    _suggestTimer = Timer(suggestDelay, () => _loadSuggestions(text));
  }

  Future<void> _loadSuggestions(String text) async {
    _suggested = text;
    final request = ++_suggestRequest;
    final found = await _relatedOrEmpty(text, suggestMax);
    if (request != _suggestRequest) {
      return;
    }
    suggestions = found;
    notifyListeners();
  }

  /// Bỏ gợi ý (mở form mới, rời form).
  void clearSuggestions() {
    _suggestTimer?.cancel();
    _suggestRequest++;
    _suggested = '';
    suggestions = [];
  }

  Future<List<FaqTopic>?> _topicsOrNull(String q) async {
    try {
      return await _dao.findTopics(q: q);
    } on ApiException {
      return null;
    }
  }

  Future<List<FaqEntry>> _relatedOrEmpty(String q, int limit) async {
    try {
      return await _dao.findRelated(q, limit: limit);
    } on ApiException {
      return const [];
    }
  }

  @override
  void dispose() {
    _suggestTimer?.cancel();
    super.dispose();
  }
}
