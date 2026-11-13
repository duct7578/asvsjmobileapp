/// Khóa mã hóa hiện tại của thành viên trên server, kèm bản sao lưu khóa bí mật đã khóa bằng "mật khẩu khôi phục"
/// (KeyBackup của web, bảng `chat_keys`). Server không đọc được khóa bí mật.
///
/// JSON: `{id, publicKey, wrappedPrivateKey, wrapSalt, wrapIv, wrapIterations, createdAt}`.
class ChatKeyBackup {
  const ChatKeyBackup({
    required this.id,
    required this.publicKey,
    required this.wrappedPrivateKey,
    required this.wrapSalt,
    required this.wrapIv,
    required this.wrapIterations,
  });

  final int id;

  /// base64 của điểm P-256 dạng raw 65 byte (0x04 ‖ x ‖ y).
  final String publicKey;

  /// base64 của AES-GCM(PKCS8 của khóa bí mật), khóa bằng PBKDF2-SHA256 của mật khẩu khôi phục.
  final String wrappedPrivateKey;
  final String wrapSalt;
  final String wrapIv;
  final int wrapIterations;

  factory ChatKeyBackup.fromJson(Map<String, dynamic> json) => ChatKeyBackup(
    id: json['id'] as int,
    publicKey: json['publicKey'] as String,
    wrappedPrivateKey: json['wrappedPrivateKey'] as String,
    wrapSalt: json['wrapSalt'] as String,
    wrapIv: json['wrapIv'] as String,
    wrapIterations: json['wrapIterations'] as int,
  );

  /// Thân của POST /api/me/chats/keys (KeyRequest của web).
  Map<String, dynamic> toRequestJson() => {
    'publicKey': publicKey,
    'wrappedPrivateKey': wrappedPrivateKey,
    'wrapSalt': wrapSalt,
    'wrapIv': wrapIv,
    'wrapIterations': wrapIterations,
  };
}
