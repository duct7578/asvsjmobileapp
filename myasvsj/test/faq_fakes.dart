import 'dart:async';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/faq_dao.dart';
import 'package:myasvsj/com.myasvsj.model/faq_entry.dart';
import 'package:myasvsj/com.myasvsj.model/faq_resource.dart';
import 'package:myasvsj/com.myasvsj.model/faq_topic.dart';
import 'package:myasvsj/com.myasvsj.model/page_result.dart';

final faqSim = FaqEntry(
  id: 4,
  question: 'Làm thế nào để mua SIM điện thoại khi mới sang Nhật?',
  answer:
      'Bạn có thể đăng ký SIM tại cửa hàng của nhà mạng.\n- Mang **thẻ cư trú**\n- Hỏi [IIJmio](https://www.iijmio.jp)',
  topicCode: 'LIVING',
  topicName: 'Sinh hoạt và đời sống',
  updatedAt: DateTime(2026, 11, 7),
);

final faqTrash = FaqEntry(
  id: 5,
  question: 'Phân loại và đổ rác tại Nhật như thế nào?',
  answer: 'Rác thường được chia thành rác cháy được và rác không cháy được.',
  topicCode: 'LIVING',
  topicName: 'Sinh hoạt và đời sống',
  updatedAt: DateTime(2026, 11, 7),
  resources: const [FaqResource(kind: 'GUIDE', targetId: 24, label: 'Xem chi tiết về phân loại rác tại Nhật')],
);

final faqPassport = FaqEntry(
  id: 10,
  question: 'Nếu bị mất hộ chiếu tại Nhật phải làm gì?',
  answer: 'Trình báo cảnh sát, sau đó liên hệ Đại sứ quán.',
  topicCode: 'OTHER',
  topicName: 'Khác',
  updatedAt: DateTime(2026, 11, 7),
);

/// DAO giả của Câu hỏi thường gặp: dữ liệu trong bộ nhớ, ghi lại các lần gọi.
class FakeFaqDao implements FaqDao {
  FakeFaqDao({this.perPage = 10});

  final int perPage;
  final List<FaqEntry> entries = [faqSim, faqTrash, faqPassport];

  /// Chủ đề theo thứ tự của web; số câu tính theo [entries] và từ khóa.
  final List<({String code, String title})> topicNames = [
    (code: 'LIVING', title: 'Sinh hoạt và đời sống'),
    (code: 'LANGUAGE', title: 'Ngôn ngữ và giao tiếp'),
    (code: 'OTHER', title: 'Khác'),
  ];

  /// Kết quả của findRelated.
  List<FaqEntry> relatedResult = [faqSim];

  final List<String> calls = [];
  final List<({String q, int limit})> relatedCalls = [];
  Map<String, Object?> lastQuery = {};

  ApiException? failWith;
  final Map<String, ApiException> failOn = {};
  Completer<void>? gate;

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

  bool _matches(FaqEntry e, String? q) {
    final text = (q ?? '').trim().toLowerCase();
    return text.isEmpty || '${e.question} ${e.answer}'.toLowerCase().contains(text);
  }

  @override
  Future<PageResult<FaqEntry>> findAll({String? q, String? topic, int page = 0, int size = FaqDao.pageSize}) async {
    lastQuery = {'q': q, 'topic': topic, 'page': page};
    await _call('findAll');
    final matches = entries
        .where((e) => _matches(e, q) && (topic == null || topic.isEmpty || e.topicCode == topic))
        .toList();
    return PageResult(
      items: matches.skip(page * perPage).take(perPage).toList(),
      page: page,
      size: perPage,
      totalItems: matches.length,
      totalPages: (matches.length / perPage).ceil(),
    );
  }

  @override
  Future<List<FaqTopic>> findTopics({String? q}) async {
    await _call('findTopics');
    return [
      for (final t in topicNames)
        FaqTopic(
          code: t.code,
          title: t.title,
          count: entries.where((e) => e.topicCode == t.code && _matches(e, q)).length,
        ),
    ];
  }

  @override
  Future<FaqEntry> findById(int id) async {
    await _call('findById');
    for (final e in entries) {
      if (e.id == id) {
        return e;
      }
    }
    throw const ApiException('FAQ không tồn tại hoặc đã bị ẩn.', statusCode: 404);
  }

  @override
  Future<List<FaqEntry>> findRelated(String q, {int limit = 3}) async {
    relatedCalls.add((q: q, limit: limit));
    await _call('findRelated');
    return relatedResult.take(limit).toList();
  }
}
