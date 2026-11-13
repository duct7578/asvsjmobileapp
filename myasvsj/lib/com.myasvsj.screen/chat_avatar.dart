import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Ảnh đại diện tròn của một thành viên trong "Tin nhắn" (`avatar(initials, size, tone)` của thiết kế); chưa có ảnh
/// thì hiện chữ cái đầu của tên trên nền [tone].
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({super.key, required this.name, this.url = '', this.radius = 20, this.tone = SenpaiTone.brand});

  final String name;

  /// Đường dẫn ảnh của server; rỗng khi chưa có.
  final String url;
  final double radius;

  /// Màu nền / chữ khi chưa có ảnh, thường lấy từ [toneFor].
  final SenpaiTone tone;

  static const _tones = [SenpaiTone.brand, SenpaiTone.ok, SenpaiTone.lantern, SenpaiTone.ai];

  /// Tone cố định theo người: cùng [peerId] luôn cùng màu như danh sách mẫu của thiết kế; người đã chặn màu crit,
  /// tài khoản không còn hoạt động màu xám.
  static SenpaiTone toneFor(int peerId, {bool active = true, bool blocked = false}) {
    if (blocked) {
      return SenpaiTone.crit;
    }
    if (!active) {
      return SenpaiTone.neutral;
    }
    return _tones[peerId.abs() % _tones.length];
  }

  @override
  Widget build(BuildContext context) => SenpaiAvatar(name: name, imageUrl: url, size: radius * 2, tone: tone);
}
