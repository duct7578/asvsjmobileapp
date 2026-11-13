/// Một giai đoạn (bảng `guide_stages`, ví dụ PRE "Trước khi đi") hoặc một chủ đề (bảng `guide_topics`,
/// ví dụ HOUSING "Nhà ở") để lọc cẩm nang. Mã lấy từ server, app không tự đặt.
///
/// JSON: `{code, title}` của `GET /api/guides/topics` (giai đoạn) và `GET /api/guides/subjects` (chủ đề).
class GuideOption {
  const GuideOption({required this.code, required this.title});

  final String code;
  final String title;

  factory GuideOption.fromJson(Map<String, dynamic> json) =>
      GuideOption(code: (json['code'] ?? '') as String, title: (json['title'] ?? '') as String);
}
