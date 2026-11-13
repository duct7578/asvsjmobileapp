import 'package:myasvsj/com.myasvsj.model/saved_kind.dart';

/// Phần chung của một mục trên "Đã lưu": SavedPlace, SavedBlog hoặc SavedGuide.
abstract interface class SavedItem {
  /// Id của địa điểm, bài viết, câu hỏi hoặc cẩm nang (không phải id của lần lưu).
  int get id;

  SavedKind get kind;

  /// Lúc lưu; danh sách xếp mới lưu trước.
  DateTime? get savedAt;
}
