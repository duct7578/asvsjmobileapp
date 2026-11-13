/// Văn bản pháp lý đang hiệu lực (bảng `legal_documents`, LegalDocumentResponse của web):
/// Điều khoản sử dụng (TOS), Chính sách bảo mật (PRIVACY), Quy tắc cộng đồng (COMMUNITY).
class LegalDocument {
  const LegalDocument({required this.type, required this.version, required this.content});

  /// TOS, PRIVACY hoặc COMMUNITY.
  final String type;

  /// Phiên bản, ví dụ "1.0".
  final String version;

  /// Nội dung chữ thường (có thể có xuống dòng).
  final String content;

  factory LegalDocument.fromJson(Map<String, dynamic> json) => LegalDocument(
    type: (json['type'] ?? '') as String,
    version: (json['version'] ?? '') as String,
    content: (json['content'] ?? '') as String,
  );

  /// Loại văn bản trong đường dẫn `GET /api/legal/{type}`: app gọi 'terms' nhưng server gọi là 'tos'.
  static String apiType(String type) {
    final lower = type.trim().toLowerCase();
    return lower == 'terms' ? 'tos' : lower;
  }

  /// Tên văn bản để làm tiêu đề, như trang /terms của web.
  static String titleOf(String type) => switch (apiType(type)) {
    'tos' => 'Điều khoản sử dụng',
    'privacy' => 'Chính sách bảo mật',
    'community' => 'Quy tắc cộng đồng',
    _ => 'Điều khoản và chính sách',
  };
}
