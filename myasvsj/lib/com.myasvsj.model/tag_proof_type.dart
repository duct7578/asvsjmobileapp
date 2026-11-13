/// Một loại minh chứng một tag nhận, ví dụ "Thẻ sinh viên (学生証)".
///
/// JSON: `{id, name}` (ProofType của `GET /api/me/tag-requests/compose`).
class TagProofType {
  const TagProofType({required this.id, required this.name});

  final int id;
  final String name;

  factory TagProofType.fromJson(Map<String, dynamic> json) =>
      TagProofType(id: json['id'] as int, name: (json['name'] ?? '') as String);
}
