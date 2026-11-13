import 'package:myasvsj/com.myasvsj.model/event.dart';
import 'package:myasvsj/com.myasvsj.model/event_review.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';

/// Dữ liệu form "Viết review" của một sự kiện (ReviewForm của `GET /api/events/{id}/review-form`).
///
/// JSON: `{event, limits: {contentMax, imagesMax, imageMaxMb, …}, quota: {newAccount, newAccountDays, postsUsed,
/// postsLimit, pinsUsed, pinsLimit, videosUsed, videosLimit}, canPostLinks, review}`.
class EventReviewForm {
  const EventReviewForm({
    required this.event,
    this.contentMax = 2000,
    this.imagesMax = 5,
    this.imageMaxMb = 20,
    this.newAccount = false,
    this.postsUsed = 0,
    this.postsLimit = 0,
    this.pinsUsed = 0,
    this.pinsLimit = 0,
    this.videosUsed = 0,
    this.videosLimit = 0,
    this.canPostLinks = false,
    this.review,
  });

  final Event event;

  /// Giới hạn của form: số ký tự, số ảnh, dung lượng mỗi ảnh.
  final int contentMax;
  final int imagesMax;
  final int imageMaxMb;

  /// Hạn mức hôm nay của tài khoản mới (BR-07): "1/3 bài viết và review · 0/2 ghim · 0/1 video".
  final bool newAccount;
  final int postsUsed;
  final int postsLimit;
  final int pinsUsed;
  final int pinsLimit;
  final int videosUsed;
  final int videosLimit;

  /// Tài khoản có tag định danh nên được chèn link (BR-22).
  final bool canPostLinks;

  /// Review năm nay của người xem để sửa; null khi viết mới.
  final EventReview? review;

  bool get isEditing => review != null;

  /// Tài khoản mới đã dùng hết lượt đăng hôm nay.
  bool get quotaFull => newAccount && postsLimit > 0 && postsUsed >= postsLimit;

  factory EventReviewForm.fromJson(Map<String, dynamic> json) {
    final limits = (json['limits'] as Map<String, dynamic>?) ?? const {};
    final quota = (json['quota'] as Map<String, dynamic>?) ?? const {};
    final own = json['review'] as Map<String, dynamic>?;
    return EventReviewForm(
      event: Event.fromJson(json['event'] as Map<String, dynamic>),
      contentMax: (limits['contentMax'] ?? 2000) as int,
      imagesMax: (limits['imagesMax'] ?? 5) as int,
      imageMaxMb: (limits['imageMaxMb'] ?? 20) as int,
      newAccount: (quota['newAccount'] ?? false) as bool,
      postsUsed: (quota['postsUsed'] ?? 0) as int,
      postsLimit: (quota['postsLimit'] ?? 0) as int,
      pinsUsed: (quota['pinsUsed'] ?? 0) as int,
      pinsLimit: (quota['pinsLimit'] ?? 0) as int,
      videosUsed: (quota['videosUsed'] ?? 0) as int,
      videosLimit: (quota['videosLimit'] ?? 0) as int,
      canPostLinks: (json['canPostLinks'] ?? false) as bool,
      review: own == null
          ? null
          : EventReview(
              id: own['id'] as int,
              rating: (own['rating'] ?? 0) as int,
              content: (own['content'] ?? '') as String,
              status: (own['status'] ?? EventReview.published) as String,
              // Ảnh / video bị từ chối khi quét không giữ lại được (như web)
              media: [
                for (final m in (own['media'] as List?) ?? const [])
                  if ((m as Map<String, dynamic>)['scanStatus'] != 'REJECTED') MediaItem.fromJson(m),
              ],
              year: ((json['event'] as Map<String, dynamic>)['reviewYear'] ?? 0) as int,
              mine: true,
            ),
    );
  }
}
