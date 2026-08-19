class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.publishedAtUtc,
    required this.isActive,
    this.imageUrl,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
    id: json['id'] as int,
    title: json['title'] as String,
    content: json['content'] as String,
    imageUrl: json['imageUrl'] as String?,
    publishedAtUtc: DateTime.parse(json['publishedAtUtc'] as String).toUtc(),
    isActive: json['isActive'] as bool,
  );

  final int id;
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime publishedAtUtc;
  final bool isActive;
}
