import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/faq_entry.dart';
import 'package:myasvsj/com.myasvsj.model/faq_topic.dart';
import 'package:myasvsj/com.myasvsj.model/page_result.dart';

/// Đọc "Câu hỏi thường gặp" (FAQ do Moderator viết) qua REST API công khai của web. App chỉ đọc, không ghi.
///
/// | Hàm          | API                               |
/// |--------------|-----------------------------------|
/// | findAll      | GET /api/faqs                     |
/// | findTopics   | GET /api/faqs/topics              |
/// | findById     | GET /api/faqs/{id}                |
/// | findRelated  | GET /api/faqs/related             |
class FaqDao {
  FaqDao(this._api);

  final ApiClient _api;

  /// Số câu mỗi trang (web: 10).
  static const int pageSize = 10;

  /// Một trang câu đã đăng (trang đầu là 0), mới cập nhật trước. [q] khớp câu hỏi hoặc câu trả lời (bỏ dấu,
  /// không phân biệt hoa thường); [topic] là mã chủ đề (FaqTopic.code), rỗng = mọi chủ đề.
  ///
  /// JSON trang của FAQ là `{items, total, page, size, totalPages}` (khác các API khác: `total`, không phải
  /// `totalItems`), nên tự đọc thay vì dùng `PageResult.fromJson`.
  Future<PageResult<FaqEntry>> findAll({String? q, String? topic, int page = 0, int size = pageSize}) async {
    final data =
        await _api.get(
              '/api/faqs',
              query: {
                if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
                if (topic != null && topic.isNotEmpty) 'topic': topic,
                'page': page,
                'size': size,
              },
            )
            as Map<String, dynamic>;
    return PageResult(
      items: [for (final item in (data['items'] as List?) ?? const []) FaqEntry.fromJson(item as Map<String, dynamic>)],
      page: (data['page'] ?? 0) as int,
      size: (data['size'] ?? size) as int,
      totalItems: (data['total'] ?? 0) as int,
      totalPages: (data['totalPages'] ?? 0) as int,
    );
  }

  /// Mọi chủ đề theo thứ tự của web, kèm số câu (khớp [q] khi đang tìm).
  Future<List<FaqTopic>> findTopics({String? q}) async {
    final data =
        await _api.get('/api/faqs/topics', query: {if (q != null && q.trim().isNotEmpty) 'q': q.trim()}) as List;
    return [for (final t in data) FaqTopic.fromJson(t as Map<String, dynamic>)];
  }

  /// Một câu. Không có hoặc đã bị ẩn: 404 "FAQ không tồn tại hoặc đã bị ẩn.".
  Future<FaqEntry> findById(int id) async => FaqEntry.fromJson(await _api.get('/api/faqs/$id') as Map<String, dynamic>);

  /// Những câu giống [q] nhất (câu hỏi đang gõ, hoặc từ khóa tìm của Hỏi-Đáp), tốt nhất trước; [limit] 1–5.
  /// Khác [findAll]: các từ không cần đứng liền nhau. Rỗng khi không có câu nào đủ giống.
  Future<List<FaqEntry>> findRelated(String q, {int limit = 3}) async {
    final data = await _api.get('/api/faqs/related', query: {'q': q.trim(), 'limit': limit}) as List;
    return [for (final e in data) FaqEntry.fromJson(e as Map<String, dynamic>)];
  }
}
