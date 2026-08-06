import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String currentUserAccountName;
  final String currentUserEmail;
  final String currentUserUniversity;
  final String currentUserCollege;
  final bool isAdmin;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.currentUserAccountName,
    required this.currentUserEmail,
    required this.currentUserUniversity,
    required this.currentUserCollege,
    this.isAdmin = false,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF121216),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                    ),
                    child: const CircleAvatar(
                      radius: 45,
                      backgroundColor: Color(0xFF1E1E24),
                      child: Icon(Icons.person, size: 50, color: Color(0xFFD4AF37)),
                    ),
                  ),
                  if (isAdmin)
                    const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.redAccent,
                      child: Icon(Icons.shield, size: 16, color: Colors.white),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(currentUserAccountName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(currentUserEmail, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 30),
            _buildInfoCard('الجامعة', currentUserUniversity, Icons.school_outlined),
            _buildInfoCard('الكلية', currentUserCollege, Icons.account_balance_outlined),
            _buildInfoCard('نوع الحساب', isAdmin ? 'مسؤول النظام (Admin)' : 'طالب قانون', Icons.badge_outlined),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.shade700,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16161C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD4AF37)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
