import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;
  bool obfuscatePassword = true;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      if (isLogin) {
        UserCredential creds = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // جلب بيانات الأدمن عند تسجيل الدخول
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(creds.user!.uid)
            .get();

        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          currentUserAccountName = data['name'] ?? 'طالب قانون';
          String role = (data['role'] ?? '').toString().toLowerCase();
          isCurrentUserAdmin = (role == 'admin' || creds.user!.email == 'hasnaqeel3@gmail.com');
        }
      } else {
        UserCredential creds = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // تحديد صلاحية أدمن إذا كان الإيميل هو الإيميل المعتمد لك
        bool makeAdmin = _emailController.text.trim() == 'hasnaqeel3@gmail.com';

        await FirebaseFirestore.instance.collection('users').doc(creds.user!.uid).set({
          'uid': creds.user!.uid,
          'name': _nameController.text.trim(),
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'university': 'جامعة الموصل',
          'college': 'كلية الحقوق',
          'role': makeAdmin ? 'admin' : 'student',
          'createdAt': FieldValue.serverTimestamp(),
        });

        currentUserAccountName = _nameController.text.trim();
        currentUserEmail = _emailController.text.trim();
        isCurrentUserAdmin = makeAdmin;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationHolder()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ في العملية';
      if (e.code == 'user-not-found') message = 'المستخدم غير موجود';
      else if (e.code == 'wrong-password') message = 'كلمة المرور غير صحيحة';
      else if (e.code == 'email-already-in-use') message = 'البريد الإلكتروني مستخدم بالفعل';
      else if (e.code == 'weak-password') message = 'كلمة المرور ضعيفة جداً';
      
      _showSnackBar(message, isError: true);
    } catch (e) {
      _showSnackBar('حدث خطأ غير متوقع: $e', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent.shade700 : const Color(0xFFD4AF37),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F12), Color(0xFF16161C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1E1E24),
                        border: Border.all(color: const Color(0xFFD4AF37)),
                      ),
                      child: const Icon(Icons.balance_rounded, size: 60, color: Color(0xFFD4AF37)),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isLogin ? 'تسجيل الدخول' : 'إنشاء حساب طالب جديد',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                    ),
                    const SizedBox(height: 30),

                    if (!isLogin) ...[
                      _buildTextField(_nameController, 'الاسم الكامل', Icons.person_outline),
                      const SizedBox(height: 16),
                      _buildTextField(_usernameController, 'اسم المستخدم (اليوزر)', Icons.alternate_email),
                      const SizedBox(height: 16),
                    ],

                    _buildTextField(_emailController, 'البريد الإلكتروني', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _passwordController,
                      'كلمة المرور',
                      Icons.lock_outline,
                      isPassword: true,
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.black)
                            : Text(
                                isLogin ? 'تسجيل الدخول' : 'إنشاء الحساب',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextButton(
                      onPressed: () => setState(() => isLogin = !isLogin),
                      child: Text(
                        isLogin ? 'ليس لديك حساب؟ سجل الآن' : 'لديك حساب بالفعل؟ سجل دخولك',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && obfuscatePassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال $label' : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFFD4AF37)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(obfuscatePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: () => setState(() => obfuscatePassword = !obfuscatePassword),
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF1E1E24),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4AF37)),
        ),
      ),
    );
  }
}
