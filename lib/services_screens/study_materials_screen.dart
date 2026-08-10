import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  String get _userAdminKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'is_admin_unlocked_$uid';
  }

  Future<String> _getAdminPin() async {
    final doc = await FirebaseFirestore.instance.collection('settings').doc('admin').get();
    if (doc.exists && doc.data()!.containsKey('pin')) {
      return doc.data()!['pin'].toString();
    }
    return '1234';
  }

  Future<void> _handleAdminAccess(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool isAdminUnlocked = prefs.getBool(_userAdminKey) ?? false;

    if (isAdminUnlocked) {
      _navigateToAdminDashboard();
    } else {
      _showPasswordDialog(prefs);
    }
  }

  void _showPasswordDialog(SharedPreferences prefs) {
    final TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('البوابة الآمنة', textAlign: TextAlign.right),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(hintText: 'أدخل كلمة السر'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final currentPin = await _getAdminPin();
              if (passwordController.text.trim() == currentPin) {
                await prefs.setBool(_userAdminKey, true);
                if (mounted) {
                  Navigator.pop(context);
                  _navigateToAdminDashboard();
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('كلمة السر غير صحيحة!')),
                  );
                }
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

  void _changePasswordDialog(BuildContext context) {
    final oldPinController = TextEditingController();
    final newPinController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغيير كلمة السر للبوابة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'كلمة السر الحالية'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: newPinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'كلمة السر الجديدة'),
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
              final doc = await FirebaseFirestore.instance.collection('settings').doc('admin').get();
              final currentPin = doc.exists && doc.data()!.containsKey('pin') ? doc.data()!['pin'] : '1234';

              if (oldPinController.text.trim() == currentPin) {
                if (newPinController.text.trim().length >= 4) {
                  await FirebaseFirestore.instance.collection('settings').doc('admin').set(
                    {'pin': newPinController.text.trim()},
                    SetOptions(merge: true),
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تغيير كلمة السر بنجاح')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يجب أن تتكون كلمة السر من 4 أرقام على الأقل')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('كلمة السر الحالية غير صحيحة')),
                );
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
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_reset, color: Colors.white),
            tooltip: 'تغيير كلمة السر',
            onPressed: () => _changePasswordDialog(context),
          ),
        ],
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
  State<AdminManageSubjectsScreen> createState() => _AdminManageSubjectsScreenState();
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

  void _editSubjectDialog(String docId, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل اسم المادة'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'اسم المادة'),
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
                    .doc(docId)
                    .update({'name': controller.text.trim()});
                if (mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  void _deleteSubject(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المادة'),
        content: const Text('هل أنت متأكد من حذف هذه المادة وكافة ملفاتها؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('stages')
          .doc('stage_${widget.stageIndex}')
          .collection('subjects')
          .doc(docId)
          .delete();
    }
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

          if (docs.isEmpty) {
            return const Center(child: Text('لا توجد مواد مضافة'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return Card(
                child: ListTile(
                  title: Text(data['name'] ?? ''),
                  leading: const Icon(Icons.book, color: Colors.blue),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editSubjectDialog(docId, data['name'] ?? '');
                      } else if (value == 'delete') {
                        _deleteSubject(docId);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                      const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminManagePdfsScreen(
                          stageIndex: widget.stageIndex,
                          subjectId: docId,
                          subjectName: data['name'] ?? '',
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
  
  void _addPdfDialog() {
    final titleController = TextEditingController();
    File? selectedFile;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('رفع منهج PDF جديد', textAlign: TextAlign.right),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(hintText: 'عنوان المحاضرة أو المنهج'),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: Text(selectedFile == null ? 'اختيار ملف PDF من الهاتف' : 'تم اختيار الملف'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedFile == null ? Colors.blue : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isUploading ? null : () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['pdf'],
                    );

                    if (result != null && result.files.single.path != null) {
                      setStateDialog(() {
                        selectedFile = File(result.files.single.path!);
                      });
                    }
                  },
                ),
                if (isUploading) ...[
                  const SizedBox(height: 15),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  const Text('جاري الرفع للسيرفر، لا تغلق النافذة...', style: TextStyle(fontSize: 12)),
                ]
              ],
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: (isUploading || selectedFile == null || titleController.text.isEmpty)
                    ? null
                    : () async {
                        setStateDialog(() { isUploading = true; });
                        try {
                          final fileName = '${DateTime.now().millisecondsSinceEpoch}.pdf';
                          
                          // الرفع لسيرفر Supabase
                          await Supabase.instance.client.storage
                              .from('pdfs')
                              .upload(fileName, selectedFile!);

                          final publicUrl = Supabase.instance.client.storage
                              .from('pdfs')
                              .getPublicUrl(fileName);

                          // الحفظ في الفايرستور
                          await FirebaseFirestore.instance
                              .collection('stages')
                              .doc('stage_${widget.stageIndex}')
                              .collection('subjects')
                              .doc(widget.subjectId)
                              .collection('pdfs')
                              .add({
                            'title': titleController.text.trim(),
                            'url': publicUrl,
                            'fileName': fileName,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          if (mounted) Navigator.pop(ctx);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('حدث خطأ: $e')),
                          );
                          setStateDialog(() { isUploading = false; });
                        }
                      },
                child: const Text('رفع وحفظ'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _editPdfDialog(String pdfId, String currentTitle, String currentUrl) {
    final titleController = TextEditingController(text: currentTitle);
    final urlController = TextEditingController(text: currentUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تعديل الملف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: 'عنوان المحاضرة'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(hintText: 'الرابط'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('stages')
                  .doc('stage_${widget.stageIndex}')
                  .collection('subjects')
                  .doc(widget.subjectId)
                  .collection('pdfs')
                  .doc(pdfId)
                  .update({
                'title': titleController.text.trim(),
                'url': urlController.text.trim(),
              });
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text('تعديل'),
          ),
        ],
      ),
    );
  }

  void _deletePdf(String pdfId, String? fileName) async {
    await FirebaseFirestore.instance
        .collection('stages')
        .doc('stage_${widget.stageIndex}')
        .collection('subjects')
        .doc(widget.subjectId)
        .collection('pdfs')
        .doc(pdfId)
        .delete();

    if (fileName != null && fileName.isNotEmpty) {
      try {
        await Supabase.instance.client.storage.from('pdfs').remove([fileName]);
      } catch (e) {
        debugPrint('خطأ في حذف الملف: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مناهج ${widget.subjectName}'),
        backgroundColor: AppColors.primary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPdfDialog,
        label: const Text('رفع ملف PDF'),
        icon: const Icon(Icons.upload_file),
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
              final pdfId = docs[index].id;

              return ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(data['title'] ?? ''),
                subtitle: Text(data['url'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editPdfDialog(pdfId, data['title'] ?? '', data['url'] ?? '');
                    } else if (value == 'delete') {
                      _deletePdf(pdfId, data['fileName']);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                    const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.red))),
                  ],
                ),
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
                          subjectName: data['name'] ?? '',
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

  // الدالة المعدلة لفتح الرابط مباشرة عبر المتصفح أو تطبيق القراءة في النظام
  Future<void> _openPdfUrl(BuildContext context, String rawUrl) async {
    if (rawUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرابط غير صالح')),
      );
      return;
    }

    final Uri uri = Uri.parse(rawUrl.trim());
    if (await canLaunchUrl(uri)) {
      // استخدام النمط الخارجي ليفتح المتصفح أو تطبيق التنزيلات
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الملف')),
        );
      }
    }
  }

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
            .orderBy('createdAt', descending: true)
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
              final String pdfUrl = data['url'] ?? '';
              final String title = data['title'] ?? '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 30),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('اضغط لفتح الملف وعرضه', style: TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.open_in_new, color: Colors.blue),
                  onTap: () => _openPdfUrl(context, pdfUrl),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
 
