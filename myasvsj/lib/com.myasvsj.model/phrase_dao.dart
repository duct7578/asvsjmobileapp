import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/phrase.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_marks.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_overview.dart';

/// Truy cập dữ liệu Nhật ngữ (mẫu câu, từ vựng) qua REST API của web: đọc bảng `phrases`, ghi câu trả lời thẻ ghi nhớ
/// vào `user_phrase_marks` và báo lỗi vào `reports`.
///
/// | Hàm          | API                               |
/// |--------------|-----------------------------------|
/// | findOverview | GET /api/phrases/overview         |
/// | findAll      | GET /api/phrases                  |
/// | flash        | POST /api/phrases/{id}/flash      |
/// | clearFlash   | DELETE /api/phrases/{id}/flash    |
/// | report       | POST /api/phrases/{id}/report     |
///
/// Hai GET ai cũng gọi được. Ba hàm ghi chỉ dành cho thành viên đã đăng nhập (khách nhận 401).
class PhraseDao {
  PhraseDao(this._api);

  final ApiClient _api;

  /// Trang đầu: hai phần Mẫu câu và Từ vựng với chủ đề, loại địa điểm và số "đã thuộc" của thành viên,
  /// cờ `member` và các lý do báo lỗi.
  Future<PhraseOverview> findOverview() async =>
      PhraseOverview.fromJson(await _api.get('/api/phrases/overview') as Map<String, dynamic>);

  /// Mục của một chủ đề [topic], một loại địa điểm [category], một danh sách riêng [mine] ("learning" = Chưa thuộc,
  /// "learned" = Đã thuộc; chỉ thành viên, khách nhận 401), hoặc tìm theo [q] (tiếng Nhật, romaji, nghĩa, tên chủ đề
  /// và địa điểm). Không lọc gì là cả thư viện. Theo loại địa điểm rồi thứ tự nhập, tối đa 200 mục, không phân trang.
  Future<List<Phrase>> findAll({String? topic, String? category, String? mine, String? q}) async {
    final data =
        await _api.get(
              '/api/phrases',
              query: {
                if (topic != null && topic.isNotEmpty) 'topic': topic,
                if (category != null && category.isNotEmpty) 'category': category,
                if (mine != null && mine.isNotEmpty) 'mine': mine,
                if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
              },
            )
            as List;
    return [for (final item in data) Phrase.fromJson(item as Map<String, dynamic>)];
  }

  /// Câu trả lời thẻ ghi nhớ: [learned] true là "Đã thuộc", false là "Chưa thuộc"; câu trả lời sau thay câu trước.
  /// Trả về dấu mới, kèm câu "Đã lưu: Đã thuộc." / "Đã lưu: Chưa thuộc.".
  Future<PhraseMarks> flash(int id, {required bool learned}) async {
    final response = await _api.post('/api/phrases/$id/flash', {'learned': learned});
    return PhraseMarks.fromJson(response.data as Map<String, dynamic>, message: response.message);
  }

  /// "Bỏ đánh dấu": không còn Chưa thuộc hay Đã thuộc. Trả về dấu mới, kèm câu "Đã bỏ đánh dấu.".
  Future<PhraseMarks> clearFlash(int id) async {
    final response = await _api.delete('/api/phrases/$id/flash');
    return PhraseMarks.fromJson(response.data as Map<String, dynamic>, message: response.message);
  }

  /// Báo lỗi mẫu câu với lý do [reasonId] (lý do lấy từ `reportReasons` của trang đầu) và ghi chú [note]. Mỗi người
  /// chỉ báo một lần mỗi mục (lần sau nhận 409 "Bạn đã báo cáo nội dung này rồi."). Trả về câu thông báo của server.
  Future<String> report(int id, {required int reasonId, String note = ''}) async =>
      (await _api.post('/api/phrases/$id/report', {'reasonId': reasonId, 'note': note})).message;
}
