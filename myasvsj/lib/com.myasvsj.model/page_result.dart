/// Một trang kết quả của các API danh sách: `{items, page, size, totalItems, totalPages}`.
///
/// Ví dụ `GET /api/blogs?page=0&size=10`. Trang đầu là 0.
class PageResult<T> {
  const PageResult({
    required this.items,
    this.page = 0,
    this.size = 0,
    this.totalItems = 0,
    this.totalPages = 0,
  });

  final List<T> items;
  final int page;
  final int size;
  final int totalItems;
  final int totalPages;

  /// Còn trang sau để tải thêm.
  bool get hasMore => page + 1 < totalPages;

  /// Đọc phần `data` của API; [parse] đổi từng phần tử của `items` thành thực thể.
  ///
  /// Vài API (cẩm nang, review địa điểm, lịch sử điểm) gửi tổng số ở `total` và không có `totalPages`:
  /// khi đó số trang được tính từ `total` và `size`.
  factory PageResult.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>) parse) {
    final size = (json['size'] ?? 0) as int;
    final total = (json['totalItems'] ?? json['total'] ?? 0) as int;
    final pages = json['totalPages'] as int? ?? (size > 0 ? (total + size - 1) ~/ size : 0);
    return PageResult(
      items: [for (final item in (json['items'] as List?) ?? const []) parse(item as Map<String, dynamic>)],
      page: (json['page'] ?? 0) as int,
      size: size,
      totalItems: total,
      totalPages: pages,
    );
  }
}
