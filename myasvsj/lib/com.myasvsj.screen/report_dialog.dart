import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.model/report_reason.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Hộp thoại "Báo cáo": chọn một lý do (danh sách lấy từ server) và ghi chú thêm (không bắt buộc).
///
/// ```dart
/// final choice = await showReportDialog(context, reasons: blog.reportReasons);
/// if (choice != null) await controller.reportBlog(blog.id, choice.reasonId, choice.note);
/// ```
Future<({int reasonId, String note})?> showReportDialog(
  BuildContext context, {
  required List<ReportReason> reasons,
  String title = 'Báo cáo nội dung',
}) {
  return showDialog<({int reasonId, String note})>(
    context: context,
    builder: (_) => ReportDialog(reasons: reasons, title: title),
  );
}

/// Giao diện theo `overlay()` (Dialog bo 24) của thiết kế: ô icon flag tone crit, tiêu đề Title/M, nhóm "Lý do" là
/// các dòng radio trong hộp viền line, ô "Ghi chú thêm" có nhãn phía trên, nút "Hủy" (Ghost) và "Gửi báo cáo"
/// (Primary, khoá tới khi chọn lý do).
class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key, required this.reasons, this.title = 'Báo cáo nội dung'});

  final List<ReportReason> reasons;
  final String title;

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _note = TextEditingController();
  int? _reasonId;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Center(child: IconTile(Symbols.flag_rounded, tone: SenpaiTone.crit, size: 48, radius: 24)),
      title: Text(widget.title, textAlign: TextAlign.center),
      titleTextStyle: SenpaiText.titleM.copyWith(color: SenpaiColors.ink),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Text('Lý do', style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink)),
            RadioGroup<int>(
              groupValue: _reasonId,
              onChanged: (value) => setState(() => _reasonId = value),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: SenpaiColors.line),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < widget.reasons.length; i++) ...[
                      if (i > 0) const Divider(indent: 12, endIndent: 12),
                      RadioListTile<int>(
                        value: widget.reasons[i].id,
                        title: Text(widget.reasons[i].label, style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink)),
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('Ghi chú thêm (không bắt buộc)', style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink)),
            TextField(
              controller: _note,
              maxLength: 500,
              minLines: 2,
              maxLines: 3,
              style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
              decoration: const InputDecoration(hintText: 'Mô tả thêm để Moderator xem nhanh hơn'),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(
          style: SenpaiButtonStyle.ghost(SenpaiButtonSize.medium),
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: SenpaiButtonStyle.size(SenpaiButtonSize.medium),
          onPressed: _reasonId == null
              ? null
              : () => Navigator.pop(context, (reasonId: _reasonId!, note: _note.text.trim())),
          child: const Text('Gửi báo cáo'),
        ),
      ],
    );
  }
}
