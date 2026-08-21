import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../services_screens/legal_library_screen.dart';
import '../services_screens/study_materials_screen.dart';
import '../services_screens/question_bank_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String legalLibrary = '/legal_library';
  static const String studyMaterials = '/study_materials';
  static const String questionBank = '/question_bank';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    home: (context) => const HomeScreen(),
    legalLibrary: (context) => const LegalLibraryScreen(),
    studyMaterials: (context) => const StudyMaterialsScreen(),
    questionBank: (context) => const QuestionBankScreen(),
  };
}
