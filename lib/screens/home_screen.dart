import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  final String currentUserAccountName;
  final bool isAdmin;

  const HomeScreen({
    super.key,
    required this.currentUserAccountName,
    this.isAdmin = true, // مفعل للأدمن تلقائياً
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // -------------------------------------------------------------
  // إعدادات العداد التنازلي للحدث القريب (مثال: الامتحانات النهائية)
  // -------------------------------------------------------------
  final DateTime _targetEventDate = DateTime.now().add(const Duration(days: 12, hours: 5, minutes: 30));
  late Timer _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemainingTime();
    });
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    final difference = _targetEventDate.difference(now);
    if (mounted) {
      setState(() {
        _timeRemaining = difference.isNegative ? Duration.zero : difference;
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------
  // إضافة منشور جديد (خاص بالأدمن فقط)
  // -------------------------------------------------------------
  void _showAddPostDialog() {
    final TextEditingController contentController = TextEditingController();
    final TextEditingController titleController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16161C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إضافة منشور جديد 📢', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'عنوان المنشور / الإعلان',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E1E24),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'محتوى المنشور...',
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF1E1E24),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                  onPressed: () async {
                    if (contentController.text.trim().isNotEmpty) {
                      await FirebaseFirestore.instance.collection('posts').add({
                        'title': titleController.text.trim(),
                        'content': contentController.text.trim(),
                        'author': widget.currentUserAccountName,
                        'likes': 0,
                        'likedBy': [],
                        'savedBy': [],
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('نشر الآن', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // نافذة التعليقات
  // -------------------------------------------------------------
  void _showCommentsDialog(String postId) {
    final TextEditingController commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16161C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
              const Padding(
                padding: EdgeInsets.all(15),
                child: Text('التعليقات 💬', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const Divider(color: Colors.white10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(postId)
                      .collection('comments')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                    var comments = snapshot.data!.docs;
                    if (comments.isEmpty) {
                      return const Center(child: Text('لا توجد تعليقات بعد، كن أول المعلقين!', style: TextStyle(color: Colors.grey)));
                    }
                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        var c = comments[index].data() as Map<String, dynamic>;
                        return ListTile(
                          leading: const CircleAvatar(backgroundColor: Color(0xFF1E1E24), child: Icon(Icons.person, color: Color(0xFFD4AF37), size: 20)),
                          title: Text(c['userName'] ?? 'طالب', style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text(c['text'] ?? '', style: const TextStyle(color: Colors.white)),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'اكتب تعليقاً...',
                          hintStyle: const TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFF1E1E24),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: Color(0xFFD4AF37)),
                      onPressed: () async {
                        if (commentController.text.trim().isNotEmpty) {
                          await FirebaseFirestore.instance.collection('posts').doc(postId).collection('comments').add({
                            'userName': widget.currentUserAccountName,
                            'text': commentController.text.trim(),
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                          commentController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة الإعلانات والأخبار', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF121216),
        elevation: 0,
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddPostDialog,
              backgroundColor: const Color(0xFFD4AF37),
              icon: const Icon(Icons.add_rounded, color: Colors.black),
              label: const Text('إضافة منشور', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. شريط الإعلانات المتحرك (Ticker Bar)
            _buildTickerMarqueeBar(),

            const SizedBox(height: 15),

            // 2. كارت العداد التنازلي للحدث
            _buildCountdownWidget(),

            const SizedBox(height: 20),

            // 3. قسم المنشورات الأخبارية
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Icon(Icons.newspaper_rounded, color: Color(0xFFD4AF37), size: 22),
                  SizedBox(width: 8),
                  Text('المنشورات الرسمية', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // قائمة المنشورات الحية من Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                var posts = snapshot.data!.docs;

                if (posts.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    child: const Text('لا توجد منشورات حالياً', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    var post = posts[index];
                    var data = post.data() as Map<String, dynamic>;
                    List likedBy = data['likedBy'] ?? [];
                    List savedBy = data['savedBy'] ?? [];

                    bool isLiked = likedBy.contains(widget.currentUserAccountName);
                    bool isSaved = savedBy.contains(widget.currentUserAccountName);

                    return _buildPostCard(
                      postId: post.id,
                      author: data['author'] ?? 'الأدمن',
                      title: data['title'] ?? '',
                      content: data['content'] ?? '',
                      likesCount: likedBy.length,
                      isLiked: isLiked,
                      isSaved: isSaved,
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // تصميم شريط التلفاز المتحرك للاعلانات
  // -------------------------------------------------------------
  Widget _buildTickerMarqueeBar() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF1E1E24),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
            child: const Text('عاجل 🔴', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                '📢 تذكير: بدء التقديم على الامتحانات النهائية لجميع المراحل في كلية الحقوق - جامعة الموصل | برجاء مراجعة التسجيل قبل نهاية الأسبوع.',
                style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // تصميم العداد التنازلي المباشر
  // -------------------------------------------------------------
  Widget _buildCountdownWidget() {
    int days = _timeRemaining.inDays;
    int hours = _timeRemaining.inHours % 24;
    int minutes = _timeRemaining.inMinutes % 60;
    int seconds = _timeRemaining.inSeconds % 60;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF16161C), Color(0xFF22222A)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.timer_outlined, color: Color(0xFFD4AF37), size: 20),
              SizedBox(width: 8),
              Text(
                'الحدث القادم: الامتحانات الفصلية ⏳',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeUnit('$days', 'يوم'),
              _buildTimeUnit('$hours', 'ساعة'),
              _buildTimeUnit('$minutes', 'دقيقة'),
              _buildTimeUnit('$seconds', 'ثانية'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0F0F12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
          ),
          child: Text(
            value.padLeft(2, '0'),
            style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }

  // -------------------------------------------------------------
  // تصميم كارت المنشور (مثل الفيسبوك)
  // -------------------------------------------------------------
  Widget _buildPostCard({
    required String postId,
    required String author,
    required String title,
    required String content,
    required int likesCount,
    required bool isLiked,
    required bool isSaved,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16161C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFD4AF37),
                radius: 18,
                child: Icon(Icons.shield, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(author, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const Text('إعلان رسمي • الآن', style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
              const Spacer(),
              if (widget.isAdmin)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (title.isNotEmpty)
            Text(title, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
          const SizedBox(height: 15),
          const Divider(color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // زر الإعجاب (Like)
              InkWell(
                onTap: () async {
                  DocumentReference ref = FirebaseFirestore.instance.collection('posts').doc(postId);
                  if (isLiked) {
                    await ref.update({'likedBy': FieldValue.arrayRemove([widget.currentUserAccountName])});
                  } else {
                    await ref.update({'likedBy': FieldValue.arrayUnion([widget.currentUserAccountName])});
                  }
                },
                child: Row(
                  children: [
                    Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.redAccent : Colors.grey, size: 20),
                    const SizedBox(width: 6),
                    Text('$likesCount', style: TextStyle(color: isLiked ? Colors.redAccent : Colors.grey)),
                  ],
                ),
              ),

              // زر التعليقات (Comments)
              InkWell(
                onTap: () => _showCommentsDialog(postId),
                child: Row(
                  children: const [
                    Icon(Icons.mode_comment_outlined, color: Colors.grey, size: 20),
                    SizedBox(width: 6),
                    Text('تعليق', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),

              // زر الحفظ (Save)
              InkWell(
                onTap: () async {
                  DocumentReference ref = FirebaseFirestore.instance.collection('posts').doc(postId);
                  if (isSaved) {
                    await ref.update({'savedBy': FieldValue.arrayRemove([widget.currentUserAccountName])});
                  } else {
                    await ref.update({'savedBy': FieldValue.arrayUnion([widget.currentUserAccountName])});
                  }
                },
                child: Row(
                  children: [
                    Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: isSaved ? const Color(0xFFD4AF37) : Colors.grey, size: 20),
                    const SizedBox(width: 6),
                    Text(isSaved ? 'محفوظ' : 'حفظ', style: TextStyle(color: isSaved ? const Color(0xFFD4AF37) : Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
