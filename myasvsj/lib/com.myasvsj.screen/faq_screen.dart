import 'package:flutter/material.dart';

import 'package:myasvsj/com.myasvsj.screen/faq_view.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';

/// Màn "Câu hỏi thường gặp" riêng (màn 18 của thiết kế), mở từ tab Thêm, từ kết quả tìm kiếm hoặc từ "Mở riêng câu
/// này". Nội dung giống tab thứ hai của Hỏi-Đáp (FaqView); có [faqId] thì mở sẵn câu đó.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key, this.faqId});

  /// Mở sẵn câu hỏi thường gặp này (từ kết quả tìm kiếm); null = cả danh sách.
  final int? faqId;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const SenpaiAppBar(title: 'Câu hỏi thường gặp'),
    body: FaqView(faqId: faqId),
  );
}
