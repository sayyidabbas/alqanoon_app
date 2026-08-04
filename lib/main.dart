import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منصة القانون',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1A1A1A),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37),
          primary: const Color(0xFF1A1A1A),
          secondary: const Color(0xFFD4AF37),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ==========================================
// 1. الواجهة الترحيبية المتحركة (Splash Screen)
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    // الانتقال التلقائي بعد 3 ثوانٍ
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                  ),
                  child: const Icon(
                    Icons.gavel_rounded,
                    size: 80,
                    color: Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'أهلاً بكم في',
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  'منصة القانون',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'سيدعباس عقيل الحسيني',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ==========================================
// 2. نظام تسجيل الدخول وإنشاء الحساب
// ==========================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  void _submitAuth() {
    if (isLogin) {
      // تسجيل الدخول
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // إرسال كود التحقق لإنشاء الحساب
      _showOtpDialog('تم إرسال رمز التأكيد (OTP) إلى إيميلك لإكمال التسجيل.');
    }
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (context) {
        final resetEmailController = TextEditingController();
        return AlertDialog(
          title: const Text('نسيت كلمة المرور'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('أدخل بريدك الإلكتروني لإرسال رمز إعادة التعيين:'),
              const SizedBox(height: 10),
              TextField(
                controller: resetEmailController,
                decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showOtpDialog('تم إرسال كود تعيين كلمة المرور الجديدة لبريدك الإلكتروني.', isReset: true);
              },
              child: const Text('إرسال الكود'),
            ),
          ],
        );
      },
    );
  }

  void _showOtpDialog(String message, {bool isReset = false}) {
    showDialog(
      context: context,
      builder: (context) {
        final otpController = TextEditingController();
        final newPassController = TextEditingController();
        return AlertDialog(
          title: const Text('تأكيد الرمز'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 10),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'أدخل الكود (مثال: 1234)'),
              ),
              if (isReset) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: newPassController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
                ),
              ]
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isReset ? 'تم تغيير كلمة المرور بنجاح!' : 'تم تأكيد الحساب بنجاح!')),
                );
                if (!isReset) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                }
              },
              child: const Text('تأكيد'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(Icons.gavel_rounded, size: 60, color: Color(0xFFD4AF37)),
              const SizedBox(height: 20),
              Text(
                isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              if (!isLogin) ...[
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'اسم الحساب',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              if (isLogin) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    child: const Text('نسيت كلمة المرور؟'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    foregroundColor: const Color(0xFFD4AF37),
                  ),
                  onPressed: _submitAuth,
                  child: Text(isLogin ? 'دخول' : 'إرسال كود التأكيد'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                  });
                },
                child: Text(isLogin ? 'ليس لديك حساب؟ سجل الآن' : 'لديك حساب بالفعل؟ سجل الدخول'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ==========================================
// 3. الشاشة الرئيسية وقسم المنشورات والتبليغات
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> _posts = [
    {
      'author': 'الإدارة الرسمية',
      'title': 'تبليغ رسمي بشأن تحديث القوانين',
      'content': 'تم نشر الجدول الجديد للتشريعات القانونية الصادرة هذا الشهر. يرجى المتابعة.',
      'type': 'تبليغ رسمى',
      'mediaUrl': 'https://via.placeholder.com/400x200',
      'mediaType': 'image',
      'likes': 12,
      'isLiked': false,
      'comments': ['شكراً جزيلاً', 'تم الاطلاع'],
    },
  ];

  void _addPost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final titleController = TextEditingController();
        final contentController = TextEditingController();
        String selectedType = 'خبر';
        String mediaType = 'صورة';

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('نشر خبر / تبليغ جديد', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'العنوان'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'الوصف أو المحتوى النصي'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('النوع: '),
                  DropdownButton<String>(
                    value: selectedType,
                    items: ['خبر', 'تبليغ رسمى'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => selectedType = v!),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add_a_photo),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرفاق الصورة بنجاح')));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.videocam),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرفاق الفيديو بنجاح')));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A)),
                onPressed: () {
                  if (titleController.text.isNotEmpty) {
                    setState(() {
                      _posts.insert(0, {
                        'author': 'سيدعباس عقيل',
                        'title': titleController.text,
                        'content': contentController.text,
                        'type': selectedType,
                        'mediaUrl': '',
                        'mediaType': mediaType,
                        'likes': 0,
                        'isLiked': false,
                        'comments': [],
                      });
                    });
                    Navigator.pop(context);
                    // محاكاة إرسال الإشعار
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🔔 إشعار هاتف للمستخدمين: منشور جديد "$selectedType"'),
                        backgroundColor: const Color(0xFFD4AF37),
                      ),
                    );
                  }
                },
                child: const Text('نشر وتنبيه المستخدمين', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showComments(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final commentController = TextEditingController();
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Text('التعليقات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _posts[index]['comments'].length,
                itemBuilder: (context, i) => ListTile(
                  leading: const Icon(Icons.comment),
                  title: Text(_posts[index]['comments'][i]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      decoration: const InputDecoration(hintText: 'اكتب تعليقاً...'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      if (commentController.text.isNotEmpty) {
                        setState(() {
                          _posts[index]['comments'].add(commentController.text);
                        });
                        Navigator.pop(context);
                      }
                    },
                  )
                ],
              ),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة القانون - الأخبار والتبليغات'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.black,
        onPressed: _addPost,
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('نشر جديد'),
      ),
      body: _posts.isEmpty
          ? const Center(child: Text('لا توجد منشورات حالياً'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF1A1A1A),
                              child: Text(post['author'][0], style: const TextStyle(color: Color(0xFFD4AF37))),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(post['author'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: post['type'] == 'تبليغ رسمى' ? Colors.red.shade100 : Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    post['type'],
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: post['type'] == 'تبليغ رسمى' ? Colors.red : Colors.blue,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(post['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(post['content'], style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 12),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  post['isLiked'] = !post['isLiked'];
                                  post['likes'] += post['isLiked'] ? 1 : -1;
                                });
                              },
                              icon: Icon(
                                post['isLiked'] ? Icons.favorite : Icons.favorite_border,
                                color: post['isLiked'] ? Colors.red : Colors.grey,
                              ),
                              label: Text('${post['likes']} إعجاب'),
                            ),
                            TextButton.icon(
                              onPressed: () => _showComments(index),
                              icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                              label: Text('${post['comments'].length} تعليق'),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
