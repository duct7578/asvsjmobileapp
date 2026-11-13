import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.model/legal_document.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Văn bản pháp lý đang hiệu lực (màn 43 của thiết kế), như trang /terms của web: Điều khoản sử dụng, Chính sách
/// bảo mật, Quy tắc cộng đồng. Badge phiên bản, rồi nội dung trong một thẻ trắng bo 18: đoạn nào mở đầu bằng một
/// dòng tiêu đề ngắn ("1. Phạm vi áp dụng") thì dòng đó in Title/S, phần còn lại Body/S. Chọn và sao chép được chữ.
class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key, required this.type});

  /// Loại văn bản: 'terms' (server gọi là 'tos'), 'privacy' hoặc 'community'.
  final String type;

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() => context.read<AuthController>().loadLegal(widget.type);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      appBar: SenpaiAppBar(title: LegalDocument.titleOf(widget.type)),
      body: _body(auth),
    );
  }

  Widget _body(AuthController auth) {
    final doc = auth.legalOf(widget.type);
    if (doc == null) {
      final error = auth.legalErrorOf(widget.type);
      if (error != null && !auth.isLoadingLegal(widget.type)) {
        return ErrorView(message: error, onRetry: _load);
      }
      return const LoadingView();
    }
    final sections = _sections(doc.content);
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SenpaiBadge('Phiên bản ${doc.version}', tone: SenpaiTone.neutral, icon: Symbols.history_rounded),
          ),
          const SizedBox(height: 14),
          SenpaiCard(
            radius: 18,
            padding: const EdgeInsets.all(18),
            child: SelectionArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  for (final s in sections)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 4,
                      children: [
                        if (s.heading != null)
                          Text(s.heading!, style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
                        if (s.body.isNotEmpty) Text(s.body, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.ink)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dòng có dạng tiêu đề mục: ngắn, không kết thúc bằng dấu câu, thường mở đầu bằng số thứ tự ("1.", "II.",
  /// "Điều 3") hoặc dấu "#" của Markdown.
  static final _numbered = RegExp(r'^(#{1,6}\s+|\d+[.)]\s|[IVXLC]+\.\s|Điều\s+\d+)');

  static bool _isHeading(String line, {required bool hasBody}) {
    final text = line.trim();
    if (text.isEmpty || text.length > 80 || RegExp(r'[.,;:!?…]$').hasMatch(text)) {
      return false;
    }
    return _numbered.hasMatch(text) || hasBody;
  }

  /// Tách nội dung chữ thường thành các đoạn (cách nhau bởi dòng trống); dòng đầu của đoạn là tiêu đề nếu nó
  /// trông như tiêu đề mục.
  static List<({String? heading, String body})> _sections(String content) {
    final out = <({String? heading, String body})>[];
    for (final block in content.trim().split(RegExp(r'\n\s*\n'))) {
      final lines = block.split('\n').map((l) => l.trimRight()).where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) {
        continue;
      }
      if (_isHeading(lines.first, hasBody: lines.length > 1)) {
        out.add((heading: lines.first.trim().replaceFirst(RegExp(r'^#{1,6}\s+'), ''), body: lines.skip(1).join('\n')));
      } else {
        out.add((heading: null, body: lines.join('\n')));
      }
    }
    return out;
  }
}
