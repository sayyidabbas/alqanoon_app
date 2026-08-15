import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../constants/app_colors.dart';
import '../models/post_model.dart';
import 'admin_panel_screen.dart';
import '../services_screens/electronic_exams_screen.dart';
import '../services_screens/question_bank_screen.dart' as qb; 
import '../services_screens/study_materials_screen.dart' as sm;

// ==========================================
// دالة إرسال الإيميل الحقيقي (SMTP)
// ==========================================
Future<bool> sendOtpEmail(String recipientEmail, String otpCode) async {
  // ⚠️ تنبيه: ضع إيميلك الذي استخرجت منه الرمز السري هنا 
  String username = 'hasnaqeel90@gmail.com'; 
  String password = 'lbut yqdf erum jiok'; // كلمة المرور التي أرسلتها

  final smtpServer = gmail(username, password);
  final message = Message()
    ..from = Address(username, 'إدارة منصة القانون')
    ..recipients.add(recipientEmail)
    ..subject = 'كود التحقق الأمني (OTP) 🔐'
    ..html = """
      <div dir="rtl" style="font-family: Arial, sans-serif; text-align: right;">
        <h3>مرحباً بك في إدارة منصة القانون</h3>
        <p>لقد تم طلب إجراء أمني على حساب الإدارة الخاص بك.</p>
        <p>كود التحقق الخاص بك هو:</p>
        <h2 style="color: #d32f2f; letter-spacing: 5px;">$otpCode</h2>
        <p>يرجى عدم مشاركة هذا الكود مع أي شخص للحفاظ على أمان المنصة.</p>
      </div>
    """;

  try {
    await send(message, smtpServer);
    return true;
  } catch (e) {
    debugPrint('خطأ في إرسال الإيميل: $e');
    return false;
  }
}

// ==========================================
// شاشة غرفة العمليات الأساسية
// ==========================================

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

    // إظهار شاشة تحميل أثناء إرسال الإيميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: AppColors.cardBg,
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.amber),
            SizedBox(width: 20),
            Text('جاري إرسال الكود...', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    String otpCode = (Random().nextInt(900000) + 100000).toString();
    bool isSent = await sendOtpEmail(recoveryEmail, otpCode);
    
    if (!mounted) return;
    Navigator.pop(context); // إخفاء شاشة التحميل

    if (!isSent) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء إرسال الإيميل، تأكد من اتصالك بالإنترنت.')));
      return;
    }

    // حفظ الكود للتحقق منه
    await FirebaseFirestore.instance.collection('settings').doc('secure_admin').set({'current_otp': otpCode}, SetOptions(merge: true));

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
            icon: Icons.build,
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
              Navigator.push(context, MaterialPageRoute(builder: (_) => const qb.AdminQbStageSelectionScreen()));
            },
          ),
          _buildControlCard(
            title: 'تحكم المواد الدراسية',
            icon: Icons.library_books,
            color: Colors.purple,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const sm.AdminStageSelectionScreen()));
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

// ==========================================
// شاشة إعدادات الحماية وتغيير الرمز/الإيميل
// ==========================================

class SecureSettingsScreen extends StatefulWidget {
  const SecureSettingsScreen({super.key});
  @override
  State<SecureSettingsScreen> createState() => _SecureSettingsScreenState();
}

class _SecureSettingsScreenState extends State<SecureSettingsScreen> {
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  String currentEmail = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final doc = await FirebaseFirestore.instance.collection('settings').doc('secure_admin').get();
    if (doc.exists && doc.data()!.containsKey('email')) {
      currentEmail = doc.data()!['email'];
    }
    setState(() {
      isLoading = false;
    });
  }

  void _initiateSave() async {
    if (_pinController.text.isNotEmpty && _pinController.text.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرمز يجب أن يكون 4 أرقام على الأقل')));
      return;
    }
    
    if (_emailController.text.isEmpty && _pinController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال تعديل واحد على الأقل')));
      return;
    }

    if (currentEmail.isNotEmpty) {
      // هناك إيميل مربوط مسبقاً، يجب إرسال كود OTP أولاً للموافقة
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const AlertDialog(
          backgroundColor: AppColors.cardBg,
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.amber),
              SizedBox(width: 20),
              Text('جاري إرسال كود التأكيد...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );

      String otpCode = (Random().nextInt(900000) + 100000).toString();
      bool isSent = await sendOtpEmail(currentEmail, otpCode);
      
      if (!mounted) return;
      Navigator.pop(context); // إغلاق شاشة التحميل

      if (!isSent) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ في إرسال الإيميل. تأكد من اتصالك بالإنترنت.')));
        return;
      }

      // إظهار نافذة إدخال الكود
      final otpController = TextEditingController();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.cardBg,
          title: const Text('التحقق الأمني مطلوب', style: TextStyle(color: Colors.amber)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('لإجراء التعديلات، تم إرسال كود إلى إيميلك الحالي:\n$currentEmail', style: const TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
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
              onPressed: () {
                if (otpController.text.trim() == otpCode) {
                  Navigator.pop(ctx);
                  _saveToFirestore();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الكود غير صحيح!')));
                }
              },
              child: const Text('تأكيد وحفظ', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      );

    } else {
      // لا يوجد إيميل مسبق، حفظ مباشر
      _saveToFirestore();
    }
  }

  Future<void> _saveToFirestore() async {
    Map<String, dynamic> updates = {};
    if (_emailController.text.isNotEmpty) updates['email'] = _emailController.text.trim();
    if (_pinController.text.isNotEmpty) updates['pin'] = _pinController.text.trim();

    await FirebaseFirestore.instance.collection('settings').doc('secure_admin').set(updates, SetOptions(merge: true));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ التعديلات بنجاح!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(title: const Text('إعدادات الحماية'), backgroundColor: AppColors.primary),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.amber))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (currentEmail.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    margin: const EdgeInsets.bottom(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('البريد المربوط حالياً:', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text(currentEmail, style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    margin: const EdgeInsets.bottom(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.5)),
                    ),
                    child: const Text('تنبيه: لا يوجد إيميل مربوط! حسابك معرض للضياع في حال نسيان الرمز.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
                  ),

                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: currentEmail.isEmpty ? 'أدخل بريد إلكتروني للحماية' : 'تغيير البريد الإلكتروني', 
                    labelStyle: const TextStyle(color: Colors.amber),
                    filled: true, fillColor: AppColors.cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'تعيين رمز سري جديد', 
                    labelStyle: const TextStyle(color: Colors.amber),
                    filled: true, fillColor: AppColors.cardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.security, color: Colors.black),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: _initiateSave,
                    label: const Text('حفظ التعديلات', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                )
              ],
            ),
          ),
    );
  }
}
