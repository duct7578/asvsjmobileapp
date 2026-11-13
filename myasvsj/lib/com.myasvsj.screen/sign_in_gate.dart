import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.screen/login_screen.dart';

/// Thao tác cần tài khoản User (thích, lưu, bình luận, viết bài, nhắn tin…): khách được đưa sang màn
/// Đăng nhập trước. Trả về true khi đã đăng nhập sẵn hoặc vừa đăng nhập xong; false khi khách quay lại.
///
/// Cách dùng trong Screen:
/// ```dart
/// if (!await requireSignIn(context) || !context.mounted) return;
/// ```
Future<bool> requireSignIn(BuildContext context) async {
  if (context.read<AuthController>().isSignedIn) {
    return true;
  }
  final signedIn = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
  return signedIn == true;
}
