import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

// ==========================================
// إعدادات Firebase السحابية المدمجة
// ==========================================
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AiZaSyBOT51AEyYCOGBteudtWv',
    appId: '1:449394795:android:6f7',
    messagingSenderId: '449394795',
    projectId: 'alqanoon-302c7',
    storageBucket: 'alqanoon-302c7.firebasestorage.app',
  );
}

// ==========================================
// متغيرات عامة لحفظ حالة الجلسة والبيانات
// ==========================================
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

// قائمة الأحداث والعداد التنازلي القابلة للإدارة
List<Map<String, dynamic>> countdownEventsList = [
  {'title': 'امتحانات الكورس الأول', 'days': 12, 'icon': Icons.hourglass_top},
  {'title': 'المحاكمة الصورية', 'days': 5, 'icon': Icons.gavel},
];

// قائمة الحكم والمواد القانونية القابلة للإدارة
List<String> legalQuotesList = [
  '« لا جَرِيمَةَ وَلا عُقُوبَةَ إِلاّ بينَصٍّ »',
  '« العقد شريعة المتعاقدين »',
  '« المتهم بيء حتى تثبت إدانته »',
];
int currentQuoteIndex = 0;
// قاعدة بيانات جدول المحاضرات الدراسية الديناميكي
Map<String, Map<String, Map<String, List<Map<String, String>>>>> fullScheduleDatabase = {
  'المرحلة الأولى': {
    'الشعبة الأولى (أ)': {
      'الأحد': [
        {'subject': 'المدخل لدراسة القانون', 'time': '08:30 ص - 10:30 ص', 'hall': 'القاعة 1', 'professor': 'أ.د. علي الحسيني'},
      ],
      'الإثنين': [], 'الثلاثاء': [], 'الأربعاء': [], 'الخميس': [],
    },
    'الشعبة الثانية (ب)': {
      'الأحد': [], 'الإثنين': [], 'الثلاثاء': [], 'الأربعاء': [], 'الخميس': [],
    }
  },
  'المرحلة الثانية': {
    'الشعبة الأولى (أ)': {
      'الأحد': [], 'الإثنين': [], 'الثلاثاء': [], 'الأربعاء': [], 'الخميس': [],
    }
  },
  'المرحلة الثالثة': {
    'الشعبة الأولى (أ)': {
      'الأحد': [], 'الإثنين': [], 'الثلاثاء': [], 'الأربعاء': [], 'الخميس': [],
    }
  },
  'المرحلة الرابعة': {
    'الشعبة الأولى (أ)': {
      'الأحد': [], 'الإثنين': [], 'الثلاثاء': [], 'الأربعاء': [], 'الخميس': [],
    }
  },
};

// هيكلية المواد الدراسية لمكتبة الحقوق
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
  'المرحلة الثالثة': [],
  'المرحلة الرابعة': [],
};

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init bypassed/error: $e");
  }
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

    Timer(const Duration(seconds: 3), () async {
      if (mounted) {
        try {
          User? user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            isLoggedInGlobal = true;
            currentUserEmail = user.email ?? currentUserEmail;
            currentUserAccountName = user.displayName ?? currentUserAccountName;
          }
        } catch (_) {}
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
// 2. تسجيل الدخول والتسجيل عبر Firebase
// ==========================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _universityController = TextEditingController(text: 'جامعة الموصل');
  final _collegeController = TextEditingController(text: 'كلية الحقوق');

  Future<void> _submitAuth() async {
    setState(() => isLoading = true);
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        UserCredential creds = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await creds.user?.updateDisplayName(_nameController.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(creds.user?.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'university': _universityController.text.trim(),
          'college': _collegeController.text.trim(),
        });
      }

      isLoggedInGlobal = true;
      if (_nameController.text.isNotEmpty) currentUserAccountName = _nameController.text;
      if (_emailController.text.isNotEmpty) currentUserEmail = _emailController.text;
      if (_universityController.text.isNotEmpty) currentUserUniversity = _universityController.text;
      if (_collegeController.text.isNotEmpty) currentUserCollege = _collegeController.text;

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigationHolder()));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في العملية: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
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
                  onPressed: isLoading ? null : _submitAuth,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Color(0xFFD4AF37))
                      : Text(isLogin ? 'دخول' : 'تسجيل الحساب'),
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
  String _selectedCategoryFilter = 'الكل';

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

  void _showComments(String docId, List comments) {
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
                      child: comments.isEmpty
                          ? const Center(child: Text('لا توجد تعليقات بعد'))
                          : ListView.builder(
                              itemCount: comments.length,
                              itemBuilder: (context, i) {
                                final comment = comments[i];
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
                          onPressed: () async {
                            if (commentController.text.trim().isNotEmpty) {
                              List updated = List.from(comments);
                              updated.add({
                                'userName': currentUserAccountName,
                                'text': commentController.text.trim(),
                              });
                              await FirebaseFirestore.instance.collection('posts').doc(docId).update({'comments': updated});
                              commentController.clear();
                              if (mounted) Navigator.pop(context);
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

  void _addPost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final titleController = TextEditingController();
        final contentController = TextEditingController();
        String selectedType = 'أخبار الكلية';
        String? attachedImagePath;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
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
                  const Text('نشر جديد مع صورة ووصف', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                      const Text('نوع النشر: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedType,
                        items: ['تبليغ رسمى', 'أخبار الكلية', 'جداول الامتحانات']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setModalState(() {
                              selectedType = v;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A), foregroundColor: const Color(0xFFD4AF37)),
                    icon: const Icon(Icons.add_a_photo),
                    label: Text(attachedImagePath == null ? 'إرفاق صورة مع المنشور' : 'تم إرفاق الصورة'),
                    onPressed: () {
                      setModalState(() {
                        attachedImagePath = 'sample_user_uploaded_image';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                    onPressed: () async {
                      if (titleController.text.isNotEmpty) {
                        await FirebaseFirestore.instance.collection('posts').add({
                          'author': currentUserAccountName,
                          'title': titleController.text,
                          'content': contentController.text,
                          'type': selectedType,
                          'timeAgo': 'الآن',
                          'isNew': true,
                          'imagePath': attachedImagePath,
                          'likes': 0,
                          'likedBy': [],
                          'isPinned': false,
                          'comments': [],
                          'timestamp': FieldValue.serverTimestamp(),
                        });
                        if (mounted) Navigator.pop(context);
                      }
                    },
                    child: const Text('نشر وتنبيه المستخدمين', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _manageCountdownsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final titleCtrl = TextEditingController();
        final daysCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              title: const Text('إدارة العداد التنازلي للأحداث'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان الحدث', border: OutlineInputBorder())),
                    const SizedBox(height: 8),
                    TextField(controller: daysCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الأيام المتبقية', border: OutlineInputBorder())),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                      onPressed: () {
                        if (titleCtrl.text.isNotEmpty && daysCtrl.text.isNotEmpty) {
                          setState(() {
                            countdownEventsList.add({
                              'title': titleCtrl.text,
                              'days': int.parse(daysCtrl.text),
                              'icon': Icons.event
                            });
                          });
                          setDlgState(() {});
                          titleCtrl.clear();
                          daysCtrl.clear();
                        }
                      },
                      child: const Text('إضافة حدث جديدة'),
                    ),
                    const Divider(),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        itemCount: countdownEventsList.length,
                        itemBuilder: (context, idx) => ListTile(
                          dense: true,
                          title: Text(countdownEventsList[idx]['title']),
                          subtitle: Text('متبقي: ${countdownEventsList[idx]['days']} يوماً'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                            onPressed: () {
                              setState(() {
                                countdownEventsList.removeAt(idx);
                              });
                              setDlgState(() {});
                            },
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
            );
          },
        );
      },
    );
  }

  void _manageLegalQuotesDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final quoteCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              title: const Text('إدارة حكمة / مادة اليوم القانونية'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: quoteCtrl, decoration: const InputDecoration(labelText: 'نص القاعدة أو الحكمة', border: OutlineInputBorder())),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                      onPressed: () {
                        if (quoteCtrl.text.isNotEmpty) {
                          setState(() {
                            legalQuotesList.add('« ${quoteCtrl.text} »');
                          });
                          setDlgState(() {});
                          quoteCtrl.clear();
                        }
                      },
                      child: const Text('إضافة حكمة'),
                    ),
                    const Divider(),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        itemCount: legalQuotesList.length,
                        itemBuilder: (context, idx) => ListTile(
                          dense: true,
                          title: Text(legalQuotesList[idx]),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                            onPressed: () {
                              setState(() {
                                legalQuotesList.removeAt(idx);
                                if (currentQuoteIndex >= legalQuotesList.length) currentQuoteIndex = 0;
                              });
                              setDlgState(() {});
                            },
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق'))],
            );
          },
        );
      },
    );
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة القانون - التبليغات'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.timer, color: Color(0xFFD4AF37)), onPressed: _manageCountdownsDialog),
          IconButton(icon: const Icon(Icons.format_quote, color: Color(0xFFD4AF37)), onPressed: _manageLegalQuotesDialog),
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
              child: const Center(child: Icon(Icons.gavel_rounded, size: 320, color: Color(0xFFD4AF37))),
            ),
          ),
          Column(
            children: [
              if (legalQuotesList.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD4AF37)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          legalQuotesList[currentQuoteIndex],
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.navigate_next, color: Colors.white, size: 20),
                        onPressed: () {
                          setState(() {
                            currentQuoteIndex = (currentQuoteIndex + 1) % legalQuotesList.length;
                          });
                        },
                      )
                    ],
                  ),
                ),

              if (countdownEventsList.isNotEmpty)
                SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: countdownEventsList.length,
                    itemBuilder: (context, idx) {
                      final evt = countdownEventsList[idx];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            Icon(evt['icon'] as IconData, size: 16, color: Colors.black),
                            const SizedBox(width: 6),
                            Text('⌛ ${evt['title']}: متبقي ${evt['days']} يوماً', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Row(
                  children: ['الكل', 'تبليغ رسمى', 'أخبار الكلية', 'جداول الامتحانات'].map((cat) {
                    bool isSel = _selectedCategoryFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        selectedColor: const Color(0xFFD4AF37),
                        onSelected: (val) {
                          setState(() {
                            _selectedCategoryFilter = cat;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('لا توجد منشورات حالياً'));
                    }

                    var docs = snapshot.data!.docs;
                    if (_selectedCategoryFilter != 'الكل') {
                      docs = docs.where((doc) => doc['type'] == _selectedCategoryFilter).toList();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var doc = docs[index];
                        var post = doc.data() as Map<String, dynamic>;
                        String docId = doc.id;
                        List comments = post['comments'] ?? [];
                        int likes = post['likes'] ?? 0;

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
                                      child: Text((post['author'] ?? 'س')[0].toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37))),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(post['author'] ?? 'مجهول', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Row(
                                          children: [
                                            Text(post['timeAgo'] ?? 'الآن', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                            if (post['isNew'] == true) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                                decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                                                child: const Text('جديد', style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                                              )
                                            ]
                                          ],
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (val) {
                                        if (val == 'delete') {
                                          FirebaseFirestore.instance.collection('posts').doc(docId).delete();
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 6), Text('حذف التبليغ')])),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(post['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text('${post['content'] ?? ''}.', textDirection: TextDirection.rtl),
                                if (post['imagePath'] != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    height: 140,
                                    width: double.infinity,
                                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(8)),
                                    child: const Icon(Icons.image, size: 50, color: Colors.grey),
                                  )
                                ],
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        FirebaseFirestore.instance.collection('posts').doc(docId).update({'likes': likes + 1});
                                      },
                                      icon: const Icon(Icons.favorite_border, color: Colors.red),
                                      label: Text('$likes إعجاب'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _showComments(docId, comments),
                                      icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                                      label: Text('${comments.length} تعليق'),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
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
// ==========================================
// 4. شاشة الخدمات والكلية المحدثة
// ==========================================
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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
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
          const SizedBox(height: 12),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const Icon(Icons.calendar_month, size: 40, color: Colors.blue),
              title: const Text('جدول المحاضرات الأسبوعي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: const Text('متابعة المراحل والشعب وأوقات المحاضرات والقاعات'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (c) => const DynamicWeeklyScheduleScreen()));
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const Icon(Icons.forum, size: 40, color: Colors.green),
              title: const Text('منتدى الطلبة والدردشة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: const Text('غرف المحادثة، إرسال الملازم، والرد المباشر'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (c) => const StudentForumScreen()));
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------- هيكل جدول المحاضرات الديناميكي (مراحل وشعب) -----------------
class DynamicWeeklyScheduleScreen extends StatefulWidget {
  const DynamicWeeklyScheduleScreen({super.key});

  @override
  State<DynamicWeeklyScheduleScreen> createState() => _DynamicWeeklyScheduleScreenState();
}

class _DynamicWeeklyScheduleScreenState extends State<DynamicWeeklyScheduleScreen> {
  String selectedStage = 'المرحلة الأولى';

  void _addSectionDialog() {
    final secCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('إضافة شعبة جديدة لـ $selectedStage'),
        content: TextField(controller: secCtrl, decoration: const InputDecoration(labelText: 'اسم الشعبة (مثلاً: الشعبة الثالثة ج)', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            onPressed: () {
              if (secCtrl.text.isNotEmpty) {
                setState(() {
                  fullScheduleDatabase[selectedStage]![secCtrl.text] = {
                    'الأحد': [], 'الإثنين': [], 'الثلاثاء': [], 'الأربعاء': [], 'الخميس': [],
                  };
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

  @override
  Widget build(BuildContext context) {
    Map<String, Map<String, List<Map<String, String>>>> sections = fullScheduleDatabase[selectedStage] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('جدول المحاضرات الدراسية'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            height: 55,
            color: const Color(0xFF1A1A1A),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['المرحلة الأولى', 'المرحلة الثانية', 'المرحلة الثالثة', 'المرحلة الرابعة'].map((stage) {
                bool isSel = selectedStage == stage;
                return GestureDetector(
                  onTap: () => setState(() => selectedStage = stage),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFD4AF37) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(stage, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('شعب $selectedStage:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A), foregroundColor: const Color(0xFFD4AF37)),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('إضافة شعبة'),
                  onPressed: _addSectionDialog,
                )
              ],
            ),
          ),
          Expanded(
            child: sections.isEmpty
                ? const Center(child: Text('لا توجد شعب مضافة لهذه المرحلة'))
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: sections.keys.map((secName) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Color(0xFF1A1A1A), child: Icon(Icons.groups, color: Color(0xFFD4AF37))),
                          title: Text(secName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: const Text('اضغط لمشاهدة جدول الأيام والمحاضرات'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () {
                                  setState(() {
                                    fullScheduleDatabase[selectedStage]!.remove(secName);
                                  });
                                },
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 14),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => SectionDaysScheduleScreen(stage: selectedStage, sectionName: secName),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  ),
          )
        ],
      ),
    );
  }
}

class SectionDaysScheduleScreen extends StatefulWidget {
  final String stage;
  final String sectionName;
  const SectionDaysScheduleScreen({super.key, required this.stage, required this.sectionName});

  @override
  State<SectionDaysScheduleScreen> createState() => _SectionDaysScheduleScreenState();
}

class _SectionDaysScheduleScreenState extends State<SectionDaysScheduleScreen> {
  String selectedDay = 'الأحد';

  void _addLectureDialog() {
    final subjCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final hallCtrl = TextEditingController();
    final profCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('إضافة محاضرة - ${widget.sectionName} ($selectedDay)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: subjCtrl, decoration: const InputDecoration(labelText: 'اسم المادة', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'التوقيت (مثال: 08:30 ص)', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: hallCtrl, decoration: const InputDecoration(labelText: 'القاعة الدراسية', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            TextField(controller: profCtrl, decoration: const InputDecoration(labelText: 'اسم الأستاذ', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
            onPressed: () {
              if (subjCtrl.text.isNotEmpty) {
                setState(() {
                  fullScheduleDatabase[widget.stage]![widget.sectionName]![selectedDay]!.add({
                    'subject': subjCtrl.text,
                    'time': timeCtrl.text,
                    'hall': hallCtrl.text,
                    'professor': profCtrl.text,
                  });
                });
                Navigator.pop(c);
              }
            },
            child: const Text('إضافة المحاضرة'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> lectures = fullScheduleDatabase[widget.stage]?[widget.sectionName]?[selectedDay] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.sectionName} - $selectedDay'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD4AF37),
        foregroundColor: Colors.black,
        onPressed: _addLectureDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Container(
            height: 55,
            color: const Color(0xFF1A1A1A),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'].map((day) {
                bool isSel = selectedDay == day;
                return GestureDetector(
                  onTap: () => setState(() => selectedDay = day),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel ? const Color(0xFFD4AF37) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(day, style: TextStyle(color: isSel ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: lectures.isEmpty
                ? const Center(child: Text('لا توجد محاضرات في هذا اليوم لهذه الشعبة'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: lectures.length,
                    itemBuilder: (context, idx) {
                      final lec = lectures[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Color(0xFF1A1A1A), child: Icon(Icons.menu_book, color: Color(0xFFD4AF37))),
                          title: Text(lec['subject']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('⏰ ${lec['time']!} | 📍 ${lec['hall']!}\n👨‍🏫 ${lec['professor']!}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () {
                              setState(() {
                                fullScheduleDatabase[widget.stage]![widget.sectionName]![selectedDay]!.removeAt(idx);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
// ----------------- شاشة منتدى الطلبة والدردشة الاحترافية -----------------
class StudentForumScreen extends StatefulWidget {
  const StudentForumScreen({super.key});

  @override
  State<StudentForumScreen> createState() => _StudentForumScreenState();
}

class _StudentForumScreenState extends State<StudentForumScreen> {
  String activeChannel = '📢 الدردشة العامة';
  Map<String, dynamic>? replyToMessage;
  final TextEditingController _chatController = TextEditingController();

  void _sendMessage() async {
    if (_chatController.text.trim().isNotEmpty) {
      String text = _chatController.text.trim();
      _chatController.clear();
      
      await FirebaseFirestore.instance.collection('forum_chats').add({
        'channel': activeChannel,
        'sender': currentUserAccountName,
        'text': text,
        'replyTo': replyToMessage != null ? replyToMessage!['text'] : null,
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        replyToMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(activeChannel),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            color: Colors.grey.shade200,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['📢 الدردشة العامة', '📚 تبادل الملازم', '❓ سؤال وجواب'].map((ch) {
                bool isSel = activeChannel == ch;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: ChoiceChip(
                    label: Text(ch, style: TextStyle(fontSize: 12, color: isSel ? Colors.black : Colors.grey.shade700, fontWeight: FontWeight.bold)),
                    selected: isSel,
                    selectedColor: const Color(0xFFD4AF37),
                    onSelected: (val) => setState(() => activeChannel = ch),
                  ),
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('forum_chats')
                  .where('channel', isEqualTo: activeChannel)
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                }
                var docs = snapshot.data?.docs ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, idx) {
                    var msg = docs[idx].data() as Map<String, dynamic>;
                    bool isMe = msg['sender'] == currentUserAccountName;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFFD4AF37) : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: isMe ? const Radius.circular(14) : const Radius.circular(2),
                            bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(14),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMe)
                              Text(msg['sender'] ?? '', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber)),
                            if (msg['replyTo'] != null) ...[
                              Container(
                                padding: const EdgeInsets.all(6),
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                                child: Text('رد على: ${msg['replyTo']}', style: TextStyle(fontSize: 11, color: isMe ? Colors.black87 : Colors.white70, fontStyle: FontStyle.italic)),
                              )
                            ],
                            const SizedBox(height: 2),
                            Text(msg['text'] ?? '', style: TextStyle(color: isMe ? Colors.black : Colors.white, fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          if (replyToMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.amber.shade100,
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 16, color: Colors.black),
                  const SizedBox(width: 6),
                  Expanded(child: Text('جاري الرد على: ${replyToMessage!['text']}', style: const TextStyle(fontSize: 12, color: Colors.black), overflow: TextOverflow.ellipsis)),
                  IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => replyToMessage = null)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file, color: Colors.grey),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ميزة إرفاق الصور والملفات')));
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: const InputDecoration(hintText: 'اكتب رسالتك هنا...', border: InputBorder.none),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send, color: Color(0xFFD4AF37)), onPressed: _sendMessage),
              ],
            ),
          )
        ],
      ),
    );
  }
}
// ----------------- مكتبة الحقوق -----------------
class LawLibraryStagesScreen extends StatefulWidget {
  const LawLibraryStagesScreen({super.key});

  @override
  State<LawLibraryStagesScreen> createState() => _LawLibraryStagesScreenState();
}

class _LawLibraryStagesScreenState extends State<LawLibraryStagesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مكتبة الحقوق - المراحل الدراسية'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: academicStagesData.keys.map((stageName) {
          final subjects = academicStagesData[stageName] ?? [];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: const Icon(Icons.school, color: Color(0xFFD4AF37)),
              title: Text(stageName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              subtitle: Text('${subjects.length} مواد دراسية'),
              children: subjects.map((subj) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  leading: const Icon(Icons.book, color: Colors.grey),
                  title: Text(subj['title'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (c) => StageSubjectDetailsScreen(subjectData: subj),
                      ),
                    );
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

class StageSubjectDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> subjectData;
  const StageSubjectDetailsScreen({super.key, required this.subjectData});

  @override
  State<StageSubjectDetailsScreen> createState() => _StageSubjectDetailsScreenState();
}

class _StageSubjectDetailsScreenState extends State<StageSubjectDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    List categories = widget.subjectData['categories'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectData['title']),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,
        itemBuilder: (context, idx) {
          final cat = categories[idx];
          List files = cat['files'] ?? [];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: const Icon(Icons.folder, color: Color(0xFFD4AF37)),
              title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${files.length} ملفات'),
              children: files.isEmpty
                  ? [const Padding(padding: EdgeInsets.all(12), child: Text('لا توجد ملفات حالياً'))]
                  : files.map<Widget>((file) {
                      return ListTile(
                        leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                        title: Text(file['fileName']),
                        trailing: IconButton(
                          icon: const Icon(Icons.download, color: Color(0xFFD4AF37)),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('جاري تحميل: ${file['fileName']}')),
                            );
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

// ----------------- شاشات الكتب والحساب -----------------
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

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي'), backgroundColor: const Color(0xFF1A1A1A), foregroundColor: Colors.white),
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
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
            onTap: () async {
              try {
                await FirebaseAuth.instance.signOut();
              } catch (_) {}
              isLoggedInGlobal = false;
              if (context.mounted) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
              }
            },
          )
        ],
      ),
    );
  }
}
