import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  final Function(String name, String email)? onAuthSuccess;

  const AuthScreen({super.key, this.onAuthSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  bool isLogin = true;
  bool isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      isLogin = !isLogin;
    });
    _animController.reset();
    _animController.forward();
  }

  Future<void> _resetPasswordDialog() async {
    final resetEmailController = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_reset, color: Color(0xFFD4AF37)),
            SizedBox(width: 8),
            Text(
              'استعادة كلمة المرور',
              style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'أدخل بريدك الإلكتروني وسيصلك رابط التعيين (تحقق من الرسائل المهملة Spam):',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: resetEmailController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                labelStyle: const TextStyle(color: Colors.white60),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.email, color: Color(0xFFD4AF37)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى كتابة البريد الإلكتروني')),
                );
                return;
              }
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إرسال رابط إعادة التعيين! تحقق من بريدك ومجلد (Spam)'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } on FirebaseAuthException catch (e) {
                if (mounted) {
                  String msg = 'حدث خطأ أثناء الإرسال';
                  if (e.code == 'user-not-found') msg = 'هذا البريد غير مسجل بالنظام!';
                  if (e.code == 'invalid-email') msg = 'صيغة البريد الإلكتروني غير صحيحة!';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg), backgroundColor: Colors.red.shade800),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red.shade800),
                  );
                }
              }
            },
            child: const Text('إرسال الرابط', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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

        String finalName = 'سيدعباس عقيل';
        if (creds.user != null && creds.user?.displayName != null && creds.user!.displayName!.isNotEmpty) {
          finalName = creds.user!.displayName!;
        } else if (nameInput.isNotEmpty) {
          finalName = nameInput;
        }

        currentUserAccountName = finalName;
        currentUserEmail = email;
        isLoggedInGlobal = true;

        if (widget.onAuthSuccess != null) {
          widget.onAuthSuccess!(finalName, email);
        } else if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationHolder()),
          );
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
          try {
            await creds.user!.updateDisplayName(nameInput);
          } catch (_) {}
        }

        currentUserAccountName = nameInput;
        currentUserEmail = email;
        isLoggedInGlobal = true;

        if (widget.onAuthSuccess != null) {
          widget.onAuthSuccess!(nameInput, email);
        } else if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationHolder()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'حدث خطأ أثناء الاتصال بالخادم';

      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage = 'كلمة المرور غير صحيحة، يرجى التأكد منها وإعادة المحاولة.';
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
          errorMessage = 'كلمة المرور ضعيفة، يجب أن تتكون من 6 أحرف على الأقل.';
          break;
        case 'too-many-requests':
          errorMessage = 'تم محاولة الدخول لعدة مرات خطأ، يرجى الانتظار قليلاً.';
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
            content: Text('حدث خطأ: $e'),
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
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
            ),
          ),
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4AF37).withOpacity(0.12),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A1A1A),
                          border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.3),
                              blurRadius: 25,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.balance_rounded,
                          size: 60,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  isLogin ? 'تسجيل الدخول' : 'إنشاء حساب طالب جديد',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD4AF37),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 400),
                                  child: !isLogin
                                      ? Padding(
                                          padding: const EdgeInsets.only(bottom: 14),
                                          child: TextField(
                                            controller: _nameController,
                                            style: const TextStyle(color: Colors.white),
                                            decoration: InputDecoration(
                                              labelText: 'الاسم الكامل',
                                              labelStyle: const TextStyle(color: Colors.white60),
                                              prefixIcon: const Icon(Icons.person, color: Color(0xFFD4AF37)),
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              filled: true,
                                              fillColor: Colors.black26,
                                            ),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                ),
                                TextField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'البريد الإلكتروني',
                                    labelStyle: const TextStyle(color: Colors.white60),
                                    prefixIcon: const Icon(Icons.email, color: Color(0xFFD4AF37)),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.black26,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'كلمة المرور',
                                    labelStyle: const TextStyle(color: Colors.white60),
                                    prefixIcon: const Icon(Icons.lock, color: Color(0xFFD4AF37)),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.black26,
                                  ),
                                ),
                                if (isLogin) ...[
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      onPressed: _resetPasswordDialog,
                                      child: const Text(
                                        'نسيت كلمة المرور؟',
                                        style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13),
                                      ),
                                    ),
                                  ),
                                ] else
                                  const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD4AF37),
                                      foregroundColor: Colors.black,
                                      elevation: 5,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: isLoading ? null : _submitAuth,
                                    child: isLoading
                                        ? const CircularProgressIndicator(color: Colors.black)
                                        : Text(
                                            isLogin ? 'تسجيل الدخول' : 'إنشاء الحساب',
                                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _toggleMode,
                        child: Text(
                          isLogin ? 'ليس لديك حساب؟ سجل الآن' : 'لديك حساب بالفعل؟ سجل دخولك',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
