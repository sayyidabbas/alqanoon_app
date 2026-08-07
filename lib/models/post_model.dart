import 'dart:io';

class PostModel {
  String id;
  String content;
  String author;      // الاسم الكامل للكاتب
  String username;    // المعرف الخاص بالكاتب (مثل: abbas_law)
  File? imageFile;   // صورة المنشور من الجهاز
  DateTime timestamp;
  int likes;
  bool isLiked;
  List<String> comments;

  PostModel({
    required this.id,
    required this.content,
    required this.author,
    required this.username,
    this.imageFile,
    required this.timestamp,
    this.likes = 0,
    this.isLiked = false,
    List<String>? comments,
  }) : comments = comments ?? [];
}
