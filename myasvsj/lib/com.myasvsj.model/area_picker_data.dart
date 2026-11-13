import 'package:myasvsj/com.myasvsj.model/area_dev_location.dart';
import 'package:myasvsj/com.myasvsj.model/area_prefecture.dart';

/// Dữ liệu mở ô chọn khu vực: 47 tỉnh và vị trí thử của server (Picker của `GET /api/areas`).
///
/// JSON: `{prefectures: [...], devLocation: {lat, lng, label} | null}`.
class AreaPickerData {
  const AreaPickerData({this.prefectures = const [], this.devLocation});

  final List<AreaPrefecture> prefectures;
  final AreaDevLocation? devLocation;

  factory AreaPickerData.fromJson(Map<String, dynamic> json) => AreaPickerData(
    prefectures: [
      for (final p in (json['prefectures'] as List?) ?? const []) AreaPrefecture.fromJson(p as Map<String, dynamic>),
    ],
    devLocation: AreaDevLocation.tryParse(json['devLocation']),
  );
}
