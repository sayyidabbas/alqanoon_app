import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onLogout;

  const ProfileScreen({super.key, required this.onLogout});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController(text: currentUserAccountName);
  final _collegeController = TextEditingController(text: currentUserCollege);
  final _photoUrlController = TextEditingController(text: currentUserPhotoUrl);

  Future<void> _updateProfile() async {
    await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({
      'name': _nameController.text.trim(),
      'college': _collegeController.text.trim(),
      'photoUrl': _photoUrlController.text.trim(),
    });

    setState(() {
      currentUserAccountName = _nameController.text.trim();
      currentUserCollege = _collegeController.text.trim();
      currentUserPhotoUrl = _photoUrlController.text.trim();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث البيانات بنجاح ✅')),
      );
    }
  }

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
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إرسال طلبك للرئاسة بنجاح ✅')),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF1E1E24),
              backgroundImage: currentUserPhotoUrl.isNotEmpty ? NetworkImage(currentUserPhotoUrl) : null,
              child: currentUserPhotoUrl.isEmpty ? const Icon(Icons.person, size: 50, color: Color(0xFFD4AF37)) : null,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'الاسم الكامل', labelStyle: TextStyle(color: Colors.grey), prefixIcon: Icon(Icons.person, color: Color(0xFFD4AF37))),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.alternate_email, color: Color(0xFFD4AF37)),
              title: Text('@$currentUsername (اليوزر محمي)', style: const TextStyle(color: Colors.white70)),
              trailing: TextButton(
                onPressed: _requestUsernameChange,
                child: const Text('طلب تغيير', style: TextStyle(color: Color(0xFFD4AF37))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _collegeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'الكلية', labelStyle: TextStyle(color: Colors.grey), prefixIcon: Icon(Icons.school, color: Color(0xFFD4AF37))),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _photoUrlController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'رابط الصورة الشخصية (Image URL)', labelStyle: TextStyle(color: Colors.grey), prefixIcon: Icon(Icons.image, color: Color(0xFFD4AF37))),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                onPressed: _updateProfile,
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
