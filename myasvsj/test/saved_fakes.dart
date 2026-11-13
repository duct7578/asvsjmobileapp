import 'dart:async';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/saved_blog.dart';
import 'package:myasvsj/com.myasvsj.model/saved_dao.dart';
import 'package:myasvsj/com.myasvsj.model/saved_guide.dart';
import 'package:myasvsj/com.myasvsj.model/saved_item.dart';
import 'package:myasvsj/com.myasvsj.model/saved_kind.dart';
import 'package:myasvsj/com.myasvsj.model/saved_list.dart';
import 'package:myasvsj/com.myasvsj.model/saved_place.dart';
import 'package:myasvsj/com.myasvsj.model/topic.dart';

const nippori = SavedPlace(
  id: 1,
  name: 'Ga Nippori',
  categoryId: 'station',
  categoryName: 'Ga tàu',
  icon: 'train',
  address: 'Higashi-Nippori 6, Arakawa, Tokyo',
);
const ward = SavedPlace(id: 6, name: 'Văn phòng quận Arakawa', categoryName: 'Văn phòng quận', closed: true);
const tokyoPost = SavedBlog(
  id: 1,
  title: 'Năm điều mình ước biết trước tuần đầu ở Tokyo',
  authorName: 'Lan Anh',
  topics: [Topic(id: 1, name: 'Kinh nghiệm')],
  likeCount: 24,
);
const simQuestion = SavedBlog(
  id: 6,
  type: 'QA',
  title: 'Mua SIM data giá rẻ ở đâu gần Nippori ạ?',
  authorName: 'Trần Minh',
  topics: [Topic(id: 11, name: 'Mua sắm')],
  likeCount: 3,
  solved: true,
);
const trashGuide = SavedGuide(
  id: 24,
  title: 'Cách phân loại và bỏ rác tại Nhật Bản',
  summary: 'Phân loại và bỏ rác đúng quy định…',
  stageName: 'Khi mới đến (tuần đầu đến 3 tháng)',
  topicName: 'Sinh hoạt',
);

/// Đã lưu mẫu: 2 địa điểm, 1 bài viết, 1 câu hỏi, 1 cẩm nang.
const sampleSaved = SavedList({
  SavedKind.place: [nippori, ward],
  SavedKind.post: [tokyoPost],
  SavedKind.question: [simQuestion],
  SavedKind.guide: [trashGuide],
});

/// DAO giả của "Đã lưu": giữ danh sách trong bộ nhớ thay vì gọi server.
class FakeSavedDao implements SavedDao {
  FakeSavedDao([this.stored = sampleSaved]);

  SavedList stored;

  /// Các lần bỏ lưu / lưu lại đã nhận: (loại, id).
  final List<(SavedKind, int)> unsaved = [];
  final List<(SavedKind, int)> resaved = [];

  /// Đặt khác null để mọi lần gọi đều lỗi như server từ chối.
  ApiException? failWith;

  /// Chỉ bỏ lưu / lưu lại bị lỗi (tải danh sách vẫn được).
  ApiException? failWrites;

  /// Đặt khác null để lời gọi chờ tới khi test complete() (xem trạng thái chờ).
  Completer<void>? hold;

  @override
  Future<SavedList> findAll() async {
    await hold?.future;
    if (failWith != null) {
      throw failWith!;
    }
    return stored;
  }

  @override
  Future<String> unsave(SavedKind kind, int id) async {
    await hold?.future;
    final error = failWrites ?? failWith;
    if (error != null) {
      throw error;
    }
    unsaved.add((kind, id));
    final item = stored.itemsOf(kind).where((x) => x.id == id);
    if (item.isNotEmpty) {
      stored = stored.without(item.first);
    }
    return _message('Đã bỏ lưu', kind);
  }

  @override
  Future<String> save(SavedKind kind, int id) async {
    await hold?.future;
    final error = failWrites ?? failWith;
    if (error != null) {
      throw error;
    }
    resaved.add((kind, id));
    return _message('Đã lưu', kind);
  }

  static String _message(String verb, SavedKind kind) => switch (kind) {
    SavedKind.place => '$verb địa điểm.',
    SavedKind.post => '$verb bài viết.',
    SavedKind.question => '$verb câu hỏi.',
    SavedKind.guide => '$verb cẩm nang.',
  };

  /// Tiện cho test: mục [id] của loại [kind] còn trong danh sách đang lưu không.
  bool contains(SavedKind kind, int id) => stored.itemsOf(kind).any((SavedItem x) => x.id == id);
}
