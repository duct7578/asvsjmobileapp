import 'package:myasvsj/com.myasvsj.model/map_category.dart';
import 'package:myasvsj/com.myasvsj.model/place_option.dart';

/// Kết quả tìm trên bản đồ (`GET /api/map/search?q=`) hoặc "Địa điểm quanh đây" (`GET /api/map/nearby`).
///
/// JSON: `{categories: [...], places: [PlaceOption], external, externalReason}`.
class MapSearchResult {
  const MapSearchResult({this.categories = const [], this.places = const [], this.external = '', this.externalReason});

  /// Danh mục có tên khớp từ khóa (chỉ khi tìm).
  final List<MapCategory> categories;

  /// Địa điểm Senpai ơi trước, rồi địa điểm OpenStreetMap (chỉ người đã đăng nhập).
  final List<PlaceOption> places;

  /// ON, OFF, SHORT, UNAVAILABLE, BUSY, hoặc LOGIN khi là khách (chỉ tìm địa điểm Senpai ơi).
  final String external;

  /// Lý do OpenStreetMap không trả lời: LIMITED, BUSY, OSM_ERROR, SSL, TIMEOUT, DNS, NETWORK.
  final String? externalReason;

  /// Câu ghi chú dưới kết quả, giống `externalNote` của web; rỗng khi không có gì cần nói.
  String get externalNote => switch (external) {
    'LOGIN' => 'Đăng nhập để tìm thêm trên OpenStreetMap.',
    'BUSY' => 'Bạn tìm hơi nhanh, hãy chờ vài giây rồi thử lại để thấy thêm địa điểm từ OpenStreetMap.',
    'UNAVAILABLE' =>
      const ['SSL', 'DNS', 'NETWORK', 'TIMEOUT'].contains(externalReason)
          ? 'Máy chủ chưa kết nối được tới OpenStreetMap, hãy thử lại sau.'
          : 'OpenStreetMap đang bận, hãy thử lại sau ít phút.',
    'SHORT' => 'Gõ thêm để tìm trên OpenStreetMap.',
    _ => '',
  };

  factory MapSearchResult.fromJson(Map<String, dynamic> json) => MapSearchResult(
    categories: [
      for (final c in (json['categories'] as List?) ?? const []) MapCategory.fromJson(c as Map<String, dynamic>),
    ],
    places: [for (final p in (json['places'] as List?) ?? const []) PlaceOption.fromJson(p as Map<String, dynamic>)],
    external: (json['external'] ?? '') as String,
    externalReason: json['externalReason'] as String?,
  );
}
