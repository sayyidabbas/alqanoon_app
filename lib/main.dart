import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const LawPlatformApp());
}

class LawPlatformApp extends StatelessWidget {
  const LawPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'منصة القانون',
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Cairo',
        scaffoldBackgroundColor: const Color(0xff05070D),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
