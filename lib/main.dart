import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // المكتبة الجديدة للإشعارات
import 'themes/app_theme.dart';
import 'routes/app_routes.dart';

// تعريف الـ Plugin الخاص بالإشعارات المحلية
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// تعريف قناة الإشعارات ذات الأهمية القصوى للأندرويد لكي يرن ويهتز
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // هذا هو نفس المعرف (ID) الذي وضعناه في AndroidManifest.xml
  'إشعارات هامة', // اسم القناة الذي يظهر للمستخدم في إعدادات الهاتف
  description: 'هذه القناة مخصصة للإشعارات الهامة والعاجلة.',
  importance: Importance.max,
  playSound: true,
);

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

  // التأكد من تهيئة الإشعارات في الخلفية
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

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

  // إعدادات الإشعارات الخارجية (Push Notifications)
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    
    // طلب الصلاحية من المستخدم (إجباري في أندرويد 13+)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // إنشاء وتفعيل قناة الإشعارات في الأندرويد
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // إعدادات التهيئة للإشعارات المحلية
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // 1. تسجيل دالة الخلفية (التطبيق مغلق)
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. الاستماع للإشعارات والتطبيق مفتوح (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('تم استقبال إشعار والتطبيق مفتوح: ${message.notification?.title}');
      
      // عرض الإشعار المنبثق (Heads-up) عندما يكون التطبيق مفتوحاً
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    // الاشتراك في موضوع (Topic) مخصص للتبليغات الرسمية لكي يستلمها الجميع دفعة واحدة
    await FirebaseMessaging.instance.subscribeToTopic('official_announcements');
    
  } catch (e) {
    debugPrint('Firebase Messaging Error: $e');
  }

  // تهيئة Supabase بالرابط والمفتاح الخاصين بمشروعك
  try {
    await Supabase.initialize(
      url: 'https://hxtliwxlhwwrhvvgtptl.supabase.co', 
      anonKey: 'sb_publishable_GQbawy5O49Ws8JOGLJbonQ_hMjMAfJs', 
    );
  } catch (e) {
    debugPrint('Supabase Init Error: $e');
  }

  runApp(const LawPlatformApp());
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
