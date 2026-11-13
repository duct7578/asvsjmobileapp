import 'package:flutter/material.dart';

/// Hiện câu thông báo của server ở cuối màn hình (SnackBar). Bỏ qua khi [text] rỗng.
void showMessage(BuildContext context, String? text) {
  if (text == null || text.isEmpty) {
    return;
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}
