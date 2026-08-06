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

// بيانات المستخدم العامة
String currentUserId = '';
String currentUserAccountName = 'طالب قانون';
String currentUsername = 'user';
String currentUserEmail = '';
String currentUserUniversity = 'جامعة الموصل';
String currentUserCollege = 'كلية الحقوق';
String currentUserPhotoUrl = '';
bool isCurrentUserAdmin = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'منصة القانون',
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
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
      currentUserEmail = user.email ?? '';

      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
          currentUserAccountName = data['name'] ?? 'طالب قانون';
          currentUsername = data['username'] ?? 'user';
          currentUserUniversity = data['university'] ?? 'جامعة الموصل';
          currentUserCollege = data['college'] ?? 'كلية الحقوق';
          currentUserPhotoUrl = data['photoUrl'] ?? '';
          isCurrentUserAdmin = (data['role'] ?? '') == 'admin' || currentUsername == 'x9.ta9';
        }
      } catch (e) {
        debugPrint("Error loading user: $e");
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
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.balance_rounded, size: 90, color: Color(0xFFD4AF37)),
            SizedBox(height: 20),
            Text('منصة القانون', style: TextStyle(fontSize: 30, color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

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
      HomeScreen(currentUserAccountName: currentUserAccountName, isAdmin: isCurrentUserAdmin),
      StudentForumScreen(currentUserAccountName: currentUserAccountName, isAdmin: isCurrentUserAdmin),
      ServicesScreen(currentUserAccountName: currentUserAccountName),
      ProfileScreen(
        onLogout: () async {
          await FirebaseAuth.instance.signOut();
          isCurrentUserAdmin = false;
          if (context.mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AuthScreen()));
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
        backgroundColor: const Color(0xFF121216),
        selectedItemColor: const Color(0xFFD4AF37),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.forum_rounded), label: 'الدردشة'),
          BottomNavigationBarItem(icon: Icon(Icons.gavel_rounded), label: 'الخدمات'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'حسابي'),
        ],
      ),
    );
  }
}
