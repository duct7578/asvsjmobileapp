import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/phrase_controller.dart';
import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/phrase.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_dao.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_group.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_marks.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_overview.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_part.dart';
import 'package:myasvsj/com.myasvsj.model/phrase_speaker.dart';
import 'package:myasvsj/com.myasvsj.model/report_reason.dart';

import 'auth_fakes.dart';

/// App để widget test màn hình Nhật ngữ: AuthController giả (khách, hoặc [testUser] khi [signedIn]) và [phrases].
Widget phraseApp(Widget home, {required PhraseController phrases, bool signedIn = false}) => MultiProvider(
  providers: [
    ChangeNotifierProvider(
      create: (_) =>
          AuthController(FakeAuthDao(current: signedIn ? testUser : null))..currentUser = signedIn ? testUser : null,
    ),
    ChangeNotifierProvider.value(value: phrases),
  ],
  child: MaterialApp(home: home),
);

/// Màn hình thử hẹp 360 dp (như điện thoại nhỏ) và đủ cao để thấy cả danh sách.
void useNarrowPhone(WidgetTester tester, {double height = 2400}) {
  tester.view.physicalSize = Size(360, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

// Dữ liệu mẫu chép từ server thật (GET /api/phrases), rút gọn còn 6 mục ở 2 loại địa điểm.
const konbini = PhraseGroup(id: 'konbini', name: 'Cửa hàng tiện lợi', icon: 'local_convenience_store');
const station = PhraseGroup(id: 'station', name: 'Ga tàu', icon: 'train');
const pay = PhraseGroup(id: 'pay', name: 'Thanh toán');
const train = PhraseGroup(id: 'train', name: 'Đi tàu');
const ask = PhraseGroup(id: 'ask', name: 'Hỏi đường, hỏi đồ');

const _topicIcons = {'pay': 'payments', 'train': 'train', 'ask': 'help'};

const reasons = [
  ReportReason(id: 5, label: 'Sai tiếng Nhật'),
  ReportReason(id: 6, label: 'Sai nghĩa'),
  ReportReason(id: 7, label: 'Xúc phạm'),
  ReportReason(id: 8, label: 'Spam'),
];

/// Sáu mục mẫu; thành viên đã thuộc mục 1 và chưa thuộc mục 14 khi [member].
List<Phrase> samplePhrases({bool member = false}) => [
  Phrase(
    id: 1,
    kind: Phrase.phraseKind,
    japanese: '袋はいりません。',
    romaji: 'Fukuro wa irimasen.',
    meaningVi: 'Tôi không cần túi.',
    category: konbini,
    topics: const [pay],
    learned: member,
  ),
  const Phrase(
    id: 2,
    kind: Phrase.phraseKind,
    japanese: '温めてください。',
    romaji: 'Atatamete kudasai.',
    meaningVi: 'Làm ơn hâm nóng giúp tôi.',
    category: konbini,
  ),
  const Phrase(
    id: 6,
    kind: Phrase.vocabKind,
    japanese: 'レジ',
    romaji: 'reji',
    meaningVi: 'Quầy thu ngân.',
    category: konbini,
    topics: [pay],
  ),
  const Phrase(
    id: 13,
    kind: Phrase.phraseKind,
    japanese: 'この電車は上野に止まりますか。',
    romaji: 'Kono densha wa Ueno ni tomarimasu ka.',
    meaningVi: 'Tàu này có dừng ở Ueno không?',
    category: station,
    topics: [train, ask],
  ),
  Phrase(
    id: 14,
    kind: Phrase.phraseKind,
    japanese: 'チャージしたいです。',
    romaji: 'Chāji shitai desu.',
    meaningVi: 'Tôi muốn nạp tiền vào thẻ IC.',
    category: station,
    topics: const [train, pay],
    learning: member,
  ),
  const Phrase(
    id: 16,
    kind: Phrase.vocabKind,
    japanese: '乗り換え',
    romaji: 'norikae',
    meaningVi: 'Đổi tàu.',
    category: station,
    topics: [train],
  ),
];

/// Trang đầu tính từ [phrases] như server: mỗi loại một phần (Mẫu câu trước), chủ đề nhiều mục nhất trước,
/// loại địa điểm theo thứ tự cố định.
PhraseOverview overviewOf(List<Phrase> phrases, {bool member = false}) {
  PhraseGroup count(PhraseGroup g, Iterable<Phrase> items) => PhraseGroup(
    id: g.id,
    name: g.name,
    icon: g.icon == 'label' ? _topicIcons[g.id] ?? 'label' : g.icon,
    count: items.length,
    learned: member ? items.where((p) => p.learned).length : 0,
  );
  PhrasePart part(String kind, String name, String icon) {
    final items = phrases.where((p) => p.kind == kind).toList();
    final topics = <String, PhraseGroup>{
      for (final p in items)
        for (final t in p.topics) t.id: t,
    };
    final topicGroups = [for (final t in topics.values) count(t, items.where((p) => p.inGroup('topic', t.id)))]
      ..sort((a, b) => b.count != a.count ? b.count.compareTo(a.count) : a.name.compareTo(b.name));
    return PhrasePart(
      kind: kind,
      name: name,
      icon: icon,
      count: items.length,
      learned: member ? items.where((p) => p.learned).length : 0,
      topics: topicGroups,
      categories: [
        for (final c in const [konbini, station])
          if (items.any((p) => p.category.id == c.id)) count(c, items.where((p) => p.category.id == c.id)),
      ],
    );
  }

  return PhraseOverview(
    parts: [part(Phrase.phraseKind, 'Mẫu câu', 'chat'), part(Phrase.vocabKind, 'Từ vựng', 'abc')],
    member: member,
    reportReasons: reasons,
  );
}

/// DAO giả: giữ mục trong bộ nhớ thay vì gọi server, để test Controller và màn hình không cần mạng.
/// [member] = người xem là thành viên đã đăng nhập (được lưu thẻ ghi nhớ, xem danh sách riêng).
class FakePhraseDao implements PhraseDao {
  FakePhraseDao({this.member = false}) : stored = samplePhrases(member: member);

  bool member;
  List<Phrase> stored;

  /// Đặt khác null để mọi lần gọi đều lỗi như server từ chối.
  ApiException? failWith;

  /// Đặt khác null để findOverview / findAll chờ tới khi hoàn thành (test trạng thái chờ, câu trả lời cũ).
  Completer<void>? hold;

  int overviewCalls = 0;
  final List<({String? topic, String? category, String? mine, String? q})> finds = [];
  final List<({int id, bool learned})> flashes = [];
  final List<int> cleared = [];
  final List<({int id, int reasonId, String note})> reports = [];

  void _maybeFail() {
    if (failWith != null) {
      throw failWith!;
    }
  }

  void _requireMember() {
    if (!member) {
      throw const ApiException('Bạn cần đăng nhập để làm việc này.', statusCode: 401);
    }
  }

  @override
  Future<PhraseOverview> findOverview() async {
    overviewCalls++;
    final gate = hold;
    if (gate != null) {
      await gate.future;
    }
    _maybeFail();
    return overviewOf(stored, member: member);
  }

  @override
  Future<List<Phrase>> findAll({String? topic, String? category, String? mine, String? q}) async {
    finds.add((topic: topic, category: category, mine: mine, q: q));
    final gate = hold;
    if (gate != null) {
      await gate.future;
    }
    _maybeFail();
    if (mine != null) {
      _requireMember();
    }
    final keyword = q?.toLowerCase();
    return stored
        .where(
          (p) =>
              (topic == null || p.inGroup('topic', topic)) &&
              (category == null || p.category.id == category) &&
              (mine == null || p.hasStatus(mine)) &&
              (keyword == null ||
                  p.japanese.contains(keyword) ||
                  p.romaji.toLowerCase().contains(keyword) ||
                  p.meaningVi.toLowerCase().contains(keyword)),
        )
        .toList();
  }

  void _mark(int id, PhraseMarks marks) {
    stored = [for (final p in stored) p.id == id ? p.withMarks(marks) : p];
  }

  @override
  Future<PhraseMarks> flash(int id, {required bool learned}) async {
    _maybeFail();
    _requireMember();
    flashes.add((id: id, learned: learned));
    final marks = PhraseMarks(
      learning: !learned,
      learned: learned,
      message: learned ? 'Đã lưu: Đã thuộc.' : 'Đã lưu: Chưa thuộc.',
    );
    _mark(id, marks);
    return marks;
  }

  @override
  Future<PhraseMarks> clearFlash(int id) async {
    _maybeFail();
    _requireMember();
    cleared.add(id);
    const marks = PhraseMarks(message: 'Đã bỏ đánh dấu.');
    _mark(id, marks);
    return marks;
  }

  @override
  Future<String> report(int id, {required int reasonId, String note = ''}) async {
    _maybeFail();
    _requireMember();
    reports.add((id: id, reasonId: reasonId, note: note));
    return 'Đã gửi báo cáo cho Biên tập viên nội dung tiếng Nhật.';
  }
}

/// Giọng đọc giả: ghi lại câu được đọc thay vì gọi flutter_tts. [hasVoice] = false giả máy chưa có giọng ja-JP.
class FakePhraseSpeaker implements PhraseSpeaker {
  bool hasVoice = true;
  final List<String> spoken = [];
  int stops = 0;

  @override
  Future<bool> speak(String text) async {
    if (!hasVoice) {
      return false;
    }
    spoken.add(text);
    return true;
  }

  @override
  Future<void> stop() async => stops++;
}
