import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StudyMaterialsScreen extends StatelessWidget {
  const StudyMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('المواد الدراسية'),
        backgroundColor: AppColors.primary,
      ),
      body: const Center(
        child: Text(
          'محتوى المواد الدراسية قريباً...',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }
}
