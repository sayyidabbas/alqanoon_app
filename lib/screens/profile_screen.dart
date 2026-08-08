import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _postController = TextEditingController();
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _submitPost() {
    if (_postController.text.trim().isEmpty && _selectedImage == null) return;

    widget.onAddUserPost(_postController.text.trim(), _selectedImage);
    _postController.clear();
    setState(() {
      _selectedImage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نشر المنشور بنجاح!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _currentUser != null
            ? FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).snapshots()
            : null,
        builder: (context, snapshot) {
          String fullName = _currentUser?.displayName ?? 'طالب قانون';
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
                Text(
                  '@$username',
                  style: const TextStyle(fontSize: 14, color: AppColors.accent),
                ),
                const SizedBox(height: 8),
                Text(
                  bio,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white24),
                const SizedBox(height: 10),

                // قسم إضافة منشور جديد
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
                          ElevatedButton(
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

                // عرض منشورات المستخدم
                widget.posts.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text('لم تقم بنشر أي منشور بعد.', style: TextStyle(color: Colors.white38)),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.posts.length,
                        itemBuilder: (context, index) {
                          final post = widget.posts[index];
                          return Card(
                            color: AppColors.cardBg,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(post.content, style: const TextStyle(color: Colors.white, fontSize: 15)),
                                  if (post.imageFile != null) ...[
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(post.imageFile!, width: double.infinity, fit: BoxFit.cover),
                                    ),
                                  ],
                                ],
                              ),
                            ),
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
 
