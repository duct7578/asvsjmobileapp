import 'dart:async';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/guide.dart';
import 'package:myasvsj/com.myasvsj.model/guide_activity.dart';
import 'package:myasvsj/com.myasvsj.model/guide_dao.dart';
import 'package:myasvsj/com.myasvsj.model/guide_my_progress.dart';
import 'package:myasvsj/com.myasvsj.model/guide_option.dart';
import 'package:myasvsj/com.myasvsj.model/guide_preparation.dart';
import 'package:myasvsj/com.myasvsj.model/guide_progress.dart';
import 'package:myasvsj/com.myasvsj.model/guide_section.dart';
import 'package:myasvsj/com.myasvsj.model/guide_stage_progress.dart';
import 'package:myasvsj/com.myasvsj.model/guide_task.dart';
import 'package:myasvsj/com.myasvsj.model/guide_viewer.dart';
import 'package:myasvsj/com.myasvsj.model/page_result.dart';

const guideStages = [
  GuideOption(code: 'PRE', title: 'Trước khi đi'),
  GuideOption(code: 'ARR', title: 'Khi mới đến (tuần đầu đến 3 tháng)'),
  GuideOption(code: 'LEAVE', title: 'Trước khi về nước'),
  GuideOption(code: 'HOME', title: 'Sau khi về nước'),
];

const guideTopics = [GuideOption(code: 'LIVING', title: 'Sinh hoạt'), GuideOption(code: 'TRANSPORT', title: 'Đi lại')];

const checklistTasks = [
  GuideTask(id: 10, title: 'Cài đặt ứng dụng tìm đường', notes: 'Ứng dụng tìm đường gần như luôn đúng'),
  GuideTask(id: 11, title: 'Tìm tuyến tàu đến trường'),
  GuideTask(id: 12, title: 'Nạp đủ tiền đi lại'),
];

/// Cẩm nang 24 (không checklist) và 23 (có checklist 3 việc), như dữ liệu mẫu của server.
final sampleGuides = [
  Guide(
    id: 24,
    title: 'Cách phân loại và bỏ rác tại Nhật Bản',
    summary: 'Mỗi loại rác có ngày thu gom riêng.',
    stageCode: 'ARR',
    stageName: 'Khi mới đến (tuần đầu đến 3 tháng)',
    topicCode: 'LIVING',
    topicName: 'Sinh hoạt',
    creatorName: 'Dữ liệu mẫu',
    createdAt: DateTime(2026, 11, 8),
    sections: const [
      GuideSection(heading: 'Rác cháy được', content: 'Bỏ vào **túi chỉ định**.\n- Thứ hai\n- Thứ năm'),
      GuideSection(
        heading: 'Rác tái chế',
        content: 'Xem lịch của phường.',
        referenceUrl: 'https://www.city.example.jp/gomi',
      ),
    ],
  ),
  Guide(
    id: 23,
    title: 'Hướng dẫn sử dụng tàu điện Nhật Bản',
    stageCode: 'ARR',
    stageName: 'Khi mới đến (tuần đầu đến 3 tháng)',
    topicCode: 'TRANSPORT',
    topicName: 'Đi lại',
    createdAt: DateTime(2026, 11, 8),
    sections: const [GuideSection(heading: '1. Giới thiệu', content: 'Tàu điện là phương tiện phổ biến.')],
    preparationEnabled: true,
    preparationTasks: checklistTasks,
  ),
  Guide(id: 5, title: 'Chuẩn bị hành lý', stageCode: 'PRE', stageName: 'Trước khi đi', topicName: 'Sinh hoạt'),
];

/// DAO giả của Cẩm nang: dữ liệu trong bộ nhớ, phân trang 2 cẩm nang một trang để thử "Tải thêm".
class FakeGuideDao implements GuideDao {
  FakeGuideDao({this.signedIn = true});

  /// Người xem đã đăng nhập (thành viên) hay khách.
  bool signedIn;

  static const int fakePageSize = 2;

  List<Guide> guides = List.of(sampleGuides);
  final Set<int> savedIds = {};
  final Set<int> doneIds = {};
  final Map<int, Set<int>> ticked = {};

  GuideMyProgress myProgress = GuideMyProgress(
    stage: 'ARR',
    stages: const [
      GuideStageProgress(code: 'PRE', title: 'Trước khi đi', total: 5),
      GuideStageProgress(code: 'ARR', title: 'Khi mới đến (tuần đầu đến 3 tháng)', done: 1, total: 10, current: true),
      GuideStageProgress(code: 'LEAVE', title: 'Trước khi về nước', total: 5),
      GuideStageProgress(code: 'HOME', title: 'Sau khi về nước'),
    ],
    inProgress: const [
      GuideActivity(
        id: 23,
        title: 'Hướng dẫn sử dụng tàu điện Nhật Bản',
        stageTitle: 'Khi mới đến (tuần đầu đến 3 tháng)',
        tasksDone: 1,
        tasksTotal: 3,
        percent: 33,
        nextTask: 'Tìm tuyến tàu đến trường',
      ),
    ],
    recentlyDone: [GuideActivity(id: 24, title: 'Cách phân loại và bỏ rác tại Nhật Bản', at: DateTime(2026, 11, 8))],
  );

  /// Đặt khác null để mọi lần gọi đều lỗi như server từ chối.
  ApiException? failWith;

  /// Chỉ các hàm ghi (tick, lưu, đánh dấu xong) lỗi.
  ApiException? writeFailWith;

  /// Đặt khác null để hàm ghi chờ tới khi complete (kiểm tra cập nhật lạc quan).
  Completer<void>? writeGate;

  final List<({String? stage, String? topic, String? q, String sort, int page})> listCalls = [];
  final List<({int guideId, int taskId, bool completed})> checks = [];
  final List<String> actions = [];

  void _maybeFail({bool write = false}) {
    if (failWith != null) {
      throw failWith!;
    }
    if (write && writeFailWith != null) {
      throw writeFailWith!;
    }
  }

  @override
  Future<List<GuideOption>> findStages() async {
    _maybeFail();
    return guideStages;
  }

  @override
  Future<List<GuideOption>> findTopics() async {
    _maybeFail();
    return guideTopics;
  }

  @override
  Future<PageResult<Guide>> findAll({
    String? stage,
    String? topic,
    String? q,
    String sort = 'NEWEST',
    int page = 0,
  }) async {
    _maybeFail();
    listCalls.add((stage: stage, topic: topic, q: q, sort: sort, page: page));
    final text = (q ?? '').toLowerCase();
    final all = [
      for (final g in guides)
        if ((stage == null || g.stageCode == stage) &&
            (topic == null || g.topicCode == topic) &&
            (text.isEmpty || g.title.toLowerCase().contains(text)))
          g,
    ];
    if (sort == 'TITLE') {
      all.sort((a, b) => a.title.compareTo(b.title));
    }
    final pages = (all.length / fakePageSize).ceil();
    return PageResult(
      items: all.skip(page * fakePageSize).take(fakePageSize).toList(),
      page: page,
      size: fakePageSize,
      totalItems: all.length,
      totalPages: pages,
    );
  }

  @override
  Future<Guide> findById(int id) async {
    _maybeFail();
    for (final g in guides) {
      if (g.id == id) {
        return g;
      }
    }
    throw const ApiException('Không tìm thấy cẩm nang.', statusCode: 404);
  }

  @override
  Future<GuideViewer> findViewer(int id) async {
    _maybeFail();
    final guide = await findById(id);
    final progress = guide.preparationEnabled
        ? GuideProgress.fromPreparation(_preparation(guide))
        : GuideProgress(done: doneIds.contains(id), percent: doneIds.contains(id) ? 100 : 0);
    return GuideViewer(signedIn: signedIn, member: signedIn, saved: savedIds.contains(id), progress: progress);
  }

  @override
  Future<GuidePreparation> findPreparation(int id) async {
    _maybeFail();
    final guide = await findById(id);
    if (!guide.preparationEnabled) {
      throw const ApiException('Không tìm thấy danh sách chuẩn bị.', statusCode: 404);
    }
    return _preparation(guide);
  }

  GuidePreparation _preparation(Guide guide) {
    final done = signedIn ? (ticked[guide.id] ?? const <int>{}) : const <int>{};
    final tasks = [for (final t in guide.preparationTasks) t.copyWith(completed: done.contains(t.id))];
    final count = tasks.where((t) => t.completed).length;
    return GuidePreparation(
      tasks: tasks,
      completed: count,
      total: tasks.length,
      percent: tasks.isEmpty ? 0 : count * 100 ~/ tasks.length,
      signedIn: signedIn,
    );
  }

  @override
  Future<GuidePreparation> checkTask(int guideId, int taskId, bool completed) async {
    await writeGate?.future;
    _maybeFail(write: true);
    checks.add((guideId: guideId, taskId: taskId, completed: completed));
    final set = ticked.putIfAbsent(guideId, () => {});
    completed ? set.add(taskId) : set.remove(taskId);
    return _preparation(await findById(guideId));
  }

  @override
  Future<String> save(int id) async {
    await writeGate?.future;
    _maybeFail(write: true);
    actions.add('save $id');
    savedIds.add(id);
    return 'Đã lưu cẩm nang.';
  }

  @override
  Future<String> unsave(int id) async {
    await writeGate?.future;
    _maybeFail(write: true);
    actions.add('unsave $id');
    savedIds.remove(id);
    return 'Đã bỏ lưu cẩm nang.';
  }

  @override
  Future<({String message, GuideProgress progress})> markDone(int id) async {
    await writeGate?.future;
    _maybeFail(write: true);
    actions.add('done $id');
    doneIds.add(id);
    return (message: 'Đã đánh dấu xong cẩm nang.', progress: const GuideProgress(done: true, percent: 100));
  }

  @override
  Future<({String message, GuideProgress progress})> unmarkDone(int id) async {
    await writeGate?.future;
    _maybeFail(write: true);
    actions.add('undone $id');
    doneIds.remove(id);
    return (message: 'Đã bỏ đánh dấu đã xong.', progress: const GuideProgress());
  }

  @override
  Future<GuideMyProgress> findMyProgress() async {
    _maybeFail();
    return myProgress;
  }
}
