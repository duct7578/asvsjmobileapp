import 'package:myasvsj/com.myasvsj.model/map_directions.dart';
import 'package:myasvsj/com.myasvsj.model/place_scam_warning.dart';
import 'package:myasvsj/com.myasvsj.model/report_reason.dart';

/// Chi tiết một địa điểm (`GET /api/map/places/{id}`), ứng với một dòng bảng `places`.
///
/// JSON: `{id, name, nameJa, nameEn, address, osmId, lat, lng, categoryId, categoryName, categoryIcon, source, status,
/// closed, closedReports, closedThreshold, reportedClosed, reviewCount, rating, scamWarnings, saved, canAct,
/// myReviewId, mergedFrom, reportReasons}`.
class PlaceDetail {
  const PlaceDetail({
    required this.id,
    required this.name,
    this.nameJa = '',
    this.nameEn = '',
    this.address = '',
    this.osmId,
    this.lat,
    this.lng,
    this.categoryId = 'other',
    this.categoryName = '',
    this.categoryIcon = 'place',
    this.source = 'TEAM',
    this.status = 'ACTIVE',
    this.closed = false,
    this.closedReports = 0,
    this.closedThreshold = 5,
    this.reportedClosed = false,
    this.reviewCount = 0,
    this.rating,
    this.scamWarnings = const [],
    this.saved = false,
    this.canAct = false,
    this.myReviewId,
    this.mergedFrom,
    this.reportReasons = const [],
  });

  /// Tên các nguồn địa điểm, giống SOURCES của web.
  static const sourceLabels = {
    'OSM': 'OpenStreetMap',
    'GOOGLE': 'Google Maps',
    'TEAM': 'Nhóm Senpai ơi thêm',
    'MODERATOR': 'Nhóm Senpai ơi thêm',
    'USER': 'Ghim cộng đồng',
  };

  final int id;
  final String name;
  final String nameJa;
  final String nameEn;
  final String address;
  final String? osmId;
  final double? lat;
  final double? lng;
  final String categoryId;
  final String categoryName;

  /// Tên biểu tượng Material Symbols của danh mục.
  final String categoryIcon;
  final String source;

  /// ACTIVE, hoặc PENDING (ghim của mình đang chờ duyệt).
  final String status;

  /// Moderator đã xác nhận đóng cửa.
  final bool closed;

  /// Số báo "đã đóng cửa" chưa được Moderator xử lý, và số báo cần để vào hàng chờ của Moderator (5).
  final int closedReports;
  final int closedThreshold;

  /// Người xem đã báo đóng cửa (mỗi người một lần).
  final bool reportedClosed;
  final int reviewCount;
  final double? rating;
  final List<PlaceScamWarning> scamWarnings;

  /// Người xem đã lưu địa điểm.
  final bool saved;

  /// Người xem là User đã đăng nhập (khách và tài khoản staff chỉ xem).
  final bool canAct;

  /// Review của chính người xem cho địa điểm này, nếu có (thì nút là "Sửa review của bạn").
  final int? myReviewId;

  /// Địa điểm người xem mở đã được gộp vào địa điểm này.
  final int? mergedFrom;
  final List<ReportReason> reportReasons;

  bool get isActive => status == 'ACTIVE';
  bool get isPending => status == 'PENDING';

  String get sourceLabel => sourceLabels[source] ?? source;

  /// Nhiều người báo đã đóng cửa, đang chờ Moderator xác minh.
  bool get closedWaiting => !closed && closedReports >= closedThreshold;

  /// Số báo đóng cửa để hiện trên nút, ví dụ "1/5".
  String get closedProgress => '${closedReports < closedThreshold ? closedReports : closedThreshold}/$closedThreshold';

  String get directionsUrl => mapDirectionsUrl(lat: lat, lng: lng, name: name, address: address);

  PlaceDetail copyWith({bool? saved, int? closedReports, bool? reportedClosed}) => PlaceDetail(
    id: id,
    name: name,
    nameJa: nameJa,
    nameEn: nameEn,
    address: address,
    osmId: osmId,
    lat: lat,
    lng: lng,
    categoryId: categoryId,
    categoryName: categoryName,
    categoryIcon: categoryIcon,
    source: source,
    status: status,
    closed: closed,
    closedReports: closedReports ?? this.closedReports,
    closedThreshold: closedThreshold,
    reportedClosed: reportedClosed ?? this.reportedClosed,
    reviewCount: reviewCount,
    rating: rating,
    scamWarnings: scamWarnings,
    saved: saved ?? this.saved,
    canAct: canAct,
    myReviewId: myReviewId,
    mergedFrom: mergedFrom,
    reportReasons: reportReasons,
  );

  factory PlaceDetail.fromJson(Map<String, dynamic> json) => PlaceDetail(
    id: json['id'] as int,
    name: (json['name'] ?? '') as String,
    nameJa: (json['nameJa'] ?? '') as String,
    nameEn: (json['nameEn'] ?? '') as String,
    address: (json['address'] ?? '') as String,
    osmId: json['osmId'] as String?,
    lat: (json['lat'] as num?)?.toDouble(),
    lng: (json['lng'] as num?)?.toDouble(),
    categoryId: (json['categoryId'] ?? 'other') as String,
    categoryName: (json['categoryName'] ?? '') as String,
    categoryIcon: (json['categoryIcon'] ?? 'place') as String,
    source: (json['source'] ?? 'TEAM') as String,
    status: (json['status'] ?? 'ACTIVE') as String,
    closed: (json['closed'] ?? false) as bool,
    closedReports: (json['closedReports'] ?? 0) as int,
    closedThreshold: (json['closedThreshold'] ?? 5) as int,
    reportedClosed: (json['reportedClosed'] ?? false) as bool,
    reviewCount: (json['reviewCount'] ?? 0) as int,
    rating: (json['rating'] as num?)?.toDouble(),
    scamWarnings: [
      for (final w in (json['scamWarnings'] as List?) ?? const []) PlaceScamWarning.fromJson(w as Map<String, dynamic>),
    ],
    saved: (json['saved'] ?? false) as bool,
    canAct: (json['canAct'] ?? false) as bool,
    myReviewId: json['myReviewId'] as int?,
    mergedFrom: json['mergedFrom'] as int?,
    reportReasons: ReportReason.listFrom(json['reportReasons']),
  );
}
