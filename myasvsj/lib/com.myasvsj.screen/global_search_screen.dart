import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/global_search_controller.dart';
import 'package:myasvsj/com.myasvsj.model/search_result.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/home_format.dart';
import 'package:myasvsj/com.myasvsj.screen/map_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/search_result_list.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/sign_in_gate.dart';

/// "Tìm kiếm" chung (màn 03 của thiết kế, `GET /api/search?q=`): một từ khóa tìm cùng lúc trong địa điểm, bài viết,
/// Hỏi-Đáp, cẩm nang, sự kiện, mẫu câu và câu hỏi thường gặp. Thanh trên cùng là nút quay lại + ô tìm kiếm viên
/// thuốc (viền brand khi đang gõ, nút xoá tròn surface-2). Gõ xong chờ một chút thì tìm, Enter thì tìm ngay.
/// Ai cũng dùng được.
class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key, this.initialQuery = ''});

  /// Chữ đã gõ ở ô tìm kiếm của trang chủ; rỗng thì mở với ô trống và gợi ý.
  final String initialQuery;

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  /// Gõ xong chờ chừng này mới hỏi server (như web).
  static const _typingDelay = Duration(milliseconds: 300);

  late final TextEditingController _text = TextEditingController(text: _clip(widget.initialQuery));
  Timer? _typing;

  static String _clip(String text) =>
      text.length > GlobalSearchController.queryMax ? text.substring(0, GlobalSearchController.queryMax) : text;

  @override
  void initState() {
    super.initState();
    // Gọi sau khung hình đầu: notifyListeners() không được chạy giữa lúc đang dựng giao diện
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<GlobalSearchController>()
        ..reset()
        ..search(_text.text, always: true);
    });
  }

  @override
  void dispose() {
    _typing?.cancel();
    _text.dispose();
    super.dispose();
  }

  void _searchNow([String? text]) {
    _typing?.cancel();
    if (text != null) {
      _text.text = text;
    }
    setState(() {});
    context.read<GlobalSearchController>().search(_text.text, always: true);
  }

  @override
  Widget build(BuildContext context) {
    final search = context.watch<GlobalSearchController>();
    final isMember = context.select<AuthController, bool>((auth) => auth.currentUser?.isMember ?? false);
    final canPop = ModalRoute.of(context)?.impliesAppBarDismissal ?? false;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 60,
        leadingWidth: 48,
        titleSpacing: canPop ? 0 : 16,
        title: Padding(padding: const EdgeInsets.only(right: 16), child: _field(search)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: search.isLoading ? const LinearProgressIndicator(minHeight: 2) : const SizedBox(height: 2),
        ),
      ),
      body: _results(search, isMember),
    );
  }

  /// Ô tìm kiếm viên thuốc cao 48: icon search (brand khi đang gõ), chữ Body/M, nút xoá tròn 32 nền surface-2.
  Widget _field(GlobalSearchController search) => TextField(
    key: const ValueKey('global-search'),
    controller: _text,
    autofocus: widget.initialQuery.trim().isEmpty,
    textInputAction: TextInputAction.search,
    style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
    inputFormatters: [LengthLimitingTextInputFormatter(GlobalSearchController.queryMax)],
    onChanged: (text) {
      setState(() {});
      _typing?.cancel();
      _typing = Timer(_typingDelay, () => search.search(text));
    },
    onSubmitted: (_) => _searchNow(),
    decoration: senpaiSearchDecoration(
      'Tìm địa điểm, bài viết, sự kiện…',
      suffixIcon: _text.text.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(right: 8),
              // Align: giữ nút tròn 32 ở giữa thay vì bị kéo cao bằng ô nhập
              child: Align(
                widthFactor: 1,
                heightFactor: 1,
                child: IconButton(
                  tooltip: 'Xóa',
                  style: IconButton.styleFrom(
                    backgroundColor: SenpaiColors.surface2,
                    foregroundColor: SenpaiColors.muted,
                    minimumSize: const Size(32, 32),
                    fixedSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Symbols.close_rounded, size: 18),
                  onPressed: () => _searchNow(''),
                ),
              ),
            ),
    ).copyWith(suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40)),
  );

  Widget _results(GlobalSearchController search, bool isMember) {
    final asked = search.asked;
    final error = search.error;
    if (asked == null) {
      // Chưa có câu trả lời nào: đang tìm, hoặc lần tìm đầu bị lỗi
      return error == null ? const SizedBox.shrink() : ErrorView(message: error, onRetry: _searchNow);
    }
    final errorLine = error == null
        ? null
        : Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
              decoration: BoxDecoration(color: SenpaiColors.critSoft, borderRadius: BorderRadius.circular(14)),
              child: Row(
                spacing: 10,
                children: [
                  const Icon(Symbols.error_rounded, size: 20, color: SenpaiColors.crit),
                  Expanded(
                    child: Text(error, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.crit)),
                  ),
                  TextButton(
                    style: SenpaiButtonStyle.ghost(
                      SenpaiButtonSize.small,
                    ).copyWith(foregroundColor: const WidgetStatePropertyAll(SenpaiColors.crit)),
                    onPressed: _searchNow,
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          );
    final result = search.result;
    final Widget body;
    if (asked.isEmpty || result == null) {
      body = _ideas();
    } else if (result.tooShort) {
      body = _message('Hãy gõ ít nhất 2 chữ hoặc số (một chữ tiếng Nhật cũng được).');
    } else if (result.isEmpty) {
      body = _nothingFound(result);
    } else {
      body = SearchResultList(result: result, isMember: isMember);
    }
    return Column(
      children: [
        ?errorLine,
        Expanded(child: body),
      ],
    );
  }

  Widget _message(String text) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
    children: [SenpaiNote(text, icon: Symbols.info_rounded, tone: SenpaiTone.neutral)],
  );

  /// Ô trống: những thứ du học sinh mới đến hay tìm.
  Widget _ideas() => ListView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
    children: [
      Text(
        'Gõ để tìm trong địa điểm, bài viết, Hỏi-Đáp, cẩm nang, sự kiện, mẫu câu tiếng Nhật và câu hỏi '
        'thường gặp.',
        style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
      ),
      const SizedBox(height: 16),
      Text('Thử tìm:', style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink)),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final idea in GlobalSearchController.ideas)
            ActionChip(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              avatar: const Icon(Symbols.search_rounded, color: SenpaiColors.muted),
              label: Text(idea),
              onPressed: () => _searchNow(idea),
            ),
        ],
      ),
    ],
  );

  /// Không tìm thấy gì: gợi ý viết lại, tìm trên Bản đồ, hoặc đặt câu hỏi (khách được mời đăng nhập trước).
  Widget _nothingFound(SearchResult result) {
    final body = SenpaiText.bodyS.copyWith(color: SenpaiColors.ink);
    Widget tip(IconData icon, String text, [Widget? action]) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 18, color: SenpaiColors.muted),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(text, style: body),
              ?action,
            ],
          ),
        ),
      ],
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'Không tìm thấy kết quả nào cho “${result.q}”.',
          style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
        ),
        const SizedBox(height: 14),
        SenpaiCard(
          radius: 20,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Row(
                spacing: 8,
                children: [
                  const IconTile(Symbols.lightbulb_rounded, size: 28, radius: 8),
                  Text('Gợi ý', style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink)),
                ],
              ),
              tip(Symbols.edit_rounded, 'Thử từ khóa ngắn hơn hoặc viết cách khác; có dấu hay không dấu đều được.'),
              tip(
                Symbols.map_rounded,
                'Bản đồ có cả địa điểm của OpenStreetMap.',
                LinkText(
                  'Mở Bản đồ',
                  trailingIcon: Symbols.arrow_forward_rounded,
                  onTap: () => pushScreen<void>(context, const MapScreen()),
                ),
              ),
              tip(
                Symbols.contact_support_rounded,
                'Chưa ai hỏi điều này?',
                LinkText('Đặt câu hỏi cho các senpai', trailingIcon: Symbols.arrow_forward_rounded, onTap: _ask),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Đặt câu hỏi cần tài khoản: khách được đưa sang Đăng nhập trước.
  Future<void> _ask() async {
    if (!await requireSignIn(context) || !mounted) {
      return;
    }
    await pushScreen<void>(context, const QuestionFormScreen());
  }
}
