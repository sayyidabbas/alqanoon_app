import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
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
  final User? currentUser = FirebaseAuth.instance.currentUser;

  String userName = "جاري التحميل...";
  String usernameTag = ""; // اليوزر نيم الحالي
  String pendingUsername = ""; // اليوزر نيم قيد الانتظار
  DateTime? usernameRequestedAt; // تاريخ طلب التغيير

  String userEmail = "";
  String bio = "طالب في كلية القانون | مهتم بالتشريعات والدراسات القانونية";
  String? photoUrl;

  bool _isLoadingData = true;
  bool _isUploadingProfileImg = false;

  File? _selectedPostImage;
  final _postController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 📥 1. جلب البيانات وإنشاء اليوزر التلقائي والتحقق من شرط الـ 24 ساعة
  Future<void> _loadUserData() async {
    if (currentUser == null) return;

    try {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
      final doc = await userDocRef.get();

      String email = currentUser?.email ?? "";
      String defaultUsername = email.contains('@') 
          ? email.split('@')[0].replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '') 
          : "user_${currentUser!.uid.substring(0, 5)}";

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        
        String fetchedUsername = data['username'] ?? defaultUsername;
        String fetchedPending = data['pendingUsername'] ?? "";
        Timestamp? timestamp = data['usernameChangeRequestedAt'] as Timestamp?;
        DateTime? requestedAt = timestamp?.toDate();

        // 🟢 إنشاء يوزر نيم تلقائي لأول مرة عند تسجيل الدخول وإضافته للـ Firestore
        if (data['username'] == null) {
          await userDocRef.set({'username': defaultUsername}, SetOptions(merge: true));
          fetchedUsername = defaultUsername;
        }

        // ⏱️ فحص الـ 24 ساعة للتغير المعلق
        if (fetchedPending.isNotEmpty && requestedAt != null) {
          final hoursPassed = DateTime.now().difference(requestedAt).inHours;
          if (hoursPassed >= 24) {
            fetchedUsername = fetchedPending;
            fetchedPending = "";
            requestedAt = null;

            await userDocRef.set({
              'username': fetchedUsername,
              'pendingUsername': FieldValue.delete(),
              'usernameChangeRequestedAt': FieldValue.delete(),
            }, SetOptions(merge: true));
          }
        }

        setState(() {
          userName = data['fullName'] ?? currentUser?.displayName ?? "طالب قانون";
          userEmail = data['email'] ?? email;
          usernameTag = fetchedUsername;
          pendingUsername = fetchedPending;
          usernameRequestedAt = requestedAt;
          bio = data['bio'] ?? bio;
          photoUrl = data['photoUrl'];
          _isLoadingData = false;
        });
      } else {
        // إنشاء ملف أولي إذا كان حسابه جديداً تماماً
        await userDocRef.set({
          'fullName': currentUser?.displayName ?? "طالب قانون",
          'email': email,
          'username': defaultUsername,
          'bio': bio,
        }, SetOptions(merge: true));

        setState(() {
          userName = currentUser?.displayName ?? "طالب قانون";
          userEmail = email;
          usernameTag = defaultUsername;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      debugPrint("خطأ في جلب البيانات: $e");
      if (mounted) setState(() => _isLoadingData = false);
    }
  }

  // 🌐 2. دالة الرفع إلى FreeImage.host
  Future<String?> _uploadImageToFreeImageHost(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://freeimage.host/api/1/upload'),
      );

      request.fields['key'] = '6d207e02198a847aa98d0a2a901485a5';
      request.fields['action'] = 'upload';
      request.files.add(await http.MultipartFile.fromPath('source', imageFile.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final json = jsonDecode(responseData);

      if (json['status_code'] == 200) {
        return json['image']['url'];
      }
    } catch (e) {
      debugPrint("خطأ أثناء الرفع: $e");
    }
    return null;
  }

  // 📸 3. اختيار صورة البروفايل وتحديثها
  Future<void> _pickAndUploadProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null || currentUser == null) return;

    setState(() => _isUploadingProfileImg = true);

    final String? uploadedUrl = await _uploadImageToFreeImageHost(File(image.path));

    if (uploadedUrl != null) {
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set({
        'photoUrl': uploadedUrl,
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          photoUrl = uploadedUrl;
          _isUploadingProfileImg = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث صورة الملف الشخصي بنجاح! ✅'), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        setState(() => _isUploadingProfileImg = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل الرفع، جرب مرة أخرى'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // 🗑️ 4. حذف صورة البروفايل
  Future<void> _removeProfileImage() async {
    if (currentUser == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'photoUrl': FieldValue.delete(),
      });

      setState(() => photoUrl = null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف صورة البروفايل'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      debugPrint("خطأ في حذف الصورة: $e");
    }
  }

  // 📝 5. تعديل البيانات واليوزر مع تطبيق شرط الـ 24 ساعة
  void _editProfile() {
    final nameController = TextEditingController(text: userName);
    final usernameController = TextEditingController(text: pendingUsername.isNotEmpty ? pendingUsername : usernameTag);
    final bioController = TextEditingController(text: bio);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: AppColors.accent, size: 28),
            SizedBox(width: 8),
            Text('تعديل البيانات الشخصية', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم (اليوزر)',
                  prefixText: '@ ',
                  prefixStyle: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ملاحظة: سيتم تغيير اسم المستخدم (اليوزر) الخاص بك تلقائياً بعد مرور 24 ساعة من طلب التغيير.',
                        style: TextStyle(color: Colors.amber, fontSize: 11, height: 1.3, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: bioController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'النبذة التعريفية', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final newName = nameController.text.trim();
              final newUsername = usernameController.text.trim().replaceAll('@', '').replaceAll(' ', '');
              final newBio = bioController.text.trim();

              if (newName.isNotEmpty && currentUser != null) {
                Map<String, dynamic> updateData = {
                  'fullName': newName,
                  'bio': newBio,
                };

                // إذا قام بطلب تغيير الـ Username
                if (newUsername.isNotEmpty && newUsername != usernameTag && newUsername != pendingUsername) {
                  final now = DateTime.now();
                  updateData['pendingUsername'] = newUsername;
                  updateData['usernameChangeRequestedAt'] = Timestamp.fromDate(now);

                  setState(() {
                    pendingUsername = newUsername;
                    usernameRequestedAt = now;
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تسجيل طلب تغيير اليوزر! سيتم اعتماده وتغييره بعد 24 ساعة. ⏳'),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }

                setState(() {
                  userName = newName;
                  bio = newBio;
                });

                await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).set(updateData, SetOptions(merge: true));
              }

              if (mounted) Navigator.pop(context);
            },
            child: const Text('حفظ التغييرات', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // اختيار صورة للمنشور
  Future<void> _pickPostImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _selectedPostImage = File(image.path));
    }
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
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                children: [
                  // 💳 هيدر الملف الشخصي الفاخر بالتصميم المحدث
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.cardBg,
                          AppColors.primary.withOpacity(0.9),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.accent.withOpacity(0.2), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.08),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // الصورة الشخصية مع الإطار المضيء
                        Stack(
                          alignment: Alignment.bottomLeft,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [AppColors.accent, Colors.orangeAccent],
                                ),
                              ),
                              child: _isUploadingProfileImg
                                  ? const CircleAvatar(
                                      radius: 48,
                                      backgroundColor: AppColors.primary,
                                      child: CircularProgressIndicator(color: AppColors.accent),
                                    )
                                  : CircleAvatar(
                                      radius: 48,
                                      backgroundColor: AppColors.primary,
                                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                                      child: photoUrl == null
                                          ? Text(
                                              userName.isNotEmpty ? userName[0] : 'ع',
                                              style: const TextStyle(fontSize: 36, color: AppColors.accent, fontWeight: FontWeight.bold),
                                            )
                                          : null,
                                    ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.accent,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
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
                                                _pickAndUploadProfileImage();
                                              },
                                            ),
                                            if (photoUrl != null)
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

                        const SizedBox(height: 14),
                        Text(
                          userName,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(userEmail, style: const TextStyle(color: Colors.white38, fontSize: 12)),

                        const SizedBox(height: 12),

                        // 🏷️ زر اليوزر نيم البديل عن الـ ID مع ميزة النسخ المباشر
                        InkWell(
                          onTap: () async {
                            await Clipboard.setData(ClipboardData(text: '@$usernameTag'));
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('تم نسخ اسم المستخدم بنجاح! 📋'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.alternate_email, size: 14, color: AppColors.accent),
                                const SizedBox(width: 4),
                                Text(
                                  usernameTag,
                                  style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.copy_rounded, size: 13, color: Colors.white54),
                              ],
                            ),
                          ),
                        ),

                        // ⏳ تنبيه الـ 24 ساعة المباشر عند وجود يوزر جاري تغييره
                        if (pendingUsername.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined, color: Colors.orangeAccent, size: 16),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'سيتم تغيير اسم المستخدم إلى (@$pendingUsername) بعد مرور 24 ساعة من تاريخ الطلب',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),
                        Text(
                          bio,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 16),

                        // زر تعديل البيانات
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

                  // صندوق النشر
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(18),
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

                  // قائمة المنشورات
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
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                child: photoUrl == null
                    ? Text(post.author.isNotEmpty ? post.author[0] : 'ع', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.author, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('@$usernameTag', style: const TextStyle(fontSize: 11, color: Colors.white38)),
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
 
