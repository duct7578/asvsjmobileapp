/// Một từ vựng hoặc mẫu câu tiếng Nhật dùng ở địa điểm, theo danh mục (`GET /api/map/places/{id}/phrases`).
///
/// JSON: `{id, kind: "VOCAB"|"PHRASE", japanese, romaji, meaningVi}`.
class PlacePhrase {
  const PlacePhrase({
    required this.id,
    this.kind = 'PHRASE',
    required this.japanese,
    this.romaji = '',
    this.meaningVi = '',
  });

  final int id;

  /// VOCAB (từ vựng) hoặc PHRASE (mẫu câu).
  final String kind;
  final String japanese;
  final String romaji;
  final String meaningVi;

  String get kindLabel => kind == 'VOCAB' ? 'Từ vựng' : 'Mẫu câu';

  factory PlacePhrase.fromJson(Map<String, dynamic> json) => PlacePhrase(
    id: json['id'] as int,
    kind: (json['kind'] ?? 'PHRASE') as String,
    japanese: (json['japanese'] ?? '') as String,
    romaji: (json['romaji'] ?? '') as String,
    meaningVi: (json['meaningVi'] ?? '') as String,
  );
}
