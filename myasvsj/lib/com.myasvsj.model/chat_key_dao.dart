import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/chat_crypto.dart';
import 'package:myasvsj/com.myasvsj.model/chat_key_backup.dart';

/// Khóa mã hóa đầu cuối của "Tin nhắn" (bảng `chat_keys`) qua REST API của web. Server chỉ giữ khóa công khai và bản
/// sao lưu khóa bí mật đã khóa bằng mật khẩu khôi phục; mở khóa và mã hóa đều làm trong app ([ChatCrypto]).
///
/// | Hàm           | API                                  |
/// |---------------|--------------------------------------|
/// | findMine      | GET /api/me/chats/keys/me            |
/// | create        | POST /api/me/chats/keys              |
/// | findPublicKey | GET /api/me/chats/keys/{keyId}       |
class ChatKeyDao {
  ChatKeyDao(this._api);

  final ApiClient _api;

  static const String _base = '/api/me/chats/keys';

  /// Khóa hiện tại của mình kèm bản sao lưu; null khi chưa bật mã hóa.
  Future<ChatKeyBackup?> findMine() async {
    final data = await _api.get('$_base/me') as Map<String, dynamic>?;
    final key = data?['key'];
    return key is Map<String, dynamic> ? ChatKeyBackup.fromJson(key) : null;
  }

  /// Khóa mới thay khóa hiện tại (khóa cũ bị thu hồi, tin cũ vẫn ghi id của nó). Tối đa 5 khóa mỗi ngày (429).
  Future<ChatKeyBackup> create(ChatNewKey key) async =>
      ChatKeyBackup.fromJson((await _api.post(_base, key.toRequestJson())).data as Map<String, dynamic>);

  /// Khóa công khai [keyId] của mình hoặc của người cùng cuộc trò chuyện (cả khóa đã thu hồi); người khác 404.
  Future<String> findPublicKey(int keyId) async =>
      ((await _api.get('$_base/$keyId')) as Map<String, dynamic>)['publicKey'] as String;
}
