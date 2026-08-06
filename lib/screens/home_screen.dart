import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  final String currentUserAccountName;
  final bool isAdmin;

  const HomeScreen({
    super.key,
    required this.currentUserAccountName,
    this.isAdmin = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late Timer _timer;
  Duration _timeRemaining = Duration.zero;
  String _eventName = 'الحدث القادم';

  @override
  void initState() {
    super.initState();
    _fetchEventData();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchEventData();
    });
  }

  // جلب وقت وتفاصيل الحدث التنازلي ديناميكياً من Firebase
  void _fetchEventData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('app_config').doc('event').get();
      if (doc.exists && doc.data() != null) {
        var data = doc.data() as Map<String, dynamic>;
        Timestamp? targetTimestamp = data['targetDate'];
        if (targetTimestamp != null && mounted) {
          DateTime targetDate = targetTimestamp.toDate();
          final difference = targetDate.difference(DateTime.now());
          setState(() {
            _eventName = data['eventName'] ?? 'الحدث القادم';
            _timeRemaining = difference.isNegative ? Duration.zero : difference;
          });
        }
      }
    } catch (e) {
      debugPrint("Event timer error: $e");
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------
  // نافذة لوحة تحكم الأدمن (للأخبار، الإعلانات، والعداد)
  // -------------------------------------------------------------
  void _showAdminControlPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16161C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('لوحة تحكم وتوجيه التطبيق 🛡️', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildAdminOptionTile(
                icon: Icons.campaign_rounded,
                title: 'تحديث الخبر العاجل',
                subtitle: 'تغيير الشريط المتحرك العلوي',
                onTap: () {
                  Navigator.pop(context);
                  _showUpdateNewsTickerDialog();
                },
              ),
              _buildAdminOptionTile(
                icon: Icons.timer_rounded,
                title: 'تعديل العداد التنازلي',
                subtitle: 'تعديل موعد واسم الحدث المباشر',
                onTap: () {
                  Navigator.pop(context);
                  _showUpdateEventDialog();
                },
              ),
              _buildAdminOptionTile(
                icon: Icons.post_add_rounded,
                title: 'إضافة منشور جديد',
                subtitle: 'نشر خبر أو إعلان في الخلاصة',
                onTap: () {
                  Navigator.pop(context);
                  _showAddPostDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminOptionTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: const Color(0xFF1E1E24), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFD4AF37)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  // تعديل الشريط العاجل
  void _showUpdateNewsTickerDialog() {
    final TextEditingController tickerController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161C),
        title: const Text('تحديث الشريط العاجل 🔴', style: TextStyle(color: Color(0xFFD4AF37))),
        content: TextField(
          controller: tickerController,
          maxLines: 2,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'اكتب نص الخبر العاجل...', hintStyle: TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () async {
              if (tickerController.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance.collection('app_config').doc('ticker').set({
                  'text': tickerController.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('حفظ التغيير', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // تعديل العداد التنازلي
  void _showUpdateEventDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController daysController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161C),
        title: const Text('تعديل الحدث والعداد ⏳', style: TextStyle(color: Color(0xFFD4AF37))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'اسم الحدث (مثال: بدء امتحانات الماستر)', labelStyle: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'عدد الأيام المتبقية من الآن', labelStyle: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () async {
              int days = int.tryParse(daysController.text.trim()) ?? 1;
              DateTime futureDate = DateTime.now().add(Duration(days: days));

              await FirebaseFirestore.instance.collection('app_config').doc('event').set({
                'eventName': nameController.text.trim().isEmpty ? 'الحدث القادم' : nameController.text.trim(),
                'targetDate': Timestamp.fromDate(futureDate),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('تحديث العداد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // إضافة منشور
  void _showAddPostDialog() {
    final TextEditingController contentController = TextEditingController();
    final TextEditingController titleController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16161C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('إضافة منشور جديد 📢', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: 'العنوان الرئيسي', labelStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: const Color(0xFF1E1E24), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(labelText: 'محتوى المنشور...', labelStyle: const TextStyle(color: Colors.grey), filled: true, fillColor: const Color(0xFF1E1E24), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
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
                  child: const Text('نشر الان', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
        title: const Text('منصة القانون الخاصة', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF121216),
        elevation: 0,
        actions: [
          if (widget.isAdmin)
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: Color(0xFFD4AF37)),
              onPressed: _showAdminControlPanel,
            ),
        ],
      ),
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton(
              onPressed: _showAdminControlPanel,
              backgroundColor: const Color(0xFFD4AF37),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.black, size: 28),
            )
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. الشريط العاجل الديناميكي
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('app_config').doc('ticker').snapshots(),
              builder: (context, snapshot) {
                String tickerText = 'مرحباً بكم في المنصة | ترقبوا أحدث الأخبار والفعاليات هنا.';
                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  tickerText = data['text'] ?? tickerText;
                }
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
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(tickerText, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.w500)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            // 2. العداد التنازلي المباشر للحدث
            _buildCountdownWidget(),

            const SizedBox(height: 20),

            // 3. خلاصة المنشورات
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Icon(Icons.dynamic_feed_rounded, color: Color(0xFFD4AF37), size: 22),
                  SizedBox(width: 8),
                  Text('الأخبار والمنشورات', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 10),

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
                              const CircleAvatar(backgroundColor: Color(0xFFD4AF37), radius: 18, child: Icon(Icons.star, color: Colors.black, size: 20)),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['author'] ?? 'منشئ المنصة', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  const Text('منشور رسمي', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                              const Spacer(),
                              if (widget.isAdmin)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance.collection('posts').doc(post.id).delete();
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if ((data['title'] ?? '').isNotEmpty)
                            Text(data['title'], style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(data['content'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4)),
                          const SizedBox(height: 15),
                          const Divider(color: Colors.white10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              InkWell(
                                onTap: () async {
                                  DocumentReference ref = FirebaseFirestore.instance.collection('posts').doc(post.id);
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
                                    Text('${likedBy.length}', style: TextStyle(color: isLiked ? Colors.redAccent : Colors.grey)),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () async {
                                  DocumentReference ref = FirebaseFirestore.instance.collection('posts').doc(post.id);
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
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

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
            children: [
              const Icon(Icons.timer_outlined, color: Color(0xFFD4AF37), size: 20),
              const SizedBox(width: 8),
              Text(
                'الحدث: $_eventName ⏳',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
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
}
