import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; 
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../constants/app_colors.dart';
import '../models/post_model.dart';
import '../routes/app_routes.dart';
import 'profile_screen.dart';
import 'user_profile_view_screen.dart';
import 'settings_screen.dart';
import '../widgets/notification_bell.dart'; 
import 'secure_admin_dashboard_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  Duration? _targetDuration;
  Timer? _countdownTimer;

  late ScrollController _tickerScrollController;
  Timer? _tickerTimer;

  final TextEditingController _searchController = TextEditingController();

  final List<String> _announcements = [];
  final List<PostModel> _officialPosts = []; // نحتفظ بها لتمريرها للوحة الإدارة
  final List<Map<String, dynamic>> _blockedUsers = [];
  final List<PostModel> _userPosts = [];

  // متغيرات لتحميل الملفات
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadingTitle = '';

  @override
  void initState() {
    super.initState();
    _tickerScrollController = ScrollController();
    _listenToFirebaseData(); // دالة ربط التطبيق بفايربيس
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startTickerAnimation();
    });
    _setupFCMToken();
  }

  // ==========================================
  // الربط اللحظي بقاعدة بيانات فايربيس
  // ==========================================
  void _listenToFirebaseData() {
    // 1. جلب الإعلانات (Ticker)
    FirebaseFirestore.instance.collection('settings').doc('announcements').snapshots().listen((doc) {
      if (mounted && doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('texts')) {
          setState(() {
            _announcements.clear();
            _announcements.addAll(List<String>.from(data['texts']));
          });
        }
      }
    });

    // 2. جلب وقت الحدث (Timer)
    FirebaseFirestore.instance.collection('settings').doc('timer').snapshots().listen((doc) {
      if (mounted && doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('targetDate')) {
          Timestamp ts = data['targetDate'];
          DateTime target = ts.toDate();
          Duration diff = target.difference(DateTime.now());
          setState(() {
            _targetDuration = diff.isNegative ? Duration.zero : diff;
          });
          _startTimer();
        }
      } else {
        setState(() {
          _targetDuration = null;
        });
      }
    });
  }

  Future<void> _setupFCMToken() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      FirebaseMessaging messaging = FirebaseMessaging.instance;
      String? token = await messaging.getToken();
      
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set(
          {'fcmToken': token},
          SetOptions(merge: true), 
        );
      }

      messaging.onTokenRefresh.listen((newToken) async {
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set(
          {'fcmToken': newToken},
          SetOptions(merge: true),
        );
      });
      
    } catch (e) {
      debugPrint('خطأ أثناء إعداد الـ FCM Token: $e');
    }
  }

  ImageProvider? _getProfileImage(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      return MemoryImage(base64Decode(url.split(',').last));
    }
    return NetworkImage(url);
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'الآن';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return '';
    }
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أسابيع';
    return '${date.day}/${date.month}/${date.year}';
  }

  void _startTickerAnimation() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_tickerScrollController.hasClients && _tickerScrollController.position.hasContentDimensions) {
        double maxScroll = _tickerScrollController.position.maxScrollExtent;
        double currentScroll = _tickerScrollController.offset;
        if (currentScroll >= maxScroll) {
          _tickerScrollController.jumpTo(0);
        } else {
          _tickerScrollController.jumpTo(currentScroll + 1.2);
        }
      }
    });
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    if (_targetDuration == null) return;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_targetDuration != null && _targetDuration!.inSeconds > 0) {
        if (mounted) {
          setState(() {
            _targetDuration = _targetDuration! - const Duration(seconds: 1);
          });
        }
      } else {
        _countdownTimer?.cancel();
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

  // ==========================================
  // تحميل وفتح الملفات المرفقة
  // ==========================================
  Future<void> _downloadAndOpenPdf(String rawUrl, String title) async {
    if (rawUrl.isEmpty) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final safeTitle = title.replaceAll(RegExp(r'[^\w\s]+'), '_');
      final filePath = '${directory.path}/$safeTitle.pdf';
      final fileExists = await File(filePath).exists();

      if (fileExists) {
        final result = await OpenFilex.open(filePath);
        if (result.type != ResultType.done && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر فتح الملف: ${result.message}')));
        }
        return;
      }

      setState(() {
        _isDownloading = true;
        _downloadProgress = 0.0;
        _downloadingTitle = title;
      });

      final dio = Dio();
      await dio.download(
        rawUrl.trim(),
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      setState(() {
        _isDownloading = false;
      });

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر فتح الملف: ${result.message}')));
      }
    } catch (e) {
      setState(() { _isDownloading = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء التنزيل: $e')));
    }
  }

  // ==========================================
  // نافذة التعليقات للتبليغات الرسمية
  // ==========================================
  void _showOfficialCommentsModal(BuildContext context, String postId) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 16, left: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 15),
              const Text('التعليقات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              SizedBox(
                height: 350,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('official_posts').doc(postId).collection('comments').orderBy('timestamp', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                    final comments = snapshot.data!.docs;
                    if (comments.isEmpty) return const Center(child: Text('لا توجد تعليقات بعد. كن أول من يعلق!', style: TextStyle(color: Colors.white54)));

                    return ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, i) {
                        final data = comments[i].data() as Map<String, dynamic>;
                        final author = data['author'] ?? 'مستخدم';
                        final photoUrl = data['photoUrl'];
                        final commentUserId = data['userId'];
                        final username = data['username'] ?? 'user';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                          leading: GestureDetector(
                            onTap: () {
                              if (commentUserId != null && commentUserId != FirebaseAuth.instance.currentUser?.uid) {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileViewScreen(peerUid: commentUserId, username: username, fullName: author, photoUrl: photoUrl)));
                              }
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.accent,
                              backgroundImage: _getProfileImage(photoUrl),
                              child: (photoUrl == null || photoUrl.isEmpty) ? Text(author.isNotEmpty ? author[0] : 'ع', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)) : null,
                            ),
                          ),
                          title: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (commentUserId != null && commentUserId != FirebaseAuth.instance.currentUser?.uid) {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => UserProfileViewScreen(peerUid: commentUserId, username: username, fullName: author, photoUrl: photoUrl)));
                                  }
                                },
                                child: Text(author, style: const TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 6),
                              Text('@$username', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              const Spacer(),
                              Text(_formatTimestamp(data['timestamp']), style: const TextStyle(color: Colors.white38, fontSize: 10)),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(data['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(color: Colors.white10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'اكتب تعليقاً...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: AppColors.primary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.black, size: 20),
                      onPressed: () async {
                        final text = commentController.text.trim();
                        if (text.isEmpty) return;
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          final uDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                          final uData = uDoc.data();

                          await FirebaseFirestore.instance.collection('official_posts').doc(postId).collection('comments').add({
                            'text': text,
                            'author': uData?['fullName'] ?? user.displayName ?? 'مستخدم',
                            'username': uData?['username'] ?? 'user',
                            'photoUrl': uData?['photoUrl'],
                            'userId': user.uid,
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                          await FirebaseFirestore.instance.collection('official_posts').doc(postId).update({
                            'commentsCount': FieldValue.increment(1),
                          });
                          commentController.clear();
                        }
                      },
                    ),
                  )
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _openMyProfile() {
    final currentUser = FirebaseAuth.instance.currentUser;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          posts: _userPosts,
          onAddUserPost: (content, imageUrl) {
            // منطق المنشورات الشخصية المسبق
          },
        ),
      ),
    );
  }

  void _openUserProfile(Map<String, dynamic> user) {
    final uid = user['uid'] ?? user['userId'] ?? '';
    final username = user['username'] ?? '';
    final fullName = user['fullName'] ?? user['author'] ?? '';
    final bio = user['bio'] ?? 'طالب في كلية القانون | مهتم بالتشريعات والدراسات القانونية';
    final photoUrl = user['photoUrl'];

    if (uid == FirebaseAuth.instance.currentUser?.uid) {
      _openMyProfile();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileViewScreen(
          peerUid: uid,
          username: username,
          fullName: fullName,
          bio: bio,
          photoUrl: photoUrl,
          onStartChat: () {},
        ),
      ),
    );
  }

  void _showUserSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String query = "";
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'ادخل الاسم أو اسم المستخدم...',
                        hintStyle: TextStyle(color: Colors.white38),
                        prefixIcon: Icon(Icons.search, color: AppColors.accent),
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          query = val.trim();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 250,
                      child: query.isEmpty
                          ? const Center(child: Text('اكتب اسم البحث للبدء...', style: TextStyle(color: Colors.white54)))
                          : StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance.collection('users').snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) return const Center(child: Text('خطأ في الاتصال', style: TextStyle(color: Colors.redAccent)));
                                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لا يوجد مستخدمون', style: TextStyle(color: Colors.white54)));

                                final results = snapshot.data!.docs.where((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  final fullName = (data['fullName'] ?? '').toString().toLowerCase();
                                  final username = (data['username'] ?? '').toString().toLowerCase();
                                  final q = query.toLowerCase();
                                  return fullName.contains(q) || username.contains(q);
                                }).toList();

                                if (results.isEmpty) return const Center(child: Text('لا يوجد مستخدم بهذا الاسم', style: TextStyle(color: Colors.white54)));

                                return ListView.builder(
                                  itemCount: results.length,
                                  itemBuilder: (context, index) {
                                    final doc = results[index];
                                    final userData = doc.data() as Map<String, dynamic>;
                                    final fullName = userData['fullName'] ?? 'مستخدم';
                                    final username = userData['username'] ?? 'user';
                                    final bio = userData['bio'] ?? '';
                                    final photoUrl = userData['photoUrl'];

                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: AppColors.accent,
                                        backgroundImage: _getProfileImage(photoUrl),
                                        child: (photoUrl == null || photoUrl.toString().isEmpty)
                                            ? Text(fullName.isNotEmpty ? fullName[0] : 'ع', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))
                                            : null,
                                      ),
                                      title: Text(fullName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      subtitle: Text('@$username', style: const TextStyle(color: AppColors.accent, fontSize: 12)),
                                      onTap: () {
                                        Navigator.pop(context);
                                        final currentUid = FirebaseAuth.instance.currentUser?.uid;
                                        if (doc.id == currentUid) {
                                          _openMyProfile();
                                        } else {
                                          _openUserProfile({'uid': doc.id, 'username': username, 'fullName': fullName, 'bio': bio, 'photoUrl': photoUrl});
                                        }
                                      },
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        title: const Text('منصة القانون'),
        backgroundColor: AppColors.primary,
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.accent),
            onPressed: _showUserSearchDialog,
            tooltip: 'البحث عن مستخدم',
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
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // تصميم الإعلانات الجديد
              if (_announcements.isNotEmpty) _buildAnnouncementsTicker(),
              if (_announcements.isNotEmpty) const SizedBox(height: 16),
              
              // تصميم العداد الجديد
              if (_targetDuration != null && _targetDuration!.inSeconds > 0) _buildCountdownCard(),
              if (_targetDuration != null && _targetDuration!.inSeconds > 0) const SizedBox(height: 25),

              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('التبليغات الرسمية', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.accent)),
                ],
              ),
              const SizedBox(height: 15),

              // جلب المنشورات الرسمية من فايربيس (يدعم الصور، الملفات، اللايكات والتعليقات)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('official_posts').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.accent));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('لا توجد تبليغات رسمية حالياً.', style: TextStyle(color: Colors.white54)),
                    ));
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) => _buildOfficialPostCard(snapshot.data!.docs[index]),
                  );
                },
              ),
            ],
          ),
        ),
        
        // شاشة التحميل المنبثقة عند تنزيل الملفات
        if (_isDownloading)
          Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                color: AppColors.cardBg,
                margin: const EdgeInsets.symmetric(horizontal: 32),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.accent),
                      const SizedBox(height: 15),
                      Text(
                        'جاري تحميل: $_downloadingTitle',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text('${(_downloadProgress * 100).toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================
  // تصميم الإعلانات بشكل أرقى وأعلى
  // ==========================================
  Widget _buildAnnouncementsTicker() {
    String combinedText = "${_announcements.join("   •   ")}   •   ";
    return Container(
      height: 55,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accent.withOpacity(0.15), AppColors.cardBg],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.accent.withOpacity(0.6), width: 1),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
            child: const Icon(Icons.campaign, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              controller: _tickerScrollController,
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              child: Text(
                combinedText,
                style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // تصميم العداد التنازلي بشكل أنيق ومختلف
  // ==========================================
  Widget _buildCountdownCard() {
    if (_targetDuration == null) return const SizedBox();
    String days = _targetDuration!.inDays.toString().padLeft(2, '0');
    String hours = (_targetDuration!.inHours % 24).toString().padLeft(2, '0');
    String minutes = (_targetDuration!.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (_targetDuration!.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2235), Color(0xFF101423)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_bottom, color: AppColors.accent, size: 24),
              SizedBox(width: 10),
              Text('الوقت المتبقي للحدث القادم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 20),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withOpacity(0.5), width: 1),
          ),
          child: Text(value, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.accent, letterSpacing: 2)),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
      ],
    );
  }

  // دعم عرض الصور من الرابط أو Base64
  Widget _buildNetworkImage(String url, {double width = double.infinity}) {
    if (url.startsWith('data:image')) {
      return Image.memory(base64Decode(url.split(',').last), fit: BoxFit.cover, width: width);
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: width,
      placeholder: (context, url) => Container(width: width, color: AppColors.primary, child: const Center(child: CircularProgressIndicator(color: AppColors.accent))),
      errorWidget: (context, url, error) => Container(width: width, color: AppColors.primary, child: const Icon(Icons.broken_image, color: Colors.white54, size: 40)),
    );
  }

  // ==========================================
  // تصميم بطاقة التبليغ الرسمي المتكاملة
  // ==========================================
  Widget _buildOfficialPostCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String content = data['content'] ?? '';
    final List<dynamic> imageUrls = data['imageUrls'] ?? [];
    final String? singleImage = data['imageUrl'];
    final String? fileUrl = data['fileUrl'];
    final String? fileName = data['fileName'];
    final int commentsCount = data['commentsCount'] ?? 0;
    
    List<String> likes = [];
    if (data['likes'] is List) {
      likes = List<String>.from((data['likes'] as List).map((e) => e.toString()));
    }
    
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bool isLiked = likes.contains(currentUid);
    final String postTime = _formatTimestamp(data['timestamp']);

    return Card(
      color: AppColors.cardBg,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.accent.withOpacity(0.2), width: 1),
      ),
      elevation: 5,
      shadowColor: Colors.black45,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ترويسة المنشور (إزالة اليوزر ووضع مطرقة العدالة)
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.accent.withOpacity(0.2),
                  child: const Icon(Icons.gavel, color: AppColors.accent, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('إدارة منصة القانون', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    Text(postTime, style: const TextStyle(fontSize: 11, color: Colors.white54)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),
            
            // نص المنشور
            if (content.isNotEmpty) Text(content, style: const TextStyle(fontSize: 15, color: Colors.white, height: 1.4)),

            // التعامل مع الصور المتعددة أو المفردة
            if (imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, i) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildNetworkImage(imageUrls[i], width: 250),
                      ),
                    );
                  }
                ),
              ),
            ] else if (singleImage != null && singleImage.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildNetworkImage(singleImage),
              ),
            ],

            // التعامل مع الملفات المرفقة
            if (fileUrl != null && fileUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 30),
                  title: Text(fileName ?? 'ملف مرفق', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('اضغط لتحميل وفتح الملف', style: TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: const Icon(Icons.download_rounded, color: Colors.blue),
                  onTap: () => _downloadAndOpenPdf(fileUrl, fileName ?? 'مرفق'),
                ),
              ),
            ],

            // التعليقات واللايكات
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: Colors.white10, height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () async {
                    final postRef = FirebaseFirestore.instance.collection('official_posts').doc(doc.id);
                    if (isLiked) {
                      await postRef.update({'likes': FieldValue.arrayRemove([currentUid])});
                    } else {
                      await postRef.update({'likes': FieldValue.arrayUnion([currentUid])});
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Icon(isLiked ? Icons.thumb_up : Icons.thumb_up_outlined, color: isLiked ? AppColors.accent : Colors.white60, size: 20),
                        const SizedBox(width: 8),
                        Text('${likes.length} إعجاب', style: TextStyle(color: isLiked ? AppColors.accent : Colors.white60, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _showOfficialCommentsModal(context, doc.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, color: Colors.white60, size: 20),
                        const SizedBox(width: 8),
                        Text('$commentsCount تعليق', style: const TextStyle(color: Colors.white60, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
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
      {'icon': Icons.menu_book, 'title': 'المكتبة القانونية', 'route': AppRoutes.legalLibrary},
      {'icon': Icons.book, 'title': 'المواد الدراسية', 'route': AppRoutes.studyMaterials},
      {'icon': Icons.quiz, 'title': 'بنك الأسئلة', 'route': AppRoutes.questionBank},
      {'icon': Icons.assignment, 'title': 'سوق الكتب', 'route': AppRoutes.electronicExams},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) => InkWell(
          onTap: () {
            Navigator.pushNamed(context, services[index]['route']);
          },
          child: Card(
            color: AppColors.cardBg,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(services[index]['icon'], size: 40, color: AppColors.accent),
                const SizedBox(height: 8),
                Text(services[index]['title'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Drawer(
      backgroundColor: AppColors.cardBg,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: currentUser != null
                ? FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots()
                : null,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const UserAccountsDrawerHeader(
                   decoration: BoxDecoration(color: AppColors.primary),
                   accountName: Text("خطأ في التحميل", style: TextStyle(color: Colors.red)),
                   accountEmail: Text(""),
                );
              }

              String name = currentUser?.displayName ?? "طالب قانون";
              String email = currentUser?.email ?? "";
              String? photoUrl;

              if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>;
                name = data['fullName'] ?? name;
                email = data['email'] ?? email;
                photoUrl = data['photoUrl'];
              }

              return UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: AppColors.primary),
                accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                accountEmail: Text(email, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: AppColors.accent,
                  backgroundImage: _getProfileImage(photoUrl),
                  child: photoUrl == null || photoUrl.isEmpty
                      ? Text(
                          name.isNotEmpty ? name[0] : 'ع',
                          style: const TextStyle(fontSize: 26, color: Colors.black, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.person, color: AppColors.accent),
            title: const Text('الملف الشخصي', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _openMyProfile();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, color: AppColors.accent),
            title: const Text('الإعدادات', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    blockedUsers: _blockedUsers,
                    onUnblockUser: (index) {
                      setState(() {
                        _blockedUsers.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.security, color: Colors.amber),
            title: const Text('لوحة الإدارة الحصينة', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.pop(context); 
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SecureAdminDashboardScreen(
                    officialPosts: _officialPosts,
                    announcements: _announcements,
                    // تم ربط دوال الإدارة هنا بفايربيس مباشرة
                    onAddPost: (String content, File? imageFile) async {
                      String? imageUrl;
                      if (imageFile != null) {
                        final bytes = await imageFile.readAsBytes();
                        imageUrl = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                      }
                      await FirebaseFirestore.instance.collection('official_posts').add({
                        'content': content,
                        'imageUrl': imageUrl,
                        'timestamp': FieldValue.serverTimestamp(),
                        'likes': [],
                        'commentsCount': 0,
                      });
                    },
                    onDeletePost: (index) async {
                      final snapshot = await FirebaseFirestore.instance.collection('official_posts').orderBy('timestamp', descending: true).get();
                      if (index < snapshot.docs.length) {
                        await FirebaseFirestore.instance.collection('official_posts').doc(snapshot.docs[index].id).delete();
                      }
                    },
                    onEditPost: (index, newContent) async {
                      final snapshot = await FirebaseFirestore.instance.collection('official_posts').orderBy('timestamp', descending: true).get();
                      if (index < snapshot.docs.length) {
                        await FirebaseFirestore.instance.collection('official_posts').doc(snapshot.docs[index].id).update({'content': newContent});
                      }
                    },
                    onAddBanner: (banner) async {
                      List<String> updatedAnnouncements = List.from(_announcements)..add(banner);
                      await FirebaseFirestore.instance.collection('settings').doc('announcements').set({'texts': updatedAnnouncements}, SetOptions(merge: true));
                    },
                    onDeleteBanner: (index) async {
                      List<String> updatedAnnouncements = List.from(_announcements)..removeAt(index);
                      await FirebaseFirestore.instance.collection('settings').doc('announcements').set({'texts': updatedAnnouncements}, SetOptions(merge: true));
                    },
                    onUpdateTimerDays: (days) async {
                      DateTime target = DateTime.now().add(Duration(days: days));
                      await FirebaseFirestore.instance.collection('settings').doc('timer').set({'targetDate': Timestamp.fromDate(target)}, SetOptions(merge: true));
                    },
                    onDeleteTimer: () async {
                      await FirebaseFirestore.instance.collection('settings').doc('timer').delete();
                    },
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info, color: AppColors.accent),
            title: const Text('حول التطبيق', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }
}
