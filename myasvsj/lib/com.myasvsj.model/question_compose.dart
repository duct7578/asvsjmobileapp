import 'package:myasvsj/com.myasvsj.model/topic.dart';

/// Lựa chọn và luật của form "Đặt câu hỏi" (ComposeOptions của `GET /api/questions/compose`, cũng nằm trong
/// `options` của `GET /api/questions/{id}/edit`). Server vẫn kiểm tra lại khi gửi.
///
/// JSON: `{topics: [{id, name, other, scamWarning}], limits: {titleMax, contentMax, topicsMax, imagesMax, imageMaxMb,
/// questionContentRequired, …}, quota: {newAccount, postsUsed, postsLimit, …}, canPostLinks}`.
class QuestionCompose {
  const QuestionCompose({
    this.topics = const [],
    this.titleMax = 150,
    this.contentMax = 5000,
    this.topicsMax = 3,
    this.imagesMax = 5,
    this.imageMaxMb = 20,
    this.contentRequired = false,
    this.newAccount = false,
    this.postsUsed = 0,
    this.postsLimit = 0,
    this.canPostLinks = false,
  });

  final List<Topic> topics;
  final int titleMax;
  final int contentMax;
  final int topicsMax;
  final int imagesMax;
  final int imageMaxMb;

  /// Câu hỏi có bắt buộc mô tả chi tiết không (hiện tại server để không bắt buộc).
  final bool contentRequired;

  /// Tài khoản mới (BR-07): giới hạn số bài mỗi ngày; [postsUsed]/[postsLimit] là lượt đã dùng hôm nay.
  final bool newAccount;
  final int postsUsed;
  final int postsLimit;

  /// Có tag định danh nên được chèn link (BR-22).
  final bool canPostLinks;

  factory QuestionCompose.fromJson(Map<String, dynamic> json) {
    final limits = (json['limits'] as Map<String, dynamic>?) ?? const {};
    final quota = (json['quota'] as Map<String, dynamic>?) ?? const {};
    return QuestionCompose(
      topics: [for (final t in (json['topics'] as List?) ?? const []) Topic.fromJson(t as Map<String, dynamic>)],
      titleMax: (limits['titleMax'] ?? 150) as int,
      contentMax: (limits['contentMax'] ?? 5000) as int,
      topicsMax: (limits['topicsMax'] ?? 3) as int,
      imagesMax: (limits['imagesMax'] ?? 5) as int,
      imageMaxMb: (limits['imageMaxMb'] ?? 20) as int,
      contentRequired: (limits['questionContentRequired'] ?? false) as bool,
      newAccount: (quota['newAccount'] ?? false) as bool,
      postsUsed: (quota['postsUsed'] ?? 0) as int,
      postsLimit: (quota['postsLimit'] ?? 0) as int,
      canPostLinks: (json['canPostLinks'] ?? false) as bool,
    );
  }
}
