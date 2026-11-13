import 'package:myasvsj/com.myasvsj.model/api_client.dart';

/// Ảnh hoặc video gắn vào bài viết, câu hỏi, review (`media` trong JSON của web).
///
/// JSON: `{id, type: "IMAGE"|"VIDEO", url: "/media/…", width?, height?, scanStatus?}`.
class MediaItem {
  const MediaItem({required this.id, required this.type, required this.url, this.width, this.height});

  final int id;

  /// IMAGE hoặc VIDEO.
  final String type;

  /// Đường dẫn như server trả về, thường là tương đối (`/media/…`).
  final String url;
  final int? width;
  final int? height;

  bool get isImage => type == 'IMAGE';

  /// Đổi một đường dẫn media bất kỳ của server (ảnh bìa sự kiện, ảnh cẩm nang…) thành địa chỉ đầy đủ.
  /// Screen dùng hàm này (hoặc widget MediaImage) thay vì tự ghép địa chỉ server.
  static String resolve(String? path) => ApiClient.absoluteUrl(path);

  /// Địa chỉ đầy đủ để `Image.network` tải được (ghép với địa chỉ server).
  String get absoluteUrl => ApiClient.absoluteUrl(url);

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
        id: json['id'] as int,
        type: (json['type'] ?? 'IMAGE') as String,
        url: (json['url'] ?? '') as String,
        width: json['width'] as int?,
        height: json['height'] as int?,
      );
}
