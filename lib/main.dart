import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'themes/app_theme.dart';
import 'routes/app_routes.dart';

// دالة الخلفية: تعمل والتطبيق مغلق بالكامل
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAGhu0qYt7SJqgvEOEfkh0eKnnotMnv1d0",
        appId: "1:521454530754:android:9ede6222cad2fcabb08b5b",
        messagingSenderId: "521454530754",
        projectId: "law-platform-55632",
        storageBucket: "law-platform-55632.firebasestorage.app",
      ),
    );
  } catch (e) {
    debugPrint('Firebase Background Init Error: $e');
  }
  debugPrint("تم استقبال إشعار في الخلفية: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // معالجة أخطاء الواجهات لمنع الشاشة السوداء
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'حدث خطأ في الواجهة:\n${details.exception}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      ),
    );
  };

  // تهيئة الفايربيس
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAGhu0qYt7SJqgvEOEfkh0eKnnotMnv1d0",
        appId: "1:521454530754:android:9ede6222cad2fcabb08b5b",
        messagingSenderId: "521454530754",
        projectId: "law-platform-55632",
        storageBucket: "law-platform-55632.firebasestorage.app",
      ),
    );
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      await Firebase.initializeApp();
    }
  }

  // تسجيل دالة الخلفية مبكراً (لا تسبب شاشة سوداء)
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // تهيئة Supabase
  try {
    await Supabase.initialize(
      url: 'https://hxtliwxlhwwrhvvgtptl.supabase.co', 
      anonKey: 'sb_publishable_GQbawy5O49Ws8JOGLJbonQ_hMjMAfJs', 
    );
  } catch (e) {
    debugPrint('Supabase Init Error: $e');
  }

  // 1. تشغيل واجهة التطبيق أولاً (هذا يمنع الشاشة السوداء نهائياً)
  runApp(const LawPlatformApp());

  // 2. طلب صلاحيات الإشعارات بعد أن يتم رسم التطبيق
  _requestNotificationPermission();
}

// دالة منفصلة لطلب الصلاحيات والاشتراك في الإشعارات
Future<void> _requestNotificationPermission() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('تم استقبال إشعار والتطبيق مفتوح: ${message.notification?.title}');
    });

    await FirebaseMessaging.instance.subscribeToTopic('official_announcements');
  } catch (e) {
    debugPrint('Firebase Messaging Error: $e');
  }
}

class LawPlatformApp extends StatelessWidget {
  const LawPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منصة القانون',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      
      // إعدادات اللغة العربية ودعم RTL
      locale: const Locale('ar', 'IQ'),
      supportedLocales: const [Locale('ar', 'IQ')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}
