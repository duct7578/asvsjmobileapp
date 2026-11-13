/// Giai đoạn của người dùng (cột `users.stage`): mã server nhận và tên để hiện.
///
/// Mã lấy đúng từ server: `PUT /api/me/profile` chỉ nhận `PRE|ARR|LEAVE|HOME` (UpdateProfileRequest);
/// tên theo `STAGES` trong `lib/ui.js` của web.
class ProfileStage {
  const ProfileStage(this.code, this.label);

  final String code;
  final String label;

  /// Bốn giai đoạn, đúng thứ tự trên web.
  static const List<ProfileStage> all = [
    ProfileStage('PRE', 'Sắp sang Nhật'),
    ProfileStage('ARR', 'Mới đến'),
    ProfileStage('LEAVE', 'Sắp về nước'),
    ProfileStage('HOME', 'Đã về nước'),
  ];

  /// Tên của mã [code]; null khi chưa chọn hoặc mã lạ.
  static String? labelOf(String? code) {
    for (final stage in all) {
      if (stage.code == code) {
        return stage.label;
      }
    }
    return null;
  }

  /// Nhãn ô khu vực theo giai đoạn (`areaLabel` trong area-picker.js): người còn ở Việt Nam chọn khu vực
  /// sắp đến hoặc từng sống ở Nhật.
  static String areaLabel(String? code) => switch (code) {
    'PRE' => 'Khu vực bạn sắp đến',
    'HOME' => 'Khu vực bạn từng sống',
    _ => 'Khu vực bạn đang sống',
  };
}
