import 'dart:io';

class PostModel {
  String id;
  String userId;
  String content;
  String author;      
  String username;    
  String? imageUrl;   // 🟢 رابط الصورة من Firebase Storage
  File? imageFile;   
  DateTime timestamp;
  List<String> likes; // 🟢 قائمة معرّفات المستخدمين الذين أعجبهم المنشور
  int commentsCount;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    required this.author,
    required this.username,
    this.imageUrl,
    this.imageFile,
    required this.timestamp,
    List<String>? likes,
    this.commentsCount = 0,
  }) : likes = likes ?? [];

  factory PostModel.fromFirestore(String id, Map<String, dynamic> data) {
    return PostModel(
      id: id,
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      author: data['author'] ?? 'مستخدم',
      username: data['username'] ?? 'user',
      imageUrl: data['imageUrl'],
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as dynamic).toDate()
          : DateTime.now(),
      likes: List<String>.from(data['likes'] ?? []),
      commentsCount: data['commentsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'content': content,
      'author': author,
      'username': username,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
      'likes': likes,
      'commentsCount': commentsCount,
    };
  }
}
