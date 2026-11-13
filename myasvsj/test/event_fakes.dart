import 'dart:async';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/author.dart';
import 'package:myasvsj/com.myasvsj.model/event.dart';
import 'package:myasvsj/com.myasvsj.model/event_dao.dart';
import 'package:myasvsj/com.myasvsj.model/event_detail.dart';
import 'package:myasvsj/com.myasvsj.model/event_photo.dart';
import 'package:myasvsj/com.myasvsj.model/event_review.dart';
import 'package:myasvsj/com.myasvsj.model/event_review_form.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.model/report_reason.dart';

/// Sự kiện mẫu, giống dữ liệu mẫu của server (ngày 8/11/2026).
Event sampleEvent(
  int id, {
  String title = 'Lễ hội',
  String state = Event.upcoming,
  int daysUntil = 0,
  bool canReview = false,
  double? avgRating,
  int reviewCount = 0,
  double? lat = 35.7258,
  double? lng = 139.766,
}) => Event(
  id: id,
  title: title,
  startDate: DateTime(2026, 9, 8),
  endDate: DateTime(2026, 9, 10),
  locationName: 'Công viên Yanaka',
  lat: lat,
  lng: lng,
  costNote: 'Miễn phí',
  state: state,
  daysUntil: daysUntil,
  reviewYear: 2026,
  canReview: canReview,
  avgRating: avgRating,
  reviewCount: reviewCount,
);

const reportReasons = [ReportReason(id: 1, label: 'Lừa đảo'), ReportReason(id: 4, label: 'Spam')];

/// DAO giả: giữ sự kiện và review trong bộ nhớ thay vì gọi server.
class FakeEventDao implements EventDao {
  FakeEventDao({bool member = true}) {
    details = {
      1: EventDetail(
        event: events.firstWhere((e) => e.id == 1),
        tip: 'Buổi tối có múa Bon Odori quanh sân khấu giữa công viên.',
        album: const [EventPhoto(url: '/media/review/a.jpg', authorName: 'Lan Anh', year: 2026)],
        albumCount: 1,
        reviews: [
          EventReview(
            id: 11,
            author: const Author(id: 6, displayName: 'Lan Anh', tagNames: ['Mentor'], rankName: 'Senpai tin cậy'),
            rating: 4,
            content: 'Múa Bon Odori bắt đầu khoảng 7 giờ tối.',
            year: 2026,
            createdAt: DateTime(2026, 9, 10),
            likeCount: 7,
          ),
        ],
        signedIn: member,
        member: member,
        reportReasons: reportReasons,
      ),
      2: EventDetail(
        event: events.firstWhere((e) => e.id == 2),
        reviews: [
          EventReview(
            id: 10,
            author: const Author(id: 1, displayName: 'An'),
            rating: 5,
            content: 'Croquette 100 yên ở đầu phố rất ngon.',
            year: 2026,
            createdAt: DateTime(2026, 11, 6),
            likeCount: 4,
            mine: member,
          ),
        ],
        signedIn: member,
        member: member,
        myReviewId: member ? 10 : null,
        reportReasons: reportReasons,
      ),
      3: EventDetail(event: events.firstWhere((e) => e.id == 3), signedIn: member, member: member),
    };
  }

  List<Event> events = [
    sampleEvent(1, title: 'Lễ hội Obon', state: Event.past, canReview: true, avgRating: 4.0, reviewCount: 1),
    sampleEvent(2, title: 'Chợ phiên Yanaka Ginza', state: Event.now, canReview: true, avgRating: 5.0, reviewCount: 1),
    sampleEvent(3, title: 'Lễ hội phố vải Nippori', daysUntil: 2),
    sampleEvent(5, title: 'Ngắm hoa anh đào Ueno', daysUntil: 159, lat: null, lng: null),
  ];

  late Map<int, EventDetail> details;

  /// Form "Viết review" trả về; mặc định là form viết mới cho sự kiện 1.
  late EventReviewForm form = EventReviewForm(event: events.first, canPostLinks: true);

  /// Đặt khác null để mọi lần gọi đều lỗi như server từ chối.
  ApiException? failWith;

  /// Chỉ các hàm ghi (đăng, sửa, xóa, thích, báo cáo) lỗi.
  ApiException? writeFailWith;

  /// Đặt khác null để danh sách chờ tới khi complete (kiểm tra trạng thái chờ).
  Completer<void>? listGate;

  /// Đặt khác null để lượt thích chờ tới khi complete (kiểm tra trạng thái lạc quan).
  Completer<void>? likeGate;

  final List<String?> queries = [];
  final List<({int eventId, int rating, String content, List<String> images})> created = [];
  final List<({int reviewId, int rating, String content, List<int> keep, List<String> images})> updated = [];
  final List<int> deleted = [];
  final List<({int reviewId, bool on})> likes = [];
  final List<({int reviewId, int reasonId, String note})> reports = [];

  void _maybeFail({bool write = false}) {
    if (failWith != null) {
      throw failWith!;
    }
    if (write && writeFailWith != null) {
      throw writeFailWith!;
    }
  }

  @override
  Future<List<Event>> findAll({String? q}) async {
    await listGate?.future;
    _maybeFail();
    queries.add(q);
    final text = (q ?? '').toLowerCase();
    return [
      for (final e in events)
        if (text.isEmpty || e.title.toLowerCase().contains(text)) e,
    ];
  }

  @override
  Future<EventDetail> findById(int id) async {
    _maybeFail();
    final detail = details[id];
    if (detail == null) {
      throw const ApiException('Không tìm thấy sự kiện. Sự kiện có thể đã bị xóa.', statusCode: 404);
    }
    return detail;
  }

  @override
  Future<EventReviewForm> findReviewForm(int eventId) async {
    _maybeFail();
    return form;
  }

  @override
  Future<String> createReview(
    int eventId, {
    required int rating,
    required String content,
    List<String> imagePaths = const [],
  }) async {
    _maybeFail(write: true);
    created.add((eventId: eventId, rating: rating, content: content, images: imagePaths));
    return imagePaths.isEmpty
        ? 'Đã đăng review. +10 điểm.'
        : 'Đã gửi. Ảnh và video đang được quét, trong lúc này chỉ bạn thấy review.';
  }

  @override
  Future<String> updateReview(
    int reviewId, {
    required int rating,
    required String content,
    List<int> keepMediaIds = const [],
    List<String> imagePaths = const [],
  }) async {
    _maybeFail(write: true);
    updated.add((reviewId: reviewId, rating: rating, content: content, keep: keepMediaIds, images: imagePaths));
    return 'Đã lưu thay đổi.';
  }

  @override
  Future<String> deleteReview(int reviewId) async {
    _maybeFail(write: true);
    deleted.add(reviewId);
    for (final entry in details.entries) {
      details[entry.key] = entry.value.copyWith(
        reviews: [
          for (final r in entry.value.reviews)
            if (r.id != reviewId) r,
        ],
      );
    }
    return 'Đã xóa review. Điểm của review này được thu lại.';
  }

  @override
  Future<({bool liked, int likeCount})> likeReview(int reviewId) => _like(reviewId, true);

  @override
  Future<({bool liked, int likeCount})> unlikeReview(int reviewId) => _like(reviewId, false);

  Future<({bool liked, int likeCount})> _like(int reviewId, bool on) async {
    await likeGate?.future;
    _maybeFail(write: true);
    likes.add((reviewId: reviewId, on: on));
    // Server đếm lại: giả như có thêm một người khác vừa thích
    return (liked: on, likeCount: on ? 9 : 8);
  }

  @override
  Future<String> reportReview(int reviewId, {required int reasonId, String note = ''}) async {
    _maybeFail(write: true);
    reports.add((reviewId: reviewId, reasonId: reasonId, note: note));
    return 'Cảm ơn bạn. Báo cáo đã được gửi.';
  }
}

/// Review của chính người xem trong form sửa: một ảnh đã đăng.
EventReview ownReview() => const EventReview(
  id: 13,
  rating: 4,
  content: 'Vui, đông người.',
  year: 2026,
  mine: true,
  media: [MediaItem(id: 50, type: 'IMAGE', url: '/media/review/x.jpg')],
);
