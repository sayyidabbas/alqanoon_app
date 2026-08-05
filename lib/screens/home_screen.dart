import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  final String currentUserAccountName;
  const HomeScreen({super.key, required this.currentUserAccountName});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _bgAnimationController;
  String _selectedCategoryFilter = 'الكل';
  bool isAdmin = false;

  List<String> legalQuotesList = [
    '« لا جَرِيمَةَ وَلا عُقُوبَةَ إِلاّ بينَصٍّ »',
    '« العقد شريعة المتعاقدين »',
    '« المتهم بيء حتى تثبت إدانته »',
  ];
  int currentQuoteIndex = 0;

  List<Map<String, dynamic>> countdownEventsList = [
    {'title': 'امتحانات الكورس الأول', 'days': 12, 'icon': Icons.hourglass_top},
    {'title': 'المحاكمة الصورية', 'days': 5, 'icon': Icons.gavel},
  ];

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgAnimationController.dispose();
    super.dispose();
  }

  // التحقق من صلاحيات الأدمن للحساب الحالية
  Future<void> _checkAdminStatus() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          var data = userDoc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              isAdmin = (data['role'] == 'admin');
            });
          }
        }
      } catch (e) {
        debugPrint("Error checking admin status: $e");
      }
    }
  }

  // لوحة تحكم الأدمن لإدارة المقولات والأحداث
  void _showAdminControlPanel() {
    final quoteCtrl = TextEditingController();
    final eventTitleCtrl = TextEditingController();
    final eventDaysCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('لوحة إدارة الصفحة الرئيسية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              const Text('إضافة مقولة قانونية جديدة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: quoteCtrl,
                decoration: const InputDecoration(hintText: 'أدخل النص القانوني...', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                onPressed: () {
                  if (quoteCtrl.text.trim().isNotEmpty) {
                    setState(() {
                      legalQuotesList.add('« ${quoteCtrl.text.trim()} »');
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('إضافة المقولة'),
              ),
              const SizedBox(height: 16),
              const Text('إضافة حدث عد تنازلي جديد:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: eventTitleCtrl,
                decoration: const InputDecoration(hintText: 'عنوان الحدث (مثلاً: الامتحانات)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: eventDaysCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'عدد الأيام المتبقية', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                onPressed: () {
                  int? days = int.tryParse(eventDaysCtrl.text.trim());
                  if (eventTitleCtrl.text.trim().isNotEmpty && days != null) {
                    setState(() {
                      countdownEventsList.add({
                        'title': eventTitleCtrl.text.trim(),
                        'days': days,
                        'icon': Icons.event,
                      });
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('إضافة الحدث'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showComments(String docId, List comments) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final commentController = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: 400,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const Text('التعليقات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                Expanded(
                  child: comments.isEmpty
                      ? const Center(child: Text('لا توجد تعليقات بعد'))
                      : ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (context, i) {
                            final comment = comments[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF1A1A1A),
                                child: Text(
                                  (comment['userName'] ?? 'س')[0].toUpperCase(),
                                  style: const TextStyle(color: Color(0xFFD4AF37)),
                                ),
                              ),
                              title: Text(comment['userName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text(comment['text'] ?? ''),
                            );
                          },
                        ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          hintText: 'اكتب تعليقاً...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Color(0xFFD4AF37)),
                      onPressed: () async {
                        if (commentController.text.trim().isNotEmpty) {
                          List updated = List.from(comments);
                          updated.add({
                            'userName': widget.currentUserAccountName,
                            'text': commentController.text.trim(),
                          });
                          await FirebaseFirestore.instance.collection('posts').doc(docId).update({'comments': updated});
                          commentController.clear();
                          if (mounted) Navigator.pop(context);
                        }
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _addPost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final titleController = TextEditingController();
        final contentController = TextEditingController();
        String selectedType = 'أخبار الكلية';

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('نشر جديد مع وصف', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'العنوان', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: contentController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'الوصف أو المحتوى النصي', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('نوع النشر: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedType,
                        items: ['تبليغ رسمى', 'أخبار الكلية', 'جداول الامتحانات']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setModalState(() {
                              selectedType = v;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37), foregroundColor: Colors.black),
                    onPressed: () async {
                      if (titleController.text.isNotEmpty) {
                        await FirebaseFirestore.instance.collection('posts').add({
                          'author': widget.currentUserAccountName,
                          'title': titleController.text,
                          'content': contentController.text,
                          'type': selectedType,
                          'timeAgo': 'الآن',
                          'isNew': true,
                          'likes': 0,
                          'comments': [],
                          'timestamp': DateTime.now().millisecondsSinceEpoch,
                        });
                        if (mounted) Navigator.pop(context);
                      }
                    },
                    child: const Text('نشر التبليغ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة القانون - الرئيسية'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        actions: [
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings, color: Color(0xFFD4AF37)),
              tooltip: 'إدارة الصفحة الرئيسية',
              onPressed: _showAdminControlPanel,
            ),
        ],
      ),
      // زر "نشر جديد" يظهر فقط عندما يكون حساب المستخدم أدمن
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: const Color(0xFFD4AF37),
              foregroundColor: Colors.black,
              onPressed: _addPost,
              icon: const Icon(Icons.add_alert_rounded),
              label: const Text('نشر جديد'),
            )
          : null,
      body: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.03, end: 0.08).animate(_bgAnimationController),
              child: const Center(child: Icon(Icons.gavel_rounded, size: 320, color: Color(0xFFD4AF37))),
            ),
          ),
          Column(
            children: [
              if (legalQuotesList.isNotEmpty)
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFD4AF37)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          legalQuotesList[currentQuoteIndex],
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.navigate_next, color: Colors.white, size: 20),
                        onPressed: () {
                          setState(() {
                            currentQuoteIndex = (currentQuoteIndex + 1) % legalQuotesList.length;
                          });
                        },
                      )
                    ],
                  ),
                ),

              if (countdownEventsList.isNotEmpty)
                SizedBox(
                  height: 45,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: countdownEventsList.length,
                    itemBuilder: (context, idx) {
                      final evt = countdownEventsList[idx];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            Icon(evt['icon'] as IconData, size: 16, color: Colors.black),
                            const SizedBox(width: 6),
                            Text('⌛ ${evt['title']}: متبقي ${evt['days']} يوماً', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Row(
                  children: ['الكل', 'تبليغ رسمى', 'أخبار الكلية', 'جداول الامتحانات'].map((cat) {
                    bool isSel = _selectedCategoryFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        selectedColor: const Color(0xFFD4AF37),
                        onSelected: (val) {
                          setState(() {
                            _selectedCategoryFilter = cat;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('posts').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                    }
                    var docs = snapshot.data?.docs ?? [];
                    if (_selectedCategoryFilter != 'الكل') {
                      docs = docs.where((doc) => (doc.data() as Map<String, dynamic>)['type'] == _selectedCategoryFilter).toList();
                    }

                    var sortedDocs = docs.toList()
                      ..sort((a, b) {
                        var aTime = (a.data() as Map<String, dynamic>)['timestamp'] ?? 0;
                        var bTime = (b.data() as Map<String, dynamic>)['timestamp'] ?? 0;
                        return bTime.compareTo(aTime);
                      });

                    if (sortedDocs.isEmpty) {
                      return const Center(child: Text('لا توجد منشورات حالياً'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: sortedDocs.length,
                      itemBuilder: (context, index) {
                        var doc = sortedDocs[index];
                        var post = doc.data() as Map<String, dynamic>;
                        String docId = doc.id;
                        List comments = post['comments'] ?? [];
                        int likes = post['likes'] ?? 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFF1A1A1A),
                                      child: Text((post['author'] ?? 'س')[0].toUpperCase(), style: const TextStyle(color: Color(0xFFD4AF37))),
                                    ),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(post['author'] ?? 'مجهول', style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(post['timeAgo'] ?? 'الآن', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    ),
                                    const Spacer(),
                                    // أيقونة الحذف تظهر فقط للأدمن
                                    if (isAdmin)
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                        onPressed: () {
                                          FirebaseFirestore.instance.collection('posts').doc(docId).delete();
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(post['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                Text(post['content'] ?? '', textDirection: TextDirection.rtl),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        FirebaseFirestore.instance.collection('posts').doc(docId).update({'likes': likes + 1});
                                      },
                                      icon: const Icon(Icons.favorite_border, color: Colors.red),
                                      label: Text('$likes إعجاب'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _showComments(docId, comments),
                                      icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                                      label: Text('${comments.length} تعليق'),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
