import 'package:myasvsj/com.myasvsj.model/point_line.dart';

/// Một trang "Lịch sử điểm", mới nhất trước (PointPage của `GET /api/me/points?page=`).
///
/// JSON: `{items, page, size, total, points}`. Khác PageResult: server gửi `total` chứ không gửi `totalPages`.
class PointPage {
  const PointPage({this.items = const [], this.page = 0, this.size = 20, this.total = 0, this.points = 0});

  final List<PointLine> items;
  final int page;
  final int size;

  /// Tổng số dòng lịch sử của mọi trang.
  final int total;

  /// Điểm hiện có của người dùng.
  final int points;

  /// Còn trang sau để tải thêm.
  bool get hasMore => (page + 1) * size < total;

  factory PointPage.fromJson(Map<String, dynamic> json) => PointPage(
    items: [for (final item in (json['items'] as List?) ?? const []) PointLine.fromJson(item as Map<String, dynamic>)],
    page: (json['page'] ?? 0) as int,
    size: (json['size'] ?? 20) as int,
    total: (json['total'] ?? 0) as int,
    points: (json['points'] ?? 0) as int,
  );
}
