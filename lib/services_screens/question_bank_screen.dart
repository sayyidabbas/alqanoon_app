import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class QuestionBankScreen extends StatelessWidget {
  const QuestionBankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('بنك الأسئلة'),
        backgroundColor: AppColors.primary,
      ),
      body: const Center(
        child: Text(
          'محتوى بنك الأسئلة قريباً...',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }
}
