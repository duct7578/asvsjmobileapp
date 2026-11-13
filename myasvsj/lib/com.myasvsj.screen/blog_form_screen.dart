import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/blog_controller.dart';
import 'package:myasvsj/com.myasvsj.model/blog_compose_options.dart';
import 'package:myasvsj/com.myasvsj.model/blog_place.dart';
import 'package:myasvsj/com.myasvsj.model/media_item.dart';
import 'package:myasvsj/com.myasvsj.screen/blog_place_picker.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/media_image.dart';
import 'package:myasvsj/com.myasvsj.screen/photo_picker.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// Form viết bài (Create, khi [blogId] là null) và sửa bài (Update), màn 14 của thiết kế: ghi chú lượt đăng,
/// tiêu đề, chủ đề (chip), địa điểm liên quan, nội dung, ảnh; nút "Đăng bài" dính đáy màn hình.
/// Khi sửa, ảnh cũ giữ lại hoặc bỏ được và thêm được ảnh mới.
/// Lưu xong, màn hình đóng và trả về true để màn trước hiện câu thông báo của server.
class BlogFormScreen extends StatefulWidget {
  const BlogFormScreen({super.key, this.blogId});

  final int? blogId;

  @override
  State<BlogFormScreen> createState() => _BlogFormScreenState();
}

class _BlogFormScreenState extends State<BlogFormScreen> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _scroll = ScrollController();
  List<int> _topicIds = [];
  List<BlogPlace> _places = [];

  /// Ảnh / video đã gắn (khi sửa) còn giữ lại.
  List<MediaItem> _keptMedia = [];

  /// Ảnh mới chọn trên máy.
  List<String> _imagePaths = [];

  /// Nội dung form lúc mở, để hỏi trước khi bỏ thay đổi chưa lưu.
  String _opened = '';

  bool get _editing => widget.blogId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final blogs = context.read<BlogController>();
    await blogs.openForm(blogId: widget.blogId);
    if (!mounted) {
      return;
    }
    final old = blogs.editing;
    setState(() {
      if (old != null) {
        _title.text = old.title;
        _content.text = old.content;
        _topicIds = [...old.topicIds];
        _places = [...old.places];
        _keptMedia = [...old.media];
      }
      _opened = _snapshot();
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    _scroll.dispose();
    super.dispose();
  }

  String _snapshot() => [
    _title.text,
    _content.text,
    _topicIds,
    [for (final p in _places) p.key],
    [for (final m in _keptMedia) m.id],
    _imagePaths,
  ].join('|');

  @override
  Widget build(BuildContext context) {
    final blogs = context.watch<BlogController>();
    final ready = !blogs.isLoadingForm && blogs.composeOptions != null;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _leave(didPop),
      child: Scaffold(
        appBar: SenpaiAppBar(title: _editing ? 'Sửa bài' : 'Viết bài', close: true),
        body: _body(blogs),
        bottomNavigationBar: ready
            ? SenpaiBottomBar(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: blogs.isSaving ? null : _save,
                      icon: blogs.isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Symbols.send_rounded),
                      label: Text(_submitLabel(blogs.isSaving), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
              )
            : null,
      ),
    );
  }

  Widget _body(BlogController blogs) {
    final options = blogs.composeOptions;
    if (blogs.isLoadingForm) {
      return const LoadingView();
    }
    if (options == null) {
      // Không mở được form: chưa đăng nhập, tài khoản staff (MSG18), không phải tác giả hoặc mất mạng
      return ErrorView(message: blogs.formError ?? 'Không tải được dữ liệu. Vui lòng thử lại.', onRetry: _load);
    }
    final errors = blogs.fieldErrors;
    final help = SenpaiText.caption.copyWith(color: SenpaiColors.muted);
    final errorStyle = SenpaiText.caption.copyWith(color: SenpaiColors.crit);
    final topicsFull = _topicIds.length >= options.topicsMax;
    final showScamHint = _topicIds.any(options.scamWarningTopicIds.contains);
    final children = <Widget>[
      ?_note(blogs, options),
      if (blogs.formError != null) SenpaiNote(blogs.formError!, icon: Symbols.error_rounded, tone: SenpaiTone.crit),
      SenpaiLabeledField(
        label: 'Tiêu đề *',
        child: TextField(
          controller: _title,
          maxLength: options.titleMax,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
          decoration: InputDecoration(
            counterText: '',
            errorText: errors['title'],
          ),
        ),
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(
            'Chủ đề * (${_topicIds.length}/${options.topicsMax})',
            style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final topic in options.topics)
                FilterChip(
                  label: Text(topic.name),
                  selected: _topicIds.contains(topic.id),
                  showCheckmark: false,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onSelected: topicsFull && !_topicIds.contains(topic.id)
                      ? null
                      : (on) => setState(() {
                          _topicIds = on ? [..._topicIds, topic.id] : _topicIds.where((id) => id != topic.id).toList();
                        }),
                ),
            ],
          ),
          if (errors['topicIds'] != null)
            Text(errors['topicIds']!, style: errorStyle)
          else
            Text('Chọn từ 1 đến ${options.topicsMax} chủ đề. Không có chủ đề phù hợp thì chọn “Khác”.', style: help),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          BlogPlacePicker(
            selected: _places,
            max: options.placesMax,
            results: blogs.placeResults,
            isSearching: blogs.isSearchingPlaces,
            message: blogs.placeError,
            errorText: errors['placeIds'],
            onSearch: blogs.searchPlaces,
            onAdd: (place) {
              blogs.clearPlaceResults();
              setState(() => _places = [..._places, place]);
            },
            onRemove: (place) => setState(() => _places = _places.where((p) => p.key != place.key).toList()),
          ),
          if (showScamHint)
            const SenpaiNote(
              'Bài “Cảnh báo lừa đảo” gắn địa điểm sẽ hiện dấu “!” trên ghim của địa điểm đó trên bản đồ.',
              icon: Symbols.warning_rounded,
              tone: SenpaiTone.warn,
            ),
        ],
      ),
      SenpaiLabeledField(
        label: 'Nội dung *',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            TextField(
              controller: _content,
              minLines: 5,
              maxLines: 16,
              maxLength: options.contentMax,
              textCapitalization: TextCapitalization.sentences,
              style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
              decoration: InputDecoration(
                // 5 dòng + lề 15 trên dưới = cao 140 như textarea của thiết kế
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                counterText: '',
                errorText: errors['content'],
                errorMaxLines: 3,
              ),
            ),
            // `textarea(..., {help, count})`: ghi chú về link và bộ đếm chữ cùng một hàng, sát mép ô
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Expanded(
                  child: Text(
                    options.canPostLinks
                        ? 'Bạn có tag định danh nên được chèn link và đăng ảnh có mã QR. '
                              'Không dùng link rút gọn (bit.ly, tinyurl…).'
                        : 'Chỉ tài khoản có tag định danh mới chèn được link, số điện thoại, tài khoản Zalo, '
                              'LINE, Telegram hay ảnh có mã QR.',
                    style: help,
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _content,
                  builder: (_, value, _) =>
                      Text('${value.text.characters.length}/${options.contentMax}', style: help),
                ),
              ],
            ),
          ],
        ),
      ),
      ..._photos(options, errors['images'] ?? errors['video']),
    ];
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        // Các khối cách nhau 18 (body gap của thiết kế)
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 18),
          children[i],
        ],
      ],
    );
  }

  /// Ghi chú trên cùng: bài đang quét / bị từ chối (khi sửa), lượt đăng hôm nay của tài khoản mới (khi viết mới).
  Widget? _note(BlogController blogs, BlogComposeOptions options) {
    final status = blogs.editing?.status;
    final (String, SenpaiTone, IconData)? note = switch (status) {
      'PROCESSING' => (
        'Ảnh đang được quét; trong lúc này chỉ bạn thấy bài.',
        SenpaiTone.warn,
        Symbols.hourglass_top_rounded,
      ),
      'REJECTED' => (
        'Bài chưa được đăng vì ảnh hoặc video vi phạm Quy tắc cộng đồng (đã được gỡ). '
            'Sửa xong bấm “Lưu thay đổi” để đăng lại.',
        SenpaiTone.crit,
        Symbols.block_rounded,
      ),
      _ when !_editing && options.newAccount => (
        'Tài khoản mới, hôm nay: ${options.postsUsed}/${options.postsLimit} bài viết và review.'
            '${options.quotaFull ? ' Bạn đã dùng hết lượt đăng hôm nay, hãy quay lại vào ngày mai.' : ''}',
        options.quotaFull ? SenpaiTone.warn : SenpaiTone.lantern,
        Symbols.info_rounded,
      ),
      _ => null,
    };
    if (note == null) {
      return null;
    }
    return SenpaiNote(note.$1, tone: note.$2, icon: note.$3);
  }

  /// Ảnh: ảnh đang có (khi sửa) có nút bỏ, ô chọn ảnh mới, ghi chú giới hạn và lỗi ảnh của server.
  List<Widget> _photos(BlogComposeOptions options, String? error) {
    final caption = SenpaiText.caption.copyWith(color: SenpaiColors.muted);
    final keptImages = _keptMedia.where((m) => m.isImage).length;
    final room = options.imagesMax - keptImages;
    return [
      if (_keptMedia.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Text('Ảnh đang có', style: SenpaiText.labelM.copyWith(color: SenpaiColors.ink)),
            Wrap(spacing: 10, runSpacing: 10, children: [for (final m in _keptMedia) _keptTile(m)]),
          ],
        ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          if (room > 0)
            PhotoPicker(
              paths: _imagePaths,
              max: room,
              label: _keptMedia.isEmpty ? 'Ảnh (không bắt buộc)' : 'Ảnh mới',
              onChanged: (paths) => setState(() => _imagePaths = paths),
            )
          else
            Text('Đã đủ ${options.imagesMax} ảnh. Bỏ bớt ảnh đang có để thêm ảnh mới.', style: caption),
          Text(
            'Tối đa ${options.imagesMax} ảnh, mỗi ảnh không quá ${options.imageMaxMb} MB. App chưa đăng được video.',
            style: caption,
          ),
          if (error != null) Text(error, style: SenpaiText.caption.copyWith(color: SenpaiColors.crit)),
        ],
      ),
    ];
  }

  /// Ảnh (hoặc video đăng từ web) đã gắn vào bài, có nút bỏ.
  Widget _keptTile(MediaItem media) {
    return PhotoThumb(
      image: media.isImage
          ? MediaImage(url: media.url, radius: 0)
          : const ColoredBox(
              color: SenpaiColors.surface2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 2,
                children: [
                  Icon(Symbols.videocam_rounded, color: SenpaiColors.muted),
                  Text('Video', style: SenpaiText.labelS),
                ],
              ),
            ),
      removeTooltip: media.isImage ? 'Bỏ ảnh này' : 'Bỏ video',
      onRemove: () => setState(() => _keptMedia = _keptMedia.where((m) => m.id != media.id).toList()),
    );
  }

  String _submitLabel(bool saving) {
    if (saving) {
      return _imagePaths.isNotEmpty ? 'Đang tải lên và kiểm tra…' : 'Đang kiểm tra nội dung…';
    }
    return _editing ? 'Lưu thay đổi' : 'Đăng bài';
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final blogs = context.read<BlogController>();
    final saved = await blogs.saveBlog(
      title: _title.text,
      content: _content.text,
      topicIds: _topicIds,
      places: _places,
      keptMedia: _keptMedia,
      imagePaths: _imagePaths,
    );
    if (!mounted) {
      return;
    }
    if (saved) {
      Navigator.pop(context, true);
    } else if (_scroll.hasClients) {
      // Câu lỗi chung nằm trên cùng form
      _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  /// Bấm quay lại / đóng: còn thay đổi chưa lưu thì hỏi trước (MSG15).
  Future<void> _leave(bool didPop) async {
    if (didPop) {
      return;
    }
    final changed = context.read<BlogController>().composeOptions != null && _snapshot() != _opened;
    if (changed) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Bỏ thay đổi?'),
          content: Text(
            'Bạn có thay đổi chưa lưu. Bạn có muốn bỏ các thay đổi này không?',
            style: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Ở lại')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Bỏ thay đổi')),
          ],
        ),
      );
      if (discard != true) {
        return;
      }
    }
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
