import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  String _adminUsernameConfig = 'x9.ta9';
  String _adminPasswordConfig = 'Abbas312004';

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
      debugPrint("Admin config error: $e");
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
      debugPrint("Event error: $e");
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // -------------------------------------------------------------
  // البوابة الآمنة الفخمة (صفحة كاملة)
  // -------------------------------------------------------------
  void _openAdminSecurityPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isSavedAdmin = prefs.getBool('is_admin_logged_in') ?? false;

    if (isSavedAdmin) {
      _showAdminControlPanel();
    } else {
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminLoginPage(
          adminUsername: _adminUsernameConfig,
          adminPassword: _adminPasswordConfig,
          onLoginSuccess: () async {
            await prefs.setBool('is_admin_logged_in', true);
            setState(() {
              isCurrentUserAdmin = true;
            });
            if (mounted) {
              Navigator.pop(context);
              _showAdminControlPanel();
            }
          },
        )));
      }
    }
  }
    // لوحة التحكم المركزية
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('لوحة التحكم والتوجيه المركزية 🛡️', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    tooltip: 'قفل صلاحية الأدمن',
                    onPressed: () async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.remove('is_admin_logged_in');
                      setState(() => isCurrentUserAdmin = false);
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildAdminTile(Icons.campaign, 'إدارة الشريط العاجل', 'إضافة / تعديل / حذف الخبر العاجل', () {
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

  void _showTickerManager() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16161C),
        title: const Text('إدارة الشريط العاجل 🔴', style: TextStyle(color: Color(0xFFD4AF37))),
        content: TextField(controller: textController, maxLines: 2, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'اكتب نص الخبر الجديد...', hintStyle: TextStyle(color: Colors.grey))),
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

  void _showUsernameRequestsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16161C),
      builder: (context) => Container(
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
                          subtitle: Text('المطلوب: @${data['requestedUsername']}\nالسبب: ${data['reason']}', style: const TextStyle(color: Colors.grey)),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () async {
                                await FirebaseFirestore.instance.collection('users').doc(data['userId']).update({'username': data['requestedUsername']});
                                await req.reference.update({'status': 'approved'});
                              }),
                              IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () async {
                                await req.reference.update({'status': 'rejected'});
                              }),
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
      ),
    );
  }

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
                      'author': currentUserAccountName,
                      'authorPhoto': currentUserPhotoUrl,
                      'likedBy': [],
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
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1E1E24),
                          backgroundImage: (c['userPhoto'] ?? '').isNotEmpty ? NetworkImage(c['userPhoto']) : null,
                          child: (c['userPhoto'] ?? '').isEmpty ? const Icon(Icons.person, color: Color(0xFFD4AF37)) : null,
                        ),
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
                          'userName': currentUserAccountName,
                          'userPhoto': currentUserPhotoUrl,
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
            icon: const Icon(Icons.shield, color: Color(0xFFD4AF37)),
            onPressed: _openAdminSecurityPage,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAdminSecurityPage,
        backgroundColor: const Color(0xFFD4AF37),
        child: const Icon(Icons.admin_panel_settings, color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. شريط أخبار التلفاز المتحرك تلقائياً
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('app_config').doc('ticker').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  String text = data['text'] ?? '';
                  if (text.isNotEmpty) {
                    return Container(
                      height: 42,
                      width: double.infinity,
                      color: const Color(0xFF1E1E24),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            color: Colors.redAccent.shade700,
                            child: const Text('عاجل 🔴', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            child: MarqueeTickerText(text: text),
                          ),
                        ],
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
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
                    bool isLiked = likedBy.contains(currentUserAccountName);

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF16161C), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.05))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFFD4AF37),
                                radius: 18,
                                backgroundImage: (data['authorPhoto'] ?? '').isNotEmpty ? NetworkImage(data['authorPhoto']) : null,
                                child: (data['authorPhoto'] ?? '').isEmpty ? const Icon(Icons.star, color: Colors.black, size: 18) : null,
                              ),
                              const SizedBox(width: 10),
                              Text(data['author'] ?? 'منشئ المنصة', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                              InkWell(
                                onTap: () async {
                                  DocumentReference ref = FirebaseFirestore.instance.collection('posts').doc(post.id);
                                  if (isLiked) {
                                    await ref.update({'likedBy': FieldValue.arrayRemove([currentUserAccountName])});
                                  } else {
                                    await ref.update({'likedBy': FieldValue.arrayUnion([currentUserAccountName])});
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
// -------------------------------------------------------------
// شريط أخبار التلفاز التلقائي الحركة
// -------------------------------------------------------------
class MarqueeTickerText extends StatefulWidget {
  final String text;
  const MarqueeTickerText({super.key, required this.text});

  @override
  State<MarqueeTickerText> createState() => _MarqueeTickerTextState();
}

class _MarqueeTickerTextState extends State<MarqueeTickerText> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    while (_scrollController.hasClients) {
      await Future.delayed(const Duration(seconds: 1));
      if (_scrollController.hasClients) {
        double maxExtent = _scrollController.position.maxScrollExtent;
        await _scrollController.animateTo(
          maxExtent,
          duration: Duration(seconds: (maxExtent / 30).clamp(5, 30).toInt()),
          curve: Curves.linear,
        );
        await Future.delayed(const Duration(seconds: 1));
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(widget.text, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// البوابة الآمنة - صفحة دخولية فخمة ومستقلة
// -------------------------------------------------------------
class AdminLoginPage extends StatefulWidget {
  final String adminUsername;
  final String adminPassword;
  final VoidCallback onLoginSuccess;

  const AdminLoginPage({
    super.key,
    required this.adminUsername,
    required this.adminPassword,
    required this.onLoginSuccess,
  });

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();

  void _verifyLogin() {
    if (_userController.text.trim() == widget.adminUsername && _passController.text.trim() == widget.adminPassword) {
      widget.onLoginSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('عذراً، غير مصرح لك بالدخول إلى لوحة التحكم والتوجيه ❌'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0F12), Color(0xFF1E1E2A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(25),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161C),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 20, spreadRadius: 2),
                    ],
                  ),
                  child: const Icon(Icons.security, size: 60, color: Color(0xFFD4AF37)),
                ),
                const SizedBox(height: 25),
                const Text('البوابة الآمنة لرئاسة المنصة', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('منطقة مخصصة للتحكم والإدارة المركزية فقط', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 35),
                TextField(
                  controller: _userController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'اسم المستخدم (اليوزر)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.person_pin, color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: const Color(0xFF16161C),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'رمز الأمان الحصري',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFFD4AF37)),
                    filled: true,
                    fillColor: const Color(0xFF16161C),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: _verifyLogin,
                    child: const Text('مصادقة ودخول', style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('العودة للواجهة الرئيسية', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
