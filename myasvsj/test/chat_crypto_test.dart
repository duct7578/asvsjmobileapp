import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/chat_crypto.dart';
import 'package:myasvsj/com.myasvsj.model/chat_envelope.dart';
import 'package:myasvsj/com.myasvsj.model/chat_key_backup.dart';

// Dữ liệu do chat-crypto.js của web tạo (Node + WebCrypto): bản sao lưu khóa của A (100.000 vòng, mật khẩu gõ dạng
// tổ hợp NFD), khóa công khai của B, một tin A gửi B và một tin B gửi A (có kèm ảnh), và một PBKDF2 600.000 vòng.
// App phải mở, giải mã và tính ra đúng như web thì hai bên mới đọc được tin của nhau.
const _webVectors = r'''
{
  "passphrase": "Mật khẩu ở nhà 2026",
  "backupA": {
    "id": 11,
    "publicKey": "BLsVjxl5BFESJ718hjGLNaABoGjMdeVt0cOvojf+0inbLJNqUSVO/YqoIIAAayw1j51m8JRMDcwgDJn2ohTp22M=",
    "wrappedPrivateKey": "Q92STc37eBp/Y9Zo/fRJ4VMKc+7ebeyEJguIHJ6Jv3BpK5rQ2/IyvtxyJ9CIBZivSXaUVTLyoVCLAoDhAGQy9T4jYWhV1dvaIHSI9aGUS/N+XDlpoO07TKtbcHQ2wsslpbR2VONz+kMPhb00LCiVEHPoBhG4NVudW7buunK6rkFUFvMwO+DsEHpAQUP4lPwToB0kvIatnevapw==",
    "wrapSalt": "PUy6WtNiPhwP8YCykkqs6A==",
    "wrapIv": "gmYiCkslmJQlwHtc",
    "wrapIterations": 100000
  },
  "publicKeyB": "BPhb6WGWvtrkpalnLZFOILtpMv+d9TzIRrLGY4alMXtd7Fb8PCs9KcUpVwwP7MYx9NKh9C7Pnzo3h1mBU6qFa1Q=",
  "conversationId": 42,
  "userA": 7,
  "userB": 9,
  "keyA": 11,
  "keyB": 12,
  "fromA": {
    "envelope": {
      "ciphertext": "AlnysGGEg8Vay7MPOFQhDsY9MnX/E0rGR1KiZTAAsDXbkOkqZ1c6H7YlF3tm7uFSrDQaw2e4YHyv7+7anYfyuMMoxfcjgd9et2s+6F+Nvf47p/kTn55uliK+6TjUSEOM1P5DsTgYrsb+hGgma+oegDs=",
      "iv": "H65mZKSgn4fDp28Y",
      "senderKeyId": 11,
      "recipientKeyId": 12,
      "frankingTag": "60dd2454f8efe8211852c9e112ad06fd434952f1eb13af01d17291bb3cace534"
    },
    "frankingKey": "0GMdrgytRlUDLB4dlfokdj/CCjnuFdGP/X4dJlmtcuw=",
    "plaintext": "eyJ2IjoxLCJ0ZXh0IjoiQ2jDoG8gZW0sIG1haSA5aCBn4bq3cCDhu58gZ2EgU2hpbmp1a3UgbmjDqSDwn5qJIn0="
  },
  "fromB": {
    "envelope": {
      "ciphertext": "s79UT7l3O7RCdUw3tO1cys3PJF0emRDqShEiy8WVGNmE8XW3vqA6MlghcgN+dZCp1J4DANmY7H+R5LTJkxYb4Cw6qp8p1zssRU1bXu4vbg4uMeEi9AHo3unzWwtU+sLPHQDw/EsoqXrrJ9VqACS24b7CHJkR+A3aPUSiBdbXttHpecEXiTp/oJK28h6GJNzAvYbrJ+Sgj+4wMLdbfXCRyQtUymvAFZX8IMns6ucxXioMoVHG1U4Mp4x+k4dczi+fl6XefNnaOt6uczBr1aMUD0uv/p3ajdK4uhc/p/q9DXVZ+FbER3Tq2QaCBCLrhQ==",
      "iv": "6Lpr7ysk/pScYCmS",
      "senderKeyId": 12,
      "recipientKeyId": 11,
      "frankingTag": "03ead5fcb8fe39798b116cbbd698807e88fbf88d5557df1c5a707fbccaa8bd14"
    },
    "frankingKey": "VHZslyBWl2yo7l1V84wNphYHdoN71TBHNJRLXTSM27c=",
    "plaintext": "eyJ2IjoxLCJ0ZXh0IjoiROG6oSB2w6JuZyDhuqEiLCJmaWxlcyI6W3siaWQiOjUsImtpbmQiOiJJTUFHRSIsIm1pbWUiOiJpbWFnZS9qcGVnIiwic2l6ZSI6MTIzNCwia2V5IjoiQVFFQkFRRUJBUUVCQVFFQkFRRUJBUUVCQVFFQkFRRUJBUUVCQVFFQkFRRT0iLCJpdiI6IkFnSUNBZ0lDQWdJQ0FnSUMiLCJ3Ijo2NDAsImgiOjQ4MH1dfQ=="
  },
  "pbkdf2": {
    "password": "password-123",
    "salt": "AAECAwQFBgcICQoLDA0ODw==",
    "iterations": 600000,
    "out": "T7CzzZ6OV14cgyOgMSAzWWY0yCPGN1pYnFG5GzZxyrg="
  }
}
''';

void main() {
  final v = jsonDecode(_webVectors) as Map<String, dynamic>;
  final crypto = ChatCrypto.inline();
  final backupA = ChatKeyBackup.fromJson(v['backupA'] as Map<String, dynamic>);
  final conv = v['conversationId'] as int;
  final userA = v['userA'] as int;
  final userB = v['userB'] as int;
  final keyA = v['keyA'] as int;
  final keyB = v['keyB'] as int;
  final publicB = v['publicKeyB'] as String;

  ChatEnvelope envelopeOf(String name) => ChatEnvelope.tryParse((v[name] as Map)['envelope'])!;

  group('khớp với chat-crypto.js của web', () {
    test('PBKDF2-SHA256 600.000 vòng ra đúng như WebCrypto', () {
      final pb = v['pbkdf2'] as Map<String, dynamic>;
      final out = ChatCrypto.pbkdf2Sha256(
        Uint8List.fromList(utf8.encode(pb['password'] as String)),
        base64Decode(pb['salt'] as String),
        pb['iterations'] as int,
      );
      expect(base64Encode(out), pb['out']);
    });

    test('mở bản sao lưu của web bằng mật khẩu (chuẩn hóa NFC), giải mã tin hai chiều', () async {
      final identity = await crypto.unlock(backupA, v['passphrase'] as String);
      expect(identity.keyId, keyA);
      expect(identity.publicKey, backupA.publicKey);
      final key = await crypto.conversationKey(identity.privateKey, publicB, conv, keyA, keyB);

      final mine = crypto.decrypt(key: key, conversationId: conv, senderId: userA, envelope: envelopeOf('fromA'));
      expect(mine.body.text, 'Chào em, mai 9h gặp ở ga Shinjuku nhé 🚉');
      expect(mine.body.files, isEmpty);
      expect(mine.frankingKey, (v['fromA'] as Map)['frankingKey']);
      expect(mine.plaintext, (v['fromA'] as Map)['plaintext']);

      final theirs = crypto.decrypt(key: key, conversationId: conv, senderId: userB, envelope: envelopeOf('fromB'));
      expect(theirs.body.text, 'Dạ vâng ạ');
      expect(theirs.body.files.single['kind'], 'IMAGE');
      expect(theirs.body.files.single['w'], 640);
      expect(theirs.plaintext, (v['fromB'] as Map)['plaintext']);
    });

    test('sai mật khẩu khôi phục: WrongPassphraseException', () async {
      await expectLater(crypto.unlock(backupA, 'mat khau sai'), throwsA(isA<WrongPassphraseException>()));
    });

    test('tin bị đổi người gửi, đổi bản mã hay sai khóa thì không đọc được', () async {
      final identity = await crypto.unlock(backupA, v['passphrase'] as String);
      final key = await crypto.conversationKey(identity.privateKey, publicB, conv, keyA, keyB);
      final env = envelopeOf('fromB');
      // Sai người gửi (AAD)
      expect(
        () => crypto.decrypt(key: key, conversationId: conv, senderId: userA, envelope: env),
        throwsA(isA<UnreadableMessageException>()),
      );
      // Sai cuộc trò chuyện: khóa khác
      final other = await crypto.conversationKey(identity.privateKey, publicB, conv + 1, keyA, keyB);
      expect(
        () => crypto.decrypt(key: other, conversationId: conv, senderId: userB, envelope: env),
        throwsA(isA<UnreadableMessageException>()),
      );
      // Franking tag của nội dung khác
      final forged = ChatEnvelope(
        ciphertext: env.ciphertext,
        iv: env.iv,
        senderKeyId: env.senderKeyId,
        recipientKeyId: env.recipientKeyId,
        frankingTag: '00${env.frankingTag.substring(2)}',
      );
      expect(
        () => crypto.decrypt(key: key, conversationId: conv, senderId: userB, envelope: forged),
        throwsA(isA<UnreadableMessageException>()),
      );
    });
  });

  group('app tự tạo khóa và mã hóa', () {
    test('khóa mới mở lại được bằng chính mật khẩu, tin mã hóa giải mã lại được', () async {
      final made = await crypto.createKey('mật khẩu mới 123', iterations: 100000);
      expect(base64Decode(made.publicKey), hasLength(65));
      final backup = ChatKeyBackup(
        id: 30,
        publicKey: made.publicKey,
        wrappedPrivateKey: made.wrappedPrivateKey,
        wrapSalt: made.wrapSalt,
        wrapIv: made.wrapIv,
        wrapIterations: made.wrapIterations,
      );
      final again = await crypto.unlock(backup, 'mật khẩu mới 123');
      expect(again.privateKey, made.privateKey);

      // Gửi cho A của web: A (khóa từ bản sao lưu của web) đọc được
      final key = await crypto.conversationKey(made.privateKey, backupA.publicKey, conv, 30, keyA);
      final sealed = crypto.encrypt(
        key: key,
        conversationId: conv,
        senderId: userB,
        senderKeyId: 30,
        recipientKeyId: keyA,
        body: const ChatBody(text: 'Xin chào từ app'),
      );
      final identityA = await crypto.unlock(backupA, v['passphrase'] as String);
      final keyOfA = await crypto.conversationKey(identityA.privateKey, made.publicKey, conv, keyA, 30);
      final opened = crypto.decrypt(key: keyOfA, conversationId: conv, senderId: userB, envelope: sealed.envelope);
      expect(opened.body.text, 'Xin chào từ app');
      expect(opened.frankingKey, sealed.frankingKey);
    });

    test('mật khẩu khôi phục ngắn hơn 8 ký tự bị từ chối', () {
      expect(ChatCrypto.checkNewPassphrase('1234567'), isNotNull);
      expect(ChatCrypto.checkNewPassphrase('12345678'), isNull);
      expect(() => crypto.createKey('ngắn'), throwsA(isA<ChatCryptoException>()));
    });

    test('tin rỗng không mã hóa được, khóa công khai ngoài đường cong bị từ chối', () async {
      final identity = await crypto.unlock(backupA, v['passphrase'] as String);
      final key = await crypto.conversationKey(identity.privateKey, publicB, conv, keyA, keyB);
      expect(
        () => crypto.encrypt(
          key: key,
          conversationId: conv,
          senderId: userA,
          senderKeyId: keyA,
          recipientKeyId: keyB,
          body: const ChatBody(text: ''),
        ),
        throwsA(isA<ChatCryptoException>()),
      );
      final bad = base64Decode(publicB)..[64] ^= 1;
      await expectLater(
        crypto.conversationKey(identity.privateKey, base64Encode(bad), conv, keyA, keyB),
        throwsA(isA<ChatCryptoException>()),
      );
    });
  });
}
