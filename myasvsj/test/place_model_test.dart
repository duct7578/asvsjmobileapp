// Unit test các phần tự tính của thực thể Bản đồ: chỉ đường, khoảng cách, nhãn ghim, review "Còn mới".
import 'package:flutter_test/flutter_test.dart';

import 'package:myasvsj/com.myasvsj.model/map_directions.dart';
import 'package:myasvsj/com.myasvsj.model/map_place.dart';
import 'package:myasvsj/com.myasvsj.model/map_search_result.dart';
import 'package:myasvsj/com.myasvsj.model/place_detail.dart';
import 'package:myasvsj/com.myasvsj.model/place_option.dart';
import 'package:myasvsj/com.myasvsj.model/place_review.dart';
import 'package:myasvsj/com.myasvsj.screen/map_distance_text.dart';

import 'place_samples.dart';

void main() {
  test('chỉ đường theo tọa độ, không có tọa độ thì theo tên và địa chỉ', () {
    expect(
      mapDirectionsUrl(lat: 35.72892, lng: 139.771364),
      'https://www.google.com/maps/dir/?api=1&destination=35.72892%2C139.771364',
    );
    const old = PlaceOption(name: 'Quán cũ', address: 'Ueno 1');
    expect(old.directionsUrl, 'https://www.google.com/maps/dir/?api=1&destination=Qu%C3%A1n+c%C5%A9%2C+Ueno+1');
  });

  test('khoảng cách haversine và cách hiện', () {
    // Ga Nippori → Konbini Midori khoảng 170 m
    expect(mapDistanceMeters(35.72892, 139.771364, 35.7275, 139.772), closeTo(167, 5));
    expect(mapDistanceMeters(1, 2, 1, 2), 0);
    expect(formatMapDistance(null), '');
    expect(formatMapDistance(80.4), '80 m');
    expect(formatMapDistance(1234), '1,2 km');
    expect(formatMapDistance(15400), '15 km');
  });

  test('kiểu ghim: sáng, mờ, cộng đồng, chờ duyệt, đóng cửa', () {
    final lit = MapPlace.fromJson((sampleOverview['places'] as List).first as Map<String, dynamic>);
    expect(lit.isLit, isTrue);
    const closed = MapPlace(id: 9, name: 'Đã đóng', lat: 0, lng: 0, reviewCount: 3, closed: true);
    expect(closed.isLit, isFalse);
    const pending = MapPlace(
      id: 8,
      name: 'Ghim mới',
      lat: 0,
      lng: 0,
      reviewCount: 1,
      status: 'PENDING',
      source: 'USER',
    );
    expect(pending.isLit, isFalse);
    expect(pending.isPending, isTrue);
    expect(pending.isCommunity, isTrue);
  });

  test('ghi chú tìm kiếm theo external / externalReason', () {
    expect(const MapSearchResult(external: 'BUSY').externalNote, startsWith('Bạn tìm hơi nhanh'));
    expect(
      const MapSearchResult(external: 'UNAVAILABLE', externalReason: 'DNS').externalNote,
      'Máy chủ chưa kết nối được tới OpenStreetMap, hãy thử lại sau.',
    );
    expect(
      const MapSearchResult(external: 'UNAVAILABLE', externalReason: 'OSM_ERROR').externalNote,
      'OpenStreetMap đang bận, hãy thử lại sau ít phút.',
    );
    expect(const MapSearchResult(external: 'SHORT').externalNote, 'Gõ thêm để tìm trên OpenStreetMap.');
    expect(const MapSearchResult(external: 'OFF').externalNote, '');
  });

  test('chi tiết: nguồn, số báo đóng cửa, đang chờ xác minh', () {
    final d = PlaceDetail.fromJson({...sampleDetail, 'source': 'USER', 'closedReports': 7});
    expect(d.sourceLabel, 'Ghim cộng đồng');
    expect(d.closedWaiting, isTrue);
    expect(d.closedProgress, '5/5');
    expect(d.copyWith(saved: true).saved, isTrue);
    expect(d.copyWith(saved: true).name, 'Ga Nippori');
  });

  test('review: "Còn mới" trong 30 ngày, "Hơn 1 năm" khi quá 365 ngày, Hữu ích khi hơn 10 lượt thích', () {
    final review = PlaceReview.fromJson(sampleReview);
    final created = review.createdAt!;
    expect(review.isFresh(created.add(const Duration(days: 10))), isTrue);
    expect(review.isFresh(created.add(const Duration(days: 40))), isFalse);
    expect(review.isOld(created.add(const Duration(days: 400))), isTrue);
    expect(review.copyWith(likeCount: 10).helpful, isFalse);
    expect(review.copyWith(likeCount: 11).helpful, isTrue);
  });
}
