import 'dart:async' as async_lib;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('بنك الأسئلة'),
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

  @override
  Widget build(BuildContext context) {
    final stages = ['المرحلة الأولى', 'المرحلة الثانية', 'المرحلة الثالثة', 'المرحلة الرابعة'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة بنك الأسئلة (الأدمن)'),
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
              final subjectName = data['name'] ?? '';
              final subjectId = docs[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subjectName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          icon: const Icon(Icons.menu_book, size: 18),
                          label: const Text('اختبار فردي', style: TextStyle(fontSize: 14)),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentQuestionSetsScreen(
                                  stageIndex: stageIndex,
                                  subjectId: subjectId,
                                  subjectName: subjectName,
                                ),
                              ),
                            );
                          },
                        ),
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
    super.dispose();
  }

  void _answerQuestion(int index) {
    if (answered) return;
    _timer?.cancel();
    setState(() {
      selectedOptionIndex = index;
      answered = true;
      final correct = widget.questions[currentIndex]['correctIndex'] ?? 0;
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
