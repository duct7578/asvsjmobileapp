// Server giả cho test DAO: ApiClient thật, nhưng HTTP trả về JSON soạn sẵn thay vì gọi mạng.
//
// Dùng để kiểm tra DAO gửi đúng phương thức, đường dẫn, tham số, body, và đọc đúng JSON của web:
//
//   final server = FakeServer({
//     'GET /api/questions': (req) => apiOk({'items': [...], 'page': 0, 'totalPages': 1}),
//     'POST /api/questions/5/like': (req) => apiOk(null, message: 'Đã thích.'),
//   });
//   final dao = QuestionDao(server.api);
//   final page = await dao.findAll(q: 'thuê nhà');
//   expect(server.requests.last.uri.queryParameters['q'], 'thuê nhà');
//
// Mẫu JSON nên chép từ server thật (curl tới http://localhost:8080) để test bắt được lệch tên trường.
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:myasvsj/com.myasvsj.model/api_client.dart';

/// Body thành công giống ApiResponse.java: `{success: true, message, data}`.
Map<String, dynamic> apiOk(Object? data, {String message = 'OK'}) =>
    {'success': true, 'message': message, 'data': data, 'timestamp': '2026-11-08T00:00:00Z'};

/// Trả lời lỗi: mã HTTP và body `{success: false, message, data: fields}`.
FakeReply apiError(int status, String message, {Map<String, String> fields = const {}}) =>
    FakeReply(status, {'success': false, 'message': message, 'data': fields});

/// Trả lời có mã HTTP tự chọn (mặc định các route trả 200).
class FakeReply {
  const FakeReply(this.status, this.body);

  final int status;
  final Object? body;
}

/// Server giả. Khóa của [routes] là "PHƯƠNG_THỨC /đường/dẫn" (không gồm query); giá trị là hàm nhận
/// request và trả về body (Map/List, được bọc thẳng thành JSON) hoặc một [FakeReply].
class FakeServer implements HttpClientAdapter {
  FakeServer(this.routes) {
    api = ApiClient(Dio(BaseOptions(baseUrl: 'http://fake.local', validateStatus: (_) => true))
      ..httpClientAdapter = this);
  }

  final Map<String, Object? Function(RequestOptions request)> routes;

  /// Mọi request đã nhận (trừ lấy token CSRF), theo thứ tự.
  final List<RequestOptions> requests = [];

  late final ApiClient api;

  /// Request cuối cùng tới [method] [path].
  RequestOptions last(String method, String path) =>
      requests.lastWhere((r) => r.method == method && r.uri.path == path);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    // Đọc hết body như server thật: file ảnh của multipart được đóng, nên test xóa được thư mục tạm (Windows)
    await requestStream?.drain<void>();
    if (options.uri.path == '/api/auth/csrf') {
      return _json(200, apiOk({'token': 'csrf-test', 'headerName': 'X-XSRF-TOKEN'}));
    }
    requests.add(options);
    final key = '${options.method} ${options.uri.path}';
    final handler = routes[key];
    if (handler == null) {
      return _json(404, {'success': false, 'message': 'FakeServer: chưa có route "$key"', 'data': null});
    }
    final result = handler(options);
    if (result is FakeReply) {
      return _json(result.status, result.body);
    }
    return _json(200, result);
  }

  static ResponseBody _json(int status, Object? body) => ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}
