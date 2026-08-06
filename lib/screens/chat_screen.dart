import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

class StudentForumScreen extends StatefulWidget {
  final String currentUserUid;
  final String currentUserAccountName;

  const StudentForumScreen({
    super.key,
    required this.currentUserUid,
    required this.currentUserAccountName,
  });

  @override
  State<StudentForumScreen> createState() => _StudentForumScreenState();
}

class _StudentForumScreenState extends State<StudentForumScreen> {
  bool _hasJoinedChat = false;
  bool _isCheckingJoinStatus = true;
  bool _isAdminSession = false;

  @override
  void initState() {
    super.initState();
    _checkJoinStatus();
  }

  Future<void> _checkJoinStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool joined = prefs.getBool('joined_forum_${widget.currentUserUid}') ?? false;
    if (mounted) {
      setState(() {
        _hasJoinedChat = joined;
        _isCheckingJoinStatus = false;
      });
    }
  }

  Future<void> _joinForum() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('joined_forum_${widget.currentUserUid}', true);
    if (mounted) {
      setState(() {
        _hasJoinedChat = true;
      });
    }
  }

  Future<void> _leaveForum() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('joined_forum_${widget.currentUserUid}', false);
    if (mounted) {
      setState(() {
        _hasJoinedChat = false;
        _isAdminSession = false;
      });
    }
  }

  void _showAdminLoginDialog() {
    final userController = TextEditingController();
    final passController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Color(0xFFD4AF37)),
            SizedBox(width: 8),
            Text('بوابة الإدارة العليا', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: userController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم (User)',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'كلمة السر',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFD4AF37))),
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
            onPressed: () {
              if (userController.text.trim() == 'x9.ta9' &&
                  passController.text.trim() == 'Abbas312004') {
                setState(() => _isAdminSession = true);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم تسجيل الدخول كـ أدمن بنجاح')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('بيانات الدخول غير صحيحة!')),
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
    if (_isCheckingJoinStatus) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
      );
    }

    if (!_hasJoinedChat) {
      return JoinWelcomeScreen(
        onJoin: _joinForum,
        onAdminTap: _showAdminLoginDialog,
      );
    }

    return MainForumChatView(
      currentUserUid: widget.currentUserUid,
      currentUserAccountName: widget.currentUserAccountName,
      isAdmin: _isAdminSession,
      onLeaveChat: _leaveForum,
      onOpenAdminLogin: _showAdminLoginDialog,
    );
  }
}

class JoinWelcomeScreen extends StatefulWidget {
  final VoidCallback onJoin;
  final VoidCallback onAdminTap;
  const JoinWelcomeScreen({super.key, required this.onJoin, required this.onAdminTap});

  @override
  State<JoinWelcomeScreen> createState() => _JoinWelcomeScreenState();
}

class _JoinWelcomeScreenState extends State<JoinWelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.security, color: Color(0xFFD4AF37)),
            onPressed: widget.onAdminTap,
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4AF37).withOpacity(0.12),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF1A1A1A),
                          border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.25),
                              blurRadius: 18,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Icon(
                          Icons.forum_rounded,
                          size: 64,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'مرحباً بك في الدردشة العامة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'انضم للمناقشات المباشرة، تبادل المستندات والخبرات مع باقي الأعضاء.',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: widget.onJoin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'انضم إلى الدردشة',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 18),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class MainForumChatView extends StatefulWidget {
  final String currentUserUid;
  final String currentUserAccountName;
  final bool isAdmin;
  final VoidCallback onLeaveChat;
  final VoidCallback onOpenAdminLogin;

  const MainForumChatView({
    super.key,
    required this.currentUserUid,
    required this.currentUserAccountName,
    required this.isAdmin,
    required this.onLeaveChat,
    required this.onOpenAdminLogin,
  });

  @override
  State<MainForumChatView> createState() => _MainForumChatViewState();
}

class _MainForumChatViewState extends State<MainForumChatView> with WidgetsBindingObserver {
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Map<String, dynamic>? replyToMessage;
  bool _isChatDisabled = false;
  bool _isUserBanned = false;
  bool _isUploading = false;
  bool _isMuted = false;
  List<String> _bannedUsers = [];
  int _documentLimit = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setUserPresence(true);
    _listenToAdminSettings();
    _chatController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setUserPresence(false);
    _scrollController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setUserPresence(true);
    } else {
      _setUserPresence(false);
    }
  }

  void _setUserPresence(bool isOnline) {
    FirebaseFirestore.instance
        .collection('forum_presence')
        .doc(widget.currentUserUid)
        .set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
      'name': widget.currentUserAccountName,
    }, SetOptions(merge: true));
  }

  void _listenToAdminSettings() {
    FirebaseFirestore.instance
        .collection('chat_settings')
        .doc('general')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        var data = snapshot.data()!;
        if (mounted) {
          setState(() {
            _isChatDisabled = data['isChatDisabled'] ?? false;
            _bannedUsers = List<String>.from(data['bannedUsers'] ?? []);
            _isUserBanned = _bannedUsers.contains(widget.currentUserAccountName) ||
                _bannedUsers.contains(widget.currentUserUid);
          });
        }
      }
    });
  }

  void _onTextChanged() {
    bool isTyping = _chatController.text.isNotEmpty;
    FirebaseFirestore.instance
        .collection('chat_typing')
        .doc(widget.currentUserUid)
        .set({'isTyping': isTyping, 'sender': widget.currentUserAccountName});
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 2,
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFD4AF37),
              child: Icon(Icons.groups_rounded, color: Colors.black),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الدردشة العامة',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('forum_presence')
                      .where('isOnline', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = snapshot.data?.docs.length ?? 0;
                    return Text(
                      '$count متواجد الآن',
                      style: const TextStyle(fontSize: 10, color: Color(0xFFD4AF37)),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              widget.isAdmin ? Icons.admin_panel_settings : Icons.security,
              color: widget.isAdmin ? Colors.greenAccent : const Color(0xFFD4AF37),
            ),
            onPressed: () {
              if (widget.isAdmin) {
                _showAdminDashboard();
              } else {
                widget.onOpenAdminLogin();
              }
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            backgroundColor: const Color(0xFF1A1A1A),
            onSelected: (value) {
              if (value == 'leave') {
                widget.onLeaveChat();
              } else if (value == 'mute') {
                setState(() => _isMuted = !_isMuted);
                _showSnackBar(_isMuted ? 'تم كتم التنبيهات' : 'تم تفعيل التنبيهات');
              } else if (value == 'report') {
                _showSnackBar('تم إرسال بلاغك للإدارة');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mute',
                child: Row(
                  children: [
                    Icon(_isMuted ? Icons.notifications_off : Icons.notifications, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(_isMuted ? 'إلغاء الكتم' : 'كتم الدردشة', style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report_problem, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('إبلاغ عن محتوى', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'leave',
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('مغادرة الدردشة', style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPinnedBanner(),
          if (_isUploading)
            const LinearProgressIndicator(backgroundColor: Colors.black, color: Color(0xFFD4AF37)),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('forum_chats')
                  .orderBy('timestamp', descending: true)
                  .limit(_documentLimit)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
                }

                var docs = snapshot.data?.docs ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, idx) {
                    var doc = docs[idx];
                    var msg = doc.data() as Map<String, dynamic>;
                    bool isMe = (msg['senderUid'] ?? '') == widget.currentUserUid ||
                        msg['sender'] == widget.currentUserAccountName;

                    return _buildChatBubble(doc.id, msg, isMe);
                  },
                );
              },
            ),
          ),
          _buildTypingIndicator(),
          if (replyToMessage != null) _buildReplyPreview(),
          _buildInputArea(),
        ],
      ),
    );
  }
    Widget _buildChatBubble(String docId, Map<String, dynamic> msg, bool isMe) {
    String formattedTime = _formatTime(msg['timestamp']);
    Map<String, dynamic> reactions = Map<String, dynamic>.from(msg['reactions'] ?? {});
    String senderUid = msg['senderUid'] ?? '';

    return GestureDetector(
      onLongPress: () => _showContextMenu(docId, msg, isMe),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              StreamBuilder<DocumentSnapshot>(
                stream: senderUid.isNotEmpty
                    ? FirebaseFirestore.instance.collection('users').doc(senderUid).snapshots()
                    : null,
                builder: (context, userSnap) {
                  String avatarUrl = '';
                  if (userSnap.hasData && userSnap.data!.exists) {
                    var userData = userSnap.data!.data() as Map<String, dynamic>?;
                    avatarUrl = userData?['avatarUrl'] ?? userData?['photoUrl'] ?? '';
                  }
                  return CircleAvatar(
                    radius: 15,
                    backgroundColor: const Color(0xFF2A2A2A),
                    backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl.isEmpty
                        ? Text(
                            (msg['sender'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11),
                          )
                        : null,
                  );
                },
              ),
              const SizedBox(width: 6),
            ],
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFD4AF37) : const Color(0xFF222222),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: isMe ? const Radius.circular(14) : const Radius.circular(2),
                  bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(14),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    StreamBuilder<DocumentSnapshot>(
                      stream: senderUid.isNotEmpty
                          ? FirebaseFirestore.instance.collection('users').doc(senderUid).snapshots()
                          : null,
                      builder: (context, userSnap) {
                        String name = msg['sender'] ?? '';
                        if (userSnap.hasData && userSnap.data!.exists) {
                          var userData = userSnap.data!.data() as Map<String, dynamic>?;
                          name = userData?['name'] ?? userData?['username'] ?? name;
                        }
                        return Text(
                          name,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD4AF37),
                          ),
                        );
                      },
                    ),
                  if (msg['replyTo'] != null) _buildReplyContent(msg['replyTo'], isMe),
                  _buildMessageMediaContent(msg, isMe),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        formattedTime,
                        style: TextStyle(
                          fontSize: 9,
                          color: isMe ? Colors.black54 : Colors.white38,
                        ),
                      ),
                    ],
                  ),
                  if (reactions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        children: reactions.values
                            .map((e) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(e.toString(), style: const TextStyle(fontSize: 10)),
                                ))
                            .toList(),
                      ),
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyContent(Map<String, dynamic> reply, bool isMe) {
    return Container(
      padding: const EdgeInsets.all(6),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border(right: BorderSide(color: isMe ? Colors.black54 : const Color(0xFFD4AF37), width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reply['sender'] ?? '',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isMe ? Colors.black87 : const Color(0xFFD4AF37),
            ),
          ),
          Text(
            reply['text'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: isMe ? Colors.black87 : Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageMediaContent(Map<String, dynamic> msg, bool isMe) {
    String type = msg['type'] ?? 'text';
    String url = msg['mediaUrl'] ?? msg['text'] ?? '';

    switch (type) {
      case 'image':
        return GestureDetector(
          onTap: () => _openImageViewer(url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              url,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.broken_image, color: Colors.grey),
            ),
          ),
        );
      case 'audio':
        return AudioBubblePlayer(url: url, isMe: isMe);
      case 'file':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, color: isMe ? Colors.black : const Color(0xFFD4AF37)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                msg['fileName'] ?? 'مستند مرفق',
                style: TextStyle(color: isMe ? Colors.black : Colors.white, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      default:
        return Text(
          msg['text'] ?? '',
          style: TextStyle(
            color: isMe ? Colors.black : Colors.white,
            fontSize: 13,
            height: 1.3,
          ),
        );
    }
  }

  void _showContextMenu(String docId, Map<String, dynamic> msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => Container(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['❤️', '👍', '😂', '😮', '😢'].map((emoji) {
                return IconButton(
                  icon: Text(emoji, style: const TextStyle(fontSize: 22)),
                  onPressed: () {
                    Navigator.pop(context);
                    _toggleReaction(docId, Map<String, dynamic>.from(msg['reactions'] ?? {}), emoji);
                  },
                );
              }).toList(),
            ),
            const Divider(color: Colors.white10),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.white),
              title: const Text('نسخ النص', style: TextStyle(color: Colors.white)),
              onTap: () {
                Clipboard.setData(ClipboardData(text: msg['text'] ?? ''));
                Navigator.pop(context);
                _showSnackBar('تم نسخ النص');
              },
            ),
            if (isMe || widget.isAdmin)
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text('حذف الرسالة', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  FirebaseFirestore.instance.collection('forum_chats').doc(docId).delete();
                },
              ),
            if (widget.isAdmin)
              ListTile(
                leading: const Icon(Icons.push_pin, color: Color(0xFFD4AF37)),
                title: Text((msg['isPinned'] ?? false) ? 'إلغاء التثبيت' : 'تثبيت الرسالة', style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  FirebaseFirestore.instance
                      .collection('forum_chats')
                      .doc(docId)
                      .update({'isPinned': !(msg['isPinned'] ?? false)});
                },
              ),
          ],
        ),
      ),
    );
  }
    Future<void> _pickAndUploadFile(String type) async {
    File? file;
    String fileName = '';

    if (type == 'image') {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (picked != null) {
        file = File(picked.path);
        fileName = picked.name;
      }
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type == 'audio' ? FileType.audio : FileType.any,
      );
      if (result != null && result.files.single.path != null) {
        file = File(result.files.single.path!);
        fileName = result.files.single.name;
      }
    }

    if (file == null) return;

    setState(() => _isUploading = true);

    try {
      String storagePath = 'forum_uploads/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      Reference ref = FirebaseStorage.instance.ref().child(storagePath);
      UploadTask uploadTask = ref.putFile(file);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      _sendMessage(type: type, mediaUrl: downloadUrl, fileName: fileName);
    } catch (e) {
      _showSnackBar('خطأ أثناء الرفع: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _sendMessage({String type = 'text', String? mediaUrl, String? fileName}) async {
    if (_isChatDisabled && !widget.isAdmin) {
      _showSnackBar('الدردشة مغلقة حالياً بقرار من الإدارة.');
      return;
    }
    if (_isUserBanned) {
      _showSnackBar('حسابك محظور من المشاركة.');
      return;
    }

    String text = _chatController.text.trim();
    if (text.isNotEmpty || mediaUrl != null) {
      _chatController.clear();

      try {
        await FirebaseFirestore.instance.collection('forum_chats').add({
          'senderUid': widget.currentUserUid,
          'sender': widget.currentUserAccountName,
          'text': text,
          'mediaUrl': mediaUrl ?? '',
          'fileName': fileName ?? '',
          'type': type,
          'replyTo': replyToMessage != null
              ? {
                  'text': replyToMessage!['text'],
                  'sender': replyToMessage!['sender']
                }
              : null,
          'timestamp': FieldValue.serverTimestamp(),
          'reactions': {},
          'isPinned': false,
        });

        _scrollToBottom();
      } catch (e) {
        debugPrint("Send error: $e");
      }

      if (mounted) {
        setState(() {
          replyToMessage = null;
        });
      }
    }
  }

  Widget _buildInputArea() {
    if (_isChatDisabled && !widget.isAdmin) {
      return Container(
        padding: const EdgeInsets.all(14),
        color: Colors.red.shade900.withOpacity(0.2),
        child: const Center(
          child: Text('الإرسال مغلق حالياً من قبل الإدارة', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: const Color(0xFF1A1A1A),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file, color: Color(0xFFD4AF37)),
              onPressed: _showAttachmentModal,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _chatController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'اكتب رسالتك...',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFD4AF37),
              child: IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                onPressed: () => _sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => Container(
        height: 140,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _attachmentOption(Icons.image, 'صورة', () {
              Navigator.pop(context);
              _pickAndUploadFile('image');
            }),
            _attachmentOption(Icons.mic, 'تسجيل صوتي', () {
              Navigator.pop(context);
              _pickAndUploadFile('audio');
            }),
            _attachmentOption(Icons.insert_drive_file, 'مستند', () {
              Navigator.pop(context);
              _pickAndUploadFile('file');
            }),
          ],
        ),
      ),
    );
  }

  Widget _attachmentOption(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF2A2A2A),
            child: Icon(icon, color: const Color(0xFFD4AF37), size: 20),
          ),
          const SizedBox(height: 6),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.white)),
        ],
      ),
    );
  }

  void _showAdminDashboard() {
    final banController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('لوحة التحكم الكاملة للإدارة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const Divider(color: Colors.white10),
            ListTile(
              leading: Icon(_isChatDisabled ? Icons.lock_open : Icons.lock, color: const Color(0xFFD4AF37)),
              title: Text(_isChatDisabled ? 'تفعيل الدردشة للجميع' : 'قفل الدردشة مؤقتاً', style: const TextStyle(color: Colors.white)),
              onTap: () {
                FirebaseFirestore.instance
                    .collection('chat_settings')
                    .doc('general')
                    .set({'isChatDisabled': !_isChatDisabled}, SetOptions(merge: true));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.redAccent),
              title: const Text('حظر / إلغاء حظر مستخدم (يوزر أو Uid)', style: TextStyle(color: Colors.white)),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF1A1A1A),
                    title: const Text('إدارة الحظر', style: TextStyle(color: Colors.white)),
                    content: TextField(
                      controller: banController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'ادخل اليوزر أو Uid', hintStyle: TextStyle(color: Colors.grey)),
                    ),
                    actions: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () {
                          String target = banController.text.trim();
                          if (target.isNotEmpty) {
                            if (_bannedUsers.contains(target)) {
                              _bannedUsers.remove(target);
                            } else {
                              _bannedUsers.add(target);
                            }
                            FirebaseFirestore.instance
                                .collection('chat_settings')
                                .doc('general')
                                .set({'bannedUsers': _bannedUsers}, SetOptions(merge: true));
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text('تأكيد الحظر/الفك', style: TextStyle(color: Colors.white)),
                      )
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep, color: Colors.red),
              title: const Text('مسح جميع الرسائل في الشات', style: TextStyle(color: Colors.red)),
              onTap: () async {
                var snapshot = await FirebaseFirestore.instance.collection('forum_chats').get();
                for (var doc in snapshot.docs) {
                  await doc.reference.delete();
                }
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinnedBanner() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('forum_chats')
          .where('isPinned', isEqualTo: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        var pinnedData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: const Color(0xFFD4AF37).withOpacity(0.15),
          child: Row(
            children: [
              const Icon(Icons.push_pin, size: 14, color: Color(0xFFD4AF37)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'مثبّت: ${pinnedData['text']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTypingIndicator() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('chat_typing').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        var typingUsers = snapshot.data!.docs
            .where((doc) => doc['isTyping'] == true && doc.id != widget.currentUserUid)
            .map((doc) => doc['sender'])
            .toList();

        if (typingUsers.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${typingUsers.join(', ')} يكتب الآن...',
              style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Color(0xFFD4AF37)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(6),
      color: const Color(0xFF222222),
      child: Row(
        children: [
          const Icon(Icons.reply, color: Color(0xFFD4AF37), size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'الرد على (${replyToMessage!['sender']}): ${replyToMessage!['text']}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.white),
            onPressed: () => setState(() => replyToMessage = null),
          ),
        ],
      ),
    );
  }

  void _toggleReaction(String docId, Map<String, dynamic> reactions, String emoji) {
    String user = widget.currentUserUid;
    if (reactions[user] == emoji) {
      reactions.remove(user);
    } else {
      reactions[user] = emoji;
    }
    FirebaseFirestore.instance.collection('forum_chats').doc(docId).update({'reactions': reactions});
  }

  void _openImageViewer(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
          body: Center(child: InteractiveViewer(child: Image.network(url))),
        ),
      ),
    );
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null || timestamp is! Timestamp) return '';
    DateTime dt = timestamp.toDate();
    int hourInt = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    String hour = hourInt.toString().padLeft(2, '0');
    String minute = dt.minute.toString().padLeft(2, '0');
    String period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

class AudioBubblePlayer extends StatefulWidget {
  final String url;
  final bool isMe;
  const AudioBubblePlayer({super.key, required this.url, required this.isMe});

  @override
  State<AudioBubblePlayer> createState() => _AudioBubblePlayerState();
}

class _AudioBubblePlayerState extends State<AudioBubblePlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.play(UrlSource(widget.url));
      setState(() => _isPlaying = true);
      _audioPlayer.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _isPlaying = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
            size: 28,
            color: widget.isMe ? Colors.black : const Color(0xFFD4AF37),
          ),
          onPressed: _togglePlay,
        ),
        Text(
          'تسجيل صوتي',
          style: TextStyle(
            color: widget.isMe ? Colors.black : Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
