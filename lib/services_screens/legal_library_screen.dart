import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class LegalLibraryScreen extends StatelessWidget {
  const LegalLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('المكتبة القانونية'),
        backgroundColor: AppColors.primary,
      ),
      body: const Center(
        child: Text(
          'محتوى المكتبة القانونية قريباً...',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }
}
