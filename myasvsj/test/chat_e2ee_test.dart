// Mã hóa đầu cuối trong ChatController và ChatScreen: mở khóa bằng mật khẩu khôi phục, giải mã tin, gửi / sửa /
// báo cáo tin mã hóa, bật mã hóa lần đầu. Dùng ChatCrypto thật (chạy ngay, không Isolate) với DAO giả.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/chat_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/chat_conversation.dart';
import 'package:myasvsj/com.myasvsj.model/chat_crypto.dart';
import 'package:myasvsj/com.myasvsj.model/chat_envelope.dart';
import 'package:myasvsj/com.myasvsj.model/chat_key_backup.dart';
import 'package:myasvsj/com.myasvsj.model/chat_keyring.dart';
import 'package:myasvsj/com.myasvsj.model/chat_message.dart';
import 'package:myasvsj/com.myasvsj.model/chat_status.dart';
import 'package:myasvsj/com.myasvsj.model/conversation_item.dart';
import 'package:myasvsj/com.myasvsj.model/user.dart';
import 'package:myasvsj/com.myasvsj.screen/chat_screen.dart';

import 'auth_fakes.dart';
import 'chat_fakes.dart';
import 'notification_test_app.dart';

const _pass = 'mật khẩu khôi phục';
const _conv = 3;
const _myKey = 3;
const _peerKey = 4;

Future<void> _settle([int ms = 5]) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  final crypto = ChatCrypto.inline();
  late ChatNewKey me;
  late ChatNewKey peer;

  setUpAll(() async {
    me = await crypto.createKey(_pass, iterations: 100000);
    peer = await crypto.createKey('mật khẩu của Lan Anh', iterations: 100000);
  });

  ChatKeyBackup myBackup() => ChatKeyBackup(
    id: _myKey,
    publicKey: me.publicKey,
    wrappedPrivateKey: me.wrappedPrivateKey,
    wrapSalt: me.wrapSalt,
    wrapIv: me.wrapIv,
    wrapIterations: me.wrapIterations,
  );

  ChatStatus e2ee({int myKeyId = _myKey}) => ChatStatus(
    state: 'ACCEPTED',
    canSend: true,
    canReact: true,
    isEncrypted: true,
    myKeyId: myKeyId,
    peerKeyId: _peerKey,
    peerPublicKey: peer.publicKey,
  );

  /// Tin Lan Anh (id 6) mã hóa gửi cho khóa [toKey] của mình.
  Future<ChatMessage> fromPeer(int id, String text, {int toKey = _myKey}) async {
    final key = await crypto.conversationKey(peer.privateKey, me.publicKey, _conv, _peerKey, toKey);
    final sealed = crypto.encrypt(
      key: key,
      conversationId: _conv,
      senderId: lanAnh.id,
      senderKeyId: _peerKey,
      recipientKeyId: toKey,
      body: ChatBody(text: text),
    );
    return ChatMessage(id: id, mine: false, isEncrypted: true, envelope: sealed.envelope, createdAt: DateTime.now());
  }

  /// Lan Anh giải mã một phong bì mình gửi.
  Future<String?> peerReads(ChatEnvelope envelope) async {
    final key = await crypto.conversationKey(peer.privateKey, me.publicKey, _conv, _peerKey, _myKey);
    return crypto.decrypt(key: key, conversationId: _conv, senderId: testUser.id, envelope: envelope).body.text;
  }

  late FakeChatDao dao;
  late FakeChatKeyDao keys;
  final owner = Object();

  Future<void> setUpRoom() async {
    dao = FakeChatDao();
    keys = FakeChatKeyDao(mine: myBackup(), publicKeys: {_peerKey: peer.publicKey});
    dao.rooms[_conv] = ChatConversation(
      id: _conv,
      peer: lanAnh,
      status: e2ee(),
      messages: [
        chatMessage(1, 'Tin cũ trước khi mã hóa', minutesAgo: 30),
        await fromPeer(8, 'Mai 9h gặp ở ga Shinjuku nhé'),
        // Viết cho một khóa cũ (id 2) app không có
        await fromPeer(9, 'Tin cho khóa cũ', toKey: 2),
      ],
      reportReasons: reasons,
    );
  }

  ChatController newChat() => ChatController(dao, keyDao: keys, crypto: crypto);

  group('ChatController', () {
    late ChatController chat;

    setUp(() async {
      await setUpRoom();
      chat = newChat();
      chat.onSignedInChanged(testUser);
      await _settle();
      await chat.openRoom(conversationId: _conv, owner: owner);
    });

    tearDown(() => chat.dispose());

    ChatMessage shown(int id) => chat.display(chat.room!.messages.firstWhere((m) => m.id == id));

    test('tài khoản có khóa mà app chưa mở: locked, tin mã hóa hiện câu nhắc, không gửi được', () async {
      expect(chat.keyState, ChatKeyState.locked);
      expect(shown(8).content, isNull);
      expect(shown(8).lockedText, ChatKeyring.lockedLabel);
      expect(shown(1).content, 'Tin cũ trước khi mã hóa');
      expect(chat.takeKeyPrompt(), isTrue);
      expect(chat.takeKeyPrompt(), isFalse, reason: 'chỉ tự mở hộp thoại một lần');
      expect(await chat.sendMessage('Chào chị'), isFalse);
      expect(chat.sendError, ChatController.lockedNotice);
    });

    test('sai mật khẩu khôi phục: báo lỗi, vẫn locked', () async {
      expect(await chat.unlockKey('sai rồi'), 'Mật khẩu khôi phục không đúng. Hãy thử lại.');
      expect(chat.keyState, ChatKeyState.locked);
      expect(await chat.unlockKey(''), 'Hãy nhập mật khẩu khôi phục.');
    });

    test('mở khóa đúng: giải mã tin của người kia; tin viết cho khóa khác thì không đọc được', () async {
      expect(await chat.unlockKey(_pass), isNull);
      expect(chat.keyState, ChatKeyState.ready);
      expect(chat.takeMessage(), startsWith('Đã mở khóa'));
      expect(shown(8).lockedText, ChatKeyring.decryptingLabel);
      await _settle();
      expect(shown(8).content, 'Mai 9h gặp ở ga Shinjuku nhé');
      expect(shown(8).decrypted, isTrue);
      expect(shown(9).lockedText, ChatKeyring.unreadableLabel);
    });

    test('gửi tin mã hóa: server nhận phong bì, người kia đọc được, tin của mình hiện ngay', () async {
      await chat.unlockKey(_pass);
      dao.calls.clear();
      expect(await chat.sendMessage('  Dạ, em sẽ tới đúng giờ  '), isTrue);
      expect(dao.calls, contains('sendEncrypted $_conv'));
      expect(dao.calls.where((c) => c.startsWith('send ')), isEmpty, reason: 'không bao giờ gửi chữ thường');
      expect(await peerReads(dao.envelopes.single), 'Dạ, em sẽ tới đúng giờ');
      final sent = chat.room!.messages.last;
      expect(chat.display(sent).content, 'Dạ, em sẽ tới đúng giờ');
    });

    test('409 (khóa vừa đổi): đọc lại trạng thái, mã hóa và gửi lại một lần', () async {
      await chat.unlockKey(_pass);
      dao.failEncryptedOnceWith = const ApiException('Khóa đã đổi.', statusCode: 409);
      dao.calls.clear();
      expect(await chat.sendMessage('Gửi lại'), isTrue);
      expect(dao.calls, ['sendEncrypted $_conv', 'findById $_conv', 'sendEncrypted $_conv']);
      expect(await peerReads(dao.envelopes.single), 'Gửi lại');
    });

    test('khóa trên server đã thay ở máy khác: không gửi, báo nhập lại mật khẩu, tải lại khóa', () async {
      await chat.unlockKey(_pass);
      dao.rooms[_conv] = dao.rooms[_conv]!.copyWith(status: e2ee(myKeyId: 7));
      await chat.refreshRoom();
      await _settle();
      expect(keys.calls.where((c) => c == 'findMine').length, greaterThanOrEqualTo(3));
      expect(await chat.sendMessage('Tin mới'), isFalse);
      expect(chat.sendError, contains('mật khẩu khôi phục'));
      expect(dao.envelopes, isEmpty);
    });

    test('sửa tin mã hóa của mình: phong bì mới, người kia đọc được chữ mới', () async {
      await chat.unlockKey(_pass);
      await chat.sendMessage('Chữ cũ');
      final mine = chat.display(chat.room!.messages.last);
      expect(chat.canEdit(mine), isTrue);
      chat.startEdit(mine);
      expect(await chat.sendMessage('Chữ mới'), isTrue);
      expect(dao.calls.last, 'updateEncrypted $_conv ${mine.id}');
      expect(await peerReads(dao.envelopes.last), 'Chữ mới');
      expect(chat.display(chat.room!.messages.last).content, 'Chữ mới');
      expect(chat.editing, isNull);
    });

    test('báo cáo tin mã hóa: gửi kèm nội dung đã giải mã và franking key; chưa đọc được thì không báo cáo', () async {
      expect(chat.canReport(shown(8)), isFalse);
      expect(await chat.reportMessage(shown(8), reasonId: 1), isFalse);
      expect(dao.reports, isEmpty);

      await chat.unlockKey(_pass);
      shown(8);
      await _settle();
      expect(chat.canReport(shown(8)), isTrue);
      expect(await chat.reportMessage(shown(8), reasonId: 1, note: 'lừa đảo'), isTrue);
      expect(dao.evidence.single.plaintext, isNotNull);
      expect(dao.evidence.single.frankingKey, isNotNull);
    });

    test('dòng xem trước của danh sách cũng được giải mã', () async {
      final last = dao.rooms[_conv]!.messages[1];
      final item = ConversationItem(id: _conv, peer: lanAnh, lastMessage: last);
      expect(chat.previewOf(item)!.content, isNull);
      await chat.unlockKey(_pass);
      chat.previewOf(item);
      await _settle();
      expect(chat.previewOf(item)!.content, 'Mai 9h gặp ở ga Shinjuku nhé');
    });

    test('đăng xuất: quên khóa đã mở', () async {
      await chat.unlockKey(_pass);
      chat.onSignedInChanged(null);
      expect(chat.keyState, ChatKeyState.off);
    });
  });

  group('bật mã hóa lần đầu', () {
    test('chưa có khóa: none; mật khẩu ngắn / nhập lại khác bị từ chối; tạo khóa thì ready', () async {
      await setUpRoom();
      keys.mine = null;
      final chat = newChat()..onSignedInChanged(testUser);
      await _settle();
      expect(chat.keyState, ChatKeyState.none);
      expect(await chat.createKey('ngắn', 'ngắn'), 'Mật khẩu khôi phục cần ít nhất 8 ký tự.');
      expect(await chat.createKey('mật khẩu dài', 'mật khẩu khác'), 'Hai lần nhập mật khẩu khôi phục chưa giống nhau.');
      expect(await chat.createKey('mật khẩu dài', 'mật khẩu dài'), isNull);
      expect(chat.keyState, ChatKeyState.ready);
      expect(keys.calls, contains('create'));
      expect(keys.mine, isNotNull);
      expect(chat.takeMessage(), 'Đã bật mã hóa đầu cuối.');
      // Bản sao lưu vừa gửi lên mở lại được bằng chính mật khẩu đó (máy khác, hoặc web)
      final again = await crypto.unlock(keys.mine!, 'mật khẩu dài');
      expect(again.publicKey, keys.mine!.publicKey);
      chat.dispose();
    });

    test('máy khác đã bật trong lúc đó: không tạo đè, chuyển sang nhập mật khẩu khôi phục', () async {
      await setUpRoom();
      keys.mine = null;
      final chat = newChat()..onSignedInChanged(testUser);
      await _settle();
      keys.mine = myBackup();
      expect(await chat.createKey('mật khẩu dài', 'mật khẩu dài'), contains('thiết bị khác'));
      expect(chat.keyState, ChatKeyState.locked);
      expect(keys.calls, isNot(contains('create')));
      chat.dispose();
    });
  });

  group('ChatScreen', () {
    testWidgets('hộp thoại mật khẩu khôi phục tự mở, mở khóa xong thì đọc và gửi được tin', (tester) async {
      await tester.runAsync(setUpRoom);
      final chat = newChat()..onSignedInChanged(testUser);
      await tester.pumpWidget(
        notifyChatApp(
          home: const ChatScreen(conversationId: _conv),
          auth: await signedInAuth(),
          chat: chat,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nhập mật khẩu khôi phục'), findsWidgets, reason: 'tiêu đề hộp thoại tự mở');
      expect(find.text('Quên mật khẩu? Tạo khóa mới'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Mật khẩu khôi phục'), _pass);
      // Mã hóa chạy ngay trên isolate của test (ChatCrypto.inline), các bước chờ chỉ là microtask
      await tester.tap(find.text('Mở khóa'));
      await tester.pumpAndSettle();

      expect(find.text('Mở khóa'), findsNothing, reason: 'hộp thoại đã đóng');
      expect(find.text('Đã mở khóa. Bạn đọc và gửi được tin nhắn mã hóa trên app này.'), findsOneWidget);
      expect(find.text('Mai 9h gặp ở ga Shinjuku nhé'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget, reason: 'ô soạn tin mở lại');

      // Đợi SnackBar "Đã mở khóa…" ẩn (nó che nút gửi)
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Em tới rồi ạ');
      await tester.pump();
      await tester.tap(find.byTooltip('Gửi'));
      await tester.pumpAndSettle();
      expect(chat.sendError, isNull);
      expect(dao.envelopes, hasLength(1), reason: '${dao.calls}');
      expect(await peerReads(dao.envelopes.single), 'Em tới rồi ạ');
      expect(find.text('Em tới rồi ạ'), findsOneWidget);
    });

    testWidgets('đóng hộp thoại: ô soạn tin thay bằng nút "Nhập mật khẩu khôi phục"', (tester) async {
      await tester.runAsync(setUpRoom);
      final chat = newChat()..onSignedInChanged(testUser);
      await tester.pumpWidget(
        notifyChatApp(
          home: const ChatScreen(conversationId: _conv),
          auth: await signedInAuth(),
          chat: chat,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nhập mật khẩu khôi phục để đọc và gửi tin nhắn trên app này.'), findsOneWidget);
      expect(find.text(ChatKeyring.lockedLabel), findsNWidgets(2));
      await tester.tap(find.widgetWithText(FilledButton, 'Nhập mật khẩu khôi phục').last);
      await tester.pumpAndSettle();
      expect(find.text('Mở khóa'), findsOneWidget, reason: 'nút mở lại hộp thoại');
    });
  });

  group('lưu khóa trên máy', () {
    late FakeChatDeviceKeyDao device;

    setUp(() async {
      await setUpRoom();
      device = FakeChatDeviceKeyDao();
    });

    ChatController appStart() =>
        ChatController(dao, keyDao: keys, deviceKeys: device, crypto: crypto)..onSignedInChanged(testUser);

    test('mở khóa một lần; mở lại app thì ready ngay, không hỏi mật khẩu, vẫn giải mã được', () async {
      final first = appStart();
      await _settle();
      expect(first.keyState, ChatKeyState.locked);
      expect(await first.unlockKey(_pass), isNull);
      expect(device.saved[testUser.id]!.keyId, _myKey);
      first.dispose();

      final again = appStart();
      await _settle();
      expect(again.keyState, ChatKeyState.ready);
      await again.openRoom(conversationId: _conv, owner: owner);
      expect(again.takeKeyPrompt(), isFalse, reason: 'không tự mở hộp thoại mật khẩu');
      again.display(again.room!.messages[1]);
      await _settle();
      expect(again.display(again.room!.messages[1]).content, 'Mai 9h gặp ở ga Shinjuku nhé');
      again.dispose();
    });

    test('bật mã hóa trên app cũng lưu khóa vừa tạo', () async {
      keys.mine = null;
      final chat = appStart();
      await _settle();
      expect(await chat.createKey('mật khẩu dài', 'mật khẩu dài'), isNull);
      expect(device.saved[testUser.id]!.keyId, keys.mine!.id);
      chat.dispose();
    });

    test('khóa đã lưu là khóa cũ (máy khác vừa tạo khóa mới): phải nhập mật khẩu lại', () async {
      final first = appStart();
      await _settle();
      await first.unlockKey(_pass);
      first.dispose();
      keys.mine = ChatKeyBackup(
        id: 50,
        publicKey: peer.publicKey,
        wrappedPrivateKey: peer.wrappedPrivateKey,
        wrapSalt: peer.wrapSalt,
        wrapIv: peer.wrapIv,
        wrapIterations: peer.wrapIterations,
      );

      final again = appStart();
      await _settle();
      expect(again.keyState, ChatKeyState.locked);
      again.dispose();
    });

    test('máy từ chối lưu: vẫn mở khóa được trong lần mở app này', () async {
      device.failSave = true;
      final chat = appStart();
      await _settle();
      expect(await chat.unlockKey(_pass), isNull);
      expect(chat.keyState, ChatKeyState.ready);
      expect(device.saved, isEmpty);
      chat.dispose();
    });

    test('khóa lưu theo từng tài khoản: tài khoản khác không dùng được', () async {
      final first = appStart();
      await _settle();
      await first.unlockKey(_pass);
      first.onSignedInChanged(const User(id: 77, email: 'khac@example.com', displayName: 'Khác', role: 'USER'));
      await _settle();
      expect(first.keyState, ChatKeyState.locked);
      first.dispose();
    });
  });
}
