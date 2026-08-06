import 'dart:async';
import 'package:flutter/material.dart';

// --- Data Models ---
class NewsBanner {
  final String id;
  final String title;
  final String imageUrl;

  NewsBanner({required this.id, required this.title, required this.imageUrl});
}

class EventData {
  String title;
  DateTime targetDate;

  EventData({required this.title, required this.targetDate});
}

class PostComment {
  final String userName;
  final String text;
  final DateTime date;

  PostComment({required this.userName, required this.text, required this.date});
}

class AppPost {
  final String id;
  String content;
  final DateTime createdAt;
  bool isPinned;
  int likesCount;
  bool isLiked;
  List<PostComment> comments;

  AppPost({
    required this.id,
    required this.content,
    required this.createdAt,
    this.isPinned = false,
    this.likesCount = 0,
    this.isLiked = false,
    List<PostComment>? comments,
  }) : comments = comments ?? [];
}

// --- Auth Credentials ---
const String kAdminUsername = "admin";
const String kAdminPassword = "123456";
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State Data
  EventData currentEvent = EventData(
    title: "بدأ الدوام الرسمي للمرحلة الثانية ⏳",
    targetDate: DateTime.now().add(const Duration(days: 44, hours: 23, minutes: 58, seconds: 3)),
  );

  List<NewsBanner> banners = [
    NewsBanner(id: '1', title: 'عاجل: السلام عليكم طلاب هذا منستكم ان شاء الله', imageUrl: ''),
  ];

  List<AppPost> posts = [];

  void _showLoginDialog() {
    final userController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.security, color: Colors.amber),
            SizedBox(width: 10),
            Text('البوابة الآمنة 🛡️', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'اسم المستخدم',
                labelStyle: const TextStyle(color: Colors.amber),
                enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.amber), borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.amberAccent), borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'كلمة السر',
                labelStyle: const TextStyle(color: Colors.amber),
                enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.amber), borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.amberAccent), borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              if (userController.text == kAdminUsername && passController.text == kAdminPassword) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminDashboardScreen(
                      eventData: currentEvent,
                      posts: posts,
                      banners: banners,
                      onUpdate: () => setState(() {}),
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('بيانات الدخول غير صحيحة!'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('دخول', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sort posts (Pinned first)
    posts.sort((a, b) => (b.isPinned ? 1 : 0).compareTo(a.isPinned ? 1 : 0));

    return Scaffold(
      backgroundColor: const Color(0xFF121218),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('منصة القانون الخاصة ⚖️', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLoginDialog,
        backgroundColor: Colors.amber,
        icon: const Icon(Icons.shield, color: Colors.black),
        label: const Text('البوابة الآمنة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banners Section
            if (banners.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.redAccent)),
                child: Row(
                  children: [
                    const Icon(Icons.campaign, color: Colors.redAccent),
                    const SizedBox(width: 8),
                    Expanded(child: Text(banners.last.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Event Countdown Widget
            EventCountdownWidget(event: currentEvent),
            const SizedBox(height: 25),

            // Posts Header
            const Text('الأخبار والمنشورات 📜', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            // Posts List
            posts.isEmpty
                ? const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('لا توجد منشورات حالياً', style: TextStyle(color: Colors.grey))))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: posts.length,
                    itemBuilder: (context, index) => PostCard(post: posts[index], onStateChange: () => setState(() {})),
                  ),
          ],
        ),
      ),
    );
  }
}
class EventCountdownWidget extends StatefulWidget {
  final EventData event;
  const EventCountdownWidget({Key? key, required this.event}) : super(key: key);

  @override
  State<EventCountdownWidget> createState() => _EventCountdownWidgetState();
}

class _EventCountdownWidgetState extends State<EventCountdownWidget> {
  late Timer _timer;
  Duration _difference = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      setState(() {
        _difference = widget.event.targetDate.isAfter(now) ? widget.event.targetDate.difference(now) : Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(widget.event.title, style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _timeBox(_difference.inDays.toString().padLeft(2, '0'), 'يوم'),
              _timeBox((_difference.inHours % 24).toString().padLeft(2, '0'), 'ساعة'),
              _timeBox((_difference.inMinutes % 60).toString().padLeft(2, '0'), 'دقيقة'),
              _timeBox((_difference.inSeconds % 60).toString().padLeft(2, '0'), 'ثانية'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeBox(String time, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber)),
          child: Text(time, style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

// --- Post Card (Facebook-Like) ---
class PostCard extends StatelessWidget {
  final AppPost post;
  final VoidCallback onStateChange;

  const PostCard({Key? key, required this.post, required this.onStateChange}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E2C),
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (post.isPinned)
              Row(
                children: const [
                  Icon(Icons.push_pin, color: Colors.amber, size: 16),
                  SizedBox(width: 5),
                  Text('منشور مثبت', style: TextStyle(color: Colors.amber, fontSize: 12)),
                ],
              ),
            Text(post.content, style: const TextStyle(color: Colors.white, fontSize: 15)),
            const Divider(color: Colors.white12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    post.isLiked = !post.isLiked;
                    post.isLiked ? post.likesCount++ : post.likesCount--;
                    onStateChange();
                  },
                  icon: Icon(post.isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, color: post.isLiked ? Colors.amber : Colors.grey),
                  label: Text('${post.likesCount} إعجاب', style: const TextStyle(color: Colors.grey)),
                ),
                TextButton.icon(
                  onPressed: () => _showCommentsDialog(context),
                  icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                  label: Text('${post.comments.length} تعليق', style: const TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentsDialog(BuildContext context) {
    final commentController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2C),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('التعليقات', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: post.comments.length,
                itemBuilder: (context, i) => ListTile(
                  title: Text(post.comments[i].userName, style: const TextStyle(color: Colors.amber)),
                  subtitle: Text(post.comments[i].text, style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'اكتب تعليقاً...', hintStyle: TextStyle(color: Colors.grey)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.amber),
                  onPressed: () {
                    if (commentController.text.isNotEmpty) {
                      post.comments.add(PostComment(userName: 'طالب', text: commentController.text, date: DateTime.now()));
                      commentController.clear();
                      onStateChange();
                      Navigator.pop(context);
                    }
                  },
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
class AdminDashboardScreen extends StatefulWidget {
  final EventData eventData;
  final List<AppPost> posts;
  final List<NewsBanner> banners;
  final VoidCallback onUpdate;

  const AdminDashboardScreen({
    Key? key,
    required this.eventData,
    required this.posts,
    required this.banners,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _postController = TextEditingController();
  final _eventTitleController = TextEditingController();
  final _bannerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _eventTitleController.text = widget.eventData.title;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121218),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('لوحة سيطرة البوابة الآمنة 👑', style: TextStyle(color: Colors.amber)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Control Event Countdown
            _buildAdminSection(
              title: 'تعديل الحدث القادم (العداد)',
              child: Column(
                children: [
                  TextField(
                    controller: _eventTitleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'عنوان الحدث', labelStyle: TextStyle(color: Colors.amber)),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                    onPressed: () {
                      setState(() {
                        widget.eventData.title = _eventTitleController.text;
                        widget.eventData.targetDate = DateTime.now().add(const Duration(days: 30)); // إضافة شهر مثالاً
                      });
                      widget.onUpdate();
                    },
                    child: const Text('تحديث بيانات الحدث', style: TextStyle(color: Colors.black)),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Control News Banner
            _buildAdminSection(
              title: 'إضافة إعلان عاجل',
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _bannerController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'اكتب الشريط الإخباري...', hintStyle: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.amber),
                    onPressed: () {
                      if (_bannerController.text.isNotEmpty) {
                        setState(() {
                          widget.banners.add(NewsBanner(id: DateTime.now().toString(), title: _bannerController.text, imageUrl: ''));
                          _bannerController.clear();
                        });
                        widget.onUpdate();
                      }
                    },
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Create & Manage Posts
            _buildAdminSection(
              title: 'إنشاء منشور جديد',
              child: Column(
                children: [
                  TextField(
                    controller: _postController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'اكتب المنشور هنا...', hintStyle: TextStyle(color: Colors.grey)),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                    icon: const Icon(Icons.publish, color: Colors.black),
                    label: const Text('نشر الآن', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      if (_postController.text.isNotEmpty) {
                        setState(() {
                          widget.posts.insert(0, AppPost(id: DateTime.now().toString(), content: _postController.text, createdAt: DateTime.now()));
                          _postController.clear();
                        });
                        widget.onUpdate();
                      }
                    },
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Manage Existing Posts List
            const Text('إدارة المنشورات الحالية', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.posts.length,
              itemBuilder: (context, i) {
                final p = widget.posts[i];
                return ListTile(
                  title: Text(p.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(p.isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: Colors.amber),
                        onPressed: () {
                          setState(() => p.isPinned = !p.isPinned);
                          widget.onUpdate();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () {
                          setState(() => widget.posts.removeAt(i));
                          widget.onUpdate();
                        },
                      ),
                    ],
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSection({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFF1E1E2C), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
