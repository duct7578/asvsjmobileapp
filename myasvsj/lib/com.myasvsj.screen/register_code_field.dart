import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';

/// Ô nhập mã xác thực của bước 2 Đăng ký (màn 33 của thiết kế): [length] ô vuông 50 × 58 bo 12, mỗi ô một chữ số
/// Display/M; ô sắp gõ viền brand 2, có lỗi thì viền crit.
///
/// Bên dưới các ô là một TextField thật (trong suốt, phủ kín hàng ô) nên bàn phím số, dán, tự điền mã một lần
/// (oneTimeCode) và trình đọc màn hình vẫn chạy như một ô nhập thường; gợi ý [label] nằm trong ô đó.
class RegisterCodeField extends StatefulWidget {
  const RegisterCodeField({
    super.key,
    required this.controller,
    this.length = 6,
    this.label = 'Mã xác thực',
    this.hasError = false,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final int length;

  /// Tên của ô nhập (gợi ý ẩn, đọc màn hình).
  final String label;
  final bool hasError;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<RegisterCodeField> createState() => _RegisterCodeFieldState();
}

class _RegisterCodeFieldState extends State<RegisterCodeField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    return LayoutBuilder(
      builder: (context, box) {
        // Màn hẹp: các ô co lại cho vừa, tối đa 50
        final width = ((box.maxWidth - gap * (widget.length - 1)) / widget.length).clamp(24.0, 50.0);
        return SizedBox(
          height: 58,
          child: Stack(
            children: [
              ListenableBuilder(
                listenable: widget.controller,
                builder: (context, _) {
                  final text = widget.controller.text;
                  return Row(
                    spacing: gap,
                    children: [
                      for (var i = 0; i < widget.length; i++)
                        _digitBox(i < text.length ? text[i] : '', width, current: _focus.hasFocus && i == text.length),
                    ],
                  );
                },
              ),
              Positioned.fill(
                child: Opacity(
                  opacity: 0,
                  alwaysIncludeSemantics: true,
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: widget.length,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    showCursor: false,
                    enableInteractiveSelection: false,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    decoration: InputDecoration(
                      hintText: widget.label,
                      counterText: '',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _digitBox(String digit, double width, {required bool current}) {
    final Border border = widget.hasError
        ? Border.all(color: SenpaiColors.crit, width: current ? 2 : 1.5)
        : current
            ? Border.all(color: SenpaiColors.brand, width: 2)
            : Border.all(color: SenpaiColors.line);
    return Container(
      width: width,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: SenpaiColors.surface, borderRadius: BorderRadius.circular(12), border: border),
      child: Text(digit, style: SenpaiText.displayM.copyWith(color: SenpaiColors.ink)),
    );
  }
}
