import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ElectronicExamsScreen extends StatelessWidget {
  const ElectronicExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('الاختبارات الإلكترونية'),
        backgroundColor: AppColors.primary,
      ),
      body: const Center(
        child: Text(
          'محتوى الاختبارات الإلكترونية قريباً...',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }
}
