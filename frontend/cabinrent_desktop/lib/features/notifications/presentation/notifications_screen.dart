import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_exception.dart';
import '../data/notifications_repository.dart';
import '../domain/app_notification.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _notifications = [];
  bool _loading = true;
  bool? _isRead;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final notificationsController = context.read<NotificationsController>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final notifications = await context
          .read<NotificationsRepository>()
          .getNotifications(isRead: _isRead);
      if (mounted) setState(() => _notifications = notifications);
      await notificationsController.refresh();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(AppNotification notification) async {
    if (!notification.isRead) {
      try {
        await context.read<NotificationsRepository>().markRead(notification.id);
        await _load();
      } on ApiException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.message)));
        }
      }
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.message),
              const SizedBox(height: 18),
              Text(
                notificationDate(notification.createdAtUtc),
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zatvori'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAllRead() async {
    try {
      await context.read<NotificationsRepository>().markAllRead();
      await _load();
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Obavijesti',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text('Novosti o rezervacijama, statusima i recenzijama.'),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: _loading ? null : _markAllRead,
              icon: const Icon(Icons.done_all),
              label: const Text('Označi sve kao pročitano'),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              onPressed: _loading ? null : _load,
              tooltip: 'Osvježi',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: 210,
          child: DropdownButtonFormField<bool?>(
            initialValue: _isRead,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem<bool?>(
                value: null,
                child: Text('Sve obavijesti'),
              ),
              DropdownMenuItem(value: false, child: Text('Nepročitane')),
              DropdownMenuItem(value: true, child: Text('Pročitane')),
            ],
            onChanged: (value) {
              _isRead = value;
              _load();
            },
          ),
        ),
        const SizedBox(height: 18),
        Expanded(child: _content()),
      ],
    ),
  );

  Widget _content() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Obavijesti nije moguće učitati.\n$_error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Pokušaj ponovo'),
            ),
          ],
        ),
      );
    }
    if (_notifications.isEmpty) {
      return const Center(child: Text('Nema obavijesti za odabrani filter.'));
    }
    return ListView.separated(
      itemCount: _notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return Card(
          color: notification.isRead
              ? null
              : Theme.of(context).colorScheme.primary.withValues(alpha: .06),
          child: ListTile(
            onTap: () => _open(notification),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 9,
            ),
            leading: CircleAvatar(child: Icon(_icon(notification.type))),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead
                    ? FontWeight.w500
                    : FontWeight.w700,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                notification.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  notificationDate(notification.createdAtUtc),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                if (!notification.isRead)
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Badge(label: Text('Novo')),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _icon(String type) => switch (type) {
    'ReservationCreated' => Icons.calendar_month_outlined,
    'ReservationRescheduled' => Icons.event_repeat_outlined,
    'ReservationStatusChanged' => Icons.event_available_outlined,
    'ReviewCreated' => Icons.rate_review_outlined,
    _ => Icons.notifications_outlined,
  };
}
