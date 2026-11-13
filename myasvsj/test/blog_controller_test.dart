// Unit test của BlogController: chạy với DAO giả (blog_fakes.dart), không cần server.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.controller/blog_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';

import 'blog_fakes.dart';

void main() {
  late FakeBlogDao dao;
  late BlogController controller;

  setUp(() {
    dao = FakeBlogDao();
    controller = BlogController(dao);
  });

  group('danh sách', () {
    test('loadBlogs lấy trang đầu và tắt trạng thái chờ', () async {
      final future = controller.loadBlogs();
      expect(controller.isLoading, isTrue);
      await future;
      expect(controller.isLoading, isFalse);
      expect(controller.blogs.map((b) => b.title), ['Thuê nhà ở Tokyo', 'Mở tài khoản ngân hàng']);
      expect(controller.totalItems, 2);
      expect(controller.hasMore, isFalse);
      expect(controller.error, isNull);
    });

    test('loadBlogs giữ câu báo lỗi của server', () async {
      dao.failWith = const ApiException('Không kết nối được tới server.');
      await controller.loadBlogs();
      expect(controller.error, 'Không kết nối được tới server.');
      expect(controller.blogs, isEmpty);
      expect(controller.isLoading, isFalse);
    });

    test('openList tải bài nổi bật và danh sách một lần', () async {
      await controller.openList();
      await controller.openList();
      expect(dao.calls.where((c) => c == 'findOverview'), hasLength(1));
      expect(dao.calls.where((c) => c.startsWith('findAll')), hasLength(1));
      expect(controller.overview?.featuredPeriod, 'WEEK');
      expect(controller.overview?.topics, hasLength(3));
    });

    test('tìm, lọc chủ đề, sắp xếp gửi đúng bộ lọc và luôn tải lại từ trang đầu', () async {
      await controller.search('  thuê nhà ');
      expect(dao.calls.last, 'findAll q=thuê nhà topics=[] sort=NEWEST page=0');
      expect(controller.blogs.single.id, 1);
      expect(controller.isFiltered, isTrue);

      await controller.clearFilters();
      await controller.toggleTopic(3);
      expect(dao.calls.last, 'findAll q= topics=[3] sort=NEWEST page=0');
      expect(controller.blogs.single.id, 2);

      await controller.toggleTopic(3);
      expect(controller.filterTopicIds, isEmpty);
      expect(controller.isFiltered, isFalse);

      await controller.setSort('LIKES');
      expect(dao.calls.last, 'findAll q= topics=[] sort=LIKES page=0');
      await controller.setSort('SAI');
      expect(controller.sort, 'LIKES');

      await controller.filterByTopic(1);
      expect(controller.filterTopicIds, {1});
    });

    test('tìm lại đúng từ khóa cũ thì không gọi server', () async {
      await controller.search('tokyo');
      final count = dao.calls.length;
      await controller.search(' tokyo ');
      expect(dao.calls, hasLength(count));
    });

    test('loadMore nối trang sau, hết trang thì thôi', () async {
      dao.pageSize = 1;
      await controller.loadBlogs();
      expect(controller.blogs, hasLength(1));
      expect(controller.hasMore, isTrue);

      await controller.loadMore();
      expect(controller.blogs.map((b) => b.id), [1, 2]);
      expect(controller.hasMore, isFalse);
      expect(dao.calls.last, endsWith('page=1'));

      final count = dao.calls.length;
      await controller.loadMore();
      expect(dao.calls, hasLength(count));
    });

    test('loadMore lỗi giữ danh sách cũ và câu lỗi riêng', () async {
      dao.pageSize = 1;
      await controller.loadBlogs();
      dao.failWith = const ApiException('Server phản hồi quá lâu. Hãy thử lại.');
      await controller.loadMore();
      expect(controller.blogs, hasLength(1));
      expect(controller.loadMoreError, 'Server phản hồi quá lâu. Hãy thử lại.');
      expect(controller.error, isNull);
    });
  });

  group('chi tiết', () {
    test('loadBlog giữ bài theo id, hai bài mở chồng không lẫn nhau', () async {
      final future = controller.loadBlog(1);
      expect(controller.isLoadingBlog(1), isTrue);
      await future;
      await controller.loadBlog(2);
      expect(controller.isLoadingBlog(1), isFalse);
      expect(controller.blogById(1)?.title, 'Thuê nhà ở Tokyo');
      expect(controller.blogById(2)?.title, 'Mở tài khoản ngân hàng');
      expect(controller.blogById(1)?.comments.single.replies.single.content, 'Mình cũng thấy vậy.');
    });

    test('loadBlog lỗi 404 giữ câu của server cho đúng bài', () async {
      await controller.loadBlog(99);
      expect(controller.blogById(99), isNull);
      expect(controller.blogError(99), startsWith('Không tìm thấy nội dung'));
      expect(controller.blogError(1), isNull);
    });

    test('thích bài: đổi ngay trên màn hình rồi lấy số của server, cập nhật cả danh sách', () async {
      await controller.loadBlogs();
      await controller.loadBlog(1);
      dao.hold = Completer<void>();
      final future = controller.toggleLike(1);
      expect(controller.blogById(1)?.isLiked, isTrue);
      expect(controller.blogById(1)?.likeCount, 4);
      dao.hold!.complete();
      await future;
      expect(dao.calls.last, 'like 1');
      expect(controller.blogById(1)?.likeCount, 4);
      expect(controller.blogs.first.likeCount, 4);

      await controller.toggleLike(1);
      expect(dao.calls.last, 'unlike 1');
      expect(controller.blogById(1)?.isLiked, isFalse);
      expect(controller.blogById(1)?.likeCount, 3);
    });

    test('thích bài bị server từ chối thì trả lại như cũ và giữ câu lỗi', () async {
      await controller.loadBlog(1);
      dao.writeError = const ApiException('Bạn không thể thích bài viết của chính mình.', statusCode: 400);
      await controller.toggleLike(1);
      expect(controller.blogById(1)?.isLiked, isFalse);
      expect(controller.blogById(1)?.likeCount, 3);
      expect(controller.takeMessage(), 'Bạn không thể thích bài viết của chính mình.');
    });

    test('lưu, bỏ lưu bài hiện câu của server; lỗi thì trả lại', () async {
      await controller.loadBlog(1);
      await controller.toggleSave(1);
      expect(controller.blogById(1)?.isSaved, isTrue);
      expect(controller.takeMessage(), 'Đã lưu bài viết.');

      dao.writeError = const ApiException('Bạn cần đăng nhập để làm việc này.', statusCode: 401);
      await controller.toggleSave(1);
      expect(controller.blogById(1)?.isSaved, isTrue);
      expect(controller.takeMessage(), 'Bạn cần đăng nhập để làm việc này.');
    });

    test('báo cáo bài gửi lý do và ghi chú', () async {
      expect(await controller.reportBlog(1, reasonId: 4, note: 'spam'), isTrue);
      expect(dao.calls.last, 'report 1 reason=4 note=spam');
      expect(controller.takeMessage(), 'Cảm ơn bạn. Báo cáo đã được gửi.');

      dao.writeError = const ApiException('Bạn đã báo cáo nội dung này rồi.', statusCode: 400);
      expect(await controller.reportBlog(1, reasonId: 4), isFalse);
      expect(controller.takeMessage(), 'Bạn đã báo cáo nội dung này rồi.');
    });

    test('bình luận trống không gọi server', () async {
      await controller.loadBlog(1);
      expect(await controller.addComment(1, '   '), isFalse);
      expect(controller.commentError, 'Hãy viết nội dung bình luận.');
      expect(await controller.addComment(1, 'a' * 2001), isFalse);
      expect(controller.commentError, 'Bình luận tối đa 2.000 ký tự.');
      expect(dao.calls.where((c) => c.startsWith('addComment')), isEmpty);
    });

    test('bình luận và trả lời: bài mới của server thay bài cũ', () async {
      await controller.loadBlog(1);
      final future = controller.addComment(1, ' Hay quá ');
      expect(controller.isSendingComment, isTrue);
      expect(await future, isTrue);
      expect(controller.isSendingComment, isFalse);
      expect(controller.blogById(1)?.comments.last.content, 'Hay quá');
      expect(controller.takeMessage(), 'Đã đăng bình luận.');

      expect(await controller.addComment(1, 'Trả lời', parentId: 10), isTrue);
      expect(dao.calls.last, 'addComment 1 parent=10');
      expect(controller.blogById(1)?.comments.first.replies.last.content, 'Trả lời');
    });

    test('bình luận quá nhanh: giữ câu của server dưới ô bình luận', () async {
      await controller.loadBlog(1);
      dao.writeError = const ApiException('Bạn bình luận hơi nhanh. Vui lòng đợi 7 giây rồi thử lại.', statusCode: 429);
      expect(await controller.addComment(1, 'Lần hai'), isFalse);
      expect(controller.commentError, 'Bạn bình luận hơi nhanh. Vui lòng đợi 7 giây rồi thử lại.');
      controller.clearCommentError();
      expect(controller.commentError, isNull);
    });

    test('thích bình luận lồng: đổi ngay, lỗi thì trả lại', () async {
      await controller.loadBlog(1);
      dao.hold = Completer<void>();
      final future = controller.toggleCommentLike(1, 10);
      expect(controller.blogById(1)?.comments.first.liked, isTrue);
      expect(controller.blogById(1)?.comments.first.likeCount, 3);
      dao.hold!.complete();
      await future;
      expect(dao.calls.last, 'likeComment 10');

      dao.hold = null;
      dao.writeError = const ApiException('Bạn không thể thích bình luận của chính mình.', statusCode: 400);
      await controller.toggleCommentLike(1, 11);
      final reply = controller.blogById(1)!.comments.first.replies.first;
      expect(reply.liked, isFalse);
      expect(reply.likeCount, 0);
      expect(controller.takeMessage(), 'Bạn không thể thích bình luận của chính mình.');
    });

    test('sửa, xóa, báo cáo bình luận cập nhật bài và giữ câu thông báo', () async {
      await controller.loadBlog(1);
      expect(await controller.updateComment(1, 11, ' Đã sửa '), isTrue);
      expect(dao.calls.last, 'updateComment 11 Đã sửa');
      expect(controller.takeMessage(), 'Đã lưu bình luận.');

      expect(await controller.updateComment(1, 11, ''), isFalse);
      expect(controller.takeMessage(), 'Hãy viết nội dung bình luận.');

      expect(await controller.reportComment(1, 10, reasonId: 1), isTrue);
      expect(controller.takeMessage(), 'Cảm ơn bạn. Báo cáo đã được gửi.');

      expect(await controller.deleteComment(1, 11), isTrue);
      expect(controller.blogById(1)?.comments.first.replies, isEmpty);
      expect(controller.takeMessage(), 'Đã xóa bình luận.');
    });

    test('xóa bài bỏ bài khỏi danh sách và chi tiết', () async {
      await controller.loadBlogs();
      await controller.loadBlog(1);
      expect(await controller.deleteBlog(1), isTrue);
      expect(controller.blogs.map((b) => b.id), [2]);
      expect(controller.totalItems, 1);
      expect(controller.blogById(1), isNull);
      expect(controller.takeMessage(), 'Đã xóa bài viết.');
      expect(controller.takeMessage(), isNull);
    });
  });

  group('form', () {
    test('openForm lấy chủ đề; khi sửa lấy thêm bài như đang lưu', () async {
      await controller.openForm();
      expect(controller.topics.map((t) => t.name), ['Nhà ở', 'Cảnh báo lừa đảo', 'Khác']);
      expect(controller.editing, isNull);

      await controller.openForm(blogId: 1);
      expect(controller.editing?.title, 'Thuê nhà ở Tokyo');
      expect(controller.editing?.places.single.name, 'Ga Nippori');
    });

    test('openForm lỗi (khách, staff) giữ câu của server', () async {
      dao.failWith = const ApiException('Bạn cần đăng nhập để viết bài.', statusCode: 401);
      await controller.openForm();
      expect(controller.composeOptions, isNull);
      expect(controller.formError, 'Bạn cần đăng nhập để viết bài.');
      expect(controller.isLoadingForm, isFalse);
    });

    test('saveBlog không gọi server khi thiếu tiêu đề, nội dung hoặc chủ đề', () async {
      await controller.openForm();
      final saved = await controller.saveBlog(title: '   ', content: '', topicIds: []);
      expect(saved, isFalse);
      expect(controller.fieldErrors.keys, containsAll(['title', 'content', 'topicIds']));
      expect(controller.formError, 'Hãy nhập tiêu đề và nội dung cho bài viết.');
      expect(dao.created, isEmpty);
    });

    test('validate theo BlogWriteRules', () {
      final errors = BlogController.validate(
        title: 'a' * 151,
        content: 'b' * 5001,
        topicIds: [1, 2, 3, 4],
        placeCount: 6,
        imageCount: 6,
      );
      expect(errors['title'], 'Tiêu đề tối đa 150 ký tự.');
      expect(errors['content'], 'Nội dung tối đa 5.000 ký tự.');
      expect(errors['topicIds'], 'Chọn tối đa 3 chủ đề.');
      expect(errors['placeIds'], 'Chọn tối đa 5 địa điểm.');
      expect(errors['images'], startsWith('Tối đa 5 ảnh'));
      expect(BlogController.summaryOf(errors), 'Tiêu đề tối đa 150 ký tự.');
      expect(BlogController.validate(title: 'Visa', content: 'Gia hạn', topicIds: [3]), isEmpty);
    });

    test('saveBlog tạo bài mới kèm địa điểm và ảnh, rồi tải lại danh sách', () async {
      await controller.openForm();
      final future = controller.saveBlog(
        title: ' Hỏi   về visa ',
        content: ' Gia hạn thế nào? ',
        topicIds: [3],
        places: const [nippori],
        imagePaths: const ['/tmp/a.jpg'],
      );
      expect(controller.isSaving, isTrue);
      expect(await future, isTrue);
      expect(controller.isSaving, isFalse);
      final sent = dao.created.single;
      expect(sent.blog.title, 'Hỏi về visa');
      expect(sent.blog.content, 'Gia hạn thế nào?');
      expect(sent.blog.toJson()['placeIds'], [1]);
      expect(sent.blog.toJson().containsKey('keepMediaIds'), isFalse);
      expect(sent.imagePaths, ['/tmp/a.jpg']);
      expect(controller.blogs.first.title, 'Hỏi về visa');
      expect(controller.blogs.first.isProcessing, isTrue);
      expect(controller.takeMessage(), startsWith('Đã gửi. Ảnh và video đang được quét'));
    });

    test('saveBlog khi sửa: giữ ảnh cũ đã chọn (keepMediaIds) và thêm ảnh mới', () async {
      dao.stored[0] = sampleBlog(
        mine: true,
        media: const [
          MediaItem(id: 17, type: 'IMAGE', url: '/media/a.jpg'),
          MediaItem(id: 18, type: 'IMAGE', url: '/media/b.jpg'),
        ],
      );
      await controller.openForm(blogId: 1);
      await controller.loadBlog(1);
      final kept = controller.editing!.media.where((m) => m.id == 18).toList();
      final saved = await controller.saveBlog(
        title: 'Thuê nhà ở Tokyo (sửa)',
        content: 'Nội dung mới',
        topicIds: [1],
        places: controller.editing!.places,
        keptMedia: kept,
        imagePaths: const ['/tmp/c.jpg'],
      );
      expect(saved, isTrue);
      final sent = dao.updated.single;
      expect(sent.blog.id, 1);
      expect(sent.blog.toJson()['keepMediaIds'], [18]);
      expect(sent.blog.toJson()['placeIds'], [1]);
      expect(sent.imagePaths, ['/tmp/c.jpg']);
      expect(controller.takeMessage(), 'Đã lưu thay đổi.');
      // Màn chi tiết đang mở được tải lại
      expect(controller.blogById(1)?.title, 'Thuê nhà ở Tokyo (sửa)');
    });

    test('saveBlog hiện lỗi theo từng ô mà server trả về', () async {
      await controller.openForm();
      dao.writeError = const ApiException(
        'Nội dung chứa từ ngữ không phù hợp.',
        statusCode: 400,
        fields: {'content': 'Nội dung chứa từ ngữ không phù hợp.'},
      );
      final saved = await controller.saveBlog(title: 'Tiêu đề', content: 'abc', topicIds: [1]);
      expect(saved, isFalse);
      expect(controller.formError, 'Nội dung chứa từ ngữ không phù hợp.');
      expect(controller.fieldErrors['content'], 'Nội dung chứa từ ngữ không phù hợp.');
      expect(controller.isSaving, isFalse);
    });

    test('tìm địa điểm: kết quả, không có gì, lỗi, xóa kết quả', () async {
      await controller.searchPlaces(' nippori ');
      expect(dao.calls.last, 'searchPlaces nippori');
      expect(controller.placeResults.map((p) => p.name), ['Bưu điện Nippori', 'Ga Ueno']);
      expect(controller.placeResults.last.isNew, isTrue);

      await controller.searchPlaces('không có');
      expect(controller.placeError, 'Không tìm thấy địa điểm nào.');

      dao.failWith = const ApiException('Bạn cần đăng nhập để tìm địa điểm.', statusCode: 401);
      await controller.searchPlaces('ueno');
      expect(controller.placeError, 'Bạn cần đăng nhập để tìm địa điểm.');
      expect(controller.isSearchingPlaces, isFalse);

      controller.clearPlaceResults();
      expect(controller.placeResults, isEmpty);
      expect(controller.placeError, isNull);
    });
  });
}
