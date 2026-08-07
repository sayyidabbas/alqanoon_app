import 'dart:io';
import 'package:flutter/material.dart';
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
  String userName = "سيدعباس عقيل الحسيني";
  String userEmail = "abbas@lawplatform.com";
  String bio = "طالب في كلية القانون | مهتم بالتشريعات والدراسات القانونية";
  
  File? _profileImage;
  File? _selectedPostImage;
  final _postController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // اختيار صورة البروفايل من المعرض
  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  // حذف صورة البروفايل
  void _removeProfileImage() {
    setState(() {
      _profileImage = null;
    });
  }

  // اختيار صورة للمنشور من المعرض
  Future<void> _pickPostImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedPostImage = File(image.path);
      });
    }
  }

  // تعديل بيانات الملف الشخصي
  void _editProfile() {
    final nameController = TextEditingController(text: userName);
    final bioController = TextEditingController(text: bio);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('تعديل البيانات الشخصية', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bioController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'النبذة التعريفية', border: OutlineInputBorder()),
            ),
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
            child: const Text('حفظ التغييرات', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userPosts = widget.posts.where((p) => p.author == userName).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            // هيدر البروفايل الأنيق
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.cardBg, AppColors.primary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accent, width: 3),
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.primary,
                          backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                          child: _profileImage == null
                              ? Text(
                                  userName.isNotEmpty ? userName[0] : 'ع',
                                  style: const TextStyle(fontSize: 38, color: AppColors.accent, fontWeight: FontWeight.bold),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.accent,
                          child: IconButton(
                            icon: const Icon(Icons.camera_alt, size: 18, color: Colors.black),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: AppColors.cardBg,
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                builder: (context) => Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.photo_library, color: AppColors.accent),
                                        title: const Text('اختيار صورة من المعرض'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _pickProfileImage();
                                        },
                                      ),
                                      if (_profileImage != null)
                                        ListTile(
                                          leading: const Icon(Icons.delete, color: Colors.red),
                                          title: const Text('حذف صورة البروفايل', style: TextStyle(color: Colors.red)),
                                          onTap: () {
                                            Navigator.pop(context);
                                            _removeProfileImage();
                                          },
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(userEmail, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 10),
                  Text(bio, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.accent, fontSize: 13, height: 1.4)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      side: const BorderSide(color: AppColors.accent, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    onPressed: _editProfile,
                    icon: const Icon(Icons.edit, color: AppColors.accent, size: 18),
                    label: const Text('تعديل البيانات', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // صندوق النشر الفخم
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _postController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'بماذا تفكر اليوم؟ أنشر شارك الجميع...',
                      border: InputBorder.none,
                    ),
                  ),
                  if (_selectedPostImage != null) ...[
                    const SizedBox(height: 10),
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_selectedPostImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
                        ),
                        IconButton(
                          icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white, size: 18)),
                          onPressed: () => setState(() => _selectedPostImage = null),
                        )
                      ],
                    ),
                  ],
                  const Divider(color: Colors.white10, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _pickPostImage,
                        icon: const Icon(Icons.photo_library_rounded, color: AppColors.accent),
                        label: const Text('معرض الصور', style: TextStyle(color: AppColors.accent)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                        ),
                        onPressed: () {
                          if (_postController.text.isNotEmpty || _selectedPostImage != null) {
                            widget.onAddUserPost(_postController.text, _selectedPostImage);
                            _postController.clear();
                            setState(() => _selectedPostImage = null);
                          }
                        },
                        child: const Text('نشر', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerRight,
              child: Text('منشوراتي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accent)),
            ),
            const SizedBox(height: 12),

            // قائمة المنشورات مع التفاعل كامل (إعجاب وتطبيقات التعليقات)
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: userPosts.length,
              itemBuilder: (context, index) {
                final post = userPosts[index];
                return _buildPostCard(post);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.accent,
                backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null
                    ? Text(post.author.isNotEmpty ? post.author[0] : 'ع', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Text('منصة القانون', style: TextStyle(fontSize: 11, color: Colors.white38)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (post.content.isNotEmpty) Text(post.content, style: const TextStyle(fontSize: 15, height: 1.4)),
          if (post.imageFile != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(post.imageFile!, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          const Divider(color: Colors.white10, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    post.isLiked = !post.isLiked;
                    post.likes += post.isLiked ? 1 : -1;
                  });
                },
                icon: Icon(post.isLiked ? Icons.favorite : Icons.favorite_border, color: post.isLiked ? Colors.red : Colors.white60),
                label: Text('${post.likes} إعجاب', style: const TextStyle(color: Colors.white60)),
              ),
              TextButton.icon(
                onPressed: () => _showCommentsModal(post),
                icon: const Icon(Icons.comment_outlined, color: Colors.white60),
                label: Text('${post.comments.length} تعليق', style: const TextStyle(color: Colors.white60)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCommentsModal(PostModel post) {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('التعليقات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.accent)),
              const Divider(color: Colors.white10),
              Expanded(
                child: ListView.builder(
                  itemCount: post.comments.length,
                  itemBuilder: (context, i) => ListTile(
                    leading: const CircleAvatar(backgroundColor: AppColors.accent, child: Icon(Icons.person, color: Colors.black)),
                    title: Text(post.comments[i]),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: const InputDecoration(hintText: 'اكتب تعليقاً...'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.accent),
                    onPressed: () {
                      if (commentController.text.isNotEmpty) {
                        setState(() {
                          post.comments.add(commentController.text);
                        });
                        setModalState(() {});
                        commentController.clear();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
