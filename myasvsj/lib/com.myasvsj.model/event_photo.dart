/// Một ảnh trong "Album từ review" của sự kiện: ảnh của các review đã đăng, năm mới nhất trước.
///
/// JSON (AlbumPhoto của web): `{url, authorName, year, width, height}`.
class EventPhoto {
  const EventPhoto({required this.url, this.authorName = '', this.year = 0, this.width, this.height});

  /// Đường dẫn như server trả về (`/media/…`).
  final String url;
  final String authorName;

  /// Năm của lần tổ chức mà review chụp ảnh này.
  final int year;
  final int? width;
  final int? height;

  factory EventPhoto.fromJson(Map<String, dynamic> json) => EventPhoto(
    url: (json['url'] ?? '') as String,
    authorName: (json['authorName'] ?? '') as String,
    year: (json['year'] ?? 0) as int,
    width: json['width'] as int?,
    height: json['height'] as int?,
  );
}
