// Ảnh các màn Hỏi-Đáp (15 Hỏi-Đáp, 16 Câu hỏi, 17 Đặt câu hỏi, 18 Câu hỏi thường gặp) để so với
// design/figma-export/ref/15-…png … 18-…png. Dữ liệu thử dùng lại câu chữ mẫu của thiết kế.
// Chạy: flutter test test/design_shots/qa_shot_test.dart --dart-define=SHOTS=true
//
// Ảnh tham chiếu có thanh trạng thái giả cao 44 (và thanh tab dưới 82 ở màn 15): khổ ảnh Flutter trừ đi phần đó.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:myasvsj/com.myasvsj.controller/auth_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/faq_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/notification_controller.dart';
import 'package:myasvsj/com.myasvsj.controller/question_controller.dart';
import 'package:myasvsj/com.myasvsj.model/answer.dart';
import 'package:myasvsj/com.myasvsj.model/author.dart';
import 'package:myasvsj/com.myasvsj.model/faq_dao.dart';
import 'package:myasvsj/com.myasvsj.model/faq_entry.dart';
import 'package:myasvsj/com.myasvsj.model/faq_resource.dart';
import 'package:myasvsj/com.myasvsj.model/faq_topic.dart';
import 'package:myasvsj/com.myasvsj.model/page_result.dart';
import 'package:myasvsj/com.myasvsj.model/question.dart';
import 'package:myasvsj/com.myasvsj.model/question_compose.dart';
import 'package:myasvsj/com.myasvsj.model/question_dao.dart';
import 'package:myasvsj/com.myasvsj.model/question_overview.dart';
import 'package:myasvsj/com.myasvsj.model/topic.dart';
import 'package:myasvsj/com.myasvsj.model/user.dart';
import 'package:myasvsj/com.myasvsj.screen/faq_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_detail_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_form_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/question_list_screen.dart';
import 'package:myasvsj/com.myasvsj.screen/senpai_ui.dart';

import '../auth_fakes.dart';
import '../faq_fakes.dart';
import '../qa_test_app.dart';
import '../question_fakes.dart';
import 'shot_helper.dart';

const _linh = User(id: 1, email: 'linh@example.com', displayName: 'Linh Nguyễn', role: 'USER', roleLabel: 'Người dùng');

// Người viết mẫu: id chọn để tone ảnh đại diện giống thiết kế (L brand, H ok, M lantern, K ai, P ok).
const _lan = Author(id: 4, displayName: 'Lan', tagNames: ['Du học sinh']);
const _huy = Author(id: 2, displayName: 'Quang Huy', tagNames: ['Đã đi làm']);
const _mai = Author(id: 5, displayName: 'Mai', tagNames: ['Du học sinh']);
const _khanh = Author(id: 3, displayName: 'Khánh');
const _phuc = Author(id: 6, displayName: 'Phúc');

const _visa = Topic(id: 1, name: 'Visa');
const _papers = Topic(id: 2, name: 'Giấy tờ');
const _work = Topic(id: 3, name: 'Việc làm thêm');

DateTime _ago(Duration d) => DateTime.now().subtract(d);

/// Danh sách và thống kê như màn 15.
class _ShotQuestionDao extends FakeQuestionDao {
  @override
  Future<PageResult<Question>> findAll({
    String? q,
    List<int> topicIds = const [],
    String status = 'ALL',
    String sort = 'NEWEST',
    int page = 0,
    int size = QuestionDao.pageSize,
  }) async {
    final items = [
      Question(
        id: 1,
        title: 'Gia hạn visa du học cần mang những giấy tờ gì?',
        content: 'Visa mình hết hạn tháng 1, trường đã cấp giấy chứng nhận đi học. Cần thêm sổ ngân hàng không?',
        solved: true,
        author: _lan,
        topics: const [_visa],
        places: const [(id: 1, name: 'Cục XNC Tokyo')],
        likeCount: 14,
        answerCount: 5,
        createdAt: _ago(const Duration(days: 7)),
      ),
      Question(
        id: 2,
        title: 'Đổi bằng lái Việt Nam sang bằng Nhật ở Saitama mất bao lâu?',
        content: 'Mình đã dịch bằng ở JAF, giờ cần đặt lịch ở trung tâm Kōnosu thế nào?',
        unanswered: true,
        author: _khanh,
        topics: const [_papers],
        likeCount: 2,
        createdAt: _ago(const Duration(hours: 3)),
      ),
      Question(
        id: 3,
        title: 'Làm thêm quá 28 tiếng/tuần vào kỳ nghỉ có bị sao không?',
        content: 'Kỳ nghỉ dài được làm 40 tiếng/tuần, nhưng nghỉ ngắn thì tính thế nào?',
        pinned: true,
        author: _phuc,
        topics: const [_work],
        likeCount: 9,
        answerCount: 3,
        createdAt: _ago(const Duration(days: 1)),
      ),
    ];
    return PageResult(items: items, page: 0, size: 10, totalItems: 1204, totalPages: 121);
  }

  @override
  Future<QuestionOverview> findOverview() async =>
      const QuestionOverview(
        topics: [_visa, _papers, _work],
        total: 1204,
        unanswered: 86,
        solved: 932,
        popularTopics: [(topic: _visa, count: 120), (topic: _papers, count: 98), (topic: _work, count: 64)],
        topAnswerers: [(author: _huy, answerCount: 42, bestCount: 12), (author: _mai, answerCount: 17, bestCount: 0)],
      );

  @override
  Future<QuestionCompose> findCompose() async => const QuestionCompose(
    topics: [_papers, _visa, Topic(id: 4, name: 'Nhà ở'), _work, Topic(id: 5, name: 'Học tập'), Topic(id: 6, name: 'Khác')],
    imagesMax: 4,
  );
}

/// Câu hỏi đã giải quyết của màn 16: câu hay nhất có một phản hồi, thêm một câu trả lời khác.
Question _detail() => Question(
  id: 1,
  title: 'Gia hạn visa du học cần mang những giấy tờ gì?',
  content:
      'Visa của mình hết hạn ngày 20/1. Trường đã cấp giấy chứng nhận đi học và bảng điểm. Mình có cần mang thêm sổ '
      'ngân hàng hay giấy xác nhận làm thêm không ạ? Nộp ở Shinagawa có phải xếp hàng lâu không?',
  edited: true,
  author: _lan,
  topics: const [_visa],
  places: const [(id: 1, name: 'Cục xuất nhập cảnh Tokyo')],
  likeCount: 14,
  answerCount: 3,
  bestAnswerId: 11,
  solved: true,
  createdAt: _ago(const Duration(days: 7)),
  signedIn: true,
  canInteract: true,
  saved: true,
  answers: [
    Answer(
      id: 11,
      author: _huy,
      content:
          'Mang: hộ chiếu, thẻ cư trú, giấy chứng nhận đi học, bảng điểm và tỷ lệ đi học, ảnh 4×3, tem 4.000 yên (mua '
          'sau khi được duyệt). Sổ ngân hàng không bắt buộc nhưng nên mang. Đi Shinagawa trước 8h30 cho đỡ đông.',
      best: true,
      liked: true,
      likeCount: 21,
      createdAt: _ago(const Duration(days: 6)),
      replies: [
        Answer(
          id: 12,
          parentId: 11,
          author: _lan,
          content: 'Cảm ơn anh, em đi hôm qua mất 2 tiếng là xong!',
          createdAt: _ago(const Duration(days: 5)),
        ),
      ],
    ),
    Answer(
      id: 13,
      author: _mai,
      content: 'Nếu có làm thêm thì mang thêm giấy xác nhận thu nhập, nhiều bạn bị hỏi.',
      likeCount: 4,
      createdAt: _ago(const Duration(days: 5)),
    ),
  ],
  reportReasons: reportReasons,
);

/// Chủ đề và câu hỏi thường gặp như màn 18 và gợi ý của màn 17.
class _ShotFaqDao extends FakeFaqDao {
  _ShotFaqDao() {
    entries
      ..clear()
      ..addAll([
        FaqEntry(
          id: 1,
          question: 'Đổ rác ở Nhật phân loại thế nào?',
          answer:
              'Rác cháy được (giấy, đồ ăn) đổ 2 lần mỗi tuần; rác không cháy, chai PET, lon, chai thủy tinh đổ riêng '
              'theo lịch của quận. Bỏ rác trước 8 giờ sáng đúng ngày, dùng túi trong suốt hoặc túi quy định.',
          topicCode: 'LIVING',
          topicName: 'Đời sống',
          updatedAt: DateTime(2026, 10, 2),
          resources: const [
            FaqResource(kind: 'EXTERNAL', url: 'https://www.city.arakawa.tokyo.jp/', label: 'Lịch đổ rác quận Arakawa (PDF)'),
          ],
        ),
        const FaqEntry(id: 2, question: 'Mua SIM giá rẻ khi chưa có thẻ ngân hàng?', topicCode: 'LIVING', topicName: 'Đời sống'),
        const FaqEntry(id: 3, question: 'Chuyển nhà thì phải báo những đâu?', topicCode: 'PAPERS', topicName: 'Giấy tờ'),
      ]);
    relatedResult = const [
      FaqEntry(id: 7, question: 'Đổi bằng lái nước ngoài (外免切替) cần giấy tờ gì?', topicName: 'Giấy tờ'),
      FaqEntry(id: 8, question: 'Thi lý thuyết đổi bằng có tiếng Việt không?', topicName: 'Giấy tờ'),
    ];
  }

  @override
  Future<PageResult<FaqEntry>> findAll({String? q, String? topic, int page = 0, int size = FaqDao.pageSize}) async {
    final result = await super.findAll(q: q, topic: topic, page: page, size: size);
    return PageResult(items: result.items, page: 0, size: 10, totalItems: 64, totalPages: 7);
  }

  @override
  Future<List<FaqTopic>> findTopics({String? q}) async => const [
    FaqTopic(code: 'PAPERS', title: 'Giấy tờ', count: 18),
    FaqTopic(code: 'HOUSING', title: 'Nhà ở', count: 12),
    FaqTopic(code: 'LIVING', title: 'Đời sống', count: 20),
    FaqTopic(code: 'OTHER', title: 'Khác', count: 14),
  ];
}

Widget _app(Widget home, {FakeQuestionDao? questions, FakeFaqDao? faqs, User? user = _linh}) => MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthController(FakeAuthDao(current: user))..restoreSession()),
    ChangeNotifierProvider(create: (_) => NotificationController(QaFakeNotificationDao())),
    ChangeNotifierProvider(create: (_) => QuestionController(questions ?? _ShotQuestionDao())),
    ChangeNotifierProvider(
      create: (_) => FaqController(faqs ?? _ShotFaqDao(), suggestDelay: const Duration(milliseconds: 10)),
    ),
  ],
  child: shotApp(home),
);

/// Màn trước trống tự mở [screen] ngay khi dựng, để màn con có nút quay lại / đóng như ảnh thiết kế.
class _Pushed extends StatefulWidget {
  const _Pushed(this.screen);

  final Widget screen;

  @override
  State<_Pushed> createState() => _PushedState();
}

class _PushedState extends State<_Pushed> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => widget.screen)),
    );
  }

  @override
  Widget build(BuildContext context) => const Scaffold();
}

void main() {
  testWidgets('15 Hỏi-Đáp', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, _app(const QuestionListScreen()), height: 718);
    await saveShot(tester, '15-hoi-dap');
  });

  testWidgets('15 Hỏi-Đáp — cả danh sách', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, _app(const QuestionListScreen()), height: 1300);
    await saveShot(tester, '15-hoi-dap-full');
  });

  testWidgets('15 Hỏi-Đáp — mở thống kê chi tiết', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, _app(const QuestionListScreen()), height: 900);
    await tester.tap(find.byTooltip('Xem thêm thống kê'));
    await settleShot(tester);
    await saveShot(tester, '15-hoi-dap-stats-open');
  });

  testWidgets('15 Hỏi-Đáp — tab Câu hỏi thường gặp, khách', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, _app(const QuestionListScreen(initialTab: 1), user: null), height: 800);
    await saveShot(tester, '15-hoi-dap-faq-tab-guest');
  });

  testWidgets('16 Câu hỏi', skip: shotSkip != null, (tester) async {
    final dao = _ShotQuestionDao()..details[1] = _detail();
    await pumpShot(tester, _app(const _Pushed(QuestionDetailScreen(questionId: 1)), questions: dao), height: 1069);
    await saveShot(tester, '16-cau-hoi');
  });

  testWidgets('16 Câu hỏi — khách, chưa có câu trả lời', skip: shotSkip != null, (tester) async {
    final dao = FakeQuestionDao();
    dao.details[1] = detailOf(
      1,
      'Mua SIM data giá rẻ ở đâu gần Nippori ạ?',
      content: 'Em mới sang được 3 ngày, cần SIM data rẻ để dùng bản đồ.',
      signedIn: false,
      canInteract: false,
      likes: 3,
    );
    await pumpShot(tester, _app(const _Pushed(QuestionDetailScreen(questionId: 1)), questions: dao, user: null), height: 800);
    await saveShot(tester, '16-cau-hoi-guest');
  });

  testWidgets('17 Đặt câu hỏi', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, _app(const _Pushed(QuestionFormScreen())), height: 1009);
    final title = find.descendant(of: find.widgetWithText(SenpaiLabeledField, 'Câu hỏi *'), matching: find.byType(TextField));
    await tester.enterText(title, 'Đổi bằng lái Việt Nam sang bằng Nhật ở Saitama mất bao lâu?');
    await tester.tap(find.widgetWithText(FilterChip, 'Giấy tờ'));
    await settleShot(tester);
    await saveShot(tester, '17-dat-cau-hoi');
  });

  testWidgets('18 Câu hỏi thường gặp', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, _app(const _Pushed(FaqScreen())), height: 800);
    await tester.tap(find.text('Đổ rác ở Nhật phân loại thế nào?'));
    await settleShot(tester);
    await saveShot(tester, '18-cau-hoi-thuong-gap');
  });

  testWidgets('18 Câu hỏi thường gặp — cả trang', skip: shotSkip != null, (tester) async {
    await pumpShot(tester, _app(const _Pushed(FaqScreen())), height: 1100);
    await tester.tap(find.text('Đổ rác ở Nhật phân loại thế nào?'));
    await settleShot(tester);
    await saveShot(tester, '18-cau-hoi-thuong-gap-full');
  });
}
