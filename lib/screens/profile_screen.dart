import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  final String currentUserAccountName;
  final String currentUserEmail;
  final String currentUserUniversity;
  final String currentUserCollege;
  final Function onLogout;

  const ProfileScreen({
    super.key,
    required this.currentUserAccountName,
    required this.currentUserEmail,
    required this.currentUserUniversity,
    required this.currentUserCollege,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الملف الشخصي'), backgroundColor: const Color(0xFF1A1A1A), foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFF1A1A1A),
            child: Text(currentUserAccountName.isNotEmpty ? currentUserAccountName[0].toUpperCase() : 'س', style: const TextStyle(fontSize: 30, color: Color(0xFFD4AF37))),
          ),
          const SizedBox(height: 10),
          Text(currentUserAccountName, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(currentUserEmail, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 6),
          Text('$currentUserUniversity - $currentUserCollege', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
          const Divider(height: 30),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
            onTap: () async {
              try {
                await FirebaseAuth.instance.signOut();
              } catch (_) {}
              onLogout();
            },
          )
        ],
      ),
    );
  }
}
