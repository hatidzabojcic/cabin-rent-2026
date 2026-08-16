class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.relatedEntityType,
    this.relatedEntityId,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as int,
        type: json['type'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        relatedEntityType: json['relatedEntityType'] as String?,
        relatedEntityId: json['relatedEntityId'] as int?,
        isRead: json['isRead'] as bool,
        readAt: json['readAtUtc'] == null
            ? null
            : DateTime.parse(json['readAtUtc'] as String).toLocal(),
        createdAt: DateTime.parse(json['createdAtUtc'] as String).toLocal(),
      );

  final int id;
  final String type;
  final String title;
  final String message;
  final String? relatedEntityType;
  final int? relatedEntityId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotification markRead() => AppNotification(
    id: id,
    type: type,
    title: title,
    message: message,
    relatedEntityType: relatedEntityType,
    relatedEntityId: relatedEntityId,
    isRead: true,
    readAt: DateTime.now(),
    createdAt: createdAt,
  );
}

String formatNotificationDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.'
    '${value.month.toString().padLeft(2, '0')}.${value.year}. '
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';
