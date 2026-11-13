import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/area_option.dart';
import 'package:myasvsj/com.myasvsj.model/area_picker_data.dart';
import 'package:myasvsj/com.myasvsj.model/interest_settings.dart';
import 'package:myasvsj/com.myasvsj.model/point_page.dart';
import 'package:myasvsj/com.myasvsj.model/tag_compose.dart';
import 'package:myasvsj/com.myasvsj.model/tag_pending_request.dart';
import 'package:myasvsj/com.myasvsj.model/tag_request.dart';
import 'package:myasvsj/com.myasvsj.model/user_profile.dart';

/// Truy cập dữ liệu trang "Tôi" qua REST API của web: hồ sơ, lịch sử điểm, khu vực và giai đoạn,
/// chủ đề quan tâm, yêu cầu tag định danh. Các API `/api/me/**` cần đăng nhập (khách nhận 401).
///
/// | Hàm                   | API                                       |
/// |-----------------------|-------------------------------------------|
/// | findProfile           | GET /api/me/profile                       |
/// | updateAreaStage       | PUT /api/me/profile                       |
/// | findPointHistory      | GET /api/me/points?page=                  |
/// | findAreaPicker        | GET /api/areas                            |
/// | findAreasInPrefecture | GET /api/areas/prefectures/{code}         |
/// | searchAreas           | GET /api/areas/search?q=                  |
/// | findNearestArea       | GET /api/areas/nearest?lat=&lng=          |
/// | findArea              | GET /api/areas/{id}                       |
/// | findInterests         | GET /api/me/interests                     |
/// | updateInterests       | PUT /api/me/interests                     |
/// | findTagCompose        | GET /api/me/tag-requests/compose          |
/// | submitTagRequest      | POST /api/me/tag-requests (multipart)     |
class ProfileDao {
  ProfileDao(this._api);

  final ApiClient _api;

  // ---------------------------------------------------------------- Hồ sơ

  /// Hồ sơ của người đang đăng nhập.
  Future<UserProfile> findProfile() async =>
      UserProfile.fromJson(await _api.get('/api/me/profile') as Map<String, dynamic>);

  /// Lưu khu vực và giai đoạn; null là bỏ chọn. Trả về câu "Đã lưu khu vực và giai đoạn." và hồ sơ mới.
  /// Giai đoạn lạ → 400 (lỗi ô `stage`), khu vực không có → 400 "Khu vực không hợp lệ".
  Future<({String message, UserProfile profile})> updateAreaStage({int? areaId, String? stage}) async {
    final response = await _api.put('/api/me/profile', {'areaId': areaId, 'stage': stage});
    return (message: response.message, profile: UserProfile.fromJson(response.data as Map<String, dynamic>));
  }

  // ---------------------------------------------------------------- Lịch sử điểm

  /// Một trang lịch sử điểm (20 dòng, mới nhất trước, trang đầu là 0).
  Future<PointPage> findPointHistory({int page = 0}) async =>
      PointPage.fromJson(await _api.get('/api/me/points', query: {'page': page}) as Map<String, dynamic>);

  // ---------------------------------------------------------------- Khu vực (công khai)

  /// 47 tỉnh và vị trí thử của server (nếu có).
  Future<AreaPickerData> findAreaPicker() async =>
      AreaPickerData.fromJson(await _api.get('/api/areas') as Map<String, dynamic>);

  /// Các khu vực của một tỉnh, theo mã tỉnh (ví dụ "13" là Tokyo).
  Future<List<AreaOption>> findAreasInPrefecture(String code) async =>
      _areas(await _api.get('/api/areas/prefectures/${Uri.encodeComponent(code)}'));

  /// Tìm nhanh theo tên romaji, kanji hoặc kana (tối đa 12, tên bắt đầu bằng từ khóa trước); rỗng khi [q] trống.
  Future<List<AreaOption>> searchAreas(String q) async => _areas(await _api.get('/api/areas/search', query: {'q': q}));

  /// Khu vực gần vị trí nhất (gợi ý để người dùng xác nhận). Vị trí ngoài Nhật → 400
  /// "Vị trí này không ở Nhật Bản. Hãy chọn một điểm ở Nhật.". Server không lưu vị trí.
  Future<AreaOption> findNearestArea(double lat, double lng) async => AreaOption.fromJson(
    await _api.get('/api/areas/nearest', query: {'lat': lat, 'lng': lng}) as Map<String, dynamic>,
  );

  /// Một khu vực theo id; không có → 404 "Không tìm thấy khu vực này.".
  Future<AreaOption> findArea(int id) async =>
      AreaOption.fromJson(await _api.get('/api/areas/$id') as Map<String, dynamic>);

  static List<AreaOption> _areas(dynamic data) => [
    for (final a in (data as List?) ?? const []) AreaOption.fromJson(a as Map<String, dynamic>),
  ];

  // ---------------------------------------------------------------- Chủ đề quan tâm

  /// Mọi chủ đề chọn được (trừ "Khác"), cờ đã chọn và gợi ý.
  Future<InterestSettings> findInterests() async =>
      InterestSettings.fromJson(await _api.get('/api/me/interests') as Map<String, dynamic>);

  /// Lưu toàn bộ lựa chọn mới (rỗng là bỏ hết). Quá 5 → 400 "Bạn chọn được tối đa 5 chủ đề.".
  /// Trả về câu "Đã lưu chủ đề quan tâm." và danh sách mới.
  Future<({String message, InterestSettings settings})> updateInterests(List<int> topicIds) async {
    final response = await _api.put('/api/me/interests', {'topicIds': topicIds});
    return (message: response.message, settings: InterestSettings.fromJson(response.data as Map<String, dynamic>));
  }

  // ---------------------------------------------------------------- Tag định danh

  /// Các tag xin được, yêu cầu đang chờ (nếu có), số ngày giữ ảnh.
  Future<TagCompose> findTagCompose() async =>
      TagCompose.fromJson(await _api.get('/api/me/tag-requests/compose') as Map<String, dynamic>);

  /// Gửi yêu cầu tag: phần JSON "request" `{tagId, proofTypeId, consent}` và ảnh phần "photo".
  /// Thiếu thông tin → 400 kèm lỗi theo ô (`tagId`, `proofTypeId`, `photo`, `consent`); đang có yêu cầu chờ hoặc
  /// đã có tag → 409. Trả về câu "Đã gửi yêu cầu tag." và yêu cầu đang chờ mới.
  Future<({String message, TagPendingRequest? pending})> submitTagRequest(TagRequest request) async {
    final photo = request.photoPath;
    final response = await _api.sendMultipart(
      'POST',
      '/api/me/tag-requests',
      jsonPart: 'request',
      json: request.toJson(),
      files: {
        if (photo != null) 'photo': [photo],
      },
    );
    final data = response.data;
    return (
      message: response.message,
      pending: data is Map<String, dynamic> ? TagPendingRequest.tryParse(data['pending']) : null,
    );
  }
}
