import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/notifications_repository.dart';

class NotificationsController extends ChangeNotifier {
  NotificationsController(this._repository);
  final NotificationsRepository _repository;
  Timer? _timer;
  int unreadCount = 0;

  void start() {
    _timer?.cancel();
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => refresh());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    unreadCount = 0;
  }

  Future<void> refresh() async {
    try {
      final count = await _repository.getUnreadCount();
      if (count != unreadCount) {
        unreadCount = count;
        notifyListeners();
      }
    } catch (_) {
      // Periodično osvježavanje ne prekida rad aplikacije kada API nije dostupan.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
