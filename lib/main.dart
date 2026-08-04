import 'dart:async';
import 'package:flutter/material.dart';

// متغيرات عامة لحفظ حالة الجلسة والبيانات
String currentUserAccountName = 'سيدعباس عقيل';
String currentUserEmail = 'abbas@law-platform.com';
bool isLoggedInGlobal = false;
List<Map<String, dynamic>> savedPostsList = [];

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

    // التوجيه التلقائي بعد 3 ثوانٍ
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Widget targetScreen = isLoggedInGlobal ? const MainNavigationHolder() : const AuthScreen();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => targetScreen),
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
      isLoggedInGlobal = true;
      if (_emailController.text.isNotEmpty) {
        currentUserEmail = _emailController.text;
        currentUserAccountName = _emailController.text.split('@').first;
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationHolder()),
      );
    } else {
      if (_nameController.text.isNotEmpty) {
        currentUserAccountName = _nameController.text;
      }
      if (_emailController.text.isNotEmpty) {
        currentUserEmail = _emailController.text;
      }
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
                isLoggedInGlobal = true;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isReset ? 'تم تغيير كلمة المرور بنجاح!' : 'تم تأكيد الحساب بنجاح!')),
                );
                if (!isReset) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainNavigationHolder()),
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
// 3. أ) شريط التنقل السفلي وشاشة الرئيسية
// ==========================================
class MainNavigationHolder extends StatefulWidget {
  const MainNavigationHolder({super.key});

  @override
  State<MainNavigationHolder> createState() => _MainNavigationHolderState();
}

class _MainNavigationHolderState extends State<MainNavigationHolder> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const ServicesScreen(),
    const BooksScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'الخدمات'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'الكتب'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'حسابي'),
        ],
      ),
    );
  }
}

// ----------------- 1. شاشة الرئيسية (الأخبار والمنشورات) -----------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> _posts = [
    {
      'id': '1',
      'author': 'الإدارة الرسمية',
      'title': 'تبليغ رسمي بشأن تحديث القوانين',
      'content': 'تم نشر الجدول الجديد للتشريعات القانونية الصادرة هذا الشهر. يرجى المتابعة.',
      'type': 'تبليغ رسمى',
      'likes': 12,
      'isLiked': false,
      'isPinned': true,
      'isSaved': false,
      'comments': [
        {'userName': 'علي أحمد', 'text': 'شكراً جزيلاً'},
      ],
    },
  ];

  void _sortPosts() {
    _posts.sort((a, b) {
      if (a['isPinned'] == b['isPinned']) return 0;
      return a['isPinned'] ? -1 : 1;
    });
  }

  void _togglePin(int index) {
    setState(() {
      _posts[index]['isPinned'] = !_posts[index]['isPinned'];
      _sortPosts();
    });
  }

  void _toggleSave(int index) {
    setState(() {
      _posts[index]['isSaved'] = !_posts[index]['isSaved'];
      if (_posts[index]['isSaved']) {
        if (!savedPostsList.contains(_posts[index])) {
          savedPostsList.add(_posts[index]);
        }
      } else {
        savedPostsList.removeWhere((p) => p['id'] == _posts[index]['id']);
      }
    });
  }

  void _addPost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final titleController = TextEditingController();
        final contentController = TextEditingController();
        String selectedType = 'خبر';

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
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرفاق الصورة'))),
                  ),
                  IconButton(
                    icon: const Icon(Icons.videocam),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرفاق الفيديو'))),
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
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'author': currentUserAccountName,
                        'title': titleController.text,
                        'content': contentController.text,
                        'type': selectedType,
                        'likes': 0,
                        'isLiked': false,
                        'isPinned': false,
                        'isSaved': false,
                        'comments': [],
                      });
                      _sortPosts();
                    });
                    Navigator.pop(context);
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
      isScrollControlled: true,
      builder: (context) {
        final commentController = TextEditingController();
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: 400,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    const Text('التعليقات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Expanded(
                      child: _posts[index]['comments'].isEmpty
                          ? const Center(child: Text('لا توجد تعليقات بعد'))
                          : ListView.builder(
                              itemCount: _posts[index]['comments'].length,
                              itemBuilder: (context, i) {
                                final comment = _posts[index]['comments'][i];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF1A1A1A),
                                    child: Text(
                                      comment['userName'][0].toUpperCase(),
                                      style: const TextStyle(color: Color(0xFFD4AF37)),
                                    ),
                                  ),
                                  title: Text(comment['userName'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text(comment['text']),
                                );
                              },
                            ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            decoration: const InputDecoration(
                              hintText: 'اكتب تعليقاً...',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send, color: Color(0xFFD4AF37)),
                          onPressed: () {
                            if (commentController.text.trim().isNotEmpty) {
                              setState(() {
                                _posts[index]['comments'].add({
                                  'userName': currentUserAccountName,
                                  'text': commentController.text.trim(),
                                });
                              });
                              setModalState(() {});
                              commentController.clear();
                            }
                          },
                        )
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _sortPosts();
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
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          final isPinned = post['isPinned'] == true;
          final isSaved = post['isSaved'] == true;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isPinned ? const BorderSide(color: Color(0xFFD4AF37), width: 1.5) : BorderSide.none,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPinned)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Icon(Icons.push_pin, size: 16, color: Color(0xFFD4AF37)),
                          SizedBox(width: 4),
                          Text('منشور مثبت في الأعلى', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFF1A1A1A),
                        child: Text(post['author'][0].toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37))),
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
                            child: Text(post['type'], style: TextStyle(fontSize: 10, color: post['type'] == 'تبليغ رسمى' ? Colors.red : Colors.blue)),
                          )
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? const Color(0xFFD4AF37) : Colors.grey),
                        onPressed: () => _toggleSave(index),
                      ),
                      IconButton(
                        icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: isPinned ? const Color(0xFFD4AF37) : Colors.grey),
                        onPressed: () => _togglePin(index),
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
                        icon: Icon(post['isLiked'] ? Icons.favorite : Icons.favorite_border, color: post['isLiked'] ? Colors.red : Colors.grey),
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
// ==========================================
// 3. ب) شاشة الخدمات، الكتب، والملف الشخصي
// ==========================================

// ----------------- 2. شاشة الخدمات -----------------
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> services = [
      {'title': 'المكتبة التشريعية والقوانين', 'icon': Icons.gavel, 'desc': 'تصفح النصوص والقوانين الرسمية'},
      {'title': 'طلب استشارة قانونية', 'icon': Icons.support_agent, 'desc': 'تواصل مباشر مع المستشارين'},
      {'title': 'حاسبة الرسوم القضائية', 'icon': Icons.calculate, 'desc': 'احتساب التكاليف والرسوم'},
      {'title': 'نماذج وصيغ العقود', 'icon': Icons.description, 'desc': 'نماذج جاهزة للتحميل والاستخدام'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('الخدمات القانونية'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خدمة "${service['title']}" قيد التفعيل')));
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(service['icon'], size: 40, color: const Color(0xFFD4AF37)),
                    const SizedBox(height: 10),
                    Text(service['title'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(service['desc'], textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ----------------- 3. شاشة الكتب والـ PDF -----------------
class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مكتبة الكتب والمصادر'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 36),
              title: Text('الكتاب القانوني رقم ${index + 1}'),
              subtitle: const Text('شرح القوانين والأنظمة - صيغة PDF'),
              trailing: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('جاري فتح الكتاب...')));
                },
                child: const Text('قراءة', style: TextStyle(color: Color(0xFFD4AF37))),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ----------------- 4. شاشة حسابي (Profile Page) -----------------
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) {
        final passController = TextEditingController();
        return AlertDialog(
          title: const Text('تغيير كلمة المرور'),
          content: TextField(
            controller: passController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث كلمة المرور بنجاح')));
              },
              child: const Text('حفظ'),
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
        title: const Text('الملف الشخصي'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF1A1A1A),
                  child: Text(
                    currentUserAccountName.isNotEmpty ? currentUserAccountName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 40, color: Color(0xFFD4AF37)),
                  ),
                ),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFFD4AF37),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('إمكانية تغيير الصورة الشخصية')));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(currentUserAccountName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(currentUserEmail, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.bookmark, color: Color(0xFFD4AF37)),
              title: const Text('المنشورات المحفوظة'),
              trailing: Chip(label: Text('${savedPostsList.length}')),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: savedPostsList.length,
                    itemBuilder: (context, i) => ListTile(
                      title: Text(savedPostsList[i]['title']),
                      subtitle: Text(savedPostsList[i]['content']),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.lock_reset, color: Color(0xFFD4AF37)),
              title: const Text('تغيير كلمة المرور'),
              onTap: _changePassword,
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
              onTap: () {
                isLoggedInGlobal = false;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
