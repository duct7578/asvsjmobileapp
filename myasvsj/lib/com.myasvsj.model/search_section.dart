/// Một phần của kết quả tìm kiếm (Section của `GET /api/search`): tối đa 5 mục đầu và tổng số mục tìm được.
class SearchSection<T> {
  const SearchSection({this.total = 0, this.items = const []});

  final int total;
  final List<T> items;

  bool get isEmpty => total == 0;

  /// Còn mục chưa hiện (để mời "Xem thêm" ở danh sách riêng của phần đó).
  bool get hasMore => total > items.length;

  /// [parse] đổi từng phần tử của `items` thành thực thể. JSON null cho phần rỗng.
  factory SearchSection.fromJson(Object? json, T Function(Map<String, dynamic>) parse) {
    if (json is! Map<String, dynamic>) {
      return SearchSection<T>();
    }
    return SearchSection<T>(
      total: (json['total'] ?? 0) as int,
      items: [for (final item in (json['items'] as List?) ?? const []) parse(item as Map<String, dynamic>)],
    );
  }
}
