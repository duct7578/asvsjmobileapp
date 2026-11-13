import 'package:flutter/foundation.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/phrase.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_dao.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_group.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_marks.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_overview.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_speaker.dart';
import 'package:myasvsj/com.myasvsj.model/report_reason.dart';

/// Controller của Nhật ngữ: trang đầu và tìm kiếm (PhraseScreen), một bộ theo chủ đề / địa điểm hoặc danh sách
/// "Chưa thuộc" / "Đã thuộc" (PhraseListScreen), "Luyện tập" (PhrasePracticeScreen), thẻ ghi nhớ (FlashcardScreen),
/// "Nghe", "Bỏ đánh dấu" và "Báo lỗi" trên từng thẻ mẫu câu.
///
/// Mỗi mục là một [Phrase] bất biến; khi dấu của một mục đổi, Controller thay nó ở mọi danh sách đang giữ
/// (kết quả tìm, các bộ, thư viện, thẻ ghi nhớ) và cộng / trừ số "đã thuộc" ở trang đầu.
class PhraseController extends ChangeNotifier {
  PhraseController(this._dao, {PhraseSpeaker? speaker}) : _speaker = speaker ?? PhraseSpeaker();

  final PhraseDao _dao;
  final PhraseSpeaker _speaker;

  static const String noVoiceMessage = 'Máy chưa có giọng đọc tiếng Nhật.';

  /// Danh sách riêng của thành viên: khóa `mine` → tên.
  static const Map<String, String> mineNames = {'learning': 'Chưa thuộc', 'learned': 'Đã thuộc'};

  // ----- Trang đầu (PhraseScreen)
  PhraseOverview? overview;
  bool isLoadingOverview = false;
  String? overviewError;

  // ----- Tìm kiếm trên trang đầu
  String query = '';
  List<Phrase> results = [];
  bool isSearching = false;
  String? searchError;
  int _searchSeq = 0;

  // ----- Các bộ (PhraseListScreen), theo khóa [setKey]: màn bộ có thể mở chồng nhau (chủ đề → địa điểm)
  final Map<String, List<Phrase>> _sets = {};
  final Set<String> _loadingSets = {};
  final Map<String, String> _setErrors = {};

  // ----- Luyện tập (PhrasePracticeScreen): cả thư viện và các lựa chọn, giữ trong lúc app mở
  List<Phrase>? library;
  bool isLoadingLibrary = false;
  String? libraryError;

  /// "" = Tất cả, "topic" = Chủ đề, "category" = Địa điểm.
  String practiceBy = '';

  /// Mã chủ đề hoặc loại địa điểm đang chọn khi [practiceBy] khác rỗng.
  String practiceGroup = '';

  /// "" = Cả hai, hoặc một loại.
  String practiceKind = '';

  /// "" = Tất cả, learning, learned, new (chỉ thành viên).
  String practiceStatus = '';
  bool practiceShuffle = true;

  // ----- Thẻ ghi nhớ (FlashcardScreen)
  List<Phrase> flashCards = [];
  int flashIndex = 0;
  bool isFlipped = false;
  final List<int> learnedIds = [];
  final List<int> learningIds = [];
  bool isAnswering = false;

  /// Câu thông báo (của server, hoặc báo không có giọng đọc); màn hình hiện một lần bằng [takeMessage].
  String? message;

  /// Người xem là thành viên đã đăng nhập: được lưu thẻ ghi nhớ, thấy tiến độ và "Bỏ đánh dấu".
  bool get isMember => overview?.member ?? false;

  List<ReportReason> get reportReasons => overview?.reportReasons ?? const [];

  // ---------------------------------------------------------------- Trang đầu, tìm kiếm

  Future<void> loadOverview() async {
    isLoadingOverview = true;
    overviewError = null;
    notifyListeners();
    try {
      overview = await _dao.findOverview();
    } on ApiException catch (e) {
      overviewError = e.message;
    } finally {
      isLoadingOverview = false;
      notifyListeners();
    }
  }

  /// Tìm trên cả hai loại. Chữ trống thì xóa kết quả. Câu trả lời cho chữ cũ (gõ tiếp khi đang tìm) bị bỏ qua.
  Future<void> search(String text) async {
    final q = text.trim();
    query = q;
    final seq = ++_searchSeq;
    searchError = null;
    if (q.isEmpty) {
      results = [];
      isSearching = false;
      notifyListeners();
      return;
    }
    isSearching = true;
    notifyListeners();
    try {
      final found = await _dao.findAll(q: q);
      if (seq == _searchSeq) {
        results = found;
      }
    } on ApiException catch (e) {
      if (seq == _searchSeq) {
        results = [];
        searchError = e.message;
      }
    } finally {
      if (seq == _searchSeq) {
        isSearching = false;
        notifyListeners();
      }
    }
  }

  // ---------------------------------------------------------------- Một bộ

  /// Khóa của một bộ: chủ đề [topic], loại địa điểm [category] hoặc danh sách riêng [mine].
  static String setKey({String? topic, String? category, String? mine}) {
    if (mine != null) {
      return 'mine=$mine';
    }
    return topic != null ? 'topic=$topic' : 'category=$category';
  }

  /// Các mục của bộ [key]; null khi chưa tải.
  List<Phrase>? phrasesOf(String key) => _sets[key];

  bool isLoadingSet(String key) => _loadingSets.contains(key);

  String? setErrorOf(String key) => _setErrors[key];

  Future<void> loadSet({String? topic, String? category, String? mine}) async {
    final key = setKey(topic: topic, category: category, mine: mine);
    _loadingSets.add(key);
    _setErrors.remove(key);
    notifyListeners();
    try {
      _sets[key] = await _dao.findAll(topic: topic, category: category, mine: mine);
    } on ApiException catch (e) {
      _setErrors[key] = e.message;
    } finally {
      _loadingSets.remove(key);
      notifyListeners();
    }
  }

  /// Loại mở ra khi bộ không nói loại nào (mở từ Trang chủ): Mẫu câu nếu bộ có, ngược lại Từ vựng.
  static String defaultKind(List<Phrase> phrases) =>
      phrases.isNotEmpty && !phrases.any((p) => p.isPhrase) ? Phrase.vocabKind : Phrase.phraseKind;

  /// Lọc một bộ từng lớp như web: trong danh sách riêng [mine] (theo dấu hiện tại), đúng loại [kind] ("" = cả hai),
  /// qua bộ lọc mức thuộc [status] ("" = tất cả). [list] là các thẻ hiện trên màn và đi vào thẻ ghi nhớ.
  static ({List<Phrase> inList, List<Phrase> ofKind, List<Phrase> list}) filter(
    List<Phrase> phrases, {
    String? mine,
    String kind = '',
    String status = '',
  }) {
    final inList = mine == null ? phrases : phrases.where((p) => p.hasStatus(mine)).toList();
    final ofKind = kind.isEmpty ? inList : inList.where((p) => p.kind == kind).toList();
    final list = status.isEmpty ? ofKind : ofKind.where((p) => p.hasStatus(status)).toList();
    return (inList: inList, ofKind: ofKind, list: list);
  }

  // ---------------------------------------------------------------- Dấu thẻ ghi nhớ, báo lỗi, nghe

  /// "Bỏ đánh dấu" (cập nhật lạc quan: bỏ dấu ngay, trả lại dấu cũ khi server từ chối).
  /// Câu thông báo (thành công hay lỗi) nằm ở [message].
  Future<bool> clearMark(Phrase phrase) async {
    final before = PhraseMarks(learning: phrase.learning, learned: phrase.learned);
    _applyMarks(phrase, const PhraseMarks());
    notifyListeners();
    try {
      final marks = await _dao.clearFlash(phrase.id);
      _applyMarks(phrase.withMarks(const PhraseMarks()), marks);
      message = marks.message;
      return true;
    } on ApiException catch (e) {
      _applyMarks(phrase.withMarks(const PhraseMarks()), before);
      message = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// Báo lỗi mẫu câu; trả về true khi server đã nhận. Câu thông báo nằm ở [message].
  Future<bool> report(int phraseId, int reasonId, String note) async {
    try {
      message = await _dao.report(phraseId, reasonId: reasonId, note: note.trim());
      return true;
    } on ApiException catch (e) {
      message = e.message;
      return false;
    } finally {
      notifyListeners();
    }
  }

  /// "Nghe": đọc tiếng Nhật bằng giọng ja-JP. Máy chưa có giọng đọc thì đặt [message] = [noVoiceMessage].
  Future<bool> speak(String text) async {
    final spoken = await _speaker.speak(text);
    if (!spoken) {
      message = noVoiceMessage;
      notifyListeners();
    }
    return spoken;
  }

  Future<void> stopSpeaking() => _speaker.stop();

  /// Dấu mới của [phrase]: thay mục ở mọi danh sách đang giữ và chỉnh số "đã thuộc" ở trang đầu.
  void _applyMarks(Phrase phrase, PhraseMarks marks) {
    overview = overview?.withMarks(phrase, marks);
    final updated = phrase.withMarks(marks);
    List<Phrase> swap(List<Phrase> list) => [for (final p in list) p.id == updated.id ? updated : p];
    results = swap(results);
    for (final key in _sets.keys.toList()) {
      _sets[key] = swap(_sets[key]!);
    }
    if (library != null) {
      library = swap(library!);
    }
    flashCards = swap(flashCards);
  }

  // ---------------------------------------------------------------- Luyện tập

  /// Đọc lại cả thư viện mỗi lần mở "Luyện tập", để dấu là dấu mới nhất.
  Future<void> loadLibrary() async {
    isLoadingLibrary = true;
    libraryError = null;
    notifyListeners();
    try {
      library = await _dao.findAll();
      _fixPracticeChoices();
    } on ApiException catch (e) {
      libraryError = e.message;
    } finally {
      isLoadingLibrary = false;
      notifyListeners();
    }
  }

  /// Đổi một lựa chọn của "Luyện tập".
  void choosePractice({String? by, String? group, String? kind, String? status, bool? shuffle}) {
    practiceBy = by ?? practiceBy;
    practiceGroup = group ?? practiceGroup;
    practiceKind = kind ?? practiceKind;
    practiceStatus = status ?? practiceStatus;
    practiceShuffle = shuffle ?? practiceShuffle;
    _fixPracticeChoices();
    notifyListeners();
  }

  /// Chủ đề / địa điểm chọn trước không còn mục thì lấy cái đầu; khách không lọc theo mức thuộc.
  void _fixPracticeChoices() {
    if (practiceBy.isNotEmpty) {
      final groups = practiceGroups();
      if (!groups.any((g) => g.id == practiceGroup)) {
        practiceGroup = groups.isEmpty ? '' : groups.first.id;
      }
    }
    if (!isMember) {
      practiceStatus = '';
    }
  }

  /// Chủ đề hoặc loại địa điểm (theo [practiceBy]) có mục trong thư viện, theo thứ tự trang đầu, với số mục mỗi nhóm.
  List<PhraseGroup> practiceGroups() {
    final all = library ?? const <Phrase>[];
    return [
      for (final g in overview?.groupsOf(practiceBy) ?? const <PhraseGroup>[])
        PhraseGroup(id: g.id, name: g.name, icon: g.icon, count: all.where((p) => p.inGroup(practiceBy, g.id)).length),
    ].where((g) => g.count > 0).toList();
  }

  /// Mục của chủ đề / địa điểm đang chọn (cả thư viện khi chọn "Tất cả").
  List<Phrase> get practiceScope {
    final all = library ?? const <Phrase>[];
    return practiceBy.isEmpty ? all : all.where((p) => p.inGroup(practiceBy, practiceGroup)).toList();
  }

  /// Các thẻ "Bắt đầu" sẽ luyện: đúng chủ đề / địa điểm, loại và mức thuộc đã chọn.
  List<Phrase> get practicePool => practiceScope
      .where((p) => (practiceKind.isEmpty || p.kind == practiceKind) && p.hasStatus(practiceStatus))
      .toList();

  // ---------------------------------------------------------------- Thẻ ghi nhớ

  /// Bắt đầu một lượt thẻ ghi nhớ với [cards] (xáo trộn khi [shuffle]).
  void startFlash(List<Phrase> cards, {bool shuffle = false}) {
    flashCards = shuffle ? (List.of(cards)..shuffle()) : List.of(cards);
    flashIndex = 0;
    isFlipped = false;
    learnedIds.clear();
    learningIds.clear();
    isAnswering = false;
    notifyListeners();
  }

  /// "Bắt đầu" của Luyện tập.
  void startPractice() => startFlash(practicePool, shuffle: practiceShuffle);

  /// Thẻ đang hiện; null khi đã hết lượt.
  Phrase? get currentCard => flashIndex < flashCards.length ? flashCards[flashIndex] : null;

  bool get isFlashDone => currentCard == null;

  void flip() {
    isFlipped = !isFlipped;
    notifyListeners();
  }

  /// "Chưa thuộc" / "Đã thuộc" cho thẻ đang hiện. Thành viên: lưu lên server rồi mới sang thẻ sau (lỗi thì ở lại thẻ
  /// này, câu lỗi ở [message]). Khách: chỉ đếm, không lưu.
  Future<void> answer({required bool learned}) async {
    final card = currentCard;
    if (card == null || isAnswering) {
      return;
    }
    if (isMember) {
      isAnswering = true;
      notifyListeners();
      try {
        _applyMarks(card, await _dao.flash(card.id, learned: learned));
      } on ApiException catch (e) {
        message = e.message;
        return;
      } finally {
        isAnswering = false;
        notifyListeners();
      }
    }
    (learned ? learnedIds : learningIds).add(card.id);
    flashIndex++;
    isFlipped = false;
    notifyListeners();
  }

  /// "Luyện lại N thẻ chưa thuộc" ở cuối lượt.
  void againLearning() {
    final ids = learningIds.toSet();
    startFlash(flashCards.where((p) => ids.contains(p.id)).toList());
  }

  /// Lấy câu thông báo để hiện SnackBar, rồi xóa để không hiện lại lần nữa.
  String? takeMessage() {
    final text = message;
    message = null;
    return text;
  }
}
