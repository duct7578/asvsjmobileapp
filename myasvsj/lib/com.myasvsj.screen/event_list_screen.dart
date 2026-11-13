import 'dart:async';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/event_controller.dart';
import 'package:myasvsj/com.myasvsj.model/event.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/empty_view.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/event_card.dart';
import 'package:myasvsj/com.myasvsj.screen/event_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/event_review_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';
import 'package:myasvsj/com.myasvsj.screen/sign_in_gate.dart';

/// Danh sách "Lễ hội và sự kiện" (màn 19 của thiết kế, `GET /api/events?q=`): ô tìm dạng viên thuốc, câu giới
/// thiệu, rồi các nhóm như web — Đang diễn ra, Trong 30 ngày tới, Sau này, Đã diễn ra — mỗi nhóm có tiêu đề
/// Title/M kèm số đếm và các [EventCard]. Gõ để tìm theo tên, nơi tổ chức hoặc chi phí. Server trả cả danh sách
/// nên không có "Tải thêm".
class EventListScreen extends StatefulWidget {
  const EventListScreen({super.key});

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  /// Chờ người dùng ngừng gõ một chút rồi mới tìm (như web).
  static const Duration _searchDelay = Duration(milliseconds: 250);

  final _search = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<EventController>().loadEvents(q: ''));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = context.watch<EventController>();
    return Scaffold(
      appBar: const SenpaiAppBar(title: 'Lễ hội và sự kiện'),
      body: Column(
        children: [
          // Ô tìm đứng yên trên đầu, danh sách cuộn bên dưới
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _search,
              maxLength: 100,
              textInputAction: TextInputAction.search,
              style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
              decoration: senpaiSearchDecoration(
                'Tìm sự kiện hoặc nơi tổ chức',
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa từ khóa',
                        icon: const Icon(Symbols.close_rounded, size: 22),
                        onPressed: _clear,
                      ),
              ).copyWith(counterText: ''),
              onChanged: _onChanged,
              onSubmitted: (text) {
                _timer?.cancel();
                events.loadEvents(q: text);
              },
            ),
          ),
          Expanded(child: _body(events)),
        ],
      ),
    );
  }

  Widget _body(EventController events) {
    if (events.isLoading && events.events.isEmpty) {
      return const LoadingView();
    }
    if (events.error != null) {
      return ErrorView(message: events.error!, onRetry: events.loadEvents);
    }
    final sections = <(String, List<Event>)>[
      ('Đang diễn ra', events.nowEvents),
      ('Trong 30 ngày tới', events.soonEvents),
      ('Sau này', events.laterEvents),
      ('Đã diễn ra (vẫn viết review được)', events.pastEvents),
    ];
    final children = <Widget>[
      Text(
        'Do Moderator đăng. Sự kiện đang hoặc sắp diễn ra cũng hiện trên bản đồ. '
        'Ai đã đi có thể viết review và đăng ảnh cho năm đó.',
        style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
      ),
      if (events.events.isEmpty)
        EmptyView(
          text: events.query.isEmpty ? 'Chưa có sự kiện nào.' : 'Không có sự kiện nào khớp.',
          icon: Symbols.festival_rounded,
        ),
      for (final (title, list) in sections)
        if (list.isNotEmpty) ...[
          _GroupHeader(title: title, count: list.length),
          for (final event in list)
            EventCard(
              event: event,
              onTap: () => _openDetail(event.id),
              onWriteReview: () => _writeReview(event.id),
            ),
        ],
    ];
    return RefreshIndicator(
      onRefresh: events.loadEvents,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(height: 14),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }

  void _onChanged(String text) {
    setState(() {}); // vẽ lại nút xóa từ khóa
    _timer?.cancel();
    _timer = Timer(_searchDelay, () => context.read<EventController>().loadEvents(q: text));
  }

  void _clear() {
    _timer?.cancel();
    _search.clear();
    setState(() {});
    context.read<EventController>().loadEvents(q: '');
  }

  Future<void> _openDetail(int eventId) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => EventDetailScreen(eventId: eventId)));

  /// Viết review cần tài khoản User: khách được đưa sang đăng nhập trước.
  Future<void> _writeReview(int eventId) async {
    if (!await requireSignIn(context) || !mounted) {
      return;
    }
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => EventReviewFormScreen(eventId: eventId)),
    );
    if (saved == true && mounted) {
      showMessage(context, context.read<EventController>().takeMessage());
    }
  }
}

/// Tiêu đề nhóm: tên Title/M và số sự kiện trong badge brand đặc. Trình đọc màn hình đọc "Đang diễn ra (2)".
class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      header: true,
      label: '$title ($count)',
      excludeSemantics: true,
      child: Row(
        spacing: 8,
        children: [
          Flexible(child: Text(title, style: SenpaiText.titleM.copyWith(color: SenpaiColors.ink))),
          SenpaiBadge('$count', tone: SenpaiTone.solid),
        ],
      ),
    );
  }
}
