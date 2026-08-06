import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final String currentUserAccountName;

  const HomeScreen({super.key, required this.currentUserAccountName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة القانون', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF121216),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFFD4AF37)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('لا توجد إشعارات جديدة حالياً')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ترويسة الترحيب
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1E24), Color(0xFF2A2A32)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFFD4AF37),
                    child: Icon(Icons.person, color: Colors.black, size: 30),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('أهلاً بك مـرة أخرى 👋', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(
                          currentUserAccountName,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            const Text('الأقسام الرئيسية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37))),
            const SizedBox(height: 15),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              children: [
                _buildHomeCard(
                  context,
                  'القوانين العراقية',
                  Icons.menu_book_rounded,
                  Colors.amber,
                  'دستور جمهورية العراق، قانون العقوبات، القانون المدني، وقوانين الأحوال الشخصية.',
                ),
                _buildHomeCard(
                  context,
                  'المكتبة الرقمية',
                  Icons.local_library_rounded,
                  Colors.blueAccent,
                  'كتب وملازم الحقوق والبحوث القانونية المعتمدة لجامعة الموصل.',
                ),
                _buildHomeCard(
                  context,
                  'جدول المحاضرات',
                  Icons.calendar_month_rounded,
                  Colors.greenAccent,
                  'جدول المحاضرات اليومي والأسبوعي الخاص بكليتكم.',
                ),
                _buildHomeCard(
                  context,
                  'استشارات قانونية',
                  Icons.gavel_rounded,
                  Colors.purpleAccent,
                  'قسم تقديم الاستفسارات للأساتذة والمختصين القانونيين.',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeCard(BuildContext context, String title, IconData icon, Color accentColor, String details) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16161C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SectionDetailScreen(title: title, details: details, icon: icon, color: accentColor),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: accentColor),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

// شاشة تفاصيل الأقسام
class SectionDetailScreen extends StatelessWidget {
  final String title;
  final String details;
  final IconData icon;
  final Color color;

  const SectionDetailScreen({
    super.key,
    required this.title,
    required this.details,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Color(0xFFD4AF37))),
        backgroundColor: const Color(0xFF121216),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF16161C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(icon, size: 70, color: color),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    details,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
