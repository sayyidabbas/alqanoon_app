import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/post_model.dart';

class ProfileScreen extends StatefulWidget {
  final List<PostModel> posts;
  final Function(String content, String? imageUrl) onAddUserPost;

  const ProfileScreen({
    super.key,
    required this.posts,
    required this.onAddUserPost,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "سيدعباس عقيل الحسيني";
  String userEmail = "abbas@lawplatform.com";
  String bio = "طالب في كلية القانون | مهتم بالتشريعات والدراسات القانونية";

  final _postController = TextEditingController();
  final _imageUrlController = TextEditingController();

  void _editProfile() {
    final nameController = TextEditingController(text: userName);
    final bioController = TextEditingController(text: bio);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('تعديل الملف الشخصي', style: TextStyle(color: AppColors.accent)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل')),
            const SizedBox(height: 10),
            TextField(controller: bioController, decoration: const InputDecoration(labelText: 'النبذة الشخصية')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () {
              setState(() {
                userName = nameController.text;
                bio = bioController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // تصفية المنشورات الخاصة بالمستخدم الحالي فقط
    final userPosts = widget.posts.where((p) => p.author == userName).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: AppColors.accent,
              child: Text(userName.isNotEmpty ? userName[0] : 'ع', style: const TextStyle(fontSize: 32, color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(userEmail, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 8),
            Text(bio, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.accent, fontSize: 13)),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.accent)),
              onPressed: _editProfile,
              icon: const Icon(Icons.edit, color: AppColors.accent, size: 18),
              label: const Text('تعديل البيانات', style: TextStyle(color: AppColors.accent)),
            ),
            const Divider(height: 30, color: Colors.white24),
            
            // مربع إضافة منشور من قبل الطالب
            Card(
              color: AppColors.cardBg,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _postController,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: 'بماذا تفكر اليوم؟ أنشر منشوراً للجميع...'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(hintText: 'رابط صورة (اختياري)'),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                      onPressed: () {
                        if (_postController.text.isNotEmpty) {
                          widget.onAddUserPost(_postController.text, _imageUrlController.text.isEmpty ? null : _imageUrlController.text);
                          _postController.clear();
                          _imageUrlController.clear();
                          setState(() {});
                        }
                      },
                      icon: const Icon(Icons.send, color: Colors.black, size: 18),
                      label: const Text('نشر', style: TextStyle(color: Colors.black)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('منشوراتي', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accent)),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: userPosts.length,
              itemBuilder: (context, index) {
                final post = userPosts[index];
                return Card(
                  color: AppColors.cardBg,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(post.content),
                    subtitle: Text('${post.likes} إعجاب • ${post.comments.length} تعليق'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
