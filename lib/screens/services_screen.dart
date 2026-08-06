import 'package:flutter/material.dart';

class ServicesScreen extends StatelessWidget {
  final String currentUserAccountName;

  const ServicesScreen({super.key, required this.currentUserAccountName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الخدمات الطلابية', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF121216),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildServiceTile(context, 'طلب كتاب تأييد', 'استخراج تأييد استمرار بالدراسة', Icons.description_outlined),
          _buildServiceTile(context, 'النتائج الامتحانية', 'الاستعلام عن نتائج الفصل الدراسي', Icons.grade_outlined),
          _buildServiceTile(context, 'المحاكم الافتراضية', 'التسجيل في جلسات المحاكاة القانونية', Icons.balance_outlined),
        ],
      ),
    );
  }

  Widget _buildServiceTile(BuildContext context, String title, String subtitle, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF16161C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFD4AF37)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF16161C),
              title: Text(title, style: const TextStyle(color: Color(0xFFD4AF37))),
              content: Text('تم فتح طلبك لخدمة "$title" بنجاح، جاري معالجة الطلب في الكلية.', style: const TextStyle(color: Colors.white)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('حسناً', style: TextStyle(color: Color(0xFFD4AF37))),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
