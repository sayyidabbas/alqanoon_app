class PostModel {
  String id;
  String content;
  String author;
  String? imageUrl; // رابط أو مسار الصورة
  DateTime timestamp;
  int likes;
  bool isLiked;
  List<String> comments;

  PostModel({
    required this.id,
    required this.content,
    required this.author,
    this.imageUrl,
    required this.timestamp,
    this.likes = 0,
    this.isLiked = false,
    List<String>? comments,
  }) : comments = comments ?? [];
}
