/// Thông tin cho form review (`GET /api/reviews/compose?placeId=` và phần `limits`, `quota` của
/// `GET /api/reviews/{id}/edit`): giới hạn nhập, lượt đăng hôm nay của tài khoản mới, review đã có của mình.
///
/// JSON: `{limits: {contentMin, contentMax, imagesMax, imageMaxMb, …}, quota: {newAccount, newAccountDays,
/// postsUsed, postsLimit, …}, myReviewId}`.
class ReviewCompose {
  const ReviewCompose({
    this.contentMin = 10,
    this.contentMax = 2000,
    this.imagesMax = 5,
    this.imageMaxMb = 20,
    this.newAccount = false,
    this.newAccountDays = 7,
    this.postsUsed = 0,
    this.postsLimit = 3,
    this.myReviewId,
  });

  final int contentMin;
  final int contentMax;
  final int imagesMax;
  final int imageMaxMb;

  /// Tài khoản dưới [newAccountDays] ngày chỉ được đăng [postsLimit] bài viết hoặc review mỗi ngày.
  final bool newAccount;
  final int newAccountDays;
  final int postsUsed;
  final int postsLimit;

  /// Review đã có của mình cho địa điểm này: form chuyển sang sửa review đó (mỗi người một review cho một nơi).
  final int? myReviewId;

  /// Số lượt đăng còn lại hôm nay (tài khoản mới).
  int get postsLeft => postsLimit - postsUsed < 0 ? 0 : postsLimit - postsUsed;

  factory ReviewCompose.fromJson(Map<String, dynamic> json) {
    final limits = (json['limits'] as Map<String, dynamic>?) ?? const {};
    final quota = (json['quota'] as Map<String, dynamic>?) ?? const {};
    return ReviewCompose(
      contentMin: (limits['contentMin'] ?? 10) as int,
      contentMax: (limits['contentMax'] ?? 2000) as int,
      imagesMax: (limits['imagesMax'] ?? 5) as int,
      imageMaxMb: (limits['imageMaxMb'] ?? 20) as int,
      newAccount: (quota['newAccount'] ?? false) as bool,
      newAccountDays: (quota['newAccountDays'] ?? 7) as int,
      postsUsed: (quota['postsUsed'] ?? 0) as int,
      postsLimit: (quota['postsLimit'] ?? 3) as int,
      myReviewId: json['myReviewId'] as int?,
    );
  }
}
