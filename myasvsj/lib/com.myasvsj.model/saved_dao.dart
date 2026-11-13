import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/saved_kind.dart';
import 'package:myasvsj/com.myasvsj.model/saved_list.dart';

/// Truy cập dữ liệu "Đã lưu" qua REST API của web. Danh sách chỉ đọc; lưu và bỏ lưu dùng API của từng loại.
///
/// | Hàm      | API                                                                   |
/// |----------|-----------------------------------------------------------------------|
/// | findAll  | GET /api/me/saved                                                     |
/// | save     | POST /api/map/places/{id}/save, /api/blogs/{id}/save,                 |
/// |          | /api/questions/{id}/save, /api/guides/{id}/save                       |
/// | unsave   | DELETE cùng các đường dẫn trên                                        |
class SavedDao {
  SavedDao(this._api);

  final ApiClient _api;

  /// Mọi mục đã lưu còn xem được, mỗi loại mới lưu trước. Chỉ User đã đăng nhập.
  Future<SavedList> findAll() async => SavedList.fromJson(await _api.get('/api/me/saved') as Map<String, dynamic>);

  /// Lưu lại một mục (dùng cho "Hoàn tác"); trả về câu của server, ví dụ "Đã lưu bài viết.".
  Future<String> save(SavedKind kind, int id) async => (await _api.post(savePath(kind, id))).message;

  /// Bỏ lưu một mục; trả về câu của server, ví dụ "Đã bỏ lưu địa điểm.". Gọi lại khi đã bỏ vẫn thành công;
  /// nội dung đã bị gỡ → 404.
  Future<String> unsave(SavedKind kind, int id) async => (await _api.delete(savePath(kind, id))).message;

  /// API lưu của từng loại.
  static String savePath(SavedKind kind, int id) => switch (kind) {
    SavedKind.place => '/api/map/places/$id/save',
    SavedKind.post => '/api/blogs/$id/save',
    SavedKind.question => '/api/questions/$id/save',
    SavedKind.guide => '/api/guides/$id/save',
  };
}
