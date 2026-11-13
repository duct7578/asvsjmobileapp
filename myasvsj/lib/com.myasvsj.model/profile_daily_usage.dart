/// Số bài, ghim, video đã đăng hôm nay (giờ Nhật) so với hạn mức của tài khoản mới.
///
/// JSON: `{posts, maxPosts, pins, maxPins, videos, maxVideos}` (DailyUsage của `GET /api/me/profile`).
class ProfileDailyUsage {
  const ProfileDailyUsage({
    this.posts = 0,
    this.maxPosts = 0,
    this.pins = 0,
    this.maxPins = 0,
    this.videos = 0,
    this.maxVideos = 0,
  });

  /// Bài viết và review.
  final int posts;
  final int maxPosts;
  final int pins;
  final int maxPins;
  final int videos;
  final int maxVideos;

  factory ProfileDailyUsage.fromJson(Map<String, dynamic>? json) => ProfileDailyUsage(
    posts: (json?['posts'] ?? 0) as int,
    maxPosts: (json?['maxPosts'] ?? 0) as int,
    pins: (json?['pins'] ?? 0) as int,
    maxPins: (json?['maxPins'] ?? 0) as int,
    videos: (json?['videos'] ?? 0) as int,
    maxVideos: (json?['maxVideos'] ?? 0) as int,
  );
}
