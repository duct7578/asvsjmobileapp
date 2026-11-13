// Unit test của TagRequestController (Xin tag định danh) với DAO giả, không cần server.
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/tag_request_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/tag_compose.dart';
import 'package:myasvsj/com.myasvsj.model/tag_pending_request.dart';

import 'profile_fakes.dart';

void main() {
  late FakeProfileDao dao;
  late TagRequestController controller;

  setUp(() {
    dao = FakeProfileDao();
    controller = TagRequestController(dao);
  });

  test('open lấy danh sách tag, chưa có yêu cầu chờ', () async {
    final future = controller.open();
    expect(controller.isLoading, isTrue);
    await future;
    expect(controller.isLoading, isFalse);
    expect(controller.compose?.tags.map((t) => t.name), ['Kouhai', 'Mentor', 'Người Nhật']);
    expect(controller.pending, isNull);
  });

  test('open giữ câu báo lỗi của server', () async {
    dao.failWith = const ApiException('Không kết nối được tới server.');
    await controller.open();
    expect(controller.error, 'Không kết nối được tới server.');
    expect(controller.compose, isNull);
  });

  test('có yêu cầu đang chờ thì pending khác null', () async {
    dao.compose = const TagCompose(
      tags: [mentorTag],
      pending: TagPendingRequest(tagName: 'Mentor'),
    );
    await controller.open();
    expect(controller.pending?.tagName, 'Mentor');
  });

  test('tag đã có không chọn được; đổi tag thì bỏ loại minh chứng đã chọn', () async {
    await controller.open();
    controller.selectTag(1);
    expect(controller.tagId, isNull);

    controller.selectTag(2);
    controller.selectProofType(8);
    expect(controller.selectedTag?.name, 'Mentor');
    controller.selectTag(5);
    expect(controller.selectedTag?.selfieOnly, isTrue);
    expect(controller.proofTypeId, isNull);
  });

  test('gửi khi chưa nhập gì thì không gọi server, có lỗi theo từng ô', () async {
    await controller.open();
    expect(await controller.submit(), isFalse);
    expect(controller.fieldErrors, {
      'tagId': 'Hãy chọn một tag.',
      'photo': 'Hãy chọn ảnh minh chứng.',
      'consent': 'Bạn cần đồng ý cho Kiểm duyệt viên xem ảnh.',
    });
    expect(controller.formError, 'Hãy chọn một tag.');
    expect(dao.calls, isNot(contains('submitTagRequest')));
  });

  test('tag cần minh chứng mà chưa chọn loại thì báo lỗi; tag chân dung thì không cần', () {
    expect(TagRequestController.validate(tag: mentorTag, proofTypeId: null, photoPath: 'a.jpg', consent: true), {
      'proofTypeId': 'Hãy chọn loại minh chứng.',
    });
    expect(
      TagRequestController.validate(tag: mentorTag, proofTypeId: 99, photoPath: 'a.jpg', consent: true),
      {'proofTypeId': 'Hãy chọn loại minh chứng.'},
      reason: 'loại minh chứng phải thuộc tag đã chọn',
    );
    expect(TagRequestController.validate(tag: japaneseTag, proofTypeId: null, photoPath: null, consent: true), {
      'photo': 'Hãy chọn ảnh chân dung.',
    });
    expect(
      TagRequestController.validate(tag: japaneseTag, proofTypeId: null, photoPath: 'a.jpg', consent: true),
      isEmpty,
    );
  });

  test('gửi đủ thông tin: gọi server, có yêu cầu đang chờ, xóa form', () async {
    await controller.open();
    controller.selectTag(2);
    controller.selectProofType(7);
    controller.setPhotos(['/tmp/a.jpg', '/tmp/b.jpg']);
    expect(controller.photoPaths, ['/tmp/a.jpg'], reason: 'chỉ một ảnh');
    controller.setConsent(true);

    final future = controller.submit();
    expect(controller.isSubmitting, isTrue);
    expect(await future, isTrue);
    expect(controller.isSubmitting, isFalse);

    final sent = dao.submitted.single;
    expect(sent.tagId, 2);
    expect(sent.proofTypeId, 7);
    expect(sent.consent, isTrue);
    expect(sent.photoPath, '/tmp/a.jpg');
    expect(sent.toJson(), {'tagId': 2, 'proofTypeId': 7, 'consent': true});
    expect(controller.pending?.tagName, 'Mentor');
    expect(controller.tagId, isNull);
    expect(controller.takeMessage(), 'Đã gửi yêu cầu tag.');
  });

  test('tag chân dung gửi proofTypeId null (server tự chọn)', () async {
    await controller.open();
    controller.selectTag(5);
    controller.setPhotos(['/tmp/me.jpg']);
    controller.setConsent(true);
    expect(await controller.submit(), isTrue);
    expect(dao.submitted.single.proofTypeId, isNull);
  });

  test('server từ chối: giữ câu lỗi và lỗi theo ô, không mất lựa chọn', () async {
    await controller.open();
    controller.selectTag(2);
    controller.selectProofType(7);
    controller.setPhotos(['/tmp/a.jpg']);
    controller.setConsent(true);
    dao.failOn['submitTagRequest'] = const ApiException('Bạn đang có một yêu cầu tag chờ duyệt.', statusCode: 409);
    expect(await controller.submit(), isFalse);
    expect(controller.formError, 'Bạn đang có một yêu cầu tag chờ duyệt.');
    expect(controller.pending, isNull);
    expect(controller.tagId, 2);

    dao.failOn['submitTagRequest'] = const ApiException(
      'Ảnh phải là JPG, PNG hoặc HEIC và không quá 20 MB.',
      statusCode: 400,
      fields: {'photo': 'Ảnh phải là JPG, PNG hoặc HEIC và không quá 20 MB.'},
    );
    expect(await controller.submit(), isFalse);
    expect(controller.fieldErrors['photo'], startsWith('Ảnh phải là JPG'));
  });

  test('sửa một ô thì lỗi của ô đó biến mất', () async {
    await controller.open();
    await controller.submit();
    controller.setConsent(true);
    expect(controller.fieldErrors.containsKey('consent'), isFalse);
    controller.selectTag(2);
    expect(controller.fieldErrors.containsKey('tagId'), isFalse);
    controller.setPhotos(['/tmp/a.jpg']);
    expect(controller.fieldErrors.containsKey('photo'), isFalse);
  });
}
