import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart'; // <--- إضافة استيراد الفايربيس
import 'themes/app_theme.dart';
import 'routes/app_routes.dart';

void main() async { // <--- إضافة async
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة الفايربيس سحابياً
  await Firebase.initializeApp();

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
