import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
// تم إضافة هذا الاستيراد للوصول إلى شاشة ملف المستخدم في السوق
import '../services_screens/electronic_exams_screen.dart';

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

  // 2. دالة التوجيه عند الضغط على الإشعار
  void _handleNotificationTap(BuildContext context, Map<String, dynamic> data) {
    // نعتمد على عنوان الإشعار لمعرفة نوعه وتوجيهه للمكان الصحيح
    final String title = data['title'] ?? ''; 
    
    // إذا كان الإشعار يخص السوق (بيع، شراء، موافقة إدارة، رفض) 
    // نوجه المستخدم فوراً إلى شاشة (ملفي في السوق)
    if (title.contains('تأكيد البيع') || 
        title.contains('الموافقة') || 
        title.contains('الرفض') || 
        title.contains('شراء جديد')) {
      
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UserMarketProfileScreen()),
      );
      debugPrint('تم الانتقال إلى شاشة ملفي في السوق');
    } else {
      debugPrint('إشعار عام - لا يوجد توجيه مخصص');
    }
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
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('market_notifications')
                  .where('userId', isEqualTo: uid)
                  // تم التعديل إلى createdAt ليتطابق مع قاعدة بياناتك
                  .orderBy('createdAt', descending: true) 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      'حدث خطأ أثناء جلب الإشعارات\n(ملاحظة: تحتاج لإنشاء Index في Firebase)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('لا توجد إشعارات حالياً', style: TextStyle(color: Colors.white54)),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    bool isRead = data['isRead'] ?? false;
                    
                    // استخراج وقت الإشعار من البيانات (createdAt)
                    Timestamp? timestamp = data['createdAt'] as Timestamp?;

                    return Card(
                      color: isRead ? AppColors.cardBg : AppColors.cardBg.withOpacity(0.6),
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: Icon(
                          isRead ? Icons.notifications_none : Icons.notifications_active,
                          color: isRead ? Colors.white54 : AppColors.accent,
                        ),
                        title: Text(
                          data['title'] ?? 'إشعار جديد',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              data['body'] ?? '',
                              textAlign: TextAlign.right,
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 6),
                            // عرض الوقت الزمني هنا
                            Text(
                              _getTimeAgo(timestamp),
                              style: const TextStyle(color: AppColors.accent, fontSize: 11),
                            ),
                          ],
                        ),
                        onTap: () {
                          // 1. تحويل الإشعار لمقروء
                          if (!isRead) {
                            doc.reference.update({'isRead': true});
                          }
                          // 2. توجيه المستخدم
                          _handleNotificationTap(context, data);
                        },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
