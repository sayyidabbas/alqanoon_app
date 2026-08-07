import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordHidden = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(Icons.balance, size: 80, color: AppColors.accent),
                      const SizedBox(height: 16),
                      const Text(
                        'منصة القانون',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'تسجيل الدخول',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 40),
                      const TextField(
                        decoration: InputDecoration(
                          labelText: 'اسم المستخدم',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        obscureText: _isPasswordHidden,
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_isPasswordHidden ? Icons.visibility_off : Icons.visibility),
                            onPressed: () {
                              setState(() {
                                _isPasswordHidden = !_isPasswordHidden;
                              });
                            },
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('نسيت كلمة المرور؟', style: TextStyle(color: AppColors.accent)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
                        child: const Text('تسجيل الدخول', style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.accent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                        child: const Text('إنشاء حساب', style: TextStyle(fontSize: 16, color: AppColors.accent)),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'جميع الحقوق محفوظة © منصة القانون',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
