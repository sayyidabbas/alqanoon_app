import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _collegeController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: currentUserAccountName);
    _collegeController = TextEditingController(text: currentUserCollege);
    _emailController = TextEditingController(text: currentUserEmail);
  }

  // اختيار صورة من المعرض حصراً ورفعها لـ Firebase Storage
  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null) {
      setState(() => _isLoading = true);
      try {
        File file = File(image.path);
        String filePath = 'profile_photos/${currentUserId.isNotEmpty ? currentUserId : DateTime.now().millisecondsSinceEpoch}.jpg';
        
        UploadTask uploadTask = FirebaseStorage.instance.ref().child(filePath).putFile(file);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();

        // تحديث الرابط في Firestore
        if (currentUserId.isNotEmpty) {
          await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
            'photoUrl': downloadUrl,
          });
        }

        setState(() {
          currentUserPhotoUrl = downloadUrl;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الصورة الشخصية بنجاح ✅')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء رفع الصورة: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // حفظ التعديلات العامة
  Future<void> _updateProfileData() async {
    setState(() => _isLoading = true);
    try {
      if (currentUserId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
          'name': _nameController.text.trim(),
          'college': _collegeController.text.trim(),
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ البيانات بنجاح ✅')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // طلب تغيير البريد الإلكتروني عبر رابط التحقق
  void _showChangeEmailDialog() {
    final newEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161C),
        title: const Text('تغيير البريد الإلكتروني 📧', style: TextStyle(color: Color(0xFFD4AF37))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('سيتم إرسال رابط تأكيد إلى بريدك الجديد لتفعيل التغيير.', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 10),
            TextField(
              controller: newEmailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'البريد الإلكتروني الجديد', labelStyle: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () async {
              String newEmail = newEmailController.text.trim();
              if (newEmail.isNotEmpty) {
                try {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await user.verifyBeforeUpdateEmail(newEmail);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إرسال رابط التأكيد إلى البريد الجديد. يرجى تفقد الوارد وتأكيد الرابط 📩')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
                  }
                }
              }
            },
            child: const Text('إرسال الرابط', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // طلب تغيير اليوزر المقفول
  void _requestUsernameChange() {
    final newUsernameController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161C),
        title: const Text('طلب تغيير اسم المستخدم 🔒', style: TextStyle(color: Color(0xFFD4AF37))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newUsernameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'اليوزر الجديد المطلوب', labelStyle: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'سبب التغيير', labelStyle: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () async {
              if (newUsernameController.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance.collection('username_requests').add({
                  'userId': currentUserId,
                  'currentName': currentUserAccountName,
                  'oldUsername': currentUsername,
                  'requestedUsername': newUsernameController.text.trim(),
                  'reason': reasonController.text.trim(),
                  'status': 'pending',
                  'timestamp': FieldValue.serverTimestamp(),
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إرسال طلبك لرئاسة المنصة بنجاح ✅')),
                  );
                }
              }
            },
            child: const Text('إرسال الطلب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF121216),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // صورة البروفايل المعرض مع أيقونة التعديل
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: const Color(0xFF1E1E24),
                        backgroundImage: currentUserPhotoUrl.isNotEmpty ? NetworkImage(currentUserPhotoUrl) : null,
                        child: currentUserPhotoUrl.isEmpty ? const Icon(Icons.person, size: 60, color: Color(0xFFD4AF37)) : null,
                      ),
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.black, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'الاسم الكامل', labelStyle: TextStyle(color: Colors.grey), prefixIcon: Icon(Icons.person, color: Color(0xFFD4AF37))),
                  ),
                  const SizedBox(height: 12),
                  // عرض اليوزر المقفول
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF1E1E24), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.alternate_email, color: Color(0xFFD4AF37)),
                        const SizedBox(width: 10),
                        Expanded(child: Text('@$currentUsername (اليوزر محمي)', style: const TextStyle(color: Colors.white70))),
                        TextButton(onPressed: _requestUsernameChange, child: const Text('طلب تغيير', style: TextStyle(color: Color(0xFFD4AF37)))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // عرض وتعديل الإيميل
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: const Color(0xFF1E1E24), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.email, color: Color(0xFFD4AF37)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(currentUserEmail.isNotEmpty ? currentUserEmail : 'لم يحدد بريد', style: const TextStyle(color: Colors.white70))),
                        TextButton(onPressed: _showChangeEmailDialog, child: const Text('تغيير البريد', style: TextStyle(color: Color(0xFFD4AF37)))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _collegeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'الكلية / الجامعة', labelStyle: TextStyle(color: Colors.grey), prefixIcon: Icon(Icons.school, color: Color(0xFFD4AF37))),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                      onPressed: _updateProfileData,
                      child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.shade700),
                      onPressed: widget.onLogout,
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
