// ProfileDao với server thật: đọc bằng user@gmail.com, thao tác ghi bằng kouhai@gmail.com và trả lại giá trị cũ.
//
// Chạy: flutter test test/live/profile_live_test.dart --dart-define=LIVE_API=http://localhost:8080
//
// Gửi yêu cầu tag thật không hoàn tác được, nên chỉ chạy với một tài khoản thử tạo riêng (email @example.com):
// thêm --dart-define=LIVE_THROWAWAY_EMAIL=… --dart-define=LIVE_THROWAWAY_PASSWORD=…; test XÓA tài khoản đó khi
// xong (server đóng yêu cầu đang chờ và hủy ảnh minh chứng).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/profile_dao.dart';
import 'package:myasvsj/com.myasvsj.model/profile_stage.dart';
import 'package:myasvsj/com.myasvsj.model/tag_request.dart';

import 'live_api.dart';

/// Ảnh JPEG 16×16 thật (server giải mã được), làm ảnh minh chứng khi thử gửi yêu cầu tag.
const _jpegBase64 =
    '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PT'
    'gyPC4zNDL/2wBDAQkJCQwLDBgNDRgyIRwhMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjIyMjL/wAARCAAQ'
    'ABADASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJx'
    'FDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWW'
    'l5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAEC'
    'AwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAECAxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2'
    'Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU'
    '1dbX2Nna4uPk5ebn6Onq8vP09fb3+Pn6/9oADAMBAAIRAxEAPwCrRRRXvngn/9k=';

const _throwawayEmail = String.fromEnvironment('LIVE_THROWAWAY_EMAIL');
const _throwawayPassword = String.fromEnvironment('LIVE_THROWAWAY_PASSWORD');

/// Ghi ảnh mẫu ra một file tạm; xóa thư mục khi test xong.
File _samplePhoto() {
  final dir = Directory.systemTemp.createTempSync('profile_live');
  addTearDown(() {
    try {
      dir.deleteSync(recursive: true);
    } on FileSystemException {
      // thư mục tạm của hệ điều hành sẽ tự dọn
    }
  });
  return File('${dir.path}/proof.jpg')..writeAsBytesSync(base64Decode(_jpegBase64));
}

void main() {
  group('đọc (user@gmail.com)', () {
    late ProfileDao dao;

    // Không có server (chạy test thường) thì bỏ qua đăng nhập; các test trong nhóm đều skip
    setUpAll(() async {
      if (liveSkip == null) dao = ProfileDao(await liveSignedIn('user@gmail.com'));
    });

    test('findProfile', () async {
      final profile = await dao.findProfile();
      expect(profile.email, 'user@gmail.com');
      expect(profile.displayName, isNotEmpty);
      expect(profile.isMember, isTrue);
      expect(profile.roleLabel, isNotEmpty);
      expect(profile.ranks, isNotEmpty);
      expect(profile.ranks.first.minPoints, 0);
      expect(profile.currentRank, isNotNull);
      expect(profile.newAccountDays, greaterThan(0));
      expect(profile.today.maxPosts, greaterThan(0));
      expect(profile.createdAt, isNotNull);
      expect(profile.hasPassword, isTrue);
      expect(profile.savedCount, greaterThanOrEqualTo(0));
      if (profile.stage != null) {
        expect(ProfileStage.labelOf(profile.stage), isNotNull, reason: 'mã giai đoạn của server có tên trên app');
      }
      if (profile.areaId != null) {
        expect(profile.areaName, isNotEmpty);
      }
    }, skip: liveSkip);

    test('findPointHistory', () async {
      final page = await dao.findPointHistory();
      expect(page.page, 0);
      expect(page.size, 20);
      expect(page.points, greaterThanOrEqualTo(0));
      expect(page.items.length, lessThanOrEqualTo(20));
      for (final line in page.items) {
        expect(line.reasonLabel, isNotEmpty);
        expect(line.createdAt, isNotNull);
      }
    }, skip: liveSkip);

    test('findInterests', () async {
      final settings = await dao.findInterests();
      expect(settings.max, 5);
      expect(settings.topics, isNotEmpty);
      expect(settings.topics.map((t) => t.name), isNot(contains('Khác')));
      expect(settings.topics.where((t) => t.chosen && t.learnt), isEmpty);
    }, skip: liveSkip);

    test('findTagCompose', () async {
      final compose = await dao.findTagCompose();
      expect(compose.tags, isNotEmpty);
      expect(compose.tags.first.name, isNotEmpty);
      expect(compose.tags.where((t) => !t.selfieOnly).every((t) => t.proofTypes.isNotEmpty), isTrue);
      expect(compose.keepDays, greaterThan(0));
      expect(compose.photoMaxMb, greaterThan(0));
    }, skip: liveSkip);
  });

  group('khu vực (khách, API công khai)', () {
    final dao = ProfileDao(liveGuest());

    test('findAreaPicker có 47 tỉnh', () async {
      final picker = await dao.findAreaPicker();
      expect(picker.prefectures, hasLength(47));
      expect(picker.prefectures.firstWhere((p) => p.code == '13').nameEn, 'Tokyo');
    }, skip: liveSkip);

    test('findAreasInPrefecture, searchAreas, findArea', () async {
      final tokyo = await dao.findAreasInPrefecture('13');
      expect(tokyo, isNotEmpty);
      expect(tokyo.every((a) => a.prefectureCode == '13'), isTrue);

      final found = await dao.searchAreas('arakawa');
      final arakawa = found.firstWhere((a) => a.nameEn == 'Arakawa-ku');
      expect(arakawa.name, contains('東京都荒川区'));
      expect(await dao.searchAreas(''), isEmpty);

      final same = await dao.findArea(arakawa.id);
      expect(same.nameJa, '荒川区');
      expect(same.lat, isNotNull);
    }, skip: liveSkip);

    test('findNearestArea: trong Nhật có gợi ý, ngoài Nhật nhận câu báo lỗi', () async {
      final near = await dao.findNearestArea(35.736, 139.7834);
      expect(near.nameEn, 'Arakawa-ku');
      await expectLater(
        dao.findNearestArea(21.03, 105.85),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', contains('không ở Nhật Bản'))),
      );
    }, skip: liveSkip);

    test('khách đọc hồ sơ thì nhận 401', () async {
      await expectLater(
        dao.findProfile(),
        throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
      );
    }, skip: liveSkip);
  });

  group('ghi (kouhai@gmail.com, trả lại như cũ)', () {
    late ProfileDao dao;

    // Không có server (chạy test thường) thì bỏ qua đăng nhập; các test trong nhóm đều skip
    setUpAll(() async {
      if (liveSkip == null) dao = ProfileDao(await liveSignedIn('kouhai@gmail.com'));
    });

    test('updateAreaStage lưu rồi trả lại khu vực, giai đoạn cũ', () async {
      final before = await dao.findProfile();
      addTearDown(() => dao.updateAreaStage(areaId: before.areaId, stage: before.stage));

      final chiyoda = (await dao.searchAreas('chiyoda')).firstWhere((a) => a.nameEn == 'Chiyoda-ku');
      final newStage = before.stage == 'PRE' ? 'HOME' : 'PRE';
      final result = await dao.updateAreaStage(areaId: chiyoda.id, stage: newStage);
      expect(result.message, 'Đã lưu khu vực và giai đoạn.');
      expect(result.profile.areaId, chiyoda.id);
      expect(result.profile.areaName, chiyoda.name);
      expect(result.profile.stage, newStage);

      await expectLater(
        dao.updateAreaStage(areaId: chiyoda.id, stage: 'XX'),
        throwsA(isA<ApiException>().having((e) => e.fields['stage'], 'fields.stage', isNotNull)),
      );

      final restored = await dao.updateAreaStage(areaId: before.areaId, stage: before.stage);
      expect(restored.profile.areaId, before.areaId);
      expect(restored.profile.stage, before.stage);
    }, skip: liveSkip);

    test('updateInterests lưu rồi trả lại lựa chọn cũ', () async {
      final before = await dao.findInterests();
      final old = [for (final t in before.chosen) t.id];
      addTearDown(() => dao.updateInterests(old));

      final pick = [for (final t in before.topics.take(2)) t.id];
      final result = await dao.updateInterests(pick);
      expect(result.message, 'Đã lưu chủ đề quan tâm.');
      expect(result.settings.chosen.map((t) => t.id), unorderedEquals(pick));

      await expectLater(
        dao.updateInterests([for (final t in before.topics.take(6)) t.id]),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Bạn chọn được tối đa 5 chủ đề.')),
      );

      final restored = await dao.updateInterests(old);
      expect(restored.settings.chosen.map((t) => t.id), unorderedEquals(old));
    }, skip: liveSkip);

    // Gửi yêu cầu tag thật sẽ để lại yêu cầu chờ Moderator duyệt, nên chỉ thử những lần server từ chối.
    // Lỗi chỉ ở ô "consent" chứng tỏ server đã đọc được phần JSON "request" (tagId, proofTypeId) và ảnh "photo".
    test('submitTagRequest: server đọc đúng multipart, từ chối khi chưa đồng ý', () async {
      final compose = await dao.findTagCompose();
      final tag = compose.tags.firstWhere((t) => !t.owned && !t.selfieOnly);
      final photo = _samplePhoto();

      await expectLater(
        dao.submitTagRequest(
          TagRequest(tagId: tag.id, proofTypeId: tag.proofTypes.first.id, consent: false, photoPath: photo.path),
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.fields.keys, 'fields', ['consent'])
              .having((e) => e.message, 'message', 'Bạn cần đồng ý cho Kiểm duyệt viên xem ảnh.'),
        ),
      );

      // Thiếu hết: server báo lỗi từng ô
      await expectLater(
        dao.submitTagRequest(const TagRequest()),
        throwsA(isA<ApiException>().having((e) => e.fields.keys, 'fields', containsAll(['tagId', 'photo', 'consent']))),
      );

      // Đủ thông tin nhưng tag đã có (hoặc đang có yêu cầu chờ): 409, không tạo yêu cầu nào
      final owned = compose.tags.where((t) => t.owned && !t.selfieOnly);
      if (owned.isNotEmpty || compose.pending != null) {
        final target = owned.isNotEmpty ? owned.first : tag;
        await expectLater(
          dao.submitTagRequest(
            TagRequest(tagId: target.id, proofTypeId: target.proofTypes.first.id, consent: true, photoPath: photo.path),
          ),
          throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 409)),
        );
      }
    }, skip: liveSkip);
  });

  test(
    'submitTagRequest thật với tài khoản thử, rồi xóa tài khoản đó',
    () async {
      final api = await liveSignedIn(_throwawayEmail, password: _throwawayPassword);
      final dao = ProfileDao(api);
      // Xóa tài khoản thử dù test đạt hay không: server đóng yêu cầu tag đang chờ và hủy ảnh
      addTearDown(() => api.delete('/api/me'));
      expect((await dao.findProfile()).email, _throwawayEmail);

      final before = await dao.findTagCompose();
      expect(before.pending, isNull);
      final tag = before.tags.firstWhere((t) => !t.owned && !t.selfieOnly);
      final result = await dao.submitTagRequest(
        TagRequest(tagId: tag.id, proofTypeId: tag.proofTypes.last.id, consent: true, photoPath: _samplePhoto().path),
      );
      expect(result.message, 'Đã gửi yêu cầu tag.');
      expect(result.pending?.tagName, tag.name);
      expect(result.pending?.submittedAt, isNotNull);
      expect(result.pending!.expiresAt!.isAfter(result.pending!.submittedAt!), isTrue);

      final after = await dao.findTagCompose();
      expect(after.pending?.tagName, tag.name);
      expect((await dao.findProfile()).pendingTag, tag.name);

      // Mỗi người chỉ một yêu cầu chờ duyệt
      await expectLater(
        dao.submitTagRequest(
          TagRequest(tagId: tag.id, proofTypeId: tag.proofTypes.last.id, consent: true, photoPath: _samplePhoto().path),
        ),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Bạn đang có một yêu cầu tag chờ duyệt.')),
      );
    },
    skip:
        liveSkip ??
        (_throwawayEmail.endsWith('@example.com') ? null : 'Cần --dart-define=LIVE_THROWAWAY_EMAIL=<…@example.com>'),
  );
}
