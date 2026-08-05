import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _obscurePassword = true;

  final _identifierController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isCheckingUsername = false;
  bool? isUsernameAvailable;
  String usernameMessage = '';

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
    _identifierController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      isLogin = !isLogin;
      isUsernameAvailable = null;
      usernameMessage = '';
      _obscurePassword = true;
    });
    _animController.reset();
    _animController.forward();
  }

  Future<void> _checkUsernameAvailability(String username) async {
    final cleanUsername = username.trim().toLowerCase();
    if (cleanUsername.isEmpty || cleanUsername.length < 3) {
      setState(() {
        isUsernameAvailable = null;
        usernameMessage = 'اليوزر يجب أن يكون 3 أحرف على الأقل';
      });
      return;
    }

    setState(() {
      isCheckingUsername = true;
    });

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: cleanUsername)
          .get();

      if (mounted) {
        setState(() {
          isCheckingUsername = false;
          if (query.docs.isEmpty) {
            isUsernameAvailable = true;
            usernameMessage = 'اسم المستخدم متاح 🟢';
          } else {
            isUsernameAvailable = false;
            usernameMessage = 'اسم المستخدم مستعمل بالفعل 🔴';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isCheckingUsername = false;
          isUsernameAvailable = false;
          usernameMessage = 'خطأ أثناء فحص اسم المستخدم';
        });
      }
    }
  }

  // واجهة الانتظار للتحقق من رابط البريد الإلكتروني
  void _showEmailVerificationDialog(User user, String name, String email) {
    Timer? timer;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.mark_email_read, color: Color(0xFFD4AF37)),
            SizedBox(width: 8),
            Text('تأكيد البريد الإلكتروني', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تم إرسال رابط التأكيد إلى:\n$email\n\nيرجى فتح بريدك والضغط على الرابط ثم ضغط الزر بالأسفل للتعرف الآلي.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 15),
            const CircularProgressIndicator(color: Color(0xFFD4AF37)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await user.sendEmailVerification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تمت إعادة إرسال رابط التفعيل!')),
              );
            },
            child: const Text('إعادة إرسال الرابط', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            onPressed: () async {
              await user.reload();
              final updatedUser = FirebaseAuth.instance.currentUser;
              if (updatedUser != null && updatedUser.emailVerified) {
                timer?.cancel();
                currentUserAccountName = name;
                currentUserEmail = email;
                isLoggedInGlobal = true;

                if (context.mounted) {
                  Navigator.pop(ctx);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MainNavigationHolder()),
                    (route) => false,
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('لم يتم تأكيد البريد بعد! يرجى الضغط على الرابط في بريدك أولاً.')),
                );
              }
            },
            child: const Text('تم التأكيد، دخول للواجهة', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _resetPasswordDialog() async {
    final resetEmailController = TextEditingController(text: _identifierController.text.trim());
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
              cursorColor: const Color(0xFFD4AF37),
              cursorWidth: 2.5,
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
    final password = _passwordController.text.trim();

    if (isLogin) {
      final input = _identifierController.text.trim();
      if (input.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إدخال اسم المستخدم أو البريد الإلكتروني وكلمة المرور')),
        );
        return;
      }

      setState(() => isLoading = true);

      try {
        String targetEmail = input;

        if (!input.contains('@')) {
          final queryByUsername = await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: input.toLowerCase())
              .get();

          if (queryByUsername.docs.isNotEmpty) {
            targetEmail = queryByUsername.docs.first.data()['email'] ?? '';
          } else {
            throw FirebaseAuthException(code: 'user-not-found');
          }
        }

        UserCredential creds = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: targetEmail,
          password: password,
        );

        String safeName = creds.user?.displayName ?? 'طالب حقوق';
        currentUserAccountName = safeName;
        currentUserEmail = targetEmail;
        isLoggedInGlobal = true;

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigationHolder()),
            (route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage = 'بيانات الدخول غير صحيحة';
        if (e.code == 'user-not-found') errorMessage = 'اسم المستخدم أو البريد غير موجود!';
        if (e.code == 'wrong-password' || e.code == 'invalid-credential') errorMessage = 'كلمة المرور غير صحيحة!';

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red.shade800),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red.shade800),
          );
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
    } else {
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final username = _usernameController.text.trim().toLowerCase();

      if (name.isEmpty || email.isEmpty || username.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء إكمال كافة الحقول')),
        );
        return;
      }

      if (!email.contains('@')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إدخال بريد إلكتروني صحيح يحوي @')),
        );
        return;
      }

      if (isUsernameAvailable == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('اسم المستخدم غير متاح، اختر اسماً آخر')),
        );
        return;
      }

      setState(() => isLoading = true);

      try {
        UserCredential creds = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (creds.user != null) {
          await creds.user!.updateDisplayName(name);

          await FirebaseFirestore.instance.collection('users').doc(creds.user!.uid).set({
            'uid': creds.user!.uid,
            'name': name,
            'username': username,
            'email': email,
            'role': 'user',
            'createdAt': DateTime.now().millisecondsSinceEpoch,
          });

          // إرسال رابط التأكيد للإيميل
          await creds.user!.sendEmailVerification();

          if (mounted) {
            _showEmailVerificationDialog(creds.user!, name, email);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('حدث خطأ أثناء الإنشاء: $e'), backgroundColor: Colors.red.shade800),
          );
        }
      } finally {
        if (mounted) setState(() => isLoading = false);
      }
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
                                if (isLogin) ...[
                                  TextField(
                                    controller: _identifierController,
                                    cursorColor: const Color(0xFFD4AF37),
                                    cursorWidth: 2.5,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'اسم المستخدم / البريد الإلكتروني',
                                      labelStyle: const TextStyle(color: Colors.white60),
                                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFD4AF37)),
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
                                ] else ...[
                                  TextField(
                                    controller: _nameController,
                                    cursorColor: const Color(0xFFD4AF37),
                                    cursorWidth: 2.5,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'الاسم الكامل',
                                      labelStyle: const TextStyle(color: Colors.white60),
                                      prefixIcon: const Icon(Icons.badge, color: Color(0xFFD4AF37)),
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
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _emailController,
                                    cursorColor: const Color(0xFFD4AF37),
                                    cursorWidth: 2.5,
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
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _usernameController,
                                    cursorColor: const Color(0xFFD4AF37),
                                    cursorWidth: 2.5,
                                    onChanged: _checkUsernameAvailability,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'اسم المستخدم (اليوزر)',
                                      labelStyle: const TextStyle(color: Colors.white60),
                                      prefixIcon: const Icon(Icons.alternate_email, color: Color(0xFFD4AF37)),
                                      suffixIcon: isCheckingUsername
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFD4AF37))),
                                            )
                                          : (isUsernameAvailable == null
                                              ? null
                                              : Icon(
                                                  isUsernameAvailable! ? Icons.check_circle : Icons.cancel,
                                                  color: isUsernameAvailable! ? Colors.green : Colors.red,
                                                )),
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
                                  if (usernameMessage.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4, right: 6),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          usernameMessage,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isUsernameAvailable == true ? Colors.green : Colors.redAccent,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                                const SizedBox(height: 14),
                                TextField(
                                  controller: _passwordController,
                                  cursorColor: const Color(0xFFD4AF37),
                                  cursorWidth: 2.5,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'كلمة المرور',
                                    labelStyle: const TextStyle(color: Colors.white60),
                                    prefixIcon: const Icon(Icons.lock, color: Color(0xFFD4AF37)),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                        color: const Color(0xFFD4AF37),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
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
