import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'themes/app_theme.dart';
import 'routes/app_routes.dart';

// دالة الخلفية: تعمل والتطبيق مغلق بالكامل لاستقبال الإشعارات
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

  // تهيئة الفايربيس المباشرة بالبيانات الخاصة بمشروعك
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

  // 1. تسجيل دالة الخلفية مبكراً
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // تهيئة Supabase بالرابط والمفتاح الخاصين بمشروعك
  try {
    await Supabase.initialize(
      url: 'https://hxtliwxlhwwrhvvgtptl.supabase.co', 
      anonKey: 'sb_publishable_GQbawy5O49Ws8JOGLJbonQ_hMjMAfJs', 
    );
  } catch (e) {
    debugPrint('Supabase Init Error: $e');
  }

  // تشغيل التطبيق فقط (بدون أي استدعاءات تعيق الشاشة)
  runApp(const LawPlatformApp());
}

// تم تحويل LawPlatformApp إلى StatefulWidget لنتمكن من استخدام initState
class LawPlatformApp extends StatefulWidget {
  const LawPlatformApp({super.key});

  @override
  State<LawPlatformApp> createState() => _LawPlatformAppState();
}

class _LawPlatformAppState extends State<LawPlatformApp> {
  
  @override
  void initState() {
    super.initState();
    // 2. طلب صلاحيات الإشعارات هنا يضمن أن التطبيق قد فتح فعلياً ولن تظهر شاشة سوداء
    _requestNotificationPermission();
  }

  // دالة طلب الإشعارات
  Future<void> _requestNotificationPermission() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      
      // طلب الصلاحية من المستخدم (تظهر كرسالة منبثقة في أندرويد 13+)
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // الاستماع للإشعارات والتطبيق مفتوح (Foreground)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('تم استقبال إشعار والتطبيق مفتوح: ${message.notification?.title}');
      });

      // الاشتراك في موضوع (Topic) مخصص للتبليغات الرسمية
      await FirebaseMessaging.instance.subscribeToTopic('official_announcements');
      
    } catch (e) {
      debugPrint('Firebase Messaging Error: $e');
    }
  }

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
