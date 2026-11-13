// Ảnh màn 07–11 (Bản đồ và địa điểm) để so với design/figma-export/ref/07-*.png … 11-*.png.
// Chạy: flutter test test/design_shots/map_shot_test.dart --dart-define=SHOTS=true
//
// Bản đồ chụp không có ô bản đồ (test không có mạng): vùng bản đồ là nền mapLand, chỉ so các lớp nổi và ghim.
// Màn Bản đồ là một tab của MainScreen (thanh tab dưới do MainScreen vẽ), nên ảnh 07 / 08 cao 718 = 844 − 44 (thanh
// trạng thái giả của ảnh thiết kế) − 82 (thanh tab dưới): vùng bản đồ cao đúng như thiết kế.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/home_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/place_controller.dart';
import 'package:myasvsj/com.myasvsj.model/home_tag.dart';
import 'package:myasvsj/com.myasvsj.model/map_center.dart';
import 'package:myasvsj/com.myasvsj.model/map_festival.dart';
import 'package:myasvsj/com.myasvsj.model/map_overview.dart';
import 'package:myasvsj/com.myasvsj.model/map_search_result.dart';
import 'package:myasvsj/com.myasvsj.model/place_detail.dart';
import 'package:myasvsj/com.myasvsj.model/place_review.dart';
import 'package:myasvsj/com.myasvsj.model/recent_review.dart';
import 'package:myasvsj/com.myasvsj.model/review_compose.dart';
import 'package:myasvsj/com.myasvsj.screen/map_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/place_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/recent_reviews_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/review_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';

import '../home_fakes.dart';
import '../place_fakes.dart';
import '../place_samples.dart';
import 'shot_helper.dart';

/// Bản đồ giữa (35.7276, 139.7700), phóng to 16: các ghim đặt gần đúng chỗ của ảnh thiết kế.
const _overview = {
  'categories': [
    {'id': 'super', 'name': 'Siêu thị', 'icon': 'shopping_cart', 'count': 24},
    {'id': 'station', 'name': 'Ga tàu', 'icon': 'train', 'count': 12},
    {'id': 'food', 'name': 'Quán ăn', 'icon': 'restaurant', 'count': 30},
    {'id': 'clinic', 'name': 'Phòng khám', 'icon': 'local_hospital', 'count': 8},
    {'id': 'bank', 'name': 'Ngân hàng', 'icon': 'account_balance', 'count': 7},
    {'id': 'house', 'name': 'Nhà đất', 'icon': 'home_work', 'count': 5},
  ],
  'places': [
    {
      'id': 1,
      'name': 'Gyomu Super Minami-Senju',
      'nameJa': '業務スーパー 南千住店',
      'nameEn': 'Gyomu Super',
      'categoryId': 'super',
      'lat': 35.727757,
      'lng': 139.769721,
      'source': 'TEAM',
      'reviewCount': 18,
      'rating': 4.2,
    },
    {
      'id': 2,
      'name': 'Quán phở Hà Nội',
      'categoryId': 'food',
      'lat': 35.729185,
      'lng': 139.767447,
      'source': 'USER',
      'reviewCount': 9,
      'rating': 4.4,
    },
    {
      'id': 3,
      'name': 'Ga Minami-Senju',
      'nameJa': '南千住駅',
      'categoryId': 'station',
      'lat': 35.726781,
      'lng': 139.771352,
      'source': 'TEAM',
      'reviewCount': 31,
      'rating': 4.6,
    },
    {'id': 4, 'name': 'Phòng khám Senju', 'categoryId': 'clinic', 'lat': 35.72645, 'lng': 139.768155},
    {'id': 5, 'name': 'Ngân hàng Yucho', 'categoryId': 'bank', 'lat': 35.728959, 'lng': 139.771545},
    {'id': 6, 'name': 'Văn phòng nhà đất', 'categoryId': 'house', 'lat': 35.727513, 'lng': 139.767103, 'scam': true},
  ],
};

const _nearby = {
  'categories': [],
  'places': [
    {
      'id': 1,
      'name': 'Gyomu Super Minami-Senju',
      'category': 'Siêu thị',
      'address': '2-14-3 Minami-Senju',
      'source': 'TEAM',
      'lat': 35.727757,
      'lng': 139.769721,
    },
    {
      'id': 3,
      'name': 'Ga Minami-Senju',
      'category': 'Ga tàu',
      'address': 'JR Jōban, Hibiya, TX',
      'source': 'TEAM',
      'lat': 35.726781,
      'lng': 139.771352,
    },
    {
      'id': null,
      'externalId': 'N1',
      'name': 'Phòng khám Senju',
      'category': 'Phòng khám',
      'address': 'OpenStreetMap',
      'source': 'OSM',
      'lat': 35.7205,
      'lng': 139.7712,
    },
  ],
  'external': 'ON',
};

MapTestKit _mapKit() {
  final kit = MapTestKit(user: signedInUser);
  final data = MapOverview.fromJson(_overview);
  kit.places.overview = MapOverview(
    categories: data.categories,
    places: data.places,
    center: const MapCenter(lat: 35.7276, lng: 139.77, zoom: 16),
    signedIn: true,
  );
  kit.places.events = [
    MapFestival(id: 7, title: 'Lễ hội Sanja', lat: 35.729987, lng: 139.772275, daysUntil: 7),
  ];
  kit.places.nearbyResult = MapSearchResult.fromJson(_nearby);
  kit.locator.position = (lat: 35.725841, lng: 139.770064);
  return kit;
}

PlaceReview _review({
  required int id,
  required int authorId,
  required String name,
  required List<String> tags,
  required String rank,
  required String content,
  required DateTime createdAt,
  int likes = 0,
  bool edited = false,
  bool helpful = false,
  int images = 0,
}) {
  return PlaceReview.fromJson({
    'id': id,
    'author': {
      'id': authorId,
      'displayName': name,
      'tags': [for (final t in tags) {'name': t}],
      'rank': rank,
    },
    'rating': 4,
    'content': content,
    'media': [
      for (var i = 0; i < images; i++) {'id': 100 + i, 'type': 'IMAGE', 'url': '/media/review/$id-$i.jpg'},
    ],
    'createdAt': createdAt.toUtc().toIso8601String(),
    'edited': edited,
    'likeCount': likes,
    'helpful': helpful,
  });
}

MapTestKit _detailKit({bool photos = false}) {
  final kit = MapTestKit(user: signedInUser);
  final now = DateTime.now();
  kit.places.details[1] = PlaceDetail.fromJson({
    ...sampleDetail,
    'name': 'Gyomu Super Minami-Senju',
    'nameJa': '業務スーパー 南千住店',
    'nameEn': 'Gyomu Super',
    'address': '2-14-3 Minami-Senju, Arakawa-ku',
    'categoryName': 'Siêu thị',
    'categoryIcon': 'shopping_cart',
    'source': 'TEAM',
    'closedReports': 1,
    'reviewCount': 2,
    'rating': 4.0,
    'scamWarnings': [],
  });
  kit.places.reviews[1] = [
    _review(
      id: 1,
      authorId: 4,
      name: 'Hà Phương',
      tags: ['Du học sinh'],
      rank: 'Senpai bạc',
      content: 'Rau và thịt rẻ hơn konbini nhiều. Thứ Ba rau giảm 20%. Có góc đồ châu Á: nước mắm, bánh phở khô, sả '
          'cây đông lạnh.',
      createdAt: now.subtract(const Duration(hours: 3)),
      likes: 12,
      helpful: true,
      images: photos ? 5 : 0,
    ),
    _review(
      id: 2,
      authorId: 5,
      name: 'Quang Huy',
      tags: ['Đã đi làm'],
      rank: 'Senpai vàng',
      content: 'Quầy tự thanh toán có tiếng Anh. Túi nilon tính phí 3 yên, nhớ mang túi.',
      createdAt: now.subtract(const Duration(days: 400)),
      likes: 5,
      edited: true,
    ),
  ];
  kit.reviews.compose = ReviewCompose.fromJson({
    ...sampleCompose,
    'quota': {'newAccount': true, 'newAccountDays': 7, 'postsUsed': 1, 'postsLimit': 3},
  });
  return kit;
}

RecentReview _recent(
  int id,
  String place,
  String category,
  String icon,
  String area,
  int rating,
  String text,
  String author,
  int likes, {
  String? near,
  String? photo,
  int media = 0,
  Duration ago = const Duration(hours: 2),
}) {
  return RecentReview(
    id: id,
    placeId: id,
    placeName: place,
    categoryName: category,
    categoryIcon: icon,
    placeArea: area,
    near: near,
    rating: rating,
    authorName: author,
    authorTags: const [HomeTag(name: 'Du học sinh', color: '#3A4A8C')],
    excerpt: text,
    likeCount: likes,
    createdAt: DateTime.now().subtract(ago),
    photoUrl: photo,
    mediaCount: media,
  );
}

/// Bật đổ bóng thật (flutter test mặc định vẽ BoxShadow không làm mờ), trả lại như cũ khi chụp xong.
void _realShadows() {
  debugDisableShadows = false;
}

void _resetShadows() {
  debugDisableShadows = true;
}

/// "Vị trí của tôi" mà không dời bản đồ (nút trên màn hình dời bản đồ về vị trí của tôi).
Future<void> _locate(WidgetTester tester) async {
  final places = Provider.of<PlaceController>(tester.element(find.byType(MapScreen)), listen: false);
  await places.locateMe();
  await settleShot(tester);
}

void main() {
  final theme = SenpaiTheme.light();

  testWidgets('07 Bản đồ — danh sách kết quả', skip: shotSkip != null, (tester) async {
    _realShadows();
    final kit = _mapKit();
    await pumpShot(tester, kit.app(const MapScreen(showTiles: false), theme: theme), height: 718);
    await _locate(tester);
    final places = Provider.of<PlaceController>(tester.element(find.byType(MapScreen)), listen: false);
    await places.loadNearby(35.7276, 139.77, signedIn: true);
    await settleShot(tester);
    await saveShot(tester, '07-map-results');
    _resetShadows();
  });

  testWidgets('08 Bản đồ — thẻ địa điểm', skip: shotSkip != null, (tester) async {
    _realShadows();
    final kit = _mapKit();
    await pumpShot(tester, kit.app(const MapScreen(showTiles: false), theme: theme), height: 718);
    await _locate(tester);
    await tester.tap(find.byKey(const ValueKey('map-pin-1')));
    await settleShot(tester);
    await saveShot(tester, '08-map-place-sheet');
    _resetShadows();
  });

  testWidgets('08b Bản đồ — địa điểm OpenStreetMap chưa có trên Senpai ơi', skip: shotSkip != null, (tester) async {
    _realShadows();
    final kit = _mapKit();
    await pumpShot(tester, kit.app(const MapScreen(showTiles: false), theme: theme), height: 718);
    final places = Provider.of<PlaceController>(tester.element(find.byType(MapScreen)), listen: false);
    await places.loadNearby(35.7276, 139.77, signedIn: true);
    await settleShot(tester);
    await tester.tap(find.text('Phòng khám Senju').last);
    await settleShot(tester);
    await saveShot(tester, '08b-map-osm-sheet');
    _resetShadows();
  });

  testWidgets('09 Chi tiết địa điểm', skip: shotSkip != null, (tester) async {
    final kit = _detailKit();
    await pumpShot(tester, kit.app(const PlaceDetailScreen(placeId: 1), theme: theme), height: 1340);
    await saveShot(tester, '09-place-detail');
  });

  testWidgets('09b Chi tiết địa điểm — có ảnh review', skip: shotSkip != null, (tester) async {
    final kit = _detailKit(photos: true);
    await pumpShot(tester, kit.app(const PlaceDetailScreen(placeId: 1), theme: theme), height: 1440);
    await saveShot(tester, '09b-place-detail-photos');
  });

  testWidgets('09c Chi tiết địa điểm — tab Từ vựng và mẫu câu', skip: shotSkip != null, (tester) async {
    final kit = _detailKit();
    await pumpShot(tester, kit.app(const PlaceDetailScreen(placeId: 1), theme: theme), height: 1100);
    await tester.tap(find.text('Từ vựng và mẫu câu'));
    await settleShot(tester);
    await saveShot(tester, '09c-place-detail-phrases');
  });

  testWidgets('10 Viết review', skip: shotSkip != null, (tester) async {
    final kit = _detailKit();
    await pumpShot(tester, kit.app(const PlaceDetailScreen(placeId: 1), theme: theme), height: 800);
    await tester.tap(find.text('Viết review'));
    await settleShot(tester);
    await tester.tap(find.byTooltip('4 sao'));
    await tester.enterText(
      find.byType(TextField),
      'Siêu thị rộng, giá rẻ hơn konbini nhiều. Thứ Ba rau giảm 20%, có góc đồ châu Á: nước mắm, bánh phở khô…',
    );
    await settleShot(tester);
    await saveShot(tester, '10-review-form');
  });

  testWidgets('10b Sửa review (có ảnh cũ)', skip: shotSkip != null, (tester) async {
    final kit = _detailKit();
    await pumpShot(tester, kit.app(const ReviewFormScreen(reviewId: 12), theme: theme), height: 800);
    await saveShot(tester, '10b-review-form-edit');
  });

  Widget recentApp(FakeHomeDao dao, {bool signedIn = true}) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: homeTestAuth(signedIn: signedIn)),
      ChangeNotifierProvider(create: (_) => NotificationController(FakeHomeNotificationDao())),
      ChangeNotifierProvider(create: (_) => HomeController(dao)),
    ],
    child: shotApp(const RecentReviewsScreen()),
  );

  testWidgets('11 Review mới', skip: shotSkip != null, (tester) async {
    const area = 'Arakawa-ku, Tokyo · 東京都荒川区';
    final dao = FakeHomeDao()
      ..recent = [
        _recent(1, 'Ramen Ichiran Ueno', 'Quán ăn', 'restaurant', 'Taitō-ku, Tokyo · 東京都台東区', 5,
            'Ngồi buồng riêng, gọi món bằng phiếu có tiếng Anh. Tầm 21h vẫn phải xếp hàng 15 phút.', 'Minh Anh', 11,
            near: 'AREA', photo: '/media/review/ramen.jpg', media: 3),
        _recent(2, 'Coin Laundry Machiya', 'Giặt là', 'local_laundry_service', area, 3,
            'Máy sấy 10 phút 100 yên, có máy đổi tiền. Buổi tối hơi đông.', 'Khánh', 3,
            near: 'AREA', ago: const Duration(days: 1)),
        _recent(3, 'Gyomu Super Minami-Senju', 'Siêu thị', 'shopping_cart', area, 4,
            'Thứ Ba rau giảm 20%, có góc đồ châu Á.', 'Hà', 2, near: 'AREA', ago: const Duration(days: 2)),
      ];
    await pumpShot(tester, recentApp(dao), height: 800);
    await saveShot(tester, '11-recent-reviews');
  });

  testWidgets('11b Review mới — khách', skip: shotSkip != null, (tester) async {
    final dao = FakeHomeDao()..reviewsAsGuest = true;
    await pumpShot(tester, recentApp(dao, signedIn: false), height: 800);
    await saveShot(tester, '11b-recent-reviews-guest');
  });
}
