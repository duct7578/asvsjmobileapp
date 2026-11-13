import 'package:myasvsj/com.myasvsj.model/map_category.dart';
import 'package:myasvsj/com.myasvsj.model/map_center.dart';
import 'package:myasvsj/com.myasvsj.model/map_place.dart';

/// Toàn cảnh bản đồ (`GET /api/map`): danh mục kèm số lượng, mọi ghim, nơi bản đồ mở ra.
///
/// JSON: `{categories: [...], places: [...], center: {...}, signedIn, devLocation}`.
class MapOverview {
  const MapOverview({
    this.categories = const [],
    this.places = const [],
    this.center = MapCenter.tokyo,
    this.signedIn = false,
    this.devLocation,
  });

  final List<MapCategory> categories;

  /// Địa điểm ACTIVE có tọa độ, cộng ghim chờ duyệt của chính người xem.
  final List<MapPlace> places;

  /// Khu vực của người xem, hoặc Tokyo.
  final MapCenter center;
  final bool signedIn;

  /// "Vị trí của tôi" cố định của môi trường thử nghiệm ngoài Nhật; null ở môi trường thật.
  final MapCenter? devLocation;

  factory MapOverview.fromJson(Map<String, dynamic> json) => MapOverview(
    categories: [
      for (final c in (json['categories'] as List?) ?? const []) MapCategory.fromJson(c as Map<String, dynamic>),
    ],
    places: [for (final p in (json['places'] as List?) ?? const []) MapPlace.fromJson(p as Map<String, dynamic>)],
    center: MapCenter.tryParse(json['center']) ?? MapCenter.tokyo,
    signedIn: (json['signedIn'] ?? false) as bool,
    devLocation: MapCenter.tryParse(json['devLocation']),
  );
}
