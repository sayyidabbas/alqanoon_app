import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // 1. دالة حساب التوقيت الزمني للإشعار
  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return 'الآن';
    final diff = DateTime.now().difference(timestamp.toDate());
    
    if (diff.inSeconds < 60) return 'منذ ثواني';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return 'منذ ${diff.inDays ~/ 7} أسبوع';
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('الإشعارات', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: uid.isEmpty
          ? const Center(
              child: Text('يرجى تسجيل الدخول لرؤية الإشعارات', style: TextStyle(color: Colors.white)),
            )
          : Center(
              child: Text('لا توجد إشعارات حالياً', style: TextStyle(color: Colors.white54)),
            ),
    );
  }
}
