import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';

/// Vòng quay màu brand ở giữa màn hình khi đang tải lần đầu.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: SenpaiColors.brand, strokeWidth: 3));
}
