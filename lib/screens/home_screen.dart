import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_colors.dart';
import '../models/post_model.dart';
import '../routes/app_routes.dart';
import 'admin_panel_screen.dart';
import 'profile_screen.dart';
import 'user_profile_view_screen.dart';

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

  // متحكمات حركة شريط الإعلانات الأخبار
  late ScrollController _tickerScrollController;
  Timer? _tickerTimer;

  final TextEditingController _searchController = TextEditingController();

  List<String> _announcements = [
    "مرحباً بكم في منصة القانون - النسخة الرسمية!  •  تنويه: سيتم فتح التسجيل في الاختبارات الإلكترونية قريباً.  •  نتمنى لجميع الطلبة الموفقية والنجاح.",
  ];

  // قائمة محادثات تجريبية للدردشة
  final List<Map<String, dynamic>> _chatList = [
    {
      'username': 'ahmed_legal',
      'fullName': 'أحمد علي',
      'lastMessage': 'السلام عليكم، هل لديك ملازم المرحلة الثالثة؟',
      'time': '10:30 ص',
      'bio': 'باحث قانوني متقدم',
      'messages': [
        {'sender': 'ahmed_legal', 'text': 'السلام عليكم، هل لديك ملازم المرحلة الثالثة؟', 'time': '10:30 ص'},
      ]
    },
    {
      'username': 'sara_lawyer',
      'fullName': 'سارة محمود',
      'lastMessage': 'شكراً جزيلاً لك',
      'time': 'أمس',
      'bio': 'طالبة قانون - المرحلة الرابعة',
      'messages': [
        {'sender': 'me', 'text': 'تم إرسال الملف القانوني', 'time': 'أمس'},
        {'sender': 'sara_lawyer', 'text': 'شكراً جزيلاً لك', 'time': 'أمس'},
      ]
    },
  ];

  // 1. التبليغات الرسمية (تظهر بالرئيسية فقط)
  List<PostModel> _officialPosts = [
    PostModel(
      id: '1',
      author: 'إدارة منصة القانون',
      username: 'admin',
      content: 'نرحب بجميع الطلبة في منصة القانون الإلكترونية التعليمية.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      likes: 12,
    )
  ];

  // 2. منشورات المستخدمين الشخصية
  List<PostModel> _userPosts = [];

  // قاعدة بيانات تجريبية للمستخدمين للبحث عنهم
  final List<Map<String, String>> _allUsers = [
    {
      'username': 'abbas_law',
      'fullName': 'سيدعباس عقيل الحسيني',
      'bio': 'طالب في كلية القانون | مهتم بالتشريعات والدراسات القانونية'
    },
    {
      'username': 'ahmed_legal',
      'fullName': 'أحمد علي',
      'bio': 'باحث قانوني متقدم'
    },
    {
      'username': 'sara_lawyer',
      'fullName': 'سارة محمود',
      'bio': 'طالبة قانون - المرحلة الرابعة'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadPin();
    _startTimer();
    _tickerScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTickerAnimation();
    });
  }

  void _startTickerAnimation() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_tickerScrollController.hasClients) {
        double maxScroll = _tickerScrollController.position.maxScrollExtent;
        double currentScroll = _tickerScrollController.offset;
        if (currentScroll >= maxScroll) {
          _tickerScrollController.jumpTo(0);
        } else {
          _tickerScrollController.jumpTo(currentScroll + 1.5);
        }
      }
    });
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
    _tickerTimer?.cancel();
    _tickerScrollController.dispose();
    _searchController.dispose();
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
          posts: _officialPosts,
          announcements: _announcements,
          onAddPost: (content, imageFile) {
            setState(() {
              _officialPosts.insert(
                0,
                PostModel(
                  id: DateTime.now().toString(),
                  author: 'إدارة منصة القانون',
                  username: 'admin',
                  content: content,
                  imageFile: imageFile,
                  timestamp: DateTime.now(),
                ),
              );
            });
          },
          onDeletePost: (index) {
            setState(() { _officialPosts.removeAt(index); });
          },
          onEditPost: (index, newContent) {
            setState(() { _officialPosts[index].content = newContent; });
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

  // فتح صفحة المستخدم كزائر
  void _openUserProfile(Map<String, String> user) {
    List<PostModel> filteredPosts = _userPosts
        .where((p) => p.username == user['username'])
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileViewScreen(
          username: user['username']!,
          fullName: user['fullName']!,
          bio: user['bio'] ?? '',
          userPosts: filteredPosts,
        ),
      ),
    );
  }
  // نافذة البحث عن المستخدمين
  void _showUserSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String query = "";
        return StatefulBuilder(
          builder: (context, setDialogState) {
            List<Map<String, String>> searchResults = _allUsers.where((u) {
              return u['username']!.toLowerCase().contains(query.toLowerCase()) ||
                     u['fullName']!.contains(query);
            }).toList();

            return AlertDialog(
              backgroundColor: AppColors.cardBg,
              title: const Text('البحث عن مستخدم 🔍', style: TextStyle(color: AppColors.accent)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'ادخل اسم المستخدم (مثال: abbas_law)...',
                        prefixIcon: Icon(Icons.search, color: AppColors.accent),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          query = val;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 200,
                      child: searchResults.isEmpty
                          ? const Center(child: Text('لا يوجد مستخدم بهذا الاسم', style: TextStyle(color: Colors.white54)))
                          : ListView.builder(
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                final user = searchResults[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.accent,
                                    child: Text(user['fullName']![0], style: const TextStyle(color: Colors.black)),
                                  ),
                                  title: Text(user['fullName']!),
                                  subtitle: Text('@${user['username']}', style: const TextStyle(color: AppColors.accent)),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _openUserProfile(user);
                                  },
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منصة القانون'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.accent),
            onPressed: _showUserSearchDialog,
            tooltip: 'البحث عن مستخدم',
          ),
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
          _buildChatTab(), // تبويب الدردشة والمحادثات
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
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'الدردشة'),
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
          if (_announcements.isNotEmpty) _buildAnnouncementsTicker(),
          if (_announcements.isNotEmpty) const SizedBox(height: 16),
          if (_targetDuration != null) _buildCountdownCard(),
          if (_targetDuration != null) const SizedBox(height: 20),
          const Text('التبليغات الرسمية والتحديثات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.accent)),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _officialPosts.length,
            itemBuilder: (context, index) => _buildPostCard(_officialPosts[index]),
          ),
        ],
      ),
    );
  }

  // شريط الإعلانات الأخبار المتحرك تلقائياً
  Widget _buildAnnouncementsTicker() {
    String combinedText = _announcements.join("                  ");
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign, color: AppColors.accent),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              controller: _tickerScrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Text(
                combinedText,
                style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // تبويب قائمة الدردشات
  Widget _buildChatTab() {
    return _chatList.isEmpty
        ? const Center(
            child: Text(
              'لا توجد محادثات حتى الآن.\nيمكنك البحث عن زملائك ومراسلتهم!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: _chatList.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white10),
            itemBuilder: (context, index) {
              final chat = _chatList[index];
              return ListTile(
                tileColor: AppColors.cardBg, // 👈 تم التصحيح هنا واستبدال backgroundColor بـ tileColor
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: GestureDetector(
                  onTap: () {
                    _openUserProfile({
                      'username': chat['username'],
                      'fullName': chat['fullName'],
                      'bio': chat['bio'] ?? '',
                    });
                  },
                  child: CircleAvatar(
                    backgroundColor: AppColors.accent,
                    child: Text(
                      chat['fullName'][0],
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                title: Text(chat['fullName'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                subtitle: Text(chat['lastMessage'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70)),
                trailing: Text(chat['time'], style: const TextStyle(color: Colors.white38, fontSize: 12)),
                onTap: () {
                  _openUserProfile({
                    'username': chat['username'],
                    'fullName': chat['fullName'],
                    'bio': chat['bio'] ?? '',
                  });
                },
              );
            },
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.author, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('@${post.username}', style: const TextStyle(fontSize: 11, color: AppColors.accent)),
                  ],
                ),
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
                    posts: _userPosts,
                    onAddUserPost: (content, imageFile) {
                      setState(() {
                        _userPosts.insert(
                          0,
                          PostModel(
                            id: DateTime.now().toString(),
                            author: 'سيدعباس عقيل الحسيني',
                            username: 'abbas_law',
                            content: content,
                            imageFile: imageFile,
                            timestamp: DateTime.now(),
                          ),
                        );
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
