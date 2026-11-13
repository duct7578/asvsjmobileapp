import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Câu báo lỗi của server ở giữa màn hình (ô icon tone crit), kèm nút "Thử lại" khi có [onRetry].
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 14,
          children: [
            const IconTile(Symbols.cloud_off_rounded, tone: SenpaiTone.crit, size: 64, radius: 32),
            Text(message, textAlign: TextAlign.center, style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink)),
            if (onRetry != null)
              FilledButton.icon(
                style: SenpaiButtonStyle.size(SenpaiButtonSize.medium),
                onPressed: onRetry,
                icon: const Icon(Symbols.refresh_rounded),
                label: const Text('Thử lại'),
              ),
          ],
        ),
      ),
    );
  }
}
