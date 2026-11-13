// Unit test của AreaStageController (Khu vực và giai đoạn) với DAO giả, không cần server.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/area_stage_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/area_dev_location.dart';
import 'package:myasvsj/com.myasvsj.model/area_picker_data.dart';
import 'package:myasvsj/com.myasvsj.model/user_profile.dart';

import 'profile_fakes.dart';

void main() {
  late FakeProfileDao dao;
  late AreaStageController controller;

  setUp(() {
    dao = FakeProfileDao();
    controller = AreaStageController(dao);
  });

  group('open', () {
    test('lấy danh sách tỉnh, giai đoạn và khu vực đang lưu, mở sẵn tỉnh của khu vực', () async {
      final future = controller.open();
      expect(controller.isLoading, isTrue);
      await future;
      expect(controller.isLoading, isFalse);
      expect(controller.prefectures.map((p) => p.code), ['13', '27']);
      expect(controller.stage, 'ARR');
      expect(controller.prefectureCode, '13');
      expect(controller.area?.id, 679);
      expect(controller.areas.map((a) => a.id), [662, 679]);
      expect(controller.areaLabel, 'Khu vực bạn đang sống');
    });

    test('chưa chọn khu vực thì không mở tỉnh nào', () async {
      dao.profile = const UserProfile(id: 1, email: 'an@example.com', displayName: 'An');
      await controller.open();
      expect(controller.stage, isNull);
      expect(controller.prefectureCode, isNull);
      expect(controller.area, isNull);
      expect(dao.calls, isNot(contains('findAreasInPrefecture')));
    });

    test('khu vực đang lưu không còn thì coi như chưa chọn', () async {
      dao.failOn['findArea'] = const ApiException('Không tìm thấy khu vực này.', statusCode: 404);
      await controller.open();
      expect(controller.error, isNull);
      expect(controller.area, isNull);
    });

    test('lỗi server giữ ở error', () async {
      dao.failWith = const ApiException('Không kết nối được tới server.');
      await controller.open();
      expect(controller.error, 'Không kết nối được tới server.');
      expect(controller.isLoading, isFalse);
    });
  });

  group('chọn', () {
    setUp(() => controller.open());

    test('đổi giai đoạn đổi nhãn ô khu vực', () {
      controller.selectStage('PRE');
      expect(controller.areaLabel, 'Khu vực bạn sắp đến');
      controller.selectStage('HOME');
      expect(controller.areaLabel, 'Khu vực bạn từng sống');
      controller.selectStage(null);
      expect(controller.areaLabel, 'Khu vực bạn đang sống');
    });

    test('chọn tỉnh khác bỏ khu vực đang chọn và tải khu vực của tỉnh đó', () async {
      final future = controller.selectPrefecture('27');
      expect(controller.isLoadingAreas, isTrue);
      expect(controller.area, isNull);
      await future;
      expect(controller.isLoadingAreas, isFalse);
      expect(controller.areas.single.nameEn, 'Kita-ku, Osaka-shi');

      controller.selectArea(1001);
      expect(controller.area?.id, 1001);
    });

    test('danh sách khu vực của một tỉnh chỉ tải một lần', () async {
      await controller.selectPrefecture('27');
      await controller.selectPrefecture('13');
      await controller.selectPrefecture('27');
      expect(dao.calls.where((c) => c == 'findAreasInPrefecture'), hasLength(2));
    });

    test('lỗi tải khu vực giữ ở areasError, Thử lại tải được', () async {
      dao.failOn['findAreasInPrefecture'] = const ApiException('Mất mạng.');
      await controller.selectPrefecture('27');
      expect(controller.areasError, 'Mất mạng.');
      dao.failOn.clear();
      await controller.retryAreas();
      expect(controller.areasError, isNull);
      expect(controller.areas, hasLength(1));
    });

    test('clearArea bỏ chọn tỉnh và khu vực', () async {
      controller.clearArea();
      expect(controller.prefectureCode, isNull);
      expect(controller.area, isNull);
    });
  });

  group('tìm nhanh', () {
    setUp(() => controller.open());

    test('searchAreas lấy kết quả; chọn một kết quả thì mở tỉnh của nó', () async {
      await controller.searchAreas(' kita ');
      expect(controller.searchQuery, 'kita');
      expect(controller.searchResults.single.id, 1001);
      expect(controller.searchFoundNothing, isFalse);

      await controller.chooseArea(controller.searchResults.single);
      expect(controller.prefectureCode, '27');
      expect(controller.area?.id, 1001);
      expect(controller.areas.map((a) => a.id), [1001]);
      expect(controller.searchResults, isEmpty);
    });

    test('không có kết quả thì searchFoundNothing', () async {
      await controller.searchAreas('zzz');
      expect(controller.searchFoundNothing, isTrue);
    });

    test('ô tìm trống thì không gọi server', () async {
      final before = dao.calls.length;
      await controller.searchAreas('   ');
      expect(dao.calls.length, before);
      expect(controller.searchResults, isEmpty);
      expect(controller.searchFoundNothing, isFalse);
    });

    test('câu trả lời của lần tìm cũ đến muộn bị bỏ qua', () async {
      dao.hold = Completer<void>();
      final old = controller.searchAreas('kita');
      final latest = controller.searchAreas('arakawa');
      dao.hold!.complete();
      await Future.wait([old, latest]);
      expect(controller.searchQuery, 'arakawa');
      expect(controller.searchResults.single.id, 679);
      expect(controller.isSearching, isFalse);
    });
  });

  group('Vị trí của tôi', () {
    setUp(() => controller.open());

    test('gợi ý khu vực gần nhất rồi dùng khu vực đó', () async {
      await controller.selectPrefecture('27');
      final future = controller.suggestNearest(35.736, 139.78);
      expect(controller.isLocating, isTrue);
      await future;
      expect(controller.isLocating, isFalse);
      expect(controller.suggested?.id, 679);

      await controller.useSuggested();
      expect(controller.prefectureCode, '13');
      expect(controller.area?.id, 679);
      expect(controller.suggested, isNull);
    });

    test('vị trí ngoài Nhật: hiện câu của server, không gợi ý', () async {
      await controller.suggestNearest(21.03, 105.85);
      expect(controller.suggested, isNull);
      expect(controller.locateMessage, 'Vị trí này không ở Nhật Bản. Hãy chọn một điểm ở Nhật.');
    });

    test('không lấy được vị trí thì báo nhẹ', () {
      controller.startLocating();
      expect(controller.isLocating, isTrue);
      controller.locationUnavailable();
      expect(controller.isLocating, isFalse);
      expect(controller.locateMessage, contains('Không lấy được vị trí'));
    });

    test('server thử có vị trí cố định thì Controller giữ nó cho màn hình', () async {
      dao.picker = const AreaPickerData(
        prefectures: [tokyo],
        devLocation: AreaDevLocation(lat: 35.73, lng: 139.77, label: 'Nippori'),
      );
      await controller.open();
      expect(controller.devLocation?.label, 'Nippori');
    });
  });

  group('lưu', () {
    setUp(() => controller.open());

    test('gửi khu vực và giai đoạn đang chọn, giữ câu của server', () async {
      controller.selectStage('PRE');
      await controller.selectPrefecture('27');
      controller.selectArea(1001);
      final future = controller.save();
      expect(controller.isSaving, isTrue);
      expect(await future, isTrue);
      expect(controller.isSaving, isFalse);
      expect(dao.savedAreaStages.single, (areaId: 1001, stage: 'PRE'));
      expect(controller.takeMessage(), 'Đã lưu khu vực và giai đoạn.');
      expect(controller.takeMessage(), isNull);
    });

    test('bỏ chọn cả hai thì gửi null', () async {
      controller.selectStage(null);
      controller.clearArea();
      expect(await controller.save(), isTrue);
      expect(dao.savedAreaStages.single, (areaId: null, stage: null));
    });

    test('giai đoạn không hợp lệ thì không gọi server', () async {
      controller.selectStage('XX');
      expect(await controller.save(), isFalse);
      expect(controller.fieldErrors['stage'], 'Giai đoạn không hợp lệ');
      expect(dao.calls, isNot(contains('updateAreaStage')));
      expect(AreaStageController.validate(stage: 'LEAVE'), isEmpty);
    });

    test('server từ chối: giữ câu lỗi và lỗi theo ô', () async {
      dao.failOn['updateAreaStage'] = const ApiException(
        'Khu vực không hợp lệ',
        statusCode: 400,
        fields: {'areaId': 'Khu vực không hợp lệ'},
      );
      expect(await controller.save(), isFalse);
      expect(controller.saveError, 'Khu vực không hợp lệ');
      expect(controller.fieldErrors['areaId'], 'Khu vực không hợp lệ');
      expect(controller.isSaving, isFalse);
    });
  });
}
