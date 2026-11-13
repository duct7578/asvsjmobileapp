import 'package:myasvsj/com.myasvsj.model/event.dart';
import 'package:myasvsj/com.myasvsj.model/event_photo.dart';
import 'package:myasvsj/com.myasvsj.model/event_review.dart';
import 'package:myasvsj/com.myasvsj.model/report_reason.dart';

/// Trang chi tiết một sự kiện (EventDetail của `GET /api/events/{id}`).
///
/// JSON: `{event, tip, album, albumCount, reviews, viewer: {signedIn, member, myReviewId}, reportReasons}`.
class EventDetail {
  const EventDetail({
    required this.event,
    this.tip,
    this.album = const [],
    this.albumCount = 0,
    this.reviews = const [],
    this.signedIn = false,
    this.member = false,
    this.myReviewId,
    this.reportReasons = const [],
  });

  final Event event;

  /// "Mẹo từ Moderator"; null khi không có.
  final String? tip;

  /// Tối đa 12 ảnh đầu của album; [albumCount] là tổng số ảnh.
  final List<EventPhoto> album;
  final int albumCount;

  /// Review mọi năm, mới nhất trước (gồm review chưa đăng của chính người xem).
  final List<EventReview> reviews;

  /// Người xem đã đăng nhập; [member] là tài khoản User được viết, thích, báo cáo review.
  final bool signedIn;
  final bool member;

  /// Review năm nay của người xem: có thì nút là "Sửa review" thay vì "Viết review".
  final int? myReviewId;

  /// Lý do báo cáo cho hộp thoại "Báo cáo".
  final List<ReportReason> reportReasons;

  /// Số review đã đăng (không tính review đang chờ quét / bị ẩn của chính mình).
  int get publishedCount => reviews.where((r) => r.isPublished).length;

  EventDetail copyWith({List<EventReview>? reviews}) => EventDetail(
    event: event,
    tip: tip,
    album: album,
    albumCount: albumCount,
    reviews: reviews ?? this.reviews,
    signedIn: signedIn,
    member: member,
    myReviewId: myReviewId,
    reportReasons: reportReasons,
  );

  factory EventDetail.fromJson(Map<String, dynamic> json) {
    final viewer = (json['viewer'] as Map<String, dynamic>?) ?? const {};
    final tip = json['tip'] as String?;
    return EventDetail(
      event: Event.fromJson(json['event'] as Map<String, dynamic>),
      tip: tip == null || tip.trim().isEmpty ? null : tip,
      album: [for (final p in (json['album'] as List?) ?? const []) EventPhoto.fromJson(p as Map<String, dynamic>)],
      albumCount: (json['albumCount'] ?? 0) as int,
      reviews: [
        for (final r in (json['reviews'] as List?) ?? const []) EventReview.fromJson(r as Map<String, dynamic>),
      ],
      signedIn: (viewer['signedIn'] ?? false) as bool,
      member: (viewer['member'] ?? false) as bool,
      myReviewId: viewer['myReviewId'] as int?,
      reportReasons: ReportReason.listFrom(json['reportReasons']),
    );
  }
}
