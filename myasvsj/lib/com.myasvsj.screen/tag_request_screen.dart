import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/tag_request_controller.dart';
import 'package:myasvsj/com.myasvsj.model/tag_compose.dart';
import 'package:myasvsj/com.myasvsj.model/tag_option.dart';
import 'package:myasvsj/com.myasvsj.model/tag_pending_request.dart';
import 'package:myasvsj/com.myasvsj.screen/app_message.dart';
import 'package:myasvsj/com.myasvsj.screen/date_text.dart';
import 'package:myasvsj/com.myasvsj.screen/error_view.dart';
import 'package:myasvsj/com.myasvsj.screen/loading_view.dart';
import 'package:myasvsj/com.myasvsj.screen/photo_picker.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_bottom_action.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_sign_in_prompt.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_tag_chip.dart';
import 'package:myasvsj/com.myasvsj.screen/profile_user_watcher.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_app_bar.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_colors.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_text.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_theme.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

/// "Xin tag định danh" (UC-U09, màn 40 của thiết kế): chọn tag trong các thẻ có nút radio (tag đã có không chọn
/// được), loại minh chứng (tag "Người Nhật" chỉ cần ảnh chân dung), một ảnh và ô đồng ý cho Kiểm duyệt viên xem
/// ảnh, rồi "Gửi yêu cầu" ở thanh dưới. Đang có yêu cầu chờ duyệt thì màn hình hiện yêu cầu đó thay cho form.
class TagRequestScreen extends StatefulWidget {
  const TagRequestScreen({super.key});

  @override
  State<TagRequestScreen> createState() => _TagRequestScreenState();
}

class _TagRequestScreenState extends State<TagRequestScreen> with ProfileUserWatcher {
  @override
  void onUserChanged(int? userId) {
    if (userId != null) {
      context.read<TagRequestController>().open();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    watchUser(user?.id);
    final tags = context.watch<TagRequestController>();
    final showForm = user != null && !tags.isLoading && tags.compose != null && tags.compose!.pending == null;
    // Lỗi chung chỉ hiện riêng khi nó không phải lỗi của một ô (lỗi ô đã hiện dưới ô đó)
    final formError =
        tags.formError != null && !tags.fieldErrors.containsValue(tags.formError) ? tags.formError : null;
    return Scaffold(
      appBar: const SenpaiAppBar(title: 'Xin tag định danh'),
      body: user == null ? const ProfileSignInPrompt(text: 'Đăng nhập để xin tag định danh.') : _body(tags),
      bottomNavigationBar: showForm
          ? ProfileBottomAction(
              error: formError,
              button: SenpaiButton(
                label: tags.isSubmitting ? 'Đang gửi…' : 'Gửi yêu cầu',
                icon: Symbols.send_rounded,
                onPressed: tags.isSubmitting ? null : () => _submit(tags),
                expand: true,
              ),
            )
          : null,
    );
  }

  Widget _body(TagRequestController tags) {
    final compose = tags.compose;
    if (tags.isLoading) {
      return const LoadingView();
    }
    if (compose == null) {
      return ErrorView(message: tags.error ?? 'Không tải được danh sách tag.', onRetry: tags.open);
    }
    final pending = compose.pending;
    if (pending != null) {
      return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [_pendingCard(pending, compose)]);
    }
    return _form(tags, compose);
  }

  /// Yêu cầu đang chờ: thẻ trắng, ô đồng hồ cát lantern, câu giải thích ngày gửi và ngày ảnh tự xóa.
  Widget _pendingCard(TagPendingRequest pending, TagCompose compose) {
    final submitted = pending.submittedAt;
    final expires = pending.expiresAt;
    return SenpaiCard(
      radius: 18,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          const IconTile(Symbols.hourglass_top_rounded, tone: SenpaiTone.lantern),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text('Đang chờ Moderator duyệt', style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
                Text(
                  'Yêu cầu tag ${pending.tagName} đang chờ duyệt'
                  '${submitted == null ? '' : ' (gửi ngày ${formatDate(submitted)})'}. '
                  'Ảnh minh chứng tự xóa sau ${compose.keepDays} ngày nếu chưa được duyệt'
                  '${expires == null ? '' : ' (ngày ${formatDate(expires)})'}. '
                  'Bạn gửi được yêu cầu mới khi có kết quả.',
                  style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _form(TagRequestController tags, TagCompose compose) {
    final errors = tags.fieldErrors;
    final tag = tags.selectedTag;
    final blocks = <Widget>[
      Text(
        'Tag cho mọi người biết bạn là ai (đang du học, đã đi làm, giáo viên…). '
        'Moderator đối chiếu ảnh minh chứng rồi mới cấp tag.',
        style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted),
      ),
      Text('Chọn tag', style: SenpaiText.titleS.copyWith(color: SenpaiColors.ink)),
      RadioGroup<int>(
        groupValue: tags.tagId,
        onChanged: tags.selectTag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [for (final option in compose.tags) _tagTile(option, selected: option.id == tags.tagId)],
        ),
      ),
      if (errors['tagId'] != null) _error(errors['tagId']!),
      if (tag != null) ..._details(tags, compose, tag),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          blocks[i],
        ],
      ],
    );
  }

  /// `tagOption`: thẻ bo 16 p14 (đang chọn: nền brand-soft viền brand 2), nút radio, nhãn tag viền màu của tag,
  /// badge "Đã có" xanh, mô tả Body/S.
  Widget _tagTile(TagOption option, {required bool selected}) {
    return RadioListTile<int>(
      value: option.id,
      enabled: !option.owned,
      selected: selected,
      // Ô radio 40 (vòng 20 ở giữa) nằm sát trên như thiết kế: lề trên 4 cho ô radio, phần chữ tự lùi thêm 10
      // để thẻ có lề 14; vòng radio cách mép trái 15, chữ bắt đầu ở 48.
      contentPadding: const EdgeInsets.fromLTRB(5, 0, 14, 0),
      minVerticalPadding: 4,
      minTileHeight: 0,
      horizontalTitleGap: 3,
      titleAlignment: ListTileTitleAlignment.top,
      tileColor: SenpaiColors.surface,
      selectedTileColor: SenpaiColors.brandSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? SenpaiColors.brand : SenpaiColors.line, width: selected ? 2 : 1),
      ),
      title: Padding(
        padding: EdgeInsets.only(top: 10, bottom: option.description.isEmpty ? 10 : 4),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ProfileTagChip(name: option.name, color: option.color),
            if (option.owned) const SenpaiBadge('Đã có', tone: SenpaiTone.ok, icon: Symbols.check_rounded),
          ],
        ),
      ),
      subtitle: option.description.isEmpty
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(option.description, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.muted)),
            ),
    );
  }

  /// Phần sau khi đã chọn tag: loại minh chứng, ảnh, ô đồng ý.
  List<Widget> _details(TagRequestController tags, TagCompose compose, TagOption tag) {
    final errors = tags.fieldErrors;
    return [
      if (tag.selfieOnly)
        const SenpaiNote('Tag này chỉ cần một ảnh chân dung của bạn.', icon: Symbols.face_rounded, tone: SenpaiTone.ai)
      else
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 6,
          children: [
            Text('Loại minh chứng', style: SenpaiText.labelS.copyWith(color: SenpaiColors.muted)),
            DropdownButtonFormField<int>(
              key: ValueKey('proof-${tag.id}'),
              initialValue: tags.proofTypeId,
              isExpanded: true,
              style: SenpaiText.bodyM.copyWith(color: SenpaiColors.ink),
              icon: const Icon(Symbols.expand_more_rounded, size: 22, color: SenpaiColors.muted),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                errorText: errors['proofTypeId'],
              ),
              hint: Text('Chọn loại minh chứng', style: SenpaiText.bodyM.copyWith(color: SenpaiColors.muted)),
              items: [
                for (final proof in tag.proofTypes)
                  DropdownMenuItem(
                    value: proof.id,
                    child: Text(proof.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: tags.selectProofType,
            ),
          ],
        ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          PhotoPicker(
            paths: tags.photoPaths,
            onChanged: tags.setPhotos,
            max: 1,
            label: tag.selfieOnly ? 'Ảnh chân dung' : 'Ảnh minh chứng',
          ),
          Text(
            'JPG, PNG hoặc HEIC, tối đa ${compose.photoMaxMb} MB.'
            '${tag.selfieOnly ? '' : ' Có thể che số thẻ và thông tin không cần thiết, chỉ cần thấy tên và loại giấy tờ.'}',
            style: SenpaiText.caption.copyWith(color: SenpaiColors.muted),
          ),
          if (errors['photo'] != null) _error(errors['photo']!),
        ],
      ),
      CheckboxListTile(
        value: tags.consent,
        onChanged: (value) => tags.setConsent(value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        // Ô checkbox nằm ngang dòng chữ đầu (checkbox(..., {top: true}) của thiết kế)
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: 0,
        minTileHeight: 0,
        horizontalTitleGap: 2,
        titleAlignment: ListTileTitleAlignment.top,
        checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'Tôi đồng ý cho Kiểm duyệt viên xem ảnh này. Ảnh sẽ bị xóa sau khi duyệt hoặc sau ${compose.keepDays} ngày.',
            style: SenpaiText.bodyS.copyWith(color: SenpaiColors.ink),
          ),
        ),
        subtitle: errors['consent'] == null
            ? null
            : Text(errors['consent']!, style: SenpaiText.caption.copyWith(color: SenpaiColors.crit)),
      ),
    ];
  }

  static Widget _error(String text) => Text(text, style: SenpaiText.bodyS.copyWith(color: SenpaiColors.crit));

  Future<void> _submit(TagRequestController tags) async {
    final sent = await tags.submit();
    if (sent && mounted) {
      showMessage(context, tags.takeMessage());
    }
  }
}
