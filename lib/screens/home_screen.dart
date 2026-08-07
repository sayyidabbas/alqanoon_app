import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../models/post_model.dart';
import '../routes/app_routes.dart';
import 'admin_panel_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _adminPin = "1234"; 

  Duration? _targetDuration = const Duration(days: 20, hours: 19, minutes: 58, seconds: 33);
  Timer? _countdownTimer;

  List<String> _announcements = [
    "مرحباً بكم في منصة القانون - النسخة الرسمية!",
    "تنويه: سيتم فتح التسجيل في الاختبارات الإلكترونية قريباً.",
  ];

  List<PostModel> _posts = [
    PostModel(
      id: '1',
      author: 'سيدعباس عقيل الحسيني',
      content: 'نرحب بجميع الطلبة في منصة القانون الإلكترونية التعليمية.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      likes: 12,
    )
  ];

  @override
  void initState() {
    super.initState();
    _loadPin();
    _startTimer();
  }

  void _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminPin = prefs.getString('admin_pin') ?? "1234";
    });
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    if (_targetDuration == null) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_targetDuration != null && _targetDuration!.inSeconds > 0) {
        setState(() {
          _targetDuration = _targetDuration! - const Duration(seconds: 1);
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _openAdminGate() async {
    final prefs = await SharedPreferences.getInstance();
    bool isAlreadyLoggedIn = prefs.getBool('is_admin_logged_in') ?? false;

    if (isAlreadyLoggedIn) {
      _navigateToAdminPanel();
    } else {
      _showPinDialog();
    }
  }

  void _showPinDialog() {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('البوابة الآمنة 🔒', style: TextStyle(color: AppColors.accent)),
        content: TextField(
          controller: pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'أدخل رمز PIN'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
            onPressed: () async {
              if (pinController.text == _adminPin) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('is_admin_logged_in', true);
                if (mounted) {
                  Navigator.pop(context);
                  _navigateToAdminPanel();
                }
              }
            },
            child: const Text('دخول', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _navigateToAdminPanel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminPanelScreen(
          posts: _posts,
          announcements: _announcements,
          onAddPost: (content, imageFile) {
            setState(() {
              _posts.insert(0, PostModel(id: DateTime.now().toString(), author: 'سيدعباس عقيل الحسيني', content: content, imageFile: imageFile, timestamp: DateTime.now()));
            });
          },
          onDeletePost: (index) {
            setState(() { _posts.removeAt(index); });
          },
          onEditPost: (index, newContent) {
            setState(() { _posts[index].content = newContent; });
          },
          onAddBanner: (banner) {
            setState(() { _announcements.add(banner); });
          },
          onDeleteBanner: (index) {
            setState(() { _announcements.removeAt(index); });
          },
          onUpdateTimerDays: (days) {
            setState(() { _targetDuration = Duration(days: days); });
            _startTimer();
          },
          onDeleteTimer: () {
            setState(() { _targetDuration = null; });
            _countdownTimer?.cancel();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة القانون'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: TextButton.icon(
              style: TextButton.styleFrom(backgroundColor: AppColors.accent.withOpacity(0.2)),
              onPressed: _openAdminGate,
              icon: const Icon(Icons.admin_panel_settings, color: AppColors.accent, size: 20),
              label: const Text('البوابة الآمنة', style: TextStyle(color: AppColors.accent, fontSize: 12)),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildMainHomeTab(),
          _buildServicesTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppColors.accent,
        unselectedItemColor: Colors.white54,
        backgroundColor: AppColors.primary,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'الرئيسية'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'الخدمات'),
        ],
      ),
    );
  }

  Widget _buildMainHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_announcements.isNotEmpty) _buildAnnouncementsBanner(),
          if (_announcements.isNotEmpty) const SizedBox(height: 16),
          if (_targetDuration != null) _buildCountdownCard(),
          if (_targetDuration != null) const SizedBox(height: 20),
          const Text('المنشورات والتحديثات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accent)),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _posts.length,
            itemBuilder: (context, index) => _buildPostCard(_posts[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsBanner() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.accent.withOpacity(0.3))),
      child: Row(
        children: [
          const Icon(Icons.campaign, color: AppColors.accent),
          const SizedBox(width: 10),
          Expanded(
            child: PageView.builder(
              itemCount: _announcements.length,
              itemBuilder: (context, index) => Align(
                alignment: Alignment.centerRight,
                child: Text(_announcements[index], style: const TextStyle(fontSize: 14, color: Colors.white), overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountdownCard() {
    if (_targetDuration == null) return const SizedBox();
    String days = _targetDuration!.inDays.toString().padLeft(2, '0');
    String hours = (_targetDuration!.inHours % 24).toString().padLeft(2, '0');
    String minutes = (_targetDuration!.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (_targetDuration!.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          const Text('الوقت المتبقي لحدث منصة القانون القادم ⏳', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _timerUnit(days, 'يوم'),
              _timerUnit(hours, 'ساعة'),
              _timerUnit(minutes, 'دقيقة'),
              _timerUnit(seconds, 'ثانية'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timerUnit(String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(8)),
          child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.accent)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white60)),
      ],
    );
  }

  Widget _buildPostCard(PostModel post) {
    return Card(
      color: AppColors.cardBg,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.accent,
                  child: Text(post.author.isNotEmpty ? post.author[0] : 'ع', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Text(post.author, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            if (post.content.isNotEmpty) Text(post.content, style: const TextStyle(fontSize: 15)),
            if (post.imageFile != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(post.imageFile!, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
            const Divider(color: Colors.white10, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      post.isLiked = !post.isLiked;
                      post.likes += post.isLiked ? 1 : -1;
                    });
                  },
                  icon: Icon(post.isLiked ? Icons.favorite : Icons.favorite_border, color: post.isLiked ? Colors.red : Colors.white60),
                  label: Text('${post.likes} إعجاب', style: const TextStyle(color: Colors.white60)),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.comment_outlined, color: Colors.white60),
                  label: Text('${post.comments.length} تعليق', style: const TextStyle(color: Colors.white60)),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildServicesTab() {
    List<Map<String, dynamic>> services = [
      {'icon': Icons.menu_book, 'title': 'المكتبة القانونية'},
      {'icon': Icons.book, 'title': 'المواد الدراسية'},
      {'icon': Icons.quiz, 'title': 'بنك الأسئلة'},
      {'icon': Icons.assignment, 'title': 'الاختبارات الإلكترونية'},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.3),
        itemCount: services.length,
        itemBuilder: (context, index) => Card(
          color: AppColors.cardBg,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(services[index]['icon'], size: 40, color: AppColors.accent),
              const SizedBox(height: 8),
              Text(services[index]['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.cardBg,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: AppColors.primary),
            accountName: Text('سيدعباس عقيل الحسيني'),
            accountEmail: Text('abbas@lawplatform.com'),
            currentAccountPicture: CircleAvatar(backgroundColor: AppColors.accent, child: Icon(Icons.person, size: 40, color: Colors.black)),
          ),
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.accent),
            title: const Text('الملف الشخصي'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    posts: _posts,
                    onAddUserPost: (content, imageFile) {
                      setState(() {
                        _posts.insert(0, PostModel(id: DateTime.now().toString(), author: 'سيدعباس عقيل الحسيني', content: content, imageFile: imageFile, timestamp: DateTime.now()));
                      });
                    },
                  ),
                ),
              );
            },
          ),
          ListTile(leading: const Icon(Icons.settings, color: AppColors.accent), title: const Text('الإعدادات'), onTap: () {}),
          ListTile(leading: const Icon(Icons.info, color: AppColors.accent), title: const Text('حول التطبيق'), onTap: () {}),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.redAccent)),
            onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
          ),
        ],
      ),
    );
  }
}
