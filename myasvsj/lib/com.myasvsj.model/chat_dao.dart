import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/chat_blocked_member.dart';
import 'package:myasvsj/com.myasvsj.model/chat_conversation.dart';
import 'package:myasvsj/com.myasvsj.model/chat_counts.dart';
import 'package:myasvsj/com.myasvsj.model/chat_envelope.dart';
import 'package:myasvsj/com.myasvsj.model/chat_message.dart';
import 'package:myasvsj/com.myasvsj.model/chat_sent.dart';
import 'package:myasvsj/com.myasvsj.model/chat_updates.dart';
import 'package:myasvsj/com.myasvsj.model/conversation_page.dart';

/// Truy cập "Tin nhắn" giữa hai thành viên (bảng `chat_conversations`, `chat_messages`, `chat_blocks`) qua REST API
/// của web. Chỉ thành viên (role USER) đã đăng nhập; khách nhận 401, staff nhận 403. Hội thoại đã mã hóa đầu cuối chỉ
/// nhận tin mã hóa ([sendEncrypted], [updateEncrypted]; tin thường bị 400), mã hóa bằng hai khóa hiện tại (409 khi
/// một khóa vừa đổi).
///
/// Khóa mã hóa (keys/me, keys) ở ChatKeyDao.
///
/// | Hàm         | API                                                       |
/// |-------------|-----------------------------------------------------------|
/// | findAll     | GET /api/me/chats?box=INBOX\|REQUESTS&page=               |
/// | findCounts  | GET /api/me/chats/counts                                  |
/// | findById    | GET /api/me/chats/{id}                                    |
/// | findWith    | GET /api/me/chats/with/{userId}                           |
/// | findOlder   | GET /api/me/chats/{id}/messages?before=&limit=            |
/// | findUpdates | GET /api/me/chats/{id}/updates?after=&changedSince=       |
/// | send        | POST /api/me/chats/{id}/messages {content}                |
/// | sendTo      | POST /api/me/chats/with/{userId}/messages {content}       |
/// | sendEncrypted   | POST /api/me/chats/{id}/messages {encrypted}          |
/// | update      | PUT /api/me/chats/{id}/messages/{messageId} {content}     |
/// | updateEncrypted | PUT /api/me/chats/{id}/messages/{messageId} {encrypted} |
/// | recall      | DELETE /api/me/chats/{id}/messages/{messageId}            |
/// | markRead    | POST /api/me/chats/{id}/read {upToId}                     |
/// | typing      | POST /api/me/chats/{id}/typing                            |
/// | accept      | POST /api/me/chats/{id}/accept                            |
/// | decline     | POST /api/me/chats/{id}/decline                           |
/// | delete      | DELETE /api/me/chats/{id}                                 |
/// | report      | POST /api/me/chats/messages/{messageId}/report            |
/// | findBlocks  | GET /api/me/chats/blocks                                  |
/// | block       | POST /api/me/chats/blocks/{userId}                        |
/// | unblock     | DELETE /api/me/chats/blocks/{userId}                      |
class ChatDao {
  ChatDao(this._api);

  final ApiClient _api;

  /// Hộp thư "Tin nhắn" (cuộc trò chuyện đã nhận lời) và "Lời mời".
  static const String inbox = 'INBOX';
  static const String requests = 'REQUESTS';

  static const String _base = '/api/me/chats';

  // ---------------------------------------------------------------- Read

  /// Một trang cuộc trò chuyện của hộp [box] (trang đầu là 0), tin mới nhất trước, kèm các con số.
  Future<ConversationPage> findAll({String box = inbox, int page = 0}) async =>
      ConversationPage.fromJson(await _api.get(_base, query: {'box': box, 'page': page}) as Map<String, dynamic>);

  /// Số cuộc trò chuyện có tin chưa đọc, số lời mời, tin chưa đọc mới nhất.
  Future<ChatCounts> findCounts() async => ChatCounts.fromJson(await _api.get('$_base/counts') as Map<String, dynamic>);

  /// Một cuộc trò chuyện với 30 tin mới nhất. Không phải của mình: 404 "Không tìm thấy cuộc trò chuyện này.".
  Future<ChatConversation> findById(int id) async =>
      ChatConversation.fromJson(await _api.get('$_base/$id') as Map<String, dynamic>);

  /// Cuộc trò chuyện với thành viên [userId] (bấm "Nhắn tin" cạnh tên họ); `id` null khi chưa từng nhắn.
  Future<ChatConversation> findWith(int userId) async =>
      ChatConversation.fromJson(await _api.get('$_base/with/$userId') as Map<String, dynamic>);

  /// "Xem tin cũ hơn": tối đa [limit] tin trước tin [before] (null: mới nhất), cũ trước.
  Future<({List<ChatMessage> messages, bool hasOlder})> findOlder(int id, {int? before, int? limit}) async {
    final data =
        await _api.get('$_base/$id/messages', query: {'before': ?before, 'limit': ?limit}) as Map<String, dynamic>;
    return (messages: ChatMessage.listFrom(data['messages']), hasOlder: (data['hasOlder'] ?? false) as bool);
  }

  /// Tin sau tin [after], tin đã sửa / thu hồi từ [changedSince] (giờ server của lần hỏi trước) và trạng thái mới.
  Future<ChatUpdates> findUpdates(int id, {int after = 0, String? changedSince}) async => ChatUpdates.fromJson(
    await _api.get('$_base/$id/updates', query: {'after': after, 'changedSince': ?changedSince})
        as Map<String, dynamic>,
  );

  // ---------------------------------------------------------------- Create

  /// Gửi tin văn bản vào cuộc trò chuyện [conversationId].
  Future<ChatSent> send(int conversationId, String content) async => ChatSent.fromJson(
    (await _api.post('$_base/$conversationId/messages', {'content': content})).data as Map<String, dynamic>,
  );

  /// Gửi tin cho thành viên [userId]; tin đầu tiên tạo cuộc trò chuyện (thành lời mời).
  Future<ChatSent> sendTo(int userId, String content) async => ChatSent.fromJson(
    (await _api.post('$_base/with/$userId/messages', {'content': content})).data as Map<String, dynamic>,
  );

  /// Gửi tin mã hóa đầu cuối (phong bì [encrypted]) vào cuộc trò chuyện [conversationId].
  Future<ChatSent> sendEncrypted(int conversationId, ChatEnvelope encrypted) async => ChatSent.fromJson(
    (await _api.post('$_base/$conversationId/messages', {'encrypted': encrypted.toJson()})).data
        as Map<String, dynamic>,
  );

  // ---------------------------------------------------------------- Update

  /// Sửa tin của mình (trong 15 phút, tối đa 5 lần); trả về tin đã sửa và câu "Đã sửa tin nhắn.".
  Future<({String message, ChatMessage chatMessage})> update(int conversationId, int messageId, String content) async {
    final response = await _api.put('$_base/$conversationId/messages/$messageId', {'content': content});
    return (message: response.message, chatMessage: ChatMessage.fromJson(response.data as Map<String, dynamic>));
  }

  /// Sửa tin mã hóa của mình bằng phong bì mới [encrypted].
  Future<({String message, ChatMessage chatMessage})> updateEncrypted(
    int conversationId,
    int messageId,
    ChatEnvelope encrypted,
  ) async {
    final response = await _api.put('$_base/$conversationId/messages/$messageId', {'encrypted': encrypted.toJson()});
    return (message: response.message, chatMessage: ChatMessage.fromJson(response.data as Map<String, dynamic>));
  }

  /// "Thu hồi" tin của mình cho cả hai người; trả về tin đã thu hồi và câu "Đã thu hồi tin nhắn.".
  Future<({String message, ChatMessage chatMessage})> recall(int conversationId, int messageId) async {
    final response = await _api.delete('$_base/$conversationId/messages/$messageId');
    return (message: response.message, chatMessage: ChatMessage.fromJson(response.data as Map<String, dynamic>));
  }

  /// Đã đọc tới tin [upToId] (null: hết); trả về các con số còn lại.
  Future<ChatCounts> markRead(int conversationId, {int? upToId}) async {
    final response = await _api.post('$_base/$conversationId/read', {'upToId': upToId});
    return response.data is Map<String, dynamic>
        ? ChatCounts.fromJson(response.data as Map<String, dynamic>)
        : const ChatCounts();
  }

  /// Báo "đang soạn tin" cho người kia (server giữ 6 giây).
  Future<void> typing(int conversationId) async => _api.post('$_base/$conversationId/typing');

  /// "Chấp nhận" lời mời; trả về "Đã chấp nhận lời mời nhắn tin.".
  Future<String> accept(int conversationId) async => (await _api.post('$_base/$conversationId/accept')).message;

  /// "Từ chối" lời mời (người gửi không được báo); trả về "Đã từ chối lời mời nhắn tin.".
  Future<String> decline(int conversationId) async => (await _api.post('$_base/$conversationId/decline')).message;

  /// Báo cáo tin nhắn nhận được; [block] chặn luôn người gửi. Tin mã hóa gửi kèm nội dung đã giải mã [plaintext] và
  /// [frankingKey] (base64) để server kiểm franking tag. Trả về "Cảm ơn bạn. Báo cáo đã được gửi.".
  Future<String> report(
    int messageId, {
    required int reasonId,
    String note = '',
    bool block = false,
    String? plaintext,
    String? frankingKey,
  }) async => (await _api.post('$_base/messages/$messageId/report', {
    'reasonId': reasonId,
    'note': note.isEmpty ? null : note,
    'block': block,
    'plaintext': ?plaintext,
    'frankingKey': ?frankingKey,
  })).message;

  // ---------------------------------------------------------------- Delete

  /// "Xóa cuộc trò chuyện" ở phía mình (người kia vẫn giữ); xóa một lời mời là từ chối nó.
  /// Trả về "Đã xóa cuộc trò chuyện.".
  Future<String> delete(int conversationId) async => (await _api.delete('$_base/$conversationId')).message;

  // ---------------------------------------------------------------- Chặn

  /// "Người đã chặn", mới nhất trước.
  Future<List<ChatBlockedMember>> findBlocks() async => [
    for (final item in (await _api.get('$_base/blocks') as List?) ?? const [])
      ChatBlockedMember.fromJson(item as Map<String, dynamic>),
  ];

  /// Chặn [userId]: hai người không nhắn được cho nhau. Trả về "Đã chặn. Hai bạn không nhắn tin được cho nhau nữa.".
  Future<String> block(int userId) async => (await _api.post('$_base/blocks/$userId')).message;

  /// Bỏ chặn; trả về "Đã bỏ chặn.".
  Future<String> unblock(int userId) async => (await _api.delete('$_base/blocks/$userId')).message;
}
