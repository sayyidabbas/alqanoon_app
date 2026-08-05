import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ServicesScreen extends StatelessWidget {
  final String currentUserAccountName;
  const ServicesScreen({super.key, required this.currentUserAccountName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الخدمات والكلية'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const Icon(Icons.forum, size: 40, color: Colors.green),
              title: const Text('منتدى الطلبة والدردشة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              subtitle: const Text('غرف المحادثة المباشرة بين الطلبة'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (c) => StudentForumScreen(currentUserAccountName: currentUserAccountName)));
              },
            ),
          ),
        ],
      ),
    );
  }
}
