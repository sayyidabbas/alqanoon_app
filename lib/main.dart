import 'dart0:async';
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

// قائمة الأحداث والعداد التنازلي القابلة للإدارة
List<Map<String, dynamic>> countdownEventsList = [
  {'title': 'امتحانات الكورس الأول', 'days': 12, 'icon': Icons.hourglass_top},
  {'title': 'المحاكمة الصورية', 'days': 5, 'icon': Icons.gavel},
];

// قائمة الحكم والمواد القانونية القابلة للإدارة
List<String> legalQuotesList = [
  '« لا جَرِيمَةَ وَلا عُقُوبَةَ إِلاّ بِنَصٍّ »',
  '« العقد شريعة المتعاقدين »',
  '« المتهم بيء حتى تثبت إدانته »',
];
int currentQuoteIndex = 0;

// بيانات جدول المحاضرات الأسبوعي القابل للإدارة
Map<String, List<Map<String, String>>> weeklyScheduleData = {
  'الأحد': [
    {'subject': 'المدخل لدراسة القانون', 'time': '08:30 ص - 10:30 ص', 'hall': 'القاعة 1', 'professor': 'أ.د. علي الحسيني'},
    {'subject': 'القانون الدستوري', 'time': '10:45 ص - 12:45 م', 'hall': 'المدرج الكبير', 'professor': 'د. خليل إبراهيم'},
  ],
  'الإثنين': [
    {'subject': 'القانون المدني (التزامات)', 'time': '09:00 ص - 11:00 ص', 'hall': 'القاعة 3', 'professor': 'د. أسامة محمود'},
  ],
  'الثلاثاء': [
    {'subject': 'قانون العقوبات العام', 'time': '08:30 ص - 10:30 ص', 'hall': 'القاعة 2', 'professor': 'أ.د. حسن فاضل'},
  ],
  'الأربعاء': [
    {'subject': 'القانون الدولي العام', 'time': '11:00 ص - 01:00 م', 'hall': 'المدرج A', 'professor': 'د. زينب عبد السلام'},
  ],
  'الخميس': [
    {'subject': 'التطبيق القضائي والمحاكمة الصورية', 'time': '10:00 ص - 12:00 م', 'hall': 'قاعة المحاكمة الصورية', 'professor': 'القاضي أحمد سالم'},
  ],
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
  String _selectedCategoryFilter = 'الكل';

  final List<Map<String, dynamic>> _posts = [
    {
      'id': '1',
      'author': 'عمادة كلية الحقوق',
      'title': 'تبليغ رسمي بشأن تحديث القوانين والمناهج',
      'content': 'تم نشر الجدول الجديد للتشريعات والمواد الدراسية الصادرة هذا الفصل.',
      'type': 'تبليغ رسمى',
      'timeAgo': 'منذ ساعتين',
      'isNew': true,
      'imagePath': null,
      'likes': 12,
      'isLiked': false,
      'isPinned': true,
      'isSaved': false,
      'comments': [
        {'userName': 'سيدعقيل', 'text': 'تم الاطلاع، شكراً جزيلاً.'},
      ],
    },
    {
      'id': '2',
      'author': 'قسم الإعلانات',
      'title': 'جدول الامتحانات النهائية',
      'content': 'يرجى الاطلاع على الجدول المرفق للامتحانات.',
      'type': 'جداول الامتحانات',
      'timeAgo': 'أمس',
      'isNew': false,
      'imagePath': 'demo_schedule_image',
      'likes': 25,
      'isLiked': true,
      'isPinned': false,
      'isSaved': true,
      'comments': [],
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
                    onPressed: () {
                      if (titleController.text.isNotEmpty) {
                        setState(() {
                          _posts.insert(0, {
                            'id': DateTime.now().millisecondsSinceEpoch.toString(),
                            'author': currentUserAccountName,
                            'title': titleController.text,
                            'content': contentController.text,
                            'type': selectedType,
                            'timeAgo': 'الآن',
                            'isNew': true,
                            'imagePath': attachedImagePath,
                            'likes': 0,
                            'isLiked': false,
                            'isPinned': false,
                            'isSaved': false,
                            'comments': [],
                          });
                        });
                        Navigator.pop(context);
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
                    Container(
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
                    Container(
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
    List<Map<String, dynamic>> filteredPosts = _selectedCategoryFilter == 'الكل'
        ? _posts
        : _posts.where((p) => p['type'] == _selectedCategoryFilter).toList();

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
              // 1. حكمة اليوم القانونية
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

              // 2. شريط الأحداث العداد التنازلي
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

              // 3. أزرار التصفية الفئات (Filter Chips)
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

              // 4. عرض قائمة المنشورات
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredPosts.length,
                  itemBuilder: (context, index) {
                    final post = filteredPosts[index];
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
                                    Row(
                                      children: [
                                        Text(post['timeAgo'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
                                IconButton(
                                  icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? const Color(0xFFD4AF37) : Colors.grey),
                                  onPressed: () => _toggleSave(index),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      final titleCtrl = TextEditingController(text: post['title']);
                                      final contentCtrl = TextEditingController(text: post['content']);
                                      showDialog(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text('تعديل المنشور'),
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
                                                setState(() {
                                                  post['title'] = titleCtrl.text;
                                                  post['content'] = contentCtrl.text;
                                                });
                                                Navigator.pop(c);
                                              },
                                              child: const Text('حفظ'),
                                            )
                                          ],
                                        ),
                                      );
                                    }
                                    if (val == 'delete') {
                                      setState(() {
                                        _posts.removeWhere((p) => p['id'] == post['id']);
                                      });
                                    }
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// ==========================================
// 4. شاشة الخدمات والكلية المحدثة بالكامل
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
          // 1. كارت مكتبة الحقوق
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

          // 2. كارت جدول المحاضرات الأسبوعي
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const Icon(Icons.calendar_month, size: 40, color: Colors.blue),
              title: const Text('جدول المحاضرات الأسبوعي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: const Text('متابعة أوقات المحاضرات والقاعات والأستاذ'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (c) => const WeeklyScheduleScreen()));
              },
            ),
          ),
          const SizedBox(height: 12),

          // 3. كارت منتدى الطلبة والدردشة
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

// ----------------- شاشة جدول المحاضرات الأسبوعي -----------------
class WeeklyScheduleScreen extends StatefulWidget {
  const WeeklyScheduleScreen({super.key});

  @override
  State<WeeklyScheduleScreen> createState() => _WeeklyScheduleScreenState();
}

class _WeeklyScheduleScreenState extends State<WeeklyScheduleScreen> {
  String selectedDay = 'الأحد';

  void _addLectureDialog() {
    final subjCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final hallCtrl = TextEditingController();
    final profCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('إضافة محاضرة يوم $selectedDay'),
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
                  weeklyScheduleData[selectedDay]!.add({
                    'subject': subjCtrl.text,
                    'time': timeCtrl.text,
                    'hall': hallCtrl.text,
                    'professor': profCtrl.text,
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

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> currentDayLectures = weeklyScheduleData[selectedDay] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('جدول المحاضرات الأسبوعي'),
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
            height: 60,
            color: const Color(0xFF1A1A1A),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس'].map((day) {
                bool isSelected = selectedDay == day;
                return GestureDetector(
                  onTap: () => setState(() => selectedDay = day),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(day, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: currentDayLectures.isEmpty
                ? const Center(child: Text('لا توجد محاضرات في هذا اليوم'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: currentDayLectures.length,
                    itemBuilder: (context, idx) {
                      final lec = currentDayLectures[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Color(0xFF1A1A1A), child: Icon(Icons.menu_book, color: Color(0xFFD4AF37))),
                          title: Text(lec['subject']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('⏰ ${lec['time']} | 📍 ${lec['hall']}\n👨‍🏫 ${lec['professor']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () {
                              setState(() {
                                weeklyScheduleData[selectedDay]!.removeAt(idx);
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
// ----------------- شاشة منتدى الطلبة والدردشة -----------------
class StudentForumScreen extends StatefulWidget {
  const StudentForumScreen({super.key});

  @override
  State<StudentForumScreen> createState() => _StudentForumScreenState();
}

class _StudentForumScreenState extends State<StudentForumScreen> {
  String activeChannel = '📢 الدردشة العامة';
  Map<String, dynamic>? replyToMessage;
  final TextEditingController _chatController = TextEditingController();

  Map<String, List<Map<String, dynamic>>> forumChannelsMessages = {
    '📢 الدردشة العامة': [
      {'sender': 'علي أحمد', 'text': 'السلام عليكم زملاء، متى تبدأ محاضرة اليوم؟', 'time': '10:15 ص', 'replyTo': null},
    ],
    '📚 تبادل الملازم': [
      {'sender': 'سارة عمر', 'text': 'تم رفع ملخص المادة المدنية في مكتبة الحقوق.', 'time': '09:30 ص', 'replyTo': null},
    ],
    '❓ سؤال وجواب': [
      {'sender': 'حسين خليل', 'text': 'ما الفرق بين القصد الجنائي العام والخاص؟', 'time': 'أمس', 'replyTo': null},
    ],
  };

  void _sendMessage() {
    if (_chatController.text.trim().isNotEmpty) {
      setState(() {
        forumChannelsMessages[activeChannel]!.add({
          'sender': currentUserAccountName,
          'text': _chatController.text.trim(),
          'time': 'الآن',
          'replyTo': replyToMessage != null ? replyToMessage!['text'] : null,
        });
        _chatController.clear();
        replyToMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> messages = forumChannelsMessages[activeChannel] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(activeChannel),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // شريط اختيار الغرف
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
                    label: Text(ch, style: TextStyle(fontSize: 12, color: isSel ? Colors.black : Colors.grey)),
                    selected: isSel,
                    selectedColor: const Color(0xFFD4AF37),
                    onSelected: (val) => setState(() => activeChannel = ch),
                  ),
                );
              }).toList(),
            ),
          ),

          // قائمة الرسائل
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, idx) {
                final msg = messages[idx];
                bool isMe = msg['sender'] == currentUserAccountName;

                return Dismissible(
                  key: UniqueKey(),
                  direction: DismissDirection.startToEnd,
                  onDismissed: (_) {
                    setState(() {
                      replyToMessage = msg;
                    });
                  },
                  child: Align(
                    alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe ? const Color(0xFFD4AF37) : const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(msg['sender'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isMe ? Colors.black : Colors.amber)),
                          if (msg['replyTo'] != null) ...[
                            Container(
                              padding: const EdgeInsets.all(4),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
                              child: Text('رد على: ${msg['replyTo']}', style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
                            )
                          ],
                          Text(msg['text'], style: TextStyle(color: isMe ? Colors.black : Colors.white)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // شريط إدخال الرسالة وسحب الرد
          if (replyToMessage != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.amber.shade100,
              child: Row(
                children: [
                  Expanded(child: Text('جاري الرد على: ${replyToMessage!['text']}', style: const TextStyle(fontSize: 12, color: Colors.black))),
                  IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => replyToMessage = null)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(child: TextField(controller: _chatController, decoration: const InputDecoration(hintText: 'اكتب رسالة...', border: InputBorder.none))),
                IconButton(icon: const Icon(Icons.send, color: Color(0xFFD4AF37)), onPressed: _sendMessage),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ----------------- مكتبة الكتب والملف الشخصي -----------------
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
