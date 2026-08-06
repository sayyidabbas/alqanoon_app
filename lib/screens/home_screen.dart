import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  final String currentUserAccountName;
  final bool isAdmin;

  const HomeScreen({
    super.key,
    required this.currentUserAccountName,
    required this.isAdmin,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _timer;
  Duration _timeRemaining = Duration.zero;
  String _eventName = '';
  bool _hasActiveEvent = false;

  // كلمة السر واليوزر الافتراضيان للأدمن
  String _adminUsernameConfig = 'x9.ta9';
  String _adminPasswordConfig = 'Abbas312004';
  bool _isAdminLoggedInSession = false;

  @override
  void initState() {
    super.initState();
    _fetchAdminCredentials();
    _fetchEventData();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fetchEventData();
    });
  }

  void _fetchAdminCredentials() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('app_config').doc('admin_credentials').get();
      if (doc.exists && doc.data() != null) {
        var data = doc.data() as Map<String, dynamic>;
        setState(() {
          _adminUsernameConfig = data['username'] ?? 'x9.ta9';
          _adminPasswordConfig = data['password'] ?? 'Abbas312004';
        });
      }
    } catch (e) {
      debugPrint("Credentials fetch error: $e");
    }
  }

  void _fetchEventData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('app_config').doc('event').get();
      if (doc.exists && doc.data() != null) {
        var data = doc.data() as Map<String, dynamic>;
        bool active = data['active'] ?? false;
        Timestamp? targetTimestamp = data['targetDate'];

        if (active && targetTimestamp != null && mounted) {
          DateTime targetDate = targetTimestamp.toDate();
          final difference = targetDate.difference(DateTime.now());
          setState(() {
            _hasActiveEvent = true;
            _eventName = data['eventName'] ?? 'الحدث القادم';
            _timeRemaining = difference.isNegative ? Duration.zero : difference;
          });
        } else if (mounted) {
          setState(() => _hasActiveEvent = false);
        }
      } else if (mounted) {
        setState(() => _hasActiveEvent = false);
      }
    } catch (e) {
      debugPrint("Event fetch error: $e");
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------
  // المصادقة والحماية للوحة التحكم
  // -------------------------------------------------------------
  void _accessAdminPanel() {
    if (_isAdminLoggedInSession || currentUsername == _adminUsernameConfig) {
      _showAdminControlPanel();
      return;
    }

    final userController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161C),
        title: const Text('تسجيل دخول لوحة التحكم 🛡️', style: TextStyle(color: Color(0xFFD4AF37))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'اسم المستخدم (اليوزر)', labelStyle: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'كلمة المرور', labelStyle: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () {
              if (userController.text.trim() == _adminUsernameConfig && passController.text.trim() == _adminPasswordConfig) {
                setState(() {
                  _isAdminLoggedInSession = true;
                  isCurrentUserAdmin = true;
                });
                Navigator.pop(context);
                _showAdminControlPanel();
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('عذراً، غير مصرح لك بالدخول إلى لوحة التحكم والتوجيه ❌'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('دخول', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
    // -------------------------------------------------------------
  // لوحة التحكم الموحدة والشاملة
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
              const Text('لوحة التحكم والتوجيه المركزية 🛡️', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildAdminTile(Icons.campaign, 'إدارة الشريط العاجل', 'إضافة / تعديل / حذف الخبر', () {
                Navigator.pop(context);
                _showTickerManager();
              }),
              _buildAdminTile(Icons.timer, 'إدارة العداد التنازلي', 'إضافة / تعديل / حذف الحدث', () {
                Navigator.pop(context);
                _showEventManager();
              }),
              _buildAdminTile(Icons.add_comment, 'إضافة منشور جديد', 'نشر في الخلاصة الرئيسية', () {
                Navigator.pop(context);
                _showAddPostDialog();
              }),
              _buildAdminTile(Icons.manage_accounts, 'طلبات تغيير اسم المستخدم', 'الموافقة أو الرفض على الطلبات', () {
                Navigator.pop(context);
                _showUsernameRequestsDialog();
              }),
              _buildAdminTile(Icons.security, 'تغيير بيانات دخول الأدمن', 'تعديل اليوزر والباسوورد', () {
                Navigator.pop(context);
                _showChangeAdminCredentialsDialog();
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminTile(IconData icon, String title, String sub, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: const Color(0xFF1E1E24), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFD4AF37)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  // إدارة الشريط العاجل
  void _showTickerManager() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161C),
        title: const Text('إدارة الشريط العاجل 🔴', style: TextStyle(color: Color(0xFFD4AF37))),
        content: TextField(
          controller: textController,
          maxLines: 2,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'اكتب نص الخبر الجديد...', hintStyle: TextStyle(color: Colors.grey)),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('app_config').doc('ticker').delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('حذف العاجل 🗑️', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () async {
              if (textController.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance.collection('app_config').doc('ticker').set({
                  'text': textController.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('حفظ / نشر', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // إدارة العداد
  void _showEventManager() {
    final nameController = TextEditingController();
    final daysController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161C),
        title: const Text('إدارة العداد التنازلي ⏳', style: TextStyle(color: Color(0xFFD4AF37))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'اسم الحدث', labelStyle: TextStyle(color: Colors.grey))),
            const SizedBox(height: 10),
            TextField(controller: daysController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'عدد الأيام من الآن', labelStyle: TextStyle(color: Colors.grey))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('app_config').doc('event').set({'active': false});
              if (mounted) Navigator.pop(context);
            },
            child: const Text('حذف الحدث 🗑️', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () async {
              int days = int.tryParse(daysController.text.trim()) ?? 1;
              DateTime futureDate = DateTime.now().add(Duration(days: days));
              await FirebaseFirestore.instance.collection('app_config').doc('event').set({
                'eventName': nameController.text.trim().isEmpty ? 'الحدث القادم' : nameController.text.trim(),
                'targetDate': Timestamp.fromDate(futureDate),
                'active': true,
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('تفعيل / حفظ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // إدارة طلبات تغيير اليوزر
  void _showUsernameRequestsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16161C),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              const Text('طلبات تغيير اسم المستخدم 📩', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white10),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('username_requests').where('status', isEqualTo: 'pending').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                    var docs = snapshot.data!.docs;
                    if (docs.isEmpty) return const Center(child: Text('لا توجد طلبات معلقة حالياً', style: TextStyle(color: Colors.grey)));

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        var req = docs[index];
                        var data = req.data() as Map<String, dynamic>;

                        return Card(
                          color: const Color(0xFF1E1E24),
                          child: ListTile(
                            title: Text('${data['currentName']} (@${data['oldUsername']})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('اليوزر المطلوب: @${data['requestedUsername']}\nالسبب: ${data['reason']}', style: const TextStyle(color: Colors.grey)),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  onPressed: () async {
                                    // قبول الطلب وتحديث يوزر الطالب
                                    await FirebaseFirestore.instance.collection('users').doc(data['userId']).update({'username': data['requestedUsername']});
                                    await req.reference.update({'status': 'approved'});
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () async {
                                    // رفض الطلب
                                    await req.reference.update({'status': 'rejected'});
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
              ),
            ],
          ),
        );
      },
    );
  }

  // تغيير يوزر وباسوورد الأدمن
  void _showChangeAdminCredentialsDialog() {
    final newUser = TextEditingController(text: _adminUsernameConfig);
    final newPass = TextEditingController(text: _adminPasswordConfig);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161C),
        title: const Text('تغيير بيانات دخول الأدمن 🔑', style: TextStyle(color: Color(0xFFD4AF37))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: newUser, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'اليوزر الجديد', labelStyle: TextStyle(color: Colors.grey))),
            const SizedBox(height: 10),
            TextField(controller: newPass, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة', labelStyle: TextStyle(color: Colors.grey))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('app_config').doc('admin_credentials').set({
                'username': newUser.text.trim(),
                'password': newPass.text.trim(),
              });
              setState(() {
                _adminUsernameConfig = newUser.text.trim();
                _adminPasswordConfig = newPass.text.trim();
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('حفظ البيانات', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // إضافة منشور
  void _showAddPostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16161C),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('إضافة منشور جديد 📢', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(controller: titleController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'العنوان', labelStyle: TextStyle(color: Colors.grey))),
            const SizedBox(height: 10),
            TextField(controller: contentController, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'المحتوى...', labelStyle: TextStyle(color: Colors.grey))),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                onPressed: () async {
                  if (contentController.text.trim().isNotEmpty) {
                    await FirebaseFirestore.instance.collection('posts').add({
                      'title': titleController.text.trim(),
                      'content': contentController.text.trim(),
                      'author': widget.currentUserAccountName,
                      'likedBy': [],
                      'savedBy': [],
                      'timestamp': FieldValue.serverTimestamp(),
                    });
                    if (mounted) Navigator.pop(context);
                  }
                },
                child: const Text('نشر', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // عرض التعليقات مثل الفيسبوك
  void _showCommentsDialog(String postId) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16161C),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            const Padding(padding: EdgeInsets.all(12), child: Text('التعليقات 💬', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold))),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('posts').doc(postId).collection('comments').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                  var comments = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      var c = comments[index].data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(c['userName'] ?? 'طالب', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text(c['text'] ?? '', style: const TextStyle(color: Colors.white)),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'اكتب تعليقاً...', hintStyle: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Color(0xFFD4AF37)),
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
      ),
    );
  }
    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة القانون الخاصة', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF121216),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFFD4AF37)),
            onPressed: _accessAdminPanel,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _accessAdminPanel,
        backgroundColor: const Color(0xFFD4AF37),
        child: const Icon(Icons.admin_panel_settings, color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. الشريط العاجل الديناميكي
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('app_config').doc('ticker').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  String text = data['text'] ?? '';
                  if (text.isNotEmpty) {
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
                              child: Text(text, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.w500)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                }
                return const SizedBox.shrink(); // إخفاء الشريط إذا تم حذفه
              },
            ),

            const SizedBox(height: 15),

            // 2. العداد التنازلي للحدث
            if (_hasActiveEvent) _buildCountdownWidget(),

            const SizedBox(height: 20),

            // 3. خلاصة المنشورات
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: const [
                  Icon(Icons.dynamic_feed, color: Color(0xFFD4AF37), size: 22),
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
                if (posts.isEmpty) return const Padding(padding: EdgeInsets.all(40), child: Text('لا توجد منشورات حالياً', style: TextStyle(color: Colors.grey)));

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    var post = posts[index];
                    var data = post.data() as Map<String, dynamic>;
                    List likedBy = data['likedBy'] ?? [];
                    bool isLiked = likedBy.contains(widget.currentUserAccountName);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF16161C), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(backgroundColor: Color(0xFFD4AF37), radius: 16, child: Icon(Icons.star, color: Colors.black, size: 18)),
                              const SizedBox(width: 10),
                              Text(data['author'] ?? 'الأدمن', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              if (isCurrentUserAdmin)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                  onPressed: () async => await FirebaseFirestore.instance.collection('posts').doc(post.id).delete(),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if ((data['title'] ?? '').isNotEmpty) Text(data['title'], style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text(data['content'] ?? '', style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 15),
                          const Divider(color: Colors.white10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // زر الإعجاب
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
                                    Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.redAccent : Colors.grey, size: 18),
                                    const SizedBox(width: 4),
                                    Text('${likedBy.length}', style: TextStyle(color: isLiked ? Colors.redAccent : Colors.grey)),
                                  ],
                                ),
                              ),

                              // زر التعليقات مثل الفيسبوك
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance.collection('posts').doc(post.id).collection('comments').snapshots(),
                                builder: (context, commentSnap) {
                                  int count = commentSnap.hasData ? commentSnap.data!.docs.length : 0;
                                  return InkWell(
                                    onTap: () => _showCommentsDialog(post.id),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.mode_comment_outlined, color: Colors.grey, size: 18),
                                        const SizedBox(width: 4),
                                        Text('$count تعليق', style: const TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                                  );
                                },
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
          Text('الحدث: $_eventName ⏳', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
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

  Widget _buildTimeUnit(String val, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFF0F0F12), borderRadius: BorderRadius.circular(8)),
          child: Text(val.padLeft(2, '0'), style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }
}
