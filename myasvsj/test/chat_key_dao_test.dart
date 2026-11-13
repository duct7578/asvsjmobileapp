// Test ChatKeyDao và phần mã hóa của ChatDao với server giả: đường dẫn, thân request và cách đọc JSON theo
// ChatController / ChatDtos của web (KeyBackup, MyKey, PublicKey, SendRequest.encrypted, ReportRequest).
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/chat_crypto.dart';
import 'package:myasvsj/com.myasvsj.model/chat_dao.dart';
import 'package:myasvsj/com.myasvsj.model/chat_envelope.dart';
import 'package:myasvsj/com.myasvsj.model/chat_key_dao.dart';
import 'package:myasvsj/com.myasvsj.model/chat_message.dart';
import 'package:myasvsj/com.myasvsj.model/chat_status.dart';

import 'fake_api.dart';

const _backup = {
  'id': 3,
  'publicKey': 'BAx=',
  'wrappedPrivateKey': 'd3JhcHBlZA==',
  'wrapSalt': 'c2FsdHNhbHRzYWx0c2FsdA==',
  'wrapIv': 'aXZpdml2aXZpdml2',
  'wrapIterations': 600000,
  'createdAt': '2026-11-10T01:00:00Z',
};

const _envelope = ChatEnvelope(ciphertext: 'q83v', iv: 'AAAA', senderKeyId: 3, recipientKeyId: 4, frankingTag: 'ab');

Map<String, dynamic> _message(int id) => {
  'id': id,
  'mine': true,
  'content': null,
  'encrypted': _envelope.toJson(),
  'replyToId': null,
  'edited': false,
  'recalled': false,
  'reactions': [],
  'fileIds': [],
  'createdAt': '2026-11-10T01:00:00Z',
};

void main() {
  group('ChatKeyDao', () {
    test('findMine đọc {key: KeyBackup}; chưa bật mã hóa thì {key: null}', () async {
      var key = <String, dynamic>{'key': _backup};
      final server = FakeServer({'GET /api/me/chats/keys/me': (_) => apiOk(key)});
      final dao = ChatKeyDao(server.api);
      final mine = await dao.findMine();
      expect(mine!.id, 3);
      expect(mine.wrapIterations, 600000);
      expect(mine.wrapSalt, 'c2FsdHNhbHRzYWx0c2FsdA==');
      key = {'key': null};
      expect(await dao.findMine(), isNull);
    });

    test('create gửi KeyRequest và đọc khóa vừa lưu; findPublicKey đọc {publicKey}; 404 thành ApiException', () async {
      final server = FakeServer({
        'POST /api/me/chats/keys': (_) => apiOk(_backup, message: 'OK'),
        'GET /api/me/chats/keys/4': (_) => apiOk({'id': 4, 'userId': 6, 'publicKey': 'BPeer=', 'revoked': false}),
        'GET /api/me/chats/keys/9': (_) =>
            FakeReply(404, {'success': false, 'message': 'Không tìm thấy khóa mã hóa này.', 'data': null}),
      });
      final dao = ChatKeyDao(server.api);
      final saved = await dao.create(
        ChatNewKey(
          publicKey: 'BAx=',
          wrappedPrivateKey: 'd3JhcHBlZA==',
          wrapSalt: 'c2FsdHNhbHRzYWx0c2FsdA==',
          wrapIv: 'aXZpdml2aXZpdml2',
          wrapIterations: 600000,
          privateKey: Uint8List(32),
        ),
      );
      expect(server.last('POST', '/api/me/chats/keys').data, {
        'publicKey': 'BAx=',
        'wrappedPrivateKey': 'd3JhcHBlZA==',
        'wrapSalt': 'c2FsdHNhbHRzYWx0c2FsdA==',
        'wrapIv': 'aXZpdml2aXZpdml2',
        'wrapIterations': 600000,
      }, reason: 'không bao giờ gửi khóa bí mật');
      expect(saved.id, 3);
      expect(await dao.findPublicKey(4), 'BPeer=');
      await expectLater(
        dao.findPublicKey(9),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });

  group('ChatDao: tin mã hóa', () {
    test('sendEncrypted gửi {encrypted: phong bì}; updateEncrypted gửi PUT {encrypted}', () async {
      final server = FakeServer({
        'POST /api/me/chats/3/messages': (_) => apiOk({
          'conversationId': 3,
          'message': _message(20),
          'status': {
            'state': 'ACCEPTED',
            'canSend': true,
            'encryption': {'mode': 'E2EE', 'myKeyId': 3, 'peerKeyId': 4, 'peerPublicKey': 'BPeer=', 'notice': null},
          },
        }, message: 'Đã gửi.'),
        'PUT /api/me/chats/3/messages/20': (_) => apiOk(_message(20), message: 'Đã sửa tin nhắn.'),
      });
      final dao = ChatDao(server.api);
      final sent = await dao.sendEncrypted(3, _envelope);
      expect(server.last('POST', '/api/me/chats/3/messages').data, {'encrypted': _envelope.toJson()});
      expect(sent.message.isEncrypted, isTrue);
      expect(sent.message.envelope!.recipientKeyId, 4);
      expect(sent.status.myKeyId, 3);
      expect(sent.status.peerPublicKey, 'BPeer=');

      final edited = await dao.updateEncrypted(3, 20, _envelope);
      expect(server.last('PUT', '/api/me/chats/3/messages/20').data, {'encrypted': _envelope.toJson()});
      expect(edited.message, 'Đã sửa tin nhắn.');
    });

    test('report tin mã hóa gửi kèm plaintext và frankingKey; tin thường thì không có hai trường đó', () async {
      final server = FakeServer({
        'POST /api/me/chats/messages/8/report': (_) => apiOk(null, message: 'Cảm ơn bạn. Báo cáo đã được gửi.'),
      });
      final dao = ChatDao(server.api);
      await dao.report(8, reasonId: 1, plaintext: 'UA==', frankingKey: 'Rks=');
      expect(server.last('POST', '/api/me/chats/messages/8/report').data, {
        'reasonId': 1,
        'note': null,
        'block': false,
        'plaintext': 'UA==',
        'frankingKey': 'Rks=',
      });
      await dao.report(8, reasonId: 2);
      expect(server.last('POST', '/api/me/chats/messages/8/report').data, {
        'reasonId': 2,
        'note': null,
        'block': false,
      });
    });

    test('đọc trạng thái mã hóa và thông báo NO_KEY_ME; tin mã hóa hỏng phong bì vẫn là tin mã hóa', () {
      final status = ChatStatus.fromJson({
        'state': 'ACCEPTED',
        'canSend': true,
        'encryption': {
          'mode': 'PLAIN',
          'myKeyId': null,
          'peerKeyId': 4,
          'peerPublicKey': 'BPeer=',
          'notice': {'code': 'NO_KEY_ME', 'text': 'Bạn chưa bật mã hóa đầu cuối.'},
        },
      });
      expect(status.isEncrypted, isFalse);
      expect(status.encryptionNoticeCode, 'NO_KEY_ME');
      expect(status.peerKeyId, 4);
      final broken = ChatMessage.fromJson({
        ..._message(5),
        'encrypted': {'iv': 'AAAA'},
      });
      expect(broken.isEncrypted, isTrue);
      expect(broken.envelope, isNull);
    });
  });
}
