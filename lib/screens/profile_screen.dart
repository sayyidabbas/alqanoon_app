import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late AnimationController _bgAnimationController;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  String username = '';
  String phoneNumber = '';
  String profileImageUrl = '';
  String displayName = '';
  String university = '';
  String college = '';
  String academicYear = 'المرحلة الأولى';
  bool isVerified = false;
  bool notificationsEnabled = true;
  bool isLoading = true;

  File? _selectedLocalImage;
  final ImagePicker _picker = ImagePicker();

  // بيانات الدعم الفني المسترجعة ديناميكياً
  String supportWhatsApp = '07777558324';
  String supportTelegram = 'x9.ta9';

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

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.25, end: 0.6).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _loadUserData();
    _loadSupportContactInfo();
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // تحميل بيانات المستخدم من السحابة
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
              academicYear = data['academicYear'] ?? 'المرحلة الأولى';
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
        } else {
          if (mounted) setState(() => isLoading = false);
        }
      } catch (_) {
        if (mounted) setState(() => isLoading = false);
      }
    }
  }

  // تحميل بيانات الدعم والشكاوى ديناميكياً
  Future<void> _loadSupportContactInfo() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('support_info').get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            supportWhatsApp = data['whatsapp'] ?? '07777558324';
            supportTelegram = data['telegram'] ?? 'x9.ta9';
          });
        }
      }
    } catch (_) {}
  }

  // اختيار صورة البروفايل من المعرض حصراً
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedLocalImage = File(pickedFile.path);
        });

        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'avatar_local_path': pickedFile.path,
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تحديث صورة البروفايل من المعرض بنجاح! 📸'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر اختيار الصورة: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // دالة تحويل الرابط وفتحه بواتساب وتليجرام
  Future<void> _launchURL(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'لا يمكن فتح الرابط';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ بالفتح: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ميزة تغيير كلمة المرور عبر إرسال البريد
  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إرسال رابط إعادة تعيين كلمة المرور إلى: ${user.email}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر الإرسال: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
    // واجهة تعديل البيانات الشخصية
  void _openEditProfileScreen() {
    final nameCtrl = TextEditingController(text: displayName);
    final uniCtrl = TextEditingController(text: university);
    final colCtrl = TextEditingController(text: college);
    final phoneCtrl = TextEditingController(text: phoneNumber);
    String selectedStage = academicYear;

    final stages = ['المرحلة الأولى', 'المرحلة الثانية', 'المرحلة الثالثة', 'المرحلة الرابعة', 'خريج حقوق'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          appBar: AppBar(
            title: const Text('تعديل البيانات الشخصية', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
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
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'رقم الهاتف',
                    labelStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.phone, color: Color(0xFFD4AF37)),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD4AF37)), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2), borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: stages.contains(selectedStage) ? selectedStage : stages.first,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'المرحلة الدراسية',
                    labelStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.school, color: Color(0xFFD4AF37)),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD4AF37)), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2), borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                  ),
                  items: stages.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (val) {
                    if (val != null) selectedStage = val;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: uniCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'الجامعة',
                    labelStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.account_balance, color: Color(0xFFD4AF37)),
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
                    prefixIcon: const Icon(Icons.gavel, color: Color(0xFFD4AF37)),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                          'name': nameCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'academicYear': selectedStage,
                          'university': uniCtrl.text.trim(),
                          'college': colCtrl.text.trim(),
                        });
                        setState(() {
                          displayName = nameCtrl.text.trim();
                          phoneNumber = phoneCtrl.text.trim();
                          academicYear = selectedStage;
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

  // نافذة الدعم الفني والشكاوى
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
            const Text('اختر وسيلة التواصل المباشرة المتاحة للرد المباشر:', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 15),
            ListTile(
              dense: true,
              leading: const Icon(Icons.chat_bubble_outline, color: Colors.greenAccent),
              title: const Text('محادثة الواتساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text(supportWhatsApp, style: const TextStyle(color: Color(0xFFD4AF37))),
              trailing: const Icon(Icons.open_in_new, color: Colors.greenAccent, size: 18),
              onTap: () {
                final cleanPhone = supportWhatsApp.replaceAll(RegExp(r'[^0-9]'), '');
                final formattedPhone = cleanPhone.startsWith('0') ? '964${cleanPhone.substring(1)}' : cleanPhone;
                _launchURL('https://wa.me/$formattedPhone');
              },
            ),
            const Divider(color: Colors.white12),
            ListTile(
              dense: true,
              leading: const Icon(Icons.send, color: Colors.blueAccent),
              title: const Text('تيليجرام الإدارة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: Text('@${supportTelegram.replaceAll('@', '')}', style: const TextStyle(color: Color(0xFFD4AF37))),
              trailing: const Icon(Icons.open_in_new, color: Colors.blueAccent, size: 18),
              onTap: () {
                final cleanUser = supportTelegram.replaceAll('@', '');
                _launchURL('https://t.me/$cleanUser');
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

  // دخول بوابة الإدارة
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
            Text('بوابة الإدارة العليا 👑', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18)),
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

  // لوحة تحكم الإدارة العليا (للتعديل الديناميكي لدعم الواتساب والتليجرام)
  void _openAdminManagementPanel() {
    final targetUsernameCtrl = TextEditingController();
    final whatsappCtrl = TextEditingController(text: supportWhatsApp);
    final telegramCtrl = TextEditingController(text: supportTelegram);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('لوحة التحكم والإدارة العليا 👑', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(color: Colors.white24),
                const Text('تحديث وسائل اتصالات الشكاوى:', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                TextField(
                  controller: whatsappCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'رقم الواتساب الرسمي',
                    labelStyle: TextStyle(color: Colors.white60),
                    prefixIcon: Icon(Icons.phone, color: Colors.greenAccent),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: telegramCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'يوزر تليجرام الدعم',
                    labelStyle: TextStyle(color: Colors.white60),
                    prefixIcon: Icon(Icons.send, color: Colors.blueAccent),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ وسائل الدعم الجديدة'),
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('settings').doc('support_info').set({
                      'whatsapp': whatsappCtrl.text.trim(),
                      'telegram': telegramCtrl.text.trim(),
                    });
                    setState(() {
                      supportWhatsApp = whatsappCtrl.text.trim();
                      supportTelegram = telegramCtrl.text.trim();
                    });
                    if (mounted) Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تحديث أرقام ويوزرات الدعم والشكاوى بنجاح!')),
                    );
                  },
                ),
                const Divider(color: Colors.white24, height: 25),
                const Text('إدارة المشرفين والتوثيق:', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
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
                        label: const Text('ترقية المشرف'),
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
                        label: const Text('توثيق 💙'),
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
              ],
            ),
          ),
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
                Positioned(
                  top: -40,
                  left: -40,
                  child: AnimatedBuilder(
                    animation: _bgAnimationController,
                    builder: (context, child) {
                      return Container(
                        width: 220,
                        height: 220,
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
                          AnimatedBuilder(
                            animation: _glowAnimation,
                            builder: (context, child) {
                              return Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFD4AF37).withOpacity(_glowAnimation.value),
                                      blurRadius: 25,
                                      spreadRadius: 3,
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 48,
                                  backgroundColor: const Color(0xFF1A1A1A),
                                  backgroundImage: _selectedLocalImage != null
                                      ? FileImage(_selectedLocalImage!) as ImageProvider
                                      : (hasNetworkImage ? NetworkImage(profileImageUrl) : null),
                                  child: (_selectedLocalImage == null && !hasNetworkImage)
                                      ? Text(
                                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'س',
                                          style: const TextStyle(fontSize: 34, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: _pickImageFromGallery,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD4AF37),
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4)],
                                ),
                                child: const Icon(Icons.photo_library, size: 18, color: Colors.black),
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
                    Text('$university - $college ($academicYear)', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold)),

                    const SizedBox(height: 24),

                    // بطاقة الخيارات
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
                              leading: const Icon(Icons.lock_reset, color: Color(0xFFD4AF37)),
                              title: const Text('تغيير كلمة المرور', style: TextStyle(color: Colors.white)),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                              onTap: _changePassword,
                            ),
                            const Divider(color: Colors.white12, height: 1),
                            ListTile(
                              leading: const Icon(Icons.headset_mic, color: Color(0xFFD4AF37)),
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

                    // الأزرار السفلية
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
