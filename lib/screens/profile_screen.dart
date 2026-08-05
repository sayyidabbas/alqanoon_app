import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  String username = '';
  String phoneNumber = '';
  String profileImageUrl = '';
  String currentRole = 'user';
  bool notificationsEnabled = true;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // أنيميشن نبض ذهبي فخم حول الدائرة الشخصية
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadUserData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // جلب البيانات التفصيلية من Firestore
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
              currentRole = data['role'] ?? 'user';
              isLoading = false;
            });
          }
        }
      } catch (e) {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  // نافذة الإدارة الحصرية للماستر أدمن x9.ta9
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

  // لوحة ترقية وعزل المشرفين
  void _openAdminManagementPanel() {
    final newAdminUsernameCtrl = TextEditingController();

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
            const Text('لوحة التحكم - تعيين وعزل المشرفين', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: newAdminUsernameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'أدخل يوزر المشرف الجديد', hintStyle: TextStyle(color: Colors.white38)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_add_alt_1, color: Color(0xFFD4AF37)),
                  onPressed: () async {
                    final u = newAdminUsernameCtrl.text.trim().toLowerCase();
                    if (u.isNotEmpty) {
                      final q = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: u).get();
                      if (q.docs.isNotEmpty) {
                        await FirebaseFirestore.instance.collection('users').doc(q.docs.first.id).update({'role': 'admin'});
                        if (mounted) Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تمت ترقية @$u إلى مشرف 👑')));
                      }
                    }
                  },
                )
              ],
            ),
            const SizedBox(height: 15),
            const Text('المشرفون الحاليون:', style: TextStyle(color: Colors.white70, fontSize: 14)),
            SizedBox(
              height: 200,
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
    // تغيير رابط/صورة البروفايل
  void _changeProfileAvatar() {
    final imgController = TextEditingController(text: profileImageUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text('تغيير صورة البروفايل', style: TextStyle(color: Color(0xFFD4AF37))),
        content: TextField(
          controller: imgController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'ضع رابط الصورة (Image URL)...', hintStyle: TextStyle(color: Colors.white38)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                await FirebaseFirestore.instance.collection('users').doc(uid).update({'avatar': imgController.text.trim()});
                setState(() => profileImageUrl = imgController.text.trim());
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('حفظ الصورة', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  // نافذة تأكيد حذف الحساب
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

  // تأكيد تسجيل الخروج
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

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('الملف الشخصي الفاخر', style: TextStyle(fontWeight: FontWeight.bold)),
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
                // خلفية بإضاءة متحركة خفيفة
                Positioned(
                  top: -60,
                  left: -60,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFD4AF37).withOpacity(0.08),
                    ),
                  ),
                ),
                ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // الصورة الرمزية المتحركة بالنبض الذهبي
                    Center(
                      child: ScaleTransition(
                        scale: _pulseAnimation,
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
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 46,
                                backgroundColor: const Color(0xFF1A1A1A),
                                backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                                child: profileImageUrl.isEmpty
                                    ? Text(
                                        widget.currentUserAccountName.isNotEmpty ? widget.currentUserAccountName[0].toUpperCase() : 'س',
                                        style: const TextStyle(fontSize: 34, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                                      )
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _changeProfileAvatar,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: Color(0xFFD4AF37), shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(widget.currentUserAccountName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    if (username.isNotEmpty)
                      Text('@$username', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(displayContact, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('${widget.currentUserUniversity} - ${widget.currentUserCollege}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold)),
                    
                    const SizedBox(height: 24),
                    
                    // كارت glassmorphic للإحصائيات والخيارات
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
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
                              const Divider(color: Colors.white12),
                              ListTile(
                                leading: const Icon(Icons.support_agent, color: Color(0xFFD4AF37)),
                                title: const Text('الدعم الفني والشكاوى', style: TextStyle(color: Colors.white)),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                                onTap: () {},
                              ),
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
                    ),

                    const SizedBox(height: 20),

                    // زر الخروج وزر الحذف
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
