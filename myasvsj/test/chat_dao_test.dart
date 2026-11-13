// Test ChatDao với server giả: JSON chép từ server thật (curl http://localhost:8080/api/me/chats…, cuộc trò chuyện
// user@gmail.com ↔ mentor@gmail.com và lời mời của một tài khoản lạ).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/chat_dao.dart';

import 'fake_api.dart';

/// GET /api/me/chats (user@gmail.com): tin cuối đã thu hồi.
const _inboxJson = r'''
{"success":true,"message":"OK","data":{"items":[{"id":1,"peer":{"id":6,"displayName":"Lan Anh","avatarUrl":null,"tags":[{"name":"Mentor","color":"#C2456E"}],"active":true},"state":"ACCEPTED","lastMessage":{"id":6,"mine":true,"content":null,"encrypted":null,"replyToId":null,"edited":false,"recalled":true,"reactions":[],"fileIds":[],"createdAt":"2026-11-07T18:54:34Z"},"unread":0,"blockedByMe":false}],"hasMore":false,"counts":{"unread":0,"requests":0,"latest":null}},"timestamp":"2026-11-07T18:54:33.956442200Z"}
''';

/// GET /api/me/chats?box=REQUESTS (user@gmail.com): lời mời của người lạ.
const _requestsJson = r'''
{"success":true,"message":"OK","data":{"items":[{"id":2,"peer":{"id":9,"displayName":"Chat Stranger","avatarUrl":null,"tags":[],"active":true},"state":"REQUEST","lastMessage":{"id":4,"mine":false,"content":"Xin chao, tin nhan thu 3 cua nguoi la.","encrypted":null,"replyToId":null,"edited":false,"recalled":false,"reactions":[],"fileIds":[],"createdAt":"2026-11-07T18:53:55Z"},"unread":3,"blockedByMe":false}],"hasMore":false,"counts":{"unread":1,"requests":1,"latest":{"conversationId":2,"messageId":4,"peerName":"Chat Stranger","request":true,"createdAt":"2026-11-07T18:53:55Z"}}},"timestamp":"2026-11-07T18:54:01.275237700Z"}
''';

/// GET /api/me/chats/counts.
const _countsJson = r'''
{"success":true,"message":"OK","data":{"unread":1,"requests":1,"latest":{"conversationId":1,"messageId":1,"peerName":"Trần Minh","request":true,"createdAt":"2026-11-07T18:53:06Z"}},"timestamp":"2026-11-07T18:53:15.749013400Z"}
''';

/// GET /api/me/chats/1 (mentor@gmail.com, trước khi nhận lời).
const _conversationJson = r'''
{"success":true,"message":"OK","data":{"id":1,"peer":{"id":2,"displayName":"Trần Minh","avatarUrl":null,"tags":[],"active":true},"status":{"state":"REQUEST","canSend":true,"notice":{"code":"REQUEST","text":"Trần Minh muốn nhắn tin với bạn. Bạn có thể chấp nhận, trả lời hoặc từ chối; Trần Minh chưa biết bạn đã đọc tin cho đến khi bạn chấp nhận."},"blockedByMe":false,"peerReadUpTo":1,"encryption":{"mode":"PLAIN","myKeyId":null,"peerKeyId":null,"peerPublicKey":null,"notice":{"code":"REQUEST_PLAIN","text":"Lời mời nhắn tin chưa được mã hóa và chỉ gửi được chữ. Khi hai bạn đã nhận lời và cùng bật mã hóa, tin nhắn sẽ được mã hóa đầu cuối."}},"canAttach":false,"canReact":false,"peerTyping":false},"messages":[{"id":1,"mine":false,"content":"Chào chị, em là Minh. Em muốn hỏi về thuê nhà ở Tokyo ạ.","encrypted":null,"replyToId":null,"edited":false,"recalled":false,"reactions":[],"fileIds":[],"createdAt":"2026-11-07T18:53:06Z"}],"hasOlder":false,"reportReasons":[{"id":1,"label":"Lừa đảo"},{"id":2,"label":"Sai sự thật"},{"id":3,"label":"Xúc phạm"},{"id":4,"label":"Spam"}],"limits":{"messageMax":2000,"pendingMax":3,"editMinutes":15,"filesMax":5,"imageMaxBytes":10485760,"videoMaxBytes":52428800,"audioMaxBytes":5242880,"videoMaxSeconds":30,"audioMaxSeconds":120,"reactions":["👍","❤️","😂","😮","😢","🙏"]},"serverTime":"2026-11-07T18:53:15.777Z"},"timestamp":"2026-11-07T18:53:15.781226900Z"}
''';

/// GET /api/me/chats/with/6 (user@gmail.com, trước tin đầu tiên): chưa có id.
const _withJson = r'''
{"success":true,"message":"OK","data":{"id":null,"peer":{"id":6,"displayName":"Lan Anh","avatarUrl":null,"tags":[{"name":"Mentor","color":"#C2456E"}],"active":true},"status":{"state":null,"canSend":true,"notice":{"code":"NEW","text":"Tin nhắn đầu tiên sẽ đến Lan Anh dưới dạng lời mời. Trước khi Lan Anh trả lời, bạn gửi được tối đa 3 tin nhắn."},"blockedByMe":false,"peerReadUpTo":0,"encryption":{"mode":"PLAIN","myKeyId":null,"peerKeyId":null,"peerPublicKey":null,"notice":{"code":"REQUEST_PLAIN","text":"Lời mời nhắn tin chưa được mã hóa và chỉ gửi được chữ. Khi hai bạn đã nhận lời và cùng bật mã hóa, tin nhắn sẽ được mã hóa đầu cuối."}},"canAttach":false,"canReact":false,"peerTyping":false},"messages":[],"hasOlder":false,"reportReasons":[{"id":1,"label":"Lừa đảo"},{"id":2,"label":"Sai sự thật"},{"id":3,"label":"Xúc phạm"},{"id":4,"label":"Spam"}],"limits":{"messageMax":2000,"pendingMax":3,"editMinutes":15,"filesMax":5,"imageMaxBytes":10485760,"videoMaxBytes":52428800,"audioMaxBytes":5242880,"videoMaxSeconds":30,"audioMaxSeconds":120,"reactions":["👍","❤️","😂","😮","😢","🙏"]},"serverTime":"2026-11-07T18:52:57.857Z"},"timestamp":"2026-11-07T18:52:57.857129500Z"}
''';

/// Hội thoại đã mã hóa đầu cuối: dựng theo ChatDtos (Encryption mode E2EE, Envelope) vì database test chưa ai bật.
const _e2eeJson = r'''
{"success":true,"message":"OK","data":{"id":3,"peer":{"id":6,"displayName":"Lan Anh","avatarUrl":"/media/avatar/6.jpg","tags":[],"active":true},"status":{"state":"ACCEPTED","canSend":true,"notice":null,"blockedByMe":false,"peerReadUpTo":8,"encryption":{"mode":"E2EE","myKeyId":3,"peerKeyId":4,"peerPublicKey":"BAx","notice":null},"canAttach":true,"canReact":true,"peerTyping":true},"messages":[{"id":7,"mine":true,"content":"Tin cũ trước khi mã hóa","encrypted":null,"replyToId":null,"edited":true,"recalled":false,"reactions":[{"emoji":"❤️","count":1,"mine":false}],"fileIds":[],"createdAt":"2026-11-07T18:50:00Z"},{"id":8,"mine":false,"content":null,"encrypted":{"ciphertext":"q83v","iv":"AAAA","senderKeyId":4,"recipientKeyId":3,"frankingTag":"ab"},"replyToId":7,"edited":false,"recalled":false,"reactions":[],"fileIds":[12],"createdAt":"2026-11-07T18:51:00Z"}],"hasOlder":true,"reportReasons":[],"limits":{"messageMax":2000,"pendingMax":3,"editMinutes":15},"serverTime":"2026-11-07T18:53:00Z"},"timestamp":"2026-11-07T18:53:00Z"}
''';

/// GET /api/me/chats/1/updates?after=5&changedSince=… (user@gmail.com): tin 6 vừa thu hồi, tin 1 vừa sửa.
const _updatesJson = r'''
{"success":true,"message":"OK","data":{"messages":[{"id":6,"mine":true,"content":null,"encrypted":null,"replyToId":null,"edited":false,"recalled":true,"reactions":[],"fileIds":[],"createdAt":"2026-11-07T18:54:34Z"}],"changed":[{"id":1,"mine":true,"content":"Chào chị, em là Minh (đã sửa). Em muốn hỏi về thuê nhà ở Tokyo ạ.","encrypted":null,"replyToId":null,"edited":true,"recalled":false,"reactions":[],"fileIds":[],"createdAt":"2026-11-07T18:53:06Z"},{"id":6,"mine":true,"content":null,"encrypted":null,"replyToId":null,"edited":false,"recalled":true,"reactions":[],"fileIds":[],"createdAt":"2026-11-07T18:54:34Z"}],"status":{"state":"ACCEPTED","canSend":true,"notice":null,"blockedByMe":false,"peerReadUpTo":1,"encryption":{"mode":"PLAIN","myKeyId":null,"peerKeyId":null,"peerPublicKey":null,"notice":{"code":"NO_KEY_ME","text":"Bạn chưa bật mã hóa đầu cuối. Hãy bật để gửi được ảnh, video, ghi âm và để chỉ hai bạn đọc được tin nhắn."}},"canAttach":false,"canReact":true,"peerTyping":false},"serverTime":"2026-11-07T18:54:33.891Z"},"timestamp":"2026-11-07T18:54:33.898054100Z"}
''';

/// GET /api/me/chats/1/messages?limit=5.
const _olderJson = r'''
{"success":true,"message":"OK","data":{"messages":[{"id":1,"mine":false,"content":"Chào chị, em là Minh. Em muốn hỏi về thuê nhà ở Tokyo ạ.","encrypted":null,"replyToId":null,"edited":false,"recalled":false,"reactions":[],"fileIds":[],"createdAt":"2026-11-07T18:53:06Z"}],"hasOlder":false},"timestamp":"2026-11-07T18:53:15.845581900Z"}
''';

/// POST /api/me/chats/with/6/messages: tin đầu tiên tạo cuộc trò chuyện 1.
const _sentJson = r'''
{"success":true,"message":"Đã gửi.","data":{"conversationId":1,"message":{"id":1,"mine":true,"content":"Chào chị, em là Minh. Em muốn hỏi về thuê nhà ở Tokyo ạ.","encrypted":null,"replyToId":null,"edited":false,"recalled":false,"reactions":[],"fileIds":[],"createdAt":"2026-11-07T18:53:06.396943300Z"},"status":{"state":"ACCEPTED","canSend":true,"notice":{"code":"WAITING","text":"Lan Anh chưa nhận lời mời nhắn tin của bạn. Bạn còn gửi được 2 tin nhắn trước khi Lan Anh trả lời."},"blockedByMe":false,"peerReadUpTo":0,"encryption":{"mode":"PLAIN","myKeyId":null,"peerKeyId":null,"peerPublicKey":null,"notice":{"code":"REQUEST_PLAIN","text":"Lời mời nhắn tin chưa được mã hóa và chỉ gửi được chữ. Khi hai bạn đã nhận lời và cùng bật mã hóa, tin nhắn sẽ được mã hóa đầu cuối."}},"canAttach":false,"canReact":false,"peerTyping":false}},"timestamp":"2026-11-07T18:53:06.428022700Z"}
''';

/// PUT /api/me/chats/1/messages/1.
const _editedJson = r'''
{"success":true,"message":"Đã sửa tin nhắn.","data":{"id":1,"mine":true,"content":"Chào chị, em là Minh (đã sửa). Em muốn hỏi về thuê nhà ở Tokyo ạ.","encrypted":null,"replyToId":null,"edited":true,"recalled":false,"reactions":[],"fileIds":[],"createdAt":"2026-11-07T18:53:06Z"},"timestamp":"2026-11-07T18:54:33.709657400Z"}
''';

/// DELETE /api/me/chats/1/messages/6.
const _recalledJson = r'''
{"success":true,"message":"Đã thu hồi tin nhắn.","data":{"id":6,"mine":true,"content":null,"encrypted":null,"replyToId":null,"edited":false,"recalled":true,"reactions":[],"fileIds":[],"createdAt":"2026-11-07T18:54:34Z"},"timestamp":"2026-11-07T18:54:33.861548500Z"}
''';

/// POST /api/me/chats/1/accept (mentor@gmail.com).
const _acceptJson = r'''
{"success":true,"message":"Đã chấp nhận lời mời nhắn tin.","data":{"state":"ACCEPTED","canSend":true,"notice":null,"blockedByMe":false,"peerReadUpTo":1,"encryption":{"mode":"PLAIN","myKeyId":null,"peerKeyId":null,"peerPublicKey":null,"notice":{"code":"NO_KEY_ME","text":"Bạn chưa bật mã hóa đầu cuối. Hãy bật để gửi được ảnh, video, ghi âm và để chỉ hai bạn đọc được tin nhắn."}},"canAttach":false,"canReact":true,"peerTyping":false},"timestamp":"2026-11-07T18:54:13.512587100Z"}
''';

/// GET /api/me/chats/blocks.
const _blocksJson = r'''
{"success":true,"message":"OK","data":[{"peer":{"id":9,"displayName":"Chat Stranger","avatarUrl":null,"tags":[],"active":true},"blockedAt":"2026-11-07T18:54:41Z"}],"timestamp":"2026-11-07T18:54:41.112214800Z"}
''';

/// Các trả lời lỗi của server.
const _waitingFullJson = r'''
{"success":false,"message":"Trần Minh chưa nhận lời mời nhắn tin của bạn. Bạn gửi thêm được khi Trần Minh trả lời.","data":{},"timestamp":"2026-11-07T18:53:55Z"}
''';
const _notMineJson = r'''
{"success":false,"message":"Bạn chỉ sửa hoặc thu hồi được tin nhắn của chính mình.","data":{},"timestamp":"2026-11-07T18:54:33.747773Z"}
''';
const _reportNoReasonJson = r'''
{"success":false,"message":"Hãy chọn lý do báo cáo.","data":{"reasonId":"Hãy chọn lý do báo cáo."},"timestamp":"2026-11-07T18:54:33.928321300Z"}
''';
const _notFoundJson = r'''
{"success":false,"message":"Không tìm thấy cuộc trò chuyện này.","data":{},"timestamp":"2026-11-07T19:00:13.048225600Z"}
''';
const _declineAnsweredJson = r'''
{"success":false,"message":"Chỉ từ chối được lời mời nhắn tin chưa trả lời.","data":{},"timestamp":"2026-11-07T19:00:13.072725700Z"}
''';
const _encryptedOnlyJson = r'''
{"success":false,"message":"Cuộc trò chuyện này đã được mã hóa đầu cuối. Hãy tải lại trang.","data":{},"timestamp":"2026-11-07T19:00:00Z"}
''';

Map<String, dynamic> _json(String raw) => jsonDecode(raw) as Map<String, dynamic>;

FakeReply _error(int status, String raw) => FakeReply(status, _json(raw));

/// Câu trả lời thành công không có dữ liệu, như server gửi cho block / unblock / report / typing.
Map<String, dynamic> _ok(String message, [Object? data]) => {
  'success': true,
  'message': message,
  'data': data,
  'timestamp': '2026-11-07T18:54:41Z',
};

void main() {
  group('đọc', () {
    test('findAll gửi box, page và đọc hộp thư với tin cuối đã thu hồi', () async {
      final server = FakeServer({'GET /api/me/chats': (_) => _json(_inboxJson)});
      final page = await ChatDao(server.api).findAll(page: 2);

      expect(server.last('GET', '/api/me/chats').uri.queryParameters, {'box': 'INBOX', 'page': '2'});
      expect(page.hasMore, isFalse);
      final item = page.items.single;
      expect(item.id, 1);
      expect(item.state, 'ACCEPTED');
      expect(item.peer.displayName, 'Lan Anh');
      expect(item.peer.avatarUrl, '');
      expect(item.peer.tags.single, (name: 'Mentor', color: '#C2456E'));
      expect(item.peer.active, isTrue);
      expect(item.lastMessage!.recalled, isTrue);
      expect(item.lastMessage!.content, isNull);
      expect(item.lastMessage!.mine, isTrue);
      expect(page.counts.latest, isNull);
    });

    test('findAll(box: REQUESTS) đọc lời mời và các con số', () async {
      final server = FakeServer({'GET /api/me/chats': (_) => _json(_requestsJson)});
      final page = await ChatDao(server.api).findAll(box: ChatDao.requests);

      expect(server.requests.last.uri.queryParameters['box'], 'REQUESTS');
      final item = page.items.single;
      expect(item.state, 'REQUEST');
      expect(item.unread, 3);
      expect(item.lastMessage!.content, 'Xin chao, tin nhan thu 3 cua nguoi la.');
      expect(item.lastMessage!.createdAt, DateTime.utc(2026, 11, 7, 18, 53, 55).toLocal());
      expect(page.counts.requests, 1);
      expect(page.counts.latest, (conversationId: 2, messageId: 4, peerName: 'Chat Stranger', request: true));
    });

    test('findCounts', () async {
      final server = FakeServer({'GET /api/me/chats/counts': (_) => _json(_countsJson)});
      final counts = await ChatDao(server.api).findCounts();
      expect(counts.unread, 1);
      expect(counts.requests, 1);
      expect(counts.latest!.peerName, 'Trần Minh');
      expect(counts.latest!.request, isTrue);
    });

    test('findById đọc cuộc trò chuyện, trạng thái lời mời, lý do báo cáo, giới hạn', () async {
      final server = FakeServer({'GET /api/me/chats/1': (_) => _json(_conversationJson)});
      final room = await ChatDao(server.api).findById(1);

      expect(room.id, 1);
      expect(room.peer.id, 2);
      expect(room.status.state, 'REQUEST');
      expect(room.status.canSend, isTrue);
      expect(room.status.noticeCode, 'REQUEST');
      expect(room.status.isRequest, isTrue);
      expect(room.status.noticeText, startsWith('Trần Minh muốn nhắn tin với bạn.'));
      expect(room.status.peerReadUpTo, 1);
      expect(room.status.isEncrypted, isFalse);
      expect(room.status.canReact, isFalse);
      expect(room.messages.single.content, 'Chào chị, em là Minh. Em muốn hỏi về thuê nhà ở Tokyo ạ.');
      expect(room.messages.single.mine, isFalse);
      expect(room.hasOlder, isFalse);
      expect(room.reportReasons.map((r) => r.label), ['Lừa đảo', 'Sai sự thật', 'Xúc phạm', 'Spam']);
      expect(room.messageMax, 2000);
      expect(room.editMinutes, 15);
      expect(room.serverTime, '2026-11-07T18:53:15.777Z');
    });

    test('findWith: chưa từng nhắn thì id null và thông báo NEW', () async {
      final server = FakeServer({'GET /api/me/chats/with/6': (_) => _json(_withJson)});
      final room = await ChatDao(server.api).findWith(6);
      expect(room.id, isNull);
      expect(room.status.state, isNull);
      expect(room.status.noticeCode, 'NEW');
      expect(room.messages, isEmpty);
    });

    test('hội thoại mã hóa đầu cuối: nhận ra E2EE, tin mã hóa không có chữ, có tệp, có cảm xúc', () async {
      final server = FakeServer({'GET /api/me/chats/3': (_) => _json(_e2eeJson)});
      final room = await ChatDao(server.api).findById(3);
      expect(room.status.isEncrypted, isTrue);
      expect(room.status.peerTyping, isTrue);
      expect(room.peer.avatarUrl, '/media/avatar/6.jpg');
      final plain = room.messages.first;
      expect(plain.isEncrypted, isFalse);
      expect(plain.edited, isTrue);
      expect(plain.reactions.single, (emoji: '❤️', count: 1, mine: false));
      final secret = room.messages.last;
      expect(secret.isEncrypted, isTrue);
      expect(secret.content, isNull);
      expect(secret.hasFiles, isTrue);
      expect(secret.replyToId, 7);
      expect(room.hasOlder, isTrue);
    });

    test('findOlder gửi before và limit', () async {
      final server = FakeServer({'GET /api/me/chats/1/messages': (_) => _json(_olderJson)});
      final older = await ChatDao(server.api).findOlder(1, before: 5, limit: 30);
      expect(server.requests.last.uri.queryParameters, {'before': '5', 'limit': '30'});
      expect(older.messages.single.id, 1);
      expect(older.hasOlder, isFalse);

      await ChatDao(server.api).findOlder(1);
      expect(server.requests.last.uri.queryParameters, isEmpty);
    });

    test('findUpdates gửi after, changedSince và đọc tin mới, tin đã đổi, trạng thái, giờ server', () async {
      final server = FakeServer({'GET /api/me/chats/1/updates': (_) => _json(_updatesJson)});
      final updates = await ChatDao(server.api).findUpdates(1, after: 5, changedSince: '2026-11-07T18:54:00Z');
      expect(server.requests.last.uri.queryParameters, {'after': '5', 'changedSince': '2026-11-07T18:54:00Z'});
      expect(updates.messages.single.recalled, isTrue);
      expect(updates.changed.map((m) => m.id), [1, 6]);
      expect(updates.changed.first.edited, isTrue);
      expect(updates.status.canReact, isTrue);
      expect(updates.status.noticeCode, isNull);
      expect(updates.serverTime, '2026-11-07T18:54:33.891Z');
    });

    test('findBlocks', () async {
      final server = FakeServer({'GET /api/me/chats/blocks': (_) => _json(_blocksJson)});
      final blocks = await ChatDao(server.api).findBlocks();
      expect(blocks.single.peer.displayName, 'Chat Stranger');
      expect(blocks.single.blockedAt, DateTime.utc(2026, 11, 7, 18, 54, 41).toLocal());
    });

    test('không phải cuộc trò chuyện của mình: ApiException 404', () async {
      final server = FakeServer({'GET /api/me/chats/999': (_) => _error(404, _notFoundJson)});
      await expectLater(
        ChatDao(server.api).findById(999),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 404)
              .having((e) => e.message, 'message', 'Không tìm thấy cuộc trò chuyện này.'),
        ),
      );
    });
  });

  group('ghi', () {
    test('sendTo gửi {content} tới /with/{userId}/messages và đọc cuộc trò chuyện vừa tạo', () async {
      final server = FakeServer({'POST /api/me/chats/with/6/messages': (_) => _json(_sentJson)});
      final sent = await ChatDao(server.api).sendTo(6, 'Chào chị');
      final request = server.last('POST', '/api/me/chats/with/6/messages');
      expect(request.data, {'content': 'Chào chị'});
      expect(request.headers['X-XSRF-TOKEN'], 'csrf-test');
      expect(sent.conversationId, 1);
      expect(sent.message.mine, isTrue);
      expect(sent.message.createdAt, DateTime.utc(2026, 11, 7, 18, 53, 6, 396, 943).toLocal());
      expect(sent.status.noticeCode, 'WAITING');
    });

    test('send gửi vào /{id}/messages; hết lượt lời mời thì ném câu của server (403)', () async {
      final server = FakeServer({'POST /api/me/chats/2/messages': (_) => _error(403, _waitingFullJson)});
      await expectLater(
        ChatDao(server.api).send(2, 'Xin chào'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('Bạn gửi thêm được khi'))),
      );
      expect(server.requests.last.data, {'content': 'Xin chào'});
    });

    test('hội thoại đã mã hóa từ chối tin thường (400)', () async {
      final server = FakeServer({'POST /api/me/chats/3/messages': (_) => _error(400, _encryptedOnlyJson)});
      await expectLater(
        ChatDao(server.api).send(3, 'Xin chào'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400)),
      );
    });

    test('update gửi PUT {content}; recall gửi DELETE; cả hai trả về tin mới và câu của server', () async {
      final server = FakeServer({
        'PUT /api/me/chats/1/messages/1': (_) => _json(_editedJson),
        'DELETE /api/me/chats/1/messages/6': (_) => _json(_recalledJson),
        'PUT /api/me/chats/1/messages/5': (_) => _error(400, _notMineJson),
      });
      final dao = ChatDao(server.api);

      final edited = await dao.update(1, 1, 'Nội dung mới');
      expect(server.last('PUT', '/api/me/chats/1/messages/1').data, {'content': 'Nội dung mới'});
      expect(edited.message, 'Đã sửa tin nhắn.');
      expect(edited.chatMessage.edited, isTrue);

      final recalled = await dao.recall(1, 6);
      expect(recalled.message, 'Đã thu hồi tin nhắn.');
      expect(recalled.chatMessage.recalled, isTrue);

      await expectLater(
        dao.update(1, 5, 'x'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('của chính mình'))),
      );
    });

    test('markRead gửi {upToId} và đọc các con số; typing gửi POST không body', () async {
      final server = FakeServer({
        'POST /api/me/chats/1/read': (_) => apiOk({'unread': 0, 'requests': 0, 'latest': null}),
        'POST /api/me/chats/1/typing': (_) => _ok('OK'),
      });
      final dao = ChatDao(server.api);
      final counts = await dao.markRead(1, upToId: 5);
      expect(server.last('POST', '/api/me/chats/1/read').data, {'upToId': 5});
      expect(counts.unread, 0);

      await dao.typing(1);
      expect(server.last('POST', '/api/me/chats/1/typing').data, isNull);
    });

    test('accept, decline, delete trả về câu của server; từ chối lời mời đã trả lời thì lỗi', () async {
      final server = FakeServer({
        'POST /api/me/chats/1/accept': (_) => _json(_acceptJson),
        'POST /api/me/chats/2/decline': (_) => _ok('Đã từ chối lời mời nhắn tin.', {'unread': 0, 'requests': 0}),
        'POST /api/me/chats/1/decline': (_) => _error(400, _declineAnsweredJson),
        'DELETE /api/me/chats/1': (_) => _ok('Đã xóa cuộc trò chuyện.', {'unread': 0, 'requests': 0}),
      });
      final dao = ChatDao(server.api);
      expect(await dao.accept(1), 'Đã chấp nhận lời mời nhắn tin.');
      expect(await dao.decline(2), 'Đã từ chối lời mời nhắn tin.');
      expect(await dao.delete(1), 'Đã xóa cuộc trò chuyện.');
      expect(server.requests.last.method, 'DELETE');
      await expectLater(
        dao.decline(1),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message', 'Chỉ từ chối được lời mời nhắn tin chưa trả lời.'),
        ),
      );
    });

    test('report gửi {reasonId, note, block}; thiếu lý do thì lỗi theo ô reasonId', () async {
      final server = FakeServer({
        'POST /api/me/chats/messages/5/report': (req) => (req.data as Map)['reasonId'] == null
            ? _error(400, _reportNoReasonJson)
            : _ok('Cảm ơn bạn. Báo cáo đã được gửi.'),
      });
      final dao = ChatDao(server.api);
      expect(await dao.report(5, reasonId: 4, note: 'Spam'), 'Cảm ơn bạn. Báo cáo đã được gửi.');
      expect(server.requests.last.data, {'reasonId': 4, 'note': 'Spam', 'block': false});

      await dao.report(5, reasonId: 1, block: true);
      expect(server.requests.last.data, {'reasonId': 1, 'note': null, 'block': true});
    });

    test('block gửi POST, unblock gửi DELETE /blocks/{userId}', () async {
      final server = FakeServer({
        'POST /api/me/chats/blocks/9': (_) => _ok('Đã chặn. Hai bạn không nhắn tin được cho nhau nữa.'),
        'DELETE /api/me/chats/blocks/9': (_) => _ok('Đã bỏ chặn.'),
      });
      final dao = ChatDao(server.api);
      expect(await dao.block(9), 'Đã chặn. Hai bạn không nhắn tin được cho nhau nữa.');
      expect(await dao.unblock(9), 'Đã bỏ chặn.');
      expect(server.requests.map((r) => '${r.method} ${r.uri.path}'), [
        'POST /api/me/chats/blocks/9',
        'DELETE /api/me/chats/blocks/9',
      ]);
    });
  });
}
