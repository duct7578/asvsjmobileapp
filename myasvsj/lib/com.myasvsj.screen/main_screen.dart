import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'package:myasvsj/com.myasvsj.screen/blog_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/home_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/map_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/more_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';

/// Khung điều hướng của app: thanh tab dưới cùng giống web và prototype
/// (Trang chủ · Bản đồ · Blog · Hỏi-Đáp · Thêm).
///
/// Mỗi tab chỉ được dựng lần đầu khi người dùng mở tới nó (bản đồ không tải khi chưa cần), rồi được giữ lại
/// để quay về vẫn đúng chỗ đang xem.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _index = widget.initialTab;
  late final Set<int> _opened = {widget.initialTab};

  static Widget _tab(int index) => switch (index) {
        0 => const HomeScreen(),
        1 => const MapScreen(),
        2 => const BlogListScreen(),
        3 => const QuestionListScreen(),
        _ => const MoreScreen(),
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < 5; i++) _opened.contains(i) ? _tab(i) : const SizedBox.shrink(),
        ],
      ),
      // BottomNav của thiết kế: nền trắng, viền trên line, bóng Bar; tab đang chọn là icon đặc (Material Icons
      // Round) trong viên thuốc brand-soft, tab khác là icon viền (Material Symbols Rounded) màu muted.
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: SenpaiColors.surface,
          border: Border(top: BorderSide(color: SenpaiColors.line)),
          boxShadow: SenpaiColors.shadowBar,
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() {
            _index = i;
            _opened.add(i);
          }),
          destinations: const [
            NavigationDestination(
                icon: Icon(Symbols.home_rounded), selectedIcon: Icon(Icons.home_rounded), label: 'Trang chủ'),
            NavigationDestination(icon: Icon(Symbols.map_rounded), selectedIcon: Icon(Icons.map_rounded), label: 'Bản đồ'),
            NavigationDestination(
                icon: Icon(Symbols.article_rounded), selectedIcon: Icon(Icons.article_rounded), label: 'Blog'),
            NavigationDestination(
                icon: Icon(Symbols.question_answer_rounded),
                selectedIcon: Icon(Icons.question_answer_rounded),
                label: 'Hỏi-Đáp'),
            NavigationDestination(icon: Icon(Symbols.menu_rounded), selectedIcon: Icon(Icons.menu_rounded), label: 'Thêm'),
          ],
        ),
      ),
    );
  }
}
