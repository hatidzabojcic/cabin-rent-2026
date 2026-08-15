class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAtUtc,
    this.relatedEntityType,
    this.relatedEntityId,
    this.readAtUtc,
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
        readAtUtc: json['readAtUtc'] == null
            ? null
            : DateTime.parse(json['readAtUtc'] as String).toLocal(),
        createdAtUtc: DateTime.parse(json['createdAtUtc'] as String).toLocal(),
      );
  final int id;
  final String type;
  final String title;
  final String message;
  final String? relatedEntityType;
  final int? relatedEntityId;
  final bool isRead;
  final DateTime? readAtUtc;
  final DateTime createdAtUtc;
}

String notificationDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}. ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
