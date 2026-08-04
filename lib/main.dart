import 'dart:async';
import 'package:flutter/material.dart';

// متغيرات عامة لحفظ حالة الجلسة والبيانات
String currentUserAccountName = 'سيدعباس عقيل';
String currentUserEmail = 'abbas@law-platform.com';
bool isLoggedInGlobal = false;
bool notificationsEnabled = true;
bool isDarkMode = false; // التحكم بالوضع الداكن
List<Map<String, dynamic>> savedPostsList = [];

// قائمة الإعلانات المتحركة القابلة للإدارة
List<String> bannerAdsList = [
  '📣 إعلان هام: جدول امتحانات الكورس الأول لكلية الحقوق',
  '⚖️ خصم خاص على جميع الكتب الدراسية والمراجع في سوق الكتب',
  '📌 متاح الآن ملخصات المادة القانونية للمراحل الأربع',
];

// هيكلية المواد الدراسية للمراحل الأربع
Map<String, List<Map<String, dynamic>>> academicStagesData = {
  'المرحلة الأولى': [
    {
      'title': 'المدخل لدراسة القانون',
      'items': ['محاضرة 1 - التعريف بالقانون', 'ملخص نظرية الحق PDF']
    },
    {
      'title': 'القانون الدستوري',
      'items': ['أسئلة امتحانات سنوات سابقة']
    },
  ],
  'المرحلة الثانية': [
    {
      'title': 'القانون المدني (الالتزامات)',
      'items': ['شرح مصادر الالتزام']
    },
  ],
  'المرحلة الثالثة': [
    {
      'title': 'قانون العقوبات الخاص',
      'items': ['ملخص الجرائم الواقعة على الأشخاص']
    },
  ],
  'المرحلة الرابعة': [
    {
      'title': 'القانون الدولي الخاص',
      'items': ['مفهوم الجنسية والموطن']
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
// 2. تسجيل الدخول
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
    isLoggedInGlobal = true;
    if (_nameController.text.isNotEmpty) currentUserAccountName = _nameController.text;
    if (_emailController.text.isNotEmpty) currentUserEmail = _emailController.text;
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
              const SizedBox(height: 40),
              const Icon(Icons.gavel_rounded, size: 60, color: Color(0xFFD4AF37)),
              const SizedBox(height: 20),
              Text(isLogin ? 'تسجيل الدخول' : 'إنشاء حساب جديد', textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              if (!isLogin) ...[
                TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'اسم الحساب', border: OutlineInputBorder())),
                const SizedBox(height: 16),
              ],
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A1A1A), foregroundColor: const Color(0xFFD4AF37)),
                  onPressed: _submitAuth,
                  child: Text(isLogin ? 'دخول' : 'تسجيل'),
                ),
              ),
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

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  final List<Map<String, dynamic>> _posts = [
    {
      'id': '1',
      'author': 'عمادة كلية الحقوق',
      'title': 'تبليغ رسمي بشأن تحديث القوانين والمناهج',
      'content': 'تم نشر الجدول الجديد للتشريعات والمواد الدراسية الصادرة هذا الفصل.',
      'type': 'تبليغ رسمى',
      'likes': 15,
      'isLiked': false,
      'isPinned': true,
      'isSaved': false,
      'comments': [
        {'userName': 'سيدعقيل', 'text': 'تم الاطلاع شكراً جزيلاً'},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _startBannerTimer();
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
    super.dispose();
  }

  // نافذة إدارة الإعلانات للإدارة (إضافة، تعديل، حذف)
  void _manageAdsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final newAdCtrl = TextEditingController();
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('إدارة الإعلانات المتحركة'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                    const Text('الإعلانات الحالية:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      height: 180,
                      child: bannerAdsList.isEmpty
                          ? const Center(child: Text('لا توجد إعلانات حالياً'))
                          : ListView.builder(
                              itemCount: bannerAdsList.length,
                              itemBuilder: (context, index) => ListTile(
                                dense: true,
                                title: Text(bannerAdsList[index], style: const TextStyle(fontSize: 12)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                      onPressed: () {
                                        final editCtrl = TextEditingController(text: bannerAdsList[index]);
                                        showDialog(
                                          context: context,
                                          builder: (c) => AlertDialog(
                                            title: const Text('تعديل الإعلان'),
                                            content: TextField(controller: editCtrl),
                                            actions: [
                                              ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    bannerAdsList[index] = editCtrl.text;
                                                  });
                                                  setDialogState(() {});
                                                  Navigator.pop(c);
                                                },
                                                child: const Text('حفظ'),
                                              )
                                            ],
                                          ),
                                        );
                                      },
                                    ),
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
      body: Column(
        children: [
          if (bannerAdsList.isNotEmpty)
            Container(
              height: 55,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD4AF37)),
              ),
              child: PageView.builder(
                controller: _bannerController,
                itemCount: bannerAdsList.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(bannerAdsList[index], textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  );
                },
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(post['title'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(post['content']),
                      ],
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
}// ----------------- 2. شاشة الخدمات (مكتبة الحقوق + سوق الكتب) -----------------
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
                subtitle: const Text('تصفح المواد والمحاضرات حسب المرحلة الدراسية'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const LawLibraryStagesScreen()));
                },
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.storefront, size: 40, color: Color(0xFFD4AF37)),
                title: const Text('سوق الكتب', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: const Text('شراء وتصفح الكتب والمصادر القانونية'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قسم سوق الكتب قيد التفعيل')));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// شاشة عرض المراحل الأربع لمكتبة الحقوق
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
        content: TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'اسم المادة الدراسية')),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                setState(() {
                  academicStagesData[stageName]!.add({'title': titleCtrl.text, 'items': []});
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
              children: subjects.map((subj) {
                return ListTile(
                  title: Text(subj['title'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('المحتويات: ${subj['items'].length} ملف/محاضرة'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (c) => SubjectDetailsScreen(subjectData: subj)));
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

// تفاصيل المادة مع إمكانية إضافة المحتويات وتعديلها
class SubjectDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> subjectData;
  const SubjectDetailsScreen({super.key, required this.subjectData});

  @override
  State<SubjectDetailsScreen> createState() => _SubjectDetailsScreenState();
}

class _SubjectDetailsScreenState extends State<SubjectDetailsScreen> {
  void _addItem() {
    final itemCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('إضافة ملف/محاضرة للمادة'),
        content: TextField(controller: itemCtrl, decoration: const InputDecoration(labelText: 'اسم الملف أو الملخص')),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (itemCtrl.text.isNotEmpty) {
                setState(() {
                  widget.subjectData['items'].add(itemCtrl.text);
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
    final List items = widget.subjectData['items'];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subjectData['title']),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD4AF37),
        onPressed: _addItem,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: items.isEmpty
          ? const Center(child: Text('لا توجد محتويات أو محاضرة مضافة لهذه المادة'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, i) => ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(items[i]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      items.removeAt(i);
                    });
                  },
                ),
              ),
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
      body: const Center(child: Text('قسم رفع وتصفح الكتب المصدرية')),
    );
  }
}

// ----------------- 4. شاشة حسابي مع زر تحويل الوضع الداكن -----------------
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
            child: Text(currentUserAccountName.isNotEmpty ? currentUserAccountName[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 30, color: Color(0xFFD4AF37))),
          ),
          const SizedBox(height: 10),
          Text(currentUserAccountName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(currentUserEmail, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
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

