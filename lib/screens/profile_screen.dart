import 'dartd:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late AnimationController _entranceController;

  String username = '';
  String profileImageUrl = '';
  String displayName = '';
  String university = '';
  String college = '';
  String academicYear = 'المرحلة الأولى';
  bool isVerified = false;
  bool notificationsEnabled = true;
  bool isLoading = true;
  bool isMasterAdmin = false;

  File? _selectedLocalImage;
  final ImagePicker _picker = ImagePicker();

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
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _loadUserData();
    _loadSupportContactInfo();
    _checkMasterAdminStatus();
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _glowController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _checkMasterAdminStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        isMasterAdmin = prefs.getBool('isMasterAdminUnlocked') ?? false;
      });
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedImagePath = prefs.getString('saved_profile_image_path');
    if (savedImagePath != null && File(savedImagePath).existsSync()) {
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late AnimationController _entranceController;

  String username = '';
  String profileImageUrl = '';
  String displayName = '';
  String university = '';
  String college = '';
  String academicYear = 'المرحلة الأولى';
  bool isVerified = false;
  bool notificationsEnabled = true;
  bool isLoading = true;
  bool isMasterAdmin = false;

  File? _selectedLocalImage;
  final ImagePicker _picker = ImagePicker();

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
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _loadUserData();
    _loadSupportContactInfo();
    _checkMasterAdminStatus();
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    _glowController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _checkMasterAdminStatus() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        isMasterAdmin = prefs.getBool('isMasterAdminUnlocked') ?? false;
      });
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedImagePath = prefs.getString('saved_profile_image_path');
    if (savedImagePath != null && File(savedImagePath).existsSync()) {
      setState(() {
        _selectedLocalImage = File(savedImagePath);
      });
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (mounted) {
            setState(() {
              username = data['username'] ?? '';
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

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 88,
      );

      if (pickedFile != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_profile_image_path', pickedFile.path);

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
              content: Text('تم تثبيت صورة البروفايل الفاخرة بنجاح! 📸'),
              backgroundColor: Color(0xFFD4AF37),
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
  }Future<void> _launchURL(String urlString) async {
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

  void _openChangePasswordDialog() {
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF141416),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: Color(0xFFD4AF37)),
              SizedBox(width: 8),
              Text('تغيير كلمة المرور', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPassCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  labelStyle: const TextStyle(color: Colors.white60),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD4AF37)), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2), borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: confirmPassCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور الجديدة',
                  labelStyle: const TextStyle(color: Colors.white60),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD4AF37)), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2), borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final p1 = newPassCtrl.text.trim();
                      final p2 = confirmPassCtrl.text.trim();
                      if (p1.isEmpty || p1.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة المرور يجب أن لا تقل عن 6 أحرف')));
                        return;
                      }
                      if (p1 != p2) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمات المرور غير متطابقة')));
                        return;
                      }

                      setModalState(() => isSubmitting = true);
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          await user.updatePassword(p1);
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم تحديث كلمة المرور بنجاح! 🔒'), backgroundColor: Colors.green),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('خطأ أثناء التحديث: $e'), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        setModalState(() => isSubmitting = false);
                      }
                    },
              child: isSubmitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) : const Text('تحديث كلمة المرور', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditProfileScreen() {
    final nameCtrl = TextEditingController(text: displayName);
    final uniCtrl = TextEditingController(text: university);
    final colCtrl = TextEditingController(text: college);
    String selectedStage = academicYear;

    final stages = ['المرحلة الأولى', 'المرحلة الثانية', 'المرحلة الثالثة', 'المرحلة الرابعة', 'خريج حقوق'];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: const Color(0xFF0D0D0F),
          appBar: AppBar(
            title: const Text('تعديل البيانات الشخصية', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF141418),
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
                    fillColor: Colors.white.withOpacity(0.04),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: stages.contains(selectedStage) ? selectedStage : stages.first,
                  dropdownColor: const Color(0xFF1A1A1E),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'المرحلة الدراسية',
                    labelStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(Icons.school, color: Color(0xFFD4AF37)),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD4AF37)), borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2), borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.04),
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
                    fillColor: Colors.white.withOpacity(0.04),
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
                    fillColor: Colors.white.withOpacity(0.04),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  height: 52,
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
                          'academicYear': selectedStage,
                          'university': uniCtrl.text.trim(),
                          'college': colCtrl.text.trim(),
                        });
                        setState(() {
                          displayName = nameCtrl.text.trim();
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

  void _openSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141418),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
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
            const Text('اختر وسيلة التواصل المباشرة المتاحة للرد الفوري:', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
  void _openMasterAdminDialog() async {
    if (isMasterAdmin) {
      _openAdminManagementPanel();
      return;
    }

    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141418),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
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
            onPressed: () async {
              if (userCtrl.text.trim() == 'x9.ta9' && passCtrl.text.trim() == 'Abbas312004') {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isMasterAdminUnlocked', true);
                if (mounted) {
                  setState(() => isMasterAdmin = true);
                  Navigator.pop(ctx);
                  _openAdminManagementPanel();
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('غير مصرح لك بالدخول!'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('دخول وتثبيت الصلاحية'),
          ),
        ],
      ),
    );
  }

  void _openAdminManagementPanel() {
    final targetUsernameCtrl = TextEditingController();
    final whatsappCtrl = TextEditingController(text: supportWhatsApp);
    final telegramCtrl = TextEditingController(text: supportTelegram);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF141418),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 20, left: 20, right: 20),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.75,
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
                  const Text('المشرفون والحسابات الموثقة حالياً:', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 160,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                        final docs = snapshot.data!.docs.where((d) {
                          final data = d.data() as Map<String, dynamic>;
                          return (data['role'] == 'admin') || (data['isVerified'] == true);
                        }).toList();

                        if (docs.isEmpty) {
                          return const Center(child: Text('لا يوجد مشرفون أو موثقون حالياً', style: TextStyle(color: Colors.white38)));
                        }

                        return ListView.builder(
                          itemCount: docs.length,
                          itemBuilder: (ctx, i) {
                            final uData = docs[i].data() as Map<String, dynamic>;
                            final bool isAdmin = uData['role'] == 'admin';
                            final bool isVerif = uData['isVerified'] == true;

                            return ListTile(
                              dense: true,
                              title: Text(uData['name'] ?? '', style: const TextStyle(color: Colors.white)),
                              subtitle: Text('@${uData['username'] ?? ''}', style: const TextStyle(color: Color(0xFFD4AF37))),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isAdmin)
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                                      tooltip: 'سحب الإشراف',
                                      onPressed: () async {
                                        await FirebaseFirestore.instance.collection('users').doc(docs[i].id).update({'role': 'user'});
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم سحب الإشراف من @${uData['username']}')));
                                      },
                                    ),
                                  if (isVerif)
                                    IconButton(
                                      icon: const Icon(Icons.do_not_disturb_on_outlined, color: Colors.blueAccent, size: 20),
                                      tooltip: 'إزالة التوثيق',
                                      onPressed: () async {
                                        await FirebaseFirestore.instance.collection('users').doc(docs[i].id).update({'isVerified': false});
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إلغاء توثيق @${uData['username']}')));
                                      },
                                    ),
                                ],
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
          ),
        ),
      ),
    );
  }
  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141418),
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
        backgroundColor: const Color(0xFF141418),
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
    bool hasNetworkImage = profileImageUrl.startsWith('http://') || profileImageUrl.startsWith('https://');

    return Scaffold(
      backgroundColor: const Color(0xFF08080A),
      appBar: AppBar(
        title: const Text('الملف الشخصي', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: const Color(0xFF121215),
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isMasterAdmin ? Icons.workspace_premium : Icons.admin_panel_settings,
              color: const Color(0xFFD4AF37),
              size: 26,
            ),
            tooltip: isMasterAdmin ? 'لوحة الإدارة المفعلة 👑' : 'بوابة الإدارة',
            onPressed: _openMasterAdminDialog,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)))
          : Stack(
              children: [
                Positioned(
                  top: -60,
                  right: -60,
                  child: AnimatedBuilder(
                    animation: _bgAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(_bgAnimationController.value * 25, _bgAnimationController.value * 15),
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFD4AF37).withOpacity(0.12),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 100,
                  left: -80,
                  child: AnimatedBuilder(
                    animation: _bgAnimationController,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(-_bgAnimationController.value * 20, -_bgAnimationController.value * 30),
                        child: Container(
                          width: 300,
                          height: 300,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFD4AF37).withOpacity(0.08),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                FadeTransition(
                  opacity: CurvedAnimation(parent: _entranceController, curve: Curves.easeIn),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedBuilder(
                              animation: _glowAnimation,
                              builder: (context, child) {
                                return Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFD4AF37), width: 2.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD4AF37).withOpacity(_glowAnimation.value),
                                        blurRadius: 32,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 52,
                                    backgroundColor: const Color(0xFF141418),
                                    backgroundImage: _selectedLocalImage != null
                                        ? FileImage(_selectedLocalImage!) as ImageProvider
                                        : (hasNetworkImage ? NetworkImage(profileImageUrl) : null),
                                    child: (_selectedLocalImage == null && !hasNetworkImage)
                                        ? Text(
                                            displayName.isNotEmpty ? displayName[0].toUpperCase() : 'س',
                                            style: const TextStyle(fontSize: 38, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                            if (isMasterAdmin)
                              const Positioned(
                                top: -14,
                                right: 0,
                                left: 0,
                                child: Icon(Icons.workspace_premium, color: Color(0xFFD4AF37), size: 28),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: _pickImageFromGallery,
                                child: Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD4AF37),
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 6)],
                                  ),
                                  child: const Icon(Icons.photo_library, size: 19, color: Colors.black),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(displayName, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                          if (isVerified || isMasterAdmin) ...[
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
                      const SizedBox(height: 6),
                      Text(widget.currentUserEmail, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white60, fontSize: 13)),
                      const SizedBox(height: 6),
                      Text('$university - $college ($academicYear)', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold)),

                      const SizedBox(height: 26),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.06),
                                Colors.white.withOpacity(0.02),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.35), width: 1.2),
                          ),
                          child: Column(
                            children: [
                              SwitchListTile(
                                activeColor: const Color(0xFFD4AF37),
                                title: const Text('الإشعارات والتنبيهات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                secondary: const Icon(Icons.notifications_active, color: Color(0xFFD4AF37)),
                                value: notificationsEnabled,
                                onChanged: (val) => setState(() => notificationsEnabled = val),
                              ),
                              const Divider(color: Colors.white12, height: 1),
                              ListTile(
                                leading: const Icon(Icons.edit, color: Color(0xFFD4AF37)),
                                title: const Text('تعديل البيانات الشخصية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                                onTap: _openEditProfileScreen,
                              ),
                              const Divider(color: Colors.white12, height: 1),
                              ListTile(
                                leading: const Icon(Icons.lock_reset, color: Color(0xFFD4AF37)),
                                title: const Text('تغيير كلمة المرور', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                                onTap: _openChangePasswordDialog,
                              ),
                              const Divider(color: Colors.white12, height: 1),
                              ListTile(
                                leading: const Icon(Icons.headset_mic, color: Color(0xFFD4AF37)),
                                title: const Text('الدعم الفني والشكاوى', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                                onTap: _openSupportDialog,
                              ),
                              const Divider(color: Colors.white12, height: 1),
                              ListTile(
                                leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFFD4AF37)),
                                title: const Text('الشروط وسياسة الخصوصية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
                                onTap: () {},
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 26),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.12),
                                foregroundColor: Colors.redAccent,
                                side: const BorderSide(color: Colors.redAccent, width: 1.2),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.logout),
                              label: const Text('خروج', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: _confirmLogout,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade900,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              icon: const Icon(Icons.delete_forever),
                              label: const Text('حذف الحساب', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: _confirmDeleteAccount,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
