/// Một phạm vi lọc và số mục của nó (ScopeCount của web), ví dụ `{code: "NEAR", count: 4}`.
///
/// "Dành cho bạn": ALL, NEAR, STAGE, INTEREST. "Review mới": AREA, PREFECTURE, ALL.
class FeedScope {
  const FeedScope({required this.code, this.count = 0});

  final String code;
  final int count;

  factory FeedScope.fromJson(Map<String, dynamic> json) =>
      FeedScope(code: (json['code'] ?? '') as String, count: (json['count'] ?? 0) as int);

  static List<FeedScope> listFrom(Object? json) => [
    for (final s in (json as List?) ?? const []) FeedScope.fromJson(s as Map<String, dynamic>),
  ];
}
