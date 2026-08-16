import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/notifications_repository.dart';
import '../domain/app_notification.dart';

class NotificationsController extends ChangeNotifier {
  NotificationsController(this._repository);

  final NotificationsRepository _repository;
  Timer? _timer;
  bool _refreshing = false;

  List<AppNotification> notifications = [];
  int unreadCount = 0;
  bool isLoading = false;
  bool hasLoaded = false;
  String? errorMessage;

  void start() {
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => refresh(silent: true),
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh({bool silent = false}) async {
    if (_refreshing) return;
    _refreshing = true;
    if (!silent) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }
    try {
      final results = await Future.wait<Object>([
        _repository.getNotifications(),
        _repository.getUnreadCount(),
      ]);
      notifications = results[0] as List<AppNotification>;
      unreadCount = results[1] as int;
      hasLoaded = true;
      errorMessage = null;
      notifyListeners();
    } catch (_) {
      if (!silent) {
        errorMessage = 'Obavijesti trenutno nije moguće učitati.';
        notifyListeners();
      }
    } finally {
      _refreshing = false;
      if (!silent) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> markRead(AppNotification notification) async {
    if (notification.isRead) return true;
    try {
      await _repository.markRead(notification.id);
      notifications = notifications
          .map((item) => item.id == notification.id ? item.markRead() : item)
          .toList();
      if (unreadCount > 0) unreadCount--;
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'Obavijest nije moguće označiti kao pročitanu.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAllRead() async {
    if (unreadCount == 0) return true;
    try {
      await _repository.markAllRead();
      notifications = notifications.map((item) => item.markRead()).toList();
      unreadCount = 0;
      notifyListeners();
      return true;
    } catch (_) {
      errorMessage = 'Obavijesti nije moguće označiti kao pročitane.';
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
