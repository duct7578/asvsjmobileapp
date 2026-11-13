import 'package:myasvsj/com.myasvsj.model/chat_envelope.dart';

/// Một tin nhắn, ứng với một dòng của bảng `chat_messages` (Message của web).
///
/// JSON: `{id, mine, content, encrypted, replyToId, edited, recalled, reactions: [{emoji, count, mine}], fileIds,
/// createdAt}`.
///
/// Tin mã hóa đầu cuối đến từ server với [content] null và [envelope] khác null; ChatController giải mã rồi đưa
/// màn hình bản sao có [content] là chữ đã giải mã ([decrypted]), hoặc [lockedText] khi chưa đọc được.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.mine,
    this.content,
    this.isEncrypted = false,
    this.envelope,
    this.replyToId,
    this.edited = false,
    this.recalled = false,
    this.reactions = const [],
    this.hasFiles = false,
    this.fileIds = const [],
    this.decrypted = false,
    this.lockedText,
    required this.createdAt,
  });

  final int id;

  /// Tin do người đang xem gửi.
  final bool mine;

  /// Chữ của tin thường, hoặc chữ đã giải mã của tin mã hóa ([decrypted]); null khi tin mã hóa chưa đọc được hoặc
  /// đã thu hồi.
  final String? content;

  /// Tin mã hóa đầu cuối: chỉ người có khóa (mở bằng mật khẩu khôi phục) đọc được.
  final bool isEncrypted;

  /// Phong bì của tin mã hóa như server lưu; null với tin thường.
  final ChatEnvelope? envelope;

  /// Tin được trả lời (trích dẫn), nếu có.
  final int? replyToId;

  final bool edited;

  /// "Tin nhắn đã được thu hồi": không còn chữ, cảm xúc, tệp.
  final bool recalled;

  /// Cảm xúc của tin (👍 ❤️ 😂 😮 😢 🙏): số người chọn, người đang xem có chọn không.
  final List<({String emoji, int count, bool mine})> reactions;

  /// Có ảnh, video hoặc ghi âm kèm theo (chỉ có trong hội thoại mã hóa).
  final bool hasFiles;

  /// id các tệp đính kèm (server chỉ trả những tệp thật sự gắn với tin).
  final List<int> fileIds;

  /// Bản sao đã giải mã: [content] là chữ trong tin (rỗng khi tin chỉ có tệp).
  final bool decrypted;

  /// Câu hiện thay chữ khi tin mã hóa chưa đọc được ("Đang giải mã…", "Nhập mật khẩu khôi phục để đọc."…).
  final String? lockedText;

  final DateTime createdAt;

  /// Bản sao của tin mã hóa đã giải mã ra [text].
  ChatMessage withDecrypted(String text) => _copy(content: text, decrypted: true, lockedText: null);

  /// Bản sao của tin mã hóa chưa đọc được, hiện câu [text].
  ChatMessage withLocked(String text) => _copy(content: null, decrypted: false, lockedText: text);

  ChatMessage _copy({required String? content, required bool decrypted, required String? lockedText}) => ChatMessage(
    id: id,
    mine: mine,
    content: content,
    isEncrypted: isEncrypted,
    envelope: envelope,
    replyToId: replyToId,
    edited: edited,
    recalled: recalled,
    reactions: reactions,
    hasFiles: hasFiles,
    fileIds: fileIds,
    decrypted: decrypted,
    lockedText: lockedText,
    createdAt: createdAt,
  );

  /// Tin như server trả về sau khi sửa / thu hồi thay cho tin cũ cùng id.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final created = json['createdAt'];
    final fileIds = [
      for (final f in (json['fileIds'] as List?) ?? const [])
        if (f is int) f,
    ];
    return ChatMessage(
      id: json['id'] as int,
      mine: (json['mine'] ?? false) as bool,
      content: json['content'] as String?,
      isEncrypted: json['encrypted'] is Map,
      envelope: ChatEnvelope.tryParse(json['encrypted']),
      replyToId: json['replyToId'] as int?,
      edited: (json['edited'] ?? false) as bool,
      recalled: (json['recalled'] ?? false) as bool,
      reactions: [
        for (final r in (json['reactions'] as List?) ?? const [])
          if (r is Map<String, dynamic>)
            (emoji: (r['emoji'] ?? '') as String, count: (r['count'] ?? 0) as int, mine: (r['mine'] ?? false) as bool),
      ],
      hasFiles: fileIds.isNotEmpty,
      fileIds: fileIds,
      createdAt: (created is String ? DateTime.tryParse(created)?.toLocal() : null) ?? DateTime.now(),
    );
  }

  static List<ChatMessage> listFrom(Object? json) => [
    for (final item in (json as List?) ?? const []) ChatMessage.fromJson(item as Map<String, dynamic>),
  ];
}
