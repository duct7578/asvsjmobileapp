import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/area_stage_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/home_format.dart';
import 'package:myasvsj/com.myasvsj.screen/interest_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// "Điều chỉnh" gợi ý: bottom sheet (bo 24, thanh nắm) hỏi muốn đổi khu vực và giai đoạn hay chủ đề quan tâm, rồi
/// mở màn hình tương ứng (của trang Tôi). Trả về true khi màn hình đó đã lưu (đóng bằng pop(true)), để màn hình gọi
/// tải lại gợi ý.
Future<bool> showFeedSettings(BuildContext context) async {
  final choice = await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Điều chỉnh gợi ý dành cho bạn', style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink)),
            const SizedBox(height: 8),
            SenpaiListRow(
              leading: const IconTile(Symbols.location_on_rounded),
              title: 'Khu vực và giai đoạn',
              subtitle: 'Chỉ lưu khu vực (quận, thành phố), không lưu địa chỉ hay vị trí.',
              onTap: () => Navigator.pop(sheet, 0),
            ),
            const Divider(),
            SenpaiListRow(
              leading: const IconTile(Symbols.interests_rounded, tone: SenpaiTone.ai),
              title: 'Chủ đề quan tâm',
              subtitle: 'Bài thuộc chủ đề bạn chọn được ưu tiên trong gợi ý.',
              onTap: () => Navigator.pop(sheet, 1),
            ),
          ],
        ),
      ),
    ),
  );
  if (choice == null || !context.mounted) {
    return false;
  }
  return openFeedSetting(context, areaAndStage: choice == 0);
}

/// Mở thẳng màn "Khu vực và giai đoạn" ([areaAndStage]) hoặc "Chủ đề quan tâm"; true khi đã lưu.
Future<bool> openFeedSetting(BuildContext context, {required bool areaAndStage}) async {
  final saved = await pushScreen<bool>(context, areaAndStage ? const AreaStageScreen() : const InterestScreen());
  return saved == true;
}
