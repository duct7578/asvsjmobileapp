import 'dart:async';

import 'package:myasvsj/com.myasvsj.model/answer.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/author.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.model/page_result.dart';
import 'package:myasvsj/com.myasvsj.model/question.dart';
import 'package:myasvsj/com.myasvsj.model/question_compose.dart';
import 'package:myasvsj/com.myasvsj.model/question_dao.dart';
import 'package:myasvsj/com.myasvsj.model/question_overview.dart';
import 'package:myasvsj/com.myasvsj.model/report_reason.dart';
import 'package:myasvsj/com.myasvsj.model/topic.dart';

/// Người viết mẫu. [authorAn] trùng id với `testUser` (auth_fakes.dart), tức người đang đăng nhập trong test.
const authorAn = Author(id: 1, displayName: 'An');
const authorMinh = Author(id: 2, displayName: 'Trần Minh', rankName: 'Người mới');
const authorLanAnh = Author(id: 6, displayName: 'Lan Anh', tagNames: ['Mentor'], rankName: 'Senpai tin cậy');

const topicShopping = Topic(id: 11, name: 'Mua sắm');
const topicVisa = Topic(id: 4, name: 'Visa và cư trú');
const topicOther = Topic(id: 14, name: 'Khác');

const reportReasons = [ReportReason(id: 1, label: 'Lừa đảo'), ReportReason(id: 4, label: 'Spam')];

/// Một câu trả lời đủ trường.
Answer answerOf(
  int id,
  Author author,
  String content, {
  int? parentId,
  bool best = false,
  bool mine = false,
  bool liked = false,
  int likes = 0,
  bool removed = false,
  List<Answer> replies = const [],
}) => Answer(
  id: id,
  parentId: parentId,
  author: author,
  content: content,
  best: best,
  isMine: mine,
  liked: liked,
  likeCount: likes,
  removed: removed,
  createdAt: DateTime(2026, 11, 7, 10),
  replies: replies,
);

/// Chi tiết một câu hỏi như server trả về cho người đang xem.
Question detailOf(
  int id,
  String title, {
  Author author = authorMinh,
  String content = '',
  String status = 'PUBLISHED',
  bool mine = false,
  bool signedIn = true,
  bool canInteract = true,
  bool liked = false,
  bool saved = false,
  int likes = 0,
  int? bestAnswerId,
  List<Answer> answers = const [],
  List<MediaItem> media = const [],
  List<Topic> topics = const [topicShopping],
}) => Question(
  id: id,
  title: title,
  content: content,
  status: status,
  author: author,
  topics: topics,
  topicIds: [for (final t in topics) t.id],
  media: media,
  likeCount: likes,
  answerCount: _count(answers),
  bestAnswerId: bestAnswerId,
  solved: bestAnswerId != null,
  createdAt: DateTime(2026, 11, 7, 9),
  signedIn: signedIn,
  isMine: mine,
  canInteract: canInteract,
  liked: liked,
  saved: saved,
  answers: answers,
  reportReasons: reportReasons,
);

int _count(List<Answer> nodes) => nodes.fold(0, (sum, a) => sum + (a.removed ? 0 : 1) + _count(a.replies));

/// Câu 1: Minh hỏi, người đang xem (An) không phải người hỏi; Lan Anh trả lời, An đã phản hồi (câu 12 của An).
Question sampleQuestion1() => detailOf(
  1,
  'Mua SIM data giá rẻ ở đâu gần Nippori ạ?',
  content: 'Em mới sang được 3 ngày, cần SIM data rẻ để dùng bản đồ.',
  likes: 3,
  answers: [
    answerOf(
      11,
      authorLanAnh,
      'Ra BicCamera mua SIM của IIJmio nhé.',
      likes: 2,
      replies: [answerOf(12, authorAn, 'Cảm ơn chị!', parentId: 11, mine: true)],
    ),
  ],
);

/// Câu 2: An hỏi (của mình), Minh trả lời chưa được chọn, có một ảnh.
Question sampleQuestion2() => detailOf(
  2,
  'Gia hạn visa du học cần giấy tờ gì?',
  author: authorAn,
  mine: true,
  topics: const [topicVisa, topicOther],
  media: const [MediaItem(id: 19, type: 'IMAGE', url: '/media/blog/2026/11/a.jpg', width: 800, height: 600)],
  answers: [answerOf(21, authorMinh, 'Cần hộ chiếu, thẻ cư trú, giấy xác nhận đang học.')],
);

/// Thẻ danh sách ứng với một chi tiết.
Question cardOf(Question d, {bool unanswered = false}) => Question(
  id: d.id,
  title: d.title,
  content: d.content,
  status: d.status,
  solved: d.isSolved,
  unanswered: unanswered,
  author: d.author,
  topics: d.topics,
  topicIds: d.topicIds,
  likeCount: d.likeCount,
  answerCount: d.answerCount,
  createdAt: d.createdAt,
);

/// DAO giả của Hỏi-Đáp: giữ dữ liệu trong bộ nhớ thay vì gọi server, ghi lại mọi lần gọi để test kiểm tra.
class FakeQuestionDao implements QuestionDao {
  FakeQuestionDao({this.perPage = 10}) {
    details[1] = sampleQuestion1();
    details[2] = sampleQuestion2();
    stored
      ..add(cardOf(details[1]!))
      ..add(cardOf(details[2]!))
      ..add(cardOf(detailOf(3, 'Đổi bằng lái xe Việt Nam sang Nhật?'), unanswered: true));
  }

  /// Số câu mỗi trang của server giả (để test tải thêm).
  final int perPage;

  /// Thẻ danh sách và chi tiết theo id.
  final List<Question> stored = [];
  final Map<int, Question> details = {};

  /// Tên các hàm đã được gọi, theo thứ tự.
  final List<String> calls = [];

  /// Tham số của lần findAll gần nhất.
  Map<String, Object?> lastQuery = {};

  /// Câu hỏi đã gửi lên qua create / update, kèm ảnh cũ giữ lại và ảnh mới.
  final List<({Question question, List<int> keepMediaIds, List<String> imagePaths})> saved = [];

  /// Báo cáo đã gửi: (id câu hỏi hoặc câu trả lời, lý do, ghi chú).
  final List<({int id, int reasonId, String note})> reports = [];

  /// Đặt khác null để mọi lần gọi đều lỗi; [failOn] chỉ làm lỗi đúng hàm có tên đó.
  ApiException? failWith;
  final Map<String, ApiException> failOn = {};

  /// Khác null: mọi hàm chờ [gate] hoàn thành mới trả lời (để test trạng thái chờ).
  Completer<void>? gate;

  /// Tìm đúng từ khóa [slowQuery] thì chờ [slowGate] (để test câu trả lời cũ đến muộn).
  String? slowQuery;
  Completer<void>? slowGate;

  /// deleteAnswer trả về câu hỏi null (câu hỏi vừa bị ẩn).
  bool deleteReturnsNoQuestion = false;

  Future<void> _call(String name) async {
    calls.add(name);
    if (gate != null) {
      await gate!.future;
    }
    final error = failOn[name] ?? failWith;
    if (error != null) {
      throw error;
    }
  }

  static const _notFound = ApiException(
    'Không tìm thấy nội dung bạn yêu cầu. Bài viết có thể đã bị gỡ hoặc đã bị xóa.',
    statusCode: 404,
  );

  @override
  Future<PageResult<Question>> findAll({
    String? q,
    List<int> topicIds = const [],
    String status = 'ALL',
    String sort = 'NEWEST',
    int page = 0,
    int size = QuestionDao.pageSize,
  }) async {
    lastQuery = {'q': q, 'topicIds': topicIds, 'status': status, 'sort': sort, 'page': page};
    if (q != null && q == slowQuery && slowGate != null) {
      calls.add('findAll');
      await slowGate!.future;
    } else {
      await _call('findAll');
    }
    final text = (q ?? '').toLowerCase();
    final matches = stored.where((s) {
      if (text.isNotEmpty && !s.title.toLowerCase().contains(text)) {
        return false;
      }
      if (topicIds.isNotEmpty && !s.topicIds.any(topicIds.contains)) {
        return false;
      }
      return switch (status) {
        'UNANSWERED' => s.unanswered,
        'SOLVED' => s.isSolved,
        'UNSOLVED' => !s.isSolved,
        _ => true,
      };
    }).toList();
    final start = page * perPage;
    final items = matches.skip(start).take(perPage).toList();
    return PageResult(
      items: items,
      page: page,
      size: perPage,
      totalItems: matches.length,
      totalPages: (matches.length / perPage).ceil(),
    );
  }

  @override
  Future<QuestionOverview> findOverview() async {
    await _call('findOverview');
    return const QuestionOverview(
      topics: [topicVisa, topicShopping, topicOther],
      total: 3,
      unanswered: 1,
      solved: 0,
      popularTopics: [(topic: topicShopping, count: 1)],
      topAnswerers: [(author: authorLanAnh, answerCount: 3, bestCount: 1)],
    );
  }

  @override
  Future<Question> findById(int id) async {
    await _call('findById');
    return details[id] ?? (throw _notFound);
  }

  @override
  Future<QuestionCompose> findCompose() async {
    await _call('findCompose');
    return const QuestionCompose(topics: [topicVisa, topicShopping, topicOther], canPostLinks: true);
  }

  @override
  Future<({Question question, QuestionCompose compose})> findForEdit(int id) async {
    await _call('findForEdit');
    final d = details[id] ?? (throw _notFound);
    return (
      question: Question(
        id: id,
        title: d.title,
        content: d.content,
        status: d.status,
        topicIds: d.topicIds,
        places: const [(id: 3, name: 'Ga Shinjuku')],
        media: [
          ...d.media,
          const MediaItem(id: 20, type: 'VIDEO', url: '/media/blog/2026/11/v.mp4'),
        ],
        isMine: true,
      ),
      compose: const QuestionCompose(topics: [topicVisa, topicShopping, topicOther]),
    );
  }

  @override
  Future<({int id, String status, String message})> create(
    Question question, {
    List<String> imagePaths = const [],
  }) async {
    await _call('create');
    saved.add((question: question, keepMediaIds: const [], imagePaths: imagePaths));
    const id = 100;
    details[id] = detailOf(id, question.title, author: authorAn, mine: true, content: question.content);
    stored.insert(0, cardOf(details[id]!, unanswered: true));
    return imagePaths.isEmpty
        ? (id: id, status: 'PUBLISHED', message: 'Câu hỏi của bạn đã được đăng.')
        : (
            id: id,
            status: 'PROCESSING',
            message: 'Đã gửi. Ảnh và video đang được quét, trong lúc này chỉ bạn thấy câu hỏi.',
          );
  }

  @override
  Future<({int id, String status, String message})> update(
    Question question, {
    List<int> keepMediaIds = const [],
    List<String> imagePaths = const [],
  }) async {
    await _call('update');
    saved.add((question: question, keepMediaIds: keepMediaIds, imagePaths: imagePaths));
    return (id: question.id!, status: 'PUBLISHED', message: 'Đã lưu thay đổi.');
  }

  @override
  Future<String> delete(int id) async {
    await _call('delete');
    stored.removeWhere((q) => q.id == id);
    details.remove(id);
    return 'Đã xóa câu hỏi.';
  }

  @override
  Future<({bool active, int count})> like(int id) async {
    await _call('like');
    final d = details[id]!;
    details[id] = d.copyWith(liked: true, likeCount: d.liked ? d.likeCount : d.likeCount + 1);
    return (active: true, count: details[id]!.likeCount);
  }

  @override
  Future<({bool active, int count})> unlike(int id) async {
    await _call('unlike');
    final d = details[id]!;
    details[id] = d.copyWith(liked: false, likeCount: d.liked ? d.likeCount - 1 : d.likeCount);
    return (active: false, count: details[id]!.likeCount);
  }

  @override
  Future<String> save(int id) async {
    await _call('save');
    details[id] = details[id]!.copyWith(saved: true);
    return 'Đã lưu câu hỏi.';
  }

  @override
  Future<String> unsave(int id) async {
    await _call('unsave');
    details[id] = details[id]!.copyWith(saved: false);
    return 'Đã bỏ lưu câu hỏi.';
  }

  @override
  Future<String> report(int id, int reasonId, String note) async {
    await _call('report');
    reports.add((id: id, reasonId: reasonId, note: note));
    return 'Cảm ơn bạn. Báo cáo đã được gửi.';
  }

  @override
  Future<({Question question, String message})> answer(int questionId, String content, {int? parentId}) async {
    await _call('answer');
    final d = details[questionId]!;
    final id = 500 + calls.length;
    final added = answerOf(id, authorAn, content, parentId: parentId, mine: true);
    final answers = parentId == null
        ? [...d.answers, added]
        : Answer.replace(d.answers, parentId, (a) => a.copyWith(replies: [...a.replies, added]));
    details[questionId] = _rebuild(d, answers);
    return (question: details[questionId]!, message: parentId == null ? 'Đã đăng câu trả lời.' : 'Đã gửi phản hồi.');
  }

  @override
  Future<({Question question, String message})> chooseBest(int questionId, int answerId) async {
    await _call('chooseBest');
    final d = details[questionId]!;
    final answers = [
      for (final a in d.answers)
        answerOf(a.id, a.author!, a.content, best: a.id == answerId, likes: a.likeCount, replies: a.replies),
    ]..sort((x, y) => (y.best ? 1 : 0) - (x.best ? 1 : 0));
    details[questionId] = _rebuild(d, answers, bestAnswerId: answerId);
    return (question: details[questionId]!, message: 'Đã chọn câu trả lời hay nhất.');
  }

  @override
  Future<({bool active, int count})> likeAnswer(int answerId) async {
    await _call('likeAnswer');
    return _setAnswerLike(answerId, true);
  }

  @override
  Future<({bool active, int count})> unlikeAnswer(int answerId) async {
    await _call('unlikeAnswer');
    return _setAnswerLike(answerId, false);
  }

  ({bool active, int count}) _setAnswerLike(int answerId, bool liked) {
    final qid = _questionOf(answerId);
    final d = details[qid]!;
    final old = Answer.find(d.answers, answerId)!;
    final count = old.liked == liked ? old.likeCount : old.likeCount + (liked ? 1 : -1);
    details[qid] = d.copyWith(
      answers: Answer.replace(d.answers, answerId, (a) => a.copyWith(liked: liked, likeCount: count)),
    );
    return (active: liked, count: count);
  }

  @override
  Future<({Question question, String message})> reportAnswer(int answerId, int reasonId, String note) async {
    await _call('reportAnswer');
    reports.add((id: answerId, reasonId: reasonId, note: note));
    return (question: details[_questionOf(answerId)]!, message: 'Cảm ơn bạn. Báo cáo đã được gửi.');
  }

  @override
  Future<({Question question, String message})> updateAnswer(int answerId, String content) async {
    await _call('updateAnswer');
    final qid = _questionOf(answerId);
    final d = details[qid]!;
    final answers = Answer.replace(
      d.answers,
      answerId,
      (a) => Answer(
        id: a.id,
        parentId: a.parentId,
        author: a.author,
        content: content,
        edited: true,
        best: a.best,
        isMine: a.isMine,
        likeCount: a.likeCount,
        replies: a.replies,
      ),
    );
    details[qid] = _rebuild(d, answers);
    return (question: details[qid]!, message: 'Đã lưu bình luận.');
  }

  @override
  Future<({Question? question, String message})> deleteAnswer(int answerId) async {
    await _call('deleteAnswer');
    final qid = _questionOf(answerId);
    final d = details[qid]!;
    details[qid] = _rebuild(d, _without(d.answers, answerId));
    return (question: deleteReturnsNoQuestion ? null : details[qid], message: 'Đã xóa bình luận.');
  }

  static List<Answer> _without(List<Answer> nodes, int id) => [
    for (final a in nodes)
      if (a.id != id) a.copyWith(replies: _without(a.replies, id)),
  ];

  int _questionOf(int answerId) =>
      details.entries.firstWhere((e) => Answer.find(e.value.answers, answerId) != null).key;

  Question _rebuild(Question d, List<Answer> answers, {int? bestAnswerId}) => detailOf(
    d.id!,
    d.title,
    author: d.author ?? authorMinh,
    content: d.content,
    status: d.status,
    mine: d.isMine,
    signedIn: d.signedIn,
    canInteract: d.canInteract,
    liked: d.liked,
    saved: d.saved,
    likes: d.likeCount,
    bestAnswerId: bestAnswerId ?? d.bestAnswerId,
    answers: answers,
    media: d.media,
    topics: d.topics,
  );
}
