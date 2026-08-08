import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';
import '../models/post_model.dart';
import 'chat_screen.dart';

class UserProfileViewScreen extends StatelessWidget {
  final String username;
  final String fullName;
  final String bio;
  final String? photoUrl; // 🟢 تم إضافة استقبال رابط الصورة
  final List<PostModel> userPosts;
  final VoidCallback? onStartChat; // 🟢 دالة اختيارية لربطه بالدردشة الرئيسية

  const UserProfileViewScreen({
    super.key,
    required this.username,
    required this.fullName,
    this.bio = 'طالب في كلية القانون | مهتم بالتشريعات والدراسات القانونية',
    this.photoUrl,
    this.userPosts = const [],
    this.onStartChat,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('@$username'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 💳 بطاقة بيانات المستخدم
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  // 🖼️ عرض صورة بروفايل المستخدم الحقيقية
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: AppColors.accent,
                    backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                        ? NetworkImage(photoUrl!)
                        : null,
                    child: photoUrl == null || photoUrl!.isEmpty
                        ? Text(
                            fullName.isNotEmpty ? fullName[0] : 'ع',
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black),
                          )
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    fullName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@$username',
                    style: const TextStyle(fontSize: 14, color: AppColors.accent, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    bio,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  
                  // 💬 زر المراسلة
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (onStartChat != null) {
                        Navigator.pop(context);
                        onStartChat!();
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              userName: fullName,
                              userHandle: username,
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.chat_bubble_rounded, color: Colors.black, size: 20),
                    label: const Text(
                      'مراسلة',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 📝 عنوان منشورات المستخدم
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'منشورات $fullName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 12),

            // 📡 جلب المنشورات المباشرة من Firestore بدلاً من القائمة المحلية
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('username', isEqualTo: username)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(30.0),
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }

                // في حال عدم وجود منشورات في Firestore نستخدم القائمة الممررة احتياطاً
                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty && userPosts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text('لا توجد منشورات لهذا المستخدم حتى الآن.', style: TextStyle(color: Colors.white54)),
                  );
                }

                if (docs.isNotEmpty) {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return _buildFirestorePostCard(data);
                    },
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: userPosts.length,
                  itemBuilder: (context, index) => _buildPostCard(userPosts[index]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // كارت عرض المنشورات القادمة من Firestore
  Widget _buildFirestorePostCard(Map<String, dynamic> data) {
    final String content = data['content'] ?? '';
    final String? postImg = data['imageUrl'];

    return Card(
      color: AppColors.cardBg,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.accent,
                  backgroundImage: photoUrl != null && photoUrl!.isNotEmpty ? NetworkImage(photoUrl!) : null,
                  child: photoUrl == null || photoUrl!.isEmpty
                      ? Text(fullName.isNotEmpty ? fullName[0] : 'ع', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('@$username', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ],
            ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(content, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.3)),
            ],
            if (postImg != null && postImg.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(postImg, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // كارت عرض المنشورات المحلية (في حال استخدام PostModel)
  Widget _buildPostCard(PostModel post) {
    return Card(
      color: AppColors.cardBg,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.accent,
                  backgroundImage: photoUrl != null && photoUrl!.isNotEmpty ? NetworkImage(photoUrl!) : null,
                  child: photoUrl == null || photoUrl!.isEmpty
                      ? Text(post.author.isNotEmpty ? post.author[0] : 'ع', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
                      : null,
                ),
                const SizedBox(width: 10),
                Text(post.author, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 10),
            if (post.content.isNotEmpty) Text(post.content, style: const TextStyle(fontSize: 15, color: Colors.white)),
            if (post.imageFile != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(post.imageFile!, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
