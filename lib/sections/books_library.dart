import 'package:flutter/material.dart';

class BooksLibraryScreen extends StatelessWidget {
  const BooksLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مكتبة الكتب'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('قسم مكتبة الكتب - قيد الإعداد', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
