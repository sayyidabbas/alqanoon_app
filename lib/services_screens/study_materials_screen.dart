import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../constants/app_colors.dart';

class StudyMaterialsScreen extends StatefulWidget {
  const StudyMaterialsScreen({super.key});

  @override
  State<StudyMaterialsScreen> createState() => _StudyMaterialsScreenState();
}

class _StudyMaterialsScreenState extends State<StudyMaterialsScreen> {
  final List<String> stages = [
    'المرحلة الأولى',
    'المرحلة الثانية',
    'المرحلة الثالثة',
    'المرحلة الرابعة',
  ];

  // التحقق من حالة الدخول للبوابة الآمنة
  Future<void> _handleAdminAccess(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool isAdminUnlocked = prefs.getBool('is_admin_unlocked') ?? false;

    if (isAdminUnlocked) {
      _navigateToAdminDashboard();
    } else {
      _showPasswordDialog(prefs);
    }
  }

  // نافذة طلب كلمة السر
  void _showPasswordDialog(SharedPreferences prefs) {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('البوابة الآمنة', textAlign: TextAlign.right),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(
            hintText: 'أدخل كلمة السر',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text == '1234') {
                await prefs.setBool('is_admin_unlocked', true);
                if (mounted) {
                  Navigator.pop(context);
                  _navigateToAdminDashboard();
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('كلمة السر غير صحيحة!')),
                );
              }
            },
            child: const Text('دخول'),
          ),
        ],
      ),
    );
  }

  void _navigateToAdminDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminStageSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('المواد الدراسية'),
        backgroundColor: AppColors.primary,
        actions: [
          // زر البوابة الآمنة أعلى اليمين
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.amber),
            tooltip: 'البوابة الآمنة',
            onPressed: () => _handleAdminAccess(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stages.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(stages[index], textAlign: TextAlign.right),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentSubjectsScreen(
                      stageIndex: index + 1,
                      stageName: stages[index],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 1. لوحة تحكم الأدمن (البوابة الآمنة)
// ==========================================

class AdminStageSelectionScreen extends StatelessWidget {
  const AdminStageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stages = [
      'المرحلة الأولى',
      'المرحلة الثانية',
      'المرحلة الثالثة',
      'المرحلة الرابعة'
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المراحل (الأدمن)'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stages.length,
        itemBuilder: (context, index) {
          return Card(
            child: ListTile(
              title: Text(stages[index], textAlign: TextAlign.right),
              trailing: const Icon(Icons.edit),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminManageSubjectsScreen(
                      stageIndex: index + 1,
                      stageName: stages[index],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class AdminManageSubjectsScreen extends StatefulWidget {
  final int stageIndex;
  final String stageName;

  const AdminManageSubjectsScreen({
    super.key,
    required this.stageIndex,
    required this.stageName,
  });

  @override
  State<AdminManageSubjectsScreen> createState() =>
      _AdminManageSubjectsScreenState();
}

class _AdminManageSubjectsScreenState extends State<AdminManageSubjectsScreen> {
  void _addSubjectDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مادة جديدة'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'اسم المادة الدراسية'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('stages')
                    .doc('stage_${widget.stageIndex}')
                    .collection('subjects')
                    .add({'name': controller.text.trim()});
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مواد ${widget.stageName}'),
        backgroundColor: AppColors.primary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSubjectDialog,
        label: const Text('إضافة مادة'),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stages')
            .doc('stage_${widget.stageIndex}')
            .collection('subjects')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text(data['name'] ?? ''),
                  trailing: const Icon(Icons.picture_as_pdf),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminManagePdfsScreen(
                          stageIndex: widget.stageIndex,
                          subjectId: docs[index].id,
                          subjectName: data['name'],
                        ),
                      ),
                    );
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

class AdminManagePdfsScreen extends StatefulWidget {
  final int stageIndex;
  final String subjectId;
  final String subjectName;

  const AdminManagePdfsScreen({
    super.key,
    required this.stageIndex,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<AdminManagePdfsScreen> createState() => _AdminManagePdfsScreenState();
}

class _AdminManagePdfsScreenState extends State<AdminManagePdfsScreen> {
  bool _isUploading = false;

  // رفع رابط المنهج مباشرة لـ Firestore
  void _addPdfUrlDialog() {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة رابط منهج PDF'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: 'عنوان المنهج أو المحاضرة'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(hintText: 'رابط ملف الـ PDF (Google Drive أو غيره)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && urlController.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('stages')
                    .doc('stage_${widget.stageIndex}')
                    .collection('subjects')
                    .doc(widget.subjectId)
                    .collection('pdfs')
                    .add({
                  'title': titleController.text.trim(),
                  'url': urlController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مناهج ${widget.subjectName}'),
        backgroundColor: AppColors.primary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPdfUrlDialog,
        label: const Text('إضافة منهج'),
        icon: const Icon(Icons.add_link),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stages')
            .doc('stage_${widget.stageIndex}')
            .collection('subjects')
            .doc(widget.subjectId)
            .collection('pdfs')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('لا توجد مناهج مضافة بعد'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(data['title'] ?? ''),
                subtitle: Text(data['url'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
              );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 2. واجهات عرض المحتوى للطلاب
// ==========================================

class StudentSubjectsScreen extends StatelessWidget {
  final int stageIndex;
  final String stageName;

  const StudentSubjectsScreen({
    super.key,
    required this.stageIndex,
    required this.stageName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مواد $stageName'),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stages')
            .doc('stage_$stageIndex')
            .collection('subjects')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('لا توجد مواد مضافة حالياً'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text(data['name'] ?? ''),
                  trailing: const Icon(Icons.menu_book),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentPdfsScreen(
                          stageIndex: stageIndex,
                          subjectId: docs[index].id,
                          subjectName: data['name'],
                        ),
                      ),
                    );
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

class StudentPdfsScreen extends StatelessWidget {
  final int stageIndex;
  final String subjectId;
  final String subjectName;

  const StudentPdfsScreen({
    super.key,
    required this.stageIndex,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مناهج $subjectName'),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('stages')
            .doc('stage_$stageIndex')
            .collection('subjects')
            .doc(subjectId)
            .collection('pdfs')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text('لا توجد مناهج متاحة حالياً'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(data['title'] ?? ''),
              );
            },
          );
        },
      ),
    );
  }
}
