import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/app_notification.dart';
import 'notifications_controller.dart';

enum _NotificationFilter { all, unread }

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({this.onOpenReservations, super.key});

  final VoidCallback? onOpenReservations;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _NotificationFilter _filter = _NotificationFilter.all;

  Future<void> _open(AppNotification notification) async {
    final controller = context.read<NotificationsController>();
    final marked = await controller.markRead(notification);
    if (!mounted || !marked) return;
    if (notification.relatedEntityType?.toLowerCase() == 'reservation') {
      widget.onOpenReservations?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationsController>();
    final items = _filter == _NotificationFilter.unread
        ? controller.notifications.where((item) => !item.isRead).toList()
        : controller.notifications;

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Obavijesti',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (controller.unreadCount > 0)
                      TextButton(
                        onPressed: controller.markAllRead,
                        child: const Text('Označi sve'),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  controller.unreadCount == 0
                      ? 'Nemate nepročitanih obavijesti.'
                      : '${controller.unreadCount} nepročitanih obavijesti',
                ),
                const SizedBox(height: 16),
                SegmentedButton<_NotificationFilter>(
                  segments: const [
                    ButtonSegment(
                      value: _NotificationFilter.all,
                      label: Text('Sve'),
                      icon: Icon(Icons.notifications_outlined),
                    ),
                    ButtonSegment(
                      value: _NotificationFilter.unread,
                      label: Text('Nepročitane'),
                      icon: Icon(Icons.mark_email_unread_outlined),
                    ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (value) =>
                      setState(() => _filter = value.first),
                ),
                if (controller.errorMessage != null &&
                    controller.notifications.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    controller.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ]),
            ),
          ),
          if (controller.isLoading && controller.notifications.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.errorMessage != null &&
              controller.notifications.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                icon: Icons.cloud_off_outlined,
                message: controller.errorMessage!,
                action: TextButton.icon(
                  onPressed: controller.refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Pokušaj ponovo'),
                ),
              ),
            )
          else if (items.isEmpty)
            SliverFillRemaining(
              child: _EmptyState(
                icon: _filter == _NotificationFilter.unread
                    ? Icons.mark_email_read_outlined
                    : Icons.notifications_none,
                message: _filter == _NotificationFilter.unread
                    ? 'Sve obavijesti su pročitane.'
                    : 'Još nemate obavijesti.',
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
              sliver: SliverList.separated(
                itemCount: items.length,
                itemBuilder: (_, index) => _NotificationCard(
                  notification: items[index],
                  onTap: () => _open(items[index]),
                ),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: notification.isRead
        ? Colors.white
        : Theme.of(
            context,
          ).colorScheme.primaryContainer.withValues(alpha: 0.42),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(child: Icon(_notificationIcon(notification.type))),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w900,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.only(top: 5, left: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(notification.message),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Text(
                        formatNotificationDate(notification.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Spacer(),
                      if (notification.relatedEntityType?.toLowerCase() ==
                          'reservation')
                        const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const SizedBox(height: 80),
      Icon(icon, size: 58),
      const SizedBox(height: 14),
      Text(message, textAlign: TextAlign.center),
      if (action != null) Center(child: action),
    ],
  );
}

IconData _notificationIcon(String type) => switch (type) {
  'ReservationCreated' => Icons.calendar_month_outlined,
  'ReservationStatusChanged' => Icons.event_available_outlined,
  'ReservationCancelled' => Icons.event_busy_outlined,
  'ReviewCreated' => Icons.rate_review_outlined,
  _ => Icons.notifications_outlined,
};
