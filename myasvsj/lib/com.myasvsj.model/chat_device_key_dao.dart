import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:myasvsj/com.myasvsj.model/chat_identity.dart';

/// Khóa mã hóa đã mở, lưu an toàn trên điện thoại (như IndexedDB `asvsj-chat` của web) để mỗi lần mở app không phải
/// nhập lại mật khẩu khôi phục. Mỗi tài khoản một mục; dữ liệu nằm trong FlutterSecureStorage (Android: AES-GCM với
/// khóa trong Android Keystore; iOS: Keychain), không lên server, không vào bản sao lưu của Android
/// (`allowBackup="false"`).
///
/// Mục: `chat.identity.<userId>` = JSON `{keyId, publicKey, privateKey}` (privateKey là base64 của số d).
class ChatDeviceKeyDao {
  ChatDeviceKeyDao([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static String _key(int userId) => 'chat.identity.$userId';

  /// Khóa đã lưu của [userId]; null khi chưa lưu hoặc dữ liệu hỏng.
  Future<ChatIdentity?> find(int userId) async {
    final raw = await _storage.read(key: _key(userId));
    if (raw == null) {
      return null;
    }
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final privateKey = base64Decode(json['privateKey'] as String);
      if (privateKey.length != 32) {
        return null;
      }
      return ChatIdentity(
        keyId: json['keyId'] as int,
        publicKey: json['publicKey'] as String,
        privateKey: privateKey,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  /// Lưu (thay) khóa đã mở của [userId].
  Future<void> save(int userId, ChatIdentity identity) => _storage.write(
    key: _key(userId),
    value: jsonEncode({
      'keyId': identity.keyId,
      'publicKey': identity.publicKey,
      'privateKey': base64Encode(identity.privateKey),
    }),
  );

  /// Xóa khóa đã lưu của [userId] khỏi máy.
  Future<void> delete(int userId) => _storage.delete(key: _key(userId));
}
