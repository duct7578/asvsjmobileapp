/// Một mẫu câu hoặc từ vựng tiếng Nhật tìm được (PhraseCard trong `phrases` của `GET /api/search`).
class SearchPhrase {
  const SearchPhrase({
    required this.id,
    required this.japanese,
    this.kind = 'PHRASE',
    this.romaji = '',
    this.meaningVi = '',
    this.categoryName,
  });

  final int id;

  /// PHRASE (mẫu câu) hoặc VOCAB (từ vựng).
  final String kind;
  final String japanese;
  final String romaji;
  final String meaningVi;

  /// Loại địa điểm dùng câu này, ví dụ "Cửa hàng tiện lợi".
  final String? categoryName;

  bool get isVocab => kind == 'VOCAB';

  factory SearchPhrase.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    return SearchPhrase(
      id: json['id'] as int,
      kind: (json['kind'] ?? 'PHRASE') as String,
      japanese: (json['japanese'] ?? '') as String,
      romaji: (json['romaji'] ?? '') as String,
      meaningVi: (json['meaningVi'] ?? '') as String,
      categoryName: category?['name'] as String?,
    );
  }
}
