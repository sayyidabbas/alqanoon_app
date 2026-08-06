import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/services_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth_screen.dart';

// ==========================================
// إعدادات Firebase السحابية المعتمدة
// ==========================================
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBOT5lAEyYCOGBteudtWvXwydJ0PG7MWJ8',
    appId: '1:4493934795:android:6f73ac530179d429cfdb4e',
    messagingSenderId: '449394795',
    projectId: 'alqanoon-302c7',
    storageBucket: 'alqanoon-302c7.firebasestorage.app',
  );
}

// متغيرة الحالة العامة للمستخدم
String currentUserAccountName = 'سيدعباس عقيل الحسيني';
String currentUserEmail = '';
String currentUserUniversity = 'جامعة الموصل';
String currentUserCollege = 'كلية الحقوق';
bool isCurrentUserAdmin = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تثبيت الاتجاه الرأسي للشاشة وضبط شريط النظارات
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  runApp(const AlQanoonApp());
}

class AlQanoonApp extends StatelessWidget {
  const AlQanoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منصة القانون - كلية الحقوق',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F12),
        primaryColor: const Color(0xFFD4AF37),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFFD4AF37),
          primary: const Color(0xFFD4AF37),
          secondary: const Color(0xFF1E1E24),
          surface: const Color(0xFF16161C),
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// ==========================================
// شاشة الترحيب الاحترافية (Splash Screen)
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _checkAuthenticationAndRoles();
  }

  Future<void> _checkAuthenticationAndRoles() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserEmail = user.email ?? '';
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          currentUserAccountName = data['name'] ?? user.displayName ?? 'طالب قانون';
          currentUserUniversity = data['university'] ?? 'جامعة الموصل';
          currentUserCollege = data['college'] ?? 'كلية الحقوق';
          
          // التثبيت التلقائي لصلاحية الأدمن للإيميل المعتمد أو عبر الفيلد role
          String role = (data['role'] ?? '').toString().toLowerCase();
          if (role == 'admin' || currentUserEmail == 'hasnaqeel3@gmail.com') {
            isCurrentUserAdmin = true;
          }
        }
      } catch (e) {
        debugPrint("Error fetching user role: $e");
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationHolder()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF09090C), Color(0xFF141419), Color(0xFF050507)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF16161C),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.2),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.balance_rounded,
                      size: 90,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Text(
                      'المملكة القانونية',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white54,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'منصة القانون',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4AF37),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
                      ),
                      child: const Text(
                        'جامعة الموصل - كلية الحقوق',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ),
                  ],
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
// حامل الشاشات وشريط التنقل الرئيسي
// ==========================================
class MainNavigationHolder extends StatefulWidget {
  const MainNavigationHolder({super.key});

  @override
  State<MainNavigationHolder> createState() => _MainNavigationHolderState();
}

class _MainNavigationHolderState extends State<MainNavigationHolder> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    List<Widget> screens = [
      HomeScreen(currentUserAccountName: currentUserAccountName),
      StudentForumScreen(
        currentUserAccountName: currentUserAccountName,
        isAdmin: isCurrentUserAdmin,
      ),
      ServicesScreen(currentUserAccountName: currentUserAccountName),
      ProfileScreen(
        currentUserAccountName: currentUserAccountName,
        currentUserEmail: currentUserEmail,
        currentUserUniversity: currentUserUniversity,
        currentUserCollege: currentUserCollege,
        isAdmin: isCurrentUserAdmin,
        onLogout: () async {
          await FirebaseAuth.instance.signOut();
          isCurrentUserAdmin = false;
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AuthScreen()),
            );
          }
        },
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: const Color(0xFF121216),
          selectedItemColor: const Color(0xFFD4AF37),
          unselectedItemColor: Colors.grey.shade600,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.forum_rounded), label: 'الدردشة'),
            BottomNavigationBarItem(icon: Icon(Icons.gavel_rounded), label: 'الخدمات'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}
