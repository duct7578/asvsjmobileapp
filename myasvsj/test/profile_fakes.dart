import 'dart:async';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/area_option.dart';
import 'package:myasvsj/com.myasvsj.model/area_picker_data.dart';
import 'package:myasvsj/com.myasvsj.model/area_prefecture.dart';
import 'package:myasvsj/com.myasvsj.model/interest_settings.dart';
import 'package:myasvsj/com.myasvsj.model/interest_topic.dart';
import 'package:myasvsj/com.myasvsj.model/point_line.dart';
import 'package:myasvsj/com.myasvsj.model/point_page.dart';
import 'package:myasvsj/com.myasvsj.model/profile_daily_usage.dart';
import 'package:myasvsj/com.myasvsj.model/profile_dao.dart';
import 'package:myasvsj/com.myasvsj.model/profile_rank.dart';
import 'package:myasvsj/com.myasvsj.model/profile_tag.dart';
import 'package:myasvsj/com.myasvsj.model/tag_compose.dart';
import 'package:myasvsj/com.myasvsj.model/tag_option.dart';
import 'package:myasvsj/com.myasvsj.model/tag_pending_request.dart';
import 'package:myasvsj/com.myasvsj.model/tag_proof_type.dart';
import 'package:myasvsj/com.myasvsj.model/tag_request.dart';
import 'package:myasvsj/com.myasvsj.model/user_profile.dart';

const tokyo = AreaPrefecture(code: '13', nameJa: '東京都', nameEn: 'Tokyo');
const osaka = AreaPrefecture(code: '27', nameJa: '大阪府', nameEn: 'Osaka');
const chiyoda = AreaOption(
  id: 662,
  prefectureCode: '13',
  nameJa: '千代田区',
  nameEn: 'Chiyoda-ku',
  name: 'Chiyoda-ku, Tokyo · 東京都千代田区',
);
const arakawa = AreaOption(
  id: 679,
  prefectureCode: '13',
  nameJa: '荒川区',
  nameEn: 'Arakawa-ku',
  name: 'Arakawa-ku, Tokyo · 東京都荒川区',
);
const kitaOsaka = AreaOption(
  id: 1001,
  prefectureCode: '27',
  nameJa: '北区',
  nameEn: 'Kita-ku, Osaka-shi',
  name: 'Kita-ku, Osaka-shi, Osaka · 大阪府大阪市北区',
);

const ranks = [
  ProfileRank(name: 'Người mới', minPoints: 0),
  ProfileRank(name: 'Người chỉ đường', minPoints: 100, featuredBonus: 5),
  ProfileRank(name: 'Senpai tin cậy', minPoints: 300, featuredBonus: 10),
];

/// Hồ sơ mẫu: cùng id với `testUser` của auth_fakes.dart (người đang đăng nhập trong widget test).
const sampleProfile = UserProfile(
  id: 1,
  email: 'an@example.com',
  displayName: 'An',
  roleLabel: 'Người dùng',
  points: 130,
  ranks: ranks,
  tags: [ProfileTag(name: 'Kouhai', color: '#2E7D5B')],
  areaId: 679,
  areaName: 'Arakawa-ku, Tokyo · 東京都荒川区',
  stage: 'ARR',
  accountAgeDays: 3,
  newAccount: true,
  newAccountDays: 7,
  today: ProfileDailyUsage(posts: 1, maxPosts: 3, maxPins: 2, maxVideos: 1),
  savedCount: 4,
);

const mentorTag = TagOption(
  id: 2,
  name: 'Mentor',
  description: 'Đã về nước hoặc đang sinh sống tại Nhật',
  color: '#C2456E',
  proofTypes: [
    TagProofType(id: 7, name: 'Giấy chứng nhận tốt nghiệp (卒業証明書)'),
    TagProofType(id: 8, name: 'Thẻ nhân viên (社員証)'),
  ],
);
const kouhaiTag = TagOption(
  id: 1,
  name: 'Kouhai',
  description: 'Đang học tại Nhật hoặc mới đến Nhật',
  color: '#2E7D5B',
  proofTypes: [TagProofType(id: 5, name: 'Thẻ sinh viên (学生証)')],
  owned: true,
);
const japaneseTag = TagOption(
  id: 5,
  name: 'Người Nhật',
  description: 'Người Nhật dùng Senpai ơi',
  color: '#E8A33C',
  selfieOnly: true,
  proofTypes: [TagProofType(id: 10, name: 'Ảnh chân dung (selfie)')],
);

/// 25 dòng lịch sử điểm, mới nhất trước: trang 0 có 20 dòng, trang 1 có 5.
final List<PointLine> samplePointLines = [
  for (var i = 25; i >= 1; i--)
    PointLine(
      id: i,
      delta: i.isEven ? 10 : -20,
      reason: i.isEven ? 'REVIEW_CREATED' : 'CONTENT_REMOVED',
      reasonLabel: i.isEven ? 'Viết review' : 'Nội dung bị Moderator gỡ',
      title: i == 25 ? 'Ga Nippori' : (i == 24 ? null : 'Bài số $i'),
      link: i == 25 ? '/map?place=1' : null,
      createdAt: DateTime(2026, 11, 1),
    ),
];

/// DAO giả của trang Tôi: giữ dữ liệu trong bộ nhớ thay vì gọi server.
class FakeProfileDao implements ProfileDao {
  UserProfile profile = sampleProfile;
  List<PointLine> pointLines = List.of(samplePointLines);
  int points = 130;

  AreaPickerData picker = const AreaPickerData(prefectures: [tokyo, osaka]);
  Map<String, List<AreaOption>> areasByPrefecture = {
    '13': [chiyoda, arakawa],
    '27': [kitaOsaka],
  };

  InterestSettings interests = const InterestSettings(
    topics: [
      InterestTopic(id: 1, name: 'Kinh nghiệm', chosen: true),
      InterestTopic(id: 2, name: 'Cảnh báo lừa đảo'),
      InterestTopic(id: 3, name: 'Thủ tục giấy tờ'),
      InterestTopic(id: 4, name: 'Visa và cư trú'),
      InterestTopic(id: 5, name: 'Nhà ở', learnt: true),
      InterestTopic(id: 6, name: 'Việc làm thêm'),
      InterestTopic(id: 7, name: 'Ăn uống'),
    ],
  );

  TagCompose compose = const TagCompose(tags: [kouhaiTag, mentorTag, japaneseTag]);

  /// Lời gọi đã nhận, theo thứ tự (tên hàm), để test kiểm tra Controller gọi gì.
  final List<String> calls = [];
  final List<({int? areaId, String? stage})> savedAreaStages = [];
  final List<List<int>> savedInterests = [];
  final List<TagRequest> submitted = [];

  /// Đặt khác null để mọi lần gọi đều lỗi như server từ chối.
  ApiException? failWith;

  /// Lỗi chỉ cho một hàm (theo tên), ví dụ {'findInterests': ApiException(...)}.
  final Map<String, ApiException> failOn = {};

  /// Đặt khác null để mọi lời gọi chờ tới khi test complete() (xem trạng thái chờ).
  Completer<void>? hold;

  Future<void> _call(String name) async {
    calls.add(name);
    await hold?.future;
    final error = failOn[name] ?? failWith;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<UserProfile> findProfile() async {
    await _call('findProfile');
    return profile;
  }

  @override
  Future<({String message, UserProfile profile})> updateAreaStage({int? areaId, String? stage}) async {
    await _call('updateAreaStage');
    savedAreaStages.add((areaId: areaId, stage: stage));
    profile = UserProfile(
      id: profile.id,
      email: profile.email,
      displayName: profile.displayName,
      ranks: profile.ranks,
      points: profile.points,
      areaId: areaId,
      stage: stage,
    );
    return (message: 'Đã lưu khu vực và giai đoạn.', profile: profile);
  }

  @override
  Future<PointPage> findPointHistory({int page = 0}) async {
    await _call('findPointHistory');
    const size = 20;
    return PointPage(
      items: pointLines.skip(page * size).take(size).toList(),
      page: page,
      size: size,
      total: pointLines.length,
      points: points,
    );
  }

  @override
  Future<AreaPickerData> findAreaPicker() async {
    await _call('findAreaPicker');
    return picker;
  }

  @override
  Future<List<AreaOption>> findAreasInPrefecture(String code) async {
    await _call('findAreasInPrefecture');
    return areasByPrefecture[code] ?? const [];
  }

  @override
  Future<List<AreaOption>> searchAreas(String q) async {
    await _call('searchAreas');
    final text = q.toLowerCase();
    return [
      for (final list in areasByPrefecture.values)
        for (final a in list)
          if (a.nameEn.toLowerCase().contains(text) || a.nameJa.contains(q)) a,
    ];
  }

  @override
  Future<AreaOption> findNearestArea(double lat, double lng) async {
    await _call('findNearestArea');
    if (lat < 20 || lat > 46 || lng < 122 || lng > 154) {
      throw const ApiException('Vị trí này không ở Nhật Bản. Hãy chọn một điểm ở Nhật.', statusCode: 400);
    }
    return arakawa;
  }

  @override
  Future<AreaOption> findArea(int id) async {
    await _call('findArea');
    for (final list in areasByPrefecture.values) {
      for (final a in list) {
        if (a.id == id) {
          return a;
        }
      }
    }
    throw const ApiException('Không tìm thấy khu vực này.', statusCode: 404);
  }

  @override
  Future<InterestSettings> findInterests() async {
    await _call('findInterests');
    return interests;
  }

  @override
  Future<({String message, InterestSettings settings})> updateInterests(List<int> topicIds) async {
    await _call('updateInterests');
    savedInterests.add(List.of(topicIds));
    interests = InterestSettings(
      max: interests.max,
      topics: [
        for (final t in interests.topics)
          InterestTopic(
            id: t.id,
            name: t.name,
            chosen: topicIds.contains(t.id),
            learnt: t.learnt && !topicIds.contains(t.id),
          ),
      ],
    );
    return (message: 'Đã lưu chủ đề quan tâm.', settings: interests);
  }

  @override
  Future<TagCompose> findTagCompose() async {
    await _call('findTagCompose');
    return compose;
  }

  @override
  Future<({String message, TagPendingRequest? pending})> submitTagRequest(TagRequest request) async {
    await _call('submitTagRequest');
    submitted.add(request);
    final name = compose.tags.firstWhere((t) => t.id == request.tagId).name;
    final pending = TagPendingRequest(
      tagName: name,
      submittedAt: DateTime(2026, 11, 8),
      expiresAt: DateTime(2026, 11, 22),
    );
    compose = compose.withPending(pending);
    return (message: 'Đã gửi yêu cầu tag.', pending: pending);
  }
}
