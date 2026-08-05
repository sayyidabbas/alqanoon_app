import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  final String currentUserAccountName;
  final String currentUserEmail;
  final String currentUserUniversity;
  final String currentUserCollege;
  final Function onLogout;

  const ProfileScreen({
    super.key,
    required this.currentUserAccountName,
    required this.currentUserEmail,
    required this.currentUserUniversity,
    required this.currentUserCollege,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimationController;

  String username = '';
  String phoneNumber = '';
  String profileImageUrl = '';
  String displayName = '';
  String university = '';
  String college = '';
  bool isVerified = false;
  bool notificationsEnabled = true;
  bool isLoading = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    displayName = widget.currentUserAccountName;
    university = widget.currentUserUniversity;
    college = widget.currentUserCollege;

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _loadUserData();
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (mounted) {
            setState(() {
              username = data['username'] ?? '';
              phoneNumber = data['phone'] ?? '';
              profileImageUrl = data['avatar'] ?? '';
              isVerified = data['isVerified'] ?? false;
              if (data['name'] != null && data['name'].toString().isNotEmpty) {
                displayName = data['name'];
              }
              if (data['university'] != null && data['university'].toString().isNotEmpty) {
                university = data['university'];
              }
              if (data['college'] != null && data['college'].toString().isNotEmpty) {
                college = data['college'];
              }
              isLoading = false;
            });
          }
        }
      } catch (_) {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  // تغيير صورة البروفايل عبر ألبوم الهاتف مباشرة
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 75,
      );

      if (pickedFile != null) {
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({'avatar': base64Image});
          setState(() => profileImageUrl = base64Image);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تحديث صورة البروفايل بنجاح!'), backgroundColor: Colors.green),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل اختيار الصورة: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // واجهة جديدة كاملة لتعديل البيانات الشخصية
  void _openEditProfileScreen() {
    final nameCtrl = TextEditingController(text: displayName);
    final uniCtrl = TextEditingController(text: university);
    final colCtrl = TextEditingController(text: college);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          appBar: AppBar(
            title: const Text('تعديل الملف الشخصي', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF141414),
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: [
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'الاسم الكامل',
                    labelStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.person, color: Color(0xFFD4AF37)),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD4AF37)), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2), borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: uniCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'الجامعة',
                    labelStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.school, color: Color(0xFFD4AF37)),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD4AF37)), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2), borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: colCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'الكلية',
                    labelStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.account_balance, color: Color(0xFFD4AF37)),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD4AF37)), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2), borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                          'name': nameCtrl.text.trim(),
                          'university': uniCtrl.text.trim(),
                          'college': colCtrl.text.trim(),
                        });
                        setState(() {
                          displayName = nameCtrl.text.trim();
                          university = uniCtrl.text.trim();
                          college = colCtrl.text.trim();
                        });
                      }
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('حفظ التغييرات', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
    // فتح واجهة معلومات الدعم الفني
  void _openSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.headset_mic, color: Color(0xFFD4AF37)),
            SizedBox(width: 8),
            Text('الدعم الفني والشكاوى', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('للتواصل المباشر مع إدارة التطبيق والماستر أدمن:', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 15),
            ListTile(
              dense: true,
              leading: const Icon(Icons.send, color: Colors.blueAccent),
              title: const Text('تيليجرام الإدارة', style: TextStyle(color: Colors.white)),
              subtitle: const Text('@x9.ta9', style: TextStyle(color: Color(0xFFD4AF37))),
              onTap: () {
                Clipboard.setData(const ClipboardData(text: '@x9.ta9'));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ يوزر الدعم بنجاح')));
              },
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.phone, color: Colors.greenAccent),
              title: const Text('واتساب الشكاوى', style: TextStyle(color: Colors.white)),
              subtitle: const Text('07777558324', style: TextStyle(color: Color(0xFFD4AF37))),
              onTap: () {
                Clipboard.setData(const ClipboardData(text: '07777558324'));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ الرقم بنجاح')));
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق', style: TextStyle(color: Color(0xFFD4AF37))),
          ),
        ],
      ),
    );
  }

  void _openMasterAdminDialog() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFFD4AF37)),
            SizedBox(width: 8),
            Text('بوابة الإدارة العليا', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'اسم مستخدم الماستر', labelStyle: TextStyle(color: Colors.white60)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'كلمة المرور', labelStyle: TextStyle(color: Colors.white60)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            onPressed: () {
              if (userCtrl.text.trim() == 'x9.ta9' && passCtrl.text.trim() == 'Abbas312004') {
                Navigator.pop(ctx);
                _openAdminManagementPanel();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('غير مصرح لك بالدخول!'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('دخول'),
          ),
        ],
      ),
    );
  }

  // لوحة تعيين المشرفين وتوثيق الحسابات
  void _openAdminManagementPanel() {
    final targetUsernameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('لوحة التحكم - المشرفين والتوثيق 👑', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white24),
            TextField(
              controller: targetUsernameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'أدخل اليوزر المستهدف...', hintStyle: TextStyle(color: Colors.white38)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                    icon: const Icon(Icons.person_add),
                    label: const Text('منح إشراف'),
                    onPressed: () async {
                      final u = targetUsernameCtrl.text.trim().toLowerCase();
                      if (u.isNotEmpty) {
                        final q = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: u).get();
                        if (q.docs.isNotEmpty) {
                          await FirebaseFirestore.instance.collection('users').doc(q.docs.first.id).update({'role': 'admin'});
                          if (mounted) Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تمت ترقية @$u إلى مشرف')));
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                    icon: const Icon(Icons.verified),
                    label: const Text('منح توثيق 💙'),
                    onPressed: () async {
                      final u = targetUsernameCtrl.text.trim().toLowerCase();
                      if (u.isNotEmpty) {
                        final q = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: u).get();
                        if (q.docs.isNotEmpty) {
                          await FirebaseFirestore.instance.collection('users').doc(q.docs.first.id).update({'isVerified': true});
                          if (mounted) Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم توثيق حساب @$u')));
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text('المشرفون الحاليون:', style: TextStyle(color: Colors.white70, fontSize: 14)),
            SizedBox(
              height: 180,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'admin').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                  final admins = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: admins.length,
                    itemBuilder: (ctx, i) {
                      final a = admins[i].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(a['name'] ?? '', style: const TextStyle(color: Colors.white)),
                        subtitle: Text('@${a['username'] ?? ''}', style: const TextStyle(color: Color(0xFFD4AF37))),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('users').doc(admins[i].id).update({'role': 'user'});
                            if (mounted) Navigator.pop(ctx);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('حذف الحساب نهائياً', style: TextStyle(color: Colors.red, fontSize: 16)),
          ],
        ),
        content: const Text('هل أنت متأكد من حذف حسابك؟ لن تتمكن من استعادة بياناتك مطلقاً!', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
                  await user.delete();
                }
                widget.onLogout();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ بالحذف: $e')));
              }
            },
            child: const Text('تأكيد الحذف النهائي'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('تسجيل الخروج', style: TextStyle(color: Color(0xFFD4AF37))),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              widget.onLogout();
            },
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }
    @override
  Widget build(BuildContext context) {
    String displayContact = widget.currentUserEmail;
    if (displayContact.endsWith('@lawapp.com')) {
      displayContact = phoneNumber.isNotEmpty ? phoneNumber : displayContact.replaceAll('@lawapp.com', '');
    }

    bool hasNetworkImage = profileImageUrl.startsWith('http://') || profileImageUrl.startsWith('https://');
    bool hasBase64Image = profileImageUrl.startsWith('data:image');

    ImageProvider? avatarImage;
    if (hasNetworkImage) {
      avatarImage = NetworkImage(profileImageUrl);
    } else if (hasBase64Image) {
      avatarImage = MemoryImage(base64Decode(profileImageUrl.split(',').last));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('الملف الشخصي', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF141414),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Color(0xFFD4AF37)),
            tooltip: 'بوابة الإدارة',
            onPressed: _openMasterAdminDialog,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : Stack(
              children: [
                // عناصر متدرجة متحركة في الخلفية
                Positioned(
                  top: -40,
                  left: -40,
                  child: AnimatedBuilder(
                    animation: _bgAnimationController,
                    builder: (context, child) {
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFD4AF37).withOpacity(0.05 + (_bgAnimationController.value * 0.05)),
                        ),
                      );
                    },
                  ),
                ),
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withOpacity(0.35),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: const Color(0xFF1A1A1A),
                              backgroundImage: avatarImage,
                              child: avatarImage == null
                                  ? Text(
                                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'س',
                                      style: const TextStyle(fontSize: 34, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickImageFromGallery,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
                                child: const Icon(Icons.photo_camera, size: 18, color: Colors.black),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: Colors.blueAccent, size: 22),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (username.isNotEmpty)
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: '@$username'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم نسخ اسم المستخدم بنجاح! 📋'), backgroundColor: Colors.green),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('@$username', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w600, fontSize: 15)),
                            const SizedBox(width: 4),
                            const Icon(Icons.copy, size: 14, color: Color(0xFFD4AF37)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(displayContact, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('$university - $college', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold)),
                    
                    const SizedBox(height: 24),
                    
                    // خانات بألوان مميزة ومتدرجة
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E1E24), Color(0xFF141418)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.25)),
                        ),
                        child: Column(
                          children: [
                            SwitchListTile(
                              activeColor: const Color(0xFFD4AF37),
                              title: const Text('الإشعارات والتنبيهات', style: TextStyle(color: Colors.white)),
                              secondary: const Icon(Icons.notifications_active, color: Color(0xFFD4AF37)),
                              value: notificationsEnabled,
                              onChanged: (val) => setState(() => notificationsEnabled = val),
                            ),
                            const Divider(color: Colors.white12, height: 1),
                            ListTile(
                              leading: const Icon(Icons.edit, color: Color(0xFFD4AF37)),
                              title: const Text('تعديل البيانات الشخصية', style: TextStyle(color: Colors.white)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                              onTap: _openEditProfileScreen,
                            ),
                            const Divider(color: Colors.white12, height: 1),
                            ListTile(
                              leading: const Icon(Icons.support_agent, color: Color(0xFFD4AF37)),
                              title: const Text('الدعم الفني والشكاوى', style: TextStyle(color: Colors.white)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                              onTap: _openSupportDialog,
                            ),
                            const Divider(color: Colors.white12, height: 1),
                            ListTile(
                              leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFFD4AF37)),
                              title: const Text('الشروط وسياسة الخصوصية', style: TextStyle(color: Colors.white)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.15),
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.logout),
                            label: const Text('خروج'),
                            onPressed: _confirmLogout,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade900,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.delete_forever),
                            label: const Text('حذف الحساب'),
                            onPressed: _confirmDeleteAccount,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
