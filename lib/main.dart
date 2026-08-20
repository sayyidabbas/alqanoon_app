import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User; 
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:flutter_local_notifications/flutter_local_notifications.dart'; 
import 'themes/app_theme.dart';
import 'routes/app_routes.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', 
  'إشعارات هامة', 
  description: 'هذه القناة مخصصة للإشعارات الهامة والعاجلة.',
  importance: Importance.max,
  playSound: true,
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // الاعتماد الكامل على ملف google-services.json الرسمي لضمان استقرار قاعدة البيانات
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Background Init Error: $e');
  }
  debugPrint("تم استقبال إشعار في الخلفية: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // 🔥 التهيئة الرسمية والآمنة (قمنا بإزالة المفاتيح اليدوية لمنع تعارض قاعدة البيانات وتوقف الأقسام)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(); 
    }
  } catch (e) {
    debugPrint('Firebase Init Error: $e');
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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

class LawPlatformApp extends StatefulWidget {
  const LawPlatformApp({super.key});

  @override
  State<LawPlatformApp> createState() => _LawPlatformAppState();
}

class _LawPlatformAppState extends State<LawPlatformApp> {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupNotifications(); 
    });
  }

  Future<void> _setupNotifications() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      const AndroidInitializationSettings initSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initSettings = InitializationSettings(android: initSettingsAndroid);
      await flutterLocalNotificationsPlugin.initialize(initSettings);

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

      await messaging.subscribeToTopic('official_announcements');

      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user != null) {
          String? token = await messaging.getToken();
          if (token != null) {
            await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'fcmToken': token}, SetOptions(merge: true));
          }
        }
      });

      messaging.onTokenRefresh.listen((String token) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'fcmToken': token}, SetOptions(merge: true));
        }
      });
      
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
