import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; // المكتبة المُعادة
import 'themes/app_theme.dart';
import 'routes/app_routes.dart';

// تعريف القناة عالية الأهمية لكي يرن الهاتف ويهتز
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', 
  'إشعارات هامة', 
  description: 'هذه القناة مخصصة للإشعارات الهامة والعاجلة.',
  importance: Importance.max,
  playSound: true,
);

// دالة الخلفية
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
  } catch (e) {}
  debugPrint("تم استقبال إشعار في الخلفية: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // معالجة أخطاء الواجهات
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('حدث خطأ:\n${details.exception}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
        ),
      ),
    );
  };

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
    if (!e.toString().contains('duplicate-app')) await Firebase.initializeApp();
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  try {
    await Supabase.initialize(
      url: 'https://hxtliwxlhwwrhvvgtptl.supabase.co', 
      anonKey: 'sb_publishable_GQbawy5O49Ws8JOGLJbonQ_hMjMAfJs', 
    );
  } catch (e) {}

  runApp(const LawPlatformApp());
}

class LawPlatformApp extends StatefulWidget {
  const LawPlatformApp({super.key});

  @override
  State<LawPlatformApp> createState() => _LawPlatformAppState();
}

class _LawPlatformAppState extends State<LawPlatformApp> {
  
  @override
  void initState() {
    super.initState();
    _setupNotifications(); // تشغيل الإشعارات بعد رسم الواجهة
  }

  Future<void> _setupNotifications() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      
      // 1. طلب الصلاحية (لن يسبب شاشة سوداء هنا)
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      // 2. إنشاء القناة في الأندرويد
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      const AndroidInitializationSettings initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(android: initSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(initSettings);

      // 3. عرض الإشعار المنبثق والتطبيق مفتوح
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id, channel.name,
                channelDescription: channel.description,
                importance: Importance.max,
                priority: Priority.high,
                icon: '@mipmap/ic_launcher',
              ),
            ),
          );
        }
      });

      // 4. الاشتراك في الإشعارات العامة
      await messaging.subscribeToTopic('official_announcements');

      // 5. تحديث توكن المستخدم في قاعدة البيانات (مهم جداً جداً لرسائل السوق)
      String? token = await messaging.getToken();
      if (token != null) {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({'fcmToken': token}, SetOptions(merge: true));
        }
      }
      
    } catch (e) {
      debugPrint('Notification Setup Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منصة القانون',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      
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
