// Test ChatDeviceKeyDao với FlutterSecureStorage giả (setMockInitialValues): lưu, đọc lại, xóa, dữ liệu hỏng.
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/chat_device_key_dao.dart';
import 'package:myasvsj/com.myasvsj.model/chat_identity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('lưu rồi đọc lại đúng khóa của từng tài khoản; xóa thì hết', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final dao = ChatDeviceKeyDao();
    final d = Uint8List.fromList(List.generate(32, (i) => i + 1));
    await dao.save(1, ChatIdentity(keyId: 3, publicKey: 'BAx=', privateKey: d));
    final found = await dao.find(1);
    expect(found!.keyId, 3);
    expect(found.publicKey, 'BAx=');
    expect(found.privateKey, d);
    expect(await dao.find(2), isNull);
    await dao.delete(1);
    expect(await dao.find(1), isNull);
  });

  test('dữ liệu hỏng thì coi như chưa lưu', () async {
    FlutterSecureStorage.setMockInitialValues({
      'chat.identity.1': 'không phải JSON',
      'chat.identity.2': '{"keyId":3,"publicKey":"BAx=","privateKey":"AAAA"}',
      'chat.identity.3': '{"keyId":"3"}',
    });
    final dao = ChatDeviceKeyDao();
    expect(await dao.find(1), isNull);
    expect(await dao.find(2), isNull, reason: 'khóa bí mật không đủ 32 byte');
    expect(await dao.find(3), isNull);
  });
}
