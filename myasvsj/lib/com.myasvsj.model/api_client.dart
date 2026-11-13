import 'dart:async';
import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/api_response.dart';

/// Lớp duy nhất nói chuyện HTTP với server web. Chỉ các DAO dùng lớp này; Screen và Controller không gọi nó.
///
/// - Giữ cookie phiên `JSESSIONID` và lưu xuống máy, nên mở lại app vẫn còn đăng nhập (phiên web 14 ngày).
/// - Gửi header `X-XSRF-TOKEN` cho mọi POST / PUT / DELETE; token lấy từ `GET /api/auth/csrf`.
/// - Trả về [ApiResponse] khi thành công, hoặc ném [ApiException] mang câu thông báo của server.
class ApiClient {
  ApiClient(this._dio);

  /// Địa chỉ server. Mặc định là máy dev nhìn từ giả lập Android. Máy thật thì chạy
  /// `flutter run --dart-define=API_BASE_URL=http://<IP LAN của máy chạy server>:8080`.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  final Dio _dio;
  String? _csrfToken;

  /// Tạo ApiClient có cookie lưu trong thư mục riêng của app.
  static Future<ApiClient> create() async {
    final dir = await getApplicationSupportDirectory();
    final cookies = PersistCookieJar(storage: FileStorage('${dir.path}/cookies'));
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        // Nhận mọi mã HTTP để tự đọc câu thông báo của server thay vì để dio ném lỗi
        validateStatus: (_) => true,
      ),
    );
    dio.interceptors.add(CookieManager(cookies));
    return ApiClient(dio);
  }

  /// ApiClient giữ cookie trong bộ nhớ, không ghi xuống máy. Dùng cho test chạy với server thật
  /// (`test/live/`), vì trong test không có thư mục của app.
  factory ApiClient.inMemory(String url) {
    final dio = Dio(
      BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        validateStatus: (_) => true,
      ),
    );
    dio.interceptors.add(CookieManager(CookieJar()));
    return ApiClient(dio);
  }

  /// Đường dẫn media của server (ví dụ `/media/blog/12.jpg`) thành địa chỉ đầy đủ để hiện ảnh.
  /// Địa chỉ đã đầy đủ (http…) giữ nguyên; rỗng trả về rỗng.
  static String absoluteUrl(String? path) {
    if (path == null || path.isEmpty || path.startsWith('http')) {
      return path ?? '';
    }
    return '$baseUrl${path.startsWith('/') ? '' : '/'}$path';
  }

  /// GET, trả về phần `data`.
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async =>
      (await send('GET', path, query: query)).data;

  /// POST, PUT, DELETE trả về cả [ApiResponse] vì màn hình cần câu thông báo của server.
  Future<ApiResponse> post(String path, [Object? body]) => send('POST', path, body: body);

  Future<ApiResponse> put(String path, [Object? body]) => send('PUT', path, body: body);

  Future<ApiResponse> delete(String path) => send('DELETE', path);

  /// POST hoặc PUT có file (multipart/form-data), như form "Viết bài" của web.
  ///
  /// Server đọc phần JSON bằng `@RequestPart("<jsonPart>")` (ví dụ "post", "question", "review", "request")
  /// và file theo tên phần trong [files] (ví dụ {"images": [đường dẫn ảnh, …]} hoặc {"photo": [đường dẫn]}).
  /// File là đường dẫn trên máy; ảnh nên đã được nén sang JPEG trước (xem PhotoPicker).
  Future<ApiResponse> sendMultipart(
    String method,
    String path, {
    required String jsonPart,
    required Map<String, dynamic> json,
    Map<String, List<String>> files = const {},
  }) async {
    final form = FormData();
    form.files.add(MapEntry(
      jsonPart,
      MultipartFile.fromString(jsonEncode(json), contentType: DioMediaType('application', 'json')),
    ));
    for (final entry in files.entries) {
      for (final filePath in entry.value) {
        form.files.add(MapEntry(
          entry.key,
          await MultipartFile.fromFile(filePath, filename: _fileName(filePath), contentType: _mediaType(filePath)),
        ));
      }
    }
    return send(method, path, body: form);
  }

  /// Mở luồng Server-Sent Events (ví dụ `GET /api/me/live`) và trả về từng dòng chữ của luồng,
  /// kể cả dòng trống ngăn cách hai sự kiện. Luồng kết thúc khi server đóng kết nối hoặc mất mạng.
  ///
  /// Hủy lắng nghe (đăng xuất) thì kết nối HTTP được đóng ngay, không đợi dòng tiếp theo của server.
  Stream<String> openLines(String path) {
    final cancel = CancelToken();
    StreamSubscription<String>? lines;
    late final StreamController<String> controller;
    controller = StreamController<String>(
      onListen: () async {
        try {
          final response = await _dio.get<ResponseBody>(
            path,
            cancelToken: cancel,
            options: Options(
              responseType: ResponseType.stream,
              receiveTimeout: Duration.zero,
              headers: {'Accept': 'text/event-stream'},
            ),
          );
          final status = response.statusCode ?? 0;
          if (status != 200 || response.data == null) {
            controller.addError(ApiException(_errorMessage(status, null), statusCode: status));
            await controller.close();
            return;
          }
          lines = response.data!.stream
              .cast<List<int>>()
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .listen(
                controller.add,
                onError: (Object e) => controller.addError(e is DioException ? ApiException(_networkMessage(e)) : e),
                onDone: controller.close,
              );
        } on DioException catch (e) {
          if (!CancelToken.isCancel(e)) {
            controller.addError(ApiException(_networkMessage(e)));
          }
          await controller.close();
        }
      },
      onCancel: () async {
        cancel.cancel();
        await lines?.cancel();
      },
    );
    return controller.stream;
  }

  /// Đăng nhập và đăng xuất đổi phiên nên token CSRF cũ hết hiệu lực; lần ghi sau sẽ lấy token mới.
  void forgetCsrfToken() => _csrfToken = null;

  static String _fileName(String path) => path.split(RegExp(r'[\\/]')).last;

  static DioMediaType _mediaType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return DioMediaType('image', 'png');
    }
    if (lower.endsWith('.webp')) {
      return DioMediaType('image', 'webp');
    }
    if (lower.endsWith('.mp4')) {
      return DioMediaType('video', 'mp4');
    }
    return DioMediaType('image', 'jpeg');
  }

  Future<ApiResponse> send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool retried = false,
  }) async {
    final writes = method != 'GET';
    if (writes && _csrfToken == null) {
      await _loadCsrfToken();
    }

    final Response<dynamic> response;
    try {
      response = await _dio.request<dynamic>(
        path,
        queryParameters: query,
        data: body,
        options: Options(method: method, headers: {if (writes) 'X-XSRF-TOKEN': _csrfToken}),
      );
    } on DioException catch (e) {
      throw ApiException(_networkMessage(e));
    }

    final status = response.statusCode ?? 0;
    final api = ApiResponse.tryParse(response.data);

    // 403 không kèm ApiResponse là Spring Security từ chối token CSRF (token cũ, phiên đã đổi):
    // lấy token mới rồi gửi lại đúng một lần.
    if (status == 403 && api == null && writes && !retried) {
      _csrfToken = null;
      // FormData chỉ gửi được một lần: gửi lại bằng bản sao
      final again = body is FormData ? body.clone() : body;
      return send(method, path, query: query, body: again, retried: true);
    }
    if (status >= 200 && status < 300) {
      // 204 của đăng xuất không có body
      return api ?? ApiResponse(success: true, message: '', data: response.data);
    }
    throw ApiException(_errorMessage(status, api), statusCode: status, fields: _fields(api));
  }

  Future<void> _loadCsrfToken() async {
    final data = await get('/api/auth/csrf') as Map<String, dynamic>;
    _csrfToken = data['token'] as String;
  }

  static String _networkMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return 'Server phản hồi quá lâu. Hãy thử lại.';
    }
    return 'Không kết nối được tới server ($baseUrl). Hãy kiểm tra mạng.';
  }

  static String _errorMessage(int status, ApiResponse? api) {
    if (api != null && api.message.isNotEmpty) {
      return api.message;
    }
    return switch (status) {
      401 => 'Bạn cần đăng nhập để làm việc này.',
      403 => 'Bạn không có quyền thực hiện thao tác này.',
      404 => 'Không tìm thấy dữ liệu.',
      _ => 'Server gặp lỗi ($status). Hãy thử lại sau.',
    };
  }

  /// Lỗi theo từng ô nhập: server gửi trong `data` dạng {"title": "…"}.
  static Map<String, String> _fields(ApiResponse? api) {
    final data = api?.data;
    if (data is! Map) {
      return const {};
    }
    return {
      for (final entry in data.entries)
        if (entry.value is String) entry.key.toString(): entry.value as String,
    };
  }
}
