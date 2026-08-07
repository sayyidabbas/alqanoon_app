import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة القانون'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              backgroundColor: AppColors.accent,
              child: Text('ع', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: const Center(
        child: Text(
          'أهلاً بك في الصفحة الرئيسية لمنصة القانون',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.cardBg,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: AppColors.primary),
            accountName: Text('سيدعباس عقيل الحسيني'),
            accountEmail: Text('abbas@lawplatform.com'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: AppColors.accent,
              child: Icon(Icons.person, size: 40, color: Colors.black),
            ),
          ),
          _drawerItem(Icons.home, 'الصفحة الرئيسية', () {}),
          _drawerItem(Icons.menu_book, 'المكتبة القانونية', () {}),
          _drawerItem(Icons.book, 'المواد الدراسية', () {}),
          _drawerItem(Icons.quiz, 'بنك الأسئلة', () {}),
          _drawerItem(Icons.assignment, 'الاختبارات الإلكترونية', () {}),
          _drawerItem(Icons.newspaper, 'الأخبار والإعلانات', () {}),
          _drawerItem(Icons.notifications, 'الإشعارات', () {}),
          _drawerItem(Icons.favorite, 'المفضلة', () {}),
          _drawerItem(Icons.search, 'البحث', () {}),
          const Divider(color: Colors.white24),
          _drawerItem(Icons.person, 'الملف الشخصي', () {}),
          _drawerItem(Icons.settings, 'الإعدادات', () {}),
          _drawerItem(Icons.info, 'حول التطبيق', () {}),
          const Divider(color: Colors.white24),
          _drawerItem(Icons.logout, 'تسجيل الخروج', () {
            Navigator.pushReplacementNamed(context, AppRoutes.login);
          }, color: Colors.redAccent),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.accent),
      title: Text(title, style: TextStyle(color: color ?? AppColors.textPrimary)),
      onTap: onTap,
    );
  }
}
