/// Người đang đăng nhập (CurrentUserResponse của web, trả về từ `/api/auth/login`, `/api/auth/me`,
/// `/api/auth/register/complete`).
class User {
  const User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.roleLabel = '',
    this.avatarUrl,
  });

  final int id;
  final String email;
  final String displayName;

  /// USER, MODERATOR, ACADEMIC_MANAGER hoặc ADMIN (bảng `users`, cột `role`).
  final String role;

  /// Tên vai trò để hiện, ví dụ "Người dùng".
  final String roleLabel;

  /// Ảnh đại diện (đường dẫn của server); null khi chưa có.
  final String? avatarUrl;

  /// Chỉ role USER mới dùng app; staff (Moderator, Academic Manager, Admin) làm việc trên trang web.
  bool get isMember => role == 'USER';

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: (json['id'] as num).toInt(),
    email: (json['email'] ?? '') as String,
    displayName: (json['displayName'] ?? '') as String,
    role: json['role'] as String,
    roleLabel: (json['roleLabel'] ?? '') as String,
    avatarUrl: json['avatarUrl'] as String?,
  );
}
