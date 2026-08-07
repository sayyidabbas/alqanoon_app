import 'dart:io';

class PostModel {
  String id;
  String content;
  String author;
  File? imageFile; // استخدام ملف الصورة المحلي من معرض الجهاز
  DateTime timestamp;
  int likes;
  bool isLiked;
  List<String> comments;

  PostModel({
    required this.id,
    required this.content,
    required this.author,
    this.imageFile,
    required this.timestamp,
    this.likes = 0,
    this.isLiked = false,
    List<String>? comments,
  }) : comments = comments ?? [];
}
