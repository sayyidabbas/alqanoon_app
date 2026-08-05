import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/services_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/auth_screen.dart';

// ==========================================
// إعدادات Firebase السحابية
// ==========================================
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBOT5lAEyYCOGBteudtWvXwydJ0PG7MWJ8',
    appId: '1:4493934795:android:6f73ac530179d429cfdb4e',
    messagingSenderId: '449394795',
    projectId: 'alqanoon-302c7',
    storageBucket: 'alqanoon-302c7.firebasestorage.app',
  );
}

String currentUserAccountName = 'سيدعباس عقيل';
String currentUserEmail = 'abbas@law-platform.com';
String currentUserUniversity = 'جامعة الموصل';
String currentUserCollege = 'كلية الحقوق';
bool isLoggedInGlobal = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منصة القانون - كلية الحقوق',
      debugShowCheckedModeBanner: false,
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
      home: const SplashScreen(),
    );
  }
}

// ==========================================
// الواجهة الترحيبية الفخمة والمتحركة
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    Timer(const Duration(milliseconds: 3500), () {
      if (mounted) {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          isLoggedInGlobal = true;
          currentUserEmail = user.email ?? currentUserEmail;
          currentUserAccountName = (user.displayName != null && user.displayName!.isNotEmpty)
              ? user.displayName!
              : currentUserAccountName;
        }

        Widget target = isLoggedInGlobal
            ? const MainNavigationHolder()
            : AuthScreen(
                onAuthSuccess: (name, email) {
                  isLoggedInGlobal = true;
                  currentUserAccountName = name.isEmpty ? 'سيدعباس عقيل' : name;
                  currentUserEmail = email;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainNavigationHolder()),
                  );
                },
              );

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => target));
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A), Color(0xFF000000)],
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
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1A1A1A),
                      border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.25),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.balance_rounded,
                      size: 85,
                      color: Color(0xFFD4AF37),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 35),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    const Text(
                      'أهلاً بكم في',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'منصة القانون',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD4AF37),
                        letterSpacing: 1.5,
                        shadows: [
                          Shadow(
                            color: Colors.black54,
                            offset: Offset(0, 3),
                            blurRadius: 8,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
                      ),
                      child: const Text(
                        'سيدعباس عقيل الحسيني',
                        style: TextStyle(
                          fontSize: 15,
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
// شريط التنقل السفلي والتحكم بالشاشات
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
      StudentForumScreen(currentUserAccountName: currentUserAccountName),
      ServicesScreen(currentUserAccountName: currentUserAccountName),
      ProfileScreen(
        currentUserAccountName: currentUserAccountName,
        currentUserEmail: currentUserEmail,
        currentUserUniversity: currentUserUniversity,
        currentUserCollege: currentUserCollege,
        onLogout: () async {
          await FirebaseAuth.instance.signOut();
          isLoggedInGlobal = false;
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AuthScreen(
                  onAuthSuccess: (name, email) {
                    isLoggedInGlobal = true;
                    currentUserAccountName = name.isEmpty ? 'سيدعباس عقيل' : name;
                    currentUserEmail = email;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainNavigationHolder()),
                    );
                  },
                ),
              ),
            );
          }
        },
      ),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.forum), label: 'الدردشة'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'الخدمات'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }
}
