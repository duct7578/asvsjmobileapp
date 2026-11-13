/// Người đang xem làm được gì trong một cuộc trò chuyện lúc này (Status của web).
///
/// JSON: `{state, canSend, notice: {code, text}, blockedByMe, peerReadUpTo, encryption: {mode, myKeyId, peerKeyId,
/// peerPublicKey, notice}, canAttach, canReact, peerTyping}`.
class ChatStatus {
  const ChatStatus({
    this.state,
    this.canSend = false,
    this.noticeCode,
    this.noticeText = '',
    this.blockedByMe = false,
    this.peerReadUpTo = 0,
    this.isEncrypted = false,
    this.myKeyId,
    this.peerKeyId,
    this.peerPublicKey,
    this.encryptionNoticeCode,
    this.encryptionNoticeText = '',
    this.canReact = false,
    this.peerTyping = false,
  });

  /// Trạng thái của chính người xem: ACCEPTED, REQUEST hoặc DECLINED; null trước tin đầu tiên.
  final String? state;

  /// Gửi được tin nhắn lúc này.
  final bool canSend;

  /// Điều cần biết trên ô soạn tin: NEW (tin đầu tiên thành lời mời), WAITING (lời mời chưa được nhận, còn gửi được
  /// vài tin), WAITING_FULL (hết lượt), REQUEST (người kia nhắn trước: chấp nhận, từ chối hoặc trả lời),
  /// BLOCKED_BY_ME, UNAVAILABLE, DELETED; null khi nhắn tự do.
  final String? noticeCode;

  /// Câu của server cho [noticeCode], ví dụ "Lan Anh chưa nhận lời mời nhắn tin của bạn. …".
  final String noticeText;

  /// Người xem đang chặn người kia.
  final bool blockedByMe;

  /// Tin mới nhất của người xem mà người kia đã đọc ("Đã xem"); 0 khi người kia chưa nhận lời.
  final int peerReadUpTo;

  /// Hội thoại đã mã hóa đầu cuối (`encryption.mode` = E2EE: cả hai đã nhận lời và đều bật mã hóa): server chỉ nhận
  /// tin mã hóa bằng đúng hai khóa [myKeyId], [peerKeyId].
  final bool isEncrypted;

  /// Khóa hiện tại của người xem trên server; null khi chưa bật mã hóa.
  final int? myKeyId;

  /// Khóa hiện tại của người kia; null khi họ chưa bật mã hóa (hoặc chưa có tin nào).
  final int? peerKeyId;

  /// base64 khóa công khai P-256 của [peerKeyId].
  final String? peerPublicKey;

  /// NO_KEY_ME (mình chưa bật mã hóa), NO_KEY_PEER (người kia chưa bật), REQUEST_PLAIN (lời mời chưa mã hóa), null.
  final String? encryptionNoticeCode;
  final String encryptionNoticeText;

  /// Cả hai đã nhận lời, không ai chặn: "đang soạn tin" và cảm xúc dùng được.
  final bool canReact;

  /// Người kia đang soạn tin.
  final bool peerTyping;

  /// Mã thông báo làm cuộc trò chuyện bị cắt: không gửi, không sửa được nữa.
  static const Set<String> cutOffCodes = {'UNAVAILABLE', 'DELETED', 'BLOCKED_BY_ME'};

  bool get isCutOff => cutOffCodes.contains(noticeCode);

  /// Người kia nhắn trước, người xem chưa trả lời: hiện Chấp nhận / Từ chối / Chặn.
  bool get isRequest => noticeCode == 'REQUEST';

  ChatStatus copyWith({bool? peerTyping}) => ChatStatus(
    state: state,
    canSend: canSend,
    noticeCode: noticeCode,
    noticeText: noticeText,
    blockedByMe: blockedByMe,
    peerReadUpTo: peerReadUpTo,
    isEncrypted: isEncrypted,
    myKeyId: myKeyId,
    peerKeyId: peerKeyId,
    peerPublicKey: peerPublicKey,
    encryptionNoticeCode: encryptionNoticeCode,
    encryptionNoticeText: encryptionNoticeText,
    canReact: canReact,
    peerTyping: peerTyping ?? this.peerTyping,
  );

  factory ChatStatus.fromJson(Map<String, dynamic> json) {
    final notice = json['notice'] as Map<String, dynamic>?;
    final encryption = json['encryption'] as Map<String, dynamic>?;
    final encryptionNotice = encryption?['notice'] as Map<String, dynamic>?;
    return ChatStatus(
      state: json['state'] as String?,
      canSend: (json['canSend'] ?? false) as bool,
      noticeCode: notice?['code'] as String?,
      noticeText: (notice?['text'] ?? '') as String,
      blockedByMe: (json['blockedByMe'] ?? false) as bool,
      peerReadUpTo: (json['peerReadUpTo'] ?? 0) as int,
      isEncrypted: encryption?['mode'] == 'E2EE',
      myKeyId: encryption?['myKeyId'] as int?,
      peerKeyId: encryption?['peerKeyId'] as int?,
      peerPublicKey: encryption?['peerPublicKey'] as String?,
      encryptionNoticeCode: encryptionNotice?['code'] as String?,
      encryptionNoticeText: (encryptionNotice?['text'] ?? '') as String,
      canReact: (json['canReact'] ?? false) as bool,
      peerTyping: (json['peerTyping'] ?? false) as bool,
    );
  }
}
