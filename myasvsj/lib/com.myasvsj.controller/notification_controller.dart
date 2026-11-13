import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:myasvsj/com.myasvsj.model/api_exception.dart';
import 'package:myasvsj/com.myasvsj.model/app_notification.dart';
import 'package:myasvsj/com.myasvsj.model/live_dao.dart';
import 'package:myasvsj/com.myasvsj.model/live_event.dart';
import 'package:myasvsj/com.myasvsj.model/notification_dao.dart';
import 'package:myasvsj/com.myasvsj.model/notification_device.dart';
import 'package:myasvsj/com.myasvsj.model/user.dart';

/// Controller của "Thông báo": danh sách thông báo, số chưa đọc trên cái chuông (AppBarActions đọc [unreadCount]),
/// và luồng tức thì `GET /api/me/live` dùng chung cho cả app.
///
/// Khi đã đăng nhập ([onSignedInChanged]) và có [LiveDao]: giữ một kết nối SSE, tự mở lại khi rớt (chờ lâu dần
/// [retryFirst] → [retryMax], như `live.js` của web). Gặp sự kiện `notification` thì hỏi summary, cập nhật
/// [unreadCount] và hiện thông báo mới trên máy ([NotificationDevice]). Mọi sự kiện được phát lại ở [liveEvents]
/// cho ChatController.
///
/// Hàm tạo chỉ cần DAO (widget test của mọi màn hình tạo `NotificationController(daoGiả)`); không gọi mạng hay plugin.
class NotificationController extends ChangeNotifier {
  NotificationController(
    this._dao, {
    LiveDao? live,
    NotificationDevice? device,
    this.retryFirst = const Duration(seconds: 5),
    this.retryMax = const Duration(seconds: 60),
    this.reopenDelay = const Duration(seconds: 3),
    this.silenceLimit = const Duration(seconds: 75),
  }) : _live = live,
       _device = device,
       _retry = retryFirst;

  final NotificationDao _dao;
  final LiveDao? _live;
  final NotificationDevice? _device;

  /// Chờ trước khi mở lại luồng không mở được (mất mạng, server lỗi); gấp đôi sau mỗi lần, tối đa [retryMax].
  final Duration retryFirst;
  final Duration retryMax;

  /// Chờ trước khi mở lại luồng đã chạy rồi kết thúc bình thường (server đóng mỗi luồng sau 5 phút).
  final Duration reopenDelay;

  /// Không nhận được gì (kể cả dòng `:ping` 25 giây một lần) trong khoảng này thì coi như kết nối đã chết.
  final Duration silenceLimit;

  /// Số thông báo chưa đọc của người đang đăng nhập; 0 khi là khách.
  int unreadCount = 0;

  // ----- Danh sách (NotificationScreen)
  List<AppNotification> items = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = false;
  String? error;
  int _page = 0;
  bool _loaded = false;

  /// Câu báo lỗi sau một thao tác ghi; màn hình hiện một lần bằng [takeMessage].
  String? message;

  // ----- Luồng tức thì
  /// Luồng SSE đang mở (đã nhận sự kiện `ready`).
  bool isLiveConnected = false;

  User? _user;
  int? _latestSeenId;
  StreamSubscription<LiveEvent>? _liveSub;
  StreamSubscription<String>? _tapSub;
  Timer? _retryTimer;
  Timer? _silenceTimer;
  Duration _retry;
  bool _summaryBusy = false;
  bool _summaryAgain = false;
  bool _disposed = false;
  String? _openLink;

  final StreamController<LiveEvent> _events = StreamController<LiveEvent>.broadcast();

  /// Mọi sự kiện của luồng tức thì (trừ `ping`), cho các Controller khác nghe (ChatController).
  late final Stream<LiveEvent> liveEvents = _events.stream;

  /// Người dùng hiện tại mà Controller đang phục vụ (null: khách).
  User? get user => _user;

  // ---------------------------------------------------------------- Đăng nhập / đăng xuất

  /// Gọi mỗi khi người đăng nhập đổi (NotificationHost hoặc ProxyProvider gọi). Đăng nhập: hỏi summary, mở luồng
  /// tức thì, xin quyền thông báo. Đăng xuất: đóng luồng, xóa dữ liệu của người cũ.
  void onSignedInChanged(User? user) {
    if (user?.id == _user?.id) {
      return;
    }
    _stopLive();
    _user = user;
    items = [];
    hasMore = false;
    error = null;
    message = null;
    _loaded = false;
    _page = 0;
    unreadCount = 0;
    _latestSeenId = null;
    _notify();
    if (user == null) {
      return;
    }
    final device = _device;
    if (device != null) {
      _tapSub ??= device.taps.listen(_openFromDevice);
      unawaited(device.requestPermission());
      unawaited(
        device.takeLaunchLink().then((link) {
          if (link != null) {
            _openFromDevice(link);
          }
        }),
      );
    }
    unawaited(refreshSummary());
    _connect();
  }

  /// App vừa mở lại từ nền: hỏi summary một lần và mở lại luồng nếu đã rớt.
  void onAppResumed() {
    if (_user == null) {
      return;
    }
    unawaited(refreshSummary());
    if (_liveSub == null) {
      _retry = retryFirst;
      _connect();
    }
  }

  // ---------------------------------------------------------------- Read

  /// Trang đầu của danh sách thông báo (kéo xuống làm mới cũng gọi hàm này).
  Future<void> loadNotifications() async {
    isLoading = true;
    error = null;
    _notify();
    try {
      final page = await _dao.findAll();
      items = page.items;
      hasMore = page.hasMore;
      unreadCount = page.unread;
      _page = 0;
      _loaded = true;
      // Thông báo đã thấy trong danh sách thì không hiện lại trên máy
      if (page.items.isNotEmpty) {
        _latestSeenId = math.max(_latestSeenId ?? 0, page.items.first.id);
      }
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      isLoading = false;
      _notify();
    }
  }

  /// Trang sau ("Xem thêm").
  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore) {
      return;
    }
    isLoadingMore = true;
    _notify();
    try {
      final page = await _dao.findAll(page: _page + 1);
      final known = {for (final n in items) n.id};
      items = [...items, ...page.items.where((n) => !known.contains(n.id))];
      hasMore = page.hasMore;
      unreadCount = page.unread;
      _page++;
    } on ApiException catch (e) {
      message = e.message;
    } finally {
      isLoadingMore = false;
      _notify();
    }
  }

  /// Hỏi số chưa đọc và các thông báo mới (`summary?after=`); thông báo mới được hiện trên máy và thêm vào đầu danh
  /// sách. Lần đầu sau khi đăng nhập chỉ lấy mốc, không hiện thông báo cũ. Mỗi lúc chỉ một lần hỏi; có sự kiện mới
  /// trong lúc hỏi thì hỏi thêm một lần nữa.
  Future<void> refreshSummary() async {
    final user = _user;
    if (user == null) {
      return;
    }
    if (_summaryBusy) {
      _summaryAgain = true;
      return;
    }
    _summaryBusy = true;
    try {
      do {
        _summaryAgain = false;
        final after = _latestSeenId;
        final summary = await _dao.findSummary(after: after);
        if (_disposed || _user?.id != user.id) {
          return;
        }
        unreadCount = summary.unread;
        if (after != null) {
          final fresh = summary.fresh.where((n) => n.id > after).toList();
          _addFresh(fresh);
          _showOnDevice(fresh);
        }
        _latestSeenId = math.max(after ?? 0, summary.latestId);
        _notify();
      } while (_summaryAgain);
    } on ApiException {
      // Giữ số cũ; lần có sự kiện sau hoặc khi mở lại app sẽ hỏi lại
    } finally {
      _summaryBusy = false;
    }
  }

  // ---------------------------------------------------------------- Update (đã đọc)

  /// Bấm một thông báo: đánh dấu đã đọc. Server đánh dấu mọi thông báo có id ≤ id này (`{upToId}`), nên các thông
  /// báo cũ hơn cũng thành đã đọc. Cập nhật ngay trên màn hình, hoàn tác khi server từ chối.
  Future<void> markRead(AppNotification notification) async {
    if (notification.read) {
      return;
    }
    await _markRead(upToId: notification.id);
  }

  /// "Đánh dấu tất cả đã đọc".
  Future<void> markAllRead() => _markRead();

  Future<void> _markRead({int? upToId}) async {
    final oldItems = items;
    final oldUnread = unreadCount;
    var changed = 0;
    items = [
      for (final n in items)
        if (!n.read && (upToId == null || n.id <= upToId)) n.copyWith(read: true) else n,
    ];
    for (var i = 0; i < items.length; i++) {
      if (items[i].read != oldItems[i].read) {
        changed++;
      }
    }
    unreadCount = upToId == null ? 0 : math.max(0, unreadCount - changed);
    _notify();
    try {
      unreadCount = await _dao.markRead(upToId: upToId);
    } on ApiException catch (e) {
      items = oldItems;
      unreadCount = oldUnread;
      message = e.message;
    } finally {
      _notify();
    }
  }

  /// Lấy câu thông báo để hiện SnackBar, rồi xóa để không hiện lại lần nữa.
  String? takeMessage() {
    final text = message;
    message = null;
    return text;
  }

  // ---------------------------------------------------------------- Bấm thông báo trên máy

  /// Đường dẫn của thông báo trên máy người dùng vừa bấm; NotificationHost lấy một lần rồi mở màn hình tương ứng.
  String? takeOpenLink() {
    final link = _openLink;
    _openLink = null;
    return link;
  }

  void _openFromDevice(String link) {
    _openLink = link;
    _notify();
  }

  // ---------------------------------------------------------------- Luồng tức thì

  void _connect() {
    final live = _live;
    if (live == null || _user == null || _liveSub != null || _disposed) {
      return;
    }
    _retryTimer?.cancel();
    _retryTimer = null;
    var opened = false;
    _liveSub = live.open().listen(
      (event) {
        _watchSilence();
        if (event.isReady) {
          opened = true;
          _retry = retryFirst;
          isLiveConnected = true;
          _notify();
          // Mở lại sau khi rớt: hỏi bù những gì có thể đã lỡ
          unawaited(refreshSummary());
        } else if (event.isNotification) {
          unawaited(refreshSummary());
        }
        if (event.type != LiveEvent.ping) {
          _events.add(event);
        }
      },
      onError: (Object _) => _closed(opened),
      onDone: () => _closed(opened),
      cancelOnError: true,
    );
  }

  /// Luồng đã kết thúc (server đóng, mất mạng, phiên hết): mở lại sau một lúc khi vẫn đăng nhập.
  void _closed(bool opened) {
    _liveSub = null;
    _silenceTimer?.cancel();
    if (isLiveConnected) {
      isLiveConnected = false;
      _notify();
    }
    if (_user == null || _disposed) {
      return;
    }
    final wait = opened ? reopenDelay : _retry;
    if (!opened) {
      final doubled = _retry * 2;
      _retry = doubled > retryMax ? retryMax : doubled;
    }
    _retryTimer?.cancel();
    _retryTimer = Timer(wait, _connect);
  }

  void _watchSilence() {
    _silenceTimer?.cancel();
    _silenceTimer = Timer(silenceLimit, () {
      final sub = _liveSub;
      if (sub == null) {
        return;
      }
      unawaited(sub.cancel());
      _closed(true);
    });
  }

  void _stopLive() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    final sub = _liveSub;
    _liveSub = null;
    if (sub != null) {
      unawaited(sub.cancel());
    }
    isLiveConnected = false;
    _retry = retryFirst;
  }

  /// Thông báo mới (mới nhất trước) lên đầu danh sách đang hiện.
  void _addFresh(List<AppNotification> fresh) {
    if (!_loaded || fresh.isEmpty) {
      return;
    }
    final known = {for (final n in items) n.id};
    items = [...fresh.where((n) => !known.contains(n.id)), ...items];
  }

  void _showOnDevice(List<AppNotification> fresh) {
    final device = _device;
    if (device == null) {
      return;
    }
    // Cũ trước, để thông báo mới nhất nằm trên cùng khay
    for (final n in fresh.reversed) {
      unawaited(device.show(id: n.id, title: n.title, body: n.content, link: n.target ?? '/notifications'));
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _stopLive();
    final taps = _tapSub;
    if (taps != null) {
      unawaited(taps.cancel());
    }
    unawaited(_events.close());
    super.dispose();
  }
}
