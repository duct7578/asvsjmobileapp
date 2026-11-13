import 'package:myasvsj/com.myasvsj.model/tag_proof_type.dart';

/// Một tag định danh người dùng xin được (bảng `tag_types`), ví dụ "Mentor".
///
/// JSON: `{id, name, description, color, selfieOnly, proofTypes, owned}` (TagOption của
/// `GET /api/me/tag-requests/compose`).
class TagOption {
  const TagOption({
    required this.id,
    required this.name,
    this.description = '',
    this.color = '',
    this.selfieOnly = false,
    this.proofTypes = const [],
    this.owned = false,
  });

  final int id;
  final String name;
  final String description;

  /// Mã màu web, ví dụ "#C2456E".
  final String color;

  /// Chỉ cần một ảnh chân dung, không chọn loại minh chứng (tag "Người Nhật").
  final bool selfieOnly;
  final List<TagProofType> proofTypes;

  /// Người dùng đã có tag này nên không chọn được.
  final bool owned;

  factory TagOption.fromJson(Map<String, dynamic> json) => TagOption(
    id: json['id'] as int,
    name: (json['name'] ?? '') as String,
    description: (json['description'] ?? '') as String,
    color: (json['color'] ?? '') as String,
    selfieOnly: (json['selfieOnly'] ?? false) as bool,
    proofTypes: [
      for (final p in (json['proofTypes'] as List?) ?? const []) TagProofType.fromJson(p as Map<String, dynamic>),
    ],
    owned: (json['owned'] ?? false) as bool,
  );
}
