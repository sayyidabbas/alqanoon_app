import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/post_model.dart';
import 'chat_screen.dart';

class UserProfileViewScreen extends StatelessWidget {
  final String username;
  final String fullName;
  final String bio;
  final List<PostModel> userPosts;

  const UserProfileViewScreen({
    super.key,
    required this.username,
    required this.fullName,
    this.bio = 'طالب في كلية القانون | مهتم بالتشريعات والدراسات القانونية',
    required this.userPosts,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('@$username'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // بطاقة بيانات المستخدم
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      fullName.isNotEmpty ? fullName[0] : 'ع',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    fullName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
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
                  const SizedBox(height: 16),
                  
                  // زر المراسلة
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            userName: fullName,
                            userHandle: username,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat, color: Colors.black),
                    label: const Text(
                      'مراسلة',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // منشورات المستخدم
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'منشورات $fullName',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accent),
              ),
            ),
            const SizedBox(height: 12),

            userPosts.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text('لا توجد منشورات لهذا المستخدم حتى الآن.', style: TextStyle(color: Colors.white54)),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: userPosts.length,
                    itemBuilder: (context, index) => _buildPostCard(userPosts[index]),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    return Card(
      color: AppColors.cardBg,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.accent,
                  child: Text(post.author.isNotEmpty ? post.author[0] : 'ع', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Text(post.author, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            if (post.content.isNotEmpty) Text(post.content, style: const TextStyle(fontSize: 15)),
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
  }
}
