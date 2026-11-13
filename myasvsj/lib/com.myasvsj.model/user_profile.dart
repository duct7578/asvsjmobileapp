import 'package:myasvsj/com.myasvsj.model/profile_daily_usage.dart';
import 'package:myasvsj/com.myasvsj.model/profile_rank.dart';
import 'package:myasvsj/com.myasvsj.model/profile_tag.dart';

/// Hồ sơ của người đang đăng nhập trên trang "Tôi" (ProfileResponse của `GET /api/me/profile`), ứng với
/// một dòng bảng `users` kèm điểm, tag, khu vực và hạn mức hôm nay.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    this.role = 'USER',
    this.roleLabel = '',
    this.points = 0,
    this.ranks = const [],
    this.tags = const [],
    this.pendingTag,
    this.areaId,
    this.areaName,
    this.stage,
    this.createdAt,
    this.accountAgeDays = 0,
    this.newAccount = false,
    this.newAccountDays = 0,
    this.today = const ProfileDailyUsage(),
    this.reportMutedUntil,
    this.hasPassword = true,
    this.linkedProviders = const [],
    this.savedCount = 0,
  });

  final int id;
  final String email;
  final String displayName;
  final String? avatarUrl;

  /// USER, MODERATOR, ACADEMIC_MANAGER hoặc ADMIN; app chỉ mở cho USER.
  final String role;
  final String roleLabel;

  final int points;

  /// Các cấp bậc, từ thấp đến cao.
  final List<ProfileRank> ranks;

  /// Tag định danh đã được cấp.
  final List<ProfileTag> tags;

  /// Tên tag đang chờ Moderator duyệt; null khi không có yêu cầu nào đang chờ.
  final String? pendingTag;

  /// Khu vực sống (bảng `areas`); null khi chưa chọn.
  final int? areaId;

  /// Ví dụ "Arakawa-ku, Tokyo · 東京都荒川区".
  final String? areaName;

  /// PRE, ARR, LEAVE, HOME (xem ProfileStage); null khi chưa chọn.
  final String? stage;

  final DateTime? createdAt;
  final int accountAgeDays;

  /// Tài khoản tạo chưa đủ [newAccountDays] ngày: bị giới hạn số bài, ghim, video mỗi ngày.
  final bool newAccount;
  final int newAccountDays;
  final ProfileDailyUsage today;

  /// Đang bị khóa báo cáo đến lúc này; null khi không bị khóa.
  final DateTime? reportMutedUntil;

  /// Có mật khẩu (đăng nhập được bằng email).
  final bool hasPassword;

  /// Nhà cung cấp đăng nhập đã liên kết: GOOGLE, FACEBOOK…
  final List<String> linkedProviders;

  /// Số mục trên "Đã lưu": địa điểm, bài viết, câu hỏi, cẩm nang.
  final int savedCount;

  bool get isMember => role == 'USER';

  /// Vị trí cấp hiện tại trong [ranks]: cấp cao nhất đã đủ điểm.
  int get rankIndex {
    final reached = ranks.where((r) => points >= r.minPoints).length;
    return reached == 0 ? 0 : reached - 1;
  }

  ProfileRank? get currentRank => ranks.isEmpty ? null : ranks[rankIndex];

  /// Cấp kế tiếp; null khi đã ở cấp cao nhất.
  ProfileRank? get nextRank => rankIndex + 1 < ranks.length ? ranks[rankIndex + 1] : null;

  /// Tiến độ từ cấp hiện tại tới cấp kế tiếp, từ 0 đến 1 (1 khi đã ở cấp cao nhất).
  double get rankProgress {
    final current = currentRank;
    final next = nextRank;
    if (current == null || next == null) {
      return 1;
    }
    final span = next.minPoints - current.minPoints;
    return span <= 0 ? 1 : ((points - current.minPoints) / span).clamp(0, 1).toDouble();
  }

  /// Số điểm còn thiếu để lên cấp kế tiếp; 0 khi đã ở cấp cao nhất.
  int get pointsToNextRank => nextRank == null ? 0 : nextRank!.minPoints - points;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as int,
    email: (json['email'] ?? '') as String,
    displayName: (json['displayName'] ?? '') as String,
    avatarUrl: json['avatarUrl'] as String?,
    role: (json['role'] ?? 'USER') as String,
    roleLabel: (json['roleLabel'] ?? '') as String,
    points: (json['points'] ?? 0) as int,
    ranks: [for (final r in (json['ranks'] as List?) ?? const []) ProfileRank.fromJson(r as Map<String, dynamic>)],
    tags: [for (final t in (json['tags'] as List?) ?? const []) ProfileTag.fromJson(t as Map<String, dynamic>)],
    pendingTag: json['pendingTag'] as String?,
    areaId: json['areaId'] as int?,
    areaName: json['areaName'] as String?,
    stage: json['stage'] as String?,
    createdAt: _date(json['createdAt']),
    accountAgeDays: (json['accountAgeDays'] ?? 0) as int,
    newAccount: (json['newAccount'] ?? false) as bool,
    newAccountDays: (json['newAccountDays'] ?? 0) as int,
    today: ProfileDailyUsage.fromJson(json['today'] as Map<String, dynamic>?),
    reportMutedUntil: _date(json['reportMutedUntil']),
    hasPassword: (json['hasPassword'] ?? true) as bool,
    linkedProviders: [for (final p in (json['linkedProviders'] as List?) ?? const []) p as String],
    savedCount: (json['savedCount'] ?? 0) as int,
  );

  static DateTime? _date(Object? value) => value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
