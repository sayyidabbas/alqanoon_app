import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../models/post_model.dart';
import 'chat_screen.dart';

class UserProfileViewScreen extends StatelessWidget {
  final String username;
  final String fullName;
  final String bio;
  final String? photoUrl;
  final String? peerUid; // 🟢 UID الخاص بالمستخدم الآخر لتحديد الدردشة بشكل مثالي
  final List<PostModel> userPosts;
  final VoidCallback? onStartChat;

  const UserProfileViewScreen({
    super.key,
    required this.username,
    required this.fullName,
    this.bio = 'طالب في كلية القانون | مهتم بالتشريعات والدراسات القانونية',
    this.photoUrl,
    this.peerUid,
    this.userPosts = const [],
    this.onStartChat,
  });

  void _blockUser(BuildContext context) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null || peerUid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(myUid).collection('blockedUsers').doc(peerUid).set({
      'blockedAt': FieldValue.serverTimestamp(),
      'username': username,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حظر @$username بنجاح.')),
      );
      Navigator.pop(context);
    }
  }

  void _reportUser(BuildContext context) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    await FirebaseFirestore.instance.collection('reports').add({
      'reportedBy': myUid,
      'reportedUser': peerUid ?? username,
      'timestamp': FieldValue.serverTimestamp(),
      'reason': 'محتوى غير لائق / إبلاغ من الملف الشخصي',
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال بلاغك للتقييم، شكراً لمساعدتك.')),
      );
    }
  }

  void _toggleLike(String postId, List<dynamic> likes) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);
    if (likes.contains(myUid)) {
      await postRef.update({'likes': FieldValue.arrayRemove([myUid])});
    } else {
      await postRef.update({'likes': FieldValue.arrayUnion([myUid])});
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
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
                  // 🟢 زر الـ 3 نقاط للإبلاغ والحظر
                  Align(
                    alignment: Alignment.topRight,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                      color: AppColors.cardBg,
                      onSelected: (value) {
                        if (value == 'block') _blockUser(context);
                        if (value == 'report') _reportUser(context);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.flag_outlined, color: Colors.amber, size: 20),
                              SizedBox(width: 8),
                              Text('إبلاغ عن المستخدم', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(Icons.block, color: Colors.redAccent, size: 20),
                              SizedBox(width: 8),
                              Text('حظر المستخدم', style: TextStyle(color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  CircleAvatar(
                    radius: 45,
                    backgroundColor: AppColors.accent,
                    backgroundImage: photoUrl != null && photoUrl!.isNotEmpty ? NetworkImage(photoUrl!) : null,
                    child: photoUrl == null || photoUrl!.isEmpty
                        ? Text(fullName.isNotEmpty ? fullName[0] : 'ع', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black))
                        : null,
                  ),
                  const SizedBox(height: 14),
                  Text(fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('@$username', style: const TextStyle(fontSize: 14, color: AppColors.accent, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text(bio, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                  const SizedBox(height: 18),
                  
                  // 💬 زر المراسلة التفاعلي
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
                              peerUid: peerUid,
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.chat_bubble_rounded, color: Colors.black, size: 20),
                    label: const Text('مراسلة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: Text('منشورات $fullName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accent)),
            ),
            const SizedBox(height: 12),

            // 📡 جلب المنشورات المباشرة من Firestore
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

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text('لا توجد منشورات لهذا المستخدم حتى الآن.', style: TextStyle(color: Colors.white54)),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildFirestorePostCard(context, doc.id, data);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirestorePostCard(BuildContext context, String postId, Map<String, dynamic> data) {
    final String content = data['content'] ?? '';
    final String? postImg = data['imageUrl'];
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    final likes = List<String>.from(data['likes'] ?? []);
    final isLiked = likes.contains(myUid);
    final commentsCount = data['commentsCount'] ?? 0;

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
            const SizedBox(height: 10),
            const Divider(color: Colors.white10),
            // 🟢 شريط التفاعل الفعلي
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () => _toggleLike(postId, likes),
                  child: Row(
                    children: [
                      Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, color: isLiked ? AppColors.accent : Colors.white70, size: 20),
                      const SizedBox(width: 6),
                      Text('${likes.length}', style: TextStyle(color: isLiked ? AppColors.accent : Colors.white70)),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => _showCommentsModal(context, postId),
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
  }
}
 
