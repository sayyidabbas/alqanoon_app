import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../constants/app_colors.dart';

// ==========================================
// شاشة البداية والمواد الدراسية
// ==========================================
class StudyMaterialsScreen extends StatefulWidget {
  const StudyMaterialsScreen({super.key});

  @override
  State<StudyMaterialsScreen> createState() => _StudyMaterialsScreenState();
}

class _StudyMaterialsScreenState extends State<StudyMaterialsScreen> {
  final List<String> stages = ['المرحلة الأولى', 'المرحلة الثانية', 'المرحلة الثالثة', 'المرحلة الرابعة'];

  String get _userAdminKey => 'is_admin_unlocked_${FirebaseAuth.instance.currentUser?.uid ?? 'guest'}';

  Future<String> _getAdminPin() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('admin').get();
      return doc.data()?['pin']?.toString() ?? '1234';
    } catch (_) {
      return '1234';
    }
  }

  Future<void> _handleAdminAccess(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool isAdminUnlocked = prefs.getBool(_userAdminKey) ?? false;

    if (isAdminUnlocked) {
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminStageSelectionScreen()));
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final currentPin = await _getAdminPin();
              if (passwordController.text.trim() == currentPin) {
                await prefs.setBool(_userAdminKey, true);
                if (!mounted) return;
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminStageSelectionScreen()));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('كلمة السر غير صحيحة!')));
              }
            },
            child: const Text('دخول'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(title: const Text('المواد الدراسية'), backgroundColor: AppColors.primary, actions: [
        IconButton(icon: const Icon(Icons.admin_panel_settings, color: Colors.amber), onPressed: () => _handleAdminAccess(context)),
      ]),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stages.length,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(stages[index], textAlign: TextAlign.right),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentSubjectsScreen(stageIndex: index + 1, stageName: stages[index]))),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// لوحة تحكم الأدمن
// ==========================================
class AdminStageSelectionScreen extends StatelessWidget {
  const AdminStageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stages = ['المرحلة الأولى', 'المرحلة الثانية', 'المرحلة الثالثة', 'المرحلة الرابعة'];
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة المراحل (الأدمن)'), backgroundColor: AppColors.primary),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stages.length,
        itemBuilder: (context, index) => Card(
          child: ListTile(
            title: Text(stages[index], textAlign: TextAlign.right),
            trailing: const Icon(Icons.edit),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminManageSubjectsScreen(stageIndex: index + 1, stageName: stages[index]))),
          ),
        ),
      ),
    );
  }
}

class AdminManageSubjectsScreen extends StatefulWidget {
  final int stageIndex;
  final String stageName;
  const AdminManageSubjectsScreen({super.key, required this.stageIndex, required this.stageName});

  @override
  State<AdminManageSubjectsScreen> createState() => _AdminManageSubjectsScreenState();
}

class _AdminManageSubjectsScreenState extends State<AdminManageSubjectsScreen> {
  Future<void> _addSubject(String name) async {
    if (name.isEmpty) return;
    await FirebaseFirestore.instance.collection('stages').doc('stage_${widget.stageIndex}').collection('subjects').add({'name': name});
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('مواد ${widget.stageName}'), backgroundColor: AppColors.primary),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(),
        label: const Text('إضافة مادة'),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stages').doc('stage_${widget.stageIndex}').collection('subjects').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                child: ListTile(
                  title: Text(data['name'] ?? ''),
                  trailing: PopupMenuButton(
                    onSelected: (val) => val == 'delete' ? _deleteSubject(docs[index].id) : _showEditDialog(docs[index].id, data['name']),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('تعديل')),
                      const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.red))),
                    ],
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminManagePdfsScreen(stageIndex: widget.stageIndex, subjectId: docs[index].id, subjectName: data['name']))),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddDialog() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('إضافة مادة'), content: TextField(controller: ctrl), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), ElevatedButton(onPressed: () => _addSubject(ctrl.text.trim()), child: const Text('إضافة'))]));
  }

  void _showEditDialog(String id, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('تعديل'), content: TextField(controller: ctrl), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')), ElevatedButton(onPressed: () async { await FirebaseFirestore.instance.collection('stages').doc('stage_${widget.stageIndex}').collection('subjects').doc(id).update({'name': ctrl.text.trim()}); if (mounted) Navigator.pop(context); }, child: const Text('حفظ'))]));
  }

  Future<void> _deleteSubject(String id) async {
    await FirebaseFirestore.instance.collection('stages').doc('stage_${widget.stageIndex}').collection('subjects').doc(id).delete();
  }
}

// ==========================================
// شاشة إدارة الـ PDF للأدمن
// ==========================================
class AdminManagePdfsScreen extends StatefulWidget {
  final int stageIndex;
  final String subjectId;
  final String subjectName;
  const AdminManagePdfsScreen({super.key, required this.stageIndex, required this.subjectId, required this.subjectName});

  @override
  State<AdminManagePdfsScreen> createState() => _AdminManagePdfsScreenState();
}

class _AdminManagePdfsScreenState extends State<AdminManagePdfsScreen> {
  bool _isUploading = false;

  Future<void> _uploadPdf() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final titleCtrl = TextEditingController();

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(builder: (ctx, setDialog) => AlertDialog(
        title: const Text('رفع ملف PDF'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(hintText: 'عنوان الملف')),
          if (_isUploading) ...[const SizedBox(height: 20), const CircularProgressIndicator()]
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: _isUploading ? null : () async {
              if (titleCtrl.text.isEmpty) return;
              setDialog(() => _isUploading = true);
              try {
                final fileName = '${DateTime.now().millisecondsSinceEpoch}.pdf';
                await Supabase.instance.client.storage.from('pdfs').upload(fileName, file);
                final url = Supabase.instance.client.storage.from('pdfs').getPublicUrl(fileName);
                await FirebaseFirestore.instance.collection('stages').doc('stage_${widget.stageIndex}').collection('subjects').doc(widget.subjectId).collection('pdfs').add({
                  'title': titleCtrl.text.trim(), 'url': url, 'fileName': fileName, 'createdAt': FieldValue.serverTimestamp()
                });
                if (mounted) Navigator.pop(ctx);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
              } finally {
                if (mounted) setDialog(() => _isUploading = false);
              }
            },
            child: const Text('رفع'),
          )
        ],
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('مناهج ${widget.subjectName}'), backgroundColor: AppColors.primary),
      floatingActionButton: FloatingActionButton.extended(onPressed: _uploadPdf, label: const Text('رفع PDF'), icon: const Icon(Icons.upload_file)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stages').doc('stage_${widget.stageIndex}').collection('subjects').doc(widget.subjectId).collection('pdfs').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(data['title'] ?? ''),
                trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deletePdf(snapshot.data!.docs[index].id, data['fileName'])),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deletePdf(String id, String? fileName) async {
    await FirebaseFirestore.instance.collection('stages').doc('stage_${widget.stageIndex}').collection('subjects').doc(widget.subjectId).collection('pdfs').doc(id).delete();
    if (fileName != null) await Supabase.instance.client.storage.from('pdfs').remove([fileName]);
  }
}

// ==========================================
// واجهات الطلاب
// ==========================================
class StudentSubjectsScreen extends StatelessWidget {
  final int stageIndex;
  final String stageName;
  const StudentSubjectsScreen({super.key, required this.stageIndex, required this.stageName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('مواد $stageName'), backgroundColor: AppColors.primary),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stages').doc('stage_$stageIndex').collection('subjects').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              return Card(child: ListTile(title: Text(doc['name'] ?? ''), trailing: const Icon(Icons.menu_book), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentPdfsScreen(stageIndex: stageIndex, subjectId: doc.id, subjectName: doc['name'])))));
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
  const StudentPdfsScreen({super.key, required this.stageIndex, required this.subjectId, required this.subjectName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('مناهج $subjectName'), backgroundColor: AppColors.primary),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stages').doc('stage_$stageIndex').collection('subjects').doc(subjectId).collection('pdfs').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return Card(child: ListTile(leading: const Icon(Icons.picture_as_pdf, color: Colors.red), title: Text(data['title'] ?? ''), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PdfViewerScreen(title: data['title'], url: data['url'])))));
            },
          );
        },
      ),
    );
  }
}

class PdfViewerScreen extends StatelessWidget {
  final String title;
  final String url;
  const PdfViewerScreen({super.key, required this.title, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: AppColors.primary, actions: [
        IconButton(icon: const Icon(Icons.download), onPressed: () async { await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); })
      ]),
      body: url.contains('drive.google.com')
          ? _buildDriveView()
          : SfPdfViewer.network(url),
    );
  }

  Widget _buildDriveView() {
    return Center(child: ElevatedButton(onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication), child: const Text('فتح في المتصفح')));
  }
}
 
