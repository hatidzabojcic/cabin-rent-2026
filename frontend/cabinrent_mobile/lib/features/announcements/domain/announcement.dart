class Announcement {
  const Announcement({required this.title, required this.content, required this.publishedAtUtc, this.imageUrl});
  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
    title: json['title'] as String, content: json['content'] as String,
    imageUrl: json['imageUrl'] as String?, publishedAtUtc: DateTime.parse(json['publishedAtUtc'] as String).toLocal());
  final String title;
  final String content;
  final String? imageUrl;
  final DateTime publishedAtUtc;
}
