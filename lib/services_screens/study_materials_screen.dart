import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_selector/file_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('المواد الدراسية'),
        backgroundColor: AppColors.primary,
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
// 1. لوحة تحكم الأدمن (سيتم فتحها من اللوحة الحصينة المركزية)
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
            title: const Text('رفع ملف جديد', textAlign: TextAlign.right),
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
                    try {
                      const XTypeGroup typeGroup = XTypeGroup(
                        label: 'PDFs',
                        extensions: <String>['pdf'],
                      );
                      final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

                      if (file != null) {
                        setStateDialog(() {
                          selectedFile = File(file.path);
                        });
                      }
                    } catch (e) {
                      debugPrint('Error picking file: $e');
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
                          
                          await Supabase.instance.client.storage
                              .from('pdfs')
                              .upload(fileName, selectedFile!);

                          final publicUrl = Supabase.instance.client.storage
                              .from('pdfs')
                              .getPublicUrl(fileName);

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

class StudentPdfsScreen extends StatefulWidget {
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
  State<StudentPdfsScreen> createState() => _StudentPdfsScreenState();
}

class _StudentPdfsScreenState extends State<StudentPdfsScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadingTitle = '';

  Future<void> _downloadAndOpenPdf(String rawUrl, String title) async {
    if (rawUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرابط غير صالح')),
        );
      }
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final safeTitle = title.replaceAll(RegExp(r'[^\w\s]+'), '_');
      final filePath = '${directory.path}/$safeTitle.pdf';

      final fileExists = await File(filePath).exists();

      if (fileExists) {
        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تعذر فتح الملف: ${result.message}')),
          );
        }
        return;
      }

      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
        _downloadingTitle = title;
      });

      final dio = Dio();
      await dio.download(
        rawUrl.trim(),
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      setState(() {
        _isDownloading = false;
      });

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر فتح الملف: ${result.message}')),
        );
      }
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء التنزيل: $e')),
        );
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
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
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
                      subtitle: const Text('اضغط للتحميل والفتح داخل التطبيق', style: TextStyle(fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.download, color: Colors.blue),
                        tooltip: 'تحميل وفتح',
                        onPressed: _isDownloading ? null : () => _downloadAndOpenPdf(pdfUrl, title),
                      ),
                      onTap: _isDownloading ? null : () => _downloadAndOpenPdf(pdfUrl, title),
                    ),
                  );
                },
              );
            },
          ),
          if (_isDownloading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 15),
                        Text(
                          'جاري تحميل: $_downloadingTitle',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text('${(_downloadProgress * 100).toStringAsFixed(0)}%'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 
