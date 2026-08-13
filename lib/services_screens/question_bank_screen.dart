/**
 * ==============================================================================
 * 🔒 FIRESTORE SECURITY RULES (قواعد أمان فايرستور المقترحة للتطبيق)
 * ==============================================================================
 * rules_version = '2';
 * service cloud.firestore {
 *   match /databases/{database}/documents {
 *     
 *     // حماية الإعدادات (كلمة سر الأدمن)
 *     match /settings/admin {
 *       allow read: if request.auth != null;
 *       allow write: if request.auth != null;
 *     }
 * 
 *     // بنك الأسئلة: القراءة للجميع، التعديل والحذف فقط للأدمن أو عبر الشروط المأذونة
 *     match /question_bank/{stageId}/subjects/{subjectId} {
 *       allow read: if request.auth != null;
 *       allow write: if request.auth != null; // يمكن تخصيصها لاحقاً لترتبط بصلاحيات الأدمن
 *       
 *       match /question_sets/{setId} {
 *         allow read: if request.auth != null;
 *         allow write: if request.auth != null;
 *       }
 * 
 *       // غرف التحدي: السماح للمشاركين فقط بتحديث نقاطهم وحالتهم
 *       match /battle_rooms/{roomId} {
 *         allow read: if request.auth != null;
 *         allow create: if request.auth != null;
 *         allow update: if request.auth != null && 
 *           (request.auth.uid == resource.data.player1 || request.auth.uid == resource.data.player2 || request.auth.uid == request.resource.data.player2);
 *         allow delete: if request.auth != null;
 *       }
 *     }
 *   }
 * }
 * ==============================================================================
 */

import 'dart:async' as async_lib;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../constants/app_colors.dart';

class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  final List<String> stages = [
    'المرحلة الأولى',
    'المرحلة الثانية',
    'المرحلة الثالثة',
    'المرحلة الرابعة',
  ];

  String get _userAdminKey {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    return 'is_admin_unlocked_qb_$uid';
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
        title: const Text('البوابة الآمنة - بنك الأسئلة', textAlign: TextAlign.right),
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
      MaterialPageRoute(builder: (_) => const AdminQbStageSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('بنك الأسئلة'),
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
                    builder: (_) => StudentQbSubjectsScreen(
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
// 1. لوحة تحكم الأدمن لبنك الأسئلة
// ==========================================

class AdminQbStageSelectionScreen extends StatelessWidget {
  const AdminQbStageSelectionScreen({super.key});

  void _changeAdminPinDialog(BuildContext context) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تغيير كلمة سر البوابة الآمنة', textAlign: TextAlign.right),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'أدخل كلمة السر الجديدة'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance.collection('settings').doc('admin').set({
                  'pin': pinController.text.trim(),
                }, SetOptions(merge: true));
                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تغيير كلمة السر بنجاح')),
                  );
                }
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
    final stages = ['المرحلة الأولى', 'المرحلة الثانية', 'المرحلة الثالثة', 'المرحلة الرابعة'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة بنك الأسئلة (الأدمن)'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_reset, color: Colors.white),
            tooltip: 'تغيير كلمة السر',
            onPressed: () => _changeAdminPinDialog(context),
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
                    builder: (_) => AdminQbSubjectsScreen(
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

class AdminQbSubjectsScreen extends StatefulWidget {
  final int stageIndex;
  final String stageName;

  const AdminQbSubjectsScreen({super.key, required this.stageIndex, required this.stageName});

  @override
  State<AdminQbSubjectsScreen> createState() => _AdminQbSubjectsScreenState();
}

class _AdminQbSubjectsScreenState extends State<AdminQbSubjectsScreen> {
  void _addSubjectDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مادة لبنك الأسئلة'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'اسم المادة'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('question_bank')
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

  void _deleteSubject(String docId) async {
    await FirebaseFirestore.instance
        .collection('question_bank')
        .doc('stage_${widget.stageIndex}')
        .collection('subjects')
        .doc(docId)
        .delete();
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
            .collection('question_bank')
            .doc('stage_${widget.stageIndex}')
            .collection('subjects')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text('لا توجد مواد مضافة'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;

              return Card(
                child: ListTile(
                  title: Text(data['name'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteSubject(docId),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminManageQuestionSetsScreen(
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

// ==========================================
// 2. إدارة مجموعات الأسئلة (Bulk Import & List)
// ==========================================

class AdminManageQuestionSetsScreen extends StatelessWidget {
  final int stageIndex;
  final String subjectId;
  final String subjectName;

  const AdminManageQuestionSetsScreen({
    super.key,
    required this.stageIndex,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('اختبارات $subjectName'),
        backgroundColor: AppColors.primary,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminAddQuestionsScreen(
                stageIndex: stageIndex,
                subjectId: subjectId,
                subjectName: subjectName,
              ),
            ),
          );
        },
        label: const Text('إضافة دفعة أسئلة جديدة'),
        icon: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('question_bank')
            .doc('stage_$stageIndex')
            .collection('subjects')
            .doc(subjectId)
            .collection('question_sets')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text('لا توجد اختبارات مضافة. اضغط على الزر أدناه لإضافة أسئلة.'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final List questions = data['questions'] ?? [];
              final setId = docs[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(data['title'] ?? 'مجموعة أسئلة', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('عدد الأسئلة: ${questions.length}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_note, color: Colors.blue),
                        tooltip: 'تعديل وحذف الأسئلة',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AdminEditQuestionsListScreen(
                                stageIndex: stageIndex,
                                subjectId: subjectId,
                                setId: setId,
                                questions: List.from(questions),
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('question_bank')
                              .doc('stage_$stageIndex')
                              .collection('subjects')
                              .doc(subjectId)
                              .collection('question_sets')
                              .doc(setId)
                              .delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminAddQuestionsScreen extends StatefulWidget {
  final int stageIndex;
  final String subjectId;
  final String subjectName;

  const AdminAddQuestionsScreen({
    super.key,
    required this.stageIndex,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<AdminAddQuestionsScreen> createState() => _AdminAddQuestionsScreenState();
}

class _AdminAddQuestionsScreenState extends State<AdminAddQuestionsScreen> {
  final TextEditingController _bulkController = TextEditingController();
  bool _isSaving = false;

  List<Map<String, dynamic>> _parseQuestions() {
    final text = _bulkController.text.trim();
    final blocks = text.split(RegExp(r'\n\s*\n'));
    List<Map<String, dynamic>> questionsList = [];

    for (var block in blocks) {
      final lines = block.trim().split('\n');
      if (lines.length < 2) continue;

      String questionText = lines[0].trim();
      List<String> options = [];
      int correctIndex = 0;

      for (int i = 1; i < lines.length; i++) {
        String optLine = lines[i].trim();
        if (optLine.contains('✅')) {
          correctIndex = options.length;
          optLine = optLine.replaceAll('✅', '').trim();
        }
        options.add(optLine);
      }

      if (options.isNotEmpty) {
        questionsList.add({
          'question': questionText,
          'options': options,
          'correctIndex': correctIndex,
        });
      }
    }
    return questionsList;
  }

  void _onSavePressed() async {
    final text = _bulkController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء لصق الأسئلة أولاً')),
      );
      return;
    }

    final newQuestions = _parseQuestions();
    if (newQuestions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم التعرف على أي أسئلة. تأكد من النمط الصحيح!')),
      );
      return;
    }

    final setsSnapshot = await FirebaseFirestore.instance
        .collection('question_bank')
        .doc('stage_${widget.stageIndex}')
        .collection('subjects')
        .doc(widget.subjectId)
        .collection('question_sets')
        .orderBy('createdAt', descending: true)
        .get();

    if (!mounted) return;

    if (setsSnapshot.docs.isEmpty) {
      _saveAsNewSet(newQuestions);
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('طريقة الحفظ', textAlign: TextAlign.right),
          content: const Text('كيف تريد حفظ الأسئلة الجديدة؟', textAlign: TextAlign.right),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _saveAsNewSet(newQuestions);
              },
              child: const Text('مجموعة مستقلة جديدة'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _showMergeTargetDialog(setsSnapshot.docs, newQuestions);
              },
              child: const Text('دمج مع مجموعة سابقة'),
            ),
          ],
        ),
      );
    }
  }

  void _saveAsNewSet(List<Map<String, dynamic>> newQuestions) async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('question_bank')
          .doc('stage_${widget.stageIndex}')
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('question_sets')
          .add({
        'title': 'مجموعة أسئلة (${DateTime.now().toString().substring(0, 16)})',
        'questions': newQuestions,
        'createdAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isSaving = false);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة الأسئلة كمجموعة جديدة بنجاح!')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  void _showMergeTargetDialog(List<QueryDocumentSnapshot> existingDocs, List<Map<String, dynamic>> newQuestions) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('اختر المجموعة للدمج معها', textAlign: TextAlign.right),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: existingDocs.length,
            itemBuilder: (context, index) {
              final docData = existingDocs[index].data() as Map<String, dynamic>;
              final docId = existingDocs[index].id;
              final title = docData['title'] ?? 'مجموعة بدون عنوان';
              
              return ListTile(
                title: Text(title, textAlign: TextAlign.right),
                trailing: const Icon(Icons.merge_type, color: Colors.blue),
                onTap: () {
                  Navigator.pop(ctx);
                  _executeMerge(docId, docData['questions'] ?? [], newQuestions);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  void _executeMerge(String targetSetId, List existingQuestions, List<Map<String, dynamic>> newQuestions) async {
    setState(() => _isSaving = true);
    try {
      List updatedQuestions = [...newQuestions, ...existingQuestions];

      await FirebaseFirestore.instance
          .collection('question_bank')
          .doc('stage_${widget.stageIndex}')
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('question_sets')
          .doc(targetSetId)
          .update({
        'questions': updatedQuestions,
      });

      setState(() => _isSaving = false);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم دمج وإضافة الأسئلة فوق المجموعة السابقة بنجاح!')),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الدمج: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('إضافة أسئلة لـ ${widget.subjectName}'),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'الصق الأسئلة هنا بالنمط:\nالسؤال\nأ) خيار\nب) خيار ✅\nج) خيار',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: _bulkController,
                maxLines: null,
                expands: true,
                textAlign: TextAlign.right,
                decoration: const InputDecoration(
                  hintText: 'اكتب أو لصق الأسئلة هنا...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: _isSaving ? null : _onSavePressed,
                icon: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.cloud_upload),
                label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ الأسئلة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// شاشة تعديل وحذف الأسئلة الفردية
// ==========================================

class AdminEditQuestionsListScreen extends StatefulWidget {
  final int stageIndex;
  final String subjectId;
  final String setId;
  final List questions;

  const AdminEditQuestionsListScreen({
    super.key,
    required this.stageIndex,
    required this.subjectId,
    required this.setId,
    required this.questions,
  });

  @override
  State<AdminEditQuestionsListScreen> createState() => _AdminEditQuestionsListScreenState();
}

class _AdminEditQuestionsListScreenState extends State<AdminEditQuestionsListScreen> {
  late List questionsList;

  @override
  void initState() {
    super.initState();
    questionsList = List.from(widget.questions);
  }

  void _saveChanges() async {
    await FirebaseFirestore.instance
        .collection('question_bank')
        .doc('stage_${widget.stageIndex}')
        .collection('subjects')
        .doc(widget.subjectId)
        .collection('question_sets')
        .doc(widget.setId)
        .update({'questions': questionsList});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ التعديلات بنجاح')),
      );
      Navigator.pop(context);
    }
  }

  void _editQuestionDialog(int index) {
    final qData = questionsList[index];
    final qController = TextEditingController(text: qData['question']);
    List<TextEditingController> optionControllers = (qData['options'] as List)
        .map((opt) => TextEditingController(text: opt))
        .toList();
    int correctIdx = qData['correctIndex'] ?? 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('تعديل السؤال ${index + 1}', textAlign: TextAlign.right),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qController,
                  decoration: const InputDecoration(labelText: 'نص السؤال'),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 10),
                ...List.generate(optionControllers.length, (optIdx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: optIdx,
                          groupValue: correctIdx,
                          onChanged: (val) {
                            setDialogState(() => correctIdx = val!);
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: optionControllers[optIdx],
                            decoration: InputDecoration(labelText: 'الخيار ${optIdx + 1}'),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  questionsList[index] = {
                    'question': qController.text.trim(),
                    'options': optionControllers.map((c) => c.text.trim()).toList(),
                    'correctIndex': correctIdx,
                  };
                });
                Navigator.pop(ctx);
              },
              child: const Text('تحديث'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteSingleQuestion(int index) {
    setState(() {
      questionsList.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل أسئلة الاختبار'),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'حفظ التغييرات',
            onPressed: _saveChanges,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questionsList.length,
        itemBuilder: (context, index) {
          final q = questionsList[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text('${index + 1}. ${q['question']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('عدد الخيارات: ${(q['options'] as List).length}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editQuestionDialog(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteSingleQuestion(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 3. واجهات عرض وممارسة الطلاب
// ==========================================

class StudentQbSubjectsScreen extends StatelessWidget {
  final int stageIndex;
  final String stageName;

  const StudentQbSubjectsScreen({super.key, required this.stageIndex, required this.stageName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('مواد $stageName'),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('question_bank')
            .doc('stage_$stageIndex')
            .collection('subjects')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text('لا توجد مواد مضافة حالياً'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: const Icon(Icons.sports_esports, size: 20),
                    label: const Text('تحدي 1v1'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizBattleLobbyScreen(
                            stageIndex: stageIndex,
                            subjectId: docs[index].id,
                            subjectName: data['name'] ?? '',
                          ),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentQuestionSetsScreen(
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

class StudentQuestionSetsScreen extends StatelessWidget {
  final int stageIndex;
  final String subjectId;
  final String subjectName;

  const StudentQuestionSetsScreen({
    super.key,
    required this.stageIndex,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('اختبارات $subjectName'),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('question_bank')
            .doc('stage_$stageIndex')
            .collection('subjects')
            .doc(subjectId)
            .collection('question_sets')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) return const Center(child: Text('لا توجد اختبارات متاحة حالياً'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final List questions = data['questions'] ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.assignment, color: Colors.amber, size: 30),
                  title: Text(data['title'] ?? 'اختبار تدريبي', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('عدد الأسئلة: ${questions.length}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    if (questions.isNotEmpty) {
                      _showQuizOptionsDialog(context, data['title'] ?? 'اختبار', questions);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('هذا الاختبار فارغ')),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showQuizOptionsDialog(BuildContext context, String title, List originalQuestions) {
    int selectedTimerSeconds = 30;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إعدادات بدء الاختبار', textAlign: TextAlign.right),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('اختر وقت المؤقت لكل سؤال:'),
              const SizedBox(height: 10),
              DropdownButton<int>(
                value: selectedTimerSeconds,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 15, child: Text('15 ثانية', textAlign: TextAlign.right)),
                  DropdownMenuItem(value: 30, child: Text('30 ثانية', textAlign: TextAlign.right)),
                  DropdownMenuItem(value: 60, child: Text('60 ثانية', textAlign: TextAlign.right)),
                  DropdownMenuItem(value: 0, child: Text('بدون وقت (حر)', textAlign: TextAlign.right)),
                ],
                onChanged: (val) {
                  setDialogState(() => selectedTimerSeconds = val!);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                
                List randomizedQuestions = List.from(originalQuestions);
                randomizedQuestions.shuffle();

                for (var q in randomizedQuestions) {
                  List options = List.from(q['options']);
                  String correctOptionText = options[q['correctIndex'] ?? 0];
                  options.shuffle();
                  int newCorrectIndex = options.indexOf(correctOptionText);
                  q['options'] = options;
                  q['correctIndex'] = newCorrectIndex;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuizPracticeScreen(
                      setTitle: title,
                      questions: randomizedQuestions,
                      timerSeconds: selectedTimerSeconds,
                    ),
                  ),
                );
              },
              child: const Text('بدء الاختبار'),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. شاشة التدريب الفردي
// ==========================================

class QuizPracticeScreen extends StatefulWidget {
  final String setTitle;
  final List questions;
  final int timerSeconds;

  const QuizPracticeScreen({
    super.key,
    required this.setTitle,
    required this.questions,
    required this.timerSeconds,
  });

  @override
  State<QuizPracticeScreen> createState() => _QuizPracticeScreenState();
}

class _QuizPracticeScreenState extends State<QuizPracticeScreen> {
  int currentIndex = 0;
  int? selectedOptionIndex;
  bool answered = false;
  int correctAnswersCount = 0;
  
  async_lib.Timer? _timer;
  int _remainingSeconds = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _startQuestionTimer();
  }

  void _startQuestionTimer() {
    if (widget.timerSeconds <= 0) return;
    _remainingSeconds = widget.timerSeconds;
    _timer?.cancel();
    _timer = async_lib.Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        if (!answered) {
          _answerQuestion(-1);
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _answerQuestion(int index) async {
    if (answered) return;
    _timer?.cancel();

    // تشغيل الاهتزاز والصوت عند الإجابة
    HapticFeedback.mediumImpact();
    final correct = widget.questions[currentIndex]['correctIndex'] ?? 0;
    if (index == correct) {
      try {
        await _audioPlayer.play(AssetSource('sounds/correct.mp3'));
      } catch (_) {}
    } else {
      try {
        await _audioPlayer.play(AssetSource('sounds/wrong.mp3'));
      } catch (_) {}
    }

    setState(() {
      selectedOptionIndex = index;
      answered = true;
      if (index == correct) {
        correctAnswersCount++;
      }
    });
  }

  String _getOptionPrefix(int index) {
    const prefixes = ['أ.', 'ب.', 'ج.', 'د.'];
    return index < prefixes.length ? prefixes[index] : '${index + 1}.';
  }

  void _nextQuestion() {
    if (currentIndex < widget.questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedOptionIndex = null;
        answered = false;
      });
      _startQuestionTimer();
    } else {
      _timer?.cancel();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('نتيجة التدريب', textAlign: TextAlign.right),
          content: Text(
            'أحسنت لقد اتممت التدريب!\n\nأجبت بشكل صحيح على $correctAnswersCount من أصل ${widget.questions.length} سؤال.',
            textAlign: TextAlign.right,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text('إنهاء'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final questionData = widget.questions[currentIndex];
    final String questionText = questionData['question'] ?? '';
    final List options = questionData['options'] ?? [];
    final int correctIndex = questionData['correctIndex'] ?? 0;

    int total = widget.questions.length;
    int remaining = total - (currentIndex + 1);
    int completed = currentIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setTitle),
        backgroundColor: AppColors.primary,
        actions: [
          if (widget.timerSeconds > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '$_remaining ث',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(label: Text('المتبقي: $remaining'), backgroundColor: Colors.orange.shade100),
                Chip(label: Text('تم حل: $completed'), backgroundColor: Colors.blue.shade100),
                Chip(label: Text('السؤال ${currentIndex + 1}/$total'), backgroundColor: Colors.green.shade100),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  questionText,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  Color btnColor = Colors.white;
                  if (answered) {
                    if (index == correctIndex) {
                      btnColor = Colors.green.shade200;
                    } else if (index == selectedOptionIndex) {
                      btnColor = Colors.red.shade200;
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: btnColor,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        alignment: Alignment.centerRight,
                      ),
                      onPressed: () => _answerQuestion(index),
                      child: Text(
                        '${_getOptionPrefix(index)} ${options[index]}',
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (answered)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _nextQuestion,
                child: Text(
                  currentIndex == total - 1 ? 'عرض النتيجة النهائية' : 'السؤال التالي',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  int get _remaining => _remainingSeconds;
}

// ==========================================
// 5. نظام غرفة التحدي الثنائي المباشر (1v1 Live Battle)
// ==========================================

class QuizBattleLobbyScreen extends StatefulWidget {
  final int stageIndex;
  final String subjectId;
  final String subjectName;

  const QuizBattleLobbyScreen({
    super.key,
    required this.stageIndex,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  State<QuizBattleLobbyScreen> createState() => _QuizBattleLobbyScreenState();
}

class _QuizBattleLobbyScreenState extends State<QuizBattleLobbyScreen> {
  bool _isSearching = false;
  String? _currentRoomId;
  async_lib.StreamSubscription<DocumentSnapshot>? _roomSubscription;

  final User? currentUser = FirebaseAuth.instance.currentUser;
  String get myUid => currentUser?.uid ?? 'guest';
  String get myName => currentUser?.displayName ?? currentUser?.email?.split('@').first ?? 'طالب';
  String get myPhoto => currentUser?.photoURL ?? '';

  void _findOrCreateBattleRoom() async {
    setState(() => _isSearching = true);

    final battlesRef = FirebaseFirestore.instance
        .collection('question_bank')
        .doc('stage_${widget.stageIndex}')
        .collection('subjects')
        .doc(widget.subjectId)
        .collection('battle_rooms');

    final waitingRooms = await battlesRef.where('status', isEqualTo: 'waiting').get();

    String roomId;
    if (waitingRooms.docs.isNotEmpty) {
      roomId = waitingRooms.docs.first.id;
      // انضمام كـ player2 مع تهيئة بيانات النقاط الخاصة به
      await battlesRef.doc(roomId).update({
        'player2': myUid,
        'player2Name': myName,
        'player2Photo': myPhoto,
        'player2Score': 0,
        'player1Score': 0,
        'status': 'started',
      });
    } else {
      final setsSnapshot = await battlesRef.parent!.collection('question_sets').get();
      List<dynamic> allPoolQuestions = [];
      for (var doc in setsSnapshot.docs) {
        List qList = doc.data()['questions'] ?? [];
        allPoolQuestions.addAll(qList);
      }

      if (allPoolQuestions.length < 5) {
        setState(() => _isSearching = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('عذراً، لا توجد أسئلة كافية لبدء التحدي (يجب أن يكون هناك 5 أسئلة على الأقل)')),
          );
        }
        return;
      }

      allPoolQuestions.shuffle();
      int takeCount = min(10, allPoolQuestions.length);
      List selectedQuestions = allPoolQuestions.sublist(0, takeCount);

      for (var q in selectedQuestions) {
        List options = List.from(q['options']);
        String correctOptionText = options[q['correctIndex'] ?? 0];
        options.shuffle();
        int newCorrectIndex = options.indexOf(correctOptionText);
        q['options'] = options;
        q['correctIndex'] = newCorrectIndex;
      }

      // إنشاء الغرفة كـ player1
      final newRoom = await battlesRef.add({
        'player1': myUid,
        'player1Name': myName,
        'player1Photo': myPhoto,
        'player1Score': 0,
        'player2': null,
        'player2Name': '',
        'player2Photo': '',
        'player2Score': 0,
        'status': 'waiting',
        'questions': selectedQuestions,
        'createdAt': FieldValue.serverTimestamp(),
      });
      roomId = newRoom.id;
    }

    setState(() {
      _currentRoomId = roomId;
    });

    _roomSubscription = battlesRef.doc(roomId).snapshots().listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data() as Map<String, dynamic>;
      final status = data['status'];

      if (status == 'started') {
        _roomSubscription?.cancel();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ActiveQuizBattleScreen(
                roomId: roomId,
                isPlayer1: data['player1'] == myUid,
                roomData: data,
                subjectName: widget.subjectName,
              ),
            ),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    if (_currentRoomId != null && _isSearching) {
      FirebaseFirestore.instance
          .collection('question_bank')
          .doc('stage_${widget.stageIndex}')
          .collection('subjects')
          .doc(widget.subjectId)
          .collection('battle_rooms')
          .doc(_currentRoomId)
          .delete();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تحدي 1v1 - ${widget.subjectName}'),
        backgroundColor: AppColors.primary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isSearching
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.amber,
                              backgroundImage: myPhoto.isNotEmpty ? NetworkImage(myPhoto) : null,
                              child: myPhoto.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                            ),
                            const SizedBox(height: 8),
                            Text(myName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            children: [
                              const Text('VS', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                              const SizedBox(height: 4),
                              Text(widget.subjectName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Column(
                          children: const [
                            CircleAvatar(radius: 35, backgroundColor: Colors.blueGrey, child: Icon(Icons.person_search, size: 40, color: Colors.white)),
                            SizedBox(height: 8),
                            Text('جارِ البحث...', style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    const Text(
                      'انتظر لينضم زميلك لبدء التحدي...',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء البحث'),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sports_esports, size: 80, color: Colors.deepOrange),
                    const SizedBox(height: 20),
                    const Text(
                      'أهلاً بك في ساحة التحدي المباشر!',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'المادة: ${widget.subjectName}\nتحدى زملاءك في أسئلة عشوائية، من ينهي الأسئلة بدقة أسرع يفوز!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _findOrCreateBattleRoom,
                        child: const Text('بحث عن خصم / بدء التحدي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ==========================================
// 6. شاشة العد التنازلي التمهيدي قبل البدء (3 ثوانٍ متحركة)
// ==========================================

class BattleCountdownScreen extends StatefulWidget {
  final Map<String, dynamic> roomData;
  final bool isPlayer1;
  final String subjectName;
  final String roomId;

  const BattleCountdownScreen({
    super.key,
    required this.roomData,
    required this.isPlayer1,
    required this.subjectName,
    required this.roomId,
  });

  @override
  State<BattleCountdownScreen> createState() => _BattleCountdownScreenState();
}

class _BattleCountdownScreenState extends State<BattleCountdownScreen> with SingleTickerProviderStateMixin {
  int _counter = 3;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  async_lib.Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.3).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _animController.forward();

    _timer = async_lib.Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_counter > 1) {
        setState(() {
          _counter--;
        });
        _animController.reset();
        _animController.forward();
      } else {
        timer.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ActiveQuizBattleScreen(
              roomId: widget.roomId,
              isPlayer1: widget.isPlayer1,
              roomData: widget.roomData,
              subjectName: widget.subjectName,
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myName = widget.isPlayer1 ? widget.roomData['player1Name'] : widget.roomData['player2Name'];
    final oppName = widget.isPlayer1 ? widget.roomData['player2Name'] : widget.roomData['player1Name'];
    final myPhoto = widget.isPlayer1 ? widget.roomData['player1Photo'] : widget.roomData['player2Photo'];
    final oppPhoto = widget.isPlayer1 ? widget.roomData['player2Photo'] : widget.roomData['player1Photo'];

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('المعركة على وشك البدء!', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.amber,
                        backgroundImage: (myPhoto != null && myPhoto.isNotEmpty) ? NetworkImage(myPhoto) : null,
                        child: (myPhoto == null || myPhoto.isEmpty) ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                      ),
                      const SizedBox(height: 8),
                      Text(myName ?? 'أنت', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('VS', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.amber)),
                  ),
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.blueGrey,
                        backgroundImage: (oppPhoto != null && oppPhoto.isNotEmpty) ? NetworkImage(oppPhoto) : null,
                        child: (oppPhoto == null || oppPhoto.isEmpty) ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                      ),
                      const SizedBox(height: 8),
                      Text(oppName ?? 'الخصم', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 60),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Text(
                  '$_counter',
                  style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ),
              const SizedBox(height: 20),
              const Text('استعد للإجابة بسرعة وبدقة!', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 7. شاشة تفاعل التحدي الثنائي النشط (مع المزامنة الحية)
// ==========================================

class ActiveQuizBattleScreen extends StatefulWidget {
  final String roomId;
  final bool isPlayer1;
  final Map<String, dynamic> roomData;
  final String subjectName;

  const ActiveQuizBattleScreen({
    super.key,
    required this.roomId,
    required this.isPlayer1,
    required this.roomData,
    required this.subjectName,
  });

  @override
  State<ActiveQuizBattleScreen> createState() => _ActiveQuizBattleScreenState();
}

class _ActiveQuizBattleScreenState extends State<ActiveQuizBattleScreen> {
  int currentIndex = 0;
  int? selectedOptionIndex;
  bool answered = false;
  int myScore = 0;
  
  async_lib.Timer? _battleTimer;
  int _questionSeconds = 15;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _questionSeconds = 15;
    _battleTimer?.cancel();
    _battleTimer = async_lib.Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_questionSeconds > 0) {
        setState(() => _questionSeconds--);
      } else {
        timer.cancel();
        if (!answered) {
          _answerQuestion(-1);
        }
      }
    });
  }

  @override
  void dispose() {
    _battleTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _answerQuestion(int index) async {
    if (answered) return;
    _battleTimer?.cancel();

    HapticFeedback.mediumImpact();
    final questions = widget.roomData['questions'] ?? [];
    final correct = questions[currentIndex]['correctIndex'] ?? 0;
    
    if (index == correct) {
      myScore++;
      try {
        await _audioPlayer.play(AssetSource('sounds/correct.mp3'));
      } catch (_) {}
    } else {
      try {
        await _audioPlayer.play(AssetSource('sounds/wrong.mp3'));
      } catch (_) {}
    }

    setState(() {
      selectedOptionIndex = index;
      answered = true;
    });

    // تحديث نقاط اللاعب بشكل حي في Firestore لكي يراها الخصم فوراً
    if (widget.roomId.isNotEmpty) {
      final scoreField = widget.isPlayer1 ? 'player1Score' : 'player2Score';
      await FirebaseFirestore.instance
          .collection('question_bank')
          .doc(widget.roomData['stagePath'] ?? 'stage_1') // مسار افتراضي او معدل
          .collection('battle_rooms')
          .doc(widget.roomId)
          .update({scoreField: myScore});
    }
  }

  String _getOptionPrefix(int index) {
    const prefixes = ['أ.', 'ب.', 'ج.', 'د.'];
    return index < prefixes.length ? prefixes[index] : '${index + 1}.';
  }

  void _nextQuestion() async {
    final questions = widget.roomData['questions'] ?? [];
    if (currentIndex < questions.length - 1) {
      setState(() {
        currentIndex++;
        selectedOptionIndex = null;
        answered = false;
      });
      _startTimer();
    } else {
      _battleTimer?.cancel();
      
      // الانتقال لشاشة النتائج التفصيلية النهائية
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BattleResultsScreen(
              roomId: widget.roomId,
              isPlayer1: widget.isPlayer1,
              roomData: widget.roomData,
              myScore: myScore,
              totalQuestions: questions.length,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.roomData['questions'] ?? [];
    if (questions.isEmpty) return const Scaffold(body: Center(child: Text('لا توجد أسئلة')));

    final questionData = questions[currentIndex];
    final String questionText = questionData['question'] ?? '';
    final List options = questionData['options'] ?? [];
    final int correctIndex = questionData['correctIndex'] ?? 0;
    int total = questions.length;

    return StreamBuilder<DocumentSnapshot>(
      stream: widget.roomId.isNotEmpty 
          ? FirebaseFirestore.instance.collection('question_bank').doc(widget.roomData['stagePath'] ?? 'stage_1').collection('battle_rooms').doc(widget.roomId).snapshots()
          : null,
      builder: (context, snapshot) {
        Map<String, dynamic> liveData = widget.roomData;
        if (snapshot.hasData && snapshot.data!.exists) {
          liveData = snapshot.data!.data() as Map<String, dynamic>;
        }

        final myName = widget.isPlayer1 ? liveData['player1Name'] : liveData['player2Name'];
        final oppName = widget.isPlayer1 ? liveData['player2Name'] : liveData['player1Name'];
        final myPhoto = widget.isPlayer1 ? liveData['player1Photo'] : liveData['player2Photo'];
        final oppPhoto = widget.isPlayer1 ? liveData['player2Photo'] : liveData['player1Photo'];
        final oppScore = widget.isPlayer1 ? (liveData['player2Score'] ?? 0) : (liveData['player1Score'] ?? 0);

        return Scaffold(
          appBar: AppBar(
            title: Text('تحدي: ${widget.subjectName}'),
            backgroundColor: Colors.deepOrange,
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    '$_questionSeconds ث',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // شريط عرض النقاط الحية للطرفين
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.amber,
                              backgroundImage: (myPhoto != null && myPhoto.isNotEmpty) ? NetworkImage(myPhoto) : null,
                              child: (myPhoto == null || myPhoto.isEmpty) ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(myName ?? 'أنت', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text('نقاطك: $myScore', style: const TextStyle(fontSize: 11, color: Colors.green)),
                              ],
                            ),
                          ],
                        ),
                        const Text('VS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(oppName ?? 'الخصم', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                Text('نقاط الخصم: $oppScore', style: const TextStyle(fontSize: 11, color: Colors.blue)),
                              ],
                            ),
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.blueGrey,
                              backgroundImage: (oppPhoto != null && oppPhoto.isNotEmpty) ? NetworkImage(oppPhoto) : null,
                              child: (oppPhoto == null || oppPhoto.isEmpty) ? const Icon(Icons.person, size: 20, color: Colors.white) : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Chip(label: Text('نقاطك: $myScore'), backgroundColor: Colors.amber.shade100),
                    Chip(label: Text('السؤال ${currentIndex + 1}/$total'), backgroundColor: Colors.green.shade100),
                  ],
                ),
                const SizedBox(height: 15),
                Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      questionText,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      Color btnColor = Colors.white;
                      if (answered) {
                        if (index == correctIndex) {
                          btnColor = Colors.green.shade200;
                        } else if (index == selectedOptionIndex) {
                          btnColor = Colors.red.shade200;
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: btnColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            alignment: Alignment.centerRight,
                          ),
                          onPressed: () => _answerQuestion(index),
                          child: Text(
                            '${_getOptionPrefix(index)} ${options[index]}',
                            style: const TextStyle(fontSize: 16),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (answered)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _nextQuestion,
                    child: Text(
                      currentIndex == total - 1 ? 'عرض النتيجة النهائية' : 'السؤال التالي',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// 8. شاشة النتائج النهائية التفصيلية (Battle Results Screen)
// ==========================================

class BattleResultsScreen extends StatelessWidget {
  final String roomId;
  final bool isPlayer1;
  final Map<String, dynamic> roomData;
  final int myScore;
  final int totalQuestions;

  const BattleResultsScreen({
    super.key,
    required this.roomId,
    required this.isPlayer1,
    required this.roomData,
    required this.myScore,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    final myName = isPlayer1 ? roomData['player1Name'] : roomData['player2Name'];
    final oppName = isPlayer1 ? roomData['player2Name'] : roomData['player1Name'];
    final oppScore = isPlayer1 ? (roomData['player2Score'] ?? 0) : (roomData['player1Score'] ?? 0);

    String resultText = 'تعادل!';
    Color resultColor = Colors.orange;
    IconData resultIcon = Icons.balance;

    if (myScore > oppScore) {
      resultText = 'تهانينا، لقد فزت بالتحدي! 🎉';
      resultColor = Colors.green;
      resultIcon = Icons.emoji_events;
    } else if (myScore < oppScore) {
      resultText = 'حظاً أوفر، لقد خسرت المعركة 💔';
      resultColor = Colors.red;
      resultIcon = Icons.sentiment_dissatisfied;
    }

    double accuracy = totalQuestions > 0 ? (myScore / totalQuestions) * 100 : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('نتيجة التحدي النهائية'),
        backgroundColor: AppColors.primary,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(resultIcon, size: 80, color: resultColor),
            const SizedBox(height: 16),
            Text(
              resultText,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: resultColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('مقارنة النتائج', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$myName (أنت)', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('$myScore / $totalQuestions', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$oppName (الخصم)', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('$oppScore / $totalQuestions', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('نسبة الدقة لديك:'),
                        Text('${accuracy.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('العودة إلى الرئيسية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
 
