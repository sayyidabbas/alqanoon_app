import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/services_screen.dart';
import 'screens/profile_screen.dart';

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

// متغيرات المستخدم الحية والمحدثة لحظياً
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
        useMaterial3: true,
      ),
      home: const MainNavigationHolder(),
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
  void initState() {
    super.initState();
    _loadAdminSession();
  }

  // استرجاع جلسة الأدمن المحفوظة سابقاً
  Future<void> _loadAdminSession() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool savedAdminStatus = prefs.getBool('is_admin_logged_in') ?? false;
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      currentUserId = user.uid;
      currentUserEmail = user.email ?? '';
    }
    setState(() {
      isCurrentUserAdmin = savedAdminStatus;
    });
  }

  @override
  Widget build(BuildContext context) {
    // الاستماع المباشر لبيانات المستخدم لتحديثها لحظياً
    return StreamBuilder<DocumentSnapshot>(
      stream: currentUserId.isNotEmpty
          ? FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots()
          : null,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          currentUserAccountName = data['name'] ?? currentUserAccountName;
          currentUsername = data['username'] ?? currentUsername;
          currentUserCollege = data['college'] ?? currentUserCollege;
          currentUserPhotoUrl = data['photoUrl'] ?? currentUserPhotoUrl;
        }

        List<Widget> screens = [
          HomeScreen(currentUserAccountName: currentUserAccountName, isAdmin: isCurrentUserAdmin),
          ServicesScreen(currentUserAccountName: currentUserAccountName),
          ProfileScreen(
            onLogout: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('is_admin_logged_in');
              await FirebaseAuth.instance.signOut();
              setState(() {
                isCurrentUserAdmin = false;
              });
            },
          ),
        ];

        return Scaffold(
          body: screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            backgroundColor: const Color(0xFF121216),
            selectedItemColor: const Color(0xFFD4AF37),
            unselectedItemColor: Colors.grey,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'الرئيسية'),
              BottomNavigationBarItem(icon: Icon(Icons.gavel_rounded), label: 'الخدمات'),
              BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'حسابي'),
            ],
          ),
        );
      },
    );
  }
}
