// JSON mẫu của Bản đồ và review, CHÉP TỪ SERVER THẬT (curl tới http://localhost:8080, dữ liệu mẫu, ngày 8/11/2026),
// dùng cho test DAO (FakeServer) và để dựng thực thể cho DAO giả (place_fakes.dart).

/// `GET /api/map` khi đã đăng nhập user@gmail.com (rút gọn còn 4 ghim và 4 danh mục).
const Map<String, dynamic> sampleOverview = {
  'categories': [
    {'id': 'konbini', 'name': 'Cửa hàng tiện lợi', 'icon': 'local_convenience_store', 'count': 1},
    {'id': 'food', 'name': 'Quán ăn', 'icon': 'restaurant', 'count': 2},
    {'id': 'station', 'name': 'Ga tàu', 'icon': 'train', 'count': 1},
    {'id': 'park', 'name': 'Công viên', 'icon': 'park', 'count': 0},
  ],
  'places': [
    {
      'id': 1,
      'name': 'Ga Nippori',
      'nameJa': '日暮里駅',
      'nameEn': 'Nippori Station',
      'categoryId': 'station',
      'lat': 35.72892,
      'lng': 139.771364,
      'source': 'OSM',
      'status': 'ACTIVE',
      'closed': false,
      'reviewCount': 2,
      'rating': 4.5,
      'scam': true,
      'osmId': 'N772389775',
    },
    {
      'id': 3,
      'name': 'Konbini Midori',
      'nameJa': 'コンビニみどり',
      'nameEn': 'Midori Mart',
      'categoryId': 'konbini',
      'lat': 35.7275,
      'lng': 139.772,
      'source': 'TEAM',
      'status': 'ACTIVE',
      'closed': false,
      'reviewCount': 1,
      'rating': 5.0,
      'scam': false,
      'osmId': null,
    },
    {
      'id': 4,
      'name': 'Quán cơm Hana',
      'nameJa': 'はな食堂',
      'nameEn': 'Hana Shokudo',
      'categoryId': 'food',
      'lat': 35.7267,
      'lng': 139.7735,
      'source': 'USER',
      'status': 'ACTIVE',
      'closed': false,
      'reviewCount': 1,
      'rating': 5.0,
      'scam': false,
      'osmId': null,
    },
    {
      'id': 10,
      'name': 'Ramen Aoba',
      'nameJa': 'ラーメン青葉',
      'nameEn': 'Ramen Aoba',
      'categoryId': 'food',
      'lat': 35.7262,
      'lng': 139.767,
      'source': 'TEAM',
      'status': 'ACTIVE',
      'closed': false,
      'reviewCount': 0,
      'rating': null,
      'scam': false,
      'osmId': null,
    },
  ],
  'center': {'lat': 35.736083, 'lng': 139.783372, 'zoom': 15, 'areaName': 'Arakawa-ku, Tokyo · 東京都荒川区'},
  'signedIn': true,
  'devLocation': null,
};

/// `GET /api/map/events?days=30`.
const List<Map<String, dynamic>> sampleEvents = [
  {
    'id': 2,
    'title': 'Chợ phiên cuối tuần phố Yanaka Ginza',
    'startDate': '2026-11-06',
    'endDate': '2026-11-08',
    'locationName': 'Phố Yanaka Ginza',
    'lat': 35.7274,
    'lng': 139.7658,
    'daysUntil': 0,
  },
  {
    'id': 3,
    'title': 'Lễ hội phố vải Nippori',
    'startDate': '2026-11-10',
    'endDate': '2026-11-11',
    'locationName': 'Phố vải Nippori, Higashi-Nippori',
    'lat': 35.7265,
    'lng': 139.7742,
    'daysUntil': 2,
  },
];

/// `GET /api/map/search?q=ga` khi đã đăng nhập (rút gọn): danh mục khớp, địa điểm Senpai ơi, địa điểm OSM chưa có.
const Map<String, dynamic> sampleSearch = {
  'categories': [
    {'id': 'station', 'name': 'Ga tàu', 'icon': 'train', 'count': 1},
  ],
  'places': [
    {
      'id': 1,
      'externalId': 'N772389775',
      'name': 'Ga Nippori',
      'nameJa': '日暮里駅',
      'category': 'Ga tàu',
      'address': 'Higashi-Nippori 6, Arakawa, Tokyo',
      'source': 'OSM',
      'lat': 35.72892,
      'lng': 139.771364,
    },
    {
      'id': null,
      'externalId': 'DEV-ueno-station',
      'name': 'Ueno Station',
      'nameJa': null,
      'category': 'Ga tàu',
      'address': 'Ueno 7, Taito, Tokyo, Nhật Bản',
      'source': 'OSM',
      'lat': 35.711708,
      'lng': 139.776154,
    },
  ],
  'external': 'ON',
  'externalReason': null,
};

/// `GET /api/map/search?q=ga` của khách: chỉ địa điểm Senpai ơi, `external` LOGIN.
const Map<String, dynamic> sampleGuestSearch = {
  'categories': [],
  'places': [
    {
      'id': 8,
      'externalId': null,
      'name': 'Bưu điện Nippori',
      'nameJa': '日暮里郵便局',
      'category': 'Bưu điện và ngân hàng',
      'address': 'Higashi-Nippori 4',
      'source': 'TEAM',
      'lat': 35.7254,
      'lng': 139.7718,
    },
  ],
  'external': 'LOGIN',
  'externalReason': null,
};

/// `GET /api/map/places/1` khi đã đăng nhập user@gmail.com.
const Map<String, dynamic> sampleDetail = {
  'id': 1,
  'name': 'Ga Nippori',
  'nameJa': '日暮里駅',
  'nameEn': 'Nippori Station',
  'address': 'Higashi-Nippori 6, Arakawa, Tokyo',
  'osmId': 'N772389775',
  'lat': 35.72892,
  'lng': 139.771364,
  'categoryId': 'station',
  'categoryName': 'Ga tàu',
  'categoryIcon': 'train',
  'source': 'OSM',
  'status': 'ACTIVE',
  'closed': false,
  'closedReports': 0,
  'closedThreshold': 5,
  'reportedClosed': false,
  'reviewCount': 2,
  'rating': 4.5,
  'scamWarnings': [
    {'blogId': 2, 'title': 'Tin nhắn tuyển việc làm thêm lương cao quanh ga'},
  ],
  'saved': false,
  'canAct': true,
  'myReviewId': null,
  'mergedFrom': null,
  'reportReasons': [
    {'id': 1, 'label': 'Lừa đảo'},
    {'id': 2, 'label': 'Sai sự thật'},
    {'id': 3, 'label': 'Xúc phạm'},
    {'id': 4, 'label': 'Spam'},
  ],
};

/// Review của người khác (`items[0]` của `GET /api/map/places/1/reviews`).
const Map<String, dynamic> sampleReview = {
  'id': 1,
  'author': {
    'id': 6,
    'displayName': 'Lan Anh',
    'avatarUrl': null,
    'tags': [
      {'name': 'Mentor', 'color': '#C2456E'},
    ],
    'rank': 'Senpai tin cậy',
    'roleLabel': null,
  },
  'rating': 5,
  'content': 'Cổng Bắc gần trường hơn cổng Nam. Máy bán vé có nút đổi sang tiếng Anh ở góc trên bên phải.',
  'media': [],
  'createdAt': '2026-10-18T18:36:45Z',
  'edited': false,
  'status': 'PUBLISHED',
  'likeCount': 14,
  'liked': false,
  'mine': false,
  'helpful': true,
};

/// Review của chính mình có ảnh (review thử của mentor@gmail.com trên server, đã xóa sau khi chép).
const Map<String, dynamic> sampleMyReview = {
  'id': 12,
  'author': {
    'id': 6,
    'displayName': 'Lan Anh',
    'avatarUrl': null,
    'tags': [
      {'name': 'Mentor', 'color': '#C2456E'},
    ],
    'rank': 'Senpai tin cậy',
    'roleLabel': null,
  },
  'rating': 4,
  'content': 'Review thử của agent map, sẽ xóa ngay.',
  'media': [
    {
      'id': 20,
      'type': 'IMAGE',
      'url': '/media/review/2026/11/8435491d-0bf1-4d54-9e5f-685f06d1c3bf.jpg',
      'width': 772,
      'height': 721,
    },
  ],
  'createdAt': '2026-11-07T18:52:39Z',
  'edited': false,
  'status': 'PUBLISHED',
  'likeCount': 0,
  'liked': false,
  'mine': true,
  'helpful': false,
};

/// `GET /api/map/places/1/reviews?page=0`.
const Map<String, dynamic> sampleReviewPage = {
  'items': [sampleReview],
  'page': 0,
  'size': 10,
  'total': 2,
};

/// `GET /api/map/places/1/phrases` (rút gọn).
const List<Map<String, dynamic>> samplePhrases = [
  {
    'id': 13,
    'kind': 'PHRASE',
    'japanese': 'この電車は上野に止まりますか。',
    'romaji': 'Kono densha wa Ueno ni tomarimasu ka.',
    'meaningVi': 'Tàu này có dừng ở Ueno không?',
  },
  {'id': 16, 'kind': 'VOCAB', 'japanese': '乗り換え', 'romaji': 'norikae', 'meaningVi': 'Đổi tàu.'},
];

/// `GET /api/reviews/compose` của user@gmail.com (tài khoản mới).
const Map<String, dynamic> sampleCompose = {
  'limits': {
    'contentMin': 10,
    'contentMax': 2000,
    'imagesMax': 5,
    'imageMaxMb': 20,
    'videosMax': 1,
    'videoMaxSeconds': 30,
    'videoMaxMb': 50,
  },
  'quota': {
    'newAccount': true,
    'newAccountDays': 7,
    'postsUsed': 0,
    'postsLimit': 3,
    'videosUsed': 0,
    'videosLimit': 1,
  },
  'myReviewId': null,
};

/// `GET /api/reviews/12/edit` (review thử của mentor@gmail.com).
const Map<String, dynamic> sampleEdit = {
  'id': 12,
  'placeId': 11,
  'placeName': 'Tiệm giặt Coin Laundry Sora',
  'rating': 4,
  'content': 'Review thử của agent map, sẽ xóa ngay.',
  'status': 'PUBLISHED',
  'media': [
    {
      'id': 20,
      'type': 'IMAGE',
      'url': '/media/review/2026/11/8435491d-0bf1-4d54-9e5f-685f06d1c3bf.jpg',
      'scanStatus': 'PASSED',
    },
  ],
  'limits': {
    'contentMin': 10,
    'contentMax': 2000,
    'imagesMax': 5,
    'imageMaxMb': 20,
    'videosMax': 1,
    'videoMaxSeconds': 30,
    'videoMaxMb': 50,
  },
  'quota': {
    'newAccount': false,
    'newAccountDays': 7,
    'postsUsed': 2,
    'postsLimit': 3,
    'videosUsed': 0,
    'videosLimit': 1,
  },
};
