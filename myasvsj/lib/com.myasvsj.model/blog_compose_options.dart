import 'package:myasvsj/com.myasvsj.model/topic.dart';

/// Những gì form "Viết bài" cần (`GET /api/blogs/compose`, ComposeOptions của web): chủ đề, giới hạn nhập,
/// lượt đăng hôm nay của tài khoản mới, và người viết có được chèn link không (BR-22).
class BlogComposeOptions {
  const BlogComposeOptions({
    this.topics = const [],
    this.scamWarningTopicIds = const {},
    this.titleMax = 150,
    this.contentMax = 5000,
    this.topicsMax = 3,
    this.placesMax = 5,
    this.imagesMax = 5,
    this.imageMaxMb = 20,
    this.newAccount = false,
    this.postsUsed = 0,
    this.postsLimit = 0,
    this.canPostLinks = false,
  });

  final List<Topic> topics;

  /// Chủ đề "Cảnh báo lừa đảo": địa điểm gắn với bài này hiện dấu "!" trên bản đồ.
  final Set<int> scamWarningTopicIds;

  final int titleMax;
  final int contentMax;
  final int topicsMax;
  final int placesMax;
  final int imagesMax;
  final int imageMaxMb;

  /// Tài khoản mới (vài ngày đầu) bị giới hạn số bài mỗi ngày: đã đăng [postsUsed] / [postsLimit].
  final bool newAccount;
  final int postsUsed;
  final int postsLimit;

  /// Có tag định danh nên được chèn link, số điện thoại, ảnh có mã QR.
  final bool canPostLinks;

  /// Tài khoản mới đã dùng hết lượt đăng hôm nay.
  bool get quotaFull => newAccount && postsUsed >= postsLimit;

  factory BlogComposeOptions.fromJson(Map<String, dynamic> json) {
    final topics = [for (final t in (json['topics'] as List?) ?? const []) t as Map<String, dynamic>];
    final limits = (json['limits'] as Map<String, dynamic>?) ?? const {};
    final quota = (json['quota'] as Map<String, dynamic>?) ?? const {};
    return BlogComposeOptions(
      topics: [for (final t in topics) Topic.fromJson(t)],
      scamWarningTopicIds: {
        for (final t in topics)
          if (t['scamWarning'] == true) t['id'] as int,
      },
      titleMax: (limits['titleMax'] ?? 150) as int,
      contentMax: (limits['contentMax'] ?? 5000) as int,
      topicsMax: (limits['topicsMax'] ?? 3) as int,
      placesMax: (limits['placesMax'] ?? 5) as int,
      imagesMax: (limits['imagesMax'] ?? 5) as int,
      imageMaxMb: (limits['imageMaxMb'] ?? 20) as int,
      newAccount: (quota['newAccount'] ?? false) as bool,
      postsUsed: (quota['postsUsed'] ?? 0) as int,
      postsLimit: (quota['postsLimit'] ?? 0) as int,
      canPostLinks: (json['canPostLinks'] ?? false) as bool,
    );
  }
}
