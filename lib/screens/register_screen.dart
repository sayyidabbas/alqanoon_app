import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // المتحكمات
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _acceptTerms = false;
  bool _isLoading = false;
  String? _selectedStage;
  String? _selectedDepartment;

  // متغيرا الفحص اللحظي لليوزر
  bool _isCheckingUsername = false;
  bool? _isUsernameAvailable;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // 🔍 دالة الفحص اللحظي لاسم المستخدم في Firestore
  void _onUsernameChanged(String username) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    final cleanUsername = username.trim().toLowerCase();
    if (cleanUsername.isEmpty || cleanUsername.length < 3) {
      setState(() {
        _isUsernameAvailable = null;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() => _isCheckingUsername = true);

    // الانتظار 500 ملي ثانية بعد توقف المستخدم عن الكتابة للبحث في الفايربيس
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final query = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: cleanUsername)
            .get();

        if (mounted) {
          setState(() {
            _isUsernameAvailable = query.docs.isEmpty;
            _isCheckingUsername = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isCheckingUsername = false);
      }
    });
  }

  // 🚀 دالة إنشاء الحساب وإرسال رابط التحقق
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isUsernameAvailable == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اسم المستخدم مستعمل بالفعل، اختر اسماً آخر'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. إنشاء الحساب في Firebase Auth
      final UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final User? user = userCredential.user;

      if (user != null) {
        // 2. تحديث الاسم في ملف المستخدِم
        await user.updateDisplayName(_fullNameController.text.trim());

        // 3. إرسال رابط التحقق للبريد الإلكتروني
        await user.sendEmailVerification();

        // 4. حفظ كامل بيانات الحساب في قاعدة البيانات Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': _fullNameController.text.trim(),
          'username': _usernameController.text.trim().toLowerCase(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'stage': _selectedStage,
          'department': _selectedDepartment,
          'createdAt': FieldValue.serverTimestamp(),
          'isVerified': false,
        });

        if (!mounted) return;

        // 5. إظهار رسالة تنبيه بضرورة تفعيل الإيميل
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('تم إنشاء الحساب بنجاح! 📧', textAlign: TextAlign.center),
            content: Text(
              'أرسلنا رابط تأكيد إلى بريدك الإلكتروني:\n(${_emailController.text})\n\nيرجى فتح إيميلك والضغط على رابط التفعيل ثم تسجيل الدخول.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // إغلاق النافذة
                  Navigator.pop(context); // العودة لصفحة تسجيل الدخول
                },
                child: const Text('حسناً، فهمت', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ في إنشاء الحساب';
      if (e.code == 'email-already-in-use') {
        message = 'البريد الإلكتروني مستخدم بالفعل';
      } else if (e.code == 'weak-password') {
        message = 'كلمة المرور ضعيفة جداً';
      } else if (e.code == 'invalid-email') {
        message = 'البريد الإلكتروني غير صحيح';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب جديد')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // الاسم الكامل
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'الاسم الكامل', prefixIcon: Icon(Icons.person)),
                validator: (val) => val == null || val.trim().isEmpty ? 'يرجى إدخال الاسم الكامل' : null,
              ),
              const SizedBox(height: 12),

              // اسم المستخدم مع الفحص اللحظي
              TextFormField(
                controller: _usernameController,
                onChanged: _onUsernameChanged,
                decoration: InputDecoration(
                  labelText: 'اسم المستخدم',
                  prefixIcon: const Icon(Icons.alternate_email),
                  suffixIcon: _isCheckingUsername
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : _isUsernameAvailable == true
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : _isUsernameAvailable == false
                              ? const Icon(Icons.cancel, color: Colors.red)
                              : null,
                  helperText: _isUsernameAvailable == true
                      ? 'اسم المستخدم متاح ✅'
                      : _isUsernameAvailable == false
                          ? 'اسم المستخدم غير متاح ❌'
                          : null,
                  helperStyle: TextStyle(
                    color: _isUsernameAvailable == true ? Colors.green : Colors.red,
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'يرجى إدخال اسم المستخدم';
                  if (val.trim().length < 3) return 'اسم المستخدم يجب أن يكون 3 حروف على الأقل';
                  if (_isUsernameAvailable == false) return 'اسم المستخدم مستخدم مسبقاً';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // البريد الإلكتروني
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email)),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'يرجى إدخال البريد الإلكتروني';
                  if (!val.contains('@')) return 'يرجى إدخال بريد إلكتروني صحيح';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // رقم الهاتف
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الهاتف', prefixIcon: Icon(Icons.phone)),
                validator: (val) => val == null || val.trim().isEmpty ? 'يرجى إدخال رقم الهاتف' : null,
              ),
              const SizedBox(height: 12),

              // كلمة المرور
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'كلمة المرور', prefixIcon: Icon(Icons.lock)),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'يرجى إدخال كلمة المرور';
                  if (val.length < 6) return 'كلمة المرور يجب أن تكون 6 خانات على الأقل';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // تأكيد كلمة المرور
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور', prefixIcon: Icon(Icons.lock_clock)),
                validator: (val) {
                  if (val != _passwordController.text) return 'كلمات المرور غير متطابقة';
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // المرحلة الدراسية
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'المرحلة الدراسية'),
                value: _selectedStage,
                items: ['المرحلة الأولى', 'المرحلة الثانية', 'المرحلة الثالثة', 'المرحلة الرابعة']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _selectedStage = val),
                validator: (val) => val == null ? 'يرجى اختيار المرحلة الدراسية' : null,
              ),
              const SizedBox(height: 12),

              // القسم
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'القسم'),
                value: _selectedDepartment,
                items: ['القانون العام', 'القانون الخاص']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (val) => setState(() => _selectedDepartment = val),
                validator: (val) => val == null ? 'يرجى اختيار القسم' : null,
              ),
              const SizedBox(height: 12),

              // الموافقة على الشروط
              CheckboxListTile(
                title: const Text('أوافق على شروط الاستخدام والخصوصية', style: TextStyle(fontSize: 14)),
                value: _acceptTerms,
                activeColor: AppColors.accent,
                onChanged: (val) => setState(() => _acceptTerms = val ?? false),
              ),
              const SizedBox(height: 20),

              // زر إنشاء الحساب
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: (_acceptTerms && !_isLoading) ? _handleRegister : null,
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                        )
                      : const Text('إنشاء الحساب', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
