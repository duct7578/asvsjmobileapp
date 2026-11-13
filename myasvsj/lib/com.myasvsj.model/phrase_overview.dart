import 'package:myasvsj/com.myasvsj.model/phrase.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_group.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_marks.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_part.dart';
import 'package:myasvsj/com.myasvsj.model/report_reason.dart';

/// Trang đầu Nhật ngữ (Overview của `GET /api/phrases/overview`): hai phần Mẫu câu và Từ vựng, người xem có phải
/// thành viên không (chỉ thành viên được lưu thẻ ghi nhớ và báo lỗi), và các lý do báo lỗi mẫu câu.
class PhraseOverview {
  const PhraseOverview({this.parts = const [], this.member = false, this.reportReasons = const []});

  /// Theo thứ tự server gửi: Mẫu câu, rồi Từ vựng.
  final List<PhrasePart> parts;

  /// Thành viên (role USER, đang hoạt động) đã đăng nhập.
  final bool member;

  /// Sai tiếng Nhật, Sai nghĩa, Xúc phạm, Spam.
  final List<ReportReason> reportReasons;

  factory PhraseOverview.fromJson(Map<String, dynamic> json) => PhraseOverview(
    parts: [for (final p in (json['parts'] as List?) ?? const []) PhrasePart.fromJson(p as Map<String, dynamic>)],
    member: (json['member'] ?? false) as bool,
    reportReasons: ReportReason.listFrom(json['reportReasons']),
  );

  /// Phần của loại [kind]; null khi server không gửi.
  PhrasePart? part(String kind) {
    for (final p in parts) {
      if (p.kind == kind) {
        return p;
      }
    }
    return null;
  }

  /// Hai phần theo thứ tự trang hiện: Từ vựng, rồi Mẫu câu.
  List<PhrasePart> get shownParts => [
    for (final kind in Phrase.kinds)
      if (part(kind) != null) part(kind)!,
  ];

  /// Chủ đề ([by] = "topic") hoặc loại địa điểm ([by] = "category") có ít nhất một mục, mỗi nhóm một lần,
  /// theo thứ tự server gửi.
  List<PhraseGroup> groupsOf(String by) {
    final seen = <String, PhraseGroup>{};
    for (final p in parts) {
      for (final g in p.groupsOf(by)) {
        seen.putIfAbsent(g.id, () => g);
      }
    }
    return seen.values.toList();
  }

  /// Chủ đề [topicId] hoặc loại địa điểm [categoryId]; null khi không có.
  PhraseGroup? findGroup({String? topicId, String? categoryId}) {
    final by = topicId != null ? 'topic' : 'category';
    final id = topicId ?? categoryId;
    for (final g in groupsOf(by)) {
      if (g.id == id) {
        return g;
      }
    }
    return null;
  }

  /// Số "đã thuộc" sau khi [phrase] đổi dấu thành [marks]: phần của loại đó, các chủ đề và loại địa điểm của nó
  /// cộng hoặc trừ 1 (như applyMarks của web), để thanh tiến độ đúng mà không phải tải lại.
  PhraseOverview withMarks(Phrase phrase, PhraseMarks marks) {
    if (marks.learned == phrase.learned) {
      return this;
    }
    final delta = marks.learned ? 1 : -1;
    final topicIds = {for (final t in phrase.topics) t.id};
    PhraseGroup bump(PhraseGroup g) => g.copyWith(learned: g.learned + delta);
    return PhraseOverview(
      member: member,
      reportReasons: reportReasons,
      parts: [
        for (final p in parts)
          if (p.kind != phrase.kind)
            p
          else
            p.copyWith(
              learned: p.learned + delta,
              topics: [for (final t in p.topics) topicIds.contains(t.id) ? bump(t) : t],
              categories: [for (final c in p.categories) c.id == phrase.category.id ? bump(c) : c],
            ),
      ],
    );
  }
}
