import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../models/post_model.dart';

class ProfileScreen extends StatefulWidget {
  final List<PostModel> posts;
  final Function(String content, File? imageFile) onAddUserPost;

  const ProfileScreen({
    super.key,
    required this.posts,
    required this.onAddUserPost,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _postController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToStorage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child('post_images').child(fileName);
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل رفع الصورة: $e')),
        );
      }
      return null;
    }
  }

  void _submitPost() async {
    if (_postController.text.trim().isEmpty && _selectedImage == null) return;

    setState(() => _isUploading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToStorage(_selectedImage!);
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final username = userData?['username'] ?? 'user';
      final fullName = userData?['fullName'] ?? user.displayName ?? 'طالب قانون';

      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user.uid,
        'author': fullName,
        'username': username,
        'content': _postController.text.trim(),
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': <String>[],
        'commentsCount': 0,
      });

      // استدعاء الكود الخارجي إن وجد للحفاظ على النمط
      widget.onAddUserPost(_postController.text.trim(), _selectedImage);
    }

    _postController.clear();
    setState(() {
      _selectedImage = null;
      _isUploading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نشر المنشور بنجاح!')),
      );
    }
  }

  void _toggleLike(String postId, List<String> likes) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    if (likes.contains(uid)) {
      await postRef.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      await postRef.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }

  void _editPostDialog(String postId, String currentContent) {
    final editController = TextEditingController(text: currentContent);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('تعديل المنشور ✏️', style: TextStyle(color: AppColors.accent)),
        content: TextField(
          controller: editController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'أدخل النص الجديد...',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () async {
              final newContent = editController.text.trim();
              if (newContent.isNotEmpty) {
                await FirebaseFirestore.instance.collection('posts').doc(postId).update({
                  'content': newContent,
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تعديل المنشور بنجاح!')),
                  );
                }
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _deletePostConfirm(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('حذف المنشور 🗑️', style: TextStyle(color: Colors.redAccent)),
        content: const Text('هل أنت تأكد من رغبتك في حذف هذا المنشور؟', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حذف المنشور')),
                );
              }
            },
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCommentsModal(BuildContext context, String postId) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16, left: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('التعليقات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              SizedBox(
                height: 250,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .collection('comments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                    final comments = snapshot.data!.docs;
                    if (comments.isEmpty) return const Center(child: Text('لا توجد تعليقات بعد', style: TextStyle(color: Colors.white54)));

                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, i) {
                        final data = comments[i].data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(data['author'] ?? 'مستخدم', style: const TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text(data['text'] ?? '', style: const TextStyle(color: Colors.white)),
                        );
                      },
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'اكتب تعليقاً...', hintStyle: TextStyle(color: Colors.white38)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.accent),
                    onPressed: () async {
                      final text = commentController.text.trim();
                      if (text.isEmpty) return;
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await FirebaseFirestore.instance.collection('posts').doc(postId).collection('comments').add({
                          'text': text,
                          'author': user.displayName ?? 'مستخدم',
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        await FirebaseFirestore.instance.collection('posts').doc(postId).update({
                          'commentsCount': FieldValue.increment(1),
                        });
                        commentController.clear();
                      }
                    },
                  )
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileDialog(String currentName, String currentUsername, String currentBio) {
    final nameController = TextEditingController(text: currentName);
    final usernameController = TextEditingController(text: currentUsername);
    final bioController = TextEditingController(text: currentBio);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('تعديل الملف الشخصي ✏️', style: TextStyle(color: AppColors.accent)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'الاسم الكامل', labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'اسم المستخدم (User)', labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bioController,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'السيرة الذاتية (Bio)', labelStyle: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                  'fullName': nameController.text.trim(),
                  'username': usernameController.text.trim(),
                  'bio': bioController.text.trim(),
                }, SetOptions(merge: true));

                await user.updateDisplayName(nameController.text.trim());
              }
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تحديث البيانات بنجاح!')),
                );
              }
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: currentUser != null
            ? FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots()
            : null,
        builder: (context, snapshot) {
          String fullName = currentUser?.displayName ?? 'طالب قانون';
          String username = 'my_user';
          String bio = 'طالب قانون بجامعة بغداد';
          String? photoUrl;

          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            fullName = data['fullName'] ?? fullName;
            username = data['username'] ?? username;
            bio = data['bio'] ?? bio;
            photoUrl = data['photoUrl'];
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.accent,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          fullName.isNotEmpty ? fullName[0] : 'ع',
                          style: const TextStyle(fontSize: 36, color: Colors.black, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  fullName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: username));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم نسخ اسم المستخدم: @$username')),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('@$username', style: const TextStyle(fontSize: 14, color: AppColors.accent)),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy, size: 14, color: AppColors.accent),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(bio, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                  ),
                  onPressed: () => _showEditProfileDialog(fullName, username, bio),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('تعديل الملف الشخصي'),
                ),

                const SizedBox(height: 20),
                const Divider(color: Colors.white24),
                const SizedBox(height: 10),

                // قسم كتابة المنشور
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _postController,
                        maxLines: 3,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'بماذا تفكر اليوم؟ شارك مع زملائك...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                        ),
                      ),
                      if (_selectedImage != null)
                        Stack(
                          alignment: Alignment.topRight,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_selectedImage!, height: 150, width: double.infinity, fit: BoxFit.cover),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => setState(() => _selectedImage = null),
                            )
                          ],
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image, color: AppColors.accent),
                            onPressed: _pickImage,
                          ),
                          _isUploading
                              ? const CircularProgressIndicator(color: AppColors.accent)
                              : ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                                  onPressed: _submitPost,
                                  child: const Text('نشر', style: TextStyle(color: Colors.black)),
                                ),
                        ],
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('منشوراتي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accent)),
                ),
                const SizedBox(height: 10),

                // 📡 منشورات المستخدم الحقيقية المباشرة من Firestore
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .where('userId', isEqualTo: currentUser?.uid)
                      .snapshots(),
                  builder: (context, postSnapshot) {
                    if (postSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                    }

                    if (postSnapshot.hasError) {
                      return const Center(
                        child: Text('حدث خطأ أثناء جلب المنشورات.', style: TextStyle(color: Colors.white54)),
                      );
                    }

                    final docs = postSnapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('لم تقم بنشر أي منشور بعد.', style: TextStyle(color: Colors.white38)),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        // 🛡️ معالجة حقل الإعجابات بأمان
                        List<String> likes = [];
                        if (data['likes'] is List) {
                          likes = List<String>.from((data['likes'] as List).map((e) => e.toString()));
                        }

                        final isLiked = likes.contains(currentUser?.uid);
                        final commentsCount = data['commentsCount'] ?? 0;
                        final String postContent = data['content'] ?? '';
                        final String? imageUrl = data['imageUrl'] ?? data['imagePath'];

                        return Card(
                          color: AppColors.cardBg,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // زر الـ 3 نقاط (خيارات المنشور)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: AppColors.accent,
                                          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                          child: photoUrl == null
                                              ? Text(
                                                  fullName.isNotEmpty ? fullName[0] : 'ع',
                                                  style: const TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold),
                                                )
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                                      color: AppColors.cardBg,
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _editPostDialog(doc.id, postContent);
                                        } else if (value == 'delete') {
                                          _deletePostConfirm(doc.id);
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit, color: AppColors.accent, size: 18),
                                              SizedBox(width: 8),
                                              Text('تعديل المنشور', style: TextStyle(color: Colors.white)),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                              SizedBox(width: 8),
                                              Text('حذف المنشور', style: TextStyle(color: Colors.redAccent)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),

                                if (postContent.isNotEmpty)
                                  Text(postContent, style: const TextStyle(color: Colors.white, fontSize: 15)),

                                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      imageUrl,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          height: 180,
                                          color: Colors.white10,
                                          child: const Center(
                                            child: CircularProgressIndicator(color: AppColors.accent),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return const SizedBox();
                                      },
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 10),
                                const Divider(color: Colors.white10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    InkWell(
                                      onTap: () => _toggleLike(doc.id, likes),
                                      child: Row(
                                        children: [
                                          Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, color: isLiked ? AppColors.accent : Colors.white70, size: 20),
                                          const SizedBox(width: 6),
                                          Text('${likes.length}', style: TextStyle(color: isLiked ? AppColors.accent : Colors.white70)),
                                        ],
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => _showCommentsModal(context, doc.id),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.comment_outlined, color: Colors.white70, size: 20),
                                          const SizedBox(width: 6),
                                          Text('$commentsCount', style: const TextStyle(color: Colors.white70)),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
 
