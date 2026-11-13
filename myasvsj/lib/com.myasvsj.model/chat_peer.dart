/// Thành viên ở đầu bên kia của một cuộc trò chuyện (`peer` trong JSON tin nhắn của web).
///
/// JSON: `{id, displayName, avatarUrl, tags: [{name, color}], active}`.
class ChatPeer {
  const ChatPeer({
    required this.id,
    required this.displayName,
    this.avatarUrl = '',
    this.tags = const [],
    this.active = true,
  });

  final int id;
  final String displayName;

  /// Ảnh đại diện (đường dẫn của server); rỗng khi chưa có.
  final String avatarUrl;

  /// Tag định danh đã được cấp, ví dụ (name: "Mentor", color: "#C2456E").
  final List<({String name, String color})> tags;

  /// Thành viên (role USER) còn hoạt động: loại tài khoản duy nhất nhắn tin được.
  final bool active;

  factory ChatPeer.fromJson(Map<String, dynamic> json) => ChatPeer(
    id: (json['id'] ?? 0) as int,
    displayName: (json['displayName'] ?? '') as String,
    avatarUrl: (json['avatarUrl'] ?? '') as String,
    tags: [
      for (final tag in (json['tags'] as List?) ?? const [])
        if (tag is Map<String, dynamic>) (name: (tag['name'] ?? '') as String, color: (tag['color'] ?? '') as String),
    ],
    active: (json['active'] ?? false) as bool,
  );
}
