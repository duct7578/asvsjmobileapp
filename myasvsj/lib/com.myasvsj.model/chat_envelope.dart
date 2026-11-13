/// Phong bì của một tin nhắn mã hóa đầu cuối, đúng như server lưu (Envelope của web): bản mã AES-GCM (kèm tag) của
/// `fk ‖ P`, hai khóa định danh đã dùng, và franking tag để người nhận chứng minh nội dung khi báo cáo.
///
/// JSON: `{ciphertext, iv, senderKeyId, recipientKeyId, frankingTag}` (base64 chuẩn có dấu `=`, tag là hex thường).
class ChatEnvelope {
  const ChatEnvelope({
    required this.ciphertext,
    required this.iv,
    required this.senderKeyId,
    required this.recipientKeyId,
    required this.frankingTag,
  });

  final String ciphertext;
  final String iv;
  final int senderKeyId;
  final int recipientKeyId;
  final String frankingTag;

  /// null khi JSON thiếu trường (tin hỏng thì hiện "Không đọc được tin nhắn này").
  static ChatEnvelope? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final ciphertext = json['ciphertext'];
    final iv = json['iv'];
    final sender = json['senderKeyId'];
    final recipient = json['recipientKeyId'];
    final tag = json['frankingTag'];
    if (ciphertext is! String || iv is! String || sender is! int || recipient is! int) {
      return null;
    }
    return ChatEnvelope(
      ciphertext: ciphertext,
      iv: iv,
      senderKeyId: sender,
      recipientKeyId: recipient,
      frankingTag: tag is String ? tag : '',
    );
  }

  Map<String, dynamic> toJson() => {
    'ciphertext': ciphertext,
    'iv': iv,
    'senderKeyId': senderKeyId,
    'recipientKeyId': recipientKeyId,
    'frankingTag': frankingTag,
  };
}
