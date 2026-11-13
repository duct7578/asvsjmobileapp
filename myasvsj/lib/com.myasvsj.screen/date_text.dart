// Cách hiện ngày giờ dùng chung cho mọi màn hình (giờ máy, kiểu Việt Nam).

/// Ngày, ví dụ 8/11/2026.
String formatDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}

/// Ngày và giờ, ví dụ 08:05 8/11/2026.
String formatDateTime(DateTime date) {
  final local = date.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  return '$hh:$mm ${formatDate(local)}';
}

/// Thời gian tương đối cho danh sách, ví dụ "vừa xong", "5 phút trước", "3 giờ trước", "2 ngày trước";
/// quá 7 ngày thì hiện ngày.
String formatTimeAgo(DateTime date, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(date.toLocal());
  if (diff.inMinutes < 1) {
    return 'vừa xong';
  }
  if (diff.inHours < 1) {
    return '${diff.inMinutes} phút trước';
  }
  if (diff.inDays < 1) {
    return '${diff.inHours} giờ trước';
  }
  if (diff.inDays <= 7) {
    return '${diff.inDays} ngày trước';
  }
  return formatDate(date);
}
