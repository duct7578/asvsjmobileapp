/// Bốn loại mục trên "Đã lưu", đúng thứ tự của trang web. Mỗi loại lưu / bỏ lưu bằng API của chính nó
/// (xem SavedDao).
enum SavedKind {
  /// Địa điểm trên Bản đồ (bảng `saved_places`).
  place,

  /// Bài viết Blog (`blogs.blog_type` = POST).
  post,

  /// Câu hỏi Hỏi-Đáp (`blogs.blog_type` = QA).
  question,

  /// Cẩm nang (bảng `saved_guides`).
  guide,
}
