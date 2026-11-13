import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/search_result.dart';

/// "Tìm kiếm" chung qua REST API của web (chỉ đọc, ai cũng gọi được).
///
/// | Hàm    | API                  |
/// |--------|----------------------|
/// | search | GET /api/search?q=   |
class SearchDao {
  SearchDao(this._api);

  final ApiClient _api;

  /// Tìm [q] trong địa điểm, bài viết, câu hỏi, cẩm nang, sự kiện, mẫu câu và FAQ cùng lúc (5 mục đầu mỗi phần).
  /// Từ khóa quá 100 ký tự: server trả 400 "Từ khóa tìm kiếm tối đa 100 ký tự.".
  Future<SearchResult> search(String q) async =>
      SearchResult.fromJson(await _api.get('/api/search', query: {'q': q.trim()}) as Map<String, dynamic>);
}
