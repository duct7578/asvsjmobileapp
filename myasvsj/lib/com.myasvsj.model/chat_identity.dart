import 'dart:typed_data';

/// Khóa định danh đã mở khóa của người đăng nhập: id khóa trên server, khóa công khai và khóa bí mật P-256 (số d,
/// 32 byte). Chỉ nằm trong bộ nhớ của app, mất khi tắt app hoặc đăng xuất.
class ChatIdentity {
  const ChatIdentity({required this.keyId, required this.publicKey, required this.privateKey});

  final int keyId;

  /// base64 của điểm P-256 dạng raw 65 byte.
  final String publicKey;

  /// Số bí mật d (32 byte, big-endian).
  final Uint8List privateKey;
}
