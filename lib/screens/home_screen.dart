import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
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
        if (mounted) {
          setState(() {
            _adminUsernameConfig = data['username'] ?? 'x9.ta9';
            _adminPasswordConfig = data['password'] ?? 'Abbas312004';
          });
        }
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

  void _openAdminSecurityPage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isSavedAdmin = prefs.getBool('is_admin_logged_in') ?? false;

    if (mounted) {
      if (isSavedAdmin) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminDashboardPage()));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (context) => AdminLoginPage(
          adminUsername: _adminUsernameConfig,
          adminPassword: _adminPasswordConfig,
          onLoginSuccess: () async {
            await prefs.setBool('is_admin_logged_in', true);
            if (mounted) {
              setState(() => isCurrentUserAdmin = true);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboardPage()));
            }
          },
        )));
      }
    }
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
            icon: const Icon(Icons.shield, color: Color(0xFFD4AF37), size: 28),
            onPressed: _openAdminSecurityPage,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
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

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF16161C),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFD4AF37),
                    backgroundImage: currentUserPhotoUrl.isNotEmpty ? NetworkImage(currentUserPhotoUrl) : null,
                    child: currentUserPhotoUrl.isEmpty ? const Icon(Icons.person, color: Colors.black) : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('أهلاً بك مجدداً 👋', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(widget.currentUserAccountName, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            if (_hasActiveEvent) _buildCountdownWidget(),

            const SizedBox(height: 20),

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
                    String postImage = data['imageUrl'] ?? '';

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
                            ],
                          ),
                          const SizedBox(height: 10),
                          if ((data['title'] ?? '').isNotEmpty) Text(data['title'], style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
                          if ((data['content'] ?? '').isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(data['content'] ?? '', style: const TextStyle(color: Colors.white70)),
                          ],
                          if (postImage.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(postImage, fit: BoxFit.cover, width: double.infinity, height: 200),
                            ),
                          ],
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
      backgroundColor: const Color(0xFF0F0F12),
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
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  void _showAddPostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    File? selectedImage;
    bool isUploading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16161C),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 20, left: 20, right: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('إضافة منشور جديد 📢', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(controller: titleController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'العنوان (اختياري)', labelStyle: TextStyle(color: Colors.grey))),
                  const SizedBox(height: 10),
                  TextField(controller: contentController, maxLines: 3, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'محتوى النص...', labelStyle: TextStyle(color: Colors.grey))),
                  const SizedBox(height: 15),
                  if (selectedImage != null)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(selectedImage!, height: 120, width: double.infinity, fit: BoxFit.cover)),
                        IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => setModalState(() => selectedImage = null)),
                      ],
                    )
                  else
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFD4AF37))),
                      onPressed: () async {
                        final picker = ImagePicker();
                        final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                        if (img != null) {
                          setModalState(() => selectedImage = File(img.path));
                        }
                      },
                      icon: const Icon(Icons.image, color: Color(0xFFD4AF37)),
                      label: const Text('إضافة صورة من المعرض', style: TextStyle(color: Color(0xFFD4AF37))),
                    ),
                  const SizedBox(height: 20),
                  isUploading
                      ? const CircularProgressIndicator(color: Color(0xFFD4AF37))
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                            onPressed: () async {
                              if (contentController.text.trim().isNotEmpty || selectedImage != null) {
                                setModalState(() => isUploading = true);
                                try {
                                  String imageUrl = '';
                                  if (selectedImage != null) {
                                    String path = 'posts/${DateTime.now().millisecondsSinceEpoch}.jpg';
                                    UploadTask task = FirebaseStorage.instance.ref().child(path).putFile(selectedImage!);
                                    TaskSnapshot snap = await task;
                                    imageUrl = await snap.ref.getDownloadURL();
                                  }
                                  await FirebaseFirestore.instance.collection('posts').add({
                                    'title': titleController.text.trim(),
                                    'content': contentController.text.trim(),
                                    'imageUrl': imageUrl,
                                    'author': currentUserAccountName,
                                    'authorPhoto': currentUserPhotoUrl,
                                    'likedBy': [],
                                    'timestamp': FieldValue.serverTimestamp(),
                                  });
                                  if (mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('تم نشر المنشور بنجاح ✅'), backgroundColor: Colors.green),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    setModalState(() => isUploading = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('حدث خطأ أثناء النشر: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              }
                            },
                            child: const Text('نشر المنشور', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                        ),
                ],
              ),
            ),
          );
        },
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
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف الخبر العاجل 🗑️')));
              }
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
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الخبر العاجل بنجاح 🔴')));
                }
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
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء الحدث التنازلي 🗑️')));
              }
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
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تفعيل العداد التنازلي بنجاح ⏳')));
              }
            },
            child: const Text('تفعيل / حفظ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showChangeAdminCredentialsDialog() {
    final newUser = TextEditingController();
    final newPass = TextEditingController();
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
            TextField(controller: newPass, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'رمز الأمان الجديد', labelStyle: TextStyle(color: Colors.grey))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () async {
              if (newUser.text.trim().isNotEmpty && newPass.text.trim().isNotEmpty) {
                await FirebaseFirestore.instance.collection('app_config').doc('admin_credentials').set({
                  'username': newUser.text.trim(),
                  'password': newPass.text.trim(),
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث بيانات الدخول بنجاح 🔑')));
                }
              }
            },
            child: const Text('حفظ البيانات', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة التحكم المركزية 🛡️', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF121216),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: 'تسجيل الخروج من صلاحية الأدمن',
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('is_admin_logged_in');
              setState(() => isCurrentUserAdmin = false);
              if (mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDashCard(Icons.add_photo_alternate, 'إضافة منشور جديد', 'نشر صورة، كابشن أو كلاهما للطلاب', _showAddPostDialog),
            _buildDashCard(Icons.campaign, 'إدارة الشريط العاجل', 'إضافة / تعديل / حذف الشريط العاجل', _showTickerManager),
            _buildDashCard(Icons.timer, 'إدارة العداد التنازلي', 'إضافة / تعديل / حذف الحدث التنازلي', _showEventManager),
            _buildDashCard(Icons.lock_reset, 'تغيير رمز بيانات الأدمن', 'تحديث اليوزر وباسوورد لوحة التحكم', _showChangeAdminCredentialsDialog),
            
            const SizedBox(height: 25),
            const Text('طلبات تغيير اسم المستخدم 📩', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('username_requests').where('status', isEqualTo: 'pending').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                var docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(15),
                    child: const Text('لا توجد طلبات معلقة حالياً', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var req = docs[index];
                    var data = req.data() as Map<String, dynamic>;
                    String targetUserId = data['userId'] ?? '';
                    String newUsername = data['requestedUsername'] ?? '';

                    return Card(
                      color: const Color(0xFF1E1E24),
                      child: ListTile(
                        title: Text('${data['currentName']} (@${data['oldUsername']})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text('المطلوب: @$newUsername\nالسبب: ${data['reason'] ?? 'لا يوجد'}', style: const TextStyle(color: Colors.grey)),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green, size: 28),
                              onPressed: () async {
                                if (targetUserId.isNotEmpty && newUsername.isNotEmpty) {
                                  await FirebaseFirestore.instance.collection('users').doc(targetUserId).update({'username': newUsername});
                                }
                                await req.reference.update({'status': 'approved'});
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الموافقة وتحديث اليوزر بنجاح ✅'), backgroundColor: Colors.green));
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red, size: 28),
                              onPressed: () async {
                                await req.reference.update({'status': 'rejected'});
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفض الطلب ❌'), backgroundColor: Colors.orange));
                                }
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

            const SizedBox(height: 25),
            const Text('إدارة المنشورات (الحذف المباشر) 🗑️', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                var posts = snapshot.data!.docs;
                if (posts.isEmpty) return const Text('لا توجد منشورات لحذفها', style: TextStyle(color: Colors.grey));

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    var post = posts[index];
                    var data = post.data() as Map<String, dynamic>;
                    return Card(
                      color: const Color(0xFF16161C),
                      child: ListTile(
                        title: Text(data['title'] ?? data['content'] ?? 'منشور', style: const TextStyle(color: Colors.white)),
                        subtitle: Text('بقلم: ${data['author']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            await FirebaseFirestore.instance.collection('posts').doc(post.id).delete();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المنشور 🗑️')));
                            }
                          },
                        ),
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

  Widget _buildDashCard(IconData icon, String title, String sub, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF16161C), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFFD4AF37)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(su
