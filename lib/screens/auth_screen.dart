import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  final Function(String name, String email)? onAuthSuccess;

  const AuthScreen({super.key, this.onAuthSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final nameInput = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال البريد الإلكتروني وكلمة المرور')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        UserCredential creds = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        String finalName = creds.user?.displayName ?? nameInput;
        if (finalName.isEmpty) finalName = 'سيدعباس عقيل';

        if (widget.onAuthSuccess != null) {
          widget.onAuthSuccess!(finalName, email);
        }
      } else {
        if (nameInput.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('الرجاء إدخال الاسم الكامل')),
          );
          setState(() => isLoading = false);
          return;
        }

        UserCredential creds = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (creds.user != null) {
          await creds.user!.updateDisplayName(nameInput);
        }

        if (widget.onAuthSuccess != null) {
          widget.onAuthSuccess!(nameInput, email);
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'حدث خطأ أثناء الاتصال بالخادم';

      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage = 'كلمة المرور غير صحيحة، يرجى التأكد منها والتحاولة مجدداً.';
          break;
        case 'user-not-found':
          errorMessage = 'البريد الإلكتروني غير مسجل، يمكنك إنشاء حساب جديد.';
          break;

        case 'invalid-email':
          errorMessage = 'صيغة البريد الإلكتروني غير صحيحة.';
          break;
        case 'email-already-in-use':
          errorMessage = 'هذا البريد الإلكتروني مسجل بالفعل.';
          break;
        case 'weak-password':
          errorMessage = 'كلمة المرور ضعيفة جداً، يجب أن تتكون من 6 أحرف على الأقل.';
          break;
        case 'too-many-requests':
          errorMessage = 'تم محاولة الدخول لعدة مرات خطأ، يرجى الانتظار قليلاً وإعادة المحاولة.';
          break;
        default:
          errorMessage = e.message ?? errorMessage;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ غير متوقع: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                  ),
                  child: const Icon(Icons.balance_rounded, size: 50, color: Color(0xFFD4AF37)),
                ),
                const SizedBox(height: 20),
                Text(
                  isLogin ? 'تسجيل الدخول' : 'إنشاء حساب طالب جديد',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                ),
                const SizedBox(height: 24),
                if (!isLogin) ...[
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'الاسم الكامل',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person, color: Color(0xFFD4AF37)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email, color: Color(0xFFD4AF37)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock, color: Color(0xFFD4AF37)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: const Color(0xFFD4AF37),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: isLoading ? null : _submitAuth,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Color(0xFFD4AF37))
                        : Text(
                            isLogin ? 'دخول' : 'تسجيل الحساب',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(
                    isLogin ? 'ليس لديك حساب؟ سجل الآن' : 'لديك حساب بالفعل؟ سجل دخولك',
                    style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
