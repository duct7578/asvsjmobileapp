// Test luồng tức thì: đọc Server-Sent Events thành LiveEvent (từ các dòng chép của server thật,
// `curl -N http://localhost:8080/api/me/live`), và LiveDao mở đúng GET /api/me/live.
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_client.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/live_dao.dart';
import 'package:myasvsj/com.myasvsj.model/live_event.dart';
import 'package:myasvsj/com.myasvsj.model/live_event_parser.dart';

/// Luồng mentor@gmail.com nhận được khi user@gmail.com nhắn tin rồi Lan Anh nhận lời (chép từ server thật).
const _captured =
    'event:ready\n'
    'retry:3000\n'
    'data:{}\n'
    '\n'
    'event:chat\n'
    'data:{"kind":"message","conversationId":1,"messageId":1}\n'
    '\n'
    'event:chat\n'
    'data:{"kind":"status","conversationId":1}\n'
    '\n'
    ':ping\n'
    '\n'
    'event:notification\n'
    'data:{}\n'
    '\n';

Future<List<LiveEvent>> _parse(List<String> lines) =>
    Stream.fromIterable(lines).transform(const LiveEventParser()).toList();

/// Server giả trả về một luồng text/event-stream gồm các mảnh [chunks].
class _SseServer implements HttpClientAdapter {
  _SseServer(this.status, this.chunks);

  final int status;
  final List<String> chunks;
  RequestOptions? request;

  late final ApiClient api = ApiClient(
    Dio(BaseOptions(baseUrl: 'http://fake.local', validateStatus: (_) => true))..httpClientAdapter = this,
  );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody(
      Stream.fromIterable([for (final c in chunks) Uint8List.fromList(utf8.encode(c))]),
      status,
      headers: {
        Headers.contentTypeHeader: ['text/event-stream'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('LiveEventParser', () {
    test('đọc đúng các sự kiện server thật gửi, theo thứ tự', () async {
      final events = await _parse(const LineSplitter().convert(_captured));
      expect(events.map((e) => e.type), ['ready', 'chat', 'chat', 'ping', 'notification']);

      expect(events[0].isReady, isTrue);
      expect(events[0].data, isEmpty);

      final message = events[1];
      expect(message.isChat, isTrue);
      expect(message.kind, 'message');
      expect(message.conversationId, 1);
      expect(message.messageId, 1);

      expect(events[2].kind, 'status');
      expect(events[2].messageId, isNull);
      expect(events[4].isNotification, isTrue);
    });

    test('nhiều dòng data: được nối bằng xuống dòng; bỏ một dấu cách sau dấu hai chấm', () async {
      final events = await _parse(['event: chat', 'data: {"kind":', 'data: "typing","conversationId":7}', '']);
      expect(events.single.type, 'chat');
      expect(events.single.kind, 'typing');
      expect(events.single.conversationId, 7);
    });

    test('không có event: thì tên là "message"; data hỏng thì coi như {}', () async {
      final events = await _parse(['data:không phải JSON', '', 'id:42', 'retry:5000', 'event:chat', 'data:[1,2]', '']);
      expect(events.map((e) => e.type), ['message', 'chat']);
      expect(events[0].data, isEmpty);
      expect(events[1].data, isEmpty);
    });

    test('dòng trống không có data thì không sinh sự kiện; sự kiện dở dang lúc hết luồng bị bỏ', () async {
      final events = await _parse(['event:chat', '', '', 'event:notification', 'data:{}']);
      expect(events, isEmpty);
    });
  });

  group('LiveDao', () {
    test('open gọi GET /api/me/live (Accept: text/event-stream) và ghép được dòng bị cắt giữa hai mảnh', () async {
      final server = _SseServer(200, [
        'event:rea',
        'dy\nretry:3000\ndata:{}\n\nevent:chat\ndata:{"kind":"message","conv',
        'ersationId":1,"messageId":5}\n\n:ping\n\n',
      ]);
      final events = await LiveDao(server.api).open().toList();

      expect(server.request!.method, 'GET');
      expect(server.request!.uri.path, '/api/me/live');
      expect(server.request!.headers['Accept'], 'text/event-stream');
      expect(events.map((e) => e.type), ['ready', 'chat', 'ping']);
      expect(events[1].messageId, 5);
    });

    test('phiên đã hết: ném ApiException 401', () async {
      final server = _SseServer(401, ['']);
      await expectLater(
        LiveDao(server.api).open().toList(),
        throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
      );
    });
  });
}
