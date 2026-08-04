import 'dart:async';
import 'package:flutter/material.dart';

// متغيرات عامة لحفظ حالة الجلسة والبيانات
String currentUserAccountName = 'سيدعباس عقيل';
String currentUserEmail = 'abbas@law-platform.com';
String currentUserUniversity = 'جامعة الموصل';
String currentUserCollege = 'كلية الحقوق';
bool isLoggedInGlobal = false;
bool notificationsEnabled = true;
bool isDarkMode = false;
List<Map<String, dynamic>> savedPostsList = [];

// قائمة الإعلانات المتحركة القابلة للإدارة
List<String> bannerAdsList = [
  '📣 إعلان هام: جدول امتحانات الكورس الأول لكلية الحقوق',
  '⚖️ خصم خاص على جميع الكتب الدراسية والمراجع في سوق الكتب',
  '📌 متاح الآن ملخصات المادة القانونية للمراحل الأربع',
];

// هيكلية المواد الدراسية المحدثة مع دعم حقول الملفات والتصنيف الفخم
Map<String, List<Map<String, dynamic>>> academicStagesData = {
  'المرحلة الأولى': [
    {
      'title': 'المدخل لدراسة القانون',
      'categories': [
        {
          'name': 'الملازم',
          'files': [
            {'fileName': 'ملزمة الكورس الأول - أ.د. علي', 'filePath': 'demo_path.pdf'}
          ]
        },
        {
          'name': 'الكتاب المنهجي',
          'files': [
            {'fileName': 'كتاب المدخل لدراسة القانون PDF', 'filePath': 'demo_book.pdf'}
          ]
        },
        {
          'name': 'الأسئلة والملخصات',
          'files': [
            {'fileName': 'ملخص نظرية الحق', 'filePath': 'summary.pdf'},
            {'fileName': 'أسئلة شهرية 2024', 'filePath': 'exam.pdf'}
          ]
        },
      ]
    },
    {
      'title': 'القانون الدستوري',
      'categories': [
        {'name': 'الملازم', 'files': []},
        {
          'name': 'الكتاب المنهجي',
          'files': [
            {'fileName': 'النظام الدستوري المقارن', 'filePath': 'const.pdf'}
          ]
        },
        {
          'name': 'الأسئلة والملخصات',
          'files': [
            {'fileName': 'حلول أسئلة السنوات السابقة', 'filePath': 'answers.pdf'}
          ]
        },
      ]
    },
  ],
  'المرحلة الثانية': [
    {
      'title': 'القانون المدني (الالتزامات)',
      'categories': [
        {
          'name': 'الملازم',
          'files': [
            {'fileName': 'شرح مصادر الالتزام', 'filePath': 'obligations.pdf'}
          ]
        },
        {'name': 'الكتاب المنهجي', 'files': []},
        {'name': 'الأسئلة والملخصات', 'files': []},
      ]
    },
  ],
  'المرحلة الثالثة': [
    {
      'title': 'قانون العقوبات الخاص',
      'categories': [
        {
          'name': 'الملازم',
          'files': [
            {'fileName': 'جرائم الأموال والأشخاص', 'filePath': 'penal.pdf'}
          ]
        },
        {'name': 'الكتاب المنهجي', 'files': []},
        {'name': 'الأسئلة والملخصات', 'files': []},
      ]
    },
  ],
  'المرحلة الرابعة': [
    {
      'title': 'القانون الدولي الخاص',
      'categories': [
        {
          'name': 'الملازم',
          'files': [
            {'fileName': 'أحكام الجنسية والموطن', 'filePath': 'int_law.pdf'}
          ]
        },
        {'name': 'الكتاب المنهجي', 'files': []},
        {'name': 'الأسئلة والملخصات', 'files': []},
      ]
    },
  ],
};

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منصة القانون - كلية الحقوق',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF1A1A1A),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: const Color(0xFFD4AF37),
          primary: const Color(0xFF1A1A1A),
          secondary: const Color(0xFFD4AF37),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF121212),
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFFD4AF37),
          primary: const Color(0xFFD4AF37),
          secondary: const Color(0xFFD4AF37),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
// ==========================================
// 1. الواجهة الترحيبية (Splash Screen)
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Widget targetScreen = isLoggedInGlobal ? const MainNavigationHolder() : const AuthScreen();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => targetScreen));
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
                child: const Icon(Icons.gavel_rounded, size: 80, color: Color(0xFFD4AF37)),
              ),
              const SizedBox(height: 30),
              const Text('منصة القانون - كلية الحقوق', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFD4AF37).withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: const Text('سيدعباس عقيل الحسيني', style: TextStyle(fontSize: 15, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. تسجيل الدخول والتسجيل المعدل (جامعة وكلية يدوياً)
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
  final _universityController = TextEditingController(text: 'جامعة الموصل');
  final _collegeController = TextEditingController(text: 'كلية الحقوق');

  void _submitAuth() {
    isLoggedInGlobal = true;
    if (_nameController.text.isNotEmpty) currentUserAccountName = _nameController.text;
    if (_emailController.text.isNotEmpty) currentUserEmail = _emailController.text;
    if (_universityController.text.isNotEmpty) currentUserUniversity = _universityController.text;
    if (_collegeController.text.isNotEmpty) currentUserCollege = _collegeController.text;

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigationHolder()));
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
              const SizedBox(height: 20),
              const Icon(Icons.gavel_rounded, size: 60, color: Color(0xFFD4AF37)),
              const SizedBox(height: 16),
              Text(isLogin ? 'تسجيل الدخول' : 'إنشاء حساب طالب جديد', textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              if (!isLogin) ...[
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم الكامل', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _universityController, decoration: const InputDecoration(labelText: 'اسم الجامعة (يدوياً)', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _collegeController, decoration: const InputDecoration(labelText: 'اسم الكلية (يدوياً)', border: OutlineInputBorder())),
                const SizedBox(height: 12),
              ],
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder())),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A), foregroundColor: const Color(0xFFD4AF37)),
                  onPressed: _submitAuth,
                  child: Text(isLogin ? 'دخول' : 'تسجيل الحساب'),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(isLogin ? 'ليس لديك حساب؟ سجل الآن' : 'لديك حساب بالفعل؟ سجل دخولك'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
// ==========================================
// 3. شريط التنقل السفلي والواجهة الرئيسية
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
        onTap: (index) => setState(() => _currentIndex = index),
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final PageController _bannerController = PageController();
  int _bannerIndex = 0;
  Timer? _bannerTimer;
  late AnimationController _bgAnimationController;

  final List<Map<String, dynamic>> _posts = [
    {
      'id': '1',
      'author': 'عمادة كلية الحقوق',
      'title': 'تبليغ رسمي بشأن تحديث القوانين والمناهج',
      'content': 'تم نشر الجدول الجديد للتشريعات والمواد الدراسية الصادرة هذا الفصل.',
      'type': 'تبليغ رسمى',
      'likes': 12,
      'isLiked': false,
      'isPinned': true,
      'isSaved': false,
      'comments': [
        {'userName': 'سيدعقيل', 'text': 'تم الاطلاع، شكراً جزيلاً.'},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _startBannerTimer();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  void _startBannerTimer() {
    _bannerTimer?.cancel();
    if (bannerAdsList.isNotEmpty) {
      _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
        if (_bannerController.hasClients && bannerAdsList.isNotEmpty) {
          _bannerIndex = (_bannerIndex + 1) % bannerAdsList.length;
          _bannerController.animateToPage(_bannerIndex, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
        }
      });
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _bgAnimationController.dispose();
    super.dispose();
  }

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

  void _editPost(int index) {
    final titleCtrl = TextEditingController(text: _posts[index]['title']);
    final contentCtrl = TextEditingController(text: _posts[index]['content']);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تعديل التبليغ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: contentCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'المحتوى', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                setState(() {
                  _posts[index]['title'] = titleCtrl.text;
                  _posts[index]['content'] = contentCtrl.text;
                });
                Navigator.pop(c);
              }
            },
            child: const Text('حفظ التعديلات'),
          )
        ],
      ),
    );
  }

  void _deletePost(int index) {
    setState(() {
      _posts.removeAt(index);
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
                decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'الوصف أو المحتوى النصي', border: OutlineInputBorder()),
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

  void _manageAdsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final newAdCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إدارة الإعلانات المتحركة', textDirection: TextDirection.rtl),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: newAdCtrl,
                      decoration: const InputDecoration(labelText: 'إضافة نص إعلان جديد', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة الإعلان'),
                      onPressed: () {
                        if (newAdCtrl.text.trim().isNotEmpty) {
                          setState(() {
                            bannerAdsList.add(newAdCtrl.text.trim());
                          });
                          setDialogState(() {});
                          newAdCtrl.clear();
                          _startBannerTimer();
                        }
                      },
                    ),
                    const Divider(height: 24),
                    const Text('الإعلانات الحالية:', style: TextStyle(fontWeight: FontWeight.bold), textDirection: TextDirection.rtl),
                    const SizedBox(height: 8),
                    Container(
                      height: 180,
                      child: bannerAdsList.isEmpty
                          ? const Center(child: Text('لا توجد إعلانات حالياً'))
                          : ListView.builder(
                              itemCount: bannerAdsList.length,
                              itemBuilder: (context, index) => ListTile(
                                dense: true,
                                title: Text(bannerAdsList[index], style: const TextStyle(fontSize: 13), textDirection: TextDirection.rtl),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          bannerAdsList.removeAt(index);
                                        });
                                        setDialogState(() {});
                                        _startBannerTimer();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
              ],
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
        title: const Text('منصة القانون - التبليغات'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign, color: Color(0xFFD4AF37)),
            tooltip: 'إدارة الإعلانات',
            onPressed: _manageAdsDialog,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.black,
        onPressed: _addPost,
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('نشر جديد'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.03, end: 0.08).animate(_bgAnimationController),
              child: const Center(
                child: Icon(
                  Icons.gavel_rounded,
                  size: 320,
                  color: Color(0xFFD4AF37),
                ),
              ),
            ),
          ),
          Column(
            children: [
              if (bannerAdsList.isNotEmpty)
                Container(
                  height: 75,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                  ),
                  child: PageView.builder(
                    controller: _bannerController,
                    itemCount: bannerAdsList.length,
                    itemBuilder: (context, index) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            bannerAdsList[index],
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    final isPinned = post['isPinned'] == true;
                    final isSaved = post['isSaved'] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                                    Text(post['type'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                                const Spacer(),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (val) {
                                    if (val == 'edit') _editPost(index);
                                    if (val == 'delete') _deletePost(index);
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, color: Colors.blue, size: 18), SizedBox(width: 6), Text('تعديل التبليغ')])),
                                    const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 6), Text('حذف التبليغ')])),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(post['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('${post['content']}.', textDirection: TextDirection.rtl),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// ----------------- 2. شاشة الخدمات والمكتبة المحدثة بالهيكلية الفخمة -----------------
class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الخدمات والكلية'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.account_balance, size: 40, color: Color(0xFFD4AF37)),
                title: const Text('مكتبة الحقوق (المناهج والمراحل)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: const Text('تصفح المواد والمحاضرات الهيكلية المحدثة'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const LawLibraryStagesScreen()));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LawLibraryStagesScreen extends StatefulWidget {
  const LawLibraryStagesScreen({super.key});

  @override
  State<LawLibraryStagesScreen> createState() => _LawLibraryStagesScreenState();
}

class _LawLibraryStagesScreenState extends State<LawLibraryStagesScreen> {
  void _addNewSubject(String stageName) {
    final titleCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('إضافة مادة لـ $stageName'),
        content: TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'اسم المادة', border: OutlineInputBorder())),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                setState(() {
                  academicStagesData[stageName]!.add({
                    'title': titleCtrl.text,
                    'categories': [
                      {'name': 'الملازم', 'files': []},
                      {'name': 'الكتاب المنهجي', 'files': []},
                      {'name': 'الأسئلة والملخصات', 'files': []},
                    ]
                  });
                });
                Navigator.pop(c);
              }
            },
            child: const Text('إضافة'),
          )
        ],
      ),
    );
  }

  void _editSubject(String stageName, int index) {
    final editCtrl = TextEditingController(text: academicStagesData[stageName]![index]['title']);
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('تعديل اسم المادة'),
        content: TextField(controller: editCtrl, decoration: const InputDecoration(border: OutlineInputBorder())),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (editCtrl.text.isNotEmpty) {
                setState(() {
                  academicStagesData[stageName]![index]['title'] = editCtrl.text;
                });
                Navigator.pop(c);
              }
            },
            child: const Text('حفظ'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مكتبة الحقوق - المراحل الدراسية'), backgroundColor: const Color(0xFF1A1A1A), foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: academicStagesData.keys.map((stage) {
          final subjects = academicStagesData[stage]!;
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              leading: const Icon(Icons.school, color: Color(0xFFD4AF37)),
              title: Text(stage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFFD4AF37)),
                onPressed: () => _addNewSubject(stage),
              ),
              children: subjects.asMap().entries.map((entry) {
                int idx = entry.key;
                var subj = entry.value;
                return ListTile(
                  title: Text(subj['title'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('الفروع المتاحة: ${subj['categories'].length}'),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (val) {
                      if (val == 'edit') _editSubject(stage, idx);
                      if (val == 'delete') {
                        setState(() {
                          academicStagesData[stage]!.removeAt(idx);
                        });
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('تعديل المادة')),
                      const PopupMenuItem(value: 'delete', child: Text('حذف المادة')),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => SubjectCategoriesScreen(subjectData: subj)));
                  },
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
// الشاشة المحدثة للفروع والرفع الفعلي للملفات
class SubjectCategoriesScreen extends StatefulWidget {
  final Map<String, dynamic> subjectData;
  const SubjectCategoriesScreen({super.key, required this.subjectData});

  @override
  State<SubjectCategoriesScreen> createState() => _SubjectCategoriesScreenState();
}

class _SubjectCategoriesScreenState extends State<SubjectCategoriesScreen> {
  void _uploadRealFileToCategory(Map<String, dynamic> category) {
    final titleCtrl = TextEditingController();
    String simulatedPath = '';

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            title: Text('إرفاق وررفع ملف لـ ${category['name']}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'اسم أو عنوان الملف المرفوع', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A), foregroundColor: const Color(0xFFD4AF37)),
                  icon: const Icon(Icons.attach_file),
                  label: Text(simulatedPath.isEmpty ? 'اختر ملف PDF من الهاتف' : 'تم اختيار: document.pdf'),
                  onPressed: () {
                    setDlgState(() {
                      simulatedPath = '/storage/emulated/0/Download/law_file.pdf';
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                onPressed: () {
                  if (titleCtrl.text.isNotEmpty) {
                    setState(() {
                      category['files'].add({
                        'fileName': titleCtrl.text,
                        'filePath': simulatedPath.isEmpty ? 'default_path.pdf' : simulatedPath,
                      });
                    });
                    Navigator.pop(c);
                  }
                },
                child: const Text('تأكيد الرفع'),
              )
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List categories = widget.subjectData['categories'];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectData['title']),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: categories.length,
        itemBuilder: (context, catIdx) {
          final cat = categories[catIdx];
          final List files = cat['files'];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: const Icon(Icons.folder_special, color: Color(0xFFD4AF37)),
              title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${files.length} ملفات مرفوعة'),
              trailing: IconButton(
                icon: const Icon(Icons.upload_file, color: Color(0xFFD4AF37)),
                onPressed: () => _uploadRealFileToCategory(cat),
              ),
              children: files.isEmpty
                  ? [const Padding(padding: EdgeInsets.all(8.0), child: Text('لا توجد ملفات مرفوعة حالياً'))]
                  : files.asMap().entries.map((fEntry) {
                      int fIdx = fEntry.key;
                      var fileMap = fEntry.value;
                      return ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(fileMap['fileName']),
                        subtitle: Text('المسار: ${fileMap['filePath']}', style: const TextStyle(fontSize: 10)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () {
                            setState(() {
                              files.removeAt(fIdx);
                            });
                          },
                        ),
                      );
                    }).toList(),
            ),
          );
        },
      ),
    );
  }
}

// ----------------- 3. شاشة الكتب -----------------
class BooksScreen extends StatelessWidget {
  const BooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مكتبة الكتب والـ PDF'), backgroundColor: const Color(0xFF1A1A1A), foregroundColor: Colors.white),
      body: const Center(child: Text('قسم المصادر والكتب القانونية')),
    );
  }
}

// ----------------- 4. شاشة الملف الشخصي الطالب المتكاملة -----------------
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF1A1A1A),
            child: Text(currentUserAccountName.isNotEmpty ? currentUserAccountName[0].toUpperCase() : 'س', style: const TextStyle(fontSize: 30, color: Color(0xFFD4AF37))),
          ),
          const SizedBox(height: 10),
          Text(currentUserAccountName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(currentUserEmail, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Text('$currentUserUniversity - $currentUserCollege', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
          const Divider(height: 30),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode, color: Color(0xFFD4AF37)),
            title: const Text('تفعيل الوضع الداكن (Dark Mode)'),
            value: isDarkMode,
            onChanged: (val) {
              MyApp.of(context).toggleTheme();
            },
          ),
          ListTile(
            leading: const Icon(Icons.bookmark, color: Color(0xFFD4AF37)),
            title: const Text('المنشورات المحفوظة'),
            trailing: Text('${savedPostsList.length}'),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.blue),
            title: const Text('تواصل مع الدعم الفني'),
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
            onTap: () {
              isLoggedInGlobal = false;
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
            },
          )
        ],
      ),
    );
  }
}
