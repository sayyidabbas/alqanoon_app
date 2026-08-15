import 'dart:io'; // تم إضافة هذه المكتبة لحل مشكلة الـ File
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../models/post_model.dart';
import 'admin_panel_screen.dart';
import '../services_screens/electronic_exams_screen.dart';
// تم إعطاء ألقاب للملفات لحل مشكلة تعارض الأسماء
import '../services_screens/question_bank_screen.dart' as qb; 
import '../services_screens/study_materials_screen.dart' as sm;

class SecureAdminDashboardScreen extends StatefulWidget {
  final List<PostModel> officialPosts;
  final List<String> announcements;
  final Function(String, File?) onAddPost;
  final Function(int) onDeletePost;
  final Function(int, String) onEditPost;
  final Function(String) onAddBanner;
  final Function(int) onDeleteBanner;
  final Function(int) onUpdateTimerDays;
  final Function() onDeleteTimer;

  const SecureAdminDashboardScreen({
    super.key,
    required this.officialPosts,
    required this.announcements,
    required this.onAddPost,
    required this.onDeletePost,
    required this.onEditPost,
    required this.onAddBanner,
    required this.onDeleteBanner,
    required this.onUpdateTimerDays,
    required this.onDeleteTimer,
  });

  @override
  State<SecureAdminDashboardScreen> createState() => _SecureAdminDashboardScreenState();
}

class _SecureAdminDashboardScreenState extends State<SecureAdminDashboardScreen> {
  bool _isUnlocked = false;
  final TextEditingController _pinController = TextEditingController();

  Future<void> _verifyPin() async {
    final doc = await FirebaseFirestore.instance.collection('settings').doc('secure_admin').get();
    String correctPin = '1234'; 
    if (doc.exists && doc.data()!.containsKey('pin')) {
      correctPin = doc.data()!['pin'].toString();
    }

    if (_pinController.text.trim() == correctPin) {
      setState(() {
        _isUnlocked = true;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرمز السري غير صحيح!')));
      }
    }
  }

  void _showRecoveryDialog() async {
    final doc = await FirebaseFirestore.instance.collection('settings').doc('secure_admin').get();
    String recoveryEmail = '';
    if (doc.exists && doc.data()!.containsKey('email')) {
      recoveryEmail = doc.data()!['email'];
    }

    if (recoveryEmail.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لم يتم ربط بريد إلكتروني للاسترداد مسبقاً.')));
      }
      return;
    }

    String otpCode = (Random().nextInt(900000) + 100000).toString();
    
    await FirebaseFirestore.instance.collection('settings').doc('secure_admin').set({'current_otp': otpCode}, SetOptions(merge: true));
    debugPrint('كود الاسترداد المرسل للإيميل: $otpCode'); 

    if (mounted) {
      final otpController = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: const Text('استرداد الحساب', style: TextStyle(color: Colors.amber)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('تم إرسال كود التحقق إلى الإيميل:\n$recoveryEmail', style: const TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
              const SizedBox(height: 15),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'أدخل كود الـ OTP', hintStyle: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              onPressed: () async {
                final checkDoc = await FirebaseFirestore.instance.collection('settings').doc('secure_admin').get();
                if (checkDoc.data()!['current_otp'] == otpController.text.trim()) {
                  await FirebaseFirestore.instance.collection('settings').doc('secure_admin').update({'pin': '1234', 'current_otp': FieldValue.delete()});
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت استعادة الرمز إلى 1234 بنجاح')));
                  }
                } else {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الكود غير صحيح!')));
                  }
                }
              },
              child: const Text('تحقق', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isUnlocked) {
      return Scaffold(
        backgroundColor: AppColors.primary,
        appBar: AppBar(title: const Text('التحقق الأمني'), backgroundColor: AppColors.primary),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security, size: 80, color: Colors.amber),
                const SizedBox(height: 20),
                const Text('لوحة الإدارة الحصينة', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 30),
                TextField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 10),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.cardBg,
                    hintText: '****',
                    hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: _verifyPin,
                    child: const Text('دخول', style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
                TextButton(
                  onPressed: _showRecoveryDialog,
                  child: const Text('نسيت الرمز السري؟', style: TextStyle(color: Colors.white54)),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('غرفة العمليات', style: TextStyle(color: Colors.amber)),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            tooltip: 'إعدادات الأمان',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecureSettingsScreen())),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildControlCard(
            title: 'تحكم الواجهة الرئيسية',
            icon: Icons.build, // تم تعديل اسم الأيقونة هنا
            color: Colors.blue,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPanelScreen(
                posts: widget.officialPosts,
                announcements: widget.announcements,
                onAddPost: widget.onAddPost,
                onDeletePost: widget.onDeletePost,
                onEditPost: widget.onEditPost,
                onAddBanner: widget.onAddBanner,
                onDeleteBanner: widget.onDeleteBanner,
                onUpdateTimerDays: widget.onUpdateTimerDays,
                onDeleteTimer: widget.onDeleteTimer,
              )));
            },
          ),
          _buildControlCard(
            title: 'تحكم سوق الكتب',
            icon: Icons.storefront,
            color: Colors.orange,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMarketDashboard()));
            },
          ),
          _buildControlCard(
            title: 'تحكم بنك الأسئلة',
            icon: Icons.quiz,
            color: Colors.green,
            onTap: () {
              // تم تعديل الاستدعاء وحذف كلمة const المسببة للخطأ
              Navigator.push(context, MaterialPageRoute(builder: (_) => qb.AdminQbStageSelectionScreen()));
            },
          ),
          _buildControlCard(
            title: 'تحكم المواد الدراسية',
            icon: Icons.library_books,
            color: Colors.purple,
            onTap: () {
              // تم التعديل لمنع تعارض الأسماء
              Navigator.push(context, MaterialPageRoute(builder: (_) => sm.AdminStageSelectionScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlCard({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Card(
      color: AppColors.cardBg,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 30),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
        trailing: const Icon(Icons.arrow_back_ios, color: Colors.white54, size: 16),
        onTap: onTap,
      ),
    );
  }
}

class SecureSettingsScreen extends StatefulWidget {
  const SecureSettingsScreen({super.key});
  @override
  State<SecureSettingsScreen> createState() => _SecureSettingsScreenState();
}

class _SecureSettingsScreenState extends State<SecureSettingsScreen> {
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();

  void _saveSettings() async {
    if (_pinController.text.isNotEmpty && _pinController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرمز يجب أن يكون 4 أرقام على الأقل')));
      return;
    }
    
    Map<String, dynamic> updates = {};
    if (_emailController.text.isNotEmpty) updates['email'] = _emailController.text.trim();
    if (_pinController.text.isNotEmpty) updates['pin'] = _pinController.text.trim();

    if (updates.isNotEmpty) {
      await FirebaseFirestore.instance.collection('settings').doc('secure_admin').set(updates, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح!')));
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(title: const Text('إعدادات الحماية'), backgroundColor: AppColors.primary),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'بريد الاسترداد الإلكتروني (مهم جداً)', labelStyle: TextStyle(color: Colors.amber)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'تعيين رمز سري جديد', labelStyle: TextStyle(color: Colors.amber)),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(vertical: 15)),
                onPressed: _saveSettings,
                child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }
} 
