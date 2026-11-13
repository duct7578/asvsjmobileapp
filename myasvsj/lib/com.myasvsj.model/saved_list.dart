import 'package:myasvsj/com.myasvsj.model/saved_blog.dart';
import 'package:myasvsj/com.myasvsj.model/saved_guide.dart';
import 'package:myasvsj/com.myasvsj.model/saved_item.dart';
import 'package:myasvsj/com.myasvsj.model/saved_kind.dart';
import 'package:myasvsj/com.myasvsj.model/saved_place.dart';

/// Toàn bộ "Đã lưu" của người dùng, mỗi loại một danh sách, mới lưu trước (SavedResponse của `GET /api/me/saved`).
///
/// JSON: `{places: [...], posts: [...], questions: [...], guides: [...], counts: {...}}`. Số mục mỗi loại đếm lại
/// từ danh sách, để vẫn đúng sau khi bỏ lưu trên app.
class SavedList {
  const SavedList([this._items = const {}]);

  final Map<SavedKind, List<SavedItem>> _items;

  /// Các mục của một loại, mới lưu trước.
  List<SavedItem> itemsOf(SavedKind kind) => _items[kind] ?? const [];

  int countOf(SavedKind kind) => itemsOf(kind).length;

  int get total => SavedKind.values.fold(0, (sum, kind) => sum + countOf(kind));

  bool get isEmpty => total == 0;

  /// Vị trí của [item] trong danh sách loại của nó; -1 khi không có.
  int indexOf(SavedItem item) => itemsOf(item.kind).indexWhere((x) => x.id == item.id);

  /// Bản sao đã bỏ [item].
  SavedList without(SavedItem item) => SavedList({
    for (final kind in SavedKind.values)
      kind: kind == item.kind
          ? [
              for (final x in itemsOf(kind))
                if (x.id != item.id) x,
            ]
          : itemsOf(kind),
  });

  /// Bản sao đã thêm lại [item] vào vị trí [index] (bỏ lưu bị lỗi, hoặc "Hoàn tác").
  SavedList withItemAt(SavedItem item, int index) {
    final list = [
      for (final x in itemsOf(item.kind))
        if (x.id != item.id) x,
    ];
    list.insert(index.clamp(0, list.length), item);
    return SavedList({for (final kind in SavedKind.values) kind: kind == item.kind ? list : itemsOf(kind)});
  }

  factory SavedList.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> rows(String key) => [
      for (final row in (json[key] as List?) ?? const []) row as Map<String, dynamic>,
    ];
    return SavedList({
      SavedKind.place: [for (final row in rows('places')) SavedPlace.fromJson(row)],
      SavedKind.post: [for (final row in rows('posts')) SavedBlog.fromJson(row)],
      SavedKind.question: [for (final row in rows('questions')) SavedBlog.fromJson(row)],
      SavedKind.guide: [for (final row in rows('guides')) SavedGuide.fromJson(row)],
    });
  }
}
